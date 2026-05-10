#!/usr/bin/env bash
set -euo pipefail

echo "[06b] Sudoers Cleanup"

# ------------------------------------------------------------
# 1. Determine PLAYROOT safely (do NOT require launcher export)
# ------------------------------------------------------------
if [[ -z "${PLAYROOT:-}" ]]; then
    # Script lives in: .../lib/playwright/linux/install-utils
    # PLAYROOT is two levels up from install-utils
    PLAYROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi

ENV_FILE="${PLAYROOT}/playwright-env.sh"
DETECT_SCRIPT="${PLAYROOT}/install-utils/01-detect-environment.sh"

# ------------------------------------------------------------
# 2. Ensure env file exists (fallback to detect)
# ------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
    echo "[WARN] Missing env file: $ENV_FILE"
    echo "       Running detect to rebuild it..."
    bash "$DETECT_SCRIPT"
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[FAIL] Cannot continue — env file still missing after detect."
    exit 1
fi

# ------------------------------------------------------------
# 3. Load authoritative environment
# ------------------------------------------------------------
source "$ENV_FILE"

DESKTOP_USER="$PW_DESKTOP_USER"
PROJECT_NAME="$PW_PROJECT_NAME"
PW_ENVIRONMENT="$PW_ENVIRONMENT"
PLAYROOT="$PW_PLAYROOT"   # authoritative override

# ------------------------------------------------------------
# 4. Build Tier‑1 and Tier‑2 sudoers filenames
# ------------------------------------------------------------
TIER1_SUDOERS="/etc/sudoers.d/${DESKTOP_USER}-playwright"
TIER2_SUDOERS="/etc/sudoers.d/${DESKTOP_USER}-playwright-${PROJECT_NAME}-${PW_ENVIRONMENT}"

echo
echo "  Desktop user:   $DESKTOP_USER"
echo "  Project name:   $PROJECT_NAME"
echo "  Environment:    $PW_ENVIRONMENT"
echo
echo "  Tier‑1 sudoers: $TIER1_SUDOERS"
echo "  Tier‑2 sudoers: $TIER2_SUDOERS"
echo

# ------------------------------------------------------------
# 5. Remove Tier‑2 sudoers (project-specific)
# ------------------------------------------------------------
if [[ -f "$TIER2_SUDOERS" ]]; then
    echo "  - Found project-specific sudoers:"
    echo "    $TIER2_SUDOERS"
    read -r -p "    Remove this sudoers entry? (y/N): " REPLY

    case "$REPLY" in
        [yY]|[yY][eE][sS])
            echo "  - Removing Tier‑2 sudoers"
            sudo rm -f "$TIER2_SUDOERS"
            ;;
        *)
            echo "  - Keeping Tier‑2 sudoers"
            ;;
    esac
else
    echo "  - No Tier‑2 sudoers file found for this project."
fi

# ------------------------------------------------------------
# 6. Reset wrapper + fetcher to raw Git state (664, pdb:pdb)
# ------------------------------------------------------------
WRAPPER="${PLAYROOT}/imdb-fetch-linux-headless.sh"
FETCHER="${PLAYROOT}/imdb-fetch-linux-headless.mjs"

echo
echo "  - Resetting wrapper + fetcher to raw Git state (664 pdb:pdb)"

for f in "$WRAPPER" "$FETCHER"; do
    if [[ -f "$f" ]]; then
        sudo chown "$DESKTOP_USER":"$DESKTOP_USER" "$f"
        sudo chmod 664 "$f"
        echo "    * $(basename "$f") → owner=$DESKTOP_USER group=$DESKTOP_USER perm=664"
    else
        echo "    * Missing: $f"
    fi
done

# ------------------------------------------------------------
# 7. Check if any other Tier‑2 sudoers remain for this user
# ------------------------------------------------------------
REMAINING_TIER2=( /etc/sudoers.d/${DESKTOP_USER}-playwright-* )

FILTERED=()
for f in "${REMAINING_TIER2[@]}"; do
    base="$(basename "$f")"
    if [[ "$base" != "${DESKTOP_USER}-playwright" ]]; then
        FILTERED+=("$f")
    fi
done

# ------------------------------------------------------------
# 8. Remove Tier‑1 only if no other Tier‑2 exist
# ------------------------------------------------------------
if [[ ${#FILTERED[@]} -eq 0 ]]; then
    if [[ -f "$TIER1_SUDOERS" ]]; then
        echo
        echo "  - No remaining Tier‑2 sudoers for this user."
        echo "    Tier‑1 sudoers can be safely removed:"
        echo "    $TIER1_SUDOERS"
        read -r -p "    Remove Tier‑1 sudoers? (y/N): " REPLY2

        case "$REPLY2" in
            [yY]|[yY][eE][sS])
                echo "  - Removing Tier‑1 sudoers"
                sudo rm -f "$TIER1_SUDOERS"
                ;;
            *)
                echo "  - Keeping Tier‑1 sudoers"
                ;;
        esac
    fi
else
    echo
    echo "  - Other Tier‑2 sudoers still exist for this user:"
    for f in "${FILTERED[@]}"; do
        echo "      * $(basename "$f")"
    done
    echo "  - Tier‑1 sudoers will NOT be removed."
fi

echo
echo "[06b] Sudoers cleanup complete."
