#!/bin/bash
# =============================================================================
# prototype.sh — Phase 3: Mockup & Prototype Specification
# Specifies visual design direction and interaction details.
# Output: $UX_OUTPUT_DIR/03-prototype-spec.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../ux-research/scripts/_common.sh
source "$SCRIPT_DIR/../../ux-research/scripts/_common.sh"

# Step 3: accept --auto / --answers flags
ux_parse_flags "$@"


OUTPUT_FILE="$UX_OUTPUT_DIR/03-prototype-spec.md"
AREA="Prototype Specification"

start_debts=$(ux_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
ux_banner "🎭  Phase 3 — Mockup & Prototype Specification"
ux_dim "  Let's define the visual design and interaction details for your interface."
ux_dim "  Most answers are numbered choices or short descriptions. Skip with Enter if unsure."
echo ""

# ── Check Phase 2 ────────────────────────────────────────────────────────────
WIREFRAME_FILE="$UX_OUTPUT_DIR/02-wireframes.md"
if [ -f "$WIREFRAME_FILE" ]; then
  printf '%b  ✔ Found Phase 2 output: %s%b\n' "$UX_GREEN" "$WIREFRAME_FILE" "$UX_NC"
  ux_dim "  I'll reference your wireframes and layout decisions. Continuing..."
else
  printf '%b  ⚠ No Phase 2 output found at: %s%b\n' "$UX_YELLOW" "$WIREFRAME_FILE" "$UX_NC"
  ux_dim "  For best results, run Phase 2 (Wireframes) first. Continuing anyway..."
  ux_add_debt "$AREA" "No Phase 2 wireframes found" \
    "ux-output/02-wireframes.md was not present" \
    "Design specifications may lack layout grounding"
fi
echo ""

# ── Q1: Visual style ─────────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 4 — Visual style preference%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

VISUAL_STYLE=$(ux_ask_choice "Choose or describe a visual style:" \
  "Minimal — clean, whitespace, sans-serif, 2–3 colors, flat" \
  "Corporate — professional, structured, blues/grays, clear hierarchy" \
  "Playful — approachable, rounded, warm colors, illustrations" \
  "Modern — bold typography, asymmetric, gradients, animations" \
  "Custom — I'll describe my own aesthetic")

if [ "$VISUAL_STYLE" = "Custom — I'll describe my own aesthetic" ]; then
  VISUAL_STYLE=$(ux_ask "Describe your visual style preference:")
  [ -z "$VISUAL_STYLE" ] && VISUAL_STYLE="TBD"
fi

if [ "$VISUAL_STYLE" = "TBD" ]; then
  ux_add_debt "$AREA" "Visual style not defined" \
    "Design aesthetic is open" \
    "Developers cannot implement design without style direction"
fi

# ── Q2: Color scheme ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 4 — Color scheme%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  Examples: '#0055CC blue, #6C63FF purple, #F5F5F5 light gray'"
echo ""

PRIMARY_COLOR=$(ux_ask "Primary color (hex or name)? e.g. '#0055CC' or 'brand blue':")
[ -z "$PRIMARY_COLOR" ] && PRIMARY_COLOR="TBD"

SECONDARY_COLOR=$(ux_ask "Secondary color? e.g. '#6C63FF':")
[ -z "$SECONDARY_COLOR" ] && SECONDARY_COLOR="TBD"

ACCENT_COLOR=$(ux_ask "Accent color (e.g. for highlights)? e.g. '#FFD700':")
[ -z "$ACCENT_COLOR" ] && ACCENT_COLOR="TBD"

DARK_MODE=$(ux_ask_yn "Does the app need a dark mode?")

if [ "$PRIMARY_COLOR" = "TBD" ] || [ "$SECONDARY_COLOR" = "TBD" ]; then
  ux_add_debt "$AREA" "Color palette not finalized" \
    "Primary and/or secondary colors not specified" \
    "Design implementation and accessibility review cannot proceed"
fi

# ── Q3: Typography ───────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 4 — Typography%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  Examples: 'Roboto', 'System fonts', 'Helvetica Neue + Georgia'"
echo ""

FONTS=$(ux_ask "Font preference? (e.g. 'Roboto', 'System fonts', 'Inter + Courier'):")
[ -z "$FONTS" ] && FONTS="System fonts (default)"

HEADING_SIZE=$(ux_ask "Heading font size (e.g. '32px for H1')? Or Enter for standard scale:")
[ -z "$HEADING_SIZE" ] && HEADING_SIZE="32px / 24px / 18px (standard)"

# ── Q4: Interactions & component states ────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 4 — Component interactions%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  Which component states are most important to spec?"
echo ""

BUTTON_STATES=$(ux_ask_yn "Specify button states (hover, active, disabled)?")

FORM_VALIDATION=$(ux_ask_yn "Specify form validation states (error, success)?")

LOADING=$(ux_ask_yn "Specify loading states (spinners, skeletons)?")

PROTOTYPING_TOOL=$(ux_ask_choice "Where will this be prototyped for user testing?" \
  "Figma (design tool with prototype features)" \
  "InVision (interactive prototype platform)" \
  "Clickable HTML/CSS (basic prototype)" \
  "Not yet decided")

# ── Summary ───────────────────────────────────────────────────────────────────
ux_success_rule "✅ Design Specification Summary"
printf '  %bVisual style:%b        %s\n' "$UX_BOLD" "$UX_NC" "$VISUAL_STYLE"
printf '  %bColors:%b             Primary: %s | Secondary: %s | Accent: %s\n' "$UX_BOLD" "$UX_NC" "$PRIMARY_COLOR" "$SECONDARY_COLOR" "$ACCENT_COLOR"
printf '  %bDark mode:%b          %s\n' "$UX_BOLD" "$UX_NC" "$DARK_MODE"
printf '  %bFonts:%b             %s\n' "$UX_BOLD" "$UX_NC" "$FONTS"
printf '  %bPrototyping tool:%b   %s\n' "$UX_BOLD" "$UX_NC" "$PROTOTYPING_TOOL"
echo ""

if ! ux_confirm_save "Does this look correct? (y=save / n=redo)"; then
  ux_dim "  Restarting Phase 3..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Mockup & Prototype Specification"
  echo ""
  echo "> Captured: $DATE_NOW"
  [ -f "$WIREFRAME_FILE" ] && echo "> Wireframe basis: \`$WIREFRAME_FILE\`"
  echo ""
  echo "## Visual Design Direction"
  echo ""
  echo "**Style:** $VISUAL_STYLE"
  echo ""
  echo "## Color Palette"
  echo ""
  echo "| Role | Color | Usage |"
  echo "|---|---|---|"
  echo "| Primary | $PRIMARY_COLOR | Buttons, links, active states |"
  echo "| Secondary | $SECONDARY_COLOR | Accents, secondary actions |"
  echo "| Accent | $ACCENT_COLOR | Highlights, emphasis |"
  echo ""
  echo "**Dark mode:** $DARK_MODE"
  echo ""
  echo "## Typography"
  echo ""
  echo "**Fonts:** $FONTS"
  echo ""
  echo "**Size scale:**"
  echo "- Heading 1: $HEADING_SIZE"
  echo "- Heading 2: [20px / 28px]"
  echo "- Body: 16px (14px on mobile)"
  echo "- Label: 12px"
  echo ""
  echo "## Component Interactions"
  echo ""
  echo "| Component | Spec Status |"
  echo "|---|---|"
  echo "| Button states | $BUTTON_STATES |"
  echo "| Form validation | $FORM_VALIDATION |"
  echo "| Loading states | $LOADING |"
  echo ""
  echo "## Prototyping Approach"
  echo ""
  echo "**Tool:** $PROTOTYPING_TOOL"
  echo ""
  echo "## Mockup Specifications"
  echo ""
  echo "*(Add detailed mockups for each key screen with spacing, typography, and color assignments here)*"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(ux_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$UX_GREEN" "$OUTPUT_FILE" "$UX_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d UX debt(s) logged to: %s%b\n' "$UX_YELLOW" "$new_debts" "$UX_DEBT_FILE" "$UX_NC"
fi
echo ""
