#!/bin/bash
# Source-shim — delegates to the canonical bf-triage/_common.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../bf-triage/scripts/_common.sh"
