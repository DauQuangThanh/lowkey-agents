#!/bin/bash
# =============================================================================
# plan.sh — Phase 1: Test Planning
# Defines test scope, levels, approach, environments, entry/exit criteria,
# risk-based priorities, and schedule.
# Output: $TEST_OUTPUT_DIR/01-test-plan.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
tst_parse_flags "$@"


OUTPUT_FILE="$TEST_OUTPUT_DIR/01-test-plan.md"
AREA="Test Planning"

start_debts=$(tst_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
tst_banner "🧪  Step 1 of 4 — Test Planning"
tst_dim "  Let's define your test strategy. I'll ask you eight simple questions."
tst_dim "  There are no wrong answers — just share what you know."
echo ""

# ── Q1: Test scope ────────────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 8 — Test Scope%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Which user stories or features are in scope for testing?"
tst_dim "  Example: 'Login, user profile, payment checkout, reporting'"
echo ""
TEST_SCOPE=$(tst_ask "Your answer:")
if [ -z "$TEST_SCOPE" ]; then
  TEST_SCOPE="To be defined"
  tst_add_debt "$AREA" "Test scope not defined" \
    "Which user stories and features are in testing scope is not documented" \
    "Test case design and coverage planning"
fi

# ── Q2: Test levels ──────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 8 — Test Levels%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Which test levels do you need?"
echo ""
TEST_LEVELS=$(tst_ask_choice "Select all that apply (enter numbers separated by space, or 5 for all):" \
  "Unit Testing — individual functions and modules" \
  "Integration Testing — modules working together" \
  "System Testing — end-to-end workflows" \
  "User Acceptance Testing (UAT) — business users validate" \
  "All of the above")

# ── Q3: Test approach ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 8 — Test Approach%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  How will testing be executed?"
echo ""
TEST_APPROACH=$(tst_ask_choice "Select one:" \
  "All manual — testers execute every test by hand" \
  "Mostly manual with some automation — 70% manual, 30% automated" \
  "Hybrid — 50% manual, 50% automated" \
  "Mostly automated — 30% manual, 70% automated")

# ── Q4: Test environments ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 8 — Test Environments%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What environments are available for testing?"
tst_dim "  Example: 'Development, Staging, UAT, Production (read-only)'"
echo ""
TEST_ENVS=$(tst_ask "Your answer:")
if [ -z "$TEST_ENVS" ]; then
  TEST_ENVS="TBD"
  tst_add_debt "$AREA" "Test environments not specified" \
    "Available test environments (Dev, Staging, UAT) are not documented" \
    "Test execution planning and data refresh strategy"
fi

# ── Q5: Entry criteria ────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 8 — Entry Criteria%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What must be true before testing can START?"
tst_dim "  Example: 'Code is built, test data is prepared, builds are stable'"
echo ""
ENTRY_CRITERIA=$(tst_ask "Your answer:")
if [ -z "$ENTRY_CRITERIA" ]; then
  ENTRY_CRITERIA="TBD"
  tst_add_debt "$AREA" "Entry criteria not defined" \
    "Conditions for starting testing are not documented" \
    "Test readiness assessment and schedule"
fi

# ── Q6: Exit criteria ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 8 — Exit Criteria%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What must be true for testing to be COMPLETE and ready for release?"
tst_dim "  Example: 'All critical tests pass, all P1 bugs fixed, coverage >= 95%'"
echo ""
EXIT_CRITERIA=$(tst_ask "Your answer:")
if [ -z "$EXIT_CRITERIA" ]; then
  EXIT_CRITERIA="TBD"
  tst_add_debt "$AREA" "Exit criteria not defined" \
    "Conditions for completing testing and releasing are not documented" \
    "Release readiness assessment"
fi

# ── Q7: Risk-based priorities ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 7 / 8 — Risk-Based Priorities%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Which features or workflows are highest RISK and need the most testing?"
tst_dim "  Example: 'Login (critical), payment (high), UI polish (low)'"
echo ""
PRIORITIES=$(tst_ask "Your answer:")
if [ -z "$PRIORITIES" ]; then
  PRIORITIES="TBD"
  tst_add_debt "$AREA" "Risk priorities not identified" \
    "Which features are highest risk and need most test coverage is not clear" \
    "Test case prioritization and resource allocation"
fi

# ── Q8: Testing schedule ──────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 8 / 8 — Testing Schedule%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Estimate the total testing effort (in hours or days)."
tst_dim "  Example: 'Unit: 8h, Integration: 12h, System: 24h, UAT: 16h = 60h total'"
echo ""
SCHEDULE=$(tst_ask "Your answer:")
if [ -z "$SCHEDULE" ]; then
  SCHEDULE="TBD"
  tst_add_debt "$AREA" "Testing schedule not estimated" \
    "Total effort and timeline for testing is not documented" \
    "Sprint planning and resource allocation"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
tst_success_rule "✅ Test Planning Summary"
printf '  %bScope:%b         %s\n' "$TST_BOLD" "$TST_NC" "$TEST_SCOPE"
printf '  %bLevels:%b        %s\n' "$TST_BOLD" "$TST_NC" "$TEST_LEVELS"
printf '  %bApproach:%b      %s\n' "$TST_BOLD" "$TST_NC" "$TEST_APPROACH"
printf '  %bEnvironments:%b  %s\n' "$TST_BOLD" "$TST_NC" "$TEST_ENVS"
printf '  %bEntry Criteria:%b %s\n' "$TST_BOLD" "$TST_NC" "$ENTRY_CRITERIA"
printf '  %bExit Criteria:%b  %s\n' "$TST_BOLD" "$TST_NC" "$EXIT_CRITERIA"
printf '  %bPriorities:%b    %s\n' "$TST_BOLD" "$TST_NC" "$PRIORITIES"
printf '  %bSchedule:%b      %s\n' "$TST_BOLD" "$TST_NC" "$SCHEDULE"
echo ""

if ! tst_confirm_save "Does this look correct? (y=save / n=redo)"; then
  tst_dim "  Restarting step 1..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Test Plan"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Test Scope"
  echo ""
  echo "**In Scope:**"
  echo "$TEST_SCOPE"
  echo ""
  echo "## Test Levels"
  echo ""
  echo "$TEST_LEVELS"
  echo ""
  echo "## Test Approach"
  echo ""
  echo "$TEST_APPROACH"
  echo ""
  echo "## Test Environments"
  echo ""
  echo "$TEST_ENVS"
  echo ""
  echo "## Entry Criteria"
  echo ""
  echo "$ENTRY_CRITERIA"
  echo ""
  echo "## Exit Criteria"
  echo ""
  echo "$EXIT_CRITERIA"
  echo ""
  echo "## Risk-Based Priorities"
  echo ""
  echo "$PRIORITIES"
  echo ""
  echo "## Testing Schedule"
  echo ""
  echo "$SCHEDULE"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(tst_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$TST_GREEN" "$OUTPUT_FILE" "$TST_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d test quality debt(s) logged to: %s%b\n' "$TST_YELLOW" "$new_debts" "$TST_DEBT_FILE" "$TST_NC"
fi
echo ""
