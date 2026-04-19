#!/bin/bash
# =============================================================================
# team-health.sh — Phase 5: Team Health & Velocity
# Measures team health, velocity trends, and morale for coaching.
# Output: $SM_OUTPUT_DIR/05-team-health.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
sm_parse_flags "$@"


OUTPUT_FILE="$SM_OUTPUT_DIR/05-team-health.md"
AREA="Team Health"

start_debts=$(sm_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
sm_banner "💚  Phase 5 of 5 — Team Health & Velocity"
sm_dim "  Let's measure how the team is doing — velocity, morale, collaboration."
sm_dim "  These metrics help us coach the team toward sustainable high performance."
echo ""

# ── Q1: Velocity ───────────────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 3 — Velocity%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
SPRINT_NUM=$(sm_ask "Which sprint? (e.g. Sprint 5)")
[ -z "$SPRINT_NUM" ] && SPRINT_NUM="Sprint-Unknown"

PLANNED_VEL=$(sm_ask "How many points were planned? (or leave blank)")
[ -z "$PLANNED_VEL" ] && PLANNED_VEL="TBD"

ACTUAL_VEL=$(sm_ask "How many points were completed?")
[ -z "$ACTUAL_VEL" ] && ACTUAL_VEL="TBD"

COMPLETION_RATE="N/A"
if [ "$PLANNED_VEL" != "TBD" ] && [ "$ACTUAL_VEL" != "TBD" ] && [ "$PLANNED_VEL" -gt 0 ]; then
  COMPLETION_RATE=$(( (ACTUAL_VEL * 100) / PLANNED_VEL ))%
fi

# ── Q2: Morale & Collaboration ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 3 — Team Sentiment%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  Rate on a scale of 1-5 (1=very low, 5=excellent)"
echo ""

MORALE=$(sm_ask "Team morale / engagement? (1-5)")
[ -z "$MORALE" ] && MORALE="TBD"
case "$MORALE" in
  1) MORALE_EMOJI="😢" ;;
  2) MORALE_EMOJI="😕" ;;
  3) MORALE_EMOJI="😐" ;;
  4) MORALE_EMOJI="🙂" ;;
  5) MORALE_EMOJI="😄" ;;
  *) MORALE_EMOJI="❓"; MORALE="TBD" ;;
esac

COLLABORATION=$(sm_ask "Collaboration / teamwork? (1-5)")
[ -z "$COLLABORATION" ] && COLLABORATION="TBD"

TECHNICAL=$(sm_ask "Technical practices (testing, code review, etc)? (1-5)")
[ -z "$TECHNICAL" ] && TECHNICAL="TBD"

# ── Q3: Trends & Coaching ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 3 — Trends & Coaching Notes%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
sm_dim "  Are velocity, morale, or practices improving, stable, or declining?"
echo ""

TREND=$(sm_ask_choice "Overall trend?" \
  "Improving 📈 — team getting stronger" \
  "Stable ➡️ — consistent performance" \
  "Declining 📉 — needs coaching")

echo ""
COACHING=$(sm_ask "Any specific coaching observations or areas to focus on?")
[ -z "$COACHING" ] && COACHING="(None recorded)"

# ── Summary ───────────────────────────────────────────────────────────────────
sm_success_rule "✅ Team Health Summary"
printf '  %bSprint:%b                %s\n' "$SM_BOLD" "$SM_NC" "$SPRINT_NUM"
printf '  %bVelocity:%b              %s / %s points (%s)\n' "$SM_BOLD" "$SM_NC" "$ACTUAL_VEL" "$PLANNED_VEL" "$COMPLETION_RATE"
printf '  %bMorale:%b                %s/5 %s\n' "$SM_BOLD" "$SM_NC" "$MORALE" "$MORALE_EMOJI"
printf '  %bCollaboration:%b         %s/5\n' "$SM_BOLD" "$SM_NC" "$COLLABORATION"
printf '  %bTechnical practices:%b   %s/5\n' "$SM_BOLD" "$SM_NC" "$TECHNICAL"
printf '  %bTrend:%b                 %s\n' "$SM_BOLD" "$SM_NC" "$TREND"
echo ""

if ! sm_confirm_save "Save team health report? (y=save / n=redo)"; then
  sm_dim "  Restarting Phase 5..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_TIME=$(date '+%Y-%m-%d %H:%M')
{
  echo "# Team Health & Velocity"
  echo ""
  echo "> Captured: $DATE_TIME"
  echo ""
  echo "## Sprint Summary"
  echo ""
  echo "**Sprint:** $SPRINT_NUM"
  echo ""
  echo "### Velocity"
  echo ""
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Planned | $PLANNED_VEL points |"
  echo "| Completed | $ACTUAL_VEL points |"
  echo "| Completion Rate | $COMPLETION_RATE |"
  echo ""
  echo "---"
  echo ""
  echo "## Team Health Metrics"
  echo ""
  echo "| Dimension | Rating | Status |"
  echo "|-----------|--------|--------|"
  echo "| Morale / Engagement | $MORALE/5 | $MORALE_EMOJI |"
  echo "| Collaboration / Teamwork | $COLLABORATION/5 | |"
  echo "| Technical Practices | $TECHNICAL/5 | |"
  echo ""
  echo "---"
  echo ""
  echo "## Trend Analysis"
  echo ""
  echo "**Overall Trend:** $TREND"
  echo ""
  echo "### Coaching Notes"
  echo ""
  echo "$COACHING"
  echo ""
  echo "---"
  echo ""
  echo "## SM Coaching Actions"
  echo ""
  if [ "$MORALE" != "TBD" ] && [ "$MORALE" -lt 3 ]; then
    echo "- [ ] Check in 1:1 with team members on morale concerns"
  fi
  if [ "$COLLABORATION" != "TBD" ] && [ "$COLLABORATION" -lt 3 ]; then
    echo "- [ ] Facilitate team building or communication workshop"
  fi
  if [ "$TECHNICAL" != "TBD" ] && [ "$TECHNICAL" -lt 3 ]; then
    echo "- [ ] Coach team on technical practices (testing, code review, etc)"
  fi
  if [ "$COMPLETION_RATE" != "N/A" ] && [[ "$COMPLETION_RATE" == *"50"* ]]; then
    echo "- [ ] Investigate why completion rate is low (capacity? scope creep?)"
  fi
  echo ""
} > "$OUTPUT_FILE"

sm_success_rule "✅ Team health report saved to $OUTPUT_FILE"

end_debts=$(sm_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  sm_dim "  ⚠️  $new_debts health concern(s) noted. Review in $SM_DEBT_FILE"
fi
