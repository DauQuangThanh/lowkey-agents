#!/bin/bash
# =============================================================================
# validate.sh — Phase 4: Design & Code Quality Validation
# Performs automated checks on design completeness and consistency,
# asks manual validation questions, then compiles into DEVELOPER-FINAL.md
# Writes output to $DEV_OUTPUT_DIR/04-validation-report.md and DEVELOPER-FINAL.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
dev_parse_flags "$@"


REPORT_FILE="$DEV_OUTPUT_DIR/04-validation-report.md"
FINAL_FILE="$DEV_OUTPUT_DIR/DEVELOPER-FINAL.md"
AREA="Design Validation"

dev_banner "✅  Phase 4 of 4 — Design & Code Quality Validation"
dev_dim "  Confirm design is complete, consistent, and ready for implementation."
echo ""

# ── Collect all phase files ──────────────────────────────────────────────────
design_file="$DEV_OUTPUT_DIR/01-detailed-design.md"
coding_file="$DEV_OUTPUT_DIR/02-coding-plan.md"
test_file="$DEV_OUTPUT_DIR/03-unit-test-plan.md"
debt_file="$DEV_OUTPUT_DIR/05-design-debts.md"

phase1_ok=0
phase2_ok=0
phase3_ok=0

if [ -f "$design_file" ]; then
  printf '%b  ✓ Found: %s%b\n' "$DEV_GREEN" "01-detailed-design.md" "$DEV_NC"
  phase1_ok=1
else
  printf '%b  ✗ Missing: %s%b\n' "$DEV_RED" "01-detailed-design.md" "$DEV_NC"
fi

if [ -f "$coding_file" ]; then
  printf '%b  ✓ Found: %s%b\n' "$DEV_GREEN" "02-coding-plan.md" "$DEV_NC"
  phase2_ok=1
else
  printf '%b  ✗ Missing: %s%b\n' "$DEV_RED" "02-coding-plan.md" "$DEV_NC"
fi

if [ -f "$test_file" ]; then
  printf '%b  ✓ Found: %s%b\n' "$DEV_GREEN" "03-unit-test-plan.md" "$DEV_NC"
  phase3_ok=1
else
  printf '%b  ✗ Missing: %s%b\n' "$DEV_RED" "03-unit-test-plan.md" "$DEV_NC"
fi

echo ""

# ── Count DDEBTs ─────────────────────────────────────────────────────────────
blocking_ddebts=0
important_ddebts=0
if [ -f "$debt_file" ]; then
  blocking_ddebts=$(grep -c '🔴 Blocking' "$debt_file" 2>/dev/null || printf '0')
  important_ddebts=$(grep -c '🟡 Important' "$debt_file" 2>/dev/null || printf '0')
fi

printf '%b%b── Automated Checks ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
printf '\n%b  Design Documents:%b Phase 1: %s | Phase 2: %s | Phase 3: %s\n' "$DEV_DIM" "$DEV_NC" \
  "$([ $phase1_ok -eq 1 ] && printf '✓' || printf '✗')" \
  "$([ $phase2_ok -eq 1 ] && printf '✓' || printf '✗')" \
  "$([ $phase3_ok -eq 1 ] && printf '✓' || printf '✗')"
printf '%b  Design Debts:%b %d blocking | %d important\n' "$DEV_DIM" "$DEV_NC" "$blocking_ddebts" "$important_ddebts"
echo ""

# ── Manual Questions ─────────────────────────────────────────────────────────
printf '%b%b── Manual Validation Questions ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
echo ""

q1=$(dev_ask_yn "Can a mid-level developer pick up any module and understand it in 30 minutes?")
q2=$(dev_ask_yn "Are error codes and validation rules consistent across modules?")
q3=$(dev_ask_yn "Is the primary business flow clearly documented?")
q4=$(dev_ask_yn "Is the testing strategy aligned with team skill and CI/CD capacity?")
q5=$(dev_ask_yn "Are all stakeholders aware of their dependencies and responsibilities?")

echo ""

# ── Determine sign-off status ────────────────────────────────────────────────
printf '%b%b── Sign-Off Assessment ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
echo ""

all_phases=$((phase1_ok * phase2_ok * phase3_ok))
all_manual=$(([ "$q1" = "yes" ] && [ "$q2" = "yes" ] && [ "$q3" = "yes" ] && [ "$q4" = "yes" ] && [ "$q5" = "yes" ] ? 1 : 0))

if [ "$all_phases" -eq 1 ] && [ "$blocking_ddebts" -eq 0 ] && [ "$all_manual" -eq 1 ]; then
  status="READY FOR CODE"
  status_symbol="✅"
  status_color="$DEV_GREEN"
elif [ "$all_phases" -eq 1 ] && [ "$blocking_ddebts" -eq 0 ]; then
  status="READY WITH CAVEATS"
  status_symbol="⚠️ "
  status_color="$DEV_YELLOW"
else
  status="NOT READY"
  status_symbol="❌"
  status_color="$DEV_RED"
fi

printf '%b%b  %s %s%b\n\n' "$status_color" "$DEV_BOLD" "$status_symbol" "$status" "$DEV_NC"

# ── Write validation report ──────────────────────────────────────────────────
{
  echo "# Design & Code Quality Validation Report"
  echo ""
  echo "**Date:** $(date '+%Y-%m-%d')"
  echo "**Status:** $status"
  echo ""
  echo "---"
  echo ""
  echo "## Automated Checks"
  echo ""
  echo "### Design Documents"
  echo "| Phase | Status |"
  echo "|---|---|"
  [ $phase1_ok -eq 1 ] && echo "| 1. Detailed Design | ✓ Present |" || echo "| 1. Detailed Design | ✗ Missing |"
  [ $phase2_ok -eq 1 ] && echo "| 2. Coding Standards | ✓ Present |" || echo "| 2. Coding Standards | ✗ Missing |"
  [ $phase3_ok -eq 1 ] && echo "| 3. Unit Test Strategy | ✓ Present |" || echo "| 3. Unit Test Strategy | ✗ Missing |"
  echo ""
  echo "### Design Debts"
  echo "- **Blocking:** $blocking_ddebts"
  echo "- **Important:** $important_ddebts"
  [ "$blocking_ddebts" -gt 0 ] && echo "- ⚠️  _Blocking DDEBTs must be resolved before implementation_"
  echo ""
  echo "---"
  echo ""
  echo "## Manual Validation"
  echo ""
  echo "| Question | Answer |"
  echo "|---|---|"
  echo "| Can a mid-level developer understand any module in 30 min? | $q1 |"
  echo "| Are error codes & validation rules consistent? | $q2 |"
  echo "| Is the primary business flow clearly documented? | $q3 |"
  echo "| Is testing strategy aligned with team & CI/CD? | $q4 |"
  echo "| Are all stakeholders aware of dependencies? | $q5 |"
  echo ""
  echo "---"
  echo ""
  echo "## Sign-Off Status"
  echo ""
  echo "**$status**"
  echo ""
  if [ "$status" = "READY FOR CODE" ]; then
    echo "All design phases complete, no blocking debts, and all validation questions answered affirmatively. **Ready to begin implementation.**"
  elif [ "$status" = "READY WITH CAVEATS" ]; then
    echo "Design is substantially complete with minor gaps tracked as DDEBTs. Implementation can proceed with awareness of open items."
  else
    echo "Design has gaps or blocking debts that must be resolved before implementation starts."
  fi
  echo ""
} > "$REPORT_FILE"

printf '%b  ✅ Saved validation report: %s%b\n\n' "$DEV_GREEN" "$REPORT_FILE" "$DEV_NC"

# ── Compile final deliverable ────────────────────────────────────────────────
if [ $phase1_ok -eq 1 ]; then
  design_content=$(cat "$design_file")
else
  design_content="_(Phase 1 not completed)_"
fi

if [ $phase2_ok -eq 1 ]; then
  coding_content=$(cat "$coding_file")
else
  coding_content="_(Phase 2 not completed)_"
fi

if [ $phase3_ok -eq 1 ]; then
  test_content=$(cat "$test_file")
else
  test_content="_(Phase 3 not completed)_"
fi

if [ -f "$debt_file" ]; then
  debt_content=$(cat "$debt_file")
else
  debt_content="_(No design debts logged)_"
fi

{
  echo "# DEVELOPER-FINAL: Complete Design & Implementation Specification"
  echo ""
  echo "**Compiled:** $(date '+%Y-%m-%d %H:%M')"
  echo "**Status:** $status"
  echo "**Sign-Off:** $status_symbol"
  echo ""
  echo "This document consolidates all four phases of the Developer workflow:"
  echo "detailed design, coding standards, unit test strategy, and validation."
  echo "It is the complete blueprint for implementation."
  echo ""
  echo "---"
  echo ""
  echo "## 1. Detailed Design"
  echo ""
  echo "$design_content"
  echo ""
  echo "---"
  echo ""
  echo "## 2. Coding Standards & Implementation Plan"
  echo ""
  echo "$coding_content"
  echo ""
  echo "---"
  echo ""
  echo "## 3. Unit Test Strategy"
  echo ""
  echo "$test_content"
  echo ""
  echo "---"
  echo ""
  echo "## 4. Design & Code Quality Validation"
  echo ""
  echo "### Status: $status"
  echo ""
  echo "**All Phases Completed:** $([ $all_phases -eq 1 ] && echo 'Yes ✓' || echo 'No ✗')"
  echo ""
  echo "**Blocking Design Debts:** $blocking_ddebts"
  echo ""
  echo "**Manual Validation Passed:** $([ $all_manual -eq 1 ] && echo 'Yes ✓' || echo 'Partial or No')"
  echo ""
  echo "---"
  echo ""
  echo "## 5. Design Debts Register"
  echo ""
  echo "$debt_content"
  echo ""
  echo "---"
  echo ""
  echo "## Sign-Off Block"
  echo ""
  echo "| Item | Status |"
  echo "|---|---|"
  echo "| Design phases complete | $([ $all_phases -eq 1 ] && echo '✓' || echo '✗') |"
  echo "| No blocking debts | $([ $blocking_ddebts -eq 0 ] && echo '✓' || echo '✗') |"
  echo "| Manual validation passed | $([ $all_manual -eq 1 ] && echo '✓' || echo '✗') |"
  echo "| **Ready for implementation** | $status_symbol |"
  echo ""
  echo "---"
  echo ""
  echo "## Next Steps"
  echo ""
  if [ "$status" = "READY FOR CODE" ]; then
    echo "1. Distribute this specification to all team members"
    echo "2. Assign module owners and start implementation"
    echo "3. Begin with Phase 1 modules and work through dependency graph"
    echo "4. Follow coding standards (Phase 2) and test strategy (Phase 3)"
    echo "5. Track design debt items and schedule resolutions"
  elif [ "$status" = "READY WITH CAVEATS" ]; then
    echo "1. Review open DDEBTs and assign owners"
    echo "2. Set target dates for DDEBT resolution"
    echo "3. Begin implementation with awareness of known gaps"
    echo "4. Resolve DDEBTs as they are encountered"
  else
    echo "1. Review blocking items and gaps"
    echo "2. Resolve before proceeding to implementation"
    echo "3. Re-run validation once issues are addressed"
  fi
  echo ""
} > "$FINAL_FILE"

printf '%b  ✅ Saved final deliverable: %s%b\n\n' "$DEV_GREEN" "$FINAL_FILE" "$DEV_NC"

dev_success_rule "✅ Design & Code Quality Validation Complete"
printf '%b  Status: %s%b\n' "$status_color" "$status" "$DEV_NC"
printf '%b  Report:  %s%b\n' "$DEV_GREEN" "$REPORT_FILE" "$DEV_NC"
printf '%b  Final:   %s%b\n' "$DEV_GREEN" "$FINAL_FILE" "$DEV_NC"
echo ""
