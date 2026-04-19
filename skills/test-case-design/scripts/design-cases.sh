#!/bin/bash
# =============================================================================
# design-cases.sh — Phase 2: Test Case Design
# Writes detailed test cases with positive, negative, and boundary scenarios.
# Output: $TEST_OUTPUT_DIR/02-test-cases.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
tst_parse_flags "$@"


OUTPUT_FILE="$TEST_OUTPUT_DIR/02-test-cases.md"
AREA="Test Case Design"

start_debts=$(tst_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
tst_banner "📝  Step 2 of 4 — Test Case Design"
tst_dim "  Let's write detailed test cases. I'll ask you several questions."
tst_dim "  Test cases will follow Given/When/Then format for clarity."
echo ""

# ── Q1: User story selection ──────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Which User Story?%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What is the user story or feature you want to test?"
tst_dim "  Example: 'US-01: User login with email and password'"
echo ""
USER_STORY=$(tst_ask "Your answer:")
if [ -z "$USER_STORY" ]; then
  USER_STORY="Unspecified User Story"
  tst_add_debt "$AREA" "User story not specified" \
    "Test case design started without selecting a user story" \
    "Test case coverage and traceability"
fi

# ── Q2: Positive scenarios ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — Positive Scenarios%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What are the happy-path workflows? (main success scenarios)"
tst_dim "  Example: 'Valid login, user redirected to dashboard'"
echo ""
POSITIVE=$(tst_ask "Your answer:")
if [ -z "$POSITIVE" ]; then
  POSITIVE="TBD"
  tst_add_debt "$AREA" "Positive scenarios not identified" \
    "Main success paths for this user story are not documented" \
    "Test case completeness and coverage"
fi

# ── Q3: Negative scenarios ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Negative Scenarios%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What error conditions must be handled?"
tst_dim "  Example: 'Invalid password, account locked, user not found'"
echo ""
NEGATIVE=$(tst_ask "Your answer:")
if [ -z "$NEGATIVE" ]; then
  NEGATIVE="TBD"
  tst_add_debt "$AREA" "Negative scenarios not identified" \
    "Error conditions and edge cases are not documented" \
    "Test case completeness and risk coverage"
fi

# ── Q4: Boundary scenarios ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Boundary Scenarios%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What edge cases should be tested?"
tst_dim "  Example: 'Empty password, 255-char email, SQL injection attempt'"
echo ""
BOUNDARY=$(tst_ask "Your answer:")
if [ -z "$BOUNDARY" ]; then
  BOUNDARY="TBD"
  tst_add_debt "$AREA" "Boundary scenarios not identified" \
    "Edge cases and limit testing scenarios are not documented" \
    "Test case completeness"
fi

# ── Q5: Test data requirements ────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — Test Data Requirements%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  What data is needed to run these test cases?"
tst_dim "  Example: '5 test users with different roles, 10 products, 100 transactions'"
echo ""
TEST_DATA=$(tst_ask "Your answer:")
if [ -z "$TEST_DATA" ]; then
  TEST_DATA="TBD"
  tst_add_debt "$AREA" "Test data not specified" \
    "Specific test data needed for this story is not documented" \
    "Test execution planning and data setup"
fi

# ── Q6: Expected results format ───────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Expected Results Format%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
echo ""
RESULTS_FORMAT=$(tst_ask_choice "What level of detail for expected results?" \
  "Pass/Fail only" \
  "Pass/Fail + error message" \
  "Detailed assertions (UI, API, database state)")

# ── Summary ───────────────────────────────────────────────────────────────────
tst_success_rule "✅ Test Case Design Summary"
printf '  %bUser Story:%b      %s\n' "$TST_BOLD" "$TST_NC" "$USER_STORY"
printf '  %bPositive:%b        %s\n' "$TST_BOLD" "$TST_NC" "$POSITIVE"
printf '  %bNegative:%b        %s\n' "$TST_BOLD" "$TST_NC" "$NEGATIVE"
printf '  %bBoundary:%b        %s\n' "$TST_BOLD" "$TST_NC" "$BOUNDARY"
printf '  %bTest Data:%b       %s\n' "$TST_BOLD" "$TST_NC" "$TEST_DATA"
printf '  %bResults Format:%b  %s\n' "$TST_BOLD" "$TST_NC" "$RESULTS_FORMAT"
echo ""

if ! tst_confirm_save "Does this look correct? (y=save / n=redo)"; then
  tst_dim "  Restarting step 2..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Test Cases"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## User Story"
  echo ""
  echo "**Story:** $USER_STORY"
  echo ""
  echo "## Test Scenarios"
  echo ""
  echo "### Positive (Happy Path)"
  echo ""
  echo "$POSITIVE"
  echo ""
  echo "### Negative (Error Conditions)"
  echo ""
  echo "$NEGATIVE"
  echo ""
  echo "### Boundary (Edge Cases)"
  echo ""
  echo "$BOUNDARY"
  echo ""
  echo "## Test Data"
  echo ""
  echo "$TEST_DATA"
  echo ""
  echo "## Expected Results Format"
  echo ""
  echo "$RESULTS_FORMAT"
  echo ""
  echo "## Test Case Template"
  echo ""
  echo '### TC-001: [Scenario]'
  echo ""
  echo "**Given** [Preconditions]"
  echo "**When** [User action]"
  echo "**Then** [Expected result]"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(tst_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$TST_GREEN" "$OUTPUT_FILE" "$TST_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d test quality debt(s) logged to: %s%b\n' "$TST_YELLOW" "$new_debts" "$TST_DEBT_FILE" "$TST_NC"
fi
echo ""
