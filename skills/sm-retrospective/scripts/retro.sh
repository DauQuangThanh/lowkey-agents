#!/bin/bash
# =============================================================================
# retro.sh — Phase 3: Sprint Retrospective
# Facilitates sprint retrospective using Start/Stop/Continue format.
# Output: $SM_OUTPUT_DIR/03-retrospective.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
sm_parse_flags "$@"


OUTPUT_FILE="$SM_OUTPUT_DIR/03-retrospective.md"
AREA="Retrospective"

start_debts=$(sm_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
sm_banner "🔄  Phase 3 of 5 — Sprint Retrospective"
sm_dim "  Let's reflect on this sprint using Start/Stop/Continue format."
sm_dim "  What went well? What didn't? What should we try next?"
echo ""

# ── Q1: Sprint number ──────────────────────────────────────────────────────────
printf '%b%bSetup%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
SPRINT_NUM=$(sm_ask "Which sprint are we retro-ing? (e.g. Sprint 5)")
[ -z "$SPRINT_NUM" ] && SPRINT_NUM="Sprint-Unknown"
RETRO_DATE=$(date '+%Y-%m-%d')
echo ""

# ── Q2: Velocity metrics ───────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 5 — Sprint Metrics%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
PLANNED=$(sm_ask "How many story points were planned? (or leave blank if using hours)")
[ -z "$PLANNED" ] && PLANNED="TBD"

COMPLETED=$(sm_ask "How many story points were actually completed?")
[ -z "$COMPLETED" ] && COMPLETED="TBD"

# ── Q3: What went well (CONTINUE) ──────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 5 — What Went Well? (CONTINUE doing)%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  List things that went well this sprint. One per line. (blank to finish)"
echo ""

CONTINUE=""
while true; do
  ITEM=$(sm_ask "What went well?")
  [ -z "$ITEM" ] && break
  CONTINUE="${CONTINUE}- ✅ $ITEM"$'\n'
done
[ -z "$CONTINUE" ] && CONTINUE="(No items captured)"

# ── Q4: What didn't go well (STOP) ─────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 5 — What Didn'\''t Go Well? (STOP doing)%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  List things that were painful or inefficient. (blank to finish)"
echo ""

STOP=""
while true; do
  ITEM=$(sm_ask "What didn't go well?")
  [ -z "$ITEM" ] && break
  STOP="${STOP}- 🔴 $ITEM"$'\n'
done
[ -z "$STOP" ] && STOP="(No issues identified)"

# ── Q5: What to try (START) ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 5 — What Should We Try? (START doing)%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  What new practices or changes should we try next sprint? (blank to finish)"
echo ""

START=""
while true; do
  ITEM=$(sm_ask "What should we try?")
  [ -z "$ITEM" ] && break
  START="${START}- 🟡 $ITEM"$'\n'
done
[ -z "$START" ] && START="(No improvements proposed)"

# ── Q6: Action items ───────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 5 — Action Items%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  Concrete steps to improve. Include owner and due date."
sm_dim "  Format: 'Action | Owner | Due Date' (blank to finish)"
echo ""

ACTION_ITEMS=""
while true; do
  ACTION=$(sm_ask "Action item (or blank to finish):")
  [ -z "$ACTION" ] && break

  OWNER=$(sm_ask "  Owner:")
  [ -z "$OWNER" ] && OWNER="TBD"

  DUE=$(sm_ask "  Due date (or blank for next sprint):")
  [ -z "$DUE" ] && DUE="Next Sprint"

  ACTION_ITEMS="${ACTION_ITEMS}- [ ] $ACTION | *Owner:* $OWNER | *Due:* $DUE"$'\n'
done
[ -z "$ACTION_ITEMS" ] && ACTION_ITEMS="(No action items)"

# ── Summary ───────────────────────────────────────────────────────────────────
sm_success_rule "✅ Retrospective Summary"
printf '  %bSprint:%b              %s\n' "$SM_BOLD" "$SM_NC" "$SPRINT_NUM"
printf '  %bDate:%b                %s\n' "$SM_BOLD" "$SM_NC" "$RETRO_DATE"
printf '  %bPlanned vs Completed:%b %s / %s points\n' "$SM_BOLD" "$SM_NC" "$PLANNED" "$COMPLETED"
echo ""

if ! sm_confirm_save "Save retrospective? (y=save / n=redo)"; then
  sm_dim "  Restarting Phase 3..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_TIME=$(date '+%Y-%m-%d %H:%M')
{
  echo "# Sprint Retrospective"
  echo ""
  echo "> Captured: $DATE_TIME"
  echo ""
  echo "## Sprint Information"
  echo ""
  echo "**Sprint:** $SPRINT_NUM"
  echo "**Retro Date:** $RETRO_DATE"
  echo ""
  echo "### Velocity"
  echo ""
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Planned | $PLANNED points |"
  echo "| Completed | $COMPLETED points |"
  echo ""
  echo "---"
  echo ""
  echo "## Start / Stop / Continue"
  echo ""
  echo "### Continue (What went well?)"
  echo ""
  if [ "$CONTINUE" = "(No items captured)" ]; then
    echo "$CONTINUE"
  else
    echo "$CONTINUE"
  fi
  echo ""
  echo "### Stop (What didn't go well?)"
  echo ""
  if [ "$STOP" = "(No issues identified)" ]; then
    echo "$STOP"
  else
    echo "$STOP"
  fi
  echo ""
  echo "### Start (What should we try?)"
  echo ""
  if [ "$START" = "(No improvements proposed)" ]; then
    echo "$START"
  else
    echo "$START"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Action Items for Next Sprint"
  echo ""
  if [ "$ACTION_ITEMS" = "(No action items)" ]; then
    echo "$ACTION_ITEMS"
  else
    echo "$ACTION_ITEMS"
  fi
  echo ""
} > "$OUTPUT_FILE"

sm_success_rule "✅ Retrospective saved to $OUTPUT_FILE"

end_debts=$(sm_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  sm_dim "  ⚠️  $new_debts process improvement(s) logged. Review in $SM_DEBT_FILE"
fi
