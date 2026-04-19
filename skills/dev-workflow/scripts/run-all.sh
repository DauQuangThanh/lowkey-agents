#!/bin/bash
# =============================================================================
# run-all.sh — Developer Workflow Orchestrator
# Runs all four Developer phases in sequence with confirmations between each.
# Phases: Design → Coding → Unit Test → Validation
# =============================================================================

# Step 1: parse --auto / --answers flags
while [ $# -gt 0 ]; do
  case "$1" in
    --auto)       DEV_AUTO=1; export DEV_AUTO; shift ;;
    --answers)    DEV_ANSWERS="${2:-}"; export DEV_ANSWERS; shift 2 ;;
    --answers=*)  DEV_ANSWERS="${1#--answers=}"; export DEV_ANSWERS; shift ;;
    *)            shift ;;
  esac
done


set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESIGN_SCRIPT="$SKILLS_ROOT/dev-design/scripts/design.sh"
CODING_SCRIPT="$SKILLS_ROOT/dev-coding/scripts/coding.sh"
UNIT_TEST_SCRIPT="$SKILLS_ROOT/dev-unit-test/scripts/unit-test.sh"
VALIDATION_SCRIPT="$SKILLS_ROOT/dev-validation/scripts/validate.sh"

# Shared colors
DEV_ORANGE='\033[0;33m'
DEV_GREEN='\033[0;32m'
DEV_YELLOW='\033[1;33m'
DEV_RED='\033[0;31m'
DEV_BOLD='\033[1m'
DEV_DIM='\033[2m'
DEV_NC='\033[0m'

banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$DEV_ORANGE$DEV_BOLD" "$DEV_NC"
  printf '%b║  %-56s║%b\n' "$DEV_ORANGE$DEV_BOLD" "$1" "$DEV_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$DEV_ORANGE$DEV_BOLD" "$DEV_NC"
  printf '\n'
}

ask_continue() {
  local prompt="$1"
  # Auto mode: always advance to the next phase.
  case "${DEV_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
  esac
  while true; do
    printf '%b▶ %s (y/n/s/q): %b' "$DEV_YELLOW" "$prompt" "$DEV_NC"
    read -r answer
    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      s)     return 2 ;;  # skip
      q)     printf '%b  Exiting workflow.%b\n\n' "$DEV_RED" "$DEV_NC"; exit 0 ;;
      *)     printf '%b  Please enter y, n, s, or q.%b\n' "$DEV_RED" "$DEV_NC" ;;
    esac
  done
}

banner "🚀  Developer Workflow — Complete Design & Implementation Spec"
printf '%b  Four phases: Design → Coding → Unit Test → Validation%b\n' "$DEV_DIM" "$DEV_NC"
printf '%b  Run individual skills to focus on one phase.%b\n\n' "$DEV_DIM" "$DEV_NC"

# ── Phase 1: Detailed Design ─────────────────────────────────────────────────
banner "📐  PHASE 1 — Detailed Design"
bash "$DESIGN_SCRIPT"
ask_continue "Proceed to Phase 2 (Coding Standards)?"
phase2_result=$?
if [ $phase2_result -eq 2 ]; then
  printf '%b  Skipping Phase 2.%b\n' "$DEV_YELLOW" "$DEV_NC"
  phase2_skip=1
elif [ $phase2_result -ne 0 ]; then
  printf '%b  Exiting after Phase 1.%b\n' "$DEV_YELLOW" "$DEV_NC"
  exit 0
fi

# ── Phase 2: Coding Standards & Implementation Plan ──────────────────────────
if [ "${phase2_skip:-0}" -eq 0 ]; then
  banner "🛠  PHASE 2 — Coding Standards & Implementation Plan"
  bash "$CODING_SCRIPT"
  ask_continue "Proceed to Phase 3 (Unit Test Strategy)?"
  phase3_result=$?
  if [ $phase3_result -eq 2 ]; then
    printf '%b  Skipping Phase 3.%b\n' "$DEV_YELLOW" "$DEV_NC"
    phase3_skip=1
  elif [ $phase3_result -ne 0 ]; then
    printf '%b  Exiting after Phase 2.%b\n' "$DEV_YELLOW" "$DEV_NC"
    exit 0
  fi
fi

# ── Phase 3: Unit Test Strategy ──────────────────────────────────────────────
if [ "${phase3_skip:-0}" -eq 0 ]; then
  banner "🧪  PHASE 3 — Unit Test Strategy"
  bash "$UNIT_TEST_SCRIPT"
  ask_continue "Proceed to Phase 4 (Validation & Sign-Off)?"
  phase4_result=$?
  if [ $phase4_result -eq 2 ]; then
    printf '%b  Skipping Phase 4 (validation).%b\n' "$DEV_YELLOW" "$DEV_NC"
    phase4_skip=1
  elif [ $phase4_result -ne 0 ]; then
    printf '%b  Exiting after Phase 3.%b\n' "$DEV_YELLOW" "$DEV_NC"
    exit 0
  fi
fi

# ── Phase 4: Validation & Sign-Off ───────────────────────────────────────────
if [ "${phase4_skip:-0}" -eq 0 ]; then
  banner "✅  PHASE 4 — Design & Code Quality Validation"
  bash "$VALIDATION_SCRIPT"
fi

banner "🎉  Workflow Complete!"
printf '%b  All outputs are in: dev-output/%b\n' "$DEV_GREEN" "$DEV_NC"
printf '%b  Review DEVELOPER-FINAL.md for sign-off document.%b\n\n' "$DEV_GREEN" "$DEV_NC"
