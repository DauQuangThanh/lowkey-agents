#Requires -Version 5.1
# =============================================================================
# coding.ps1 — Phase 2: Coding Standards & Implementation Plan
# Establishes naming conventions, file structure, dependency management,
# branching strategy, code review criteria, and implementation sequencing.
# Writes output to $DEVOutputDir/02-coding-plan.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:DEV_AUTO = '1' }
if ($Answers) { $env:DEV_ANSWERS = $Answers }


$OutputFile = Join-Path $script:DEVOutputDir "02-coding-plan.md"
$Area = "Coding Standards"

$startDDebts = Get-DEV-DebtCount

Write-DEV-Banner "🛠  Phase 2 of 4 — Coding Standards & Implementation Plan"
Write-DEV-Dim "  Establish the conventions and sequencing that will keep code"
Write-DEV-Dim "  consistent and the team unblocked during implementation."
Write-Host ""

# ── Question 1: Naming Conventions ────────────────────────────────────────────
Write-Host "── Q1: Naming Conventions ──" -ForegroundColor Cyan
Write-DEV-Dim "  PascalCase vs camelCase for types/functions?"
Write-DEV-Dim "  Prefixes for interfaces? Suffixes for implementations?"
$naming = Ask-DEV-Text "  Describe your naming conventions (e.g., 'Classes: PascalCase, methods: camelCase, interfaces: IService'):"
if ([string]::IsNullOrWhiteSpace($naming)) {
  $naming = "TBD — naming conventions not yet decided"
  Add-DEV-Debt $Area "Naming conventions incomplete" `
    "No naming conventions established" `
    "Inconsistent naming across the codebase will make it harder to navigate"
}
Write-Host ""

# ── Question 2: File & Folder Structure ──────────────────────────────────────
Write-Host "── Q2: File & Folder Structure ──" -ForegroundColor Cyan
Write-DEV-Dim "  By layer (controllers/, services/, data/)?"
Write-DEV-Dim "  By feature (orders/, payments/)? Mixed? Maximum nesting depth?"
$structure = Ask-DEV-Text "  Describe your folder organization:"
if ([string]::IsNullOrWhiteSpace($structure)) {
  $structure = "TBD — folder structure not yet decided"
  Add-DEV-Debt $Area "Folder structure undefined" `
    "No file/folder organization pattern decided" `
    "Team will create ad-hoc file layouts; hard to onboard and navigate"
}
Write-Host ""

# ── Question 3: Dependency Management ────────────────────────────────────────
Write-Host "── Q3: Dependency Management ──" -ForegroundColor Cyan
Write-DEV-Dim "  Package manager (npm, pip, maven, cargo)?"
Write-DEV-Dim "  Version pinning (exact, minor, major)? Monorepo or separate?"
$deps = Ask-DEV-Text "  Describe dependency management strategy:"
if ([string]::IsNullOrWhiteSpace($deps)) {
  $deps = "TBD — dependency strategy not yet decided"
  Add-DEV-Debt $Area "Dependency management unclear" `
    "No dependency management or versioning strategy defined" `
    "Unexpected breaking changes or version conflicts in CI/CD"
}
Write-Host ""

# ── Question 4: Branching & Release Strategy ─────────────────────────────────
Write-Host "── Q4: Branching & Release Strategy ──" -ForegroundColor Cyan
Write-DEV-Dim "  Trunk-based dev with feature flags? GitFlow (develop/main)?"
Write-DEV-Dim "  Release cadence (continuous, weekly, sprint-based)?"
$branching = Ask-DEV-Text "  Describe your branching and release strategy:"
if ([string]::IsNullOrWhiteSpace($branching)) {
  $branching = "TBD — branching strategy not yet decided"
  Add-DEV-Debt $Area "Branching strategy undefined" `
    "No branching or release strategy agreed" `
    "Conflict-prone merges and unclear release process"
}
Write-Host ""

# ── Question 5: Code Review Checklist ────────────────────────────────────────
Write-Host "── Q5: Code Review Checklist ──" -ForegroundColor Cyan
Write-DEV-Dim "  What must every PR satisfy? (tests pass, coverage > 80%,"
Write-DEV-Dim "  no secrets, API docs updated, no new warnings)"
Write-DEV-Dim "  Who approves? Turnaround time?"
$codeReview = Ask-DEV-Text "  Describe your code review criteria and process:"
if ([string]::IsNullOrWhiteSpace($codeReview)) {
  $codeReview = "TBD — code review criteria not yet defined"
  Add-DEV-Debt $Area "Code review criteria missing" `
    "No code review checklist or criteria established" `
    "Inconsistent review quality and unpredictable merge delays"
}
Write-Host ""

# ── Question 6: Implementation Order / Priority ───────────────────────────────
Write-Host "── Q6: Implementation Order ──" -ForegroundColor Cyan
Write-DEV-Dim "  Given the modules and APIs, what's the logical build sequence?"
Write-DEV-Dim "  Which modules are blockers? Which are independent?"
$implOrder = Ask-DEV-Text "  Describe the implementation sequence and priorities:"
if ([string]::IsNullOrWhiteSpace($implOrder)) {
  $implOrder = "TBD — implementation order to be determined"
  Add-DEV-Debt $Area "Implementation order not planned" `
    "No implementation sequence or dependency tracking" `
    "Teams will work in parallel on blocked features"
}
Write-Host ""

# ── Question 7: Tech Debt Management ──────────────────────────────────────────
Write-Host "── Q7: Tech Debt Management ──" -ForegroundColor Cyan
Write-DEV-Dim "  How to track and prioritize tech debt items (DDEBT)?"
Write-DEV-Dim "  Refactor in-sprint, or dedicated 'debt sprints'?"
$techDebt = Ask-DEV-Text "  Describe your tech debt management approach:"
if ([string]::IsNullOrWhiteSpace($techDebt)) {
  $techDebt = "TBD — tech debt policy not yet established"
}
Write-Host ""

# ── Question 8: Testing in the Build ──────────────────────────────────────────
Write-Host "── Q8: Testing in the Build ──" -ForegroundColor Cyan
Write-DEV-Dim "  Unit tests must pass before commit? Integration tests in CI/CD?"
Write-DEV-Dim "  Performance tests? Compatibility matrix?"
$testing = Ask-DEV-Text "  Describe testing gates and CI/CD integration:"
if ([string]::IsNullOrWhiteSpace($testing)) {
  $testing = "TBD — testing strategy in build not yet defined"
  Add-DEV-Debt $Area "Testing in build undefined" `
    "No testing gates, coverage requirements, or CI/CD policy" `
    "Broken code reaching main; slow, unreliable builds"
}
Write-Host ""

# ── Confirmation ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Confirm All Answers ──" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Naming:           $($naming.Substring(0, [Math]::Min(60, $naming.Length)))..."
Write-Host "  Structure:        $($structure.Substring(0, [Math]::Min(60, $structure.Length)))..."
Write-Host "  Dependencies:     $($deps.Substring(0, [Math]::Min(60, $deps.Length)))..."
Write-Host "  Branching:        $($branching.Substring(0, [Math]::Min(60, $branching.Length)))..."
Write-Host "  Code Review:      $($codeReview.Substring(0, [Math]::Min(60, $codeReview.Length)))..."
Write-Host "  Impl Order:       $($implOrder.Substring(0, [Math]::Min(60, $implOrder.Length)))..."
Write-Host "  Tech Debt:        $($techDebt.Substring(0, [Math]::Min(60, $techDebt.Length)))..."
Write-Host "  Testing:          $($testing.Substring(0, [Math]::Min(60, $testing.Length)))..."
Write-Host ""

if (Test-DEV-Auto) {
  $ready = "yes"
} else {
  $ready = Ask-DEV-YN "Write these to the coding plan document?"
}
if ($ready -eq "no") {
  Write-Host "  Cancelled. No changes made." -ForegroundColor Yellow
  Write-Host ""
  exit 0
}

# ── Write output file ────────────────────────────────────────────────────────
$content = @"
# Coding Standards & Implementation Plan — [Project Name]

**Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Developer:** [Name]
**Design Source:** dev-output/01-detailed-design.md

## Overview

This document establishes the coding conventions and implementation
sequencing that will guide the team during development. It ensures
consistency, reduces cognitive load, and makes code reviews faster.

---

## Naming Conventions

**Convention (Q1):**

$naming

---

## File & Folder Structure

**Organization (Q2):**

$structure

---

## Dependency Management

**Strategy (Q3):**

$deps

---

## Branching & Release Strategy

**Strategy (Q4):**

$branching

---

## Code Review Checklist

**Criteria (Q5):**

$codeReview

---

## Implementation Order & Priorities

**Sequence (Q6):**

$implOrder

---

## Tech Debt Management

**Policy (Q7):**

$techDebt

---

## Testing in the Build

**Gates & CI/CD (Q8):**

$testing

---

## Known Unknowns / Design Debts

_See 05-design-debts.md_

"@

Set-Content -Path $OutputFile -Value $content

Write-Host "  ✅ Saved: $OutputFile" -ForegroundColor Green
Write-Host ""

$endDDebts = Get-DEV-DebtCount
$newDDebts = $endDDebts - $startDDebts

Write-DEV-SuccessRule "✅ Coding Standards Complete"
Write-Host "  Output:  $OutputFile" -ForegroundColor Green
if ($newDDebts -gt 0) {
  Write-Host "  ⚠  $newDDebts design debt(s) logged to: $script:DEVDebtFile" -ForegroundColor Yellow
}
Write-Host ""
