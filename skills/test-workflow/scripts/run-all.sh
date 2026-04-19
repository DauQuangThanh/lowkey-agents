#!/bin/bash
# =============================================================================
# run-all.sh — Orchestrator: Runs all 4 testing phases in sequence
# Executes: test-planning → test-case-design → test-execution → test-report
# Output: All test artifacts in test-output/ plus consolidated debts
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
tst_parse_flags "$@"


# ── Header ────────────────────────────────────────────────────────────────────
tst_banner "🧪  TESTER WORKFLOW — Complete Testing Lifecycle"
tst_dim "  This will run all 4 phases: Planning → Design → Execution → Report"
tst_dim "  Estimated time: 30–60 minutes depending on project scope."
echo ""

if tst_is_auto; then
  HAS_CONFIRMED="yes"
else
  HAS_CONFIRMED=$(tst_ask_yn "Ready to begin the complete testing workflow?")
fi
if [ "$HAS_CONFIRMED" != "yes" ]; then
  echo "  Cancelled."
  exit 0
fi

echo ""

# ── Phase 1: Test Planning ────────────────────────────────────────────────────
printf '%b%bPhase 1 / 4 — Test Planning%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Running: bash <SKILL_DIR>/test-planning/scripts/plan.sh"
echo ""

PLANNING_SCRIPT="$SCRIPT_DIR/../../test-planning/scripts/plan.sh"
if [ -f "$PLANNING_SCRIPT" ]; then
  bash "$PLANNING_SCRIPT"
else
  tst_dim "  ⚠  Script not found. Skipping Phase 1."
fi

echo ""
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TST_MAGENTA" "$TST_NC"
echo ""

# ── Phase 2: Test Case Design ────────────────────────────────────────────────
printf '%b%bPhase 2 / 4 — Test Case Design%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Running: bash <SKILL_DIR>/test-case-design/scripts/design-cases.sh"
echo ""

DESIGN_SCRIPT="$SCRIPT_DIR/../../test-case-design/scripts/design-cases.sh"
if [ -f "$DESIGN_SCRIPT" ]; then
  bash "$DESIGN_SCRIPT"
else
  tst_dim "  ⚠  Script not found. Skipping Phase 2."
fi

echo ""
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TST_MAGENTA" "$TST_NC"
echo ""

# ── Phase 3: Test Execution ───────────────────────────────────────────────────
printf '%b%bPhase 3 / 4 — Test Execution & Bug Tracking%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Running: bash <SKILL_DIR>/test-execution/scripts/execute.sh"
echo ""

EXECUTION_SCRIPT="$SCRIPT_DIR/../../test-execution/scripts/execute.sh"
if [ -f "$EXECUTION_SCRIPT" ]; then
  bash "$EXECUTION_SCRIPT"
else
  tst_dim "  ⚠  Script not found. Skipping Phase 3."
fi

echo ""
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TST_MAGENTA" "$TST_NC"
echo ""

# ── Phase 4: Test Summary Report ──────────────────────────────────────────────
printf '%b%bPhase 4 / 4 — Test Summary Report & Release Recommendation%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Running: bash <SKILL_DIR>/test-report/scripts/report.sh"
echo ""

REPORT_SCRIPT="$SCRIPT_DIR/../../test-report/scripts/report.sh"
if [ -f "$REPORT_SCRIPT" ]; then
  bash "$REPORT_SCRIPT"
else
  tst_dim "  ⚠  Script not found. Skipping Phase 4."
fi

echo ""
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TST_MAGENTA" "$TST_NC"
echo ""

# ── Completion ────────────────────────────────────────────────────────────────
tst_success_rule "✅ TESTER WORKFLOW COMPLETE"

tst_dim "All test artifacts have been created in: $TEST_OUTPUT_DIR"
echo ""
tst_dim "Output files:"
ls -1 "$TEST_OUTPUT_DIR"/*.md 2>/dev/null | sed 's/^/  /'
echo ""

DEBT_COUNT=$(tst_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '%b⚠  %d test quality debt(s) recorded.%b\n' "$TST_YELLOW" "$DEBT_COUNT" "$TST_NC"
  tst_dim "Review: $TST_DEBT_FILE"
  echo ""
fi

tst_dim "Next steps:"
tst_dim "  1. Review: $TEST_OUTPUT_DIR/01-test-plan.md"
tst_dim "  2. Review: $TEST_OUTPUT_DIR/02-test-cases.md"
tst_dim "  3. Review: $TEST_OUTPUT_DIR/03-test-execution.md"
tst_dim "  4. Review: $TEST_OUTPUT_DIR/TESTER-FINAL.md (executive summary)"
echo ""
