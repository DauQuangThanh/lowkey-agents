#!/bin/bash
# =============================================================================
# run-all.sh — Bug-Fixer orchestrator.
# Runs the 5 bug-fixer phases in sequence.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers / --branch / --dry-run flags
bf_parse_flags "$@"

TRIAGE_SCRIPT="$SKILLS_ROOT/bf-triage/scripts/triage.sh"
FIX_SCRIPT="$SKILLS_ROOT/bf-fix/scripts/fix.sh"
REGRESSION_SCRIPT="$SKILLS_ROOT/bf-regression/scripts/regression.sh"
REGISTER_SCRIPT="$SKILLS_ROOT/bf-change-register/scripts/register.sh"
VALIDATE_SCRIPT="$SKILLS_ROOT/bf-validation/scripts/validate.sh"

bf_banner "🐛 Bug-Fixer — Full Workflow"

cat <<'EOF'

Runs 5 phases in sequence:
  1. Triage       (bf-triage)       — prioritise bugs/CQDEBT/CSDEBT
  2. Fix          (bf-fix)          — apply patches on a fix branch
  3. Regression   (bf-regression)   — regression test stubs per fix
  4. Register     (bf-change-register) — upstream/downstream impact
  5. Validation   (bf-validation)   — checks + BF-FINAL.md

Safety:
  - Requires a clean git working tree (or --dry-run).
  - Auto mode requires --branch NAME.
  - Never pushes; branches are handed off for PR.

EOF

for s in "$TRIAGE_SCRIPT" "$FIX_SCRIPT" "$REGRESSION_SCRIPT" "$REGISTER_SCRIPT" "$VALIDATE_SCRIPT"; do
  if [ ! -f "$s" ]; then
    printf '%bERROR:%b Phase script not found: %s%b\n' "$BF_RED" "$BF_NC" "$s" "$BF_NC" >&2
    exit 1
  fi
done

printf '%b✓ All phase scripts present%b\n\n' "$BF_GREEN" "$BF_NC"

printf '%b▶ Phase 1: Triage%b\n\n' "$BF_BOLD" "$BF_NC"
bash "$TRIAGE_SCRIPT"

printf '\n%b▶ Phase 2: Fix%b\n\n' "$BF_BOLD" "$BF_NC"
bash "$FIX_SCRIPT"

printf '\n%b▶ Phase 3: Regression tests%b\n\n' "$BF_BOLD" "$BF_NC"
bash "$REGRESSION_SCRIPT"

printf '\n%b▶ Phase 4: Change register%b\n\n' "$BF_BOLD" "$BF_NC"
bash "$REGISTER_SCRIPT"

printf '\n%b▶ Phase 5: Validation%b\n\n' "$BF_BOLD" "$BF_NC"
bash "$VALIDATE_SCRIPT"

bf_success_rule "🎉 Bug-Fixer workflow complete"
printf '\nAll outputs in: %s\n\n' "$BF_OUTPUT_DIR"
