#!/bin/bash
# =============================================================================
# map-stakeholders.sh — Phase 2: Stakeholder Mapping
# Identifies who uses or is affected by the system.
# Output: $BA_OUTPUT_DIR/02-stakeholders.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


OUTPUT_FILE="$BA_OUTPUT_DIR/02-stakeholders.md"
AREA="Stakeholder Mapping"

start_debts=$(ba_current_debt_count)

STAKE_COUNT=0
STAKEHOLDERS=()

capture_stakeholder() {
  local type="$1"
  STAKE_COUNT=$((STAKE_COUNT + 1))
  echo ""
  printf '%b%b  ── %s ──%b\n' "$BA_CYAN" "$BA_BOLD" "$type" "$BA_NC"
  local name tech need
  name=$(ba_ask "  What is their role or title? (e.g. 'Sales Manager', 'End Customer')")
  if [ -z "$name" ]; then
    name="TBD"
    ba_add_debt "$AREA" "Stakeholder role name missing" \
      "A $type stakeholder was identified but not named" \
      "Requirements may not reflect their needs"
  fi

  echo ""
  tech=$(ba_ask_choice "  How technical are they?" \
    "Not technical at all" \
    "Some technical knowledge" \
    "Very technical / developer")

  echo ""
  ba_dim "  What is the ONE thing they most need from this system?"
  need=$(ba_ask "  (e.g. 'See all customer orders in one place')")
  if [ -z "$need" ]; then
    need="TBD"
    ba_add_debt "$AREA" "Key need for $name not captured" \
      "Stakeholder '$name' has no documented primary need" \
      "Requirements may miss critical features for this group"
  fi

  STAKEHOLDERS+=("| **$type** | $name | $tech | $need |")
}

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "👥  Step 2 of 7 — Stakeholder Mapping"
ba_dim "  A stakeholder is anyone who uses or is affected by this system."
ba_dim "  We'll go through each type. Answer y/n to whether they exist."
echo ""

# ── Primary users ─────────────────────────────────────────────────────────────
printf '%b%bPrimary Users%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  These are the people who will use the system every day."
has_primary=$(ba_ask_yn "Does your system have primary daily users?")
if [ "$has_primary" = "yes" ]; then
  ba_dim "  How many different types of primary user are there?"
  num_primary_choice=$(ba_ask_choice "Select:" "1" "2" "3" "4 or more (I'll add them one by one)")
  if [ "$num_primary_choice" = "4 or more (I'll add them one by one)" ]; then
    num_primary=4
  else
    num_primary="$num_primary_choice"
  fi
  i=1
  while [ "$i" -le "$num_primary" ]; do
    ba_dim "  Primary user $i of $num_primary:"
    capture_stakeholder "Primary User"
    i=$((i + 1))
  done
else
  ba_add_debt "$AREA" "No primary users identified" \
    "No primary daily users were identified" \
    "Cannot write user stories without knowing who uses the system"
fi

# ── Secondary users ───────────────────────────────────────────────────────────
echo ""
printf '%b%bSecondary Users%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  People who use the system occasionally or consume its reports/exports."
has_secondary=$(ba_ask_yn "Are there secondary or occasional users?")
if [ "$has_secondary" = "yes" ]; then
  capture_stakeholder "Secondary User"
  while : ; do
    add_more=$(ba_ask_yn "  Add another secondary user?")
    [ "$add_more" = "no" ] && break
    capture_stakeholder "Secondary User"
  done
fi

# ── Decision makers ───────────────────────────────────────────────────────────
echo ""
printf '%b%bDecision Makers%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  Who approves the requirements and signs off on the project?"
has_decision=$(ba_ask_yn "Is there a decision maker or sponsor for this project?")
if [ "$has_decision" = "yes" ]; then
  capture_stakeholder "Decision Maker / Sponsor"
else
  ba_add_debt "$AREA" "No decision maker identified" \
    "No one has been named as project owner or sponsor" \
    "Requirements changes and scope decisions will have no authority"
fi

# ── External parties ──────────────────────────────────────────────────────────
echo ""
printf '%b%bExternal Parties%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  Third-party vendors, regulators, partner systems, or customers."
has_external=$(ba_ask_yn "Are there any external organisations or systems this project interacts with?")
if [ "$has_external" = "yes" ]; then
  capture_stakeholder "External Party"
  while : ; do
    add_more=$(ba_ask_yn "  Add another external party?")
    [ "$add_more" = "no" ] && break
    capture_stakeholder "External Party"
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
ba_success_rule "✅ Stakeholder Summary ($STAKE_COUNT stakeholders identified)"
for s in "${STAKEHOLDERS[@]+"${STAKEHOLDERS[@]}"}"; do printf '  %s\n' "$s"; done
echo ""

if ! ba_confirm_save "Does this look right? (y=save / n=redo)"; then
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Stakeholder Map"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Identified Stakeholders"
  echo ""
  echo "| Type | Role / Title | Technical Level | Primary Need |"
  echo "|---|---|---|---|"
  for s in "${STAKEHOLDERS[@]+"${STAKEHOLDERS[@]}"}"; do echo "$s"; done
  echo ""
  echo "## Notes"
  echo ""
  echo "Total stakeholders identified: $STAKE_COUNT"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(ba_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$BA_GREEN" "$OUTPUT_FILE" "$BA_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d debt(s) logged.%b\n' "$BA_YELLOW" "$new_debts" "$BA_NC"
fi
echo ""
