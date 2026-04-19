#!/bin/bash
# Source-shim — delegates to the canonical _common.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../ux-research/scripts/_common.sh"
