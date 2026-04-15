#!/bin/bash
# pw-sudo-03-undo.sh (UPDATED FOR unified .mjs)

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
echo " Undo Playwright Sudo Setup (linux-mac)"
echo "---------------------------------------------------------"

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    chmod 755 "$f"
    chown root:root "$f"
    echo "  ✔ Reset: $(basename "$f")"
  fi
done

if [[ -f "$SUDOERS_FILE" ]]; then
  rm -f "$SUDOERS_FILE"
  echo "  ✔ Removed sudoers entry"
fi

echo
echo "Undo complete."
