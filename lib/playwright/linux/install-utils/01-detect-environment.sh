#!/usr/bin/env bash
set -euo pipefail

echo "[01] Detecting environment..."

# ------------------------------------------------------------
# Path resolution
# ------------------------------------------------------------
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"     # .../lib/playwright/linux/install-utils
BASE_DIR="$(dirname "${UTILS_DIR}")"                         # .../lib/playwright/linux
PLAYWRIGHT_DIR="$(dirname "${BASE_DIR}")"                    # .../lib/playwright
LIB_DIR="$(dirname "${PLAYWRIGHT_DIR}")"                     # .../lib
PROJECT_ROOT="$(dirname "${LIB_DIR}")"                       # .../project root

PLAYROOT="${BASE_DIR}"                                       # .../lib/playwright/linux
ENV_FILE="${PLAYROOT}/playwright-env.sh"

DESKTOP_USER="${SUDO_USER:-$USER}"

echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "LIB_DIR     : $LIB_DIR"
echo "UTILS_DIR   : $UTILS_DIR"
echo "BASE_DIR    : $BASE_DIR"
echo "PLAYROOT    : $PLAYROOT"
echo "ENV_FILE    : $ENV_FILE"
echo "DESKTOP_USER: $DESKTOP_USER"

echo
echo "------------------------------------------------------------"
echo " Checking for existing installation"
echo "------------------------------------------------------------"

if [[ -f "${ENV_FILE}" ]]; then
    echo "Existing Playwright installation detected:"
    echo "------------------------------------------"
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    echo "  PW_ENVIRONMENT  = ${PW_ENVIRONMENT}"
    echo "  PW_APACHE_USER  = ${PW_APACHE_USER}"
    echo "  PW_DESKTOP_USER = ${PW_DESKTOP_USER}"
    echo "  PW_PROJECT_ROOT = ${PW_PROJECT_ROOT}"
    echo "  PW_PLAYROOT     = ${PW_PLAYROOT}"
    echo
    echo "This installer will RECONFIGURE the environment."
else
    echo "No existing Playwright installation detected."
    echo "A new environment will be configured."
fi

echo
echo "------------------------------------------------------------"
echo " Detecting installed Apache environments"
echo "------------------------------------------------------------"

SYSTEM_APACHE_BIN="/usr/sbin/apache2"
LAMPP_APACHE_BIN="/opt/lampp/lampp"

SYSTEM_INSTALLED=false
LAMPP_INSTALLED=false

[[ -x "$SYSTEM_APACHE_BIN" ]] && SYSTEM_INSTALLED=true
[[ -x "$LAMPP_APACHE_BIN" ]] && LAMPP_INSTALLED=true

echo "System Apache installed: $SYSTEM_INSTALLED"
echo "LAMPP Apache installed:  $LAMPP_INSTALLED"
echo

echo "------------------------------------------------------------"
echo " Detecting running Apache"
echo "------------------------------------------------------------"

SYSTEM_RUNNING=false
LAMPP_RUNNING=false

if ps -eo user,comm | grep -q "apache2"; then
    SYSTEM_RUNNING=true
fi

if ps -eo user,comm | grep -q "daemon"; then
    LAMPP_RUNNING=true
fi

echo "System Apache running: $SYSTEM_RUNNING"
echo "LAMPP Apache running:  $LAMPP_RUNNING"
echo

# ------------------------------------------------------------
# Decision logic
# ------------------------------------------------------------

choose_environment() {
    echo "Both Apache environments detected."
    echo "Which environment do you want to configure?"
    echo "  1) System Apache (www-data)"
    echo "  2) LAMPP/XAMPP Apache (daemon)"
    echo
    read -r -p "Select option (1/2): " CHOICE

    case "$CHOICE" in
        1) PW_ENVIRONMENT="system"; PW_APACHE_USER="www-data" ;;
        2) PW_ENVIRONMENT="lampp";  PW_APACHE_USER="daemon" ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac
}

# Case D — none installed
if ! $SYSTEM_INSTALLED && ! $LAMPP_INSTALLED; then
    echo "ERROR: No Apache installation detected."
    echo "Install either system Apache or LAMPP before running this installer."
    exit 1
fi

# Case A — only system installed
if $SYSTEM_INSTALLED && ! $LAMPP_INSTALLED; then
    echo "Detected only System Apache. Using system environment."
    PW_ENVIRONMENT="system"
    PW_APACHE_USER="www-data"
fi

# Case B — only LAMPP installed
if ! $SYSTEM_INSTALLED && $LAMPP_INSTALLED; then
    echo "Detected only LAMPP Apache. Using lampp environment."
    PW_ENVIRONMENT="lampp"
    PW_APACHE_USER="daemon"
fi

# Case C — both installed
if $SYSTEM_INSTALLED && $LAMPP_INSTALLED; then
    if $SYSTEM_RUNNING && ! $LAMPP_RUNNING; then
        echo "System Apache is running; LAMPP is installed but inactive."
        read -r -p "Use System Apache? (Y/n): " ANS
        if [[ "$ANS" =~ ^[nN]$ ]]; then
            PW_ENVIRONMENT="lampp"
            PW_APACHE_USER="daemon"
        else
            PW_ENVIRONMENT="system"
            PW_APACHE_USER="www-data"
        fi
    elif ! $SYSTEM_RUNNING && $LAMPP_RUNNING; then
        echo "LAMPP Apache is running; System Apache is installed but inactive."
        read -r -p "Use LAMPP Apache? (Y/n): " ANS
        if [[ "$ANS" =~ ^[nN]$ ]]; then
            PW_ENVIRONMENT="system"
            PW_APACHE_USER="www-data"
        else
            PW_ENVIRONMENT="lampp"
            PW_APACHE_USER="daemon"
        fi
    else
        # Both installed, neither running OR both running
        choose_environment
    fi
fi

# ------------------------------------------------------------
# OS type (informational)
# ------------------------------------------------------------
PW_OS_TYPE="$(uname | tr '[:upper:]' '[:lower:]')"
[[ "$PW_OS_TYPE" = "darwin" ]] && PW_OS_TYPE="mac"

# ------------------------------------------------------------
# Derive project name
# ------------------------------------------------------------
PW_PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# ------------------------------------------------------------
# Write persistent environment file
# ------------------------------------------------------------
cat > "${ENV_FILE}" <<EOF
# Playwright environment configuration (persistent)

PW_ENVIRONMENT="${PW_ENVIRONMENT}"
PW_OS_TYPE="${PW_OS_TYPE}"

PW_APACHE_USER="${PW_APACHE_USER}"
PW_DESKTOP_USER="${DESKTOP_USER}"

PW_PROJECT_ROOT="${PROJECT_ROOT}"
PW_PROJECT_NAME="${PW_PROJECT_NAME}"
PW_PLAYROOT="${PLAYROOT}"
EOF

echo
echo "------------------------------------------------------------"
echo " Environment selected:"
echo "------------------------------------------------------------"
echo "  PW_ENVIRONMENT  = ${PW_ENVIRONMENT}"
echo "  PW_APACHE_USER  = ${PW_APACHE_USER}"
echo "  PW_DESKTOP_USER = ${DESKTOP_USER}"
echo "  PW_OS_TYPE      = ${PW_OS_TYPE}"
echo "  PW_PROJECT_ROOT = ${PROJECT_ROOT}"
echo "  PW_PROJECT_NAME = ${PW_PROJECT_NAME}"
echo "  PW_PLAYROOT     = ${PLAYROOT}"
echo
echo "[01] Saved persistent env file:"
echo "     ${ENV_FILE}"
