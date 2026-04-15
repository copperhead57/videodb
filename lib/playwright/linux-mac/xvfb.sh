#!/bin/bash
# xvfb.sh - run any command inside a temporary Xvfb display
# Usage: xvfb.sh <command> [args...]
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 2
fi

# Build the command to run under xvfb-run
# "$@" preserves all arguments (command + its args)
exec xvfb-run --auto-servernum --server-args='-screen 0 1920x1080x24' "$@"
