#!/bin/bash
# =============================================================================
# acceptance.sh — Phase 2: Acceptance Criteria & Definition of Done
# Defines acceptance criteria for backlog stories using BDD scenarios.
# Output: $PO_OUTPUT_DIR/02-acceptance-criteria.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
po_parse_flags "$@"


OUTPUT_FILE="$PO_OUTPUT_DIR/02-acceptance-criteria.md"
AREA="Acceptance Criteria"
BACKLOG_FILE="$PO_OUTPUT_DIR/01-product-backlog.md"

start_debts=$(po_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
po_banner "📋  Phase 2 — Acceptance Criteria & Definition of Done"
po_dim "  Let's define what 'done' means for each story."
po_dim "  We'll use BDD (Given/When/Then) scenarios."
echo ""

# Check if backlog exists
if [ ! -f "$BACKLOG_FILE" ]; then
  po_dim "  Note: No backlog file found at $BACKLOG_FILE"
  po_dim "  I'll ask you which stories to define acceptance for."
  echo ""
fi

# ── Q1: Story selection ───────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Story Selection%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Which story would you like to define acceptance criteria for?"
echo ""
STORY=$(po_ask "Story title or ID:")
if [ -z "$STORY" ]; then
  STORY="Unnamed Story"
  po_add_debt "$AREA" "Story not identified" \
    "No story was selected for acceptance criteria" \
    "Development team cannot start work"
fi

# ── Q2: BDD scenarios ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — BDD Scenarios (Given/When/Then)%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Let's define acceptance scenarios using Given/When/Then format."
po_dim "  Example:"
po_dim "    Given: user is logged in"
po_dim "    When: user clicks 'Save'"
po_dim "    Then: data is saved and confirmation shown"
echo ""

declare -a SCENARIOS_GIVEN
declare -a SCENARIOS_WHEN
declare -a SCENARIOS_THEN

scenario_count=0

while true; do
  scenario_num=$((scenario_count + 1))
  printf '%b▶ Add BDD scenario #%d? (y/n): %b' "$PO_YELLOW" "$scenario_num" "$PO_NC"
  IFS= read -r response
  response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "$response" != "y" ] && [ "$response" != "yes" ]; then
    break
  fi

  GIVEN=$(po_ask "Given (precondition):")
  [ -z "$GIVEN" ] && GIVEN="(precondition not specified)"
  SCENARIOS_GIVEN+=("$GIVEN")

  WHEN=$(po_ask "When (action):")
  [ -z "$WHEN" ] && WHEN="(action not specified)"
  SCENARIOS_WHEN+=("$WHEN")

  THEN=$(po_ask "Then (expected result):")
  [ -z "$THEN" ] && THEN="(result not specified)"
  SCENARIOS_THEN+=("$THEN")

  scenario_count=$((scenario_count + 1))
done

if [ "$scenario_count" -eq 0 ]; then
  po_add_debt "$AREA" "No BDD scenarios defined" \
    "Story has no acceptance scenarios" \
    "Dev team lacks clear acceptance criteria"
fi

# ── Q3: Edge cases ────────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Edge Cases & Error Handling%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  What edge cases or error conditions should be handled?"
echo ""
EDGE_CASES=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$EDGE_CASES" ] && EDGE_CASES="Not specified"

# ── Q4: Non-functional acceptance criteria ────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Non-Functional Acceptance Criteria%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Performance, security, accessibility, etc. Example:"
po_dim "    - Response time < 200ms"
po_dim "    - Must be mobile-friendly"
po_dim "    - Accessibility: WCAG AA compliant"
echo ""
NFR=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$NFR" ] && NFR="Not specified"

# ── Q5: Global DoD checklist ──────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — Global Definition of Done%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Items that apply to ALL stories (code review, tests, docs, etc)."
echo ""
GLOBAL_DOD=$(po_ask "Your answer (comma-separated, or press Enter to use defaults):")
if [ -z "$GLOBAL_DOD" ]; then
  GLOBAL_DOD="Code reviewed, Unit tests passed, Documentation updated, No critical warnings"
fi

# ── Q6: Story-specific DoD ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Story-Specific Definition of Done%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Additional DoD items specific to this story."
echo ""
STORY_DOD=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$STORY_DOD" ] && STORY_DOD="None additional"

# ── Summary ───────────────────────────────────────────────────────────────────
po_success_rule "✅ Acceptance Criteria Summary"
printf '  %bStory:%b              %s\n' "$PO_BOLD" "$PO_NC" "$STORY"
printf '  %bScenarios:%b          %d scenarios\n' "$PO_BOLD" "$PO_NC" "$scenario_count"
printf '  %bEdge Cases:%b         %s\n' "$PO_BOLD" "$PO_NC" "$(echo "$EDGE_CASES" | cut -c1-40)..."
printf '  %bNon-Functional:%b     %s\n' "$PO_BOLD" "$PO_NC" "$(echo "$NFR" | cut -c1-40)..."
echo ""

if ! po_confirm_save "Does this look correct? (y=save / n=redo)"; then
  po_dim "  Restarting phase 2..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Acceptance Criteria & Definition of Done"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Story: $STORY"
  echo ""
  echo "### BDD Scenarios"
  echo ""

  if [ "$scenario_count" -gt 0 ]; then
    for ((i=0; i<scenario_count; i++)); do
      echo "#### Scenario $((i+1))"
      echo ""
      echo "**Given:** ${SCENARIOS_GIVEN[$i]}"
      echo ""
      echo "**When:** ${SCENARIOS_WHEN[$i]}"
      echo ""
      echo "**Then:** ${SCENARIOS_THEN[$i]}"
      echo ""
    done
  else
    echo "(No scenarios defined)"
    echo ""
  fi

  echo "### Edge Cases & Error Handling"
  echo ""
  echo "$EDGE_CASES"
  echo ""
  echo "### Non-Functional Acceptance Criteria"
  echo ""
  echo "$NFR"
  echo ""
  echo "### Definition of Done"
  echo ""
  echo "#### Global DoD (applies to all stories)"
  echo ""
  echo "- $(echo "$GLOBAL_DOD" | sed 's/, /\n- /g')"
  echo ""
  echo "#### Story-Specific DoD"
  echo ""
  if [ "$STORY_DOD" != "None additional" ]; then
    echo "- $(echo "$STORY_DOD" | sed 's/, /\n- /g')"
  else
    echo "(None additional)"
  fi
  echo ""
} > "$OUTPUT_FILE"

po_success_rule "✅ Acceptance Criteria saved"
printf '%b  Output: %s%b\n' "$PO_GREEN" "$OUTPUT_FILE" "$PO_NC"
echo ""

# ── Log new debts ─────────────────────────────────────────────────────────────
end_debts=$(po_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  po_dim "  Logged $new_debts debt(s) — see po-output/06-po-debts.md"
fi
echo ""
