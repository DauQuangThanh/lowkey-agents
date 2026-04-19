#!/bin/bash
# =============================================================================
# run-all.sh — UX Workflow Orchestrator
# Executes all 4 UX phases in sequence.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common helpers from ux-research
source "$SKILLS_DIR/ux-research/scripts/_common.sh"

# Step 1: parse --auto / --answers flags
ux_parse_flags "$@"


ux_banner "🚀  UX Designer Workflow — Complete"
ux_dim "  Running all phases in sequence. This will take 30–45 minutes."
echo ""

# ── Phase 1: User Research ─────────────────────────────────────────────────────
echo ""
ux_dim "  ▶ Starting Phase 1: User Research & Personas..."
echo ""
if bash "$SKILLS_DIR/ux-research/scripts/research.sh"; then
  ux_success_rule "✅ Phase 1 Complete"
else
  printf '%b❌ Phase 1 failed. Aborting workflow.%b\n' "$UX_RED" "$UX_NC"
  exit 1
fi

# ── Phase 2: Wireframes ────────────────────────────────────────────────────────
echo ""
ux_dim "  ▶ Starting Phase 2: Wireframes & Information Architecture..."
echo ""
if bash "$SKILLS_DIR/ux-wireframe/scripts/wireframe.sh"; then
  ux_success_rule "✅ Phase 2 Complete"
else
  printf '%b❌ Phase 2 failed. Aborting workflow.%b\n' "$UX_RED" "$UX_NC"
  exit 1
fi

# ── Phase 3: Mockups ───────────────────────────────────────────────────────────
echo ""
ux_dim "  ▶ Starting Phase 3: Mockup & Prototype Specification..."
echo ""
if bash "$SKILLS_DIR/ux-prototype/scripts/prototype.sh"; then
  ux_success_rule "✅ Phase 3 Complete"
else
  printf '%b❌ Phase 3 failed. Aborting workflow.%b\n' "$UX_RED" "$UX_NC"
  exit 1
fi

# ── Phase 4: Validation ────────────────────────────────────────────────────────
echo ""
ux_dim "  ▶ Starting Phase 4: UX Review & Validation..."
echo ""
if bash "$SKILLS_DIR/ux-validation/scripts/validate.sh"; then
  ux_success_rule "✅ Phase 4 Complete"
else
  printf '%b❌ Phase 4 failed. Aborting workflow.%b\n' "$UX_RED" "$UX_NC"
  exit 1
fi

# ── Final Summary ──────────────────────────────────────────────────────────────
echo ""
ux_banner "🎉  UX Workflow Complete!"
ux_dim "  All phases executed successfully."
printf '%b  Deliverables saved to: %s%b\n' "$UX_GREEN" "$UX_OUTPUT_DIR" "$UX_NC"
printf '%b  Final package: %s/UX-DESIGNER-FINAL.md%b\n' "$UX_GREEN" "$UX_OUTPUT_DIR" "$UX_NC"
echo ""
