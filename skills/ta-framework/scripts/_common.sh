#!/bin/bash
# Symlink to ta-strategy _common.sh
COMMON_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/ta-strategy/scripts/_common.sh"
[ -f "$COMMON_PATH" ] && source "$COMMON_PATH"
