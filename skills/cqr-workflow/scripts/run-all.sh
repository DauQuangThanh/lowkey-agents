#!/bin/bash
# =============================================================================
# run-all.sh — Code Quality Reviewer Workflow Orchestrator
#
# Purpose:
#   Runs all 4 phases of the code quality review sequentially:
#   Phase 1: Standards Review
#   Phase 2: Complexity Analysis
#   Phase 3: Pattern & Architecture Review
#   Phase 4: Quality Report & Recommendations
#
# Usage:
#   bash <SKILL_DIR>/cqr-workflow/scripts/run-all.sh
#
# Output:
#   cqr-output/01-standards-review.md
#   cqr-output/02-complexity-report.md
#   cqr-output/03-patterns-review.md
#   cqr-output/04-quality-report.md
#   cqr-output/05-cq-debts.md
#   cqr-output/CQR-FINAL.md
#
# =============================================================================

set -euo pipefail

# Resolve script directory and locate all phase scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Phase script locations
STANDARDS_SCRIPT="$PROJECT_ROOT/cqr-standards/scripts/standards.sh"
COMPLEXITY_SCRIPT="$PROJECT_ROOT/cqr-complexity/scripts/complexity.sh"
PATTERNS_SCRIPT="$PROJECT_ROOT/cqr-patterns/scripts/patterns.sh"
REPORT_SCRIPT="$PROJECT_ROOT/cqr-report/scripts/report.sh"

# Source common helpers from standards skill
source "$PROJECT_ROOT/cqr-standards/scripts/_common.sh"

# Step 1: parse --auto / --answers flags
cqr_parse_flags "$@"


# =============================================================================
# VALIDATION
# =============================================================================

cqr_banner "Code Quality Reviewer — Complete Workflow"

cat << 'EOF'

This workflow will guide you through a comprehensive code quality review:

  Phase 1: Coding Standards Review (8 questions)
  Phase 2: Complexity & Maintainability Analysis (6 questions)
  Phase 3: Design Pattern & Architecture Review (6 questions)
  Phase 4: Quality Report & Recommendations (automated)

Estimated time: 20–30 minutes

EOF

# Verify all phase scripts exist
for script in "$STANDARDS_SCRIPT" "$COMPLEXITY_SCRIPT" "$PATTERNS_SCRIPT" "$REPORT_SCRIPT"; do
  if [ ! -f "$script" ]; then
    printf '%bERROR: Phase script not found: %s%b\n' "$CQR_RED" "$script" "$CQR_NC"
    exit 1
  fi
done

printf '%b✓ All phase scripts found%b\n\n' "$CQR_GREEN" "$CQR_NC"

# =============================================================================
# PHASE 1: STANDARDS REVIEW
# =============================================================================

printf '%bRunning Phase 1 (Standards Review)...%b\n\n' "$CQR_BOLD" "$CQR_NC"
bash "$STANDARDS_SCRIPT"

# =============================================================================
# PHASE 2: COMPLEXITY ANALYSIS
# =============================================================================

printf '\n%bRunning Phase 2 (Complexity Analysis)...%b\n\n' "$CQR_BOLD" "$CQR_NC"
bash "$COMPLEXITY_SCRIPT"

# =============================================================================
# PHASE 3: PATTERN & ARCHITECTURE REVIEW
# =============================================================================

printf '\n%bRunning Phase 3 (Pattern & Architecture Review)...%b\n\n' "$CQR_BOLD" "$CQR_NC"
bash "$PATTERNS_SCRIPT"

# =============================================================================
# PHASE 4: QUALITY REPORT
# =============================================================================

printf '\n%bRunning Phase 4 (Quality Report & Recommendations)...%b\n\n' "$CQR_BOLD" "$CQR_NC"
bash "$REPORT_SCRIPT"

# =============================================================================
# COMPLETION
# =============================================================================

cqr_banner "Code Quality Review Complete"

cat << EOF

All output files have been written to: $CQR_OUTPUT_DIR

Main Reports:
  • 01-standards-review.md  — Coding standards baseline and findings
  • 02-complexity-report.md — Complexity metrics and hotspots
  • 03-patterns-review.md   — SOLID audit and pattern compliance
  • 04-quality-report.md    — Detailed findings by severity
  • CQR-FINAL.md            — Executive summary and recommendations
  • 05-cq-debts.md          — Technical debt registry

Next Steps:
  1. Review CQR-FINAL.md for executive summary
  2. Review 04-quality-report.md for detailed findings
  3. Use the top 10 priority actions to plan refactoring sprints
  4. Track CQDEBT-NN entries in your backlog

Quality Improvement Roadmap:
  Week 1: Fix critical issues (security, stability)
  Week 2: Begin major refactoring (complexity, SOLID violations)
  Week 3: Complete refactoring and add documentation
  Week 4: Validation and follow-up analysis

---

EOF

printf '%b✅ Workflow complete!%b\n\n' "$CQR_GREEN" "$CQR_NC"
