#!/bin/bash
# strategy.sh — Phase 1: Test Strategy Design
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ta_parse_flags "$@"


ta_banner "Phase 1: Test Strategy Design"

OUTPUT_FILE="$TA_OUTPUT_DIR/01-test-strategy.md"

# Check for upstream BA output
BA_FINAL="$TA_BA_INPUT_DIR/REQUIREMENTS-FINAL.md"
if [ -f "$BA_FINAL" ]; then
  ta_dim "✓ Found BA output at $BA_FINAL"
  ta_dim "  Reading requirements..."
fi

# Initialize debt file if not present
if [ ! -f "$TA_DEBT_FILE" ]; then
  {
    printf '# Test Architecture Debt Register\n'
    printf '\n'
    printf '**Project:** TBD\n'
    printf '**Version:** 1.0\n'
    printf '**Last Updated:** %s\n' "$(date -u +'%Y-%m-%d')"
    printf '\n'
  } > "$TA_DEBT_FILE"
fi

# Q1: Test Approach
printf '%b\n' "$TA_CYAN"
printf 'Question 1/8: Test Approach%b\n' "$TA_NC"
ta_dim "What testing methodology will guide decisions?"
test_approach=$(ta_ask_choice "Choose test approach:" \
  "Risk-based (focus on high-risk areas)" \
  "Requirement-based (cover all specified requirements)" \
  "Exploratory (ad-hoc testing with skilled testers)" \
  "Hybrid (combination of the above)")

# Q2: Test Levels
printf '%b\n' "$TA_CYAN"
printf 'Question 2/8: Test Levels%b\n' "$TA_NC"
ta_dim "Which test levels are in scope? (comma-separated from: Unit, Integration, System, E2E, UAT)"
test_levels=$(ta_ask "Enter test levels in scope:")
[ -z "$test_levels" ] && test_levels="Unit, Integration, System, E2E" && ta_dim "Using default: $test_levels"

# Q3: Test Types
printf '%b\n' "$TA_CYAN"
printf 'Question 3/8: Test Types%b\n' "$TA_NC"
ta_dim "Which test types are required? (comma-separated from: Functional, Performance, Security, Accessibility, Compatibility, Usability)"
test_types=$(ta_ask "Enter test types in scope:")
[ -z "$test_types" ] && test_types="Functional, Performance, Security" && ta_dim "Using default: $test_types"

# Q4: Automation Ratio
printf '%b\n' "$TA_CYAN"
printf 'Question 4/8: Automation vs Manual Ratio%b\n' "$TA_NC"
ta_dim "Target split (e.g. 80 for 80% automated, 20% manual)"
automation_ratio=$(ta_ask "Enter automation % target:")
[ -z "$automation_ratio" ] && automation_ratio="80" && ta_dim "Using default: 80%"

# Q5: Test Data Management
printf '%b\n' "$TA_CYAN"
printf 'Question 5/8: Test Data Management%b\n' "$TA_NC"
test_data=$(ta_ask_choice "How will you manage test data?" \
  "Production replica (masked PII)" \
  "Synthetic generation (factories, faker libraries)" \
  "Embedded fixtures (git-versioned data sets)" \
  "On-the-fly creation (API factories during test run)")

# Q6: Defect Management Process
printf '%b\n' "$TA_CYAN"
printf 'Question 6/8: Defect Management%b\n' "$TA_NC"
defect_tool=$(ta_ask "What tool will you use for defect tracking? (e.g. Jira, GitHub Issues, Azure DevOps)")
[ -z "$defect_tool" ] && defect_tool="TBD" && ta_dim "Will determine later"

# Q7: Test Metrics
printf '%b\n' "$TA_CYAN"
printf 'Question 7/8: Test Metrics & KPIs%b\n' "$TA_NC"
ta_dim "Which KPIs matter most? (comma-separated from: Code Coverage %, Requirements Coverage %, Defect Escape Rate, Test Execution Time, Defect Density)"
test_metrics=$(ta_ask "Enter key metrics:")
[ -z "$test_metrics" ] && test_metrics="Code Coverage %, Requirements Coverage %, Defect Escape Rate" && ta_dim "Using default: $test_metrics"

# Q8: Test Exit Criteria
printf '%b\n' "$TA_CYAN"
printf 'Question 8/8: Test Exit Criteria%b\n' "$TA_NC"
ta_dim "When is testing done? (comma-separated from: All critical requirements tested, Code coverage threshold met, Zero critical defects, Smoke tests passed, UAT sign-off)"
exit_criteria=$(ta_ask "Enter test exit criteria:")
[ -z "$exit_criteria" ] && exit_criteria="All critical requirements tested, Code coverage threshold met, Zero critical defects, UAT sign-off" && ta_dim "Using default"

# Generate output
printf '\n'
ta_success_rule "Generating test strategy document..."

{
  printf '# 1. Test Strategy\n'
  printf '\n'
  printf '**Project:** TBD\n'
  printf '**Version:** 1.0\n'
  printf '**Date:** %s\n' "$(date -u +'%Y-%m-%d')"
  printf '**Owner:** TBD\n'
  printf '\n'
  printf '## Overview\n'
  printf '\n'
  printf 'This test strategy outlines the overall testing approach for the project.\n'
  printf '\n'
  printf '## 1.1 Test Approach\n'
  printf '\n'
  printf 'We will use **%s** testing.\n' "$test_approach"
  printf '\n'
  printf '## 1.2 Test Levels & Scope\n'
  printf '\n'
  printf 'In scope: %s\n' "$test_levels"
  printf '\n'
  printf '## 1.3 Test Types\n'
  printf '\n'
  printf 'Test types: %s\n' "$test_types"
  printf '\n'
  printf '## 1.4 Automation vs. Manual Ratio\n'
  printf '\n'
  printf 'Target: %s%% automated, %d%% manual\n' "$automation_ratio" "$((100 - automation_ratio))"
  printf '\n'
  printf '## 1.5 Test Data Management\n'
  printf '\n'
  printf 'Approach: %s\n' "$test_data"
  printf '\n'
  printf '## 1.6 Defect Management\n'
  printf '\n'
  printf 'Tool: %s\n' "$defect_tool"
  printf '\n'
  printf '## 1.7 Test Metrics & KPIs\n'
  printf '\n'
  printf 'Metrics: %s\n' "$test_metrics"
  printf '\n'
  printf '## 1.8 Test Exit Criteria\n'
  printf '\n'
  printf 'Criteria: %s\n' "$exit_criteria"
  printf '\n'
} > "$OUTPUT_FILE"

printf '%b✓%b Output saved to: %s\n' "$TA_GREEN" "$TA_NC" "$OUTPUT_FILE"

ta_success_rule "Phase 1 Complete: Test Strategy"
