#!/bin/bash
# =============================================================================
# stakeholder-comms.sh — Phase 4: Stakeholder Communication Planning
# Defines communication strategy for different stakeholder groups.
# Output: $PO_OUTPUT_DIR/04-stakeholder-comms.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
po_parse_flags "$@"


OUTPUT_FILE="$PO_OUTPUT_DIR/04-stakeholder-comms.md"
AREA="Stakeholder Communication"

start_debts=$(po_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
po_banner "📣  Phase 4 — Stakeholder Communication Plan"
po_dim "  Let's define how we communicate product progress to key groups."
echo ""

# ── Q1: Stakeholder groups ────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Stakeholder Groups%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Who are the key stakeholders for this product?"
po_dim "  Example: executives, customers, support team, partners, etc."
echo ""

declare -a GROUPS
declare -a GROUP_FREQ
declare -a GROUP_FORMAT
declare -a GROUP_NEEDS

group_count=0

while true; do
  group_num=$((group_count + 1))
  printf '%b▶ Add stakeholder group #%d? (y/n): %b' "$PO_YELLOW" "$group_num" "$PO_NC"
  IFS= read -r response
  response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "$response" != "y" ] && [ "$response" != "yes" ]; then
    break
  fi

  GROUP=$(po_ask "Group name (e.g. 'Executives', 'Customers', 'Support Team'):")
  [ -z "$GROUP" ] && GROUP="Unnamed Group"
  GROUPS+=("$GROUP")

  FREQ=$(po_ask_choice "Communication frequency:" \
    "Weekly" \
    "Bi-weekly" \
    "Monthly" \
    "Quarterly" \
    "Ad-hoc (only on major updates)")
  GROUP_FREQ+=("$FREQ")

  FORMAT=$(po_ask_choice "Preferred format:" \
    "Email update" \
    "In-person meeting" \
    "Video call" \
    "Dashboard / self-serve" \
    "Mixed (combination)")
  GROUP_FORMAT+=("$FORMAT")

  NEEDS=$(po_ask "What do they need to know? (progress, metrics, blockers, timeline, etc.):")
  [ -z "$NEEDS" ] && NEEDS="Standard updates"
  GROUP_NEEDS+=("$NEEDS")

  group_count=$((group_count + 1))
done

if [ "$group_count" -eq 0 ]; then
  po_add_debt "$AREA" "No stakeholder groups defined" \
    "Stakeholder communication groups are not identified" \
    "Communication strategy, stakeholder alignment"
fi

# ── Q2: Sprint review format ──────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — Sprint Review Format%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  How do you run sprint reviews? Who attends? What's the agenda?"
echo ""
SPRINT_FORMAT=$(po_ask "Your answer:")
if [ -z "$SPRINT_FORMAT" ]; then
  SPRINT_FORMAT="Not yet defined"
  po_add_debt "$AREA" "Sprint review format not defined" \
    "Sprint review process is not documented" \
    "Demo preparation, stakeholder engagement"
fi

# ── Q3: Demo preparation ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Demo Preparation Checklist%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  What needs to be prepared before each demo or review?"
po_dim "  Example: 'Test environment ready', 'Demo script written', 'Backup plan ready'"
echo ""
DEMO_CHECKLIST=$(po_ask "Your answer (comma-separated, or press Enter to skip):")
if [ -z "$DEMO_CHECKLIST" ]; then
  DEMO_CHECKLIST="Demo environment tested, Demo script prepared, Backup scenarios ready"
fi

# ── Q4: Feedback collection ──────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Feedback Collection Method%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  How do you gather feedback from stakeholders?"
po_dim "  Example: 'During review', 'Post-demo survey', 'Weekly sync call'"
echo ""
FEEDBACK_METHOD=$(po_ask "Your answer:")
[ -z "$FEEDBACK_METHOD" ] && FEEDBACK_METHOD="During sprint reviews"

# ── Q5: Escalation triggers ───────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — Escalation Triggers%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  When should issues be escalated to stakeholders?"
po_dim "  Example: 'Milestone missed', 'Major blocker', 'Scope change > 20%'"
echo ""
ESCALATION=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$ESCALATION" ] && ESCALATION="Not yet defined"

# ── Q6: Additional communication practices ────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Other Communication Practices%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Any other communication channels or practices? (dashboards, newsletters, etc.)"
echo ""
OTHER=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$OTHER" ] && OTHER="None defined"

# ── Summary ───────────────────────────────────────────────────────────────────
po_success_rule "✅ Stakeholder Communication Summary"
printf '  %bGroups:%b           %d groups\n' "$PO_BOLD" "$PO_NC" "$group_count"
printf '  %bSprint Review:%b    %s\n' "$PO_BOLD" "$PO_NC" "$(echo "$SPRINT_FORMAT" | cut -c1-40)..."
printf '  %bFeedback Method:%b  %s\n' "$PO_BOLD" "$PO_NC" "$FEEDBACK_METHOD"
echo ""

if ! po_confirm_save "Does this look correct? (y=save / n=redo)"; then
  po_dim "  Restarting phase 4..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Stakeholder Communication Plan"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Stakeholder Groups"
  echo ""

  if [ "$group_count" -gt 0 ]; then
    echo "| Group | Frequency | Format | Communication Needs |"
    echo "|-------|-----------|--------|---------------------|"
    for ((i=0; i<group_count; i++)); do
      printf "| %s | %s | %s | %s |\n" \
        "${GROUPS[$i]}" \
        "${GROUP_FREQ[$i]}" \
        "${GROUP_FORMAT[$i]}" \
        "$(echo "${GROUP_NEEDS[$i]}" | cut -c1-30)..."
    done
    echo ""
    echo "### Detailed Communication Plans"
    echo ""
    for ((i=0; i<group_count; i++)); do
      echo "#### ${GROUPS[$i]}"
      echo ""
      echo "**Frequency:** ${GROUP_FREQ[$i]}"
      echo ""
      echo "**Format:** ${GROUP_FORMAT[$i]}"
      echo ""
      echo "**Needs:** ${GROUP_NEEDS[$i]}"
      echo ""
    done
  else
    echo "(No stakeholder groups defined)"
    echo ""
  fi

  echo "## Sprint Review Format"
  echo ""
  echo "$SPRINT_FORMAT"
  echo ""
  echo "## Demo Preparation Checklist"
  echo ""
  echo "- $(echo "$DEMO_CHECKLIST" | sed 's/, /\n- /g')"
  echo ""
  echo "## Feedback Collection"
  echo ""
  echo "$FEEDBACK_METHOD"
  echo ""
  echo "## Escalation Triggers"
  echo ""
  echo "$ESCALATION"
  echo ""
  echo "## Other Communication Practices"
  echo ""
  echo "$OTHER"
  echo ""
} > "$OUTPUT_FILE"

po_success_rule "✅ Stakeholder Communication Plan saved"
printf '%b  Output: %s%b\n' "$PO_GREEN" "$OUTPUT_FILE" "$PO_NC"
echo ""

# ── Log new debts ─────────────────────────────────────────────────────────────
end_debts=$(po_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  po_dim "  Logged $new_debts debt(s) — see po-output/06-po-debts.md"
fi
echo ""
