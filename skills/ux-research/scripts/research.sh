#!/bin/bash
# =============================================================================
# research.sh — Phase 1: User Research & Personas
# Captures the user insights that guide all downstream UX decisions.
# Output: $UX_OUTPUT_DIR/01-user-research.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ux_parse_flags "$@"


OUTPUT_FILE="$UX_OUTPUT_DIR/01-user-research.md"
AREA="User Research"

start_debts=$(ux_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
ux_banner "🎯  Phase 1 — User Research & Personas"
ux_dim "  Let's understand your users: who they are, what they want, and how they interact."
ux_dim "  Most answers are short narratives. Skip with Enter if you'll gather this later."
echo ""

# ── Handover from BA ─────────────────────────────────────────────────────────
BA_FINAL="$UX_BA_INPUT_DIR/REQUIREMENTS-FINAL.md"
if [ -f "$BA_FINAL" ]; then
  printf '%b  ✔ Found BA output: %s%b\n' "$UX_GREEN" "$BA_FINAL" "$UX_NC"
  ux_dim "  I'll read user stories and stakeholder data from there. Continuing..."
else
  printf '%b  ⚠ No BA output found at: %s%b\n' "$UX_YELLOW" "$BA_FINAL" "$UX_NC"
  ux_dim "  For best results, run the business-analyst first. Continuing anyway..."
  ux_add_debt "$AREA" "No BA requirements input found" \
    "ba-output/REQUIREMENTS-FINAL.md was not present at research time" \
    "Personas may lack grounding in actual user stories and stakeholder feedback"
fi
echo ""

# ── Q1: Primary user personas ────────────────────────────────────────────────
printf '%b%bQuestion 1 / 5 — Primary user personas%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  Name the 2–4 primary user types. For each, I'll ask about their role, goals, pain points."
echo ""

PERSONAS=""
for i in 1 2; do
  PERSONA_NAME=$(ux_ask "Persona $i name? (e.g. 'Alice the Customer', 'Bob the Admin') — or Enter to skip:")
  [ -z "$PERSONA_NAME" ] && break

  PERSONA_ROLE=$(ux_ask "  Role/title for $PERSONA_NAME? (e.g. 'E-commerce customer', 'Product owner'):")
  [ -z "$PERSONA_ROLE" ] && PERSONA_ROLE="Unknown"

  PERSONA_GOALS=$(ux_ask "  Top 3 goals? (e.g. 'Find product, add to cart, checkout' — one per line or comma-separated):")
  [ -z "$PERSONA_GOALS" ] && PERSONA_GOALS="TBD"

  PERSONA_PAINS=$(ux_ask "  Pain points? (e.g. 'Slow search, confusing checkout, no guest option'):")
  [ -z "$PERSONA_PAINS" ] && PERSONA_PAINS="TBD"

  PERSONA_TECH=$(ux_ask_choice "  Tech comfort level?" \
    "Beginner — barely uses software" \
    "Intermediate — can use email, web apps" \
    "Advanced — comfortable with most tech" \
    "Expert — power user, knows keyboard shortcuts")

  PERSONA_DEVICE=$(ux_ask_choice "  Device preference?" \
    "Desktop only" \
    "Mobile first (mostly phone)" \
    "Equal mobile and desktop" \
    "Multiple devices depending on context")

  PERSONAS+="
### Persona $i: $PERSONA_NAME
- **Role:** $PERSONA_ROLE
- **Goals:** $PERSONA_GOALS
- **Pain Points:** $PERSONA_PAINS
- **Tech Comfort:** $PERSONA_TECH
- **Device Preference:** $PERSONA_DEVICE
"
done

if [ -z "$PERSONAS" ]; then
  PERSONAS="No personas captured this session."
  ux_add_debt "$AREA" "User personas not defined" \
    "No primary user types were captured" \
    "Wireframes and design decisions lack user grounding"
fi

# ── Q2: User scenarios ───────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 5 — User scenarios%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  Describe 2–3 key user scenarios in plain language. e.g. 'A customer browsing for shoes on mobile.'"
echo ""

SCENARIOS=""
for i in 1 2; do
  SCENARIO=$(ux_ask "Scenario $i? (short narrative) — or Enter to skip:")
  [ -z "$SCENARIO" ] && break
  SCENARIOS+="
### Scenario $i
$SCENARIO
"
done

if [ -z "$SCENARIOS" ]; then
  SCENARIOS="No scenarios captured."
  ux_add_debt "$AREA" "User scenarios not documented" \
    "No key user scenarios were described" \
    "Design decisions lack context for real user tasks"
fi

# ── Q3: User journey maps ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 5 — User journey maps%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  For one key scenario, map the steps. Include actions, emotions, pain points, touchpoints."
echo ""

JOURNEY=""
JOURNEY_SCENARIO=$(ux_ask "Which scenario should we map? (e.g. 'checkout flow') — or Enter to skip:")
if [ -n "$JOURNEY_SCENARIO" ]; then
  JOURNEY="
### Journey: $JOURNEY_SCENARIO

| Step | Action | Emotion | Pain Point | Touchpoint |
|---|---|---|---|---|"

  for step in 1 2 3 4 5; do
    ACTION=$(ux_ask "  Step $step action? (e.g. 'User adds item to cart') — Enter when done:")
    [ -z "$ACTION" ] && break

    EMOTION=$(ux_ask_choice "    Emotion?" "😀 Happy" "😐 Neutral" "😞 Frustrated" "😕 Confused")
    PAIN=$(ux_ask "    Pain point? (e.g. 'Can't find add button' — or Enter for none):")
    [ -z "$PAIN" ] && PAIN="None"

    TOUCH=$(ux_ask "    Touchpoint? (e.g. 'Product card', 'Mobile app'):")
    [ -z "$TOUCH" ] && TOUCH="Unknown"

    JOURNEY+="
| $step | $ACTION | $EMOTION | $PAIN | $TOUCH |"
  done
  JOURNEY+="
"
else
  JOURNEY="No journey map created."
  ux_add_debt "$AREA" "User journey not mapped" \
    "No detailed user journey steps were documented" \
    "Cannot verify wireframes cover all journey steps"
fi

# ── Q4: Accessibility needs ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 5 — Accessibility needs%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  Does your app need to support any of these? (y/n for each)"
echo ""

ACCESSIBILITY=""

COLOR_BLIND=$(ux_ask_yn "  Color-blindness accommodation needed?")
ACCESSIBILITY+="- **Color-blindness:** $COLOR_BLIND"$'\n'

MOTOR=$(ux_ask_yn "  Keyboard-only navigation (motor impairment)?")
ACCESSIBILITY+="- **Motor (keyboard-only):** $MOTOR"$'\n'

SCREEN_READER=$(ux_ask_yn "  Screen reader support (blind/low vision)?")
ACCESSIBILITY+="- **Screen reader support:** $SCREEN_READER"$'\n'

DYSLEXIA=$(ux_ask_yn "  Dyslexia-friendly fonts (readable typography)?")
ACCESSIBILITY+="- **Dyslexia support:** $DYSLEXIA"$'\n'

HEARING=$(ux_ask_yn "  Captions/transcripts (hearing impairment)?")
ACCESSIBILITY+="- **Hearing loss support:** $HEARING"$'\n'

COGNITIVE=$(ux_ask_yn "  Low cognitive load (plain language, simple flows)?")
ACCESSIBILITY+="- **Cognitive accessibility:** $COGNITIVE"$'\n'

# Check if any are yes and add debt if none
if ! [[ "$ACCESSIBILITY" =~ yes ]]; then
  ux_add_debt "$AREA" "Accessibility requirements not specified" \
    "No accessibility accommodations were requested" \
    "Design may not be inclusive; compliance risk for WCAG"
fi

# ── Q5: Device usage patterns ────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 5 — Device usage patterns%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  What percentage of users are on each device type?"
echo ""

DESKTOP=$(ux_ask "  Desktop users (%)? (e.g. '60' for 60%) — or Enter for unknown:")
[ -z "$DESKTOP" ] && DESKTOP="Unknown"

MOBILE=$(ux_ask "  Mobile users (%)? (e.g. '35'):")
[ -z "$MOBILE" ] && MOBILE="Unknown"

TABLET=$(ux_ask "  Tablet users (%)? (e.g. '5'):")
[ -z "$TABLET" ] && TABLET="Unknown"

# ── Summary ───────────────────────────────────────────────────────────────────
ux_success_rule "✅ User Research Summary"
printf '  %bPersonas captured:%b %s\n' "$UX_BOLD" "$UX_NC" "$(echo "$PERSONAS" | grep -c '^###')"
printf '  %bScenarios captured:%b %s\n' "$UX_BOLD" "$UX_NC" "$(echo "$SCENARIOS" | grep -c '^###')"
printf '  %bDevice split:%b Desktop %s%% | Mobile %s%% | Tablet %s%%\n' "$UX_BOLD" "$UX_NC" "$DESKTOP" "$MOBILE" "$TABLET"
echo ""

if ! ux_confirm_save "Does this look correct? (y=save / n=redo)"; then
  ux_dim "  Restarting Phase 1..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# User Research & Personas"
  echo ""
  echo "> Captured: $DATE_NOW"
  if [ -f "$BA_FINAL" ]; then
    echo "> Requirements basis: \`$BA_FINAL\`"
  fi
  echo ""
  echo "## Primary User Personas"
  echo ""
  echo "$PERSONAS"
  echo ""
  echo "## User Scenarios"
  echo ""
  echo "$SCENARIOS"
  echo ""
  echo "## User Journey Maps"
  echo ""
  echo "$JOURNEY"
  echo ""
  echo "## Accessibility Needs"
  echo ""
  echo "$ACCESSIBILITY"
  echo ""
  echo "## Device Usage Patterns"
  echo ""
  echo "| Device | Percentage |"
  echo "|---|---|"
  echo "| Desktop | $DESKTOP% |"
  echo "| Mobile | $MOBILE% |"
  echo "| Tablet | $TABLET% |"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(ux_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$UX_GREEN" "$OUTPUT_FILE" "$UX_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d UX debt(s) logged to: %s%b\n' "$UX_YELLOW" "$new_debts" "$UX_DEBT_FILE" "$UX_NC"
fi
echo ""
