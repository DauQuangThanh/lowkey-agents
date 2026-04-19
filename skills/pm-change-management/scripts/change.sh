#!/bin/bash
# =============================================================================
# change.sh — Phase 5: Change Request Tracking
# Captures change requests with impact assessment, priority, and approval status.
# Output: pm-output/05-change-log.md
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
pm_parse_flags "$@"


pm_banner "Phase 5: Change Request Tracking"

CHANGES=""
CHANGE_COUNT=0

# ── Loop: Add change requests one at a time ───────────────────────────────────
while true; do
  printf '\n%b▶ Add a change request (or press Enter to finish).%b\n' "$PM_YELLOW" "$PM_NC"
  CR_DESC=$(pm_ask "Change request description (what is changing and why?)")
  [ -z "$CR_DESC" ] && break

  CR_REASON=$(pm_ask "Reason for the change (business justification)")
  pm_dim "Reason: $CR_REASON"

  SCOPE_IMPACT=$(pm_ask_choice \
    "Impact on scope?" \
    "High (affects major features)" \
    "Medium (affects some functionality)" \
    "Low (affects documentation/minor features)" \
    "None")
  SCOPE_IMPACT="${SCOPE_IMPACT:0:1}"
  pm_dim "Scope impact: $SCOPE_IMPACT"

  SCHEDULE_IMPACT=$(pm_ask_choice \
    "Impact on schedule?" \
    "High (delays major milestone)" \
    "Medium (delays features by weeks)" \
    "Low (delays by days or none)" \
    "None")
  SCHEDULE_IMPACT="${SCHEDULE_IMPACT:0:1}"
  pm_dim "Schedule impact: $SCHEDULE_IMPACT"

  BUDGET_IMPACT=$(pm_ask_choice \
    "Impact on budget?" \
    "High (increases budget >20%)" \
    "Medium (increases 5-20%)" \
    "Low (increases <5%)" \
    "None")
  BUDGET_IMPACT="${BUDGET_IMPACT:0:1}"
  pm_dim "Budget impact: $BUDGET_IMPACT"

  QUALITY_IMPACT=$(pm_ask_choice \
    "Impact on quality?" \
    "High (may reduce quality)" \
    "Medium (requires extra testing)" \
    "Low (minimal quality impact)" \
    "None")
  QUALITY_IMPACT="${QUALITY_IMPACT:0:1}"
  pm_dim "Quality impact: $QUALITY_IMPACT"

  PRIORITY=$(pm_ask_choice \
    "Priority?" \
    "🔴 Critical (blocks other work)" \
    "🟡 High (important, needs quick approval)" \
    "🟢 Medium (standard approval)" \
    "🔵 Low (can defer)")
  pm_dim "Priority: $PRIORITY"

  STATUS=$(pm_ask_choice \
    "Approval status?" \
    "Pending (awaiting review)" \
    "Approved" \
    "Rejected" \
    "On Hold")
  pm_dim "Status: $STATUS"

  APPROVAL_REASON=""
  if [ "$STATUS" = "Approved" ] || [ "$STATUS" = "Rejected" ] || [ "$STATUS" = "On Hold" ]; then
    APPROVAL_REASON=$(pm_ask "Decision reason / comments")
    pm_dim "Reason: $APPROVAL_REASON"
  fi

  APPROVER=$(pm_ask "Approved/reviewed by (name/role)")
  pm_dim "Approver: $APPROVER"

  # Append to changes string
  CHANGE_COUNT=$((CHANGE_COUNT + 1))
  CHANGE_ENTRY="CR-$(printf '%02d' "$CHANGE_COUNT")|$CR_DESC|$CR_REASON|$SCOPE_IMPACT|$SCHEDULE_IMPACT|$BUDGET_IMPACT|$QUALITY_IMPACT|$PRIORITY|$STATUS|$APPROVAL_REASON|$APPROVER"
  if [ -z "$CHANGES" ]; then
    CHANGES="$CHANGE_ENTRY"
  else
    CHANGES="$CHANGES"$'\n'"$CHANGE_ENTRY"
  fi

  printf '\n'
  pm_ask_yn "Add another change request?"
  if [ $? -ne 0 ]; then
    break
  fi
done

if [ "$CHANGE_COUNT" -eq 0 ]; then
  pm_dim "No change requests logged yet."
  CHANGES="(No changes logged)"
fi

# ── Confirmation ──────────────────────────────────────────────────────────────
printf '\n'
pm_ask_yn "Save this change log?"
if [ $? -ne 0 ]; then
  pm_dim "Change log discarded. Exiting."
  exit 0
fi

# ── Write Output ──────────────────────────────────────────────────────────────
OUTPUT_FILE="$PM_OUTPUT_DIR/05-change-log.md"

{
  printf '# Change Log\n\n'
  printf '**Date:** %s\n' "$(date '+%d/%m/%Y')"
  printf '**Total Changes:** %d\n\n' "$CHANGE_COUNT"

  printf '## Change Summary\n'
  if [ "$CHANGE_COUNT" -gt 0 ]; then
    APPROVED=$(printf '%s' "$CHANGES" | grep -c 'Approved' || printf '0')
    PENDING=$(printf '%s' "$CHANGES" | grep -c 'Pending' || printf '0')
    REJECTED=$(printf '%s' "$CHANGES" | grep -c 'Rejected' || printf '0')
    printf '| Status | Count |\n'
    printf '|---|---|\n'
    printf '| Approved | %d |\n' "$APPROVED"
    printf '| Pending | %d |\n' "$PENDING"
    printf '| Rejected | %d |\n\n' "$REJECTED"
  fi

  printf '## Changes\n\n'
  if [ "$CHANGE_COUNT" -gt 0 ]; then
    printf '%s\n' "$CHANGES" | while IFS='|' read -r id desc reason scope schedule budget quality priority status approval_reason approver; do
      printf '### %s: %s\n' "$id" "$desc"
      printf '**Requested By:** TBD\n'
      printf '**Request Date:** %s\n' "$(date '+%d/%m/%Y')"
      printf '**Priority:** %s\n' "$priority"
      printf '**Status:** %s\n\n' "$status"

      printf '**Business Reason:** %s\n\n' "$reason"

      printf '**Impact Assessment:**\n'
      printf '| Area | Impact |\n'
      printf '|---|---|\n'
      printf '| Scope | %s |\n' "$scope"
      printf '| Schedule | %s |\n' "$schedule"
      printf '| Budget | %s |\n' "$budget"
      printf '| Quality | %s |\n\n' "$quality"

      printf '**Decision:** %s\n' "$status"
      if [ -n "$approval_reason" ]; then
        printf '**Reason:** %s\n' "$approval_reason"
      fi
      printf '**Approved By:** %s\n' "$approver"
      printf '**Date Approved:** TBD\n\n'
    done
  else
    printf '(No changes logged)\n\n'
  fi

  printf '## Process\n'
  printf '1. Requestor submits CR with description and business case\n'
  printf '2. PM assesses impact on scope, schedule, budget, quality\n'
  printf '3. CCB (Change Control Board) reviews and votes\n'
  printf '4. If approved: PM updates plan and communicates to team\n'
  printf '5. If rejected: PM documents reason and archives CR for audit trail\n'
} > "$OUTPUT_FILE"

pm_success_rule "Change log written to $OUTPUT_FILE"
printf '\n'

# ── Final Summary ─────────────────────────────────────────────────────────────
pm_dim "Summary:"
pm_dim "  Total Changes: $CHANGE_COUNT"
if [ "$CHANGE_COUNT" -gt 0 ]; then
  APPROVED=$(printf '%s' "$CHANGES" | grep -c 'Approved' || printf '0')
  PENDING=$(printf '%s' "$CHANGES" | grep -c 'Pending' || printf '0')
  REJECTED=$(printf '%s' "$CHANGES" | grep -c 'Rejected' || printf '0')
  pm_dim "  Approved: $APPROVED"
  pm_dim "  Pending: $PENDING"
  pm_dim "  Rejected: $REJECTED"
fi

DEBT_COUNT=$(pm_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '\n%b⚠ %d open PM debt(s) to resolve — see %s%b\n' \
    "$PM_YELLOW" "$DEBT_COUNT" "$PM_DEBT_FILE" "$PM_NC"
fi

printf '\n%b✓ Phase 5 complete.%b\n\n' "$PM_GREEN" "$PM_NC"
