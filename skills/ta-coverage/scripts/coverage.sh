#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ta_parse_flags "$@"


ta_banner "Phase 3: Test Coverage Analysis"

OUTPUT_FILE="$TA_OUTPUT_DIR/03-coverage-matrix.md"

printf '%b\n' "$TA_CYAN"
printf 'Question 1/6: Requirements to Cover%b\n' "$TA_NC"
requirements=$(ta_ask "Describe requirements to cover (functional, non-functional, user stories):")
[ -z "$requirements" ] && requirements="TBD"

printf '%b\n' "$TA_CYAN"
printf 'Question 2/6: Coverage Target %%'
coverage_target=$(ta_ask "Enter code coverage % target (default 80):")
[ -z "$coverage_target" ] && coverage_target="80"

printf '%b\n' "$TA_CYAN"
printf 'Question 3/6: Traceability Approach'
traceability=$(ta_ask_choice "How will you map requirements to test cases?" \
  "Spreadsheet/Matrix (requirement ID → test case IDs)" \
  "Test management tool (TestRail, Zephyr)" \
  "Git-versioned traceability matrix (CSV/markdown)" \
  "Code-embedded via comments/annotations")

printf '%b\n' "$TA_CYAN"
printf 'Question 4/6: Risk-Based Prioritization'
risk_areas=$(ta_ask "List high-risk areas requiring 100% coverage:")
[ -z "$risk_areas" ] && risk_areas="Critical business flows, high-complexity components"

printf '%b\n' "$TA_CYAN"
printf 'Question 5/6: Coverage Metrics'
metrics=$(ta_ask "Which metrics to track (comma-separated: Statement, Branch, Requirement, Feature, User Journey):")
[ -z "$metrics" ] && metrics="Statement, Branch, Requirement"

printf '%b\n' "$TA_CYAN"
printf 'Question 6/6: Gap Analysis'
gaps=$(ta_ask "Identify under-tested areas:")
[ -z "$gaps" ] && gaps="TBD"

printf '\n'
ta_success_rule "Generating test coverage matrix..."

{
  printf '# 3. Test Coverage Analysis\n'
  printf '\n'
  printf '**Project:** TBD\n'
  printf '**Version:** 1.0\n'
  printf '**Date:** %s\n' "$(date -u +'%Y-%m-%d')"
  printf '\n'
  printf '## 3.1 Requirements to Cover\n'
  printf '\n%s\n' "$requirements"
  printf '\n'
  printf '## 3.2 Coverage Target\n'
  printf '\nTarget: %s%% code coverage\n' "$coverage_target"
  printf '\n'
  printf '## 3.3 Traceability Approach\n'
  printf '\nApproach: %s\n' "$traceability"
  printf '\n'
  printf '## 3.4 Risk-Based Prioritization\n'
  printf '\nHigh-risk areas: %s\n' "$risk_areas"
  printf '\n'
  printf '## 3.5 Coverage Metrics\n'
  printf '\nMetrics: %s\n' "$metrics"
  printf '\n'
  printf '## 3.6 Gap Analysis\n'
  printf '\nUnder-tested areas: %s\n' "$gaps"
  printf '\n'
} > "$OUTPUT_FILE"

printf '%b✓%b Output saved to: %s\n' "$TA_GREEN" "$TA_NC" "$OUTPUT_FILE"
ta_success_rule "Phase 3 Complete: Test Coverage Analysis"
