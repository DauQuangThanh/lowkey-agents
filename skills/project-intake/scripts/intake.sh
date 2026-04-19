#!/bin/bash
# =============================================================================
# intake.sh — Phase 1: Project Intake
# Gathers basic project context with minimal user effort.
# Output: $BA_OUTPUT_DIR/01-project-intake.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


OUTPUT_FILE="$BA_OUTPUT_DIR/01-project-intake.md"
AREA="Project Intake"

start_debts=$(ba_current_debt_count)

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "📋  Step 1 of 7 — Project Intake"
ba_dim "  Let's start with the basics. I'll ask you a series of simple questions."
ba_dim "  There are no wrong answers — just share what you know."
echo ""

# ── Q1: Project name ─────────────────────────────────────────────────────────
printf '%b%bQuestion 1 / 8 — Project Name%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
PROJECT_NAME=$(ba_get PROJECT_NAME "What is the name of this project? (e.g. 'Customer Portal', 'Inventory App')")
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME="Unnamed Project"
  ba_add_debt "$AREA" "Project name not provided" \
    "Project has no confirmed name" \
    "Branding, documentation, and team communication"
fi

# ── Q2: Problem statement ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 8 — The Problem%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  In one or two sentences, what problem are you trying to solve?"
ba_dim "  Example: 'Our team tracks orders in spreadsheets and keeps losing data.'"
echo ""
PROBLEM=$(ba_get PROBLEM "Your answer:")
if [ -z "$PROBLEM" ]; then
  PROBLEM="TBD"
  ba_add_debt "$AREA" "Problem statement not defined" \
    "The core problem this project solves is not documented" \
    "All requirements are anchored to the problem statement"
fi

# ── Q3: Methodology ───────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 8 — Development Approach%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  How will the team build this project? (If unsure, choose the last option.)"
echo ""
METHODOLOGY=$(ba_get_choice METHODOLOGY "Select one:" \
  "Agile / Scrum — Work in short 2-week sprints with regular reviews" \
  "Kanban — Continuous flow of work with no fixed sprints" \
  "Waterfall — Plan everything first, then build in sequence" \
  "Hybrid — Mix of structured planning and flexible delivery" \
  "Not decided yet")
if [ "$METHODOLOGY" = "Not decided yet" ]; then
  ba_add_debt "$AREA" "Methodology not selected" \
    "Development approach has not been chosen" \
    "Sprint planning, ceremony setup, and release cadence"
fi

# ── Q4: Timeline ─────────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 8 — Estimated Timeline%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
echo ""
TIMELINE=$(ba_get_choice TIMELINE "How long do you expect this project to take?" \
  "Less than 1 month" \
  "1 to 3 months" \
  "3 to 6 months" \
  "6 to 12 months" \
  "More than 1 year")

# ── Q5: Hard deadline ────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 8 — Hard Deadline%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
# HARD_DEADLINE is either a date string, "None", or empty. Treat non-empty
# values other than "None" as the actual deadline.
DEADLINE=$(ba_get HARD_DEADLINE "What is the hard deadline? (e.g. 31 Dec 2026, or 'None')" "None")
[ -z "$DEADLINE" ] && DEADLINE="None"

# ── Q6: Team size ─────────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 8 — Team Size%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
echo ""
TEAM_SIZE=$(ba_get_choice TEAM_SIZE "How many people will work on this project?" \
  "Just me — I'm working alone" \
  "2 to 5 people — Small team" \
  "6 to 15 people — Medium team" \
  "More than 15 people — Large team")

# ── Q7: Budget ────────────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 7 / 8 — Budget%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
# BUDGET can be "Not specified" (no limit), a specific range, or any freeform value.
BUDGET=$(ba_get BUDGET "What is the approximate budget range? (or 'Not specified')" "Not specified")
[ -z "$BUDGET" ] && BUDGET="Not specified"

# ── Q8: Out of scope ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 8 / 8 — What is OUT of scope?%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  Is there anything people might expect but should NOT be included?"
ba_dim "  Example: 'We are NOT building a mobile app in version 1.'"
ba_dim "  (Press Enter to skip if nothing comes to mind)"
echo ""
OUT_OF_SCOPE=$(ba_get OUT_OF_SCOPE "Your answer:")
[ -z "$OUT_OF_SCOPE" ] && OUT_OF_SCOPE="To be defined"

# ── Summary ───────────────────────────────────────────────────────────────────
ba_success_rule "✅ Project Intake Summary"
printf '  %bProject:%b      %s\n' "$BA_BOLD" "$BA_NC" "$PROJECT_NAME"
printf '  %bProblem:%b      %s\n' "$BA_BOLD" "$BA_NC" "$PROBLEM"
printf '  %bApproach:%b     %s\n' "$BA_BOLD" "$BA_NC" "$METHODOLOGY"
printf '  %bTimeline:%b     %s\n' "$BA_BOLD" "$BA_NC" "$TIMELINE"
printf '  %bDeadline:%b     %s\n' "$BA_BOLD" "$BA_NC" "$DEADLINE"
printf '  %bTeam size:%b    %s\n' "$BA_BOLD" "$BA_NC" "$TEAM_SIZE"
printf '  %bBudget:%b       %s\n' "$BA_BOLD" "$BA_NC" "$BUDGET"
printf '  %bOut of scope:%b %s\n' "$BA_BOLD" "$BA_NC" "$OUT_OF_SCOPE"
echo ""

if ! ba_confirm_save "Does this look correct? (y=save / n=redo)"; then
  ba_dim "  Restarting step 1..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Project Intake"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Project Overview"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| **Project Name** | $PROJECT_NAME |"
  echo "| **Methodology** | $METHODOLOGY |"
  echo "| **Timeline** | $TIMELINE |"
  echo "| **Hard Deadline** | $DEADLINE |"
  echo "| **Team Size** | $TEAM_SIZE |"
  echo "| **Budget** | $BUDGET |"
  echo ""
  echo "## Problem Statement"
  echo ""
  echo "$PROBLEM"
  echo ""
  echo "## Out of Scope"
  echo ""
  echo "$OUT_OF_SCOPE"
  echo ""
} > "$OUTPUT_FILE"

ba_write_extract "${OUTPUT_FILE%.md}.extract" \
  "PROJECT_NAME=$PROJECT_NAME" \
  "PROBLEM=$PROBLEM" \
  "METHODOLOGY=$METHODOLOGY" \
  "TIMELINE=$TIMELINE" \
  "HARD_DEADLINE=$DEADLINE" \
  "TEAM_SIZE=$TEAM_SIZE" \
  "BUDGET=$BUDGET" \
  "OUT_OF_SCOPE=$OUT_OF_SCOPE"

end_debts=$(ba_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$BA_GREEN" "$OUTPUT_FILE" "$BA_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d requirement debt(s) logged to: %s%b\n' "$BA_YELLOW" "$new_debts" "$BA_DEBT_FILE" "$BA_NC"
fi
echo ""
