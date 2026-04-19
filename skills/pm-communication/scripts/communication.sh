#!/bin/bash
# =============================================================================
# communication.sh — Phase 4: Communication & Stakeholder Management
# Captures stakeholder groups, communication channels, cadence, escalation,
# RACI matrix, and change request process.
# Output: pm-output/04-communication-plan.md
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
pm_parse_flags "$@"


pm_banner "Phase 4: Communication & Stakeholder Management"

# ── Question 1: Stakeholder Groups ────────────────────────────────────────────
printf '\n%b▶ Define stakeholder groups and their communication preferences.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: Exec Steering, Development Team, QA, Product Owner, Clients)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   For each group, provide: Name | Key Interests | Communication Channel | Frequency%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

STAKEHOLDERS=""
while true; do
  item=$(pm_ask "Add stakeholder group (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$STAKEHOLDERS" ]; then
    STAKEHOLDERS="$item"
  else
    STAKEHOLDERS="$STAKEHOLDERS"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$STAKEHOLDERS" ]; then
  pm_dim "No stakeholder groups defined — logging as debt."
  pm_add_debt "Communication" "Stakeholder groups undefined" "No stakeholder groups or communication preferences captured" "Cannot ensure all stakeholders are informed"
  STAKEHOLDERS="(TBD)"
fi

# ── Question 2: Communication Channels ────────────────────────────────────────
printf '\n%b▶ Which communication channels will you use?%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: Email, Slack, Jira, Weekly meetings, SharePoint wiki, Town halls)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

CHANNELS=""
while true; do
  item=$(pm_ask "Add communication channel (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$CHANNELS" ]; then
    CHANNELS="$item"
  else
    CHANNELS="$CHANNELS"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$CHANNELS" ]; then
  pm_dim "No channels defined — logging as debt."
  pm_add_debt "Communication" "Communication channels undefined" "No specific communication channels identified" "Cannot ensure consistent and accessible information flow"
  CHANNELS="(TBD)"
fi

# ── Question 3: Meeting Cadence ───────────────────────────────────────────────
CADENCE=$(pm_ask_choice \
  "What is your primary meeting cadence?" \
  "Daily standup" \
  "Weekly" \
  "Bi-weekly" \
  "Monthly" \
  "As-needed")
pm_dim "Meeting cadence: $CADENCE"

# ── Question 4: Escalation Path ───────────────────────────────────────────────
printf '\n%b▶ Define your escalation path.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: Blocker → PM → Sponsor, within 2 hours; Critical issue → CCB)%b\n' "$PM_DIM" "$PM_NC"

ESCALATION=$(pm_ask "Describe your escalation rules (or type 'skip' to use defaults)")
if [ "$ESCALATION" = "skip" ] || [ -z "$ESCALATION" ]; then
  ESCALATION="Tier 1: Blocker → PM → Sponsor (within 2 hours)"$'\n'"Tier 2: Critical issue → CCB review (within 1 day)"
  pm_dim "Using default escalation rules."
else
  pm_dim "Escalation: $ESCALATION"
fi

# ── Question 5: RACI for Key Deliverables ────────────────────────────────────
printf '\n%b▶ Define RACI for key deliverables.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (R=Responsible, A=Accountable, C=Consulted, I=Informed)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   (Example: Project Plan - R:PM, A:Sponsor, C:Tech Lead, I:Team)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

RACI_ITEMS=""
while true; do
  item=$(pm_ask "Add RACI entry (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$RACI_ITEMS" ]; then
    RACI_ITEMS="$item"
  else
    RACI_ITEMS="$RACI_ITEMS"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$RACI_ITEMS" ]; then
  pm_dim "No RACI matrix entries — logging as debt."
  pm_add_debt "Communication" "RACI matrix incomplete" "No clear responsibility assignments for key deliverables" "Roles and accountability are unclear"
  RACI_ITEMS="(TBD)"
fi

# ── Question 6: Change Request Process ────────────────────────────────────────
printf '\n%b▶ How will change requests be handled?%b\n' "$PM_YELLOW" "$PM_NC"

CR_APPROVAL=$(pm_ask "Who approves change requests? (role/name/board)")
pm_dim "CR Approval: $CR_APPROVAL"

CR_TRIGGERS=$(pm_ask "What triggers a change request? (Scope change, Budget change, Schedule change, all of above, etc.)")
pm_dim "CR Triggers: $CR_TRIGGERS"

# ── Confirmation ──────────────────────────────────────────────────────────────
printf '\n'
pm_ask_yn "Save this communication plan?"
if [ $? -ne 0 ]; then
  pm_dim "Plan discarded. Exiting."
  exit 0
fi

# ── Write Output ──────────────────────────────────────────────────────────────
OUTPUT_FILE="$PM_OUTPUT_DIR/04-communication-plan.md"

{
  printf '# Communication Plan\n\n'
  printf '**Date:** %s\n\n' "$(date '+%d/%m/%Y')"

  printf '## Stakeholder Groups\n'
  printf '| Group | Key Interests | Communication Channel | Frequency |\n'
  printf '|---|---|---|---|\n'
  if [ "$STAKEHOLDERS" != "(TBD)" ]; then
    printf '%s\n' "$STAKEHOLDERS" | while IFS= read -r line; do
      printf '| %s | TBD | TBD | TBD |\n' "$line"
    done
  else
    printf '| (TBD) | | | |\n'
  fi
  printf '\n'

  printf '## Communication Channels\n'
  if [ "$CHANNELS" != "(TBD)" ]; then
    printf '%s\n' "$CHANNELS" | sed 's/^/- /'
  else
    printf -- '- (TBD)\n'
  fi
  printf '\n'

  printf '## Meeting Cadence\n'
  printf '**Primary Cadence:** %s\n' "$CADENCE"
  printf -- '- Standup/Status meetings: [To be scheduled]\n'
  printf -- '- Steering committee: [To be scheduled]\n\n'

  printf '## Escalation Path\n'
  printf '%s\n\n' "$ESCALATION" | sed 's/^/- /'

  printf '## RACI Matrix (Key Deliverables)\n'
  printf '| Deliverable | Responsible | Accountable | Consulted | Informed |\n'
  printf '|---|---|---|---|---|\n'
  if [ "$RACI_ITEMS" != "(TBD)" ]; then
    printf '%s\n' "$RACI_ITEMS" | sed 's/^/| /' | sed 's/$/ | TBD | TBD | TBD |/'
  else
    printf '| (TBD) | | | | |\n'
  fi
  printf '\n'

  printf '## Change Request Process\n'
  printf '**Approval Authority:** %s\n' "$CR_APPROVAL"
  printf '**Triggers:** %s\n' "$CR_TRIGGERS"
  printf '**Process:**\n'
  printf '1. Requestor submits CR with description and rationale\n'
  printf '2. PM assesses impact (scope, schedule, budget, quality)\n'
  printf '3. CCB (Change Control Board) reviews and votes\n'
  printf '4. If approved: PM updates plan, communicates change\n'
  printf '5. If rejected: PM documents reason and archives CR\n'
} > "$OUTPUT_FILE"

pm_success_rule "Communication plan written to $OUTPUT_FILE"
printf '\n'

# ── Final Summary ─────────────────────────────────────────────────────────────
pm_dim "Summary:"
pm_dim "  Stakeholder Groups: $(if [ "$STAKEHOLDERS" = "(TBD)" ]; then printf 'TBD'; else printf '%s' "$STAKEHOLDERS" | wc -l | tr -d ' '; fi) defined"
pm_dim "  Communication Channels: $(if [ "$CHANNELS" = "(TBD)" ]; then printf 'TBD'; else printf '%s' "$CHANNELS" | wc -l | tr -d ' '; fi) defined"
pm_dim "  Meeting Cadence: $CADENCE"
pm_dim "  CR Approval: $CR_APPROVAL"

DEBT_COUNT=$(pm_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '\n%b⚠ %d open PM debt(s) to resolve — see %s%b\n' \
    "$PM_YELLOW" "$DEBT_COUNT" "$PM_DEBT_FILE" "$PM_NC"
fi

printf '\n%b✓ Phase 4 complete.%b\n\n' "$PM_GREEN" "$PM_NC"
