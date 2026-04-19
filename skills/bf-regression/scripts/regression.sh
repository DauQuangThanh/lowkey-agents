#!/bin/bash
# =============================================================================
# regression.sh — Phase 3: create regression test stubs for each applied fix.
#
# Reads:
#   - $BF_OUTPUT_DIR/02-fixes.extract  (FIXED_IDS)
#   - $TEST_OUTPUT_DIR/bugs.md         (to copy Steps to Reproduce into the test stub)
# Writes:
#   - $BF_OUTPUT_DIR/03-regression-tests.md
#   - $BF_OUTPUT_DIR/03-regression-tests.extract
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

bf_parse_flags "$@"

OUTPUT_FILE="$BF_OUTPUT_DIR/03-regression-tests.md"
EXTRACT_FILE="$BF_OUTPUT_DIR/03-regression-tests.extract"
FIX_EXTRACT="$BF_OUTPUT_DIR/02-fixes.extract"
BUGS_FILE="${TEST_OUTPUT_DIR:-$(pwd)/test-output}/bugs.md"

bf_banner "Phase 3 — Regression test stubs"

if [ ! -f "$FIX_EXTRACT" ]; then
  printf '%bERROR:%b Phase 2 extract not found: %s\n' "$BF_RED" "$BF_NC" "$FIX_EXTRACT" >&2
  exit 1
fi

FIXED_IDS=$(bf_read_extract "$FIX_EXTRACT" FIXED_IDS)
BRANCH=$(bf_read_extract "$FIX_EXTRACT" BRANCH)

if [ -z "$FIXED_IDS" ] || [ "$FIXED_IDS" = "(none)" ]; then
  {
    echo "# Phase 3 — Regression tests"
    echo ""
    echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo ""
    echo "_No fixes applied in Phase 2 — no regression tests needed this round._"
  } > "$OUTPUT_FILE"
  bf_write_extract "$EXTRACT_FILE" \
    "TESTS_CREATED=0" \
    "TEST_IDS=" \
    "SOURCE_FIXED_IDS=$FIXED_IDS"
  bf_success_rule "✅ Phase 3 Complete — no fixes to cover"
  exit 0
fi

# Config
FRAMEWORK=$(bf_get REGRESSION_TEST_FRAMEWORK "Test framework hint (Jest / Pytest / JUnit / xUnit / Go test / Other):" "Jest")
TEST_PATH_HINT=$(bf_get REGRESSION_TEST_PATH "Where should new tests live (dir or file pattern)?" "tests/regression/")

# Extract bug details per FIXED id
extract_bug_field() {
  local bug_id="$1" field="$2"
  awk -v id="$bug_id" -v field="$field" '
    $0 ~ "^## " id ": " { in_bug=1; next }
    /^## / && in_bug { exit }
    in_bug && $0 ~ "^\\*\\*" field ":\\*\\*" {
      val = $0
      sub("^\\*\\*" field ":\\*\\* *", "", val)
      sub(" *$", "", val)
      print val
      exit
    }
  ' "$BUGS_FILE" 2>/dev/null
}

extract_bug_section() {
  local bug_id="$1" heading="$2"
  awk -v id="$bug_id" -v heading="$heading" '
    $0 ~ "^## " id ": " { in_bug=1; next }
    /^## / && in_bug { exit }
    in_bug && $0 ~ "^### " heading {
      in_sec=1; next
    }
    in_sec && /^### / { exit }
    in_sec && /^--- *$/ { exit }
    in_sec { print }
  ' "$BUGS_FILE" 2>/dev/null
}

{
  echo "# Phase 3 — Regression tests"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Branch:** $BRANCH"
  echo "**Framework hint:** $FRAMEWORK"
  echo "**Test path:** $TEST_PATH_HINT"
  echo ""
  echo "Each regression test below is a stub. It captures the reproduction"
  echo "steps from bugs.md plus the expected outcome so the tester agent can"
  echo "merge it into \`test-output/02-test-cases.md\` on its next run."
  echo ""
} > "$OUTPUT_FILE"

TEST_IDS=""
tc_num=1

IFS=','
for id in $FIXED_IDS; do
  [ -z "$id" ] && continue
  title=$(extract_bug_field "$id" "Title")
  component=$(extract_bug_field "$id" "Component")
  severity=$(extract_bug_field "$id" "Severity")
  priority=$(extract_bug_field "$id" "Priority")
  steps=$(extract_bug_section "$id" "Steps to Reproduce")
  expected=$(extract_bug_section "$id" "Expected")
  actual=$(extract_bug_section "$id" "Actual")

  tc_id=$(printf 'TC-BF-%03d' "$tc_num")

  {
    echo "## $tc_id — Regression for $id"
    echo ""
    echo "**Covers bug:** $id"
    echo "**Severity:** ${severity:-unknown}"
    echo "**Priority:** ${priority:-unknown}"
    echo "**Component:** ${component:-unknown}"
    echo "**Framework:** $FRAMEWORK"
    echo "**Target location:** $TEST_PATH_HINT"
    echo ""
    echo "### Precondition"
    echo ""
    echo "A clean test environment as described in \`$id\`'s \`Found in\` field."
    echo ""
    echo "### Steps"
    echo ""
    if [ -n "$steps" ]; then
      printf '%s\n' "$steps"
    else
      echo "_(Steps to Reproduce missing from bugs.md — bf-regression could not populate. Check \`$id\` and update bugs.md.)_"
    fi
    echo ""
    echo "### Expected"
    echo ""
    if [ -n "$expected" ]; then
      printf '%s\n' "$expected"
    else
      echo "_(Expected missing from bugs.md.)_"
    fi
    echo ""
    echo "### Regression guard"
    echo ""
    echo "Assert the test fails on the pre-fix commit AND passes on the fix commit."
    echo ""
    echo "\`\`\`"
    echo "# Framework-specific stub — translate the steps above into code for $FRAMEWORK."
    echo "# Example pattern:"
    echo "#   test('${id}: ${title:-regression}', () => {"
    echo "#     // setup per Steps"
    echo "#     // exercise"
    echo "#     // assert matches Expected"
    echo "#   });"
    echo "\`\`\`"
    echo ""
    echo "---"
    echo ""
  } >> "$OUTPUT_FILE"

  TEST_IDS="${TEST_IDS}${tc_id},"
  tc_num=$((tc_num + 1))
done
unset IFS

TEST_IDS="${TEST_IDS%,}"
TESTS_CREATED=$((tc_num - 1))

bf_write_extract "$EXTRACT_FILE" \
  "TESTS_CREATED=$TESTS_CREATED" \
  "TEST_IDS=$TEST_IDS" \
  "SOURCE_FIXED_IDS=$FIXED_IDS" \
  "FRAMEWORK=$FRAMEWORK" \
  "TEST_PATH_HINT=$TEST_PATH_HINT"

bf_success_rule "✅ Phase 3 Complete — $TESTS_CREATED regression test stub(s)"
printf '  Markdown: %s\n' "$OUTPUT_FILE"
printf '\nNext: Phase 4 — bash <SKILL_DIR>/bf-change-register/scripts/register.sh\n\n'
