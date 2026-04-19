#!/bin/bash
# =============================================================================
# risk.sh — Phase 3: Risk Management
# Captures risks with likelihood, impact, mitigation, contingency, owner, category.
# Computes risk scores and generates a risk register.
# Output: pm-output/03-risk-register.md
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
pm_parse_flags "$@"


pm_banner "Phase 3: Risk Management"

RISKS=""
RISK_COUNT=0

# ── Loop: Add risks one at a time ─────────────────────────────────────────────
while true; do
  printf '\n%b▶ Add a risk (or press Enter to finish).%b\n' "$PM_YELLOW" "$PM_NC"
  RISK_DESC=$(pm_ask "Risk description (what could go wrong?)")
  [ -z "$RISK_DESC" ] && break

  LIKELIHOOD=$(pm_ask_choice \
    "How likely is this risk?" \
    "1 - Rare (< 10%)" \
    "2 - Unlikely (10-30%)" \
    "3 - Possible (30-50%)" \
    "4 - Likely (50-75%)" \
    "5 - Almost certain (> 75%)")
  LIKELIHOOD_NUM="${LIKELIHOOD:0:1}"
  pm_dim "Likelihood: $LIKELIHOOD"

  IMPACT=$(pm_ask_choice \
    "What is the impact if this risk occurs?" \
    "1 - Negligible (minor inconvenience)" \
    "2 - Minor (small delay or cost)" \
    "3 - Moderate (noticeable effect)" \
    "4 - Major (significant impact)" \
    "5 - Critical (project-threatening)")
  IMPACT_NUM="${IMPACT:0:1}"
  pm_dim "Impact: $IMPACT"

  SCORE=$((LIKELIHOOD_NUM * IMPACT_NUM))
  if [ "$SCORE" -ge 15 ]; then
    SEVERITY="🔴 RED"
  elif [ "$SCORE" -ge 8 ]; then
    SEVERITY="🟡 AMBER"
  else
    SEVERITY="🟢 GREEN"
  fi
  pm_dim "Score: $SCORE ($SEVERITY)"

  CATEGORY=$(pm_ask_choice \
    "Risk category:" \
    "Technical" \
    "Schedule" \
    "Resource" \
    "Budget" \
    "Scope" \
    "External" \
    "Other")
  pm_dim "Category: $CATEGORY"

  MITIGATION=$(pm_ask "Mitigation strategy (what will you do to prevent/reduce this risk?)")
  pm_dim "Mitigation: $MITIGATION"

  CONTINGENCY=$(pm_ask "Contingency plan (what if the risk occurs anyway?)")
  pm_dim "Contingency: $CONTINGENCY"

  OWNER=$(pm_ask "Who owns this risk? (name/role)")
  pm_dim "Owner: $OWNER"

  # Append to risks string
  RISK_COUNT=$((RISK_COUNT + 1))
  RISK_ENTRY="RISK-$(printf '%02d' "$RISK_COUNT")|$RISK_DESC|$LIKELIHOOD_NUM|$IMPACT_NUM|$SCORE|$SEVERITY|$CATEGORY|$MITIGATION|$CONTINGENCY|$OWNER"
  if [ -z "$RISKS" ]; then
    RISKS="$RISK_ENTRY"
  else
    RISKS="$RISKS"$'\n'"$RISK_ENTRY"
  fi

  printf '\n'
  pm_ask_yn "Add another risk?"
  if [ $? -ne 0 ]; then
    break
  fi
done

if [ "$RISK_COUNT" -eq 0 ]; then
  pm_dim "No risks identified."
  pm_add_debt "Risk" "No risks identified" "No project risks were documented" "Cannot manage or mitigate emerging issues"
  RISKS="(No risks identified)"
fi

# ── Confirmation ──────────────────────────────────────────────────────────────
printf '\n'
pm_ask_yn "Save this risk register?"
if [ $? -ne 0 ]; then
  pm_dim "Risk register discarded. Exiting."
  exit 0
fi

# ── Write Output ──────────────────────────────────────────────────────────────
OUTPUT_FILE="$PM_OUTPUT_DIR/03-risk-register.md"

{
  printf '# Risk Register\n\n'
  printf '**Date:** %s\n' "$(date '+%d/%m/%Y')"
  printf '**Total Risks:** %d\n\n' "$RISK_COUNT"

  printf '## Risk Matrix Scoring\n'
  printf -- '- **Score = Likelihood × Impact**\n'
  printf -- '- **15+:** 🔴 RED (must mitigate immediately)\n'
  printf -- '- **8-14:** 🟡 AMBER (plan mitigation)\n'
  printf -- '- **5-7:** 🟢 GREEN (monitor)\n\n'

  printf '## Risk Summary\n'
  if [ "$RISK_COUNT" -gt 0 ]; then
    RED_COUNT=$(printf '%s' "$RISKS" | grep -c '🔴 RED' || printf '0')
    AMBER_COUNT=$(printf '%s' "$RISKS" | grep -c '🟡 AMBER' || printf '0')
    GREEN_COUNT=$(printf '%s' "$RISKS" | grep -c '🟢 GREEN' || printf '0')
    printf '| Severity | Count |\n'
    printf '|---|---|\n'
    printf '| 🔴 RED | %d |\n' "$RED_COUNT"
    printf '| 🟡 AMBER | %d |\n' "$AMBER_COUNT"
    printf '| 🟢 GREEN | %d |\n\n' "$GREEN_COUNT"
  fi

  printf '## Risks\n\n'
  if [ "$RISK_COUNT" -gt 0 ]; then
    printf '%s\n' "$RISKS" | while IFS='|' read -r id desc likelihood impact score severity category mitigation contingency owner; do
      printf '### %s: %s\n' "$id" "$desc"
      printf '**Severity:** %s\n' "$severity"
      printf '**Likelihood:** %s | **Impact:** %s | **Score:** %s\n' "$likelihood" "$impact" "$score"
      printf '**Category:** %s\n' "$category"
      printf '**Mitigation Strategy:** %s\n' "$mitigation"
      printf '**Contingency Plan:** %s\n' "$contingency"
      printf '**Owner:** %s\n' "$owner"
      printf '**Status:** Active\n\n'
    done
  else
    printf '(No risks identified)\n\n'
  fi

  printf '## Mitigation Actions\n'
  printf '| Risk | Mitigation | Owner | Target Date |\n'
  printf '|---|---|---|---|\n'
  if [ "$RISK_COUNT" -gt 0 ]; then
    printf '%s\n' "$RISKS" | while IFS='|' read -r id desc likelihood impact score severity category mitigation contingency owner; do
      printf '| %s | %s | %s | TBD |\n' "$id" "$mitigation" "$owner"
    done
  else
    printf '| (None) | | | |\n'
  fi
} > "$OUTPUT_FILE"

pm_success_rule "Risk register written to $OUTPUT_FILE"
printf '\n'

# ── Final Summary ─────────────────────────────────────────────────────────────
pm_dim "Summary:"
pm_dim "  Total Risks: $RISK_COUNT"
if [ "$RISK_COUNT" -gt 0 ]; then
  RED=$(printf '%s' "$RISKS" | grep -c '🔴 RED' || printf '0')
  AMBER=$(printf '%s' "$RISKS" | grep -c '🟡 AMBER' || printf '0')
  GREEN=$(printf '%s' "$RISKS" | grep -c '🟢 GREEN' || printf '0')
  pm_dim "  Red (15+): $RED"
  pm_dim "  Amber (8-14): $AMBER"
  pm_dim "  Green (5-7): $GREEN"
fi

DEBT_COUNT=$(pm_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '\n%b⚠ %d open PM debt(s) to resolve — see %s%b\n' \
    "$PM_YELLOW" "$DEBT_COUNT" "$PM_DEBT_FILE" "$PM_NC"
fi

printf '\n%b✓ Phase 3 complete.%b\n\n' "$PM_GREEN" "$PM_NC"
