#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ta_parse_flags "$@"


ta_banner "Phase 5: Test Environment Planning"

OUTPUT_FILE="$TA_OUTPUT_DIR/05-environment-plan.md"

printf '%b\n' "$TA_CYAN"
printf 'Question 1/6: Environments Needed%b\n' "$TA_NC"
envs=$(ta_ask "Which environments? (e.g. Dev, QA, Staging, Production):")
[ -z "$envs" ] && envs="Dev, QA, Staging"

printf '%b\n' "$TA_CYAN"
printf 'Question 2/6: Data Requirements'
data_req=$(ta_ask "Data volume per environment? (e.g. Dev: 10 users, QA: 100 users, Staging: 10k users):")
[ -z "$data_req" ] && data_req="Dev: small, QA: medium, Staging: large"

printf '%b\n' "$TA_CYAN"
printf 'Question 3/6: Infrastructure Needs'
infra=$(ta_ask "What infrastructure is needed? (e.g. VMs, databases, mocks, device farm):")
[ -z "$infra" ] && infra="Virtual machines, PostgreSQL, service mocks"

printf '%b\n' "$TA_CYAN"
printf 'Question 4/6: Test Data Masking'
masking=$(ta_ask_choice "How will you handle PII?" \
  "Production replica (masked PII)" \
  "Synthetic generation (no real data)" \
  "Hybrid (some masked, some synthetic)")

printf '%b\n' "$TA_CYAN"
printf 'Question 5/6: Refresh Frequency'
refresh=$(ta_ask "How often to refresh test environments? (e.g. nightly, weekly, on-demand):")
[ -z "$refresh" ] && refresh="Nightly"

printf '%b\n' "$TA_CYAN"
printf 'Question 6/6: Access Control'
access=$(ta_ask "How will test credentials be secured? (e.g. Vault, GitHub Secrets, environment variables):")
[ -z "$access" ] && access="Environment variables, secrets manager"

printf '\n'
ta_success_rule "Generating test environment plan..."

{
  printf '# 5. Test Environment Plan\n'
  printf '\n'
  printf '**Project:** TBD\n'
  printf '**Version:** 1.0\n'
  printf '**Date:** %s\n' "$(date -u +'%Y-%m-%d')"
  printf '\n'
  printf '## 5.1 Environments Needed\n'
  printf '\n%s\n' "$envs"
  printf '\n'
  printf '## 5.2 Data Requirements\n'
  printf '\n%s\n' "$data_req"
  printf '\n'
  printf '## 5.3 Infrastructure & Services\n'
  printf '\n%s\n' "$infra"
  printf '\n'
  printf '## 5.4 Test Data Masking\n'
  printf '\nApproach: %s\n' "$masking"
  printf '\n'
  printf '## 5.5 Environment Refresh Frequency\n'
  printf '\n%s\n' "$refresh"
  printf '\n'
  printf '## 5.6 Access Control & Security\n'
  printf '\n%s\n' "$access"
  printf '\n'
} > "$OUTPUT_FILE"

printf '%b✓%b Output saved to: %s\n' "$TA_GREEN" "$TA_NC" "$OUTPUT_FILE"
ta_success_rule "Phase 5 Complete: Test Environment Plan"
