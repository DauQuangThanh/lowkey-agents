#!/bin/bash
# =============================================================================
# standup.sh — Phase 2: Daily Standup Notes
# Facilitates standup collection for each team member.
# Output: $SM_OUTPUT_DIR/02-standup-log.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
sm_parse_flags "$@"


OUTPUT_FILE="$SM_OUTPUT_DIR/02-standup-log.md"
AREA="Standup"

start_debts=$(sm_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
sm_banner "☀️  Phase 2 of 5 — Daily Standup"
sm_dim "  Let's capture standup updates from each team member."
sm_dim "  I'll ask: What did you do? What will you do? Any blockers?"
echo ""

# ── Q1: Number of team members ─────────────────────────────────────────────────
printf '%b%bSetup%b\n' "$SM_CYAN" "$SM_BOLD" "$SM_NC"
STANDUP_DATE=$(date '+%Y-%m-%d')
echo ""

# ── Collect standup for each team member ───────────────────────────────────────
TEAM_MEMBERS=""
BLOCKERS=""
BLOCKERS_COUNT=0

member_count=0
while true; do
  MEMBER=$(sm_ask "Team member name (or blank to finish):")
  [ -z "$MEMBER" ] && break

  member_count=$((member_count + 1))
  printf '\n%b%bTeam Member %d: %s%b\n' "$SM_MAGENTA" "$SM_BOLD" "$member_count" "$MEMBER" "$SM_NC"

  YESTERDAY=$(sm_ask "  What did you accomplish yesterday?")
  [ -z "$YESTERDAY" ] && YESTERDAY="(Nothing to report)"

  echo ""
  TODAY=$(sm_ask "  What will you work on today?")
  [ -z "$TODAY" ] && TODAY="(TBD)"

  echo ""
  BLOCKER=$(sm_ask "  Any blockers or impediments? (blank if none)")

  TEAM_MEMBERS="${TEAM_MEMBERS}### $MEMBER

**Yesterday:** $YESTERDAY

**Today:** $TODAY

**Blockers:** "

  if [ -z "$BLOCKER" ]; then
    TEAM_MEMBERS="${TEAM_MEMBERS}None"
    BLOCKER="None"
  else
    TEAM_MEMBERS="${TEAM_MEMBERS}⚠️ $BLOCKER"
    BLOCKERS="${BLOCKERS}- $MEMBER: $BLOCKER"$'\n'
    BLOCKERS_COUNT=$((BLOCKERS_COUNT + 1))
    sm_add_debt "$AREA" "Blocker: $BLOCKER" \
      "$MEMBER blocked on: $BLOCKER" \
      "Unblocking decision or task needed"
  fi

  TEAM_MEMBERS="${TEAM_MEMBERS}

"
  echo ""
done

[ -z "$TEAM_MEMBERS" ] && TEAM_MEMBERS="(No team members logged)"
[ -z "$BLOCKERS" ] && BLOCKERS="None identified"

# ── Summary ───────────────────────────────────────────────────────────────────
sm_success_rule "✅ Standup Summary"
printf '  %bDate:%b          %s\n' "$SM_BOLD" "$SM_NC" "$STANDUP_DATE"
printf '  %bTeam members:%b  %d\n' "$SM_BOLD" "$SM_NC" "$member_count"
printf '  %bBlockers:%b      %d\n' "$SM_BOLD" "$SM_NC" "$BLOCKERS_COUNT"
echo ""

if ! sm_confirm_save "Save standup notes? (y=save / n=redo)"; then
  sm_dim "  Restarting Phase 2..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_TIME=$(date '+%Y-%m-%d %H:%M')
{
  echo "# Daily Standup"
  echo ""
  echo "> Captured: $DATE_TIME"
  echo ""
  echo "## Standup Date"
  echo ""
  echo "**Date:** $STANDUP_DATE"
  echo "**Team Members Reporting:** $member_count"
  echo ""
  echo "## Team Updates"
  echo ""
  echo "$TEAM_MEMBERS"
  echo "---"
  echo ""
  echo "## Impediments Summary"
  echo ""
  echo "**Blockers Identified:** $BLOCKERS_COUNT"
  echo ""
  if [ "$BLOCKERS_COUNT" -gt 0 ]; then
    echo "$BLOCKERS"
  else
    echo "None identified"
  fi
  echo ""
  echo "## SM Actions"
  echo ""
  if [ "$BLOCKERS_COUNT" -gt 0 ]; then
    echo "- [ ] Follow up on $BLOCKERS_COUNT blocker(s)"
    echo "- [ ] Escalate if needed to stakeholders"
  else
    echo "- [ ] Team is unblocked and moving forward"
  fi
  echo ""
} > "$OUTPUT_FILE"

sm_success_rule "✅ Standup log saved to $OUTPUT_FILE"

end_debts=$(sm_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  sm_dim "  ⚠️  $new_debts blocker(s) logged as debts. Review in $SM_DEBT_FILE"
fi
