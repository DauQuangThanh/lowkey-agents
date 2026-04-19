#!/bin/bash
# =============================================================================
# run-all.sh — Reverse Engineering Workflow Orchestrator
# Runs all 6 RE phases sequentially and compiles RE-FINAL.md.
# =============================================================================

# Step 1: parse --auto / --answers flags
while [ $# -gt 0 ]; do
  case "$1" in
    --auto)       RE_AUTO=1; export RE_AUTO; shift ;;
    --answers)    RE_ANSWERS="${2:-}"; export RE_ANSWERS; shift 2 ;;
    --answers=*)  RE_ANSWERS="${1#--answers=}"; export RE_ANSWERS; shift ;;
    *)            shift ;;
  esac
done

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Phase 0: RE Workflow Orchestrator"
echo ""

# Run each phase. Phases are designed to tolerate missing upstream output
# (they log a debt and continue), so a failure in one phase doesn't abort
# the chain.
bash "$SCRIPT_DIR/../../re-codebase-scan/scripts/codebase-scan.sh"         || true
bash "$SCRIPT_DIR/../../re-architecture-extraction/scripts/architecture.sh" || true
bash "$SCRIPT_DIR/../../re-api-documentation/scripts/api-docs.sh"           || true
bash "$SCRIPT_DIR/../../re-data-model/scripts/data-model.sh"                || true
bash "$SCRIPT_DIR/../../re-dependency-analysis/scripts/dependency-analysis.sh" || true
bash "$SCRIPT_DIR/../../re-documentation-gen/scripts/doc-gen.sh"            || true

echo ""
echo "RE Workflow Complete. Outputs in ${RE_OUTPUT_DIR:-./re-output}/"
