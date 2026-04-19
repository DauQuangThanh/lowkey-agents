#!/bin/bash
# =============================================================================
# impediments.sh — Phase 4: Impediment Tracker
# Logs and prioritizes blockers, escalation status, and SM follow-up.
# Output: $SM_OUTPUT_DIR/04-impediment-log.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
sm_parse_flags "$@"


OUTPUT_FILE="$SM_OUTPUT_DIR/04-impediment-log.md"
AREA="Impediments"

start_debts=$(sm_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
sm_banner "🚧  Phase 4 of 5 — Impediment Tracker"
sm_dim "  Let's capture and prioritize all blockers and impediments."
sm_dim "  I'll help you assign owners and escalate where needed."
echo ""

# ── Collect impediments ────────────────────────────────────────────────────────
IMPEDIMENTS=""
ESCALATIONS=0
BLOCKING_COUNT=0
LOG_DATE=$(date '+%Y-%m-%d')

impediment_count=0
while true; do
  DESCRIPTION=$(sm_ask "Impediment description (or blank to finish):")
  [ -z "$DESCRIPTION" ] && break

  impediment_count=$((impediment_count + 1))
  printf '\n%b%bImpediment %d: %s%b\n' "$SM_MAGENTA" "$SM_BOLD" "$impediment_count" "$DESCRIPTION" "$SM_NC"

  SEVERITY=$(sm_ask_choice "What is the severity?" \
    "Blocking — stops all progress" \
    "Degrading — slows progress" \
    "Minor — low impact")

  case "$SEVERITY" in
    *Blocking*) BLOCKING_COUNT=$((BLOCKING_COUNT + 1)) SEV_EMOJI="🔴" ;;
    *Degrading*) SEV_EMOJI="🟡" ;;
    *Minor*) SEV_EMOJI="🟢" ;;
  esac

  echo ""
  AFFECTED=$(sm_ask "  Which stories/tasks are affected?")
  [ -z "$AFFECTED" ] && AFFECTED="Unclear"

  echo ""
  ESCALATE=$(sm_ask_yn "  Does this need escalation? (y/n)")
  if [ "$ESCALATE" = "yes" ]; then
    ESCALATIONS=$((ESCALATIONS + 1))
    ESC_MARK="⬆️  YES"
  else
    ESC_MARK="No"
  fi

  echo ""
  OWNER=$(sm_ask "  Who should resolve this? (name or role)")
  [ -z "$OWNER" ] && OWNER="TBD"

  echo ""
  TARGET=$(sm_ask "  Target resolution date? (blank for TBD)")
  [ -z "$TARGET" ] && TARGET="TBD"

  IMPEDIMENTS="${IMPEDIMENTS}### $SEV_EMOJI Impediment $impediment_count: $DESCRIPTION

**Severity:** $SEVERITY

**Affected Work:** $AFFECTED

**Escalation:** $ESC_MARK

**Owner:** $OWNER

**Target Resolution:** $TARGET

"

  sm_add_debt "$AREA" "$DESCRIPTION" \
    "Impediment: $DESCRIPTION (affects: $AFFECTED)" \
    "Work blocked or degraded until resolved"

  echo ""
done

[ -z "$IMPEDIMENTS" ] && IMPEDIMENTS="(No impediments logged)"

# ── Summary ───────────────────────────────────────────────────────────────────
sm_success_rule "✅ Impediment Summary"
printf '  %bDate:%b                %s\n' "$SM_BOLD" "$SM_NC" "$LOG_DATE"
printf '  %bTotal impediments:%b   %d\n' "$SM_BOLD" "$SM_NC" "$impediment_count"
printf '  %bBlocking issues:%b     %d\n' "$SM_BOLD" "$SM_NC" "$BLOCKING_COUNT"
printf '  %bEscalations needed:%b  %d\n' "$SM_BOLD" "$SM_NC" "$ESCALATIONS"
echo ""

if ! sm_confirm_save "Save impediment log? (y=save / n=redo)"; then
  sm_dim "  Restarting Phase 4..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_TIME=$(date '+%Y-%m-%d %H:%M')
{
  echo "# Impediment Log"
  echo ""
  echo "> Captured: $DATE_TIME"
  echo ""
  echo "## Summary"
  echo ""
  echo "**Log Date:** $LOG_DATE"
  echo "**Total Impediments:** $impediment_count"
  echo "**Blocking Issues:** $BLOCKING_COUNT"
  echo "**Escalations Required:** $ESCALATIONS"
  echo ""
  echo "---"
  echo ""
  echo "## Impediments"
  echo ""
  if [ "$impediment_count" -gt 0 ]; then
    echo "$IMPEDIMENTS"
  else
    echo "$IMPEDIMENTS"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## SM Actions"
  echo ""
  if [ "$impediment_count" -gt 0 ]; then
    echo "- [ ] Follow up on $impediment_count impediment(s)"
    if [ "$BLOCKING_COUNT" -gt 0 ]; then
      echo "- [ ] Immediately address $BLOCKING_COUNT blocking issue(s)"
    fi
    if [ "$ESCALATIONS" -gt 0 ]; then
      echo "- [ ] Escalate $ESCALATIONS issue(s) to leadership"
    fi
    echo "- [ ] Daily check-in on resolution progress"
  else
    echo "- [ ] No impediments identified — team is unblocked"
  fi
  echo ""
} > "$OUTPUT_FILE"

sm_success_rule "✅ Impediment log saved to $OUTPUT_FILE"

end_debts=$(sm_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  sm_dim "  ⚠️  $new_debts impediment(s) logged as debts. Review in $SM_DEBT_FILE"
fi
