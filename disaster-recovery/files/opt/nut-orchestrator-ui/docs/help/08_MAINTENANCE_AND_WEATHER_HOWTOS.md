# Maintenance and Weather - Complete Operator How-Tos

## Purpose

Maintenance and Weather guidance helps determine whether current/forecast conditions are acceptable for planned maintenance that could reduce power resilience.

The maintenance state is informational guidance and must be interpreted together with the planned work.

---

## How to Interpret CLEAR

CLEAR means the evaluated conditions are acceptable under the configured maintenance/weather rules.

CLEAR does not mean:

- no risk exists
- weather cannot change
- a maintenance task is automatically approved

Use normal change-control and production-safety requirements.

Search phrases:

- maintenance clear
- what does CLEAR mean
- safe for maintenance

---

## How to Interpret CAUTION

CAUTION means conditions deserve additional attention but have not reached a configured BLOCK threshold.

Examples may include:

- forecast high between 85 and 89.9 F
- wind gusts between 30 and 39.9 mph
- freezing drizzle
- light/moderate snow
- snow grains
- snow showers

CAUTION should prompt the operator to review the specific reason before proceeding with maintenance.

PROTECTING mode by itself is not a CAUTION condition.

live_actions=1 by itself is not a CAUTION condition.

Search phrases:

- maintenance caution
- why does NUT say CAUTION
- weather caution

---

## How to Interpret BLOCK

BLOCK means one or more configured conditions meet the threshold where planned maintenance should be deferred unless there is an overriding approved reason.

Configured BLOCK examples include:

- severe thunderstorm/hail
- significant ice/freezing rain
- heavy snow/heavy snow showers
- forecast low at or below 34 F
- forecast high at or above 90 F
- wind gust at or above 40 mph

Search phrases:

- maintenance block
- why does NUT say BLOCK
- weather block
- should maintenance be postponed

---

## How Weather Affects Maintenance Recommendations

The current weather logic evaluates specific conditions rather than treating ordinary rain as automatically unsafe.

Configured guidance includes:

BLOCK:

- severe thunderstorm/hail
- significant ice/freezing rain
- heavy snow/heavy snow showers
- forecast low <= 34 F
- forecast high >= 90 F
- gust >= 40 mph

CAUTION:

- forecast high 85 to 89.9 F
- gust 30 to 39.9 mph
- freezing drizzle
- light/moderate snow
- snow grains
- snow showers

Ordinary rain/drizzle or precipitation probability alone does not automatically create CAUTION.

High-heat guidance is based on possible grid-load risk, not a claim that a power failure will occur.

---

## How to Read the Weather Summary

The user-facing weather summary should include:

- current temperature
- plain-English summary
- significant weather/grid-risk conditions when present

Examples of summary language may include:

- Nice day
- stormy
- snow/ice
- rainy
- windy
- hot

---

## How to Turn Weather-Based Closing Thoughts ON or OFF

Use Notification Settings Help.

This presentation option controls the closing thought in the Daily Health Email.

It does not disable the underlying weather/maintenance evaluation.

---

UPS Maintenance Mode can affect whether shutdown commits are allowed. For the shutdown side of that behavior, see [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md).

## How to Verify Maintenance Status

1. Open the Control Center maintenance/weather status area. If the overall NUT protection state is unclear, first review [Protection Modes](02_PROTECTION_MODES.md).
2. Review CLEAR, CAUTION, or BLOCK.
3. Read the stated reason.
4. Review the current/forecast weather summary and the documented [weather data source and flow](08_MAINTENANCE_AND_WEATHER_HOWTOS.md).
5. Confirm the displayed reason matches the configured rule.

Do not infer a maintenance state only from temperature without reviewing the complete status.

---

## Production-Hours Safety

Reviewing maintenance/weather status is read-only and safe during production hours.

Changing maintenance logic or thresholds is a configuration/code change and should be separately reviewed.

---

## Monitoring Impact

Maintenance/weather status does not itself disable UPS monitoring.

## Notification Impact

Maintenance/weather information may be included in configured health email/Telegram reporting.

## Shutdown-Protection Impact

Maintenance guidance does not itself trigger protected-system shutdown.

---

## Troubleshooting

If the displayed maintenance state looks wrong:

1. Review the reason text.
2. Review current temperature.
3. Review forecast high/low.
4. Review wind gust values.
5. Review snow/ice/storm conditions.
6. Check the maintenance/weather backend output and use [Logs](16_LOGS_HOWTOS.md) if the displayed state does not match backend behavior.
7. Compare it with the configured thresholds above.

Do not change thresholds merely to make the displayed state more convenient.


## Security

Maintenance/weather data should not require exposing credentials in Help.

---

## Weather Data, Grid Risk, and Maintenance Recommendations

### Why Weather Information Matters

Weather information is not decorative. The NUT Control Center uses local weather and forecast conditions as an additional risk input when deciding whether planned UPS swaps, battery maintenance, or other scheduled power work should proceed.

Weather does **not** independently trigger a UPS shutdown, server shutdown, or protected-system action.

Weather matters because:

- extreme heat can increase electrical-grid demand
- severe weather can increase the likelihood of utility-power interruptions
- high winds can increase outage risk
- freezing temperatures, snow, and ice can make planned infrastructure work less desirable
- ordinary rain, clouds, or fair weather may be informational without automatically creating a maintenance warning

### Weather Data Source

- Provider: **Open-Meteo**
- Local cache: `/var/cache/nut/weather-cache.json`
- Refresh service: `nut-weather-cache-refresh.service`
- Refresh timer: `nut-weather-cache-refresh.timer`
- Scheduled refreshes: **4:00 AM and 12:00 PM America/Detroit**

### Weather Data Flow

```text
                         Open-Meteo
                             |
                             | 2 scheduled refreshes per day
                             |
                    +--------+--------+
                    |                 |
                 4:00 AM           12:00 PM
              America/Detroit    America/Detroit
                    |                 |
                    +--------+--------+
                             |
                             v
                  Local Weather Cache
                             |
               +-------------+-------------+
               |             |             |
               v             v             v
        Daily Health     Daily Health    /health
           Email          Telegram
               |             |
               +------+------+
                      |
               +------+-------+
               |              |
               v              v
        /maintenance    Weather-Based
                        Closing Thought
```

The reporting paths reuse the cached forecast instead of independently contacting Open-Meteo each time they run.

This reduces unnecessary API traffic and makes NUT health reporting less dependent on the external weather provider being reachable at the exact moment a report is generated.

### Weather Risk Thresholds

The current maintenance-risk logic includes these weather conditions:

- Forecast low at or below **34°F**: cold-weather maintenance risk
- Forecast high at or above **85°F**: elevated heat/grid-load CAUTION
- Forecast high at or above **90°F**: high heat/grid-load risk
- Forecast wind gusts at or above **30 mph**: wind CAUTION
- Forecast wind gusts at or above **40 mph**: high-wind risk
- Significant snow, freezing precipitation, thunderstorms, and other severe conditions may also affect the recommendation

Weather is only one input. UPS status, NUT monitoring state, IDF power information, and other health checks remain separate inputs.

### What Happens if Open-Meteo Is Unavailable

A successful scheduled refresh updates the local weather cache.

If a later refresh fails, the last known good cache is preserved instead of replacing it with bad or empty data.

The current refresh helper reports failures such as HTTP errors, invalid JSON, empty responses, or other retrieval failures while preserving the existing cache.

Health reports should continue using the most recent valid cached forecast and show when that cache was last updated.

### Troubleshooting the Weather Cache

Check the timer:

`systemctl list-timers --all --no-pager | grep nut-weather-cache-refresh`

Check the refresh service:

`systemctl status nut-weather-cache-refresh.service --no-pager -l`

Check the cache timestamp:

`stat -c '%y %n' /var/cache/nut/weather-cache.json`

Manually refresh the cache:

`sudo /usr/local/sbin/nut-weather-cache-refresh`

A successful refresh reports:

`WEATHER_CACHE_REFRESH=PASS`

A failed refresh should report the failure while preserving the last known good cache.

### Where the Health Information Comes From

The Daily Health report combines several independent information sources:

- **UPS status:** read from the locally configured NUT UPS monitoring system using the current UPS status and values reported through NUT.
- **NUT monitoring state and protection mode:** read from the NUT production-status/control logic on the NUT server.
- **IDF power health:** derived from the monitored IDF power-event/status information maintained by the NUT monitoring system.
- **Weather and grid-risk context:** read from the shared local Open-Meteo weather cache described above.

These inputs are combined to produce the overall health and maintenance recommendation.

Weather information is advisory context only. A weather condition by itself does not create a UPS power event or initiate a protected-system shutdown.

