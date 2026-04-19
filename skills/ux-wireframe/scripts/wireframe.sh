#!/bin/bash
# =============================================================================
# wireframe.sh — Phase 2: Wireframe & Information Architecture
# Creates screen layouts, navigation flows, and information architecture.
# Output: $UX_OUTPUT_DIR/02-wireframes.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../_common.sh
source "$SCRIPT_DIR/../scripts/_common.sh"

# Step 3: accept --auto / --answers flags
ux_parse_flags "$@"


OUTPUT_FILE="$UX_OUTPUT_DIR/02-wireframes.md"
AREA="Wireframe & IA"

start_debts=$(ux_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
ux_banner "🎨  Phase 2 — Wireframes & Information Architecture"
ux_dim "  Let's sketch the screens and navigation structure that serve your users."
ux_dim "  Most answers are numbered choices or short descriptions. Skip with Enter if unsure."
echo ""

# ── Check Phase 1 ────────────────────────────────────────────────────────────
RESEARCH_FILE="$UX_OUTPUT_DIR/01-user-research.md"
if [ -f "$RESEARCH_FILE" ]; then
  printf '%b  ✔ Found Phase 1 output: %s%b\n' "$UX_GREEN" "$RESEARCH_FILE" "$UX_NC"
  ux_dim "  I'll reference your personas and scenarios. Continuing..."
else
  printf '%b  ⚠ No Phase 1 output found at: %s%b\n' "$UX_YELLOW" "$RESEARCH_FILE" "$UX_NC"
  ux_dim "  For best results, run Phase 1 (User Research) first. Continuing anyway..."
  ux_add_debt "$AREA" "No Phase 1 user research found" \
    "ux-output/01-user-research.md was not present" \
    "Wireframes lack user grounding"
fi
echo ""

# ── Q1: Navigation structure ─────────────────────────────────────────────────
printf '%b%bQuestion 1 / 4 — Navigation structure%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

NAV_STRUCTURE=$(ux_ask_choice "What is the primary navigation pattern?" \
  "Sidebar menu (persistent left or right)" \
  "Top horizontal menu" \
  "Bottom tabs (mobile app style)" \
  "Hamburger menu (mobile)" \
  "Linear / wizard (step-by-step)" \
  "Not sure yet")

if [ "$NAV_STRUCTURE" = "Not sure yet" ]; then
  ux_add_debt "$AREA" "Navigation structure not decided" \
    "Primary navigation pattern is open" \
    "Cannot design wireframes without knowing how users navigate"
fi

# ── Q2: Key screens ──────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 4 — Key screens to wireframe%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
ux_dim "  List 3–6 primary screens you want wireframed (comma-separated)."
ux_dim "  Examples: 'Login, Dashboard, Product List, Product Detail, Cart, Checkout'"
echo ""

KEY_SCREENS=$(ux_ask "Your screens:")
if [ -z "$KEY_SCREENS" ]; then
  KEY_SCREENS="TBD"
  ux_add_debt "$AREA" "Key screens not identified" \
    "No primary screens were listed for wireframing" \
    "Cannot produce wireframes without screen list"
fi

# ── Q3: Layout preferences ───────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 4 — Page layout%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

LAYOUT=$(ux_ask_choice "Primary layout pattern?" \
  "Header + Sidebar + Main + Footer" \
  "Header + Main (full width) + Footer" \
  "Two-column: narrow left (sidebar) + wide right (main)" \
  "Card-based grid layout" \
  "Floating elements (no strict grid)" \
  "Not decided yet")

HIERARCHY=$(ux_ask "Content hierarchy: where should the main CTA (call-to-action) be? (e.g. 'top-right corner', 'inline with product card')")
if [ -z "$HIERARCHY" ]; then
  HIERARCHY="Not specified"
  ux_add_debt "$AREA" "Content hierarchy not specified" \
    "CTA placement and hierarchy unclear" \
    "Design may lack visual guidance for primary action"
fi

# ── Q4: Interaction patterns ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 4 — Interaction patterns%b\n' "$UX_CYAN" "$UX_BOLD" "$UX_NC"
echo ""

FORMS=$(ux_ask_choice "Form interaction style?" \
  "Single-page form with real-time validation" \
  "Multi-step wizard with progress bar" \
  "Simple submit with validation on submit" \
  "Not yet decided")

LISTS=$(ux_ask_choice "For lists/tables, what interactions matter most?" \
  "Sorting and filtering" \
  "Search only" \
  "Pagination to view more" \
  "Infinite scroll (load more automatically)" \
  "All of the above" \
  "Not applicable for this product")

RESPONSIVE=$(ux_ask_choice "Responsive design approach?" \
  "Mobile-first (design for mobile, enhance for desktop)" \
  "Desktop-first (design for desktop, adapt for mobile)" \
  "Separate designs per breakpoint" \
  "Not decided yet")

if [ "$RESPONSIVE" = "Not decided yet" ]; then
  ux_add_debt "$AREA" "Responsive strategy not decided" \
    "Mobile-first vs. desktop-first not chosen" \
    "Cannot finalize layout without responsiveness strategy"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
ux_success_rule "✅ Wireframe Plan Summary"
printf '  %bNavigation:%b        %s\n' "$UX_BOLD" "$UX_NC" "$NAV_STRUCTURE"
printf '  %bKey screens:%b       %s\n' "$UX_BOLD" "$UX_NC" "$KEY_SCREENS"
printf '  %bLayout pattern:%b    %s\n' "$UX_BOLD" "$UX_NC" "$LAYOUT"
printf '  %bCTA placement:%b     %s\n' "$UX_BOLD" "$UX_NC" "$HIERARCHY"
printf '  %bForms:%b            %s\n' "$UX_BOLD" "$UX_NC" "$FORMS"
printf '  %bLists/Tables:%b      %s\n' "$UX_BOLD" "$UX_NC" "$LISTS"
printf '  %bResponsive:%b        %s\n' "$UX_BOLD" "$UX_NC" "$RESPONSIVE"
echo ""

if ! ux_confirm_save "Does this look correct? (y=save / n=redo)"; then
  ux_dim "  Restarting Phase 2..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Wireframes & Information Architecture"
  echo ""
  echo "> Captured: $DATE_NOW"
  [ -f "$RESEARCH_FILE" ] && echo "> User research basis: \`$RESEARCH_FILE\`"
  echo ""
  echo "## Navigation Structure"
  echo ""
  echo "**Primary pattern:** $NAV_STRUCTURE"
  echo ""
  echo "## Key Screens"
  echo ""
  echo "**Screens to wireframe:** $KEY_SCREENS"
  echo ""
  echo "## Layout & Hierarchy"
  echo ""
  echo "**Layout pattern:** $LAYOUT"
  echo ""
  echo "**Content hierarchy / CTA placement:** $HIERARCHY"
  echo ""
  echo "## Interaction Patterns"
  echo ""
  echo "| Pattern | Choice |"
  echo "|---|---|"
  echo "| Forms | $FORMS |"
  echo "| Lists / Tables | $LISTS |"
  echo "| Responsive strategy | $RESPONSIVE |"
  echo ""
  echo "## Wireframe Sketches"
  echo ""
  echo "*(Detailed wireframe descriptions for each screen will be added in next iteration)*"
  echo ""
  echo "## Navigation Flowchart"
  echo ""
  echo "\`\`\`mermaid"
  echo "flowchart TD"
  echo "  Home[Home] --> Nav{Navigation}"
  echo "  Nav -->|Screen1| S1[Screen 1]"
  echo "  Nav -->|Screen2| S2[Screen 2]"
  echo "  S1 --> End[End]"
  echo "  S2 --> End"
  echo "\`\`\`"
  echo ""
  echo "## Information Architecture"
  echo ""
  echo "\`\`\`mermaid"
  echo "graph TD"
  echo "  Root[App] --> S1[$KEY_SCREENS]"
  echo "\`\`\`"
  echo ""
  echo "## Responsive Considerations"
  echo ""
  echo "- **Strategy:** $RESPONSIVE"
  echo "- **Breakpoints:** [Mobile: <768px, Tablet: 768-1024px, Desktop: >1024px]"
  echo "- **Touch targets:** Minimum 48px for mobile"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(ux_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$UX_GREEN" "$OUTPUT_FILE" "$UX_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d UX debt(s) logged to: %s%b\n' "$UX_YELLOW" "$new_debts" "$UX_DEBT_FILE" "$UX_NC"
fi
echo ""
