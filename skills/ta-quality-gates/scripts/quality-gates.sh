#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ta_parse_flags "$@"


ta_banner "Phase 4: Quality Gate Definitions"

OUTPUT_FILE="$TA_OUTPUT_DIR/04-quality-gates.md"

printf '%b\n' "$TA_CYAN"
printf 'Question 1/6: Gate Checkpoints%b\n' "$TA_NC"
checkpoints=$(ta_ask "When do gates apply? (e.g. per-commit, per-sprint, pre-release):")
[ -z "$checkpoints" ] && checkpoints="Per-commit, Per-release"

printf '%b\n' "$TA_CYAN"
printf 'Question 2/6: Pass/Fail Criteria'
criteria=$(ta_ask "What must pass? (e.g. tests pass, coverage threshold, zero critical defects):")
[ -z "$criteria" ] && criteria="All tests pass, coverage >= 80%, zero critical defects"

printf '%b\n' "$TA_CYAN"
printf 'Question 3/6: Code Coverage Threshold'
coverage_unit=$(ta_ask "Unit test coverage % target (default 90):")
[ -z "$coverage_unit" ] && coverage_unit="90"
coverage_integration=$(ta_ask "Integration test coverage % target (default 60):")
[ -z "$coverage_integration" ] && coverage_integration="60"

printf '%b\n' "$TA_CYAN"
printf 'Question 4/6: Performance Benchmarks'
perf=$(ta_ask "Enter performance SLAs (e.g. API p95 < 200ms, page load < 3s):")
[ -z "$perf" ] && perf="TBD"

printf '%b\n' "$TA_CYAN"
printf 'Question 5/6: Security Scan Requirements'
security=$(ta_ask "Which scans required? (e.g. SAST, DAST, dependency scanning, OWASP):")
[ -z "$security" ] && security="SAST, dependency scanning"

printf '%b\n' "$TA_CYAN"
printf 'Question 6/6: Manual Approval Gates'
approvals=$(ta_ask "Which gates require manual approval? (e.g. security, release, UAT):")
[ -z "$approvals" ] && approvals="Release, UAT"

printf '\n'
ta_success_rule "Generating quality gate definitions..."

{
  printf '# 4. Quality Gate Definitions\n'
  printf '\n'
  printf '**Project:** TBD\n'
  printf '**Version:** 1.0\n'
  printf '**Date:** %s\n' "$(date -u +'%Y-%m-%d')"
  printf '\n'
  printf '## 4.1 Gate Checkpoints\n'
  printf '\n%s\n' "$checkpoints"
  printf '\n'
  printf '## 4.2 Pass/Fail Criteria\n'
  printf '\n%s\n' "$criteria"
  printf '\n'
  printf '## 4.3 Code Coverage Thresholds\n'
  printf '\n'
  printf -- '- Unit tests: %s%%\n' "$coverage_unit"
  printf -- '- Integration tests: %s%%\n' "$coverage_integration"
  printf '\n'
  printf '## 4.4 Performance Benchmarks\n'
  printf '\n%s\n' "$perf"
  printf '\n'
  printf '## 4.5 Security Scan Requirements\n'
  printf '\n%s\n' "$security"
  printf '\n'
  printf '## 4.6 Manual Approval Gates\n'
  printf '\n%s\n' "$approvals"
  printf '\n'
} > "$OUTPUT_FILE"

printf '%b✓%b Output saved to: %s\n' "$TA_GREEN" "$TA_NC" "$OUTPUT_FILE"
ta_success_rule "Phase 4 Complete: Quality Gates"
