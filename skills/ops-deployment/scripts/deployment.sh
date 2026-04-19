#!/bin/bash

# OPS Skill: ops-deployment (Phase 5)
# Deployment Strategy Design

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ops_parse_flags "$@"


OUTPUT_FILE="$OPS_OUTPUT_DIR/05-deployment-strategy.md"

ops_banner "Phase 5: Deployment Strategy Design"

ops_ask_choice "Deployment Pattern?" \
    "Rolling (gradual replacement)" \
    "Blue-green (parallel environments)" \
    "Canary (traffic %-based)" \
    "Recreate (with downtime)" \
    "A-B testing" > /dev/null

{
    cat <<'EOF'
# Phase 5: Deployment Strategy Design

## Status

This is a placeholder. Full implementation includes:

1. **Deployment Pattern** - Rolling, blue-green, canary, recreate, A-B
2. **Rollback Strategy** - Instant, gradual, database snapshot
3. **Database Migrations** - Expand-contract, zero-downtime, maintenance window
4. **Feature Flags** - LaunchDarkly, Unleash, custom, none
5. **Zero-Downtime Requirements** - 24/7, business hours, windows
6. **Deployment Window** - Continuous, scheduled, on-demand, weekly
7. **Smoke Test Strategy** - Synthetic, canary, manual, automated e2e
8. **Disaster Recovery** - RTO/RPO targets, backup frequency, failover

## Deployment Patterns

- **Rolling**: Gradual replacement, no downtime, slower
- **Blue-Green**: Parallel environments, instant cutover, 2x cost
- **Canary**: Production testing, detected issues early
- **Recreate**: Simple, downtime-based, risky

## Next Steps

Run the full skill for complete deployment strategy design.

EOF
} > "$OUTPUT_FILE"

ops_success_rule "Deployment strategy placeholder written to $OUTPUT_FILE"
echo ""
echo "Next: Run ops-environment skill."
echo ""
