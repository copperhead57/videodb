#!/bin/bash
# pw-sudo-03-undo.sh
# Undo Playwright sudo setup (menu-compatible version)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="${PLAYROOT:-$SCRIPT_DIR}"

SUDOERS_FILE="/etc/sudoers.d/videodb-playwright"

FILES=(
  "$PLAYROOT/xvfb.sh"
  "$PLAYROOT/node-clean.sh"
  "$PLAYROOT/imdb-fetch-unix.mjs"
)

echo "---------------------------------------------------------"
echo " Undo Playwright Sudo Setup"
echo "---------------------------------------------------------"
echo "PLAYROOT:"
echo "  $PLAYROOT"
echo

# ---------------------------------------------------------
# 1. Ask which ownership to restore
# ---------------------------------------------------------
echo "Restore script ownership to:"
echo "  1) Your desktop user"
echo "  2) root:root"
echo

read -p "Select option (1/2): " CHOICE

case "$CHOICE" in
  1)
    DESKTOP_USER="$(whoami)"
    OWNER="$DESKTOP_USER:$DESKTOP_USER"
    ;;
  2)
    OWNER="root:root"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# ---------------------------------------------------------
# 2. Reset script permissions
# ---------------------------------------------------------
echo "--- Resetting script permissions ---"

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    chmod 755 "$f"
    chown "$OWNER" "$f"
    echo "  ✔ Reset: $(basename "$f") → $OWNER"
  fi
done

# ---------------------------------------------------------
# 3. Remove sudoers entry
# ---------------------------------------------------------
if [[ -f "$SUDOERS_FILE" ]]; then
  rm -f "$SUDOERS_FILE"
  echo "  ✔ Removed sudoers file: $SUDOERS_FILE"
else
  echo "  (No sudoers file found — nothing to remove)"
fi

# ---------------------------------------------------------
# 4. Validate sudoers
# ---------------------------------------------------------
echo
echo "--- Validating sudoers ---"
if visudo -c >/dev/null 2>&1; then
  echo "  ✔ sudoers syntax OK"
else
  echo "  ⚠ WARNING: sudoers validation reported issues"
fi

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
echo
echo "---------------------------------------------------------"
echo " Undo complete"
echo "---------------------------------------------------------"
echo "Scripts restored to owner: $OWNER"
echo "Sudoers entry removed (if present)"
echo
