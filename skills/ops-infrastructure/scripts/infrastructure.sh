#!/bin/bash

# OPS Skill: ops-infrastructure (Phase 2)
# Infrastructure as Code Design

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ops_parse_flags "$@"


OUTPUT_FILE="$OPS_OUTPUT_DIR/02-infrastructure.md"

ops_banner "Phase 2: Infrastructure as Code Design"

# Placeholder implementation - full version includes detailed questionnaire and IaC templates
ops_ask_choice "IaC Tool?" \
    "Terraform" \
    "Pulumi" \
    "CloudFormation" \
    "Bicep" \
    "Ansible" \
    "CDK" \
    "Not decided yet" > /dev/null

{
    cat <<'EOF'
# Phase 2: Infrastructure as Code Design

## Status

This is a placeholder. Full implementation includes:

1. **IaC Tool Selection** - Questions and rationale for each platform
2. **Resource Inventory** - Compute, storage, networking, database resources
3. **State Management** - Remote state configuration and locking strategy
4. **Module Structure** - Organizing IaC for scalability
5. **Secret Management** - Vault, AWS Secrets Manager, or Azure Key Vault
6. **Tagging Strategy** - Governance and cost tracking
7. **Cost Estimation** - Baseline and forecasting

## Next Steps

Run the full skill for complete IaC architecture design.

EOF
} > "$OUTPUT_FILE"

ops_success_rule "Infrastructure specification placeholder written to $OUTPUT_FILE"
echo ""
echo "Next: Run ops-containerization skill."
echo ""
