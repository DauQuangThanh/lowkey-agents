#!/bin/bash
# =============================================================================
# backlog.sh — Phase 1: Product Backlog Management
# Gathers product vision and backlog items with prioritization.
# Output: $PO_OUTPUT_DIR/01-product-backlog.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
po_parse_flags "$@"


OUTPUT_FILE="$PO_OUTPUT_DIR/01-product-backlog.md"
AREA="Product Backlog"

start_debts=$(po_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
po_banner "📋  Phase 1 — Product Backlog Management"
po_dim "  Let's define what we're building and prioritize the work."
po_dim "  You can add as many backlog items as needed."
echo ""

# ── Q1: Product vision ────────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 8 — Product Vision%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  In one or two sentences, what is the vision for this product?"
po_dim "  Example: 'A mobile app that helps teams collaborate on projects in real-time.'"
echo ""
VISION=$(po_ask "Your answer:")
if [ -z "$VISION" ]; then
  VISION="TBD"
  po_add_debt "$AREA" "Product vision not defined" \
    "Product vision statement is missing" \
    "Backlog prioritization, release planning, and stakeholder alignment"
fi

# ── Q2: Backlog items ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 8 — Backlog Items%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Let's add backlog items. You can add as many as you'd like."
po_dim "  For each, I'll ask: title, description, type, priority, value, and estimate."
echo ""

declare -a ITEMS_TITLE
declare -a ITEMS_DESC
declare -a ITEMS_TYPE
declare -a ITEMS_PRIORITY
declare -a ITEMS_VALUE
declare -a ITEMS_EST

item_count=0

while true; do
  item_num=$((item_count + 1))
  echo ""
  printf '%b▶ Add backlog item #%d? (y/n): %b' "$PO_YELLOW" "$item_num" "$PO_NC"
  IFS= read -r response
  response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "$response" != "y" ] && [ "$response" != "yes" ]; then
    break
  fi

  TITLE=$(po_ask "Title (e.g. 'User login feature'):")
  [ -z "$TITLE" ] && TITLE="Untitled Item"
  ITEMS_TITLE+=("$TITLE")

  DESC=$(po_ask "Description:")
  [ -z "$DESC" ] && DESC="No description"
  ITEMS_DESC+=("$DESC")

  TYPE=$(po_ask_choice "Type:" \
    "Epic — Large feature or initiative" \
    "Story — User-facing feature" \
    "Bug — Defect or issue" \
    "Tech-Debt — Internal improvement")
  ITEMS_TYPE+=("$TYPE")

  PRIORITY=$(po_ask_choice "Priority (MoSCoW):" \
    "Must Have — Critical, non-negotiable" \
    "Should Have — Important, but flexible" \
    "Could Have — Nice-to-have" \
    "Won't Have — Explicitly excluded")
  ITEMS_PRIORITY+=("$PRIORITY")

  VALUE=$(po_ask_choice "Business Value:" \
    "High — Directly solves core problem" \
    "Medium — Supports core capability" \
    "Low — Nice feature, supporting role")
  ITEMS_VALUE+=("$VALUE")

  EST=$(po_ask_choice "Estimation (T-shirt):" \
    "S — Small (1-3 days)" \
    "M — Medium (1-2 weeks)" \
    "L — Large (3+ weeks)" \
    "XL — Extra Large (1+ month)")
  ITEMS_EST+=("$EST")

  item_count=$((item_count + 1))
done

if [ "$item_count" -eq 0 ]; then
  po_add_debt "$AREA" "No backlog items defined" \
    "Backlog has no items" \
    "Sprint planning, roadmap definition, and MVP scope"
fi

# ── Q3: Dependencies ──────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 8 — Dependencies%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Are there any dependencies between items?"
po_dim "  Example: 'User auth must be done before user profile.'"
echo ""
DEPENDENCIES=$(po_ask "Your answer (or press Enter to skip):")
[ -z "$DEPENDENCIES" ] && DEPENDENCIES="None identified"

# ── Q4: MVP definition ────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 8 — MVP Definition%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  Which backlog items are in the Minimum Viable Product (MVP)?"
echo ""
MVP=$(po_ask "Your answer (comma-separated item titles, or press Enter if unclear):")
if [ -z "$MVP" ]; then
  MVP="To be determined"
  po_add_debt "$AREA" "MVP not clearly defined" \
    "Which items are in the MVP is unclear" \
    "Release planning, scope management, and stakeholder expectations"
fi

# ── Q5: Total effort ──────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 8 — Total Estimated Effort%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
TOTAL_EFFORT=$(po_ask "Estimate total effort for all backlog items (e.g. '10 sprints', '6 months'):")
[ -z "$TOTAL_EFFORT" ] && TOTAL_EFFORT="To be calculated"

# ── Q6: Release priorities ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 8 — Release Priorities%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  How should backlog items be released? What are the themes?"
echo ""
RELEASE_STRATEGY=$(po_ask "Your answer:")
[ -z "$RELEASE_STRATEGY" ] && RELEASE_STRATEGY="Not yet planned"

# ── Q7: Backlog refinement ────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 7 / 8 — Backlog Refinement Cadence%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
REFINEMENT=$(po_ask_choice "How often should the backlog be refined?" \
  "Weekly — Continuous refinement" \
  "Bi-weekly — During sprint planning" \
  "Monthly — Structured grooming" \
  "Not yet decided")

# ── Q8: MVP acceptance criteria ───────────────────────────────────────────────
echo ""
printf '%b%bQuestion 8 / 8 — MVP Acceptance Criteria%b\n' "$PO_CYAN" "$PO_BOLD" "$PO_NC"
po_dim "  What criteria must be met for the MVP to be accepted?"
echo ""
MVP_CRITERIA=$(po_ask "Your answer (or press Enter to defer to Phase 2):")
[ -z "$MVP_CRITERIA" ] && MVP_CRITERIA="To be defined in acceptance criteria phase"

# ── Summary ───────────────────────────────────────────────────────────────────
po_success_rule "✅ Backlog Summary"
printf '  %bVision:%b         %s\n' "$PO_BOLD" "$PO_NC" "$VISION"
printf '  %bItems:%b          %d items\n' "$PO_BOLD" "$PO_NC" "$item_count"
printf '  %bMVP:%b            %s\n' "$PO_BOLD" "$PO_NC" "$MVP"
printf '  %bTotal Effort:%b    %s\n' "$PO_BOLD" "$PO_NC" "$TOTAL_EFFORT"
printf '  %bRefinement:%b      %s\n' "$PO_BOLD" "$PO_NC" "$REFINEMENT"
echo ""

if ! po_confirm_save "Does this look correct? (y=save / n=redo)"; then
  po_dim "  Restarting phase 1..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Product Backlog"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Product Vision"
  echo ""
  echo "$VISION"
  echo ""
  echo "## Backlog Items"
  echo ""

  if [ "$item_count" -gt 0 ]; then
    echo "| # | Title | Type | Priority | Value | Estimation |"
    echo "|---|-------|------|----------|-------|------------|"
    for ((i=0; i<item_count; i++)); do
      printf "| %d | %s | %s | %s | %s | %s |\n" \
        "$((i+1))" \
        "${ITEMS_TITLE[$i]}" \
        "${ITEMS_TYPE[$i]}" \
        "${ITEMS_PRIORITY[$i]}" \
        "${ITEMS_VALUE[$i]}" \
        "${ITEMS_EST[$i]}"
    done
    echo ""
    echo "## Detailed Item Descriptions"
    echo ""
    for ((i=0; i<item_count; i++)); do
      echo "### ${i+1}. ${ITEMS_TITLE[$i]}"
      echo ""
      echo "**Type:** ${ITEMS_TYPE[$i]}"
      echo ""
      echo "**Priority:** ${ITEMS_PRIORITY[$i]}"
      echo ""
      echo "**Business Value:** ${ITEMS_VALUE[$i]}"
      echo ""
      echo "**Estimation:** ${ITEMS_EST[$i]}"
      echo ""
      echo "**Description:** ${ITEMS_DESC[$i]}"
      echo ""
    done
  else
    echo "(No backlog items added)"
    echo ""
  fi

  echo "## MVP Definition"
  echo ""
  echo "$MVP"
  echo ""
  echo "## Dependencies"
  echo ""
  echo "$DEPENDENCIES"
  echo ""
  echo "## Total Estimated Effort"
  echo ""
  echo "$TOTAL_EFFORT"
  echo ""
  echo "## Release Strategy"
  echo ""
  echo "$RELEASE_STRATEGY"
  echo ""
  echo "## Backlog Refinement Cadence"
  echo ""
  echo "$REFINEMENT"
  echo ""
  echo "## MVP Acceptance Criteria"
  echo ""
  echo "$MVP_CRITERIA"
  echo ""
} > "$OUTPUT_FILE"

po_success_rule "✅ Product Backlog saved"
printf '%b  Output: %s%b\n' "$PO_GREEN" "$OUTPUT_FILE" "$PO_NC"
echo ""

# ── Log new debts ─────────────────────────────────────────────────────────────
end_debts=$(po_current_debt_count)
if [ "$end_debts" -gt "$start_debts" ]; then
  new_debts=$((end_debts - start_debts))
  po_dim "  Logged $new_debts debt(s) — see po-output/06-po-debts.md"
fi
echo ""
