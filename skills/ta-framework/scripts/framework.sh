#!/bin/bash
# framework.sh — Phase 2: Test Automation Framework Design
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ta_parse_flags "$@"


ta_banner "Phase 2: Test Automation Framework Design"

OUTPUT_FILE="$TA_OUTPUT_DIR/02-automation-framework.md"

# Q1: Tech Stack
printf '%b\n' "$TA_CYAN"
printf 'Question 1/8: Tech Stack%b\n' "$TA_NC"
ta_dim "What is the frontend framework (React, Vue, Angular, Svelte, server-rendered)?"
frontend_fw=$(ta_ask "Enter frontend framework:")
[ -z "$frontend_fw" ] && frontend_fw="TBD"

ta_dim "What is the backend language and framework?"
backend_stack=$(ta_ask "Enter backend language/framework:")
[ -z "$backend_stack" ] && backend_stack="TBD"

# Q2: Automation Tool Selection
printf '%b\n' "$TA_CYAN"
printf 'Question 2/8: Automation Tool Selection%b\n' "$TA_NC"
ta_dim "What will you use for UI/E2E testing?"
ui_tool=$(ta_ask_choice "Choose UI/E2E automation tool:" \
  "Playwright (multi-browser, fast)" \
  "Cypress (single-browser, excellent DX)" \
  "Selenium (mature, cross-browser)" \
  "Other (specify)")
[ "$ui_tool" = "Other (specify)" ] && ui_tool=$(ta_ask "Enter tool name:")

ta_dim "What will you use for API testing?"
api_tool=$(ta_ask_choice "Choose API testing tool:" \
  "Postman + Newman (user-friendly, CI-friendly)" \
  "REST Assured (powerful, Java-based)" \
  "Karate (API+performance, open-source)" \
  "Other (specify)")
[ "$api_tool" = "Other (specify)" ] && api_tool=$(ta_ask "Enter tool name:")

# Q3: Framework Pattern
printf '%b\n' "$TA_CYAN"
printf 'Question 3/8: Framework Pattern%b\n' "$TA_NC"
framework_pattern=$(ta_ask_choice "Choose framework pattern:" \
  "Page Object Model (POM - maintainable)" \
  "Screenplay Pattern (OOP, readable)" \
  "Keyword-Driven (low-code)" \
  "BDD (Gherkin - Given/When/Then)" \
  "Hybrid (combination)")

# Q4: Test Runner & Framework
printf '%b\n' "$TA_CYAN"
printf 'Question 4/8: Test Runner & Framework%b\n' "$TA_NC"
test_runner=$(ta_ask "What test runner/framework? (e.g. Jest, JUnit, Pytest, Mocha)")
[ -z "$test_runner" ] && test_runner="TBD"

# Q5: Reporting & Observability
printf '%b\n' "$TA_CYAN"
printf 'Question 5/8: Reporting & Observability%b\n' "$TA_NC"
ta_dim "Where will test reports be generated?"
reporting=$(ta_ask "Enter reporting tool/approach (e.g. HTML, Allure, ReportPortal):")
[ -z "$reporting" ] && reporting="HTML reports"

# Q6: CI/CD Integration
printf '%b\n' "$TA_CYAN"
printf 'Question 6/8: CI/CD Integration%b\n' "$TA_NC"
cicd_tool=$(ta_ask "What CI/CD platform? (e.g. GitHub Actions, GitLab CI, Azure DevOps, Jenkins)")
[ -z "$cicd_tool" ] && cicd_tool="TBD"

ta_dim "When should tests be triggered?"
cicd_trigger=$(ta_ask_choice "Choose CI/CD trigger:" \
  "On every commit/PR (fast feedback)" \
  "On merge to develop (gated promotion)" \
  "Scheduled nightly (slower, comprehensive)" \
  "Manual + scheduled (flexible)")

# Q7: Parallel Execution Strategy
printf '%b\n' "$TA_CYAN"
printf 'Question 7/8: Parallel Execution Strategy%b\n' "$TA_NC"
ta_dim "How many test workers/browsers in parallel?"
parallel_workers=$(ta_ask "Enter number of parallel workers (default 4):")
[ -z "$parallel_workers" ] && parallel_workers="4"

# Q8: Test Environment Requirements
printf '%b\n' "$TA_CYAN"
printf 'Question 8/8: Test Environment Requirements%b\n' "$TA_NC"
ta_dim "What browsers to test? (comma-separated: Chrome, Firefox, Safari, Edge)"
browsers=$(ta_ask "Enter browsers:")
[ -z "$browsers" ] && browsers="Chrome (latest), Firefox (latest)"

# Generate output
printf '\n'
ta_success_rule "Generating test automation framework document..."

{
  printf '# 2. Test Automation Framework Design\n'
  printf '\n'
  printf '**Project:** TBD\n'
  printf '**Version:** 1.0\n'
  printf '**Date:** %s\n' "$(date -u +'%Y-%m-%d')"
  printf '**Owner:** TBD\n'
  printf '\n'
  printf '## 2.1 Tech Stack Summary\n'
  printf '\n'
  printf '| Component | Technology |\n'
  printf '|-----------|---|\n'
  printf '| Frontend | %s |\n' "$frontend_fw"
  printf '| Backend | %s |\n' "$backend_stack"
  printf '\n'
  printf '## 2.2 Automation Tool Selection\n'
  printf '\n'
  printf 'UI/E2E Testing: **%s**\n' "$ui_tool"
  printf '\n'
  printf 'API Testing: **%s**\n' "$api_tool"
  printf '\n'
  printf '## 2.3 Framework Pattern\n'
  printf '\n'
  printf 'Chosen: **%s**\n' "$framework_pattern"
  printf '\n'
  printf '## 2.4 Test Runner & Framework\n'
  printf '\n'
  printf 'Runner: %s\n' "$test_runner"
  printf '\n'
  printf '## 2.5 Reporting & Observability\n'
  printf '\n'
  printf 'Tool: %s\n' "$reporting"
  printf '\n'
  printf '## 2.6 CI/CD Integration\n'
  printf '\n'
  printf 'Platform: %s\n' "$cicd_tool"
  printf 'Trigger: %s\n' "$cicd_trigger"
  printf '\n'
  printf '## 2.7 Parallel Execution Strategy\n'
  printf '\n'
  printf 'Workers: %s\n' "$parallel_workers"
  printf '\n'
  printf '## 2.8 Test Environment Requirements\n'
  printf '\n'
  printf 'Browsers: %s\n' "$browsers"
  printf '\n'
} > "$OUTPUT_FILE"

printf '%b✓%b Output saved to: %s\n' "$TA_GREEN" "$TA_NC" "$OUTPUT_FILE"

ta_success_rule "Phase 2 Complete: Test Automation Framework"
