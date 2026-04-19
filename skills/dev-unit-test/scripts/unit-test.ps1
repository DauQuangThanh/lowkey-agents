#Requires -Version 5.1
# =============================================================================
# unit-test.ps1 — Phase 3: Unit Test Strategy & Generation
# Designs testable architecture, specifies framework, coverage targets,
# mocking strategy, test data, categories, and CI/CD integration.
# Writes output to $DEVOutputDir/03-unit-test-plan.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:DEV_AUTO = '1' }
if ($Answers) { $env:DEV_ANSWERS = $Answers }


$OutputFile = Join-Path $script:DEVOutputDir "03-unit-test-plan.md"
$Area = "Unit Test Strategy"

$startDDebts = Get-DEV-DebtCount

Write-DEV-Banner "🧪  Phase 3 of 4 — Unit Test Strategy"
Write-DEV-Dim "  Design a testable architecture and specify testing framework,"
Write-DEV-Dim "  coverage targets, mocking strategy, and CI/CD integration."
Write-Host ""

# ── Question 1: Testing Framework ────────────────────────────────────────────
Write-Host "── Q1: Testing Framework ──" -ForegroundColor Cyan
Write-DEV-Dim "  Language-specific: Jest/Vitest (JS), Pytest/Unittest (Python),"
Write-DEV-Dim "  JUnit/Mockito (Java), Xunit (.NET), etc."
Write-DEV-Dim "  Assertion library? BDD (Gherkin) or TDD?"
$framework = Ask-DEV-Text "  What testing framework and assertion library?"
if ([string]::IsNullOrWhiteSpace($framework)) {
  $framework = "TBD — testing framework not yet chosen"
  Add-DEV-Debt $Area "Testing framework not chosen" `
    "No testing framework or assertion library selected" `
    "Cannot begin writing unit tests without framework decision"
}
Write-Host ""

# ── Question 2: Coverage Target ──────────────────────────────────────────────
Write-Host "── Q2: Coverage Target ──" -ForegroundColor Cyan
Write-DEV-Dim "  Minimum %? Different targets per module?"
Write-DEV-Dim "  Example: Overall 80%, Core Domain 95%, UI 60%"
Write-DEV-Dim "  Line coverage, branch coverage, or path coverage?"
$coverage = Ask-DEV-Text "  What are your coverage targets?"
if ([string]::IsNullOrWhiteSpace($coverage)) {
  $coverage = "TBD — coverage targets not yet defined"
  Add-DEV-Debt $Area "Coverage targets undefined" `
    "No coverage targets or metrics defined" `
    "Unclear what level of testing is expected"
}
Write-Host ""

# ── Question 3: Test Naming & Structure ──────────────────────────────────────
Write-Host "── Q3: Test Naming & Structure ──" -ForegroundColor Cyan
Write-DEV-Dim "  Convention: test<MethodName>_<Scenario>_<Expected>?"
Write-DEV-Dim "  One test class per class under test?"
Write-DEV-Dim "  Fixtures shared or isolated?"
$naming = Ask-DEV-Text "  Describe your test naming and structure conventions:"
if ([string]::IsNullOrWhiteSpace($naming)) {
  $naming = "TBD — test naming conventions not yet decided"
  Add-DEV-Debt $Area "Test naming conventions undefined" `
    "No test naming or structure convention established" `
    "Inconsistent test organization makes maintenance harder"
}
Write-Host ""

# ── Question 4: What to Mock / Stub ──────────────────────────────────────────
Write-Host "── Q4: What to Mock / Stub ──" -ForegroundColor Cyan
Write-DEV-Dim "  Mock external services (APIs, DBs, message queues)?"
Write-DEV-Dim "  Use in-memory doubles or real test containers (Testcontainers)?"
Write-DEV-Dim "  Spy on side effects (logging, events)?"
$mocking = Ask-DEV-Text "  Describe your mocking and stubbing strategy:"
if ([string]::IsNullOrWhiteSpace($mocking)) {
  $mocking = "TBD — mocking strategy not yet decided"
  Add-DEV-Debt $Area "Mocking strategy undefined" `
    "No mocking or stubbing approach defined" `
    "Tests will be brittle or slow; unclear test dependencies"
}
Write-Host ""

# ── Question 5: Test Data Strategy ───────────────────────────────────────────
Write-Host "── Q5: Test Data Strategy ──" -ForegroundColor Cyan
Write-DEV-Dim "  Fixtures hardcoded in tests? Factories? Builders?"
Write-DEV-Dim "  Realistic/representative data or minimal?"
Write-DEV-Dim "  Seeding for integration tests?"
$testData = Ask-DEV-Text "  Describe your test data strategy:"
if ([string]::IsNullOrWhiteSpace($testData)) {
  $testData = "TBD — test data strategy not yet planned"
  Add-DEV-Debt $Area "Test data strategy undefined" `
    "No approach for test data generation or fixtures" `
    "Tests will be fragile and hard to maintain"
}
Write-Host ""

# ── Question 6: Test Categories & Execution ──────────────────────────────────
Write-Host "── Q6: Test Categories & Execution ──" -ForegroundColor Cyan
Write-DEV-Dim "  Unit (no IO, < 1s), Integration (< 10s), Smoke, E2E (slow)?"
Write-DEV-Dim "  How to tag/organize? Run all on every commit?"
Write-DEV-Dim "  Parallel execution? Fail-fast strategy?"
$categories = Ask-DEV-Text "  Describe your test categories and execution strategy:"
if ([string]::IsNullOrWhiteSpace($categories)) {
  $categories = "TBD — test categories not yet organized"
  Add-DEV-Debt $Area "Test categories undefined" `
    "No distinction between unit, integration, E2E tests" `
    "Long feedback loop; slow CI/CD pipeline"
}
Write-Host ""

# ── Question 7: CI/CD Integration ────────────────────────────────────────────
Write-Host "── Q7: CI/CD Integration ──" -ForegroundColor Cyan
Write-DEV-Dim "  Run all tests on every push? Parallel execution?"
Write-DEV-Dim "  Fail on coverage drop? Flaky test tolerance?"
Write-DEV-Dim "  What tests block merge vs. inform vs. optional?"
$ciCd = Ask-DEV-Text "  Describe your CI/CD testing gates and strategy:"
if ([string]::IsNullOrWhiteSpace($ciCd)) {
  $ciCd = "TBD — CI/CD testing gates not yet defined"
  Add-DEV-Debt $Area "CI/CD testing gates undefined" `
    "No automated testing gates in CI/CD pipeline" `
    "Broken code may reach main; no coverage enforcement"
}
Write-Host ""

# ── Question 8: Mutation Testing & Benchmarks ────────────────────────────────
Write-Host "── Q8: Mutation Testing & Benchmarks ──" -ForegroundColor Cyan
Write-DEV-Dim "  Plan to use mutation testing (PIT, mutants)?"
Write-DEV-Dim "  Performance benchmarks for critical paths?"
Write-DEV-Dim "  When to run (pre-merge, nightly)?"
$mutation = Ask-DEV-Text "  Describe plans for mutation testing and benchmarks:"
if ([string]::IsNullOrWhiteSpace($mutation)) {
  $mutation = "TBD — mutation testing and benchmarks not planned"
}
Write-Host ""

# ── Confirmation ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Confirm All Answers ──" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Framework:       $($framework.Substring(0, [Math]::Min(60, $framework.Length)))..."
Write-Host "  Coverage:        $($coverage.Substring(0, [Math]::Min(60, $coverage.Length)))..."
Write-Host "  Naming:          $($naming.Substring(0, [Math]::Min(60, $naming.Length)))..."
Write-Host "  Mocking:         $($mocking.Substring(0, [Math]::Min(60, $mocking.Length)))..."
Write-Host "  Test Data:       $($testData.Substring(0, [Math]::Min(60, $testData.Length)))..."
Write-Host "  Categories:      $($categories.Substring(0, [Math]::Min(60, $categories.Length)))..."
Write-Host "  CI/CD:           $($ciCd.Substring(0, [Math]::Min(60, $ciCd.Length)))..."
Write-Host "  Mutation:        $($mutation.Substring(0, [Math]::Min(60, $mutation.Length)))..."
Write-Host ""

if (Test-DEV-Auto) {
  $ready = "yes"
} else {
  $ready = Ask-DEV-YN "Write these to the unit test plan document?"
}
if ($ready -eq "no") {
  Write-Host "  Cancelled. No changes made." -ForegroundColor Yellow
  Write-Host ""
  exit 0
}

# ── Write output file ────────────────────────────────────────────────────────
$content = @"
# Unit Test Strategy — [Project Name]

**Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Developer:** [Name]
**Design Source:** dev-output/01-detailed-design.md

## Overview

This document specifies the testing framework, strategy, and coverage
targets that will guide unit test development. It ensures consistent,
maintainable tests that provide confidence in code quality.

---

## Testing Framework & Tools

**Framework (Q1):**

$framework

---

## Coverage Targets

**Targets (Q2):**

$coverage

---

## Test Naming & Structure

**Convention (Q3):**

$naming

---

## Mocking & Stubbing Strategy

**Strategy (Q4):**

$mocking

---

## Test Data Strategy

**Data (Q5):**

$testData

---

## Test Categories & Execution

**Categories (Q6):**

$categories

---

## CI/CD Integration

**Gates & Strategy (Q7):**

$ciCd

---

## Mutation Testing & Benchmarks

**Advanced Testing (Q8):**

$mutation

---

## Known Unknowns / Design Debts

_See 05-design-debts.md_

"@

Set-Content -Path $OutputFile -Value $content

Write-Host "  ✅ Saved: $OutputFile" -ForegroundColor Green
Write-Host ""

$endDDebts = Get-DEV-DebtCount
$newDDebts = $endDDebts - $startDDebts

Write-DEV-SuccessRule "✅ Unit Test Strategy Complete"
Write-Host "  Output:  $OutputFile" -ForegroundColor Green
if ($newDDebts -gt 0) {
  Write-Host "  ⚠  $newDDebts design debt(s) logged to: $script:DEVDebtFile" -ForegroundColor Yellow
}
Write-Host ""
