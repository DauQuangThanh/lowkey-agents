#!/bin/bash
# =============================================================================
# sprint-review.sh — Phase 5: Sprint Review Preparation
# Documents sprint results, velocity, blockers, and lessons learned.
# Output: $PO_OUTPUT_DIR/05-sprint-review.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
po_parse_flags "$@"


OUTPUT_FILE="$PO_OUTPUT_DIR/05-sprint-review.md"
AREA="Sprint Review"

start_debts=$(po_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
po_banner "✓   Phase 5 — Sprint Review Preparation"
po_dim "  Let's document what was delivered this sprint."
echo ""

# ── Q1: Sprint info ───────────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Sprint Information%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
SPRINT_NUM=$(po_ask "Sprint number (e.g. 'Sprint 5', 'Iteration 3'):")
[ -z "$SPRINT_NUM" ] && SPRINT_NUM="Current Sprint"

SPRINT_DATES=$(po_ask "Sprint dates (e.g. 'Apr 7-18, 2026'):")
[ -z "$SPRINT_DATES" ] && SPRINT_DATES="TBD"

# ── Q2: Stories completed ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — Stories Completed%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Which backlog items or stories were completed this sprint?"
echo ""

declare -a COMPLETED_ITEMS
declare -a COMPLETED_SIZING

completed_count=0

while true; do
  item_num=$((completed_count + 1))
  printf '%b▶ Add completed item #%d? (y/n): %b' "$PO_YELLOW" "$item_num" "$PO_NC"
  IFS= read -r response
  response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "$response" != "y" ] && [ "$response" != "yes" ]; then
    break
  fi

  ITEM=$(po_ask "Item title:")
  [ -z "$ITEM" ] && ITEM="Unnamed Item"
  COMPLETED_ITEMS+=("$ITEM")

  SIZING=$(po_ask_choice "Sizing:" \
    "S — Small" \
    "M — Medium" \
    "L — Large" \
    "XL — Extra Large")
  COMPLETED_SIZING+=("$SIZING")

  completed_count=$((completed_count + 1))
done

# ── Q3: Stories not completed ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Stories Not Completed%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Which items were not completed? Why? (technical blockers, scope, capacity, etc.)"
echo ""

declare -a INCOMPLETE_ITEMS
declare -a INCOMPLETE_REASONS

incomplete_count=0

while true; do
  item_num=$((incomplete_count + 1))
  printf '%b▶ Add incomplete item #%d? (y/n): %b' "$PO_YELLOW" "$item_num" "$PO_NC"
  IFS= read -r response
  response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "$response" != "y" ] && [ "$response" != "yes" ]; then
    break
  fi

  ITEM=$(po_ask "Item title:")
  [ -z "$ITEM" ] && ITEM="Unnamed Item"
  INCOMPLETE_ITEMS+=("$ITEM")

  REASON=$(po_ask "Reason for non-completion:")
  [ -z "$REASON" ] && REASON="TBD"
  INCOMPLETE_REASONS+=("$REASON")

  incomplete_count=$((incomplete_count + 1))
done

# ── Q4: Demo items ───────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Demo Items & Highlights%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  What are the standout items to demo to stakeholders?"
echo ""
DEMO_ITEMS=$(po_ask "Your answer (comma-separated, or press Enter to skip):")
[ -z "$DEMO_ITEMS" ] && DEMO_ITEMS="Items shown in review"

# ── Q5: Stakeholder feedback ──────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — Stakeholder Feedback%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  What feedback did stakeholders provide during the review?"
echo ""
FEEDBACK=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$FEEDBACK" ] && FEEDBACK="No formal feedback collected"

# ── Q6: Backlog adjustments ───────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Backlog Adjustments & Next Sprint%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  What backlog changes or reprioritization is needed?"
po_dim "  What's planned for the next sprint?"
echo ""
ADJUSTMENTS=$(po_ask "Your answer (or press Enter to defer):")
[ -z "$ADJUSTMENTS" ] && ADJUSTMENTS="To be determined in sprint planning"

# ── Calculate metrics ─────────────────────────────────────────────────────────
TOTAL_ITEMS=$((completed_count + incomplete_count))
if [ "$TOTAL_ITEMS" -gt 0 ]; then
  COMPLETION_RATE=$((completed_count * 100 / TOTAL_ITEMS))
else
  COMPLETION_RATE=0
fi

# ── Summary ───────────────────────────────────────────────────────────────────
po_success_rule "✅ Sprint Review Summary"
printf '  %bSprint:%b           %s (%s)\n' "$PO_BOLD" "$PO_NC" "$SPRINT_NUM" "$SPRINT_DATES"
printf '  %bCompleted:%b        %d items\n' "$PO_BOLD" "$PO_NC" "$completed_count"
printf '  %bIncomplete:%b       %d items\n' "$PO_BOLD" "$PO_NC" "$incomplete_count"
printf '  %bCompletion Rate:%b  %d%%\n' "$PO_BOLD" "$PO_NC" "$COMPLETION_RATE"
echo ""

if ! po_confirm_save "Does this look correct? (y=save / n=redo)"; then
  po_dim "  Restarting phase 5..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Sprint Review"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Sprint Information"
  echo ""
  echo "**Sprint:** $SPRINT_NUM"
  echo ""
  echo "**Dates:** $SPRINT_DATES"
  echo ""
  echo "## Metrics"
  echo ""
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Items Completed | $completed_count |"
  echo "| Items Incomplete | $incomplete_count |"
  echo "| Total Items | $TOTAL_ITEMS |"
  echo "| Completion Rate | $COMPLETION_RATE% |"
  echo ""
  echo "## Items Completed"
  echo ""

  if [ "$completed_count" -gt 0 ]; then
    echo "| Item | Sizing |"
    echo "|------|--------|"
    for ((i=0; i<completed_count; i++)); do
      printf "| %s | %s |\n" "${COMPLETED_ITEMS[$i]}" "${COMPLETED_SIZING[$i]}"
    done
    echo ""
  else
    echo "(No items completed)"
    echo ""
  fi

  echo "## Items Not Completed"
  echo ""
  if [ "$incomplete_count" -gt 0 ]; then
    echo "| Item | Reason |"
    echo "|------|--------|"
    for ((i=0; i<incomplete_count; i++)); do
      printf "| %s | %s |\n" "${INCOMPLETE_ITEMS[$i]}" "${INCOMPLETE_REASONS[$i]}"
    done
    echo ""
  else
    echo "(All planned items completed)"
    echo ""
  fi

  echo "## Demo Items & Highlights"
  echo ""
  echo "- $(echo "$DEMO_ITEMS" | sed 's/, /\n- /g')"
  echo ""
  echo "## Stakeholder Feedback"
  echo ""
  echo "$FEEDBACK"
  echo ""
  echo "## Backlog Adjustments & Next Sprint"
  echo ""
  echo "$ADJUSTMENTS"
  echo ""
} > "$OUTPUT_FILE"

po_success_rule "✅ Sprint Review saved"
printf '%b  Output: %s%b\n' "$PO_GREEN" "$OUTPUT_FILE" "$PO_NC"
echo ""

# ── Log new debts ─────────────────────────────────────────────────────────────
end_debts=$(po_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  po_dim "  Logged $new_debts debt(s) — see po-output/06-po-debts.md"
fi
echo ""
