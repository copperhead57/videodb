#!/usr/bin/env bash
set -u

echo "== Verify Playwright Install (07-verify-install.sh) =="

FAIL=0
ok()   { echo "  ✔ $1"; }
fail() { echo "  ✘ $1"; FAIL=1; }
warn() { echo "  ! $1"; }

# ---------------------------------------------------------
# Path resolution (only to find PLAYROOT + env file)
# ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="$(dirname "$SCRIPT_DIR")"          # lib/playwright/linux
ENV_FILE="${PLAYROOT}/playwright-env.sh"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[FAIL] Missing environment file: $ENV_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

PW_OS_TYPE="${PW_OS_TYPE:-linux}"
PW_ENVIRONMENT="${PW_ENVIRONMENT:-system}"
PW_APACHE_USER="${PW_APACHE_USER:-www-data}"
DESKTOP_USER="${PW_DESKTOP_USER}"
PROJECT_ROOT="${PW_PROJECT_ROOT}"
PROJECT_NAME="${PW_PROJECT_NAME}"
BROWSER_ROOT="${PW_PLAYROOT}/node_modules/playwright-core/.local-browsers"
FETCHER="${PW_PLAYROOT}/imdb-fetch-linux-headless.mjs"

GLOBAL_SUDOERS="/etc/sudoers.d/${DESKTOP_USER}-playwright"
PROJECT_SUDOERS="/etc/sudoers.d/${DESKTOP_USER}-playwright-${PROJECT_NAME}-${PW_ENVIRONMENT}"

echo "---------------------------------------------------------"
echo " Full Environment Verification — Playwright Headless"
echo "---------------------------------------------------------"
echo "PLAYROOT:       $PW_PLAYROOT"
echo "PROJECT_ROOT:   $PROJECT_ROOT"
echo "PROJECT_NAME:   $PROJECT_NAME"
echo "PW_ENVIRONMENT: $PW_ENVIRONMENT"
echo "PW_APACHE_USER: $PW_APACHE_USER"
echo "PW_OS_TYPE:     $PW_OS_TYPE"
echo "BROWSER_ROOT:   $BROWSER_ROOT"
echo "FETCHER:        $FETCHER"
echo

# ---------------------------------------------------------
# 1. Node
# ---------------------------------------------------------
echo "[1] Node Runtime"
if command -v node >/dev/null 2>&1; then
    ok "node: $(node -v)"
else
    fail "node missing"
fi

if command -v npm >/dev/null 2>&1; then
    ok "npm: $(npm -v)"
else
    fail "npm missing"
fi
echo

# ---------------------------------------------------------
# 2. Playwright installation
# ---------------------------------------------------------
echo "[2] Playwright Installation"
[ -f "$PW_PLAYROOT/package.json" ] && ok "package.json exists" || fail "package.json missing"
[ -d "$PW_PLAYROOT/node_modules" ] && ok "node_modules exists" || fail "node_modules missing"
[ -d "$PW_PLAYROOT/node_modules/playwright" ] && ok "playwright package installed" || fail "playwright package missing"
echo

# ---------------------------------------------------------
# 3. Browsers (system-install mode)
# ---------------------------------------------------------
echo "[3] Playwright Browsers (system-install mode)"
[ -d "$BROWSER_ROOT" ] && ok "browser root exists: $BROWSER_ROOT" || fail "browser root missing: $BROWSER_ROOT"

for b in chromium firefox webkit ffmpeg; do
    if ls "$BROWSER_ROOT" 2>/dev/null | grep -q "^$b-"; then
        ok "$b installed"
    else
        warn "$b not found (may be unused)"
    fi
done
echo

# ---------------------------------------------------------
# 4. Wrapper permissions (fetcher only)
# ---------------------------------------------------------
echo "[4] Wrapper Permissions"

if [[ -f "$FETCHER" ]]; then
    owner=$(stat -c %U "$FETCHER")
    group=$(stat -c %G "$FETCHER")
    perm=$(stat -c %a "$FETCHER")

    if [[ "$owner" = "$DESKTOP_USER" && "$group" = "$PW_APACHE_USER" && "$perm" = "770" ]]; then
        ok "$(basename "$FETCHER") owner=$owner group=$group perm=$perm"
    else
        fail "$(basename "$FETCHER") owner=$owner group=$group perm=$perm (expected $DESKTOP_USER:$PW_APACHE_USER 770)"
    fi
else
    fail "fetcher missing: $FETCHER"
fi
echo

# ---------------------------------------------------------
# 5. Sudoers File (Tier‑1 + Tier‑2)
# ---------------------------------------------------------
echo "[5] Sudoers Files"

# --- Tier‑1: must exist, syntax OK, no project-specific rules ---
if sudo test -f "$GLOBAL_SUDOERS"; then
    ok "Tier‑1 sudoers exists: $GLOBAL_SUDOERS"
else
    fail "Tier‑1 sudoers missing: $GLOBAL_SUDOERS"
fi

if sudo visudo -c -f "$GLOBAL_SUDOERS" >/dev/null 2>&1; then
    ok "Tier‑1 syntax OK"
else
    fail "Tier‑1 syntax error"
fi

if sudo grep -q "$PROJECT_ROOT" "$GLOBAL_SUDOERS"; then
    fail "Tier‑1 contains project-specific rules (should be empty)"
else
    ok "Tier‑1 contains no project-specific rules"
fi

echo
sudo sed 's/^/    /' "$GLOBAL_SUDOERS" || true
echo

# --- Tier‑2: must exist, syntax OK, contain Apache rules ---
if sudo test -f "$PROJECT_SUDOERS"; then
    ok "Tier‑2 sudoers exists: $PROJECT_SUDOERS"
else
    fail "Tier‑2 sudoers missing: $PROJECT_SUDOERS"
fi

if sudo visudo -c -f "$PROJECT_SUDOERS" >/dev/null 2>&1; then
    ok "Tier‑2 syntax OK"
else
    fail "Tier‑2 syntax error"
fi

if sudo grep -q "^${PW_APACHE_USER} " "$PROJECT_SUDOERS"; then
    ok "Tier‑2 contains Apache rules for ${PW_APACHE_USER}"
else
    fail "Tier‑2 missing Apache rules for ${PW_APACHE_USER}"
fi

echo
sudo sed 's/^/    /' "$PROJECT_SUDOERS" || true
echo

# ---------------------------------------------------------
# 6. Desktop user group membership
# ---------------------------------------------------------
echo "[6] Desktop User Group Membership"
if groups "$DESKTOP_USER" | grep -q "$PW_APACHE_USER"; then
    ok "$DESKTOP_USER is in group $PW_APACHE_USER"
else
    fail "$DESKTOP_USER NOT in group $PW_APACHE_USER"
fi
echo

# ---------------------------------------------------------
# 7. Fetcher test (optional full chain)
# ---------------------------------------------------------
echo "[7] Fetcher Execution Test"

FETCH_URL="https://www.imdb.com/title/tt0133093/"
WRAPPER="$PLAYROOT/imdb-fetch-linux-headless.sh"

CMD_STRING="sudo -n -u \"$DESKTOP_USER\" \"$WRAPPER\" \"$FETCH_URL\""

echo "  Running:"
echo "    Desktop user: $DESKTOP_USER"
echo "    WRAPPER     : $WRAPPER"
echo "    URL         : $FETCH_URL"
echo "    Command     : $CMD_STRING"
echo

FETCH_OUTPUT=$(eval "$CMD_STRING" 2>&1 || true)

PW_HTML_LIMIT=800

HTML_CONTENT=$(echo "$FETCH_OUTPUT" \
  | sed -n 's/.*"html":"\(.*\)","wafDetected".*/\1/p')

HTML_CONTENT=$(echo "$HTML_CONTENT" | sed 's/\x1b\[[0-9;]*m//g')

TRUNCATED_HTML="${HTML_CONTENT:0:$PW_HTML_LIMIT}"

if [[ ${#HTML_CONTENT} -gt $PW_HTML_LIMIT ]]; then
    TRUNCATED_HTML="$TRUNCATED_HTML[TRUNCATED]"
fi

ESCAPED_HTML=$(printf '%s' "$TRUNCATED_HTML" \
  | sed 's/\\/\\\\/g' \
  | sed 's/"/\\"/g' \
  | sed 's/\//\\\//g' \
  | tr '\n' ' ')

JSON_WITH_TRUNCATED_HTML=$(echo "$FETCH_OUTPUT" \
  | sed "s/\"html\":\".*\",\"wafDetected\"/\"html\":\"$ESCAPED_HTML\",\"wafDetected\"/")

echo "  JSON with truncated HTML:"
echo "-----------------------------"
echo "$JSON_WITH_TRUNCATED_HTML"
echo "-----------------------------"
echo

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
echo "---------------------------------------------------------"
if [[ "$FAIL" -eq 0 ]]; then
    echo " FULL VERIFICATION PASSED — Environment is correct"
else
    echo " VERIFICATION COMPLETED WITH FAILURES — See above"
fi
echo "---------------------------------------------------------"
