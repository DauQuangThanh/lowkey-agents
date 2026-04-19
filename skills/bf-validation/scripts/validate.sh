#!/bin/bash
# =============================================================================
# validate.sh — Phase 5: cross-check fixes vs tests vs register; compile final.
#
# Reads:
#   - $BF_OUTPUT_DIR/02-fixes.extract     (FIXED_IDS, BRANCH)
#   - $BF_OUTPUT_DIR/03-regression-tests.extract  (TEST_IDS)
#   - $BF_OUTPUT_DIR/04-change-register.extract   (FILES_MODIFIED, UPSTREAM_AFFECTED)
#
# Writes:
#   - $BF_OUTPUT_DIR/06-validation-report.md
#   - $BF_OUTPUT_DIR/BF-FINAL.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

bf_parse_flags "$@"

REPORT_FILE="$BF_OUTPUT_DIR/06-validation-report.md"
FINAL_FILE="$BF_OUTPUT_DIR/BF-FINAL.md"

FIX_EXTRACT="$BF_OUTPUT_DIR/02-fixes.extract"
REG_TEST_EXTRACT="$BF_OUTPUT_DIR/03-regression-tests.extract"
CHANGE_EXTRACT="$BF_OUTPUT_DIR/04-change-register.extract"

bf_banner "Phase 5 — Validation"

for f in "$FIX_EXTRACT" "$CHANGE_EXTRACT"; do
  if [ ! -f "$f" ]; then
    printf '%bERROR:%b Required extract not found: %s%b\n' "$BF_RED" "$BF_NC" "$f" "$BF_NC" >&2
    printf 'Run earlier phases first.\n' >&2
    exit 1
  fi
done

FIXED_IDS=$(bf_read_extract "$FIX_EXTRACT" FIXED_IDS)
DEFERRED_IDS=$(bf_read_extract "$FIX_EXTRACT" DEFERRED_IDS)
SKIPPED_IDS=$(bf_read_extract "$FIX_EXTRACT" SKIPPED_IDS)
BRANCH=$(bf_read_extract "$FIX_EXTRACT" BRANCH)
COMMITS=$(bf_read_extract "$FIX_EXTRACT" COMMITS)
TEST_IDS=$(bf_read_extract "$REG_TEST_EXTRACT" TEST_IDS 2>/dev/null || echo "")
TESTS_CREATED=$(bf_read_extract "$REG_TEST_EXTRACT" TESTS_CREATED 2>/dev/null || echo "0")
FILES_MODIFIED=$(bf_read_extract "$CHANGE_EXTRACT" FILES_MODIFIED)

# Count fixes (comma-separated, "(none)" means zero)
count_ids() {
  local ids="$1"
  [ -z "$ids" ] && { printf '0'; return; }
  [ "$ids" = "(none)" ] && { printf '0'; return; }
  printf '%s' "$ids" | awk -F',' '{print NF}'
}

N_FIXED=$(count_ids "$FIXED_IDS")
N_DEFERRED=$(count_ids "$DEFERRED_IDS")
N_SKIPPED=$(count_ids "$SKIPPED_IDS")
N_TESTS=${TESTS_CREATED:-0}

# ── Check: every applied fix has a regression test? ──────────────────────────
MISSING_TESTS=0
if [ "$N_FIXED" -gt 0 ] && [ "$N_TESTS" -lt "$N_FIXED" ]; then
  MISSING_TESTS=$((N_FIXED - N_TESTS))
  bf_add_debt "Validation" "Fix/test mismatch" \
    "$N_FIXED fixes applied but only $N_TESTS regression tests created" \
    "Cannot guarantee the bugs won't return; add the missing test(s)"
fi

# ── Check: validation command (optional) ─────────────────────────────────────
VALIDATION_COMMAND=$(bf_get VALIDATION_COMMAND "Validation command (e.g. 'npm test -- --run', 'pytest -q'; blank to skip):" "")
VALIDATION_STATUS="skipped (no command configured)"
if [ -n "$VALIDATION_COMMAND" ]; then
  bf_dim "  Running: $VALIDATION_COMMAND"
  if bash -c "$VALIDATION_COMMAND" >/dev/null 2>&1; then
    VALIDATION_STATUS="✅ passed"
  else
    VALIDATION_STATUS="❌ failed"
    bf_add_debt "Validation" "Validation command failed" \
      "The configured test command returned non-zero after the fix batch" \
      "Batch may introduce a regression; review before merging"
  fi
fi

# ── Overall verdict ──────────────────────────────────────────────────────────
VERDICT="✅ READY"
VERDICT_NOTES=""
if [ "$MISSING_TESTS" -gt 0 ]; then
  VERDICT="⚠️  CONDITIONAL"
  VERDICT_NOTES="${VERDICT_NOTES}- Missing regression tests: $MISSING_TESTS\n"
fi
if [ "$VALIDATION_STATUS" = "❌ failed" ]; then
  VERDICT="❌ NOT READY"
  VERDICT_NOTES="${VERDICT_NOTES}- Validation command failed\n"
fi
if [ "$N_FIXED" -eq 0 ]; then
  VERDICT="ℹ️  NO CHANGES"
  VERDICT_NOTES="${VERDICT_NOTES}- No fixes applied this round\n"
fi

DEBT_TOTAL=$(bf_current_debt_count)

# ── Write validation report ──────────────────────────────────────────────────
{
  echo "# Phase 5 — Validation Report"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Branch:** $BRANCH"
  echo ""
  echo "## Counts"
  echo ""
  echo "| Outcome | Count | IDs |"
  echo "|---|---|---|"
  echo "| Fixed | $N_FIXED | $FIXED_IDS |"
  echo "| Deferred | $N_DEFERRED | $DEFERRED_IDS |"
  echo "| Skipped | $N_SKIPPED | $SKIPPED_IDS |"
  echo "| Regression tests created | $N_TESTS | $TEST_IDS |"
  echo ""
  echo "## Automated Checks"
  echo ""
  if [ "$N_FIXED" -gt 0 ]; then
    if [ "$MISSING_TESTS" -eq 0 ]; then
      echo "- ✅ Every applied fix has at least one regression test"
    else
      echo "- ❌ $MISSING_TESTS fix(es) missing a regression test"
    fi
  else
    echo "- ℹ️ No fixes applied — test-coverage check skipped"
  fi
  echo "- Validation command: $VALIDATION_STATUS"
  echo ""
  echo "## Verdict"
  echo ""
  echo "**$VERDICT**"
  echo ""
  if [ -n "$VERDICT_NOTES" ]; then
    printf '%b' "$VERDICT_NOTES"
  fi
  echo ""
  echo "## Next Steps"
  echo ""
  echo "1. Review \`04-change-register.md\` with the team."
  echo "2. Open a PR for branch \`$BRANCH\`."
  echo "3. Trigger downstream re-runs as listed in \`04-change-register.md\`."
  echo "4. Share \`05-upstream-impact.md\` with business-analyst / architect / developer / ux-designer."
  echo ""
} > "$REPORT_FILE"

# ── Write BF-FINAL.md ────────────────────────────────────────────────────────
{
  echo "# Bug-Fixer — Final Report"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Branch:** $BRANCH"
  echo "**Verdict:** $VERDICT"
  echo ""
  echo "## Headline"
  echo ""
  echo "- Fixes applied: **$N_FIXED**  ($FIXED_IDS)"
  echo "- Deferred:      $N_DEFERRED ($DEFERRED_IDS)"
  echo "- Skipped:       $N_SKIPPED ($SKIPPED_IDS)"
  echo "- Regression tests: $N_TESTS ($TEST_IDS)"
  echo "- BFDEBT entries: $DEBT_TOTAL"
  echo ""
  echo "## Files Modified"
  echo ""
  if [ "$FILES_MODIFIED" = "(none)" ]; then
    echo "_No files modified._"
  else
    IFS=';'
    for f in $FILES_MODIFIED; do [ -n "$f" ] && echo "- \`$f\`"; done
    unset IFS
  fi
  echo ""
  echo "## Commits on \`$BRANCH\`"
  echo ""
  echo "$COMMITS"
  echo ""
  echo "## Outputs in This Round"
  echo ""
  echo "- \`01-triage.md\` — prioritised batch"
  echo "- \`02-fixes.md\` — per-fix diffs + commit SHAs"
  echo "- \`03-regression-tests.md\` — stubs for the tester to merge"
  echo "- \`04-change-register.md\` — **read by downstream reviewers**"
  echo "- \`05-upstream-impact.md\` — **read by upstream agents on their next run**"
  echo "- \`06-validation-report.md\` — automated checks + verdict"
  echo "- \`07-bf-debts.md\` — deferred work"
  echo "- \`all-patches.diff\` — consolidated batch diff"
  echo ""
  echo "## Hand-off Checklist"
  echo ""
  echo "- [ ] Open PR for \`$BRANCH\`"
  echo "- [ ] Run \`cqr-workflow --auto\` on files in \`04-change-register.extract::FILES_MODIFIED\`"
  echo "- [ ] Run \`csr-workflow --auto\` on the same files"
  echo "- [ ] Hand \`03-regression-tests.md\` to the tester"
  echo "- [ ] Send \`05-upstream-impact.md\` to BA / architect / developer / UX"
  echo ""
  echo "---"
} > "$FINAL_FILE"

bf_success_rule "✅ Phase 5 Complete — Verdict: $VERDICT"
printf '  Report: %s\n' "$REPORT_FILE"
printf '  Final:  %s\n' "$FINAL_FILE"
printf '\nShare %s/05-upstream-impact.md with upstream agents.\n' "$BF_OUTPUT_DIR"
printf 'Share %s/04-change-register.md with downstream reviewers.\n\n' "$BF_OUTPUT_DIR"
