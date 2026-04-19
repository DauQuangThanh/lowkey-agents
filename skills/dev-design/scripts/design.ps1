#Requires -Version 5.1
# =============================================================================
# design.ps1 — Phase 1: Detailed Design
# Translates architecture diagrams into module/class structures, API contracts,
# database schemas, async flows, sequence diagrams, and dependency graphs.
# Writes output to $DEVOutputDir/01-detailed-design.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:DEV_AUTO = '1' }
if ($Answers) { $env:DEV_ANSWERS = $Answers }


$OutputFile = Join-Path $script:DEVOutputDir "01-detailed-design.md"
$Area = "Detailed Design"

$startDDebts = Get-DEV-DebtCount

Write-DEV-Banner "📐  Phase 1 of 4 — Detailed Design"
Write-DEV-Dim "  Translate the architecture diagrams and ADRs into module/class"
Write-DEV-Dim "  structures, API contracts, database schemas, and sequence diagrams."
Write-Host ""

# Check for architecture input
$archFile = Join-Path $script:DEVArchInputDir "04-architecture.md"
if (Test-Path $archFile) {
  Write-Host "  ✓ Found architecture documentation in: $script:DEVArchInputDir" -ForegroundColor Green
  Write-Host ""
  $confirm = Ask-DEV-YN "Use this architecture as the basis for design?"
  if ($confirm -eq "no") {
    Write-Host "  ⚠  Proceeding without architecture baseline." -ForegroundColor Yellow
    Write-Host ""
  }
} else {
  Write-Host "  ⚠  No architecture.md found in $script:DEVArchInputDir" -ForegroundColor Yellow
  Write-Host "  Recommend running the architect subagent first." -ForegroundColor Yellow
  Write-Host ""
}

# ── Question 1: Module Breakdown ─────────────────────────────────────────────
Write-Host "── Q1: Module Breakdown ──" -ForegroundColor Cyan
Write-DEV-Dim "  For each Container from the C4 diagram, list the 3–5 major modules."
Write-DEV-Dim "  Example: Orders, Inventory, Payments, Reporting, Auth"
$modules = Ask-DEV-Text "  List your modules (comma-separated):"
if ([string]::IsNullOrWhiteSpace($modules)) {
  $modules = "TBD — modules not yet identified"
  Add-DEV-Debt $Area "Module breakdown incomplete" `
    "Modules were not identified or captured" `
    "Cannot proceed with class design without clear module boundaries"
}
Write-Host ""

# ── Question 2: Class/Component Structure ────────────────────────────────────
Write-Host "── Q2: Class/Component Structure ──" -ForegroundColor Cyan
Write-DEV-Dim "  Sketch the key classes/types per module: controllers, services,"
Write-DEV-Dim "  repositories, domain models, validators, adapters."
Write-DEV-Dim "  Pattern preference? (Layered, Hexagonal/Ports&Adapters, CQRS, etc.)"
$classStructure = Ask-DEV-Text "  Describe the structure (e.g. 'Layered: Presentation/Domain/Data' or 'Hexagonal'):"
if ([string]::IsNullOrWhiteSpace($classStructure)) {
  $classStructure = "TBD — class structure not yet decided"
  Add-DEV-Debt $Area "Class/component structure incomplete" `
    "No class structure or pattern decided" `
    "Developers will not know how to organize code into classes"
}
Write-Host ""

# ── Question 3: API Endpoints / Interface Contracts ──────────────────────────
Write-Host "── Q3: API Endpoints / Interface Contracts ──" -ForegroundColor Cyan
Write-DEV-Dim "  List the major API endpoints (REST, gRPC, messages)."
Write-DEV-Dim "  For each: method + path, input schema, output schema, auth, errors."
$apiEndpoints = Ask-DEV-Text "  Describe the top 5–10 endpoints (can be brief; refine later):"
if ([string]::IsNullOrWhiteSpace($apiEndpoints)) {
  $apiEndpoints = "TBD — endpoints not yet listed"
  Add-DEV-Debt $Area "API endpoints not designed" `
    "No API endpoints or interface contracts captured" `
    "Frontend and backend teams cannot design in parallel"
}
Write-Host ""

# ── Question 4: Database Schema ──────────────────────────────────────────────
Write-Host "── Q4: Database Schema ──" -ForegroundColor Cyan
Write-DEV-Dim "  Sketch the logical data model: entities, relationships, cardinality."
Write-DEV-Dim "  Which tables are write-heavy vs. read-heavy? Denormalization needed?"
$dbSchema = Ask-DEV-Text "  Describe the main tables/collections and relationships:"
if ([string]::IsNullOrWhiteSpace($dbSchema)) {
  $dbSchema = "TBD — database schema not yet designed"
  Add-DEV-Debt $Area "Database schema incomplete" `
    "No database schema designed" `
    "Data layer implementation cannot start without schema"
}
Write-Host ""

# ── Question 5: Async/Event Design ───────────────────────────────────────────
Write-Host "── Q5: Async/Event Design ──" -ForegroundColor Cyan
Write-DEV-Dim "  What work should happen asynchronously (email, audit, data sync)?"
Write-DEV-Dim "  Message queue? Event log? Webhooks? Consistency guarantees?"
$asyncDesign = Ask-DEV-Text "  Describe async flows and event/message patterns:"
if ([string]::IsNullOrWhiteSpace($asyncDesign)) {
  $asyncDesign = "TBD — async design not yet decided (assume synchronous for now)"
}
Write-Host ""

# ── Question 6: Cross-Cutting Concerns ───────────────────────────────────────
Write-Host "── Q6: Cross-Cutting Concerns ──" -ForegroundColor Cyan
Write-DEV-Dim "  Logging, error handling, auth/authz, caching, feature flags."
Write-DEV-Dim "  Where do these live in the module tree?"
$crossCutting = Ask-DEV-Text "  Describe cross-cutting concerns and their location:"
if ([string]::IsNullOrWhiteSpace($crossCutting)) {
  $crossCutting = "TBD — cross-cutting patterns to be defined"
  Add-DEV-Debt $Area "Cross-cutting concerns not specified" `
    "No logging, error handling, or auth patterns defined" `
    "Each developer will implement these differently"
}
Write-Host ""

# ── Question 7: Sequence Diagrams for Critical Flows ────────────────────────
Write-Host "── Q7: Sequence Diagrams ──" -ForegroundColor Cyan
Write-DEV-Dim "  For the top 3–4 critical flows (e.g. checkout, auth, search),"
Write-DEV-Dim "  sketch the call sequence across modules and services."
$sequences = Ask-DEV-Text "  List critical flows and briefly sketch their sequences:"
if ([string]::IsNullOrWhiteSpace($sequences)) {
  $sequences = "TBD — sequence diagrams to be created"
  Add-DEV-Debt $Area "Sequence diagrams not captured" `
    "No flows or sequence diagrams sketched" `
    "Developers may not understand call ordering and dependencies"
}
Write-Host ""

# ── Question 8: Dependency Map ───────────────────────────────────────────────
Write-Host "── Q8: Dependency Map ──" -ForegroundColor Cyan
Write-DEV-Dim "  Which modules can depend on which others? Circular dependencies?"
Write-DEV-Dim "  What's the natural build/implementation order?"
$depMap = Ask-DEV-Text "  Describe the module dependency graph and build order:"
if ([string]::IsNullOrWhiteSpace($depMap)) {
  $depMap = "TBD — dependency map to be determined"
  Add-DEV-Debt $Area "Module dependencies not mapped" `
    "No dependency graph or build order established" `
    "Implementation sequencing will be unclear"
}
Write-Host ""

# ── Confirmation ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Confirm All Answers ──" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Modules:             $($modules.Substring(0, [Math]::Min(60, $modules.Length)))..."
Write-Host "  Class Structure:     $($classStructure.Substring(0, [Math]::Min(60, $classStructure.Length)))..."
Write-Host "  API Endpoints:       $($apiEndpoints.Substring(0, [Math]::Min(60, $apiEndpoints.Length)))..."
Write-Host "  Database:            $($dbSchema.Substring(0, [Math]::Min(60, $dbSchema.Length)))..."
Write-Host "  Async Flows:         $($asyncDesign.Substring(0, [Math]::Min(60, $asyncDesign.Length)))..."
Write-Host "  Cross-Cutting:       $($crossCutting.Substring(0, [Math]::Min(60, $crossCutting.Length)))..."
Write-Host "  Sequences:           $($sequences.Substring(0, [Math]::Min(60, $sequences.Length)))..."
Write-Host "  Dependencies:        $($depMap.Substring(0, [Math]::Min(60, $depMap.Length)))..."
Write-Host ""

if (Test-DEV-Auto) {
  $ready = "yes"
} else {
  $ready = Ask-DEV-YN "Write these to the design document?"
}
if ($ready -eq "no") {
  Write-Host "  Cancelled. No changes made." -ForegroundColor Yellow
  Write-Host ""
  exit 0
}

# ── Write output file ────────────────────────────────────────────────────────
$content = @"
# Detailed Design — [Project Name]

**Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Developer:** [Name]
**Architecture Source:** arch-output/ (see 04-architecture.md)

## Overview

This document translates the C4 architecture diagrams and ADRs into concrete
module/class structures, API contracts, database schemas, and implementation
sequences. It serves as the blueprint for code implementation.

---

## Module Breakdown

**Modules (Q1):**

$modules

---

## Class / Component Structure

**Pattern (Q2):**

$classStructure

---

## API Endpoints & Interface Contracts

**Endpoints (Q3):**

$apiEndpoints

---

## Database Schema

**Schema (Q4):**

$dbSchema

---

## Async / Event Flows

**Flows (Q5):**

$asyncDesign

---

## Cross-Cutting Concerns

**Concerns (Q6):**

$crossCutting

---

## Sequence Diagrams

**Critical Flows (Q7):**

$sequences

---

## Module Dependency Graph

**Dependencies (Q8):**

$depMap

---

## Known Unknowns / Design Debts

_See 05-design-debts.md_

"@

Set-Content -Path $OutputFile -Value $content

Write-Host "  ✅ Saved: $OutputFile" -ForegroundColor Green
Write-Host ""

$endDDebts = Get-DEV-DebtCount
$newDDebts = $endDDebts - $startDDebts

Write-DEV-SuccessRule "✅ Detailed Design Complete"
Write-Host "  Output:  $OutputFile" -ForegroundColor Green
if ($newDDebts -gt 0) {
  Write-Host "  ⚠  $newDDebts design debt(s) logged to: $script:DEVDebtFile" -ForegroundColor Yellow
}
Write-Host ""
