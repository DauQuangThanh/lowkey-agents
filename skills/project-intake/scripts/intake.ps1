# =============================================================================
# intake.ps1 — Phase 1: Project Intake (PowerShell)
# Output: $BAOutputDir\01-project-intake.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$OutputFile = Join-Path $script:BAOutputDir "01-project-intake.md"
$Area       = "Project Intake"

$startDebts = Get-BA-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "📋  Step 1 of 7 — Project Intake"
Write-BA-Dim "  Let's start with the basics. I'll ask you a series of simple questions."
Write-BA-Dim "  There are no wrong answers — just share what you know."
Write-Host ""

# ── Q1: Project name ─────────────────────────────────────────────────────────
Write-Host "Question 1 / 8 — Project Name" -ForegroundColor Cyan
$ProjectName = Get-BA-Answer -Key "PROJECT_NAME" -Prompt "What is the name of this project? (e.g. 'Customer Portal', 'Inventory App')"
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = "Unnamed Project"
  Add-BA-Debt -Area $Area -Title "Project name not provided" `
    -Description "Project has no confirmed name" `
    -Impact "Branding, documentation, and team communication"
}

# ── Q2: Problem statement ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 8 — The Problem" -ForegroundColor Cyan
Write-BA-Dim "  In one or two sentences, what problem are you trying to solve?"
Write-BA-Dim "  Example: 'Our team tracks orders in spreadsheets and keeps losing data.'"
Write-Host ""
$Problem = Get-BA-Answer -Key "PROBLEM" -Prompt "Your answer:"
if ([string]::IsNullOrWhiteSpace($Problem)) {
  $Problem = "TBD"
  Add-BA-Debt -Area $Area -Title "Problem statement not defined" `
    -Description "The core problem this project solves is not documented" `
    -Impact "All requirements are anchored to the problem statement"
}

# ── Q3: Methodology ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 8 — Development Approach" -ForegroundColor Cyan
Write-BA-Dim "  How will the team build this project? (If unsure, choose the last option.)"
Write-Host ""
$Methodology = Get-BA-Choice -Key "METHODOLOGY" -Prompt "Select one:" -Options @(
  "Agile / Scrum — Work in short 2-week sprints with regular reviews",
  "Kanban — Continuous flow of work with no fixed sprints",
  "Waterfall — Plan everything first, then build in sequence",
  "Hybrid — Mix of structured planning and flexible delivery",
  "Not decided yet"
)
if ($Methodology -eq "Not decided yet") {
  Add-BA-Debt -Area $Area -Title "Methodology not selected" `
    -Description "Development approach has not been chosen" `
    -Impact "Sprint planning, ceremony setup, and release cadence"
}

# ── Q4: Timeline ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 8 — Estimated Timeline" -ForegroundColor Cyan
Write-Host ""
$Timeline = Get-BA-Choice -Key "TIMELINE" -Prompt "How long do you expect this project to take?" -Options @(
  "Less than 1 month",
  "1 to 3 months",
  "3 to 6 months",
  "6 to 12 months",
  "More than 1 year"
)

# ── Q5: Hard deadline ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 8 — Hard Deadline" -ForegroundColor Cyan
# HARD_DEADLINE is either a date string, "None", or empty. Treat non-empty
# values other than "None" as the actual deadline.
$Deadline = Get-BA-Answer -Key "HARD_DEADLINE" -Prompt "What is the hard deadline? (e.g. 31 Dec 2026, or 'None')" -Default "None"
if ([string]::IsNullOrWhiteSpace($Deadline)) { $Deadline = "None" }

# ── Q6: Team size ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 8 — Team Size" -ForegroundColor Cyan
Write-Host ""
$TeamSize = Get-BA-Choice -Key "TEAM_SIZE" -Prompt "How many people will work on this project?" -Options @(
  "Just me — I'm working alone",
  "2 to 5 people — Small team",
  "6 to 15 people — Medium team",
  "More than 15 people — Large team"
)

# ── Q7: Budget ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 7 / 8 — Budget" -ForegroundColor Cyan
# BUDGET can be "Not specified" (no limit), a specific range, or any freeform value.
$Budget = Get-BA-Answer -Key "BUDGET" -Prompt "What is the approximate budget range? (or 'Not specified')" -Default "Not specified"
if ([string]::IsNullOrWhiteSpace($Budget)) { $Budget = "Not specified" }

# ── Q8: Out of scope ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 8 / 8 — What is OUT of scope?" -ForegroundColor Cyan
Write-BA-Dim "  Is there anything people might expect but should NOT be included?"
Write-BA-Dim "  Example: 'We are NOT building a mobile app in version 1.'"
Write-BA-Dim "  (Press Enter to skip if nothing comes to mind)"
Write-Host ""
$OutOfScope = Get-BA-Answer -Key "OUT_OF_SCOPE" -Prompt "Your answer:"
if ([string]::IsNullOrWhiteSpace($OutOfScope)) { $OutOfScope = "To be defined" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-BA-SuccessRule "✅ Project Intake Summary"
Write-Host "  Project:      $ProjectName"
Write-Host "  Problem:      $Problem"
Write-Host "  Approach:     $Methodology"
Write-Host "  Timeline:     $Timeline"
Write-Host "  Deadline:     $Deadline"
Write-Host "  Team size:    $TeamSize"
Write-Host "  Budget:       $Budget"
Write-Host "  Out of scope: $OutOfScope"
Write-Host ""

if (-not (Confirm-BA-Save "Does this look correct? (y=save / n=redo)")) {
  Write-BA-Dim "  Restarting step 1..."
  & $PSCommandPath
  return
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$content = @"
# Project Intake

> Captured: $DateNow

## Project Overview

| Field | Value |
|---|---|
| **Project Name** | $ProjectName |
| **Methodology** | $Methodology |
| **Timeline** | $Timeline |
| **Hard Deadline** | $Deadline |
| **Team Size** | $TeamSize |
| **Budget** | $Budget |

## Problem Statement

$Problem

## Out of Scope

$OutOfScope

"@
$content | Set-Content -Path $OutputFile -Encoding UTF8

$extractFile = [System.IO.Path]::ChangeExtension($OutputFile, "extract")
Write-BA-Extract -Path $extractFile -Pairs @{
  "PROJECT_NAME"  = $ProjectName
  "PROBLEM"       = $Problem
  "METHODOLOGY"   = $Methodology
  "TIMELINE"      = $Timeline
  "HARD_DEADLINE" = $Deadline
  "TEAM_SIZE"     = $TeamSize
  "BUDGET"        = $Budget
  "OUT_OF_SCOPE"  = $OutOfScope
}

$endDebts = Get-BA-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host ""
Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newDebts -gt 0) {
  Write-Host "  ⚠  $newDebts requirement debt(s) logged to: $script:BADebtFile" -ForegroundColor Yellow
}
Write-Host ""
