#!/bin/bash

# OPS Skill: ops-environment (Phase 6)
# Environment Management Design

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ops_parse_flags "$@"


OUTPUT_FILE="$OPS_OUTPUT_DIR/06-environment-plan.md"

ops_banner "Phase 6: Environment Management Design"

ops_ask_choice "How many environments?" \
    "dev + staging + prod (3)" \
    "dev + qa + staging + prod (4)" \
    "dev + qa + staging + pre-prod + prod (5)" \
    "Custom" > /dev/null

{
    cat <<'EOF'
# Phase 6: Environment Management Design

## Status

This is a placeholder. Full implementation includes:

1. **Environment Definitions** - dev, QA, staging, pre-prod, prod
2. **Environment Parity** - Identical, right-sized, custom
3. **Configuration Management** - Env vars, config files, config server, ConfigMap
4. **Access Control** - Role-based (developer/QA/ops/admin)
5. **Data Management** - Seeding, masking, refresh cadence
6. **Environment Provisioning** - Fully automated, semi-automated, manual

## Environment Matrix

| Name | Purpose | Replicas | CPU | Memory | Access |
|------|---------|----------|-----|--------|--------|
| dev | Developer testing | 1 | 0.5 | 512Mi | All engineers |
| qa | QA testing | 1 | 1 | 1Gi | QA + engineers |
| staging | Production-like | 2 | 1 | 2Gi | QA + ops + PM |
| prod | Live traffic | 3+ | 2+ | 4Gi+ | Ops + on-call |

## Next Steps

Run the full skill for complete environment management design.

EOF
} > "$OUTPUT_FILE"

ops_success_rule "Environment plan placeholder written to $OUTPUT_FILE"
echo ""
echo "All phases complete. Run ops-workflow to compile final handbook."
echo ""
