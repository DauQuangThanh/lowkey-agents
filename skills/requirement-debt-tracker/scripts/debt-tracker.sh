#!/bin/bash
# =============================================================================
# debt-tracker.sh — Phase 6: Requirement Debt Tracker
# Reviews all debts collected during the session, lets the user assign owners
# and priorities, and captures any new manual debts.
# Output: $BA_OUTPUT_DIR/06-requirement-debts.md (appends / enriches)
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


AREA="Requirement Debt Tracker"

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "🔍  Step 6 of 7 — Requirement Debt Review"
ba_dim "  A 'Requirement Debt' is anything that is unknown, unclear, or unconfirmed"
ba_dim "  that MUST be resolved before or during development."
echo ""

# ── Show existing debts ───────────────────────────────────────────────────────
EXISTING_COUNT=$(ba_current_debt_count)

if [ "$EXISTING_COUNT" -gt 0 ]; then
  printf '%b%b  ⚠  Found %d requirement debt(s) from earlier steps:%b\n' "$BA_YELLOW" "$BA_BOLD" "$EXISTING_COUNT" "$BA_NC"
  echo ""
  grep -E '^## DEBT-|^\*\*Area:\*\*|^\*\*Description:\*\*|^\*\*Priority:\*\*' "$BA_DEBT_FILE" 2>/dev/null | \
    sed -e 's/^## DEBT-/  🔴  DEBT-/g' \
        -e 's/^\*\*Area:\*\* /     📂 Area: /g' \
        -e 's/^\*\*Description:\*\* /     📝 /g' \
        -e 's/^\*\*Priority:\*\* /     🚦 Priority: /g'
  echo ""
  ba_dim "  These will be included in your final requirements document."
else
  printf '%b  ✅ No requirement debts were logged in earlier steps!%b\n' "$BA_GREEN" "$BA_NC"
  echo ""
fi

# ── Update owners for existing debts ─────────────────────────────────────────
if [ "$EXISTING_COUNT" -gt 0 ]; then
  echo ""
  printf '%b%b── Assigning Owners ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
  ba_dim "  For each debt, who is the best person to resolve it?"
  ba_dim "  We'll add a general owner for now — you can update per-item later."
  echo ""
  default_owner=$(ba_ask "  Who is the primary person responsible for answering open questions? (name or role, e.g. 'Product Owner', 'Thanh')")
  [ -z "$default_owner" ] && default_owner="Product Owner"

  # Cross-platform sed: write to a temp file and move back (avoids BSD/GNU -i differences).
  tmp_file="${BA_DEBT_FILE}.tmp.$$"
  sed "s/^\*\*Owner:\*\* TBD/**Owner:** ${default_owner}/g" "$BA_DEBT_FILE" > "$tmp_file" \
    && mv "$tmp_file" "$BA_DEBT_FILE"
  printf '%b  ✅ Owner set to "%s" for all open debts.%b\n' "$BA_GREEN" "$default_owner" "$BA_NC"
fi

# ── Add new debts ─────────────────────────────────────────────────────────────
echo ""
printf '%b%b── Adding New Debts ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  Are there any other open questions, unknowns, or risks you know about"
ba_dim "  that haven't been captured yet?"
echo ""
ba_dim "  Common areas to check:"
ba_dim "  • Business rules that are vague or assumed"
ba_dim "  • Stakeholders who haven't been consulted yet"
ba_dim "  • Technical dependencies not yet confirmed"
ba_dim "  • Legal or compliance questions"
ba_dim "  • Budget or resource constraints not yet finalised"
echo ""

add_manual_debt() {
  local current_count new_id
  current_count=$(ba_current_debt_count)
  new_id=$(printf "%02d" $((current_count + 1)))

  echo ""
  printf '%b  New Debt #%s%b\n' "$BA_CYAN" "$new_id" "$BA_NC"
  local title area impact owner priority due_date
  title=$(ba_ask "  Briefly describe what is unknown or unclear:")
  [ -z "$title" ] && title="Unknown item"

  area=$(ba_ask_choice "  Which area does this relate to?" \
    "Project scope / goals" \
    "Stakeholders / decision making" \
    "Functional requirements" \
    "Non-functional requirements" \
    "Integrations / external systems" \
    "Legal / compliance" \
    "Technical / infrastructure" \
    "Other")

  impact=$(ba_ask "  What is the impact if this is NOT resolved? (one sentence):")
  [ -z "$impact" ] && impact="Unknown impact — needs assessment"

  owner=$(ba_ask "  Who should resolve this? (name or role):")
  [ -z "$owner" ] && owner="Product Owner"

  priority=$(ba_ask_choice "  How urgent is this?" \
    "🔴 Blocking — Must resolve before development starts" \
    "🟡 Important — Resolve in first sprint/phase" \
    "🟢 Can Wait — Resolve before feature is built")

  due_date=$(ba_ask "  Target resolution date? (e.g. 30 Jun 2026, or press Enter for TBD):")
  [ -z "$due_date" ] && due_date="TBD"

  {
    echo ""
    echo "## DEBT-${new_id}: $title"
    echo "**Area:** $area"
    echo "**Description:** $title"
    echo "**Impact:** $impact"
    echo "**Owner:** $owner"
    echo "**Priority:** $priority"
    echo "**Target Date:** $due_date"
    echo "**Status:** Open"
    echo ""
  } >> "$BA_DEBT_FILE"

  printf '%b  ✅ Debt DEBT-%s logged.%b\n' "$BA_GREEN" "$new_id" "$BA_NC"
}

add_more=$(ba_ask_yn "Do you want to add a new requirement debt?")
while [ "$add_more" = "yes" ]; do
  add_manual_debt
  echo ""
  add_more=$(ba_ask_yn "Add another debt?")
done

# ── Debt priority summary ─────────────────────────────────────────────────────
echo ""
FINAL_COUNT=$(ba_current_debt_count)
BLOCKING_COUNT=0
IMPORTANT_COUNT=0
WAIT_COUNT=0
if [ -f "$BA_DEBT_FILE" ]; then
  BLOCKING_COUNT=$(grep -c 'Blocking' "$BA_DEBT_FILE" 2>/dev/null || printf '0')
  IMPORTANT_COUNT=$(grep -c 'Important' "$BA_DEBT_FILE" 2>/dev/null || printf '0')
  WAIT_COUNT=$(grep -c 'Can Wait' "$BA_DEBT_FILE" 2>/dev/null || printf '0')
  # Grep variants sometimes emit multi-line output; normalise to first numeric token.
  BLOCKING_COUNT=$(printf '%s' "$BLOCKING_COUNT" | head -1 | tr -dc '0-9')
  IMPORTANT_COUNT=$(printf '%s' "$IMPORTANT_COUNT" | head -1 | tr -dc '0-9')
  WAIT_COUNT=$(printf '%s' "$WAIT_COUNT" | head -1 | tr -dc '0-9')
  [ -z "$BLOCKING_COUNT" ] && BLOCKING_COUNT=0
  [ -z "$IMPORTANT_COUNT" ] && IMPORTANT_COUNT=0
  [ -z "$WAIT_COUNT" ] && WAIT_COUNT=0
fi

ba_success_rule "✅ Requirement Debt Register Summary"
printf '  Total debts:     %b%s%b\n' "$BA_BOLD" "$FINAL_COUNT" "$BA_NC"
printf '  🔴 Blocking:     %s — must resolve before development\n' "$BLOCKING_COUNT"
printf '  🟡 Important:    %s — resolve in first sprint\n' "$IMPORTANT_COUNT"
printf '  🟢 Can Wait:     %s — resolve before feature is built\n' "$WAIT_COUNT"
echo ""

if [ "$BLOCKING_COUNT" -gt 0 ]; then
  printf '%b  ⚠  WARNING: You have %s blocking debt(s).%b\n' "$BA_RED" "$BLOCKING_COUNT" "$BA_NC"
  printf '%b     These must be resolved before development can begin.%b\n' "$BA_RED" "$BA_NC"
  echo ""
fi

# ── Add header to debt file if it doesn't have one ───────────────────────────
if [ -f "$BA_DEBT_FILE" ] && ! grep -q '^# Requirement Debt Register' "$BA_DEBT_FILE" 2>/dev/null; then
  tmp_file="${BA_DEBT_FILE}.header.$$"
  {
    echo "# Requirement Debt Register"
    echo ""
    echo "> Last updated: $(date '+%Y-%m-%d')"
    echo ""
    echo "A requirement debt is any unknown, unclear, or unconfirmed piece of information"
    echo "needed to properly define, build, or test the system."
    echo ""
    echo "| Priority | Meaning |"
    echo "|---|---|"
    echo "| 🔴 Blocking | Must resolve before development starts |"
    echo "| 🟡 Important | Must resolve before the related feature is built |"
    echo "| 🟢 Can Wait | Should resolve before the related story is accepted |"
    echo ""
    echo "---"
    echo ""
    cat "$BA_DEBT_FILE"
  } > "$tmp_file" && mv "$tmp_file" "$BA_DEBT_FILE"
fi

printf '%b  Debt register saved to: %s%b\n' "$BA_GREEN" "$BA_DEBT_FILE" "$BA_NC"
echo ""
