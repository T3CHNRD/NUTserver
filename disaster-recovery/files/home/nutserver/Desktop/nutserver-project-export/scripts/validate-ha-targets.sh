#!/usr/bin/env bash
set -u

CONFIG_FILE="${HOME}/Desktop/nutserver-project-export/config/ha-production-targets.conf"
LOG_DIR="${HOME}/Desktop/nutserver-project-export/runtime"
LOG_FILE="${LOG_DIR}/validate-ha-targets.log"

mkdir -p "${LOG_DIR}"
: > "${LOG_FILE}"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    echo "[$(timestamp)] $1" | tee -a "${LOG_FILE}"
}

fail_count=0
warn_count=0
last_phase=0
nut_last_seen=0
placeholder_seen=0

valid_types=("vm" "host" "storage" "nut")
valid_methods=("vcenter_vm" "vcenter_host" "storage_manual" "local_nut")

is_in_array() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

log "============================================================"
log "Starting HA production target validation"
log "Config file: ${CONFIG_FILE}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    log "ERROR: Config file not found"
    exit 1
fi

line_num=0

while IFS='|' read -r phase type name method wait_seconds notes; do
    line_num=$((line_num + 1))

    [[ -z "${phase}" ]] && continue
    [[ "${phase}" =~ ^# ]] && continue

    log "Checking line ${line_num}: ${phase}|${type}|${name}|${method}|${wait_seconds}|${notes}"

    if [[ ! "${phase}" =~ ^[0-9]+$ ]]; then
        log "ERROR: line ${line_num} has invalid phase '${phase}'"
        fail_count=$((fail_count + 1))
        continue
    fi

    if (( phase < last_phase )); then
        log "ERROR: line ${line_num} phase ${phase} is out of order (previous phase ${last_phase})"
        fail_count=$((fail_count + 1))
    fi
    last_phase=${phase}

    if ! is_in_array "${type}" "${valid_types[@]}"; then
        log "ERROR: line ${line_num} has invalid type '${type}'"
        fail_count=$((fail_count + 1))
    fi

    if ! is_in_array "${method}" "${valid_methods[@]}"; then
        log "ERROR: line ${line_num} has invalid method '${method}'"
        fail_count=$((fail_count + 1))
    fi

    if [[ ! "${wait_seconds}" =~ ^[0-9]+$ ]]; then
        log "ERROR: line ${line_num} has invalid wait_seconds '${wait_seconds}'"
        fail_count=$((fail_count + 1))
    fi

    if [[ "${name}" == "CHANGE_ME_VCSA_LAST_HOST" ]]; then
        log "WARNING: placeholder CHANGE_ME_VCSA_LAST_HOST is still present"
        warn_count=$((warn_count + 1))
        placeholder_seen=1
    fi

    if [[ "${type}" == "nut" ]]; then
        nut_last_seen=1
        if [[ "${phase}" -ne 8 ]]; then
            log "ERROR: NUT server entry should be phase 8"
            fail_count=$((fail_count + 1))
        fi
        if [[ "${method}" != "local_nut" ]]; then
            log "ERROR: NUT server entry should use method local_nut"
            fail_count=$((fail_count + 1))
        fi
    fi
done < "${CONFIG_FILE}"

if [[ "${nut_last_seen}" -eq 0 ]]; then
    log "ERROR: no NUT server final entry was found"
    fail_count=$((fail_count + 1))
fi


if [[ "${placeholder_seen}" -eq 1 ]]; then
    log "EXECUTION BLOCKED: CHANGE_ME_VCSA_LAST_HOST is still present"
    log "EXECUTION BLOCKED: identify the ESXi host that normally carries vCenter during shutdown"
fi

log "Validation complete"
log "Warnings: ${warn_count}"
log "Errors: ${fail_count}"
log "============================================================"

if [[ "${fail_count}" -gt 0 ]]; then
    exit 1
fi

