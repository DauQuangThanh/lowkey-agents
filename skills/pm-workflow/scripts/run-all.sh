#!/bin/bash
# =============================================================================
# run-all.sh — Project Manager Full Workflow Runner
# Runs all 5 PM phases in sequence and compiles the final document.
# Usage: bash <SKILL_DIR>/pm-workflow/scripts/run-all.sh [--skip-to N]
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
pm_parse_flags "$@"


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TOTAL_STEPS=5
START_STEP=1

# ── Parse args ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--skip-to" ] && [ -n "${2:-}" ]; then
  START_STEP="$2"
  pm_dim "  Skipping to step $START_STEP..."
fi

# ── Check for existing pm-output ──────────────────────────────────────────────
if [ -d "$PM_OUTPUT_DIR" ] && [ "$(ls -A "$PM_OUTPUT_DIR" 2>/dev/null)" ]; then
  if pm_is_auto; then
    pm_dim "  Auto mode: continuing from existing output in $PM_OUTPUT_DIR"
  else
    printf '\n%b⚠ Found existing project management output at:%b\n' "$PM_YELLOW" "$PM_NC"
    printf '%b  %s%b\n' "$PM_CYAN" "$PM_OUTPUT_DIR" "$PM_NC"
    printf '\n%bArchive and start fresh? (y/n): %b' "$PM_YELLOW" "$PM_NC"
    IFS= read -r archive_choice
    if [ "$(to_lower "$archive_choice")" = "y" ] || [ "$(to_lower "$archive_choice")" = "yes" ]; then
      ARCHIVE_DIR="${PM_OUTPUT_DIR}_archive_${TIMESTAMP}"
      mv "$PM_OUTPUT_DIR" "$ARCHIVE_DIR"
      mkdir -p "$PM_OUTPUT_DIR"
      pm_dim "  Archived to: $ARCHIVE_DIR"
    fi
  fi
fi

# ── Step runner ───────────────────────────────────────────────────────────────
step_header() {
  local step="$1" total="$2" title="$3"
  printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$PM_CYAN$PM_BOLD" "$PM_NC"
  printf '%b  STEP %s of %s — %s%b\n' "$PM_CYAN$PM_BOLD" "$step" "$total" "$title" "$PM_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$PM_CYAN$PM_BOLD" "$PM_NC"
}

progress_bar() {
  local current="$1" total="$2"
  local filled=$(( current * 20 / total ))
  local empty=$(( 20 - filled ))
  local bar="" i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  printf '%b  Progress: [%s] %s/%s%b\n' "$PM_GREEN" "$bar" "$current" "$total" "$PM_NC"
}

ask_step_continue() {
  if pm_is_auto; then printf 'y'; return 0; fi
  local raw norm
  printf '\n%b▶ Ready to start this step? (y=yes / s=skip / q=quit): %b' "$PM_YELLOW" "$PM_NC"
  IFS= read -r raw
  norm=$(to_lower "$raw")
  printf '%s' "$norm"
}

run_step() {
  local step="$1" title="$2" script_path="$3"
  if [ "$step" -lt "$START_STEP" ]; then return; fi

  step_header "$step" "$TOTAL_STEPS" "$title"
  progress_bar "$step" "$TOTAL_STEPS"

  local choice
  choice=$(ask_step_continue)
  case "$choice" in
    y|yes)
      bash "$script_path"
      ;;
    s|skip)
      printf '%b  ⏭  Skipped. You can run this step later.%b\n\n' "$PM_DIM" "$PM_NC"
      printf -- '- **SKIPPED:** Step %s (%s) — run `bash %s` to complete.\n' \
        "$step" "$title" "$script_path" >> "$PM_OUTPUT_DIR/skipped-steps.md"
      ;;
    q|quit)
      printf '\n%b  Session paused. Resume anytime with:%b\n' "$PM_YELLOW" "$PM_NC"
      printf '%b  bash <SKILL_DIR>/pm-workflow/scripts/run-all.sh --skip-to %s%b\n\n' "$PM_CYAN" "$step" "$PM_NC"
      exit 0
      ;;
    *)
      printf '%b  Invalid choice. Skipping step %s.%b\n' "$PM_RED" "$step" "$PM_NC"
      ;;
  esac
}

# ── Run all phases ────────────────────────────────────────────────────────────
run_step 1 "Project Planning" "$SKILLS_ROOT/pm-planning/scripts/planning.sh"
run_step 2 "Status Tracking & Reporting" "$SKILLS_ROOT/pm-tracking/scripts/tracking.sh"
run_step 3 "Risk Management" "$SKILLS_ROOT/pm-risk/scripts/risk.sh"
run_step 4 "Communication & Stakeholder Management" "$SKILLS_ROOT/pm-communication/scripts/communication.sh"
run_step 5 "Change Request Tracking" "$SKILLS_ROOT/pm-change-management/scripts/change.sh"

# ── Compile final document ────────────────────────────────────────────────────
compile_final_doc() {
  local final_file="$PM_OUTPUT_DIR/PM-FINAL.md"
  local f
  {
    echo "# Project Management Deliverable"
    echo ""
    echo "> Auto-compiled from PM workflow — $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "---"
    echo ""
    for f in \
      "$PM_OUTPUT_DIR/01-project-plan.md" \
      "$PM_OUTPUT_DIR/02-status-report.md" \
      "$PM_OUTPUT_DIR/03-risk-register.md" \
      "$PM_OUTPUT_DIR/04-communication-plan.md" \
      "$PM_OUTPUT_DIR/05-change-log.md" \
      "$PM_OUTPUT_DIR/06-pm-debts.md"; do
      if [ -f "$f" ]; then
        echo ""
        cat "$f"
        echo ""
        echo "---"
      fi
    done
  } > "$final_file"
  pm_success_rule "Compiled PM-FINAL.md"
}

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n'
pm_banner "Project Management Workflow Complete"

if [ -f "$PM_OUTPUT_DIR/01-project-plan.md" ] || \
   [ -f "$PM_OUTPUT_DIR/02-status-report.md" ] || \
   [ -f "$PM_OUTPUT_DIR/03-risk-register.md" ] || \
   [ -f "$PM_OUTPUT_DIR/04-communication-plan.md" ] || \
   [ -f "$PM_OUTPUT_DIR/05-change-log.md" ]; then

  compile_final_doc

  printf '\n%bAll deliverables:' "$PM_CYAN"
  for f in "$PM_OUTPUT_DIR"/*.md; do
    if [ -f "$f" ]; then
      printf '\n  ✓ %s' "$(basename "$f")"
    fi
  done
  printf '%b\n\n' "$PM_NC"
fi

if [ -f "$PM_OUTPUT_DIR/skipped-steps.md" ]; then
  printf '\n%bSkipped steps — complete them later:%b\n' "$PM_YELLOW" "$PM_NC"
  cat "$PM_OUTPUT_DIR/skipped-steps.md"
fi

DEBT_COUNT=$(pm_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '\n%b⚠ %d open PM debt(s) — see %s%b\n' \
    "$PM_YELLOW" "$DEBT_COUNT" "$PM_DEBT_FILE" "$PM_NC"
fi

printf '\n%b✓ Workflow complete. Your project management setup is ready.%b\n\n' "$PM_GREEN" "$PM_NC"
