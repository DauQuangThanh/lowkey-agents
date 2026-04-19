#!/bin/bash
# =============================================================================
# sprint-planning.sh — Phase 1: Sprint Planning
# Facilitates sprint planning with goal, capacity, story commitment, DoD review.
# Output: $SM_OUTPUT_DIR/01-sprint-plan.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
sm_parse_flags "$@"


OUTPUT_FILE="$SM_OUTPUT_DIR/01-sprint-plan.md"
AREA="Sprint Planning"

start_debts=$(sm_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
sm_banner "📋  Phase 1 of 5 — Sprint Planning"
sm_dim "  Let's plan this sprint together. I'll ask about goals, capacity, and scope."
sm_dim "  You can also load stories from your backlog if they exist."
echo ""

# ── Q1: Sprint number and goal ─────────────────────────────────────────────────
printf '%b%bQuestion 1 / 8 — Sprint Identification%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
SPRINT_NUM=$(sm_ask "What sprint number is this? (e.g. 1, 2, Sprint-Q2-2026)")
[ -z "$SPRINT_NUM" ] && SPRINT_NUM="Sprint-TBD"

echo ""
printf '%b%bQuestion 2 / 8 — Sprint Goal%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  A sprint goal is ONE sentence that captures the team's focus."
sm_dim "  Example: 'Complete user authentication and basic dashboard.'"
echo ""
SPRINT_GOAL=$(sm_ask "What is the sprint goal?")
if [ -z "$SPRINT_GOAL" ]; then
  SPRINT_GOAL="TBD"
  sm_add_debt "$AREA" "Sprint goal not defined" \
    "No clear sprint goal established" \
    "Team alignment and sprint focus"
fi

# ── Q3: Sprint duration ───────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 8 — Sprint Duration%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
DURATION=$(sm_ask_choice "How long is this sprint?" \
  "1 week" \
  "2 weeks" \
  "3 weeks" \
  "4 weeks")

# Calculate sprint dates
START_DATE=$(date '+%Y-%m-%d')
case "$DURATION" in
  "1 week")  END_DATE=$(date -d "+7 days" '+%Y-%m-%d' 2>/dev/null || date -v+7d '+%Y-%m-%d' 2>/dev/null || echo "TBD") ;;
  "2 weeks") END_DATE=$(date -d "+14 days" '+%Y-%m-%d' 2>/dev/null || date -v+14d '+%Y-%m-%d' 2>/dev/null || echo "TBD") ;;
  "3 weeks") END_DATE=$(date -d "+21 days" '+%Y-%m-%d' 2>/dev/null || date -v+21d '+%Y-%m-%d' 2>/dev/null || echo "TBD") ;;
  "4 weeks") END_DATE=$(date -d "+28 days" '+%Y-%m-%d' 2>/dev/null || date -v+28d '+%Y-%m-%d' 2>/dev/null || echo "TBD") ;;
esac

# ── Q4: Team capacity ──────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 8 — Team Capacity%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
CAPACITY_TYPE=$(sm_ask_choice "How will you measure team capacity?" \
  "Story points per sprint" \
  "Team hours available" \
  "Number of stories")

echo ""
TEAM_CAPACITY=$(sm_ask "What is the team's total available capacity? (e.g. 40 points, 160 hours, 8 stories)")
if [ -z "$TEAM_CAPACITY" ]; then
  TEAM_CAPACITY="TBD"
  sm_add_debt "$AREA" "Team capacity not estimated" \
    "No capacity baseline established for sprint" \
    "Scope definition and commitment decisions"
fi

# ── Q5: Committed stories ──────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 8 — Stories to Commit%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  List the user stories you're committing to this sprint."
sm_dim "  You can paste story IDs, titles, or descriptions. One per line."
sm_dim "  (Press Enter twice when done)"
echo ""

STORIES=""
while true; do
  STORY=$(sm_ask "Story (or blank to finish):")
  [ -z "$STORY" ] && break
  STORIES="$STORIES- $STORY"$'\n'
done
[ -z "$STORIES" ] && STORIES="(To be added)"

# ── Q6: Acceptance criteria ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 8 — Acceptance Criteria Review%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
AC_REVIEW=$(sm_ask_yn "Have all committed stories been reviewed for acceptance criteria?")
if [ "$AC_REVIEW" = "no" ]; then
  sm_add_debt "$AREA" "Acceptance criteria incomplete" \
    "Stories lack clear acceptance criteria" \
    "Development clarity and testing readiness"
fi

# ── Q7: Definition of Done ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 7 / 8 — Definition of Done (DoD)%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  Does the team have a clear Definition of Done? (What makes a story complete?)"
echo ""
DOD_CONFIRMED=$(sm_ask_yn "Is the DoD clearly documented and understood by the team?")
DOD_TEXT="(To be documented)"
if [ "$DOD_CONFIRMED" = "yes" ]; then
  DOD_TEXT="✅ Team has confirmed DoD. Closing ceremony will verify all work meets criteria."
fi

# ── Q8: Sprint risks ───────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 8 / 8 — Known Risks%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  Are there any known risks, blockers, or dependencies for this sprint?"
echo ""
RISKS=""
while true; do
  RISK=$(sm_ask "Risk / Blocker (or blank to finish):")
  [ -z "$RISK" ] && break
  RISKS="$RISKS- $RISK"$'\n'
done
[ -z "$RISKS" ] && RISKS="None identified"

# ── Summary ───────────────────────────────────────────────────────────────────
sm_success_rule "✅ Sprint Planning Summary"
printf '  %bSprint:%b         %s\n' "$SM_BOLD" "$SM_NC" "$SPRINT_NUM"
printf '  %bGoal:%b           %s\n' "$SM_BOLD" "$SM_NC" "$SPRINT_GOAL"
printf '  %bDuration:%b       %s (%s to %s)\n' "$SM_BOLD" "$SM_NC" "$DURATION" "$START_DATE" "$END_DATE"
printf '  %bCapacity:%b       %s (%s)\n' "$SM_BOLD" "$SM_NC" "$TEAM_CAPACITY" "$CAPACITY_TYPE"
printf '  %bStories:%b        %d committed\n' "$SM_BOLD" "$SM_NC" "$(echo "$STORIES" | grep -c '^-')"
echo ""

if ! sm_confirm_save "Does this look correct? (y=save / n=redo)"; then
  sm_dim "  Restarting Phase 1..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d %H:%M')
{
  echo "# Sprint Planning"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Sprint Overview"
  echo ""
  echo "**Sprint:** $SPRINT_NUM"
  echo "**Duration:** $DURATION (${START_DATE} → ${END_DATE})"
  echo "**Goal:** $SPRINT_GOAL"
  echo ""
  echo "## Team Capacity"
  echo ""
  echo "**Measurement:** $CAPACITY_TYPE"
  echo "**Available Capacity:** $TEAM_CAPACITY"
  echo ""
  echo "## Committed Stories"
  echo ""
  if [ "$STORIES" = "(To be added)" ]; then
    echo "$STORIES"
  else
    echo "$STORIES"
  fi
  echo ""
  echo "## Quality Standards"
  echo ""
  echo "**Acceptance Criteria:** $AC_REVIEW"
  echo "**Definition of Done:** $DOD_TEXT"
  echo ""
  echo "## Sprint Risks & Dependencies"
  echo ""
  echo "$RISKS"
  echo ""
  echo "---"
  echo ""
  echo "## Sprint Health Baseline"
  echo ""
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Capacity | $TEAM_CAPACITY |"
  echo "| Scope Locked | $([ "$STORIES" = "(To be added)" ] && echo "No" || echo "Yes") |"
  echo "| DoD Confirmed | $DOD_CONFIRMED |"
  echo "| Risks Identified | $([ "$RISKS" = "None identified" ] && echo "No" || echo "Yes") |"
  echo ""
} > "$OUTPUT_FILE"

sm_success_rule "✅ Sprint plan saved to $OUTPUT_FILE"

end_debts=$(sm_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  sm_dim "  ⚠️  $new_debts new debt(s) created. Review in $SM_DEBT_FILE"
fi
