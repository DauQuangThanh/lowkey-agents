#!/bin/bash
# =============================================================================
# run-all.sh — Orchestrator: Run all Code Security Review phases (1–5)
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
csr_parse_flags "$@"


csr_banner "CODE SECURITY REVIEW WORKFLOW — ALL PHASES"

printf '%bExecuting Phases 1–5 of the Code Security Review...%b\n\n' "$CSR_CYAN" "$CSR_NC"

PHASES=(
  "Phase 1: Vulnerability Assessment" "bash $SCRIPT_DIR/../../csr-vulnerability/scripts/vulnerability.sh"
  "Phase 2: Authentication & Authorization Review" "bash $SCRIPT_DIR/../../csr-auth-review/scripts/auth-review.sh"
  "Phase 3: Data Protection & Privacy Review" "bash $SCRIPT_DIR/../../csr-data-protection/scripts/data-protection.sh"
  "Phase 4: Dependency & Supply Chain Audit" "bash $SCRIPT_DIR/../../csr-dependency-audit/scripts/dependency-audit.sh"
  "Phase 5: Security Report & Remediation Plan" "bash $SCRIPT_DIR/../../csr-report/scripts/report.sh"
)

FAILED=0
for ((i=0; i<${#PHASES[@]}; i+=2)); do
  phase_name="${PHASES[$i]}"
  phase_cmd="${PHASES[$((i+1))]}"

  printf '%b%s%b\n' "$CSR_CYAN$CSR_BOLD" "$phase_name" "$CSR_NC"

  if eval "$phase_cmd"; then
    printf '%b✓ %s completed successfully%b\n\n' "$CSR_GREEN" "$phase_name" "$CSR_NC"
  else
    printf '%b✗ %s failed%b\n\n' "$CSR_RED" "$phase_name" "$CSR_NC"
    ((FAILED++))
  fi
done

printf '\n'

if [ "$FAILED" -eq 0 ]; then
  csr_success_rule "ALL PHASES COMPLETE - Code Security Review finished successfully!"
  printf '%b\nOutput files:%b\n' "$CSR_GREEN" "$CSR_NC"
  ls -lh "$CSR_OUTPUT_DIR"/*.md 2>/dev/null | awk '{print "  " $NF}'
  printf '\n%bNext: Review CSR-FINAL.md and create remediation tickets.%b\n\n' "$CSR_CYAN" "$CSR_NC"
else
  printf '%b%d phase(s) failed. Review logs above for details.%b\n\n' "$CSR_RED" "$FAILED" "$CSR_NC"
  exit 1
fi
