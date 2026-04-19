#!/bin/bash
# =============================================================================
# run-all.sh — Architect Full Workflow Runner
# Runs all 6 architect phases in sequence and compiles ARCHITECTURE-FINAL.md.
# Usage: bash <SKILL_DIR>/architecture-workflow/scripts/run-all.sh [--skip-to N]
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
arch_parse_flags "$@"


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TOTAL_STEPS=6
START_STEP=1

# ── Parse args ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--skip-to" ] && [ -n "${2:-}" ]; then
  START_STEP="$2"
  arch_dim "  Skipping to step $START_STEP..."
fi

step_header() {
  local step="$1" total="$2" title="$3"
  printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$ARCH_CYAN$ARCH_BOLD" "$ARCH_NC"
  printf '%b  STEP %s of %s — %s%b\n' "$ARCH_CYAN$ARCH_BOLD" "$step" "$total" "$title" "$ARCH_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$ARCH_CYAN$ARCH_BOLD" "$ARCH_NC"
}

progress_bar() {
  local current="$1" total="$2"
  local filled=$(( current * 20 / total ))
  local empty=$(( 20 - filled ))
  local bar="" i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  printf '%b  Progress: [%s] %s/%s%b\n' "$ARCH_GREEN" "$bar" "$current" "$total" "$ARCH_NC"
}

ask_step_continue() {
  if arch_is_auto; then printf 'y'; return 0; fi
  local raw norm
  printf '\n%b▶ Ready to start this step? (y=yes / s=skip / q=quit): %b' "$ARCH_YELLOW" "$ARCH_NC"
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
      printf '%b  ⏭  Skipped. You can run this step later.%b\n\n' "$ARCH_DIM" "$ARCH_NC"
      printf -- '- **SKIPPED:** Step %s (%s) — run `bash %s` to complete.\n' \
        "$step" "$title" "$script_path" >> "$ARCH_OUTPUT_DIR/skipped-steps.md"
      ;;
    q|quit)
      printf '\n%b  Session paused. Resume anytime with:%b\n' "$ARCH_YELLOW" "$ARCH_NC"
      printf '%b  bash <SKILL_DIR>/architecture-workflow/scripts/run-all.sh --skip-to %s%b\n\n' "$ARCH_CYAN" "$step" "$ARCH_NC"
      exit 0
      ;;
    *)
      printf '%b  Invalid choice. Skipping step %s.%b\n' "$ARCH_RED" "$step" "$ARCH_NC"
      ;;
  esac
}

# ── Startup ───────────────────────────────────────────────────────────────────
arch_banner "🏛  Architect — Full Architecture Workflow"

# Check BA handover
BA_FINAL="$ARCH_BA_INPUT_DIR/REQUIREMENTS-FINAL.md"
if [ -f "$BA_FINAL" ]; then
  printf '%b  ✔ Found BA requirements: %s%b\n' "$ARCH_GREEN" "$BA_FINAL" "$ARCH_NC"
  arch_dim "  Confirm this as the basis for the architecture before continuing."
else
  printf '%b  ⚠ No BA requirements found at: %s%b\n' "$ARCH_YELLOW" "$BA_FINAL" "$ARCH_NC"
  arch_dim "  For best results, run the business-analyst first."
fi
echo ""

# Handle existing output
if [ -d "$ARCH_OUTPUT_DIR" ] && [ -n "$(ls -A "$ARCH_OUTPUT_DIR" 2>/dev/null)" ]; then
  if arch_is_auto; then
    resume_choice="1"
    arch_dim "  Auto mode: continuing from existing output in $ARCH_OUTPUT_DIR"
  else
    printf '%b⚠  Found existing architect output in: %s%b\n\n' "$ARCH_YELLOW" "$ARCH_OUTPUT_DIR" "$ARCH_NC"
    echo "  1) Continue from where I left off"
    echo "  2) Start fresh (existing files will be archived)"
    echo ""
    printf '%b▶ Your choice (1 or 2): %b' "$ARCH_YELLOW" "$ARCH_NC"
    IFS= read -r resume_choice
  fi
  if [ "$resume_choice" = "2" ]; then
    archive_dir="${ARCH_OUTPUT_DIR}_archive_${TIMESTAMP}"
    mv "$ARCH_OUTPUT_DIR" "$archive_dir"
    arch_dim "  Archived to: $archive_dir"
    mkdir -p "$ARCH_OUTPUT_DIR"
  fi
else
  mkdir -p "$ARCH_OUTPUT_DIR"
fi

arch_dim "  This workflow has $TOTAL_STEPS steps. You can skip any step and return later."
arch_dim "  All outputs are saved automatically to: $ARCH_OUTPUT_DIR/"
echo ""

run_step 1 "Architecture Intake"          "$SKILLS_ROOT/architecture-intake/scripts/intake.sh"
run_step 2 "Technology Research"          "$SKILLS_ROOT/technology-research/scripts/research.sh"
run_step 3 "ADR Building"                 "$SKILLS_ROOT/adr-builder/scripts/new-adr.sh"
run_step 4 "C4 Architecture Documentation" "$SKILLS_ROOT/c4-architecture/scripts/build-c4.sh"
run_step 5 "Risk & Trade-off Register"    "$SKILLS_ROOT/risk-tradeoff-register/scripts/register.sh"
run_step 6 "Validation & Sign-Off"        "$SKILLS_ROOT/architecture-validation/scripts/validate.sh"

printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$ARCH_BLUE$ARCH_BOLD" "$ARCH_NC"
printf '%b  🎉 All architect steps complete.%b\n' "$ARCH_BLUE$ARCH_BOLD" "$ARCH_NC"
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$ARCH_BLUE$ARCH_BOLD" "$ARCH_NC"

printf '%b  Your architecture documents are in:%b\n' "$ARCH_GREEN$ARCH_BOLD" "$ARCH_NC"
printf '%b  %s/%b\n\n' "$ARCH_CYAN" "$ARCH_OUTPUT_DIR" "$ARCH_NC"
arch_dim "  📄 Files generated:"
ls "$ARCH_OUTPUT_DIR"/*.md 2>/dev/null | while read -r f; do
  arch_dim "     • $(basename "$f")"
done
if [ -d "$ARCH_ADR_DIR" ]; then
  for f in "$ARCH_ADR_DIR"/*.md; do
    [ -f "$f" ] || continue
    arch_dim "     • adr/$(basename "$f")"
  done
fi
if [ -d "$ARCH_DIAGRAMS_DIR" ]; then
  for f in "$ARCH_DIAGRAMS_DIR"/*.mmd "$ARCH_DIAGRAMS_DIR"/*.dsl; do
    [ -f "$f" ] || continue
    arch_dim "     • diagrams/$(basename "$f")"
  done
fi
printf '\n%b  Share arch-output/ARCHITECTURE-FINAL.md with your team.%b\n\n' "$ARCH_GREEN" "$ARCH_NC"
