#!/bin/bash
# =============================================================================
# unit-test.sh — Phase 3: Unit Test Strategy & Generation
# Designs testable architecture, specifies framework, coverage targets,
# mocking strategy, test data, categories, and CI/CD integration.
# Writes output to $DEV_OUTPUT_DIR/03-unit-test-plan.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
dev_parse_flags "$@"


OUTPUT_FILE="$DEV_OUTPUT_DIR/03-unit-test-plan.md"
AREA="Unit Test Strategy"

start_ddebts=$(dev_current_ddebt_count)

dev_banner "🧪  Phase 3 of 4 — Unit Test Strategy"
dev_dim "  Design a testable architecture and specify testing framework,"
dev_dim "  coverage targets, mocking strategy, and CI/CD integration."
echo ""

# ── Question 1: Testing Framework ────────────────────────────────────────────
printf '%b%b── Q1: Testing Framework ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Language-specific: Jest/Vitest (JS), Pytest/Unittest (Python),"
dev_dim "  JUnit/Mockito (Java), Xunit (.NET), etc."
dev_dim "  Assertion library? BDD (Gherkin) or TDD?"
framework=$(dev_ask "  What testing framework and assertion library?")
if [ -z "$framework" ]; then
  framework="TBD — testing framework not yet chosen"
  dev_add_ddebt "$AREA" "Testing framework not chosen" \
    "No testing framework or assertion library selected" \
    "Cannot begin writing unit tests without framework decision"
fi
echo ""

# ── Question 2: Coverage Target ──────────────────────────────────────────────
printf '%b%b── Q2: Coverage Target ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Minimum %? Different targets per module?"
dev_dim "  Example: Overall 80%, Core Domain 95%, UI 60%"
dev_dim "  Line coverage, branch coverage, or path coverage?"
coverage=$(dev_ask "  What are your coverage targets?")
if [ -z "$coverage" ]; then
  coverage="TBD — coverage targets not yet defined"
  dev_add_ddebt "$AREA" "Coverage targets undefined" \
    "No coverage targets or metrics defined" \
    "Unclear what level of testing is expected"
fi
echo ""

# ── Question 3: Test Naming & Structure ──────────────────────────────────────
printf '%b%b── Q3: Test Naming & Structure ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Convention: test<MethodName>_<Scenario>_<Expected>?"
dev_dim "  One test class per class under test?"
dev_dim "  Fixtures shared or isolated?"
naming=$(dev_ask "  Describe your test naming and structure conventions:")
if [ -z "$naming" ]; then
  naming="TBD — test naming conventions not yet decided"
  dev_add_ddebt "$AREA" "Test naming conventions undefined" \
    "No test naming or structure convention established" \
    "Inconsistent test organization makes maintenance harder"
fi
echo ""

# ── Question 4: What to Mock / Stub ──────────────────────────────────────────
printf '%b%b── Q4: What to Mock / Stub ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Mock external services (APIs, DBs, message queues)?"
dev_dim "  Use in-memory doubles or real test containers (Testcontainers)?"
dev_dim "  Spy on side effects (logging, events)?"
mocking=$(dev_ask "  Describe your mocking and stubbing strategy:")
if [ -z "$mocking" ]; then
  mocking="TBD — mocking strategy not yet decided"
  dev_add_ddebt "$AREA" "Mocking strategy undefined" \
    "No mocking or stubbing approach defined" \
    "Tests will be brittle or slow; unclear test dependencies"
fi
echo ""

# ── Question 5: Test Data Strategy ───────────────────────────────────────────
printf '%b%b── Q5: Test Data Strategy ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Fixtures hardcoded in tests? Factories? Builders?"
dev_dim "  Realistic/representative data or minimal?"
dev_dim "  Seeding for integration tests?"
test_data=$(dev_ask "  Describe your test data strategy:")
if [ -z "$test_data" ]; then
  test_data="TBD — test data strategy not yet planned"
  dev_add_ddebt "$AREA" "Test data strategy undefined" \
    "No approach for test data generation or fixtures" \
    "Tests will be fragile and hard to maintain"
fi
echo ""

# ── Question 6: Test Categories & Execution ──────────────────────────────────
printf '%b%b── Q6: Test Categories & Execution ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Unit (no IO, < 1s), Integration (< 10s), Smoke, E2E (slow)?"
dev_dim "  How to tag/organize? Run all on every commit?"
dev_dim "  Parallel execution? Fail-fast strategy?"
categories=$(dev_ask "  Describe your test categories and execution strategy:")
if [ -z "$categories" ]; then
  categories="TBD — test categories not yet organized"
  dev_add_ddebt "$AREA" "Test categories undefined" \
    "No distinction between unit, integration, E2E tests" \
    "Long feedback loop; slow CI/CD pipeline"
fi
echo ""

# ── Question 7: CI/CD Integration ────────────────────────────────────────────
printf '%b%b── Q7: CI/CD Integration ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Run all tests on every push? Parallel execution?"
dev_dim "  Fail on coverage drop? Flaky test tolerance?"
dev_dim "  What tests block merge vs. inform vs. optional?"
ci_cd=$(dev_ask "  Describe your CI/CD testing gates and strategy:")
if [ -z "$ci_cd" ]; then
  ci_cd="TBD — CI/CD testing gates not yet defined"
  dev_add_ddebt "$AREA" "CI/CD testing gates undefined" \
    "No automated testing gates in CI/CD pipeline" \
    "Broken code may reach main; no coverage enforcement"
fi
echo ""

# ── Question 8: Mutation Testing & Benchmarks ────────────────────────────────
printf '%b%b── Q8: Mutation Testing & Benchmarks ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Plan to use mutation testing (PIT, mutants)?"
dev_dim "  Performance benchmarks for critical paths?"
dev_dim "  When to run (pre-merge, nightly)?"
mutation=$(dev_ask "  Describe plans for mutation testing and benchmarks:")
if [ -z "$mutation" ]; then
  mutation="TBD — mutation testing and benchmarks not planned"
fi
echo ""

# ── Confirmation ─────────────────────────────────────────────────────────────
printf '\n%b%b── Confirm All Answers ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
printf '\n%b  Framework:%b %s\n' "$DEV_DIM" "$DEV_NC" "${framework:0:60}..."
printf '%b  Coverage:%b %s\n' "$DEV_DIM" "$DEV_NC" "${coverage:0:60}..."
printf '%b  Naming:%b %s\n' "$DEV_DIM" "$DEV_NC" "${naming:0:60}..."
printf '%b  Mocking:%b %s\n' "$DEV_DIM" "$DEV_NC" "${mocking:0:60}..."
printf '%b  Test Data:%b %s\n' "$DEV_DIM" "$DEV_NC" "${test_data:0:60}..."
printf '%b  Categories:%b %s\n' "$DEV_DIM" "$DEV_NC" "${categories:0:60}..."
printf '%b  CI/CD:%b %s\n' "$DEV_DIM" "$DEV_NC" "${ci_cd:0:60}..."
printf '%b  Mutation:%b %s\n\n' "$DEV_DIM" "$DEV_NC" "${mutation:0:60}..."

if dev_is_auto; then
  ready="yes"
else
  ready=$(dev_ask_yn "Write these to the unit test plan document?")
fi
if [ "$ready" = "no" ]; then
  printf '%b  Cancelled. No changes made.%b\n\n' "$DEV_YELLOW" "$DEV_NC"
  exit 0
fi

# ── Write output file ────────────────────────────────────────────────────────
{
  echo "# Unit Test Strategy — [Project Name]"
  echo ""
  echo "**Date:** $(date '+%Y-%m-%d')"
  echo "**Developer:** [Name]"
  echo "**Design Source:** dev-output/01-detailed-design.md"
  echo ""
  echo "## Overview"
  echo ""
  echo "This document specifies the testing framework, strategy, and coverage"
  echo "targets that will guide unit test development. It ensures consistent,"
  echo "maintainable tests that provide confidence in code quality."
  echo ""
  echo "---"
  echo ""
  echo "## Testing Framework & Tools"
  echo ""
  echo "**Framework (Q1):**"
  echo ""
  echo "${framework}"
  echo ""
  echo "---"
  echo ""
  echo "## Coverage Targets"
  echo ""
  echo "**Targets (Q2):**"
  echo ""
  echo "${coverage}"
  echo ""
  echo "---"
  echo ""
  echo "## Test Naming & Structure"
  echo ""
  echo "**Convention (Q3):**"
  echo ""
  echo "${naming}"
  echo ""
  echo "---"
  echo ""
  echo "## Mocking & Stubbing Strategy"
  echo ""
  echo "**Strategy (Q4):**"
  echo ""
  echo "${mocking}"
  echo ""
  echo "---"
  echo ""
  echo "## Test Data Strategy"
  echo ""
  echo "**Data (Q5):**"
  echo ""
  echo "${test_data}"
  echo ""
  echo "---"
  echo ""
  echo "## Test Categories & Execution"
  echo ""
  echo "**Categories (Q6):**"
  echo ""
  echo "${categories}"
  echo ""
  echo "---"
  echo ""
  echo "## CI/CD Integration"
  echo ""
  echo "**Gates & Strategy (Q7):**"
  echo ""
  echo "${ci_cd}"
  echo ""
  echo "---"
  echo ""
  echo "## Mutation Testing & Benchmarks"
  echo ""
  echo "**Advanced Testing (Q8):**"
  echo ""
  echo "${mutation}"
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

dev_success_rule "✅ Unit Test Strategy Complete"
printf '%b  Output:  %s%b\n' "$DEV_GREEN" "$OUTPUT_FILE" "$DEV_NC"
if [ "$new_ddebts" -gt 0 ]; then
  printf '%b  ⚠  %d design debt(s) logged to: %s%b\n' "$DEV_YELLOW" "$new_ddebts" "$DEV_DEBT_FILE" "$DEV_NC"
fi
echo ""
