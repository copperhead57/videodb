#!/usr/bin/env bash
set -euo pipefail

echo "[03] Configuring sudo rules..."

# ------------------------------------------------------------
# Load persistent environment file
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${PLAYROOT}/playwright-env.sh"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[FAIL] Missing environment file: $ENV_FILE"
    exit 1
fi

# Load authoritative environment
source "$ENV_FILE"

# ------------------------------------------------------------
# Use authoritative project name from environment file
# ------------------------------------------------------------
PROJECT_NAME="${PW_PROJECT_NAME}"

# ------------------------------------------------------------
# Paths to allowed commands
# ------------------------------------------------------------
NODE_BIN="/usr/bin/node"
WRAPPER="${PW_PLAYROOT}/imdb-fetch-headless.sh"
FETCHER="${PW_PLAYROOT}/imdb-fetch-unix-headless.mjs"

# ------------------------------------------------------------
# Tier-1 and Tier-2 sudoers paths
# ------------------------------------------------------------
GLOBAL_SUDOERS="/etc/sudoers.d/${PW_DESKTOP_USER}-playwright"
SUDOERS_FILE="/etc/sudoers.d/${PW_DESKTOP_USER}-playwright-${PROJECT_NAME}-${PW_ENVIRONMENT}"

echo
echo "------------------------------------------------------------"
echo " PREVIEW — Sudo rules that will be applied"
echo "------------------------------------------------------------"
echo "Desktop user:       $PW_DESKTOP_USER"
echo "Apache user:        $PW_APACHE_USER"
echo "Project name:       $PROJECT_NAME"
echo "Environment:        $PW_ENVIRONMENT"
echo
echo "Tier-1 sudoers:     $GLOBAL_SUDOERS"
echo "Tier-2 sudoers:     $SUDOERS_FILE"
echo
echo "Allowed commands:"
echo "  $NODE_BIN"
echo "  $FETCHER"
echo
echo "Press ENTER to continue, or CTRL+C to abort..."
read -r _

# ------------------------------------------------------------
# Ensure fetcher exists
# ------------------------------------------------------------
if [[ ! -f "$FETCHER" ]]; then
    echo "[FAIL] Missing fetcher script: $FETCHER"
    exit 1
fi

# ------------------------------------------------------------
# Apply ownership + permissions to wrapper fetcher
# ------------------------------------------------------------
echo "  Setting ownership and permissions on fetcher..."

for f in "$WRAPPER" "$FETCHER"; do
    if [[ -f "$f" ]]; then
        chown "$PW_DESKTOP_USER":"$PW_APACHE_USER" "$f"
        chmod 770 "$f"
        echo "    * $(basename "$f") → owner=$PW_DESKTOP_USER group=$PW_APACHE_USER perm=770"
    else
        echo "    * Missing: $f"
    fi
done

# ------------------------------------------------------------
# Tier-1: global sudoers (marker, no rules)
# ------------------------------------------------------------
echo "  Ensuring Tier-1 global sudoers file exists..."

if [[ ! -f "$GLOBAL_SUDOERS" ]]; then
    sudo bash -c "cat > '$GLOBAL_SUDOERS' <<EOF
# Global Playwright sudo namespace
# Desktop user: $PW_DESKTOP_USER
#
# This file intentionally contains no rules.
# Project-specific rules live in:
#   /etc/sudoers.d/${PW_DESKTOP_USER}-playwright-<project>-<env>
EOF"
    sudo chmod 440 "$GLOBAL_SUDOERS"
    echo "  Created Tier-1 sudoers: $GLOBAL_SUDOERS"
else
    echo "  Tier-1 sudoers already present: $GLOBAL_SUDOERS"
fi

# ------------------------------------------------------------
# Tier-2: project-specific sudoers
# ------------------------------------------------------------
echo "  Writing Tier-2 project sudoers file..."

sudo bash -c "cat > '$SUDOERS_FILE' <<EOF
# Project-specific Playwright sudo rules
# Desktop user: $PW_DESKTOP_USER
# Project:      $PROJECT_NAME
# Environment:  $PW_ENVIRONMENT

# Allow Apache user to run Node as $PW_DESKTOP_USER
$PW_APACHE_USER ALL=($PW_DESKTOP_USER) NOPASSWD: $NODE_BIN

# Allow Apache user to run the fetcher as $PW_DESKTOP_USER
$PW_APACHE_USER ALL=($PW_DESKTOP_USER) NOPASSWD: $FETCHER

# Allow Apache user to run the wrapper as $PW_DESKTOP_USER
$PW_APACHE_USER ALL=($PW_DESKTOP_USER) NOPASSWD: $WRAPPER *
EOF"

sudo chmod 440 "$SUDOERS_FILE"
echo "  Created Tier-2 sudoers: $SUDOERS_FILE"

# ------------------------------------------------------------
# Validate sudoers
# ------------------------------------------------------------
echo "  Validating sudoers..."
sudo visudo -c >/dev/null

echo "[03] Sudo setup complete."
