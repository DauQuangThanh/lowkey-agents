#!/bin/bash
# =============================================================================
# execute.sh — Phase 3: Test Execution & Bug Tracking
#
# Records pass/fail/blocked counts AND captures structured bug entries that
# the bug-fixer subagent consumes. Writes:
#   - $TEST_OUTPUT_DIR/03-test-execution.md   (human-readable summary)
#   - $TEST_OUTPUT_DIR/bugs.md                (one section per bug, canonical schema)
#   - $TEST_OUTPUT_DIR/bugs.extract           (KEY=VALUE index for automation)
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

tst_parse_flags "$@"

OUTPUT_FILE="$TEST_OUTPUT_DIR/03-test-execution.md"
BUGS_FILE="$TEST_OUTPUT_DIR/bugs.md"
BUGS_EXTRACT="$TEST_OUTPUT_DIR/bugs.extract"
AREA="Test Execution"

start_debts=$(tst_current_debt_count)

# ── Helpers ──────────────────────────────────────────────────────────────────
ensure_bugs_file() {
  if [ ! -f "$BUGS_FILE" ]; then
    cat > "$BUGS_FILE" <<'EOF'
# Bug Register

> One section per bug. The bug-fixer subagent parses this file, so keep the
> schema consistent: `## BUG-NN: <title>` heading, fields in the order shown,
> and `### Steps to Reproduce / ### Expected / ### Actual / ### Evidence /
> ### Regression Risk / ### Suggested Fix` sub-headings. Add new bugs at the
> bottom; never renumber or remove an existing entry.

---

EOF
  fi
}

bugs_count() {
  if [ -f "$BUGS_FILE" ]; then
    grep -c '^## BUG-' "$BUGS_FILE" 2>/dev/null || printf '0'
  else
    printf '0'
  fi
}

next_bug_id() {
  local n
  n=$(bugs_count)
  printf 'BUG-%03d' "$((n + 1))"
}

append_bug() {
  local id="$1" title="$2" severity="$3" priority="$4" component="$5" \
        story="$6" testcase="$7" environment="$8" \
        steps="$9" expected="${10}" actual="${11}" evidence="${12}" \
        regression="${13}" suggested="${14}" reporter="${15}"

  ensure_bugs_file
  {
    printf '## %s: %s\n\n' "$id" "$title"
    printf '**Severity:** %s  \n' "$severity"
    printf '**Priority:** %s  \n'  "$priority"
    printf '**Status:** Open  \n'
    printf '**Found:** %s  \n' "$(date '+%Y-%m-%d')"
    printf '**Found in:** %s  \n' "$environment"
    printf '**Component:** %s  \n' "$component"
    printf '**Related story:** %s  \n' "$story"
    printf '**Related test case:** %s  \n' "$testcase"
    printf '**Reporter:** %s\n\n' "$reporter"
    printf '### Steps to Reproduce\n\n%s\n\n' "$steps"
    printf '### Expected\n\n%s\n\n' "$expected"
    printf '### Actual\n\n%s\n\n' "$actual"
    printf '### Evidence\n\n%s\n\n' "$evidence"
    printf '### Regression Risk\n\n%s\n\n' "$regression"
    printf '### Suggested Fix\n\n%s\n\n' "$suggested"
    printf -- '---\n\n'
  } >> "$BUGS_FILE"
}

# ── Header ────────────────────────────────────────────────────────────────────
tst_banner "▶️  Step 3 of 4 — Test Execution & Bug Tracking"
tst_dim "  Record your test execution results and log each bug in full detail."
tst_dim "  The bug-fixer subagent reads bugs.md — the richer each entry, the"
tst_dim "  faster and safer the fix cycle."
echo ""

# ── Q1: Execution round ───────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Execution Round ID%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Example: 'Round 1', 'Sprint 3 UAT', 'Regression Run 5'"
ROUND_ID=$(tst_ask "Your answer:")
[ -z "$ROUND_ID" ] && ROUND_ID="Round $(date +%s | tail -c 4)"

# ── Q2: Execution summary ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — Execution Summary%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Example: '45 passed, 4 failed, 1 blocked, 1 not run'"
SUMMARY=$(tst_ask "Your answer:")
if [ -z "$SUMMARY" ]; then
  SUMMARY="TBD"
  tst_add_debt "$AREA" "Test execution summary not recorded" \
    "Execution results (passed/failed/blocked counts) not documented" \
    "Test reporting and metrics"
fi

# ── Q3: Test environment ──────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Test Environment%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  OS, browser, version, config, data refresh — anything a developer"
tst_dim "  needs to reproduce the bug on their machine."
ENV_DETAILS=$(tst_ask "Your answer:")
[ -z "$ENV_DETAILS" ] && ENV_DETAILS="TBD"

# ── Q4: Reporter ──────────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Reporter (tester name)%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
REPORTER=$(tst_ask "Your answer (used for every bug logged in this round):")
[ -z "$REPORTER" ] && REPORTER="QA"

# ── Q5: Bug loop ──────────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — Log Bugs%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  For every failed test, capture enough detail so the bug-fixer can"
tst_dim "  act without guessing. 11 fields per bug — the schema is fixed."
echo ""

BUG_IDS=""
bugs_in_round=0

if tst_is_auto; then
  tst_dim "  [Auto mode] Skipping interactive bug loop. Populate bugs.md"
  tst_dim "  manually from your CI output if you want the fixer to run on it."
else
  while true; do
    add_another=$(tst_ask_yn "Add a bug from this round?")
    [ "$add_another" = "no" ] && break

    BUG_ID=$(next_bug_id)
    echo ""
    printf '%b  Logging %s — 11 fields%b\n' "$TST_CYAN" "$BUG_ID" "$TST_NC"

    TITLE=$(tst_ask "1/11  Title (one line, e.g. 'Login rejects valid email with trailing space'):")
    [ -z "$TITLE" ] && TITLE="Untitled"

    SEVERITY=$(tst_ask_choice "2/11  Severity:" \
      "Critical — system unusable / data loss / security breach" \
      "Major — core feature broken / significant user impact" \
      "Minor — peripheral feature broken / workaround exists" \
      "Trivial — cosmetic or very low impact")
    SEVERITY="${SEVERITY%% —*}"

    PRIORITY=$(tst_ask_choice "3/11  Priority:" \
      "P0 — drop everything, fix now" \
      "P1 — fix this sprint" \
      "P2 — fix next sprint" \
      "P3 — backlog")
    PRIORITY="${PRIORITY%% —*}"

    COMPONENT=$(tst_ask "4/11  Component (module or file path, e.g. 'src/auth/login.ts' — best guess is fine):")
    [ -z "$COMPONENT" ] && {
      COMPONENT="Unknown"
      tst_add_debt "$AREA" "$BUG_ID component not identified" \
        "Bug logged without component hint" \
        "Bug-fixer has to search the codebase blindly"
    }

    STORY=$(tst_ask "5/11  Related user story / requirement ID (e.g. 'FR-03', 'US-17', or blank):")
    [ -z "$STORY" ] && STORY="N/A"

    TESTCASE=$(tst_ask "6/11  Test case that detected this (e.g. 'TC-12', or blank):")
    [ -z "$TESTCASE" ] && TESTCASE="N/A"

    echo ""
    tst_dim "  Steps to reproduce — one line per step; press Enter twice when done."
    STEPS=""
    step_num=1
    while true; do
      line=$(tst_ask "    Step $step_num (blank to finish):")
      [ -z "$line" ] && break
      STEPS="${STEPS}${step_num}. ${line}"$'\n'
      step_num=$((step_num + 1))
    done
    [ -z "$STEPS" ] && {
      STEPS="(not captured)"
      tst_add_debt "$AREA" "$BUG_ID reproduction steps missing" \
        "Bug logged without reproducible steps" \
        "Bug-fixer cannot verify the fix works"
    }

    EXPECTED=$(tst_ask "8/11  Expected behaviour (what should have happened):")
    [ -z "$EXPECTED" ] && EXPECTED="(not captured)"

    ACTUAL=$(tst_ask "9/11  Actual behaviour (what did happen):")
    [ -z "$ACTUAL" ] && ACTUAL="(not captured)"

    EVIDENCE=$(tst_ask "10/11 Evidence (stack trace, error code, log snippet, screenshot path — single line OK):")
    [ -z "$EVIDENCE" ] && EVIDENCE="None attached"

    REGRESSION=$(tst_ask "11/11 Regression risk (what else might break if we fix this? blank = none obvious):")
    [ -z "$REGRESSION" ] && REGRESSION="None obvious"

    SUGGESTED=$(tst_ask "(opt) Suggested fix (blank = leave to bug-fixer):")
    [ -z "$SUGGESTED" ] && SUGGESTED="Leave to bug-fixer"

    append_bug "$BUG_ID" "$TITLE" "$SEVERITY" "$PRIORITY" "$COMPONENT" \
               "$STORY" "$TESTCASE" "$ENV_DETAILS" \
               "$STEPS" "$EXPECTED" "$ACTUAL" "$EVIDENCE" \
               "$REGRESSION" "$SUGGESTED" "$REPORTER"

    BUG_IDS="${BUG_IDS}${BUG_ID}, "
    bugs_in_round=$((bugs_in_round + 1))

    printf '%b  ✅ %s logged.%b\n\n' "$TST_GREEN" "$BUG_ID" "$TST_NC"
  done
fi

BUG_IDS="${BUG_IDS%, }"   # trim trailing ", "
[ -z "$BUG_IDS" ] && BUG_IDS="None"

# ── Q6: Blocked tests / retests ───────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Blocked & Retested%b\n' "$TST_CYAN" "$TST_BOLD" "$TST_NC"
tst_dim "  Blocked tests (what's blocked and why) — free text, or 'none':"
BLOCKED=$(tst_ask "Your answer:")
[ -z "$BLOCKED" ] && BLOCKED="None"

tst_dim "  Previously failed bugs retested this round (e.g. 'BUG-001: fixed, passed'):"
RETESTS=$(tst_ask "Your answer:")
[ -z "$RETESTS" ] && RETESTS="None"

# ── Summary ───────────────────────────────────────────────────────────────────
tst_success_rule "✅ Test Execution Summary"
printf '  %bRound:%b          %s\n' "$TST_BOLD" "$TST_NC" "$ROUND_ID"
printf '  %bResults:%b        %s\n' "$TST_BOLD" "$TST_NC" "$SUMMARY"
printf '  %bEnvironment:%b    %s\n' "$TST_BOLD" "$TST_NC" "$ENV_DETAILS"
printf '  %bBugs logged:%b    %d (%s)\n' "$TST_BOLD" "$TST_NC" "$bugs_in_round" "$BUG_IDS"
printf '  %bBlocked:%b        %s\n' "$TST_BOLD" "$TST_NC" "$BLOCKED"
printf '  %bRetests:%b        %s\n' "$TST_BOLD" "$TST_NC" "$RETESTS"
echo ""

if ! tst_confirm_save "Does this look correct? (y=save / n=redo)"; then
  tst_dim "  Restarting step 3..."
  exec bash "$0"
fi

# ── Write outputs ─────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
total_bugs=$(bugs_count)

{
  echo "# Test Execution Report"
  echo ""
  echo "> Execution Round: $ROUND_ID"
  echo "> Date: $DATE_NOW"
  echo "> Reporter: $REPORTER"
  echo ""
  echo "## Execution Summary"
  echo ""
  echo "$SUMMARY"
  echo ""
  echo "## Environment"
  echo ""
  echo "$ENV_DETAILS"
  echo ""
  echo "## Bugs Logged This Round"
  echo ""
  if [ "$bugs_in_round" -gt 0 ]; then
    printf -- '- %d new bug(s): %s\n' "$bugs_in_round" "$BUG_IDS"
    printf -- '- Full details: [bugs.md](./bugs.md)\n'
  else
    echo "- None"
  fi
  echo ""
  echo "## Blocked Tests"
  echo ""
  echo "$BLOCKED"
  echo ""
  echo "## Retests"
  echo ""
  echo "$RETESTS"
  echo ""
} > "$OUTPUT_FILE"

# Extract — consumed by bug-fixer's bf-triage
tst_write_extract "$BUGS_EXTRACT" \
  "BUGS_FILE=$BUGS_FILE" \
  "BUGS_TOTAL=$total_bugs" \
  "BUGS_NEW_THIS_ROUND=$bugs_in_round" \
  "BUGS_IDS_THIS_ROUND=$BUG_IDS" \
  "ROUND_ID=$ROUND_ID" \
  "REPORTER=$REPORTER" \
  "ENVIRONMENT=$ENV_DETAILS"

end_debts=$(tst_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved execution report: %s%b\n' "$TST_GREEN" "$OUTPUT_FILE" "$TST_NC"
printf '%b  Bug register:           %s  (%d total)%b\n' "$TST_GREEN" "$BUGS_FILE" "$total_bugs" "$TST_NC"
printf '%b  Extract for bug-fixer:  %s%b\n' "$TST_GREEN" "$BUGS_EXTRACT" "$TST_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d test quality debt(s) logged to: %s%b\n' "$TST_YELLOW" "$new_debts" "$TST_DEBT_FILE" "$TST_NC"
fi
echo ""
