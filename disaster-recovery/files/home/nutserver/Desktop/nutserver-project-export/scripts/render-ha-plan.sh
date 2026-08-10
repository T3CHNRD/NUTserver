#!/usr/bin/env bash
set -u

CONFIG_FILE="${HOME}/Desktop/nutserver-project-export/config/ha-production-targets.conf"
LOG_DIR="${HOME}/Desktop/nutserver-project-export/runtime"
OUTPUT_FILE="${LOG_DIR}/ha-shutdown-plan.txt"

mkdir -p "${LOG_DIR}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    exit 1
fi

declare -A phase_titles
phase_titles[1]="Phase 1 - Non-Critical Apps"
phase_titles[2]="Phase 2 - Business Apps"
phase_titles[3]="Phase 3 - Cluster Support"
phase_titles[4]="Phase 4 - Core Identity"
phase_titles[5]="Phase 5 - vCenter / Final VM"
phase_titles[6]="Phase 6 - ESXi Hosts"
phase_titles[7]="Phase 7 - Storage"
phase_titles[8]="Phase 8 - NUT Server Final Shutdown"

{
    echo "============================================================"
    echo "HA Shutdown Plan"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Config: ${CONFIG_FILE}"
    echo "============================================================"
    echo

    current_phase=""

    while IFS='|' read -r phase type name method wait_seconds notes; do
        [[ -z "${phase}" ]] && continue
        [[ "${phase}" =~ ^# ]] && continue

        if [[ "${phase}" != "${current_phase}" ]]; then
            current_phase="${phase}"
            echo "${phase_titles[${phase}]}"
            echo "------------------------------------------------------------"
        fi

        printf "  - %-20s | type=%-7s | method=%-14s | wait=%-3s | %s\n" \
            "${name}" "${type}" "${method}" "${wait_seconds}" "${notes}"

        if [[ "${name}" == "CHANGE_ME_VCSA_LAST_HOST" ]]; then
            echo
            echo "  *** EXECUTION BLOCKER: CHANGE_ME_VCSA_LAST_HOST is still present ***"
            echo "  *** Identify the ESXi host that normally carries vCenter during shutdown ***"
            echo
        fi
    done < "${CONFIG_FILE}"

    echo
    echo "============================================================"
    echo "NOTE: This file is a rendered plan only."
    echo "No shutdown actions were executed."
    echo "============================================================"
} > "${OUTPUT_FILE}"

cat "${OUTPUT_FILE}"

