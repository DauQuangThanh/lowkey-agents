#!/bin/bash
# run-all.sh — Test Architect Workflow Orchestrator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
ta_parse_flags "$@"


ta_banner "Test Architect Workflow — All Phases"

# Check for upstream outputs
printf '%b\n' "$TA_CYAN"
printf 'Checking for upstream outputs...%b\n' "$TA_NC"

BA_FINAL="$TA_BA_INPUT_DIR/REQUIREMENTS-FINAL.md"
ARCH_FINAL="$TA_ARCH_INPUT_DIR/ARCHITECTURE-FINAL.md"

if [ -f "$BA_FINAL" ]; then
  ta_dim "✓ Found BA output: $BA_FINAL"
fi

if [ -f "$ARCH_FINAL" ]; then
  ta_dim "✓ Found Architect output: $ARCH_FINAL"
fi

printf '\n'

# Run Phase 1: Test Strategy
printf '%b\n' "$TA_CYAN"
printf 'Running Phase 1: Test Strategy Design%b\n' "$TA_NC"
ta_dim "This phase captures your overall test approach, levels, types, automation ratio, and exit criteria."
bash "$SCRIPT_DIR/../../ta-strategy/scripts/strategy.sh" || true

printf '\n'

# Run Phase 2: Test Framework
printf '%b\n' "$TA_CYAN"
printf 'Running Phase 2: Test Automation Framework Design%b\n' "$TA_NC"
ta_dim "This phase selects automation tools and designs your framework pattern."
bash "$SCRIPT_DIR/../../ta-framework/scripts/framework.sh" || true

printf '\n'

# Run Phase 3: Coverage
printf '%b\n' "$TA_CYAN"
printf 'Running Phase 3: Test Coverage Analysis%b\n' "$TA_NC"
ta_dim "This phase maps requirements to test cases and identifies gaps."
bash "$SCRIPT_DIR/../../ta-coverage/scripts/coverage.sh" || true

printf '\n'

# Run Phase 4: Quality Gates
printf '%b\n' "$TA_CYAN"
printf 'Running Phase 4: Quality Gate Definitions%b\n' "$TA_NC"
ta_dim "This phase defines quality checkpoints and pass/fail criteria."
bash "$SCRIPT_DIR/../../ta-quality-gates/scripts/quality-gates.sh" || true

printf '\n'

# Run Phase 5: Environments
printf '%b\n' "$TA_CYAN"
printf 'Running Phase 5: Test Environment Planning%b\n' "$TA_NC"
ta_dim "This phase plans your test infrastructure and data needs."
bash "$SCRIPT_DIR/../../ta-environment/scripts/environment.sh" || true

printf '\n'

# Compile final output
ta_success_rule "Compiling final deliverable..."

FINAL_FILE="$TA_OUTPUT_DIR/TA-FINAL.md"

{
  printf '# Test Architecture — Final Deliverable\n'
  printf '\n'
  printf '**Generated:** %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf '\n'
  printf '## Executive Summary\n'
  printf '\n'
  printf 'This document consolidates the test architecture for your project.\n'
  printf '\n'

  if [ -f "$TA_OUTPUT_DIR/01-test-strategy.md" ]; then
    printf -- '---\n'
    printf '\n'
    printf '## Phase 1: Test Strategy\n'
    printf '\n'
    tail -n +2 "$TA_OUTPUT_DIR/01-test-strategy.md" >> "$FINAL_FILE" || true
    printf '\n'
  fi

  if [ -f "$TA_OUTPUT_DIR/02-automation-framework.md" ]; then
    printf -- '---\n'
    printf '\n'
    printf '## Phase 2: Test Automation Framework\n'
    printf '\n'
    tail -n +2 "$TA_OUTPUT_DIR/02-automation-framework.md" >> "$FINAL_FILE" || true
    printf '\n'
  fi

  if [ -f "$TA_OUTPUT_DIR/03-coverage-matrix.md" ]; then
    printf -- '---\n'
    printf '\n'
    printf '## Phase 3: Test Coverage Analysis\n'
    printf '\n'
    tail -n +2 "$TA_OUTPUT_DIR/03-coverage-matrix.md" >> "$FINAL_FILE" || true
    printf '\n'
  fi

  if [ -f "$TA_OUTPUT_DIR/04-quality-gates.md" ]; then
    printf -- '---\n'
    printf '\n'
    printf '## Phase 4: Quality Gate Definitions\n'
    printf '\n'
    tail -n +2 "$TA_OUTPUT_DIR/04-quality-gates.md" >> "$FINAL_FILE" || true
    printf '\n'
  fi

  if [ -f "$TA_OUTPUT_DIR/05-environment-plan.md" ]; then
    printf -- '---\n'
    printf '\n'
    printf '## Phase 5: Test Environment Plan\n'
    printf '\n'
    tail -n +2 "$TA_OUTPUT_DIR/05-environment-plan.md" >> "$FINAL_FILE" || true
    printf '\n'
  fi

  printf -- '---\n'
  printf '\n'
  printf '## Test Debt Register\n'
  printf '\n'
  if [ -f "$TA_DEBT_FILE" ]; then
    cat "$TA_DEBT_FILE" >> "$FINAL_FILE" || true
  else
    printf 'No debts recorded.\n' >> "$FINAL_FILE"
  fi

  printf '\n'
  printf '## Sign-Off Block\n'
  printf '\n'
  printf '**Approved by:**\n'
  printf -- '- Test Lead: ________________  Date: __________\n'
  printf -- '- Engineering Lead: ________________  Date: __________\n'
  printf -- '- Product Owner: ________________  Date: __________\n'
  printf '\n'

} > "$FINAL_FILE"

printf '%b✓%b All phases complete! Output saved to:\n' "$TA_GREEN" "$TA_NC"
printf '  %s\n' "$FINAL_FILE"

ta_success_rule "Test Architecture Workflow Complete"

printf '%b\n' "$TA_CYAN"
ta_dim "Next steps:"
ta_dim "  1. Review all outputs in ta-output/"
ta_dim "  2. Address any TadebtS in 06-ta-debts.md"
ta_dim "  3. Share TA-FINAL.md with stakeholders for sign-off"
ta_dim "  4. Hand over to developers and testers"
printf '%b\n' "$TA_NC"
