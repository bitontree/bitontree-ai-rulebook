#!/usr/bin/env bash
# Bitontree rulebook installer — macOS double-click launcher.
# macOS opens .command files in Terminal automatically. This wraps install-global.sh
# and pauses at the end so the window doesn't close before you read the output.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Bitontree rulebook installer (macOS double-click launcher)"
echo

set +e
"${SCRIPT_DIR}/install-global.sh" "$@"
exit_code=$?
set -e

echo
read -r -p "Press Enter to close..." _
exit "${exit_code}"
