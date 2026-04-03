#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/check-env.sh"

DB_FILE="${1:-${DB_FILE:-}}"
check_required_vars DB_FILE

if [ -f "$DB_FILE" ]; then
    cat "$DB_FILE"
else
    echo "{}"
fi