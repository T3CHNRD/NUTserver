"""Pure consistency rules shared by the NUT health report and its notifier."""

from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timedelta
import re
from typing import Any, Iterable


class EvidenceError(ValueError):
    """Evidence is malformed or ambiguous; callers must fail closed."""


_BATTERY = "UPS: On battery power"
_RESTORED = "UPS: No longer on battery power"
_GLOBAL_RESTORE = "all monitored ups units are on line/grid power"
_RECEIPT_RE = re.compile(r"^\[(?P<stamp>[^\]]+)\]")
_EVENT_TIME_RE = re.compile(r'event_time="([^"]+)"')
_COMM_OK_RE = re.compile(r"UPS_MAINTENANCE_COMM_OK\s+ups(?P<ups>\d+)\b", re.I)
_RETURNED_RE = re.compile(
    r"UPS_MAINTENANCE_(?:UPS_RETURNED|COMPLETED|RETIREMENT_COMPLETED)\b.*?ups=(?P<ups>[A-Za-z0-9_.-]+)",
    re.I,
)
_STARTED_EVENT = "UPS_MAINTENANCE_STARTED"
_COMM_BAD_EVENT = "UPS_MAINTENANCE_COMM_BAD"
_COMM_OK_EVENT = "UPS_MAINTENANCE_COMM_OK"
_RETURN_EVENTS = {
    _COMM_OK_EVENT,
    "UPS_MAINTENANCE_UPS_RETURNED",
    "UPS_MAINTENANCE_COMPLETED",
    "UPS_MAINTENANCE_RETIREMENT_COMPLETED",
}


def parse_timestamp(value: Any, *, local_tz=None) -> datetime:
    if not isinstance(value, str) or not value.strip():
        raise EvidenceError("timestamp missing or not text")
    raw = value.strip()
    parsed = None
    try:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        for fmt in ("%Y-%m-%d %H:%M:%S", "%m/%d/%Y %H:%M:%S"):
            try:
                parsed = datetime.strptime(raw, fmt)
                break
            except ValueError:
                continue
    if parsed is None:
        raise EvidenceError(f"invalid timestamp: {raw}")
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=local_tz or datetime.now().astimezone().tzinfo)
    return parsed


def _receipt_time(line: str) -> datetime | None:
    match = _RECEIPT_RE.match(line)
    if not match:
        return None
    try:
        return parse_timestamp(match.group("stamp"))
    except EvidenceError:
        return None


def _event_time(line: str) -> datetime | None:
    match = _EVENT_TIME_RE.search(line)
    if match:
        try:
            return parse_timestamp(match.group(1))
        except EvidenceError:
            return None
    return _receipt_time(line)


def latest_idf_event_from_lines(
    source: str,
    lines: Iterable[str],
    *,
    now: datetime | None = None,
    freshness: timedelta = timedelta(hours=24),
) -> tuple[str, str, str]:
    """Return battery/line-grid only from fresh evidence, otherwise unknown."""
    key = str(source or "").strip().upper()
    aliases = {
        "IDF2": ("source=\"idf2\"", "device=\"idf2\"", "device=\"apc-idf2\"", "ip=\"192.168.9.251\"", "dns=\"apc-idf2"),
        "IDF3": ("source=\"idf3\"", "device=\"idf3\"", "device=\"apc-idf3\"", "ip=\"192.168.9.252\"", "dns=\"apc-idf3"),
    }.get(key)
    if aliases is None:
        return "unknown", "not found", "unknown UPS source"

    candidates: list[tuple[datetime, int, str, str]] = []
    for index, raw in enumerate(lines):
        line = str(raw).replace("\r", "")
        lower = line.lower()
        is_global_restore = "online - power restored" in lower and _GLOBAL_RESTORE in lower
        has_target = any(alias in lower for alias in aliases)
        is_apc = "apc_idf_event" in lower or "apc_idf_target_event" in lower

        if is_global_restore:
            occurred = _receipt_time(line)
            if occurred:
                candidates.append((occurred, index, "line/grid", "global power-restored event: all monitored UPS units on line/grid"))
            continue

        if not (has_target and is_apc):
            continue
        if _RESTORED.lower() in lower:
            state = "line/grid"
        elif _BATTERY.lower() in lower:
            state = "battery"
        else:
            continue
        occurred = _event_time(line)
        if occurred:
            msg_match = re.search(r'message="([^"]*)"', line, re.I)
            message = msg_match.group(1) if msg_match else state
            candidates.append((occurred, index, state, message))

    if not candidates:
        return "unknown", "not found", "no target-specific power event or global restore evidence"

    latest = max(candidates, key=lambda item: (item[0], item[1]))
    now = now or datetime.now().astimezone()
    if now.tzinfo is None:
        now = now.replace(tzinfo=datetime.now().astimezone().tzinfo)
    age = now - latest[0].astimezone(now.tzinfo)
    event_label = latest[0].astimezone(now.tzinfo).isoformat(timespec="seconds")
    if age < timedelta(minutes=-5):
        return "unknown", event_label, "event timestamp is in the future; review required"
    if age > freshness:
        return "unknown", event_label, f"last {latest[2]} evidence is stale (older than {int(freshness.total_seconds() // 3600)} hours); review required"
    return latest[2], event_label, latest[3]


def _event_evidence(power_event_lines: Iterable[str], state_records: list[dict[str, Any]]):
    returns: dict[str, list[datetime]] = {}
    starts: dict[str, list[datetime]] = {}
    for record in state_records:
        ups = record.get("ups")
        event = record.get("event")
        if not isinstance(event, str) or not event:
            raise EvidenceError("maintenance event record has no event name")
        if not isinstance(ups, str):
            raise EvidenceError("maintenance event record UPS identity is invalid")
        stamp = parse_timestamp(record.get("timestamp"))
        if not ups:
            if event in _RETURN_EVENTS or event in {_STARTED_EVENT, _COMM_BAD_EVENT, "UPS_MAINTENANCE_UPS_OFFLINE"}:
                raise EvidenceError(f"maintenance event {event} has no UPS identity")
            continue
        if event in _RETURN_EVENTS:
            returns.setdefault(ups, []).append(stamp)
        elif event == _STARTED_EVENT:
            starts.setdefault(ups, []).append(stamp)

    for raw in power_event_lines:
        line = str(raw)
        stamp = _receipt_time(line)
        if not stamp:
            continue
        match = _COMM_OK_RE.search(line)
        if match:
            returns.setdefault("ups" + match.group("ups"), []).append(stamp)
            continue
        match = _RETURNED_RE.search(line)
        if match:
            returns.setdefault(match.group("ups"), []).append(stamp)
    return returns, starts


def reconcile_maintenance_state(
    state: Any,
    *,
    power_event_lines: Iterable[str] = (),
    current_statuses: dict[str, str] | None = None,
) -> tuple[dict[str, Any], dict[str, str]]:
    """Return a validated state projection and cleared UPS -> evidence map.

    Explicitly started maintenance is preserved. Automatic COMM_BAD sessions
    clear only on a later return event, or a fresh OL observation for that
    automatic session. Malformed state raises EvidenceError.
    """
    if not isinstance(state, dict):
        raise EvidenceError("maintenance state is not an object")
    result = deepcopy(state)
    active = result.get("active_sessions", [])
    unresolved = result.get("unresolved_items", [])
    records = result.get("recent_records", [])
    if not isinstance(active, list) or not isinstance(unresolved, list) or not isinstance(records, list):
        raise EvidenceError("maintenance state collections must be arrays")

    rows_by_ups: dict[str, list[dict[str, Any]]] = {}
    for collection_name, collection in (("active_sessions", active), ("unresolved_items", unresolved)):
        seen: set[str] = set()
        for item in collection:
            if not isinstance(item, dict):
                raise EvidenceError(f"{collection_name} entry is not an object")
            ups = item.get("ups")
            if not isinstance(ups, str) or not ups.strip():
                raise EvidenceError(f"{collection_name} entry has no UPS identity")
            if ups in seen:
                raise EvidenceError(f"duplicate {collection_name} entry for {ups}")
            seen.add(ups)
            parse_timestamp(item.get("started_at"))
            if not isinstance(item.get("status"), str) or not item.get("status"):
                raise EvidenceError(f"{collection_name} entry for {ups} has no status")
            rows_by_ups.setdefault(ups, []).append(item)

    for record in records:
        if not isinstance(record, dict):
            raise EvidenceError("recent maintenance record is not an object")
        parse_timestamp(record.get("timestamp"))

    returns, starts = _event_evidence(power_event_lines, records)
    statuses = current_statuses or {}
    if not isinstance(statuses, dict):
        raise EvidenceError("current UPS statuses are not an object")

    cleared: dict[str, str] = {}
    for ups, rows in rows_by_ups.items():
        last_start = max(parse_timestamp(row["started_at"]) for row in rows)
        explicit_start = max(starts.get(ups, []), default=None)
        return_after = max((t for t in returns.get(ups, []) if t > last_start), default=None)
        if explicit_start and (not return_after or explicit_start >= return_after):
            continue
        if return_after:
            cleared[ups] = f"later return evidence at {return_after.isoformat(timespec='seconds')}"
            continue

        automatic_commbad = all(
            row.get("mode") == "commbad"
            and row.get("last_event") == "UPS_MAINTENANCE_UPS_OFFLINE"
            for row in rows
        )
        status = statuses.get(ups, "")
        tokens = [REDACTED]
        if automatic_commbad and not explicit_start and "OL" in tokens:
            cleared[ups] = "fresh current UPS status is OL for an automatic COMM_BAD session"

    if cleared:
        result["active_sessions"] = [row for row in active if row["ups"] not in cleared]
        result["unresolved_items"] = [row for row in unresolved if row["ups"] not in cleared]
    return result, cleared


def classify_preview_status(preview: str) -> str:
    """Parse the email preview's one canonical status; ambiguity is UNKNOWN."""
    statuses = re.findall(r"^Status: (BLOCK|CAUTION|CLEAR)\b", preview or "", re.M)
    if len(statuses) != 1:
        return "UNKNOWN"
    return statuses[0]


def choose_health_status(blockers: Iterable[Any], cautions: Iterable[Any]) -> str:
    if any(blockers):
        return "BLOCK"
    if any(cautions):
        return "CAUTION"
    return "CLEAR"
