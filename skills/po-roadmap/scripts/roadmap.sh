#!/bin/bash
# =============================================================================
# roadmap.sh — Phase 3: Product Roadmap Planning
# Creates a release-based product roadmap with themes and milestones.
# Output: $PO_OUTPUT_DIR/03-product-roadmap.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
po_parse_flags "$@"


OUTPUT_FILE="$PO_OUTPUT_DIR/03-product-roadmap.md"
AREA="Product Roadmap"

start_debts=$(po_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
po_banner "🗺   Phase 3 — Product Roadmap"
po_dim "  Let's plan when features ship and communicate product direction."
echo ""

# ── Q1: Roadmap horizon ───────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Roadmap Horizon%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  How far ahead should we plan?"
echo ""
HORIZON=$(po_ask_choice "Select roadmap horizon:" \
  "1 Quarter (3 months)" \
  "2 Quarters (6 months)" \
  "1 Year (12 months)" \
  "18 Months" \
  "Custom (you'll specify)")

if [ "$HORIZON" = "Custom (you'll specify)" ]; then
  HORIZON=$(po_ask "Enter custom horizon (e.g. '9 months', '2 years'):")
fi

# ── Q2: Release cadence ───────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — Release Cadence%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  How often do you release new versions?"
echo ""
CADENCE=$(po_ask_choice "Release frequency:" \
  "Weekly" \
  "Bi-weekly (every 2 weeks)" \
  "Monthly" \
  "Quarterly" \
  "Custom (you'll specify)")

if [ "$CADENCE" = "Custom (you'll specify)" ]; then
  CADENCE=$(po_ask "Enter custom cadence (e.g. 'every 2 weeks', '3 times per quarter'):")
fi

# ── Q3: Release themes and periods ────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Release Themes & Goals%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Define what each release or period focuses on."
echo ""

declare -a RELEASE_NAMES
declare -a RELEASE_DATES
declare -a RELEASE_THEMES
declare -a RELEASE_GOALS

release_count=0

while true; do
  release_num=$((release_count + 1))
  printf '%b▶ Add release #%d? (y/n): %b' "$PO_YELLOW" "$release_num" "$PO_NC"
  IFS= read -r response
  response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "$response" != "y" ] && [ "$response" != "yes" ]; then
    break
  fi

  NAME=$(po_ask "Release name (e.g. 'v1.0', 'Spring 2026', 'MVP'):")
  [ -z "$NAME" ] && NAME="Release $((release_count + 1))"
  RELEASE_NAMES+=("$NAME")

  DATE=$(po_ask "Planned date (e.g. 'End of March 2026', 'Q2 2026'):")
  [ -z "$DATE" ] && DATE="TBD"
  RELEASE_DATES+=("$DATE")

  THEME=$(po_ask "Release theme (main focus):")
  [ -z "$THEME" ] && THEME="No theme defined"
  RELEASE_THEMES+=("$THEME")

  GOALS=$(po_ask "Key goals/highlights (comma-separated):")
  [ -z "$GOALS" ] && GOALS="TBD"
  RELEASE_GOALS+=("$GOALS")

  release_count=$((release_count + 1))
done

if [ "$release_count" -eq 0 ]; then
  po_add_debt "$AREA" "No releases defined" \
    "Roadmap has no release periods" \
    "Stakeholder communication, team planning"
fi

# ── Q4: Key milestones ────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Key Milestones%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Major dates, events, or deliverables beyond releases."
po_dim "  Example: 'Beta launch - June 2026', 'GA release - Q3 2026'"
echo ""
MILESTONES=$(po_ask "Your answer (comma-separated, or press Enter to skip):")
[ -z "$MILESTONES" ] && MILESTONES="Not yet defined"

# ── Q5: External dependencies ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — External Dependencies%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Dependencies on other teams, vendors, or events."
po_dim "  Example: 'Waiting for vendor API - May 2026'"
echo ""
DEPENDENCIES=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$DEPENDENCIES" ] && DEPENDENCIES="None identified"

# ── Q6: Success metrics ───────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Success Metrics per Release%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  How will you measure success for each release?"
po_dim "  Example: 'User adoption > 1000', 'Page load < 200ms'"
echo ""
METRICS=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$METRICS" ] && METRICS="Not yet defined"

# ── Summary ───────────────────────────────────────────────────────────────────
po_success_rule "✅ Roadmap Summary"
printf '  %bHorizon:%b        %s\n' "$PO_BOLD" "$PO_NC" "$HORIZON"
printf '  %bCadence:%b        %s\n' "$PO_BOLD" "$PO_NC" "$CADENCE"
printf '  %bReleases:%b       %d releases\n' "$PO_BOLD" "$PO_NC" "$release_count"
printf '  %bMilestones:%b     %s\n' "$PO_BOLD" "$PO_NC" "$(echo "$MILESTONES" | cut -c1-40)..."
echo ""

if ! po_confirm_save "Does this look correct? (y=save / n=redo)"; then
  po_dim "  Restarting phase 3..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Product Roadmap"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Roadmap Overview"
  echo ""
  echo "**Horizon:** $HORIZON"
  echo ""
  echo "**Release Cadence:** $CADENCE"
  echo ""
  echo "## Release Schedule"
  echo ""

  if [ "$release_count" -gt 0 ]; then
    echo "| Release | Planned Date | Theme | Goals |"
    echo "|---------|--------------|-------|-------|"
    for ((i=0; i<release_count; i++)); do
      printf "| %s | %s | %s | %s |\n" \
        "${RELEASE_NAMES[$i]}" \
        "${RELEASE_DATES[$i]}" \
        "${RELEASE_THEMES[$i]}" \
        "$(echo "${RELEASE_GOALS[$i]}" | cut -c1-30)..."
    done
    echo ""
    echo "### Release Details"
    echo ""
    for ((i=0; i<release_count; i++)); do
      echo "#### ${RELEASE_NAMES[$i]}"
      echo ""
      echo "**Planned Date:** ${RELEASE_DATES[$i]}"
      echo ""
      echo "**Theme:** ${RELEASE_THEMES[$i]}"
      echo ""
      echo "**Goals:**"
      echo ""
      echo "- $(echo "${RELEASE_GOALS[$i]}" | sed 's/, /\n- /g')"
      echo ""
    done
  else
    echo "(No releases defined)"
    echo ""
  fi

  echo "## Key Milestones"
  echo ""
  echo "$MILESTONES"
  echo ""
  echo "## External Dependencies"
  echo ""
  echo "$DEPENDENCIES"
  echo ""
  echo "## Success Metrics"
  echo ""
  echo "$METRICS"
  echo ""
} > "$OUTPUT_FILE"

po_success_rule "✅ Product Roadmap saved"
printf '%b  Output: %s%b\n' "$PO_GREEN" "$OUTPUT_FILE" "$PO_NC"
echo ""

# ── Log new debts ─────────────────────────────────────────────────────────────
end_debts=$(po_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  po_dim "  Logged $new_debts debt(s) — see po-output/06-po-debts.md"
fi
echo ""
