#!/bin/bash
# xvfb.sh - run any command inside a temporary Xvfb display
# Usage: xvfb.sh <command> [args...]
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 2
fi

# Resolve this script's directory
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Project-local HOME for Chromium (required for headed mode)
export HOME="$BASE_DIR/chrome-home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Run the command inside a temporary Xvfb display
exec xvfb-run --auto-servernum --server-args='-screen 0 1920x1080x24' "$@"
