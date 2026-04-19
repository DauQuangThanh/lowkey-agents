#!/bin/bash
# =============================================================================
# run-all.sh — Product Owner Full Workflow Runner
# Runs all 5 PO phases in sequence and compiles the final document.
# Usage: bash <SKILL_DIR>/po-workflow/scripts/run-all.sh [--skip-to N]
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
po_parse_flags "$@"


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TOTAL_STEPS=5
START_STEP=1

# ── Parse args ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--skip-to" ] && [ -n "${2:-}" ]; then
  START_STEP="$2"
  po_dim "  Skipping to step $START_STEP..."
fi

# ── Step runner ───────────────────────────────────────────────────────────────
step_header() {
  local step="$1" total="$2" title="$3"
  printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"
  printf '%b  STEP %s of %s — %s%b\n' "$PO_MAGENTA$PO_BOLD" "$step" "$total" "$title" "$PO_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"
}

progress_bar() {
  local current="$1" total="$2"
  local filled=$(( current * 20 / total ))
  local empty=$(( 20 - filled ))
  local bar="" i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  printf '%b  Progress: [%s] %s/%s%b\n' "$PO_GREEN" "$bar" "$current" "$total" "$PO_NC"
}

ask_step_continue() {
  if po_is_auto; then printf 'y'; return 0; fi
  local raw norm
  printf '\n%b▶ Ready to start this step? (y=yes / s=skip / q=quit): %b' "$PO_YELLOW" "$PO_NC"
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
      printf '%b  ⏭  Skipped. You can run this step later.%b\n\n' "$PO_DIM" "$PO_NC"
      echo "- **SKIPPED:** Step $step ($title) — run \`bash $script_path\` to complete." >> "$PO_OUTPUT_DIR/skipped-steps.md"
      ;;
    q|quit)
      printf '\n%b  Session paused. Resume anytime with:%b\n' "$PO_YELLOW" "$PO_NC"
      printf '%b  bash <SKILL_DIR>/po-workflow/scripts/run-all.sh --skip-to %s%b\n\n' "$PO_CYAN" "$step" "$PO_NC"
      exit 0
      ;;
    *)
      printf '%b  Invalid choice. Skipping step %s.%b\n' "$PO_RED" "$step" "$PO_NC"
      ;;
  esac
}

compile_final_doc() {
  local final_file="$PO_OUTPUT_DIR/PO-FINAL.md"
  local f
  {
    echo "# Product Owner Documentation"
    echo ""
    echo "> Auto-compiled from PO workflow — $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "---"
    echo ""
    for f in \
      "$PO_OUTPUT_DIR/01-product-backlog.md" \
      "$PO_OUTPUT_DIR/02-acceptance-criteria.md" \
      "$PO_OUTPUT_DIR/03-product-roadmap.md" \
      "$PO_OUTPUT_DIR/04-stakeholder-comms.md" \
      "$PO_OUTPUT_DIR/05-sprint-review.md" \
      "$PO_OUTPUT_DIR/06-po-debts.md"; do
      if [ -f "$f" ]; then
        echo ""
        cat "$f"
        echo ""
        echo "---"
        echo ""
      fi
    done
  } > "$final_file"
  printf '%b  ✅ Final document compiled: %s%b\n' "$PO_GREEN$PO_BOLD" "$final_file" "$PO_NC"
}

# ── Startup ───────────────────────────────────────────────────────────────────
po_banner "🎯  Product Owner — Full Workflow"

# Handle existing output
if [ -d "$PO_OUTPUT_DIR" ] && [ -n "$(ls -A "$PO_OUTPUT_DIR" 2>/dev/null)" ]; then
  if po_is_auto; then
    resume_choice="1"
    po_dim "  Auto mode: continuing from existing output in $PO_OUTPUT_DIR"
  else
    printf '%b⚠  Found existing PO output files in: %s%b\n\n' "$PO_YELLOW" "$PO_OUTPUT_DIR" "$PO_NC"
    echo "  1) Continue from where I left off"
    echo "  2) Start fresh (existing files will be archived)"
    echo ""
    printf '%b▶ Your choice (1 or 2): %b' "$PO_YELLOW" "$PO_NC"
    IFS= read -r resume_choice
  fi
  if [ "$resume_choice" = "2" ]; then
    archive_dir="${PO_OUTPUT_DIR}_archive_${TIMESTAMP}"
    mv "$PO_OUTPUT_DIR" "$archive_dir"
    po_dim "  Archived to: $archive_dir"
    mkdir -p "$PO_OUTPUT_DIR"
  fi
else
  mkdir -p "$PO_OUTPUT_DIR"
fi

po_dim "  This workflow has $TOTAL_STEPS steps. You can skip any step and return later."
po_dim "  All answers are saved automatically to: $PO_OUTPUT_DIR/"
echo ""

run_step 1 "Product Backlog Management"  "$SKILLS_ROOT/po-backlog/scripts/backlog.sh"
run_step 2 "Acceptance Criteria"         "$SKILLS_ROOT/po-acceptance/scripts/acceptance.sh"
run_step 3 "Product Roadmap"             "$SKILLS_ROOT/po-roadmap/scripts/roadmap.sh"
run_step 4 "Stakeholder Communication"   "$SKILLS_ROOT/po-stakeholder-comms/scripts/stakeholder-comms.sh"
run_step 5 "Sprint Review Preparation"   "$SKILLS_ROOT/po-sprint-review/scripts/sprint-review.sh"

# ── Compile final document ────────────────────────────────────────────────────
printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"
printf '%b  🎉 All steps complete! Compiling final PO document...%b\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"
printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"

compile_final_doc

printf '\n%b  Your PO documents are in:%b\n' "$PO_GREEN$PO_BOLD" "$PO_NC"
printf '%b  → %s%b\n\n' "$PO_GREEN" "$PO_OUTPUT_DIR" "$PO_NC"

po_success_rule "✅ Workflow Complete"
