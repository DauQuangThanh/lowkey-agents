#!/bin/bash
# =============================================================================
# tracking.sh — Phase 2: Status Tracking & Reporting
# Captures: reporting period, RAG status, accomplishments, activities,
# blockers/issues, and budget status.
# Output: pm-output/02-status-report.md
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
pm_parse_flags "$@"


pm_banner "Phase 2: Status Tracking & Reporting"

# ── Question 1: Reporting Period ──────────────────────────────────────────────
PERIOD=$(pm_ask_choice \
  "What is your reporting period?" \
  "Weekly" \
  "Bi-weekly" \
  "Monthly" \
  "Per-milestone")
pm_dim "Reporting period: $PERIOD"

# ── Question 2: RAG Status ────────────────────────────────────────────────────
RAG_STATUS=$(pm_ask_choice \
  "What is the overall project RAG status?" \
  "🟢 GREEN (On track)" \
  "🟡 AMBER (At risk)" \
  "🔴 RED (Off track)")
pm_dim "Status: $RAG_STATUS"

# ── Question 3: Key Accomplishments ───────────────────────────────────────────
printf '\n%b▶ List key accomplishments this period.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: Completed design review, Deployed to staging, Fixed critical bugs)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

ACCOMPLISHMENTS=""
while true; do
  item=$(pm_ask "Add accomplishment (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$ACCOMPLISHMENTS" ]; then
    ACCOMPLISHMENTS="$item"
  else
    ACCOMPLISHMENTS="$ACCOMPLISHMENTS"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$ACCOMPLISHMENTS" ]; then
  pm_dim "No accomplishments recorded — logging as debt."
  pm_add_debt "Tracking" "No accomplishments recorded" "No progress documented this period" "Cannot track momentum or communicate success"
  ACCOMPLISHMENTS="(None documented)"
fi

# ── Question 4: Planned Activities ────────────────────────────────────────────
printf '\n%b▶ List planned activities for the next period.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: Start development, User acceptance testing, Deploy to production)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

ACTIVITIES=""
while true; do
  item=$(pm_ask "Add planned activity (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$ACTIVITIES" ]; then
    ACTIVITIES="$item"
  else
    ACTIVITIES="$ACTIVITIES"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$ACTIVITIES" ]; then
  pm_dim "No planned activities defined — logging as debt."
  pm_add_debt "Tracking" "No planned activities" "Next period activities are undefined" "Cannot manage expectations or dependencies"
  ACTIVITIES="(TBD)"
fi

# ── Question 5: Blockers & Issues ─────────────────────────────────────────────
printf '\n%b▶ Identify any blockers or issues preventing progress.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Format: Issue description | Owner | Target resolution date)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

BLOCKERS=""
while true; do
  item=$(pm_ask "Add blocker/issue (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$BLOCKERS" ]; then
    BLOCKERS="$item"
  else
    BLOCKERS="$BLOCKERS"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$BLOCKERS" ]; then
  pm_dim "No blockers identified."
else
  pm_dim "Blockers recorded and will be tracked."
fi

# ── Question 6: Budget Status ─────────────────────────────────────────────────
printf '\n%b▶ What is the current budget status?%b\n' "$PM_YELLOW" "$PM_NC"
BUDGET_STATUS=$(pm_ask_choice \
  "Budget status:" \
  "On track" \
  "Over budget" \
  "Under budget" \
  "Not tracking budget")
pm_dim "Budget: $BUDGET_STATUS"

# Only ask for variance if applicable
BUDGET_VARIANCE=""
if [ "$BUDGET_STATUS" != "Not tracking budget" ]; then
  BUDGET_VARIANCE=$(pm_ask "What is the budget variance? (e.g., +5%, -10%, or $5000 under)")
  pm_dim "Variance: $BUDGET_VARIANCE"
fi

# ── Confirmation ──────────────────────────────────────────────────────────────
printf '\n'
pm_ask_yn "Save this status report?"
if [ $? -ne 0 ]; then
  pm_dim "Report discarded. Exiting."
  exit 0
fi

# ── Write Output ──────────────────────────────────────────────────────────────
OUTPUT_FILE="$PM_OUTPUT_DIR/02-status-report.md"

{
  printf '# Status Report\n\n'
  printf '**Period:** %s\n' "$(date '+%d/%m/%Y')"
  printf '**Reporting Cadence:** %s\n\n' "$PERIOD"

  # Extract status indicator
  if [[ "$RAG_STATUS" == *"GREEN"* ]]; then
    STATUS_INDICATOR="🟢 GREEN"
  elif [[ "$RAG_STATUS" == *"AMBER"* ]]; then
    STATUS_INDICATOR="🟡 AMBER"
  else
    STATUS_INDICATOR="🔴 RED"
  fi

  printf '## Overall Status\n'
  printf '**RAG: %s**\n\n' "$STATUS_INDICATOR"
  printf '[One paragraph covering overall health — to be completed by project manager]\n\n'

  printf '## Key Accomplishments This Period\n'
  if [ "$ACCOMPLISHMENTS" != "(None documented)" ]; then
    printf '%s\n' "$ACCOMPLISHMENTS" | sed 's/^/1. /'
  else
    printf '%s\n' "$ACCOMPLISHMENTS"
  fi
  printf '\n'

  printf '## Planned Activities Next Period\n'
  if [ "$ACTIVITIES" != "(TBD)" ]; then
    printf '%s\n' "$ACTIVITIES" | sed 's/^/1. /'
  else
    printf '%s\n' "$ACTIVITIES"
  fi
  printf '\n'

  printf '## Budget Status\n'
  printf '**Status:** %s\n' "$BUDGET_STATUS"
  if [ -n "$BUDGET_VARIANCE" ]; then
    printf '**Variance:** %s\n' "$BUDGET_VARIANCE"
  fi
  printf '\n'

  printf '## Blockers & Issues\n'
  if [ -n "$BLOCKERS" ]; then
    printf '### Active Issues\n'
    printf '%s\n' "$BLOCKERS" | sed 's/^/- /'
  else
    printf -- '- None at this time\n'
  fi
  printf '\n'

  printf '## Risks Escalated This Period\n'
  printf -- '- [Add any newly escalated risks]\n\n'

  printf '## Next Steps & Decisions Required\n'
  printf '1. [Decision needed]: Owner [Name], due [Date]\n'
  printf '2. [Approval needed]: Owner [Name], due [Date]\n'
} > "$OUTPUT_FILE"

pm_success_rule "Status report written to $OUTPUT_FILE"
printf '\n'

# ── Final Summary ─────────────────────────────────────────────────────────────
pm_dim "Summary:"
pm_dim "  Reporting Period: $PERIOD"
pm_dim "  RAG Status: $STATUS_INDICATOR"
pm_dim "  Accomplishments: $(printf '%s' "$ACCOMPLISHMENTS" | wc -l | tr -d ' ') items"
pm_dim "  Planned Activities: $(printf '%s' "$ACTIVITIES" | wc -l | tr -d ' ') items"
pm_dim "  Budget Status: $BUDGET_STATUS"
if [ -n "$BLOCKERS" ]; then
  pm_dim "  Blockers: $(printf '%s' "$BLOCKERS" | wc -l | tr -d ' ') identified"
fi

DEBT_COUNT=$(pm_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '\n%b⚠ %d open PM debt(s) to resolve — see %s%b\n' \
    "$PM_YELLOW" "$DEBT_COUNT" "$PM_DEBT_FILE" "$PM_NC"
fi

printf '\n%b✓ Phase 2 complete.%b\n\n' "$PM_GREEN" "$PM_NC"
