#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/check-env.sh"
source "$SCRIPT_DIR/lib/api.sh"

check_required_vars CODEBERG_TOKEN REPO_OWNER REPO_NAME

PRS=$(get_open_pulls)
echo "prs<<EOF"
echo "$PRS"
echo "EOF"
