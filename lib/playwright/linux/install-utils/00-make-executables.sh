#!/usr/bin/env bash
set -euo pipefail

# Directory of this script (install-utils/)
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# One level up: linux/
BASE_DIR="$(dirname "${UTILS_DIR}")"

echo "[00] Ensuring all installer and runtime .sh scripts are executable"
echo

fix_dir() {
    local DIR="$1"
    local LABEL="$2"

    echo "Scanning: ${LABEL} (${DIR})"
    shopt -s nullglob

    local COUNT=0
    local FIXED=0

    for f in "${DIR}"/*.sh; do
        local filename
        filename="$(basename "$f")"
        COUNT=$((COUNT + 1))

        if [[ -x "$f" ]]; then
            echo "OK:    ${filename}"
        else
            echo "FIXED: ${filename} (adding +x)"
            chmod +x "$f"
            FIXED=$((FIXED + 1))
        fi
    done

    shopt -u nullglob

    echo "  Total .sh files: ${COUNT}"
    echo "  Files fixed:     ${FIXED}"
    echo
}

# Fix install-utils scripts
fix_dir "${UTILS_DIR}" "install-utils"

# Fix runtime scripts in linux
fix_dir "${BASE_DIR}" "linux runtime"

echo "[00] Done."
