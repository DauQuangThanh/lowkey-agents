#!/bin/bash
# =============================================================================
# validate.sh — Phase 4: UX Review & Validation
# Validates design against heuristics, coverage, and sign-off criteria.
# Output: $UX_OUTPUT_DIR/04-ux-validation.md + $UX_OUTPUT_DIR/UX-DESIGNER-FINAL.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../ux-research/scripts/_common.sh
source "$SCRIPT_DIR/../../ux-research/scripts/_common.sh"

# Step 3: accept --auto / --answers flags
ux_parse_flags "$@"


OUTPUT_FILE="$UX_OUTPUT_DIR/04-ux-validation.md"
FINAL_FILE="$UX_OUTPUT_DIR/UX-DESIGNER-FINAL.md"
AREA="UX Validation"

start_debts=$(ux_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
ux_banner "✅  Phase 4 — UX Review & Validation"
ux_dim "  Let's validate the design is complete, heuristic-sound, and ready for handoff."
echo ""

# ── Check all previous phases ────────────────────────────────────────────────
RESEARCH_FILE="$UX_OUTPUT_DIR/01-user-research.md"
WIREFRAME_FILE="$UX_OUTPUT_DIR/02-wireframes.md"
PROTOTYPE_FILE="$UX_OUTPUT_DIR/03-prototype-spec.md"

printf '%b  Phase completeness check:%b\n' "$UX_CYAN" "$UX_NC"
[ -f "$RESEARCH_FILE" ] && printf '    ✔ Phase 1 (Research): %s\n' "$(basename "$RESEARCH_FILE")" || printf '    ✗ Phase 1 (Research): MISSING\n'
[ -f "$WIREFRAME_FILE" ] && printf '    ✔ Phase 2 (Wireframes): %s\n' "$(basename "$WIREFRAME_FILE")" || printf '    ✗ Phase 2 (Wireframes): MISSING\n'
[ -f "$PROTOTYPE_FILE" ] && printf '    ✔ Phase 3 (Mockups): %s\n' "$(basename "$PROTOTYPE_FILE")" || printf '    ✗ Phase 3 (Mockups): MISSING\n'
echo ""

# ── Nielsen's 10 Heuristics Checklist ────────────────────────────────────────
printf '%b%bNielsen'"'"'s 10 Usability Heuristics Review%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

HEURISTICS=(
  "System visibility and status — Are users informed of what is happening?"
  "Match system and real world — Does language match user mental models?"
  "User control and freedom — Can users undo, back out, cancel?"
  "Error prevention and recovery — Errors prevented? Messages clear?"
  "Help and documentation — Is there guidance for non-obvious tasks?"
  "Flexibility and shortcuts — Can power users skip steps?"
  "Aesthetic and minimalist design — Is interface focused, not cluttered?"
  "Error messages — Are they clear, non-technical, constructive?"
  "Help and support — Can users find answers without leaving the app?"
  "Accessibility — Is design inclusive (color, motor, cognitive)?"
)

HEURISTIC_SCORES=""
for i in "${!HEURISTICS[@]}"; do
  h=$((i + 1))
  prompt="${HEURISTICS[$i]}"

  STATUS=$(ux_ask_choice "  $h. $prompt" \
    "✅ Pass" \
    "⚠️  Minor gap" \
    "🔴 Major gap" \
    "N/A for this product")

  HEURISTIC_SCORES+="| $h | $prompt | $STATUS |"$'\n'
done

# ── Requirement coverage ──────────────────────────────────────────────────────
echo ""
printf '%b%bRequirement Coverage%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

BA_FINAL="$UX_BA_INPUT_DIR/REQUIREMENTS-FINAL.md"
if [ -f "$BA_FINAL" ]; then
  STORY_COVERAGE=$(ux_ask_yn "Do all user stories map to at least one wireframe screen?")
  SCENARIO_COVERAGE=$(ux_ask_yn "Are all user scenarios covered by the user journeys?")
else
  STORY_COVERAGE="N/A — no BA requirements"
  SCENARIO_COVERAGE="N/A — no BA requirements"
fi

# ── Accessibility & Responsiveness ────────────────────────────────────────────
echo ""
ACCESSIBILITY=$(ux_ask_yn "Do wireframes address all accessibility needs from Phase 1?")
RESPONSIVE=$(ux_ask_yn "Are responsive design breakpoints explicitly defined?")
INTERACTIONS=$(ux_ask_yn "Are all interaction patterns specified (forms, validation, errors)?")

# ── Open Debts ────────────────────────────────────────────────────────────────
echo ""
printf '%b%bOpen UX Debts%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

TOTAL_DEBTS=$(ux_current_debt_count)
BLOCKING_DEBTS=0
if [ "$TOTAL_DEBTS" -gt 0 ] && [ -f "$UX_DEBT_FILE" ]; then
  BLOCKING_DEBTS=$(grep -c '🔴 Blocking' "$UX_DEBT_FILE" 2>/dev/null || printf '0')
fi

printf '  Total UX Debts: %d\n' "$TOTAL_DEBTS"
printf '  Blocking (🔴): %d\n' "$BLOCKING_DEBTS"
echo ""

# ── Stakeholder sign-off ──────────────────────────────────────────────────────
printf '%b%bStakeholder Sign-Off%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

STAKEHOLDER_REVIEW=$(ux_ask_yn "Have all key stakeholders reviewed and approved the designs?")
DESIGN_FINAL=$(ux_ask_yn "Are there any open design questions blocking handoff to engineering?")
HANDOFF_READY=$(ux_ask_yn "Is this design package ready for developer handoff?")

# ── Determine overall status ──────────────────────────────────────────────────
echo ""
ux_success_rule "✅ Validation Summary"

if [ "$BLOCKING_DEBTS" -gt 0 ]; then
  OVERALL_STATUS="❌ NOT READY"
  printf '%b  %s — Resolve %d blocking debt(s) before handoff%b\n' "$UX_RED" "$OVERALL_STATUS" "$BLOCKING_DEBTS" "$UX_NC"
elif [ "$STAKEHOLDER_REVIEW" = "no" ] || [ "$HANDOFF_READY" = "no" ]; then
  OVERALL_STATUS="⚠️  CONDITIONALLY APPROVED"
  printf '%b  %s — Address stakeholder feedback; some gaps tracked as debts%b\n' "$UX_YELLOW" "$OVERALL_STATUS" "$UX_NC"
else
  OVERALL_STATUS="✅ APPROVED"
  printf '%b  %s — Design is complete and ready for engineering handoff%b\n' "$UX_GREEN" "$OVERALL_STATUS" "$UX_NC"
fi
echo ""

# ── Write validation output ───────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# UX Review & Validation"
  echo ""
  echo "> Date: $DATE_NOW"
  echo "> Status: $OVERALL_STATUS"
  echo ""
  echo "## Nielsen's 10 Usability Heuristics"
  echo ""
  echo "| # | Heuristic | Assessment |"
  echo "|---|---|---|"
  echo "$HEURISTIC_SCORES"
  echo ""
  echo "## Requirement Coverage"
  echo ""
  echo "- **User stories mapped to wireframes:** $STORY_COVERAGE"
  echo "- **Scenarios covered in journeys:** $SCENARIO_COVERAGE"
  echo ""
  echo "## Accessibility & Responsiveness"
  echo ""
  echo "- **Accessibility needs addressed:** $ACCESSIBILITY"
  echo "- **Responsive breakpoints defined:** $RESPONSIVE"
  echo "- **All interactions specified:** $INTERACTIONS"
  echo ""
  echo "## Open UX Debts"
  echo ""
  echo "- **Total:** $TOTAL_DEBTS"
  echo "- **Blocking (🔴):** $BLOCKING_DEBTS"
  echo ""
  echo "## Stakeholder Sign-Off"
  echo ""
  echo "- **Stakeholders reviewed:** $STAKEHOLDER_REVIEW"
  echo "- **Design finalized:** $DESIGN_FINAL"
  echo "- **Ready for handoff:** $HANDOFF_READY"
  echo ""
  echo "## Recommendation"
  echo ""
  echo "**Overall Status:** $OVERALL_STATUS"
  echo ""
  if [ "$BLOCKING_DEBTS" -gt 0 ]; then
    echo "**Next steps:** Resolve all 🔴 Blocking debts in \`05-ux-debts.md\` before proceeding."
  elif [ "$STAKEHOLDER_REVIEW" = "no" ]; then
    echo "**Next steps:** Gather stakeholder feedback and incorporate into design before engineering handoff."
  else
    echo "**Next steps:** Hand off to engineering. Design is complete and approved."
  fi
  echo ""
} > "$OUTPUT_FILE"

# ── Compile final deliverable ────────────────────────────────────────────────
{
  echo "# UX Design Package — Final Deliverable"
  echo ""
  echo "> Compiled: $DATE_NOW"
  echo "> Status: $OVERALL_STATUS"
  echo ""
  echo "---"
  echo ""
  [ -f "$RESEARCH_FILE" ] && cat "$RESEARCH_FILE" || echo "*Phase 1 (User Research): Not completed*"
  echo ""
  echo "---"
  echo ""
  [ -f "$WIREFRAME_FILE" ] && cat "$WIREFRAME_FILE" || echo "*Phase 2 (Wireframes): Not completed*"
  echo ""
  echo "---"
  echo ""
  [ -f "$PROTOTYPE_FILE" ] && cat "$PROTOTYPE_FILE" || echo "*Phase 3 (Mockups): Not completed*"
  echo ""
  echo "---"
  echo ""
  cat "$OUTPUT_FILE"
  echo ""
  echo "---"
  echo ""
  echo "## All UX Debts"
  echo ""
  if [ -f "$UX_DEBT_FILE" ]; then
    cat "$UX_DEBT_FILE"
  else
    echo "No open UX debts."
  fi
  echo ""
} > "$FINAL_FILE"

printf '%b  Saved validation to: %s%b\n' "$UX_GREEN" "$OUTPUT_FILE" "$UX_NC"
printf '%b  Compiled final package to: %s%b\n' "$UX_GREEN" "$FINAL_FILE" "$UX_NC"
echo ""

end_debts=$(ux_current_debt_count)
new_debts=$((end_debts - start_debts))
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d UX debt(s) logged to: %s%b\n' "$UX_YELLOW" "$new_debts" "$UX_DEBT_FILE" "$UX_NC"
fi
echo ""
