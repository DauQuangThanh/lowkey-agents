#!/bin/bash
# =============================================================================
# run-all.sh — Business Analyst Full Workflow Runner
# Runs all 7 BA phases in sequence and compiles the final document.
# Usage: bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh [--skip-to N]
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
ba_parse_flags "$@"


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TOTAL_STEPS=7
START_STEP=1

# ── Parse args ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--skip-to" ] && [ -n "${2:-}" ]; then
  START_STEP="$2"
  ba_dim "  Skipping to step $START_STEP..."
fi

# ── Step runner ───────────────────────────────────────────────────────────────
step_header() {
  local step="$1" total="$2" title="$3"
  printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BA_CYAN$BA_BOLD" "$BA_NC"
  printf '%b  STEP %s of %s — %s%b\n' "$BA_CYAN$BA_BOLD" "$step" "$total" "$title" "$BA_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$BA_CYAN$BA_BOLD" "$BA_NC"
}

progress_bar() {
  local current="$1" total="$2"
  local filled=$(( current * 20 / total ))
  local empty=$(( 20 - filled ))
  local bar="" i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  printf '%b  Progress: [%s] %s/%s%b\n' "$BA_GREEN" "$bar" "$current" "$total" "$BA_NC"
}

ask_step_continue() {
  if ba_is_auto; then printf 'y'; return 0; fi
  local raw norm
  printf '\n%b▶ Ready to start this step? (y=yes / s=skip / q=quit): %b' "$BA_YELLOW" "$BA_NC"
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
      printf '%b  ⏭  Skipped. You can run this step later.%b\n\n' "$BA_DIM" "$BA_NC"
      printf -- '- **SKIPPED:** Step %s (%s) — run `bash %s` to complete.\n' \
        "$step" "$title" "$script_path" >> "$BA_OUTPUT_DIR/skipped-steps.md"
      ;;
    q|quit)
      printf '\n%b  Session paused. Resume anytime with:%b\n' "$BA_YELLOW" "$BA_NC"
      printf '%b  bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh --skip-to %s%b\n\n' "$BA_CYAN" "$step" "$BA_NC"
      exit 0
      ;;
    *)
      printf '%b  Invalid choice. Skipping step %s.%b\n' "$BA_RED" "$step" "$BA_NC"
      ;;
  esac
}

compile_final_doc() {
  local final_file="$BA_OUTPUT_DIR/REQUIREMENTS-FINAL.md"
  local f
  {
    echo "# Requirements Document"
    echo ""
    echo "> Auto-compiled from BA workflow — $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "---"
    echo ""
    for f in \
      "$BA_OUTPUT_DIR/01-project-intake.md" \
      "$BA_OUTPUT_DIR/02-stakeholders.md" \
      "$BA_OUTPUT_DIR/03-requirements.md" \
      "$BA_OUTPUT_DIR/04-user-stories.md" \
      "$BA_OUTPUT_DIR/05-nfr.md" \
      "$BA_OUTPUT_DIR/06-requirement-debts.md" \
      "$BA_OUTPUT_DIR/07-validation-report.md"; do
      if [ -f "$f" ]; then
        echo ""
        cat "$f"
        echo ""
        echo "---"
        echo ""
      fi
    done
  } > "$final_file"
  printf '%b  ✅ Final document compiled: %s%b\n' "$BA_GREEN$BA_BOLD" "$final_file" "$BA_NC"
}

# ── Startup ───────────────────────────────────────────────────────────────────
ba_banner "🗂  Business Analyst — Full Requirements Workflow"

# Handle existing output
if [ -d "$BA_OUTPUT_DIR" ] && [ -n "$(ls -A "$BA_OUTPUT_DIR" 2>/dev/null)" ]; then
  if ba_is_auto; then
    resume_choice="1"
    ba_dim "  Auto mode: continuing from existing output in $BA_OUTPUT_DIR"
  else
    printf '%b⚠  Found existing BA output files in: %s%b\n\n' "$BA_YELLOW" "$BA_OUTPUT_DIR" "$BA_NC"
    echo "  1) Continue from where I left off"
    echo "  2) Start fresh (existing files will be archived)"
    echo ""
    printf '%b▶ Your choice (1 or 2): %b' "$BA_YELLOW" "$BA_NC"
    IFS= read -r resume_choice
  fi
  if [ "$resume_choice" = "2" ]; then
    archive_dir="${BA_OUTPUT_DIR}_archive_${TIMESTAMP}"
    mv "$BA_OUTPUT_DIR" "$archive_dir"
    ba_dim "  Archived to: $archive_dir"
    mkdir -p "$BA_OUTPUT_DIR"
  fi
else
  mkdir -p "$BA_OUTPUT_DIR"
fi

ba_dim "  This workflow has $TOTAL_STEPS steps. You can skip any step and return later."
ba_dim "  All answers are saved automatically to: $BA_OUTPUT_DIR/"
echo ""

run_step 1 "Project Intake"              "$SKILLS_ROOT/project-intake/scripts/intake.sh"
run_step 2 "Stakeholder Mapping"         "$SKILLS_ROOT/stakeholder-mapping/scripts/map-stakeholders.sh"
run_step 3 "Requirements Elicitation"    "$SKILLS_ROOT/requirements-elicitation/scripts/elicit-requirements.sh"
run_step 4 "User Story Building"         "$SKILLS_ROOT/user-story-builder/scripts/build-stories.sh"
run_step 5 "Non-Functional Requirements" "$SKILLS_ROOT/nfr-checklist/scripts/nfr-checklist.sh"
run_step 6 "Requirement Debt Review"     "$SKILLS_ROOT/requirement-debt-tracker/scripts/debt-tracker.sh"
run_step 7 "Validation & Sign-Off"       "$SKILLS_ROOT/requirements-validation/scripts/validate-requirements.sh"

# ── Compile final document ────────────────────────────────────────────────────
printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BA_BLUE$BA_BOLD" "$BA_NC"
printf '%b  🎉 All steps complete! Compiling final requirements document...%b\n' "$BA_BLUE$BA_BOLD" "$BA_NC"
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$BA_BLUE$BA_BOLD" "$BA_NC"

compile_final_doc

printf '\n%b  Your requirements documents are in:%b\n' "$BA_GREEN$BA_BOLD" "$BA_NC"
printf '%b  %s/%b\n\n' "$BA_CYAN" "$BA_OUTPUT_DIR" "$BA_NC"
ba_dim "  📄 Files generated:"
ls "$BA_OUTPUT_DIR"/*.md 2>/dev/null | while read -r f; do
  ba_dim "     • $(basename "$f")"
done
printf '\n%b  Thank you! Share ba-output/REQUIREMENTS-FINAL.md with your team.%b\n\n' "$BA_GREEN" "$BA_NC"
