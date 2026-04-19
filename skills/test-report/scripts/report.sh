#!/bin/bash
# =============================================================================
# report.sh — Phase 4: Test Summary Report & Validation
# Analyzes test coverage, metrics, open defects, and generates release
# recommendation. Produces detailed report + executive summary.
# Output: $TEST_OUTPUT_DIR/04-test-report.md + TESTER-FINAL.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
tst_parse_flags "$@"


OUTPUT_FILE="$TEST_OUTPUT_DIR/04-test-report.md"
FINAL_FILE="$TEST_OUTPUT_DIR/TESTER-FINAL.md"
AREA="Test Report"

start_debts=$(tst_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
tst_banner "📊  Step 4 of 4 — Test Summary Report"
tst_dim "  Let's create a final test summary and release recommendation."
echo ""

# ── Q1: Coverage percentage ───────────────────────────────────────────────────
printf '%b%bQuestion 1 / 2 — Test Coverage%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What percentage of requirements were tested?"
tst_dim "  (Target: 95%+ for critical, 80%+ for others)"
echo ""
COVERAGE=$(tst_ask "Coverage %:")
if [ -z "$COVERAGE" ]; then
  COVERAGE="TBD"
  tst_add_debt "$AREA" "Coverage percentage not recorded" \
    "Test coverage percentage not documented" \
    "Release readiness assessment"
fi

# ── Q2: Release recommendation ────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 2 — Release Readiness%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Can we release this software to production?"
echo ""
RELEASE_READY=$(tst_ask_choice "Select one:" \
  "YES — Ready to release" \
  "CONDITIONAL — Ready if P0/P1 bugs fixed" \
  "NO — Not ready (blockers remain)")

# ── Summary ───────────────────────────────────────────────────────────────────
tst_success_rule "✅ Test Report Summary"
printf '  %bCoverage:%b          %s\n' "$TST_BOLD" "$TST_NC" "$COVERAGE"
printf '  %bRelease Status:%b    %s\n' "$TST_BOLD" "$TST_NC" "$RELEASE_READY"
echo ""

if ! tst_confirm_save "Does this look correct? (y=save / n=redo)"; then
  tst_dim "  Restarting step 4..."
  exec bash "$0"
fi

# ── Write detailed report ─────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Test Summary Report"
  echo ""
  echo "> Report Date: $DATE_NOW"
  echo ""
  echo "## Executive Summary"
  echo ""
  echo "**Overall Test Result:** $RELEASE_READY"
  echo "**Coverage:** $COVERAGE"
  echo ""
  echo "## Test Metrics"
  echo ""
  echo "### Coverage"
  echo ""
  echo "- Functional Requirements tested: [Add from execution report]"
  echo "- Non-Functional Requirements tested: [Add from execution report]"
  echo "- Overall coverage: $COVERAGE"
  echo ""
  echo "### Test Results"
  echo ""
  echo "| Status | Count | % |"
  echo "|---|---|---|"
  echo "| Passed | [Add count] | [Add %] |"
  echo "| Failed | [Add count] | [Add %] |"
  echo "| Blocked | [Add count] | [Add %] |"
  echo ""
  echo "### Defects"
  echo ""
  echo "| Severity | Count | Status |"
  echo "|---|---|---|"
  echo "| Critical | [Add count] | [Add status] |"
  echo "| High | [Add count] | [Add status] |"
  echo "| Medium | [Add count] | [Add status] |"
  echo "| Low | [Add count] | [Add status] |"
  echo ""
  echo "## Open Issues"
  echo ""
  echo "### Critical Blockers"
  echo ""
  echo "[List P0 bugs and blockers, if any]"
  echo ""
  echo "### Blocked Tests"
  echo ""
  echo "[List blocked tests and what's blocking them]"
  echo ""
  echo "## Test Quality Debts"
  echo ""
  echo "[Auto-populated from 05-test-debts.md]"
  echo ""
  echo "## Release Recommendation"
  echo ""
  echo "**Status:** $RELEASE_READY"
  echo ""
  echo "**Next Steps:**"
  echo "- [Action 1]"
  echo "- [Action 2]"
  echo "- [Action 3]"
  echo ""
} > "$OUTPUT_FILE"

# ── Write executive summary ───────────────────────────────────────────────────
{
  echo "# Test Summary — Executive Report"
  echo ""
  echo "> Date: $DATE_NOW"
  echo ""
  echo "## Release Readiness"
  echo ""
  echo "**Status:** $RELEASE_READY"
  echo ""
  echo "| Metric | Target | Achieved | Status |"
  echo "|---|---|---|---|"
  echo "| Coverage | 95%+ | $COVERAGE | [✓/⚠/✗] |"
  echo "| Pass Rate | 90%+ | [Add %] | [✓/⚠/✗] |"
  echo "| P0 Bugs | 0 | [Add count] | [✓/✗] |"
  echo "| Blockers | 0 | [Add count] | [✓/✗] |"
  echo ""
  echo "## Summary"
  echo ""
  echo "[Add 2–3 sentence summary of test results, key findings, and recommendation]"
  echo ""
  echo "## Next Steps"
  echo ""
  echo "- [Top priority action]"
  echo "- [Second priority]"
  echo "- [Third priority]"
  echo ""
} > "$FINAL_FILE"

end_debts=$(tst_current_debt_count)
new_debts=$((end_debts - start_debts))

tst_success_rule "✅ Test Reports Complete"
printf '%b  Detailed report: %s%b\n' "$TST_GREEN" "$OUTPUT_FILE" "$TST_NC"
printf '%b  Executive summary: %s%b\n' "$TST_GREEN" "$FINAL_FILE" "$TST_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d test quality debt(s) logged to: %s%b\n' "$TST_YELLOW" "$new_debts" "$TST_DEBT_FILE" "$TST_NC"
fi
echo ""
