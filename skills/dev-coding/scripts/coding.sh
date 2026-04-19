#!/bin/bash
# =============================================================================
# coding.sh — Phase 2: Coding Standards & Implementation Plan
# Establishes naming conventions, file structure, dependency management,
# branching strategy, code review criteria, and implementation sequencing.
# Writes output to $DEV_OUTPUT_DIR/02-coding-plan.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
dev_parse_flags "$@"


OUTPUT_FILE="$DEV_OUTPUT_DIR/02-coding-plan.md"
AREA="Coding Standards"

start_ddebts=$(dev_current_ddebt_count)

dev_banner "🛠  Phase 2 of 4 — Coding Standards & Implementation Plan"
dev_dim "  Establish the conventions and sequencing that will keep code"
dev_dim "  consistent and the team unblocked during implementation."
echo ""

# ── Question 1: Naming Conventions ────────────────────────────────────────────
printf '%b%b── Q1: Naming Conventions ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  PascalCase vs camelCase for types/functions?"
dev_dim "  Prefixes for interfaces? Suffixes for implementations?"
naming=$(dev_ask "  Describe your naming conventions (e.g., 'Classes: PascalCase, methods: camelCase, interfaces: IService'):")
if [ -z "$naming" ]; then
  naming="TBD — naming conventions not yet decided"
  dev_add_ddebt "$AREA" "Naming conventions incomplete" \
    "No naming conventions established" \
    "Inconsistent naming across the codebase will make it harder to navigate"
fi
echo ""

# ── Question 2: File & Folder Structure ──────────────────────────────────────
printf '%b%b── Q2: File & Folder Structure ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  By layer (controllers/, services/, data/)?"
dev_dim "  By feature (orders/, payments/)? Mixed? Maximum nesting depth?"
structure=$(dev_ask "  Describe your folder organization:")
if [ -z "$structure" ]; then
  structure="TBD — folder structure not yet decided"
  dev_add_ddebt "$AREA" "Folder structure undefined" \
    "No file/folder organization pattern decided" \
    "Team will create ad-hoc file layouts; hard to onboard and navigate"
fi
echo ""

# ── Question 3: Dependency Management ────────────────────────────────────────
printf '%b%b── Q3: Dependency Management ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Package manager (npm, pip, maven, cargo)?"
dev_dim "  Version pinning (exact, minor, major)? Monorepo or separate?"
deps=$(dev_ask "  Describe dependency management strategy:")
if [ -z "$deps" ]; then
  deps="TBD — dependency strategy not yet decided"
  dev_add_ddebt "$AREA" "Dependency management unclear" \
    "No dependency management or versioning strategy defined" \
    "Unexpected breaking changes or version conflicts in CI/CD"
fi
echo ""

# ── Question 4: Branching & Release Strategy ─────────────────────────────────
printf '%b%b── Q4: Branching & Release Strategy ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Trunk-based dev with feature flags? GitFlow (develop/main)?"
dev_dim "  Release cadence (continuous, weekly, sprint-based)?"
branching=$(dev_ask "  Describe your branching and release strategy:")
if [ -z "$branching" ]; then
  branching="TBD — branching strategy not yet decided"
  dev_add_ddebt "$AREA" "Branching strategy undefined" \
    "No branching or release strategy agreed" \
    "Conflict-prone merges and unclear release process"
fi
echo ""

# ── Question 5: Code Review Checklist ────────────────────────────────────────
printf '%b%b── Q5: Code Review Checklist ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  What must every PR satisfy? (tests pass, coverage > 80%,"
dev_dim "  no secrets, API docs updated, no new warnings)"
dev_dim "  Who approves? Turnaround time?"
code_review=$(dev_ask "  Describe your code review criteria and process:")
if [ -z "$code_review" ]; then
  code_review="TBD — code review criteria not yet defined"
  dev_add_ddebt "$AREA" "Code review criteria missing" \
    "No code review checklist or criteria established" \
    "Inconsistent review quality and unpredictable merge delays"
fi
echo ""

# ── Question 6: Implementation Order / Priority ───────────────────────────────
printf '%b%b── Q6: Implementation Order ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Given the modules and APIs, what's the logical build sequence?"
dev_dim "  Which modules are blockers? Which are independent?"
impl_order=$(dev_ask "  Describe the implementation sequence and priorities:")
if [ -z "$impl_order" ]; then
  impl_order="TBD — implementation order to be determined"
  dev_add_ddebt "$AREA" "Implementation order not planned" \
    "No implementation sequence or dependency tracking" \
    "Teams will work in parallel on blocked features"
fi
echo ""

# ── Question 7: Tech Debt Management ──────────────────────────────────────────
printf '%b%b── Q7: Tech Debt Management ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  How to track and prioritize tech debt items (DDEBT)?"
dev_dim "  Refactor in-sprint, or dedicated 'debt sprints'?"
tech_debt=$(dev_ask "  Describe your tech debt management approach:")
if [ -z "$tech_debt" ]; then
  tech_debt="TBD — tech debt policy not yet established"
fi
echo ""

# ── Question 8: Testing in the Build ──────────────────────────────────────────
printf '%b%b── Q8: Testing in the Build ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Unit tests must pass before commit? Integration tests in CI/CD?"
dev_dim "  Performance tests? Compatibility matrix?"
testing=$(dev_ask "  Describe testing gates and CI/CD integration:")
if [ -z "$testing" ]; then
  testing="TBD — testing strategy in build not yet defined"
  dev_add_ddebt "$AREA" "Testing in build undefined" \
    "No testing gates, coverage requirements, or CI/CD policy" \
    "Broken code reaching main; slow, unreliable builds"
fi
echo ""

# ── Confirmation ─────────────────────────────────────────────────────────────
printf '\n%b%b── Confirm All Answers ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
printf '\n%b  Naming:%b %s\n' "$DEV_DIM" "$DEV_NC" "${naming:0:60}..."
printf '%b  Structure:%b %s\n' "$DEV_DIM" "$DEV_NC" "${structure:0:60}..."
printf '%b  Dependencies:%b %s\n' "$DEV_DIM" "$DEV_NC" "${deps:0:60}..."
printf '%b  Branching:%b %s\n' "$DEV_DIM" "$DEV_NC" "${branching:0:60}..."
printf '%b  Code Review:%b %s\n' "$DEV_DIM" "$DEV_NC" "${code_review:0:60}..."
printf '%b  Impl Order:%b %s\n' "$DEV_DIM" "$DEV_NC" "${impl_order:0:60}..."
printf '%b  Tech Debt:%b %s\n' "$DEV_DIM" "$DEV_NC" "${tech_debt:0:60}..."
printf '%b  Testing:%b %s\n\n' "$DEV_DIM" "$DEV_NC" "${testing:0:60}..."

if dev_is_auto; then
  ready="yes"
else
  ready=$(dev_ask_yn "Write these to the coding plan document?")
fi
if [ "$ready" = "no" ]; then
  printf '%b  Cancelled. No changes made.%b\n\n' "$DEV_YELLOW" "$DEV_NC"
  exit 0
fi

# ── Write output file ────────────────────────────────────────────────────────
{
  echo "# Coding Standards & Implementation Plan — [Project Name]"
  echo ""
  echo "**Date:** $(date '+%Y-%m-%d')"
  echo "**Developer:** [Name]"
  echo "**Design Source:** dev-output/01-detailed-design.md"
  echo ""
  echo "## Overview"
  echo ""
  echo "This document establishes the coding conventions and implementation"
  echo "sequencing that will guide the team during development. It ensures"
  echo "consistency, reduces cognitive load, and makes code reviews faster."
  echo ""
  echo "---"
  echo ""
  echo "## Naming Conventions"
  echo ""
  echo "**Convention (Q1):**"
  echo ""
  echo "${naming}"
  echo ""
  echo "---"
  echo ""
  echo "## File & Folder Structure"
  echo ""
  echo "**Organization (Q2):**"
  echo ""
  echo "${structure}"
  echo ""
  echo "---"
  echo ""
  echo "## Dependency Management"
  echo ""
  echo "**Strategy (Q3):**"
  echo ""
  echo "${deps}"
  echo ""
  echo "---"
  echo ""
  echo "## Branching & Release Strategy"
  echo ""
  echo "**Strategy (Q4):**"
  echo ""
  echo "${branching}"
  echo ""
  echo "---"
  echo ""
  echo "## Code Review Checklist"
  echo ""
  echo "**Criteria (Q5):**"
  echo ""
  echo "${code_review}"
  echo ""
  echo "---"
  echo ""
  echo "## Implementation Order & Priorities"
  echo ""
  echo "**Sequence (Q6):**"
  echo ""
  echo "${impl_order}"
  echo ""
  echo "---"
  echo ""
  echo "## Tech Debt Management"
  echo ""
  echo "**Policy (Q7):**"
  echo ""
  echo "${tech_debt}"
  echo ""
  echo "---"
  echo ""
  echo "## Testing in the Build"
  echo ""
  echo "**Gates & CI/CD (Q8):**"
  echo ""
  echo "${testing}"
  echo ""
  echo "---"
  echo ""
  echo "## Known Unknowns / Design Debts"
  echo ""
  echo "_See 05-design-debts.md_"
  echo ""
} > "$OUTPUT_FILE"

printf '%b  ✅ Saved: %s%b\n\n' "$DEV_GREEN" "$OUTPUT_FILE" "$DEV_NC"

end_ddebts=$(dev_current_ddebt_count)
new_ddebts=$((end_ddebts - start_ddebts))

dev_success_rule "✅ Coding Standards Complete"
printf '%b  Output:  %s%b\n' "$DEV_GREEN" "$OUTPUT_FILE" "$DEV_NC"
if [ "$new_ddebts" -gt 0 ]; then
  printf '%b  ⚠  %d design debt(s) logged to: %s%b\n' "$DEV_YELLOW" "$new_ddebts" "$DEV_DEBT_FILE" "$DEV_NC"
fi
echo ""
