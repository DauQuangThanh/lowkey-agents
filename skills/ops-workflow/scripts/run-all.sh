#!/bin/bash

# OPS Orchestrator: ops-workflow (Phase 0)
# Run all phases 1-6 and compile final handbook

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
ops_parse_flags "$@"


FINAL_OUTPUT="$OPS_OUTPUT_DIR/OPS-FINAL.md"
SKILLS_BASE="$(dirname "$(dirname "$SCRIPT_DIR")")"

ops_banner "DevOps Orchestrator: Full Workflow"

echo -e "${OPS_CYAN}Welcome to the DevOps Orchestration Workflow!${OPS_NC}"
echo ""
echo "This workflow will guide you through designing a complete DevOps strategy:"
echo "  Phase 1: CI/CD Pipeline Design"
echo "  Phase 2: Infrastructure as Code"
echo "  Phase 3: Containerization & Orchestration"
echo "  Phase 4: Monitoring & Observability"
echo "  Phase 5: Deployment Strategy"
echo "  Phase 6: Environment Management"
echo ""
echo "Total time: ~60-90 minutes (15 min per phase)"
echo ""

if ! ops_ask_yn "Ready to start the full workflow?"; then
    echo "Exiting. You can run individual skills later."
    exit 0
fi

# Phase 1: CI/CD
echo ""
if ops_ask_yn "Run Phase 1: CI/CD Pipeline Design?"; then
    echo "Launching ops-cicd..."
    bash "$SKILLS_BASE/ops-cicd/scripts/cicd.sh" || true
else
    echo "Skipped Phase 1"
fi

# Phase 2: Infrastructure
echo ""
if ops_ask_yn "Run Phase 2: Infrastructure as Code?"; then
    echo "Launching ops-infrastructure..."
    bash "$SKILLS_BASE/ops-infrastructure/scripts/infrastructure.sh" || true
else
    echo "Skipped Phase 2"
fi

# Phase 3: Containerization
echo ""
if ops_ask_yn "Run Phase 3: Containerization & Orchestration?"; then
    echo "Launching ops-containerization..."
    bash "$SKILLS_BASE/ops-containerization/scripts/containerization.sh" || true
else
    echo "Skipped Phase 3"
fi

# Phase 4: Monitoring
echo ""
if ops_ask_yn "Run Phase 4: Monitoring & Observability?"; then
    echo "Launching ops-monitoring..."
    bash "$SKILLS_BASE/ops-monitoring/scripts/monitoring.sh" || true
else
    echo "Skipped Phase 4"
fi

# Phase 5: Deployment
echo ""
if ops_ask_yn "Run Phase 5: Deployment Strategy?"; then
    echo "Launching ops-deployment..."
    bash "$SKILLS_BASE/ops-deployment/scripts/deployment.sh" || true
else
    echo "Skipped Phase 5"
fi

# Phase 6: Environment
echo ""
if ops_ask_yn "Run Phase 6: Environment Management?"; then
    echo "Launching ops-environment..."
    bash "$SKILLS_BASE/ops-environment/scripts/environment.sh" || true
else
    echo "Skipped Phase 6"
fi

# Compile final output
ops_banner "Compiling Final DevOps Handbook"

{
    echo "# OPS-FINAL: Complete DevOps Strategy Handbook"
    echo ""
    echo "**Generated**: $(date -u '+%Y-%m-%d %H:%M UTC')"
    echo ""
    echo "## Executive Summary"
    echo ""
    echo "This comprehensive DevOps handbook consolidates all design decisions across six operational phases."
    echo ""
    echo "---"
    echo ""
    echo "## Phase Outputs"
    echo ""

    for phase in 01-cicd-pipeline 02-infrastructure 03-containerization 04-monitoring 05-deployment-strategy 06-environment-plan; do
        phase_file="$OPS_OUTPUT_DIR/${phase}.md"
        if [ -f "$phase_file" ]; then
            echo "### Phase: ${phase//-/ }"
            echo ""
            echo "\`\`\`"
            head -20 "$phase_file" | sed 's/^/  /'
            echo "\`\`\`"
            echo ""
            echo "[See full details in $phase_file]"
            echo ""
        fi
    done

    echo "---"
    echo ""
    echo "## OPS Debt Tracker"
    echo ""

    if [ -f "$OPS_DEBT_FILE" ]; then
        echo "### Tracked Debt Items"
        echo ""
        cat "$OPS_DEBT_FILE" | tail -50
        echo ""
    else
        echo "No debt items tracked yet."
        echo ""
    fi

    echo "---"
    echo ""
    echo "## Implementation Roadmap"
    echo ""
    echo "### Immediate (Week 1)"
    echo "- [ ] Set up CI/CD pipeline repository"
    echo "- [ ] Configure artifact storage"
    echo "- [ ] Create deployment scripts"
    echo ""
    echo "### Short-term (Month 1)"
    echo "- [ ] Implement Infrastructure-as-Code"
    echo "- [ ] Set up containerization (if applicable)"
    echo "- [ ] Configure monitoring and alerting"
    echo ""
    echo "### Medium-term (Month 3)"
    echo "- [ ] Implement deployment strategy"
    echo "- [ ] Set up multi-environment management"
    echo "- [ ] Establish on-call rotation"
    echo ""
    echo "### Long-term (Quarter 2+)"
    echo "- [ ] Optimize DORA metrics"
    echo "- [ ] Implement disaster recovery"
    echo "- [ ] Continuous improvement and debt paydown"
    echo ""
    echo "---"
    echo ""
    echo "## Quick Reference"
    echo ""
    echo "### Key Files"
    echo "- \`$OPS_OUTPUT_DIR/01-cicd-pipeline.md\` - CI/CD architecture"
    echo "- \`$OPS_OUTPUT_DIR/02-infrastructure.md\` - IaC strategy"
    echo "- \`$OPS_OUTPUT_DIR/03-containerization.md\` - Container orchestration"
    echo "- \`$OPS_OUTPUT_DIR/04-monitoring.md\` - Observability setup"
    echo "- \`$OPS_OUTPUT_DIR/05-deployment-strategy.md\` - Deployment patterns"
    echo "- \`$OPS_OUTPUT_DIR/06-environment-plan.md\` - Environment management"
    echo "- \`$OPS_DEBT_FILE\` - Debt tracker"
    echo ""
    echo "### Commands"
    echo "- Run single phase: \`bash <SKILL_DIR>/ops-{cicd,infrastructure,containerization,monitoring,deployment,environment}/scripts/[*.sh|*.ps1]\`"
    echo "- View debt: \`cat $OPS_DEBT_FILE\`"
    echo "- View phase output: \`cat $OPS_OUTPUT_DIR/{01..06}-*.md\`"
    echo ""
    echo "---"
    echo ""
    echo "**Status**: Handbook compiled and ready for implementation."
    echo "**Next**: Share this handbook with your team and start Phase 1 implementation."

} > "$FINAL_OUTPUT"

ops_success_rule "Final handbook compiled: $FINAL_OUTPUT"

echo ""
echo "Summary:"
echo "  Output directory: $OPS_OUTPUT_DIR"
echo "  Final handbook: $FINAL_OUTPUT"
echo "  Debt tracker: $OPS_DEBT_FILE"
echo ""
echo "Next: Review $FINAL_OUTPUT and begin implementation."
echo ""
