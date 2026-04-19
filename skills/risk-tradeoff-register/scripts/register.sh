#!/bin/bash
# =============================================================================
# register.sh — Phase 5: Risk & Trade-off Register
# Reviews existing Technical Debts, lets the user assign owners, and captures
# new Risks (RISK-NN) and Technical Debts (TDEBT-NN).
# Output: $ARCH_OUTPUT_DIR/05-technical-debts.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
arch_parse_flags "$@"


AREA="Risk & Trade-off Register"

# ── Header ────────────────────────────────────────────────────────────────────
arch_banner "🚦  Step 5 of 6 — Risk & Trade-off Register"
arch_dim "  Risks (RISK-NN): things that could hurt us — with mitigation + contingency."
arch_dim "  Technical Debts (TDEBT-NN): things we knowingly deferred."
echo ""

EXISTING_TDEBTS=$(arch_current_tdebt_count)
EXISTING_RISKS=$(arch_current_risk_count)

# ── Show existing TDEBTs ─────────────────────────────────────────────────────
if [ "$EXISTING_TDEBTS" -gt 0 ]; then
  printf '%b%b  ⚠  Found %d technical debt(s) from earlier steps:%b\n' "$ARCH_YELLOW" "$ARCH_BOLD" "$EXISTING_TDEBTS" "$ARCH_NC"
  echo ""
  grep -E '^## TDEBT-|^\*\*Area:\*\*|^\*\*Description:\*\*|^\*\*Priority:\*\*' "$ARCH_TDEBT_FILE" 2>/dev/null | \
    sed -e 's/^## TDEBT-/  🔴  TDEBT-/g' \
        -e 's/^\*\*Area:\*\* /     📂 Area: /g' \
        -e 's/^\*\*Description:\*\* /     📝 /g' \
        -e 's/^\*\*Priority:\*\* /     🚦 Priority: /g'
  echo ""
else
  printf '%b  ✅ No technical debts logged in earlier steps.%b\n' "$ARCH_GREEN" "$ARCH_NC"
  echo ""
fi

# ── Update owners ─────────────────────────────────────────────────────────────
if [ "$EXISTING_TDEBTS" -gt 0 ]; then
  printf '%b%b── Assigning Owners ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
  arch_dim "  We'll set a default owner for all debts that are still TBD."
  echo ""
  default_owner=$(arch_ask "  Who is the default owner? (name or role, e.g. 'Architect', 'Thanh')")
  [ -z "$default_owner" ] && default_owner="Architect"

  tmp_file="${ARCH_TDEBT_FILE}.tmp.$$"
  sed "s/^\*\*Owner:\*\* TBD/**Owner:** ${default_owner}/g" "$ARCH_TDEBT_FILE" > "$tmp_file" \
    && mv "$tmp_file" "$ARCH_TDEBT_FILE"
  printf '%b  ✅ Default owner set to "%s" for all TBD debts.%b\n' "$ARCH_GREEN" "$default_owner" "$ARCH_NC"
  echo ""
fi

# ── Add new RISKs ─────────────────────────────────────────────────────────────
add_risk() {
  local current_count new_id title likelihood impact mitigation contingency owner linked status

  current_count=$(arch_current_risk_count)
  new_id=$(printf "%02d" $((current_count + 1)))

  echo ""
  printf '%b  New Risk: RISK-%s%b\n' "$ARCH_CYAN" "$new_id" "$ARCH_NC"
  title=$(arch_ask "  Briefly describe the risk:")
  [ -z "$title" ] && title="Unnamed risk"

  likelihood=$(arch_ask_choice "  Likelihood?" "Low" "Medium" "High")
  impact=$(arch_ask_choice "  Impact?"         "Low" "Medium" "High")

  mitigation=$(arch_ask "  Proactive mitigation (what we do to prevent it):")
  [ -z "$mitigation" ] && mitigation="TBD"

  if [ "$likelihood" = "High" ] && [ "$impact" = "High" ] && [ "$mitigation" = "TBD" ]; then
    printf '%b  ⚠  WARNING: High/High risk with no mitigation — please revisit.%b\n' "$ARCH_RED" "$ARCH_NC"
  fi

  contingency=$(arch_ask "  Reactive contingency (what we do if it happens):")
  [ -z "$contingency" ] && contingency="TBD"

  owner=$(arch_ask "  Owner:")
  [ -z "$owner" ] && owner="Architect"

  linked=$(arch_ask "  Linked ADR or requirement ID (e.g. 'ADR-0002, NFR-07'):")
  [ -z "$linked" ] && linked="None"

  status=$(arch_ask_choice "  Status?" "Open" "Mitigated" "Accepted" "Closed")

  {
    echo ""
    echo "## RISK-${new_id}: $title"
    echo "**Likelihood:** $likelihood"
    echo "**Impact:** $impact"
    echo "**Mitigation (proactive):** $mitigation"
    echo "**Contingency (reactive):** $contingency"
    echo "**Owner:** $owner"
    echo "**Linked:** $linked"
    echo "**Status:** $status"
    echo ""
  } >> "$ARCH_TDEBT_FILE"

  printf '%b  ✅ Risk RISK-%s logged.%b\n' "$ARCH_GREEN" "$new_id" "$ARCH_NC"
}

printf '%b%b── Risks ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
arch_dim "  Examples: vendor lock-in, unproven technology, performance unknowns, staffing"
arch_dim "  gaps, compliance gap, data migration complexity."
echo ""
add_more=$(arch_ask_yn "Do you want to add a new risk?")
while [ "$add_more" = "yes" ]; do
  add_risk
  echo ""
  add_more=$(arch_ask_yn "Add another risk?")
done

# ── Add new TDEBTs ────────────────────────────────────────────────────────────
add_tdebt_manual() {
  local current_count new_id title area impact owner priority due_date linked

  current_count=$(arch_current_tdebt_count)
  new_id=$(printf "%02d" $((current_count + 1)))

  echo ""
  printf '%b  New Technical Debt: TDEBT-%s%b\n' "$ARCH_CYAN" "$new_id" "$ARCH_NC"
  title=$(arch_ask "  Briefly describe what is unknown or deferred:")
  [ -z "$title" ] && title="Unnamed debt"

  area=$(arch_ask_choice "  Area?" \
    "Decision — technology choice open" \
    "Component — part of the architecture is unspecified" \
    "Operations — running/monitoring concern" \
    "Compliance — regulatory/legal gap" \
    "Other")

  impact=$(arch_ask "  What is blocked until this is resolved?")
  [ -z "$impact" ] && impact="Unknown — needs assessment"

  owner=$(arch_ask "  Owner:")
  [ -z "$owner" ] && owner="Architect"

  priority=$(arch_ask_choice "  Priority?" \
    "🔴 Blocking — must resolve before implementation starts" \
    "🟡 Important — must resolve before affected feature is built" \
    "🟢 Can Wait — resolve before go-live")

  due_date=$(arch_ask "  Target resolution date? (YYYY-MM-DD or Enter for TBD):")
  [ -z "$due_date" ] && due_date="TBD"

  linked=$(arch_ask "  Linked ADR / requirement (e.g. 'ADR-0002'):")
  [ -z "$linked" ] && linked="None"

  {
    echo ""
    echo "## TDEBT-${new_id}: $title"
    echo "**Area:** $area"
    echo "**Description:** $title"
    echo "**Impact:** $impact"
    echo "**Owner:** $owner"
    echo "**Priority:** $priority"
    echo "**Target Date:** $due_date"
    echo "**Linked:** $linked"
    echo "**Status:** Open"
    echo ""
  } >> "$ARCH_TDEBT_FILE"

  printf '%b  ✅ TDEBT-%s logged.%b\n' "$ARCH_GREEN" "$new_id" "$ARCH_NC"
}

echo ""
printf '%b%b── Technical Debts ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
add_more=$(arch_ask_yn "Do you want to add a new technical debt?")
while [ "$add_more" = "yes" ]; do
  add_tdebt_manual
  echo ""
  add_more=$(arch_ask_yn "Add another technical debt?")
done

# ── Summary counters ──────────────────────────────────────────────────────────
echo ""
FINAL_TDEBTS=$(arch_current_tdebt_count)
FINAL_RISKS=$(arch_current_risk_count)
BLOCKING=0; IMPORTANT=0; WAIT=0
HIGH_HIGH_OPEN=0

if [ -f "$ARCH_TDEBT_FILE" ]; then
  BLOCKING=$(grep -c 'Blocking' "$ARCH_TDEBT_FILE" 2>/dev/null  | head -1 | tr -dc '0-9'); [ -z "$BLOCKING" ] && BLOCKING=0
  IMPORTANT=$(grep -c 'Important' "$ARCH_TDEBT_FILE" 2>/dev/null | head -1 | tr -dc '0-9'); [ -z "$IMPORTANT" ] && IMPORTANT=0
  WAIT=$(grep -c 'Can Wait' "$ARCH_TDEBT_FILE" 2>/dev/null       | head -1 | tr -dc '0-9'); [ -z "$WAIT" ] && WAIT=0
fi

# ── Add/refresh header on the register ────────────────────────────────────────
if [ -f "$ARCH_TDEBT_FILE" ] && ! grep -q '^# Risk & Technical Debt Register' "$ARCH_TDEBT_FILE" 2>/dev/null; then
  tmp_file="${ARCH_TDEBT_FILE}.header.$$"
  {
    echo "# Risk & Technical Debt Register"
    echo ""
    echo "> Last updated: $(date '+%Y-%m-%d')"
    echo ""
    echo "**RISK-NN** entries are things that could hurt us (with likelihood, impact,"
    echo "mitigation, contingency). **TDEBT-NN** entries are things we knowingly deferred"
    echo "(with area, impact, owner, priority, target date)."
    echo ""
    echo "| Priority | Meaning |"
    echo "|---|---|"
    echo "| 🔴 Blocking | Must resolve before implementation starts |"
    echo "| 🟡 Important | Must resolve before the affected feature is built |"
    echo "| 🟢 Can Wait | Should resolve before go-live |"
    echo ""
    echo "---"
    echo ""
    cat "$ARCH_TDEBT_FILE"
  } > "$tmp_file" && mv "$tmp_file" "$ARCH_TDEBT_FILE"
fi

arch_success_rule "✅ Risk & Technical Debt Register"
printf '  Total risks:          %s\n' "$FINAL_RISKS"
printf '  Total technical debts: %s\n' "$FINAL_TDEBTS"
printf '  🔴 Blocking:           %s\n' "$BLOCKING"
printf '  🟡 Important:          %s\n' "$IMPORTANT"
printf '  🟢 Can Wait:           %s\n' "$WAIT"
echo ""
if [ "$BLOCKING" -gt 0 ]; then
  printf '%b  ⚠  WARNING: %s blocking debt(s) open — resolve before implementation.%b\n' "$ARCH_RED" "$BLOCKING" "$ARCH_NC"
  echo ""
fi

printf '%b  Register saved to: %s%b\n' "$ARCH_GREEN" "$ARCH_TDEBT_FILE" "$ARCH_NC"
echo ""
