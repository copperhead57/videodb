#!/usr/bin/env bash
set -euo pipefail

echo "== Verify Uninstalled (07-verify-uninstall.sh) =="

# ------------------------------------------------------------
# Resolve PLAYROOT (install-utils/.. = lib/playwright/linux)
# ------------------------------------------------------------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYROOT="${BASE_DIR}"

echo "BASE_DIR:  $BASE_DIR"
echo "PLAYROOT:  $PLAYROOT"
echo

FAIL=0

# ------------------------------------------------------------
# 1. Recover DESKTOP_USER, PROJECT_NAME, PW_ENVIRONMENT
# ------------------------------------------------------------
ENV_FILE="${PLAYROOT}/playwright-env.sh"

if [[ -f "$ENV_FILE" ]]; then
    echo "-- Loading environment from $ENV_FILE"
    source "$ENV_FILE"

    DESKTOP_USER="$PW_DESKTOP_USER"
    PROJECT_NAME="$PW_PROJECT_NAME"
    PW_ENVIRONMENT="$PW_ENVIRONMENT"

else
    echo "-- Env file missing → attempting reconstruction"

    # Try to reconstruct from remaining Tier‑2 sudoers
    shopt -s nullglob
    CANDIDATES=( /etc/sudoers.d/*-playwright-*-* )
    shopt -u nullglob

    TIER2=""
    for f in "${CANDIDATES[@]}"; do
        base="$(basename "$f")"
        # Skip Tier‑1 (<user>-playwright)
        if [[ "$base" =~ ^[^-]+-playwright$ ]]; then
            continue
        fi
        TIER2="$f"
        break
    done

    if [[ -n "$TIER2" ]]; then
        echo "  Found remaining Tier‑2 sudoers → reconstructing"
        base="$(basename "$TIER2")"

        DESKTOP_USER="${base%%-playwright-*}"
        REST="${base#*-playwright-}"

        PROJECT_NAME="${REST%-*}"
        PW_ENVIRONMENT="${REST##*-}"

        echo "    DESKTOP_USER=$DESKTOP_USER"
        echo "    PROJECT_NAME=$PROJECT_NAME"
        echo "    PW_ENVIRONMENT=$PW_ENVIRONMENT"

    else
        echo "  No Tier‑2 sudoers remain → using wrapper owner as fallback"

        WRAPPER="${PLAYROOT}/imdb-fetch-linux-headless.sh"

        if [[ -f "$WRAPPER" ]]; then
            DESKTOP_USER="$(stat -c "%U" "$WRAPPER")"
        else
            DESKTOP_USER="unknown"
        fi

        PROJECT_NAME="unknown"
        PW_ENVIRONMENT="unknown"

        echo "    DESKTOP_USER=$DESKTOP_USER"
        echo "    PROJECT_NAME=$PROJECT_NAME"
        echo "    PW_ENVIRONMENT=$PW_ENVIRONMENT"
    fi
fi

echo
echo "DESKTOP_USER:   $DESKTOP_USER"
echo "PROJECT_NAME:   $PROJECT_NAME"
echo "PW_ENVIRONMENT: $PW_ENVIRONMENT"
echo

# ------------------------------------------------------------
# 2. Build Tier‑1 and Tier‑2 filenames
# ------------------------------------------------------------
TIER1_SUDOERS="/etc/sudoers.d/${DESKTOP_USER}-playwright"
TIER2_SUDOERS="/etc/sudoers.d/${DESKTOP_USER}-playwright-${PROJECT_NAME}-${PW_ENVIRONMENT}"

echo "Tier‑1: $TIER1_SUDOERS"
echo "Tier‑2: $TIER2_SUDOERS"
echo

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------
check_missing_dir() {
    if [[ -d "$1" ]]; then
        echo "✘ Directory still exists: $1"
        FAIL=1
    else
        echo "✔ Removed: $1"
    fi
}

check_missing_file() {
    if [[ -f "$1" ]]; then
        echo "✘ File still exists: $1"
        FAIL=1
    else
        echo "✔ Not Present: $1"
    fi
}

check_present_file() {
    if [[ -f "$1" ]]; then
        echo "✔ Present (expected): $1"
    else
        echo "✘ Missing (should exist): $1"
        FAIL=1
    fi
}

check_perm() {
    local FILE="$1"
    local EXPECT_OWNER="$2"
    local EXPECT_GROUP="$3"
    local EXPECT_MODE="$4"

    if [[ ! -f "$FILE" ]]; then
        echo "✘ Missing: $FILE"
        FAIL=1
        return
    fi

    OWNER=$(stat -c "%U" "$FILE")
    GROUP=$(stat -c "%G" "$FILE")
    MODE=$(stat -c "%a" "$FILE")

    [[ "$OWNER" == "$EXPECT_OWNER" ]] && echo "✔ Owner OK: $FILE" \
        || { echo "✘ Wrong owner ($OWNER, expected $EXPECT_OWNER)"; FAIL=1; }

    [[ "$GROUP" == "$EXPECT_GROUP" ]] && echo "✔ Group OK: $FILE" \
        || { echo "✘ Wrong group ($GROUP, expected $EXPECT_GROUP)"; FAIL=1; }

    [[ "$MODE" == "$EXPECT_MODE" ]] && echo "✔ Mode OK: $FILE" \
        || { echo "✘ Wrong mode ($MODE, expected $EXPECT_MODE)"; FAIL=1; }
}

# ------------------------------------------------------------
# 3. Runtime folders must be removed (new architecture)
# ------------------------------------------------------------
echo "-- Playwright runtime should be removed --"

check_missing_dir "${PLAYROOT}/node_modules"
check_missing_file "${PLAYROOT}/package-lock.json"

echo

# ------------------------------------------------------------
# 4. Sudoers state
# ------------------------------------------------------------
echo "-- Sudoers state --"

# Tier‑2 must be removed
if [[ -f "$TIER2_SUDOERS" ]]; then
    echo "✘ Tier‑2 still exists (should be removed)"
    FAIL=1
else
    echo "✔ Tier‑2 removed"
fi

# Determine if any other Tier‑2 exist
OTHER_TIER2=( /etc/sudoers.d/${DESKTOP_USER}-playwright-* )
FILTERED=()

for f in "${OTHER_TIER2[@]}"; do
    base="$(basename "$f")"
    if [[ "$base" != "${DESKTOP_USER}-playwright" ]]; then
        FILTERED+=("$f")
    fi
done

if [[ ${#FILTERED[@]} -eq 0 ]]; then
    # Tier‑1 should be removed
    if [[ -f "$TIER1_SUDOERS" ]]; then
        echo "✘ Tier‑1 still exists (should be removed when no Tier‑2 remain)"
        FAIL=1
    else
        echo "✔ Tier‑1 removed (expected)"
    fi
else
    # Tier‑1 should remain
    if [[ -f "$TIER1_SUDOERS" ]]; then
        echo "✔ Tier‑1 present (other Tier‑2 exist)"
    else
        echo "✘ Tier‑1 missing (should remain because other Tier‑2 exist)"
        FAIL=1
    fi
fi

echo

# ------------------------------------------------------------
# 5. Wrapper scripts must exist and be in RAW Git state
# ------------------------------------------------------------
echo "-- Wrapper script permissions --"

WRAPPER="${PLAYROOT}/imdb-fetch-linux-headless.sh"
FETCHER="${PLAYROOT}/imdb-fetch-linux-headless.mjs"

EXPECT_OWNER="$DESKTOP_USER"
EXPECT_GROUP="$DESKTOP_USER"
EXPECT_MODE="664"

check_perm "$WRAPPER" "$EXPECT_OWNER" "$EXPECT_GROUP" "$EXPECT_MODE"
check_perm "$FETCHER" "$EXPECT_OWNER" "$EXPECT_GROUP" "$EXPECT_MODE"

echo
echo "-- Wrapper scripts should still exist --"
check_present_file "$WRAPPER"
check_present_file "$FETCHER"

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------
echo
if [[ "$FAIL" -eq 0 ]]; then
    echo "== Uninstall verification PASSED =="
else
    echo "== Uninstall verification FAILED =="
fi
