#requires -version 5.1

# =============================================================================
# sprint-planning.ps1 — Phase 1: Sprint Planning
# Facilitates sprint planning with goal, capacity, story commitment, DoD review.
# Output: $script:SMOutputDir\01-sprint-plan.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:SM_AUTO = '1' }
if ($Answers) { $env:SM_ANSWERS = $Answers }


$OutputFile = Join-Path $script:SMOutputDir "01-sprint-plan.md"
$Area = "Sprint Planning"

$startDebts = Get-SM-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-SM-Banner "Phase 1 of 5 — Sprint Planning"
Write-SM-Dim "Let's plan this sprint together. I'll ask about goals, capacity, and scope."
Write-SM-Dim "You can also load stories from your backlog if they exist."
Write-Host ""

# ── Q1: Sprint number and goal ─────────────────────────────────────────────────
Write-Host "Question 1 / 8 — Sprint Identification" -ForegroundColor Cyan -BackgroundColor DarkCyan
$sprintNum = Ask-SM-Text "What sprint number is this? (e.g. 1, 2, Sprint-Q2-2026)"
if ([string]::IsNullOrWhiteSpace($sprintNum)) { $sprintNum = "Sprint-TBD" }

Write-Host ""
Write-Host "Question 2 / 8 — Sprint Goal" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "A sprint goal is ONE sentence that captures the team's focus."
Write-SM-Dim "Example: 'Complete user authentication and basic dashboard.'"
Write-Host ""
$sprintGoal = Ask-SM-Text "What is the sprint goal?"
if ([string]::IsNullOrWhiteSpace($sprintGoal)) {
  $sprintGoal = "TBD"
  Add-SM-Debt $Area "Sprint goal not defined" `
    "No clear sprint goal established" `
    "Team alignment and sprint focus"
}

# ── Q3: Sprint duration ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 8 — Sprint Duration" -ForegroundColor Cyan -BackgroundColor DarkCyan
$duration = Ask-SM-Choice "How long is this sprint?" @(
  "1 week",
  "2 weeks",
  "3 weeks",
  "4 weeks"
)

# Calculate sprint dates
$startDate = (Get-Date).ToString("yyyy-MM-dd")
$endDate = switch ($duration) {
  "1 week"  { (Get-Date).AddDays(7).ToString("yyyy-MM-dd") }
  "2 weeks" { (Get-Date).AddDays(14).ToString("yyyy-MM-dd") }
  "3 weeks" { (Get-Date).AddDays(21).ToString("yyyy-MM-dd") }
  "4 weeks" { (Get-Date).AddDays(28).ToString("yyyy-MM-dd") }
}

# ── Q4: Team capacity ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 8 — Team Capacity" -ForegroundColor Cyan -BackgroundColor DarkCyan
$capacityType = Ask-SM-Choice "How will you measure team capacity?" @(
  "Story points per sprint",
  "Team hours available",
  "Number of stories"
)

Write-Host ""
$teamCapacity = Ask-SM-Text "What is the team's total available capacity? (e.g. 40 points, 160 hours, 8 stories)"
if ([string]::IsNullOrWhiteSpace($teamCapacity)) {
  $teamCapacity = "TBD"
  Add-SM-Debt $Area "Team capacity not estimated" `
    "No capacity baseline established for sprint" `
    "Scope definition and commitment decisions"
}

# ── Q5: Committed stories ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 8 — Stories to Commit" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "List the user stories you're committing to this sprint."
Write-SM-Dim "You can paste story IDs, titles, or descriptions. One per line."
Write-SM-Dim "(Press Enter twice when done)"
Write-Host ""

$stories = @()
while ($true) {
  $story = Ask-SM-Text "Story (or blank to finish)"
  if ([string]::IsNullOrWhiteSpace($story)) { break }
  $stories += "- $story"
}

if ($stories.Count -eq 0) { $stories = "(To be added)" }

# ── Q6: Acceptance criteria ────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 8 — Acceptance Criteria Review" -ForegroundColor Cyan -BackgroundColor DarkCyan
$acReview = Ask-SM-YN "Have all committed stories been reviewed for acceptance criteria?"
if ($acReview -eq "no") {
  Add-SM-Debt $Area "Acceptance criteria incomplete" `
    "Stories lack clear acceptance criteria" `
    "Development clarity and testing readiness"
}

# ── Q7: Definition of Done ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 7 / 8 — Definition of Done (DoD)" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "Does the team have a clear Definition of Done? (What makes a story complete?)"
Write-Host ""
$dodConfirmed = Ask-SM-YN "Is the DoD clearly documented and understood by the team?"
$dodText = "(To be documented)"
if ($dodConfirmed -eq "yes") {
  $dodText = "✅ Team has confirmed DoD. Closing ceremony will verify all work meets criteria."
}

# ── Q8: Sprint risks ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 8 / 8 — Known Risks" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "Are there any known risks, blockers, or dependencies for this sprint?"
Write-Host ""

$risks = @()
while ($true) {
  $risk = Ask-SM-Text "Risk / Blocker (or blank to finish)"
  if ([string]::IsNullOrWhiteSpace($risk)) { break }
  $risks += "- $risk"
}

if ($risks.Count -eq 0) { $risks = "None identified" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-SM-SuccessRule "✅ Sprint Planning Summary"
Write-Host ("  Sprint:         {0}" -f $sprintNum)
Write-Host ("  Goal:           {0}" -f $sprintGoal)
Write-Host ("  Duration:       {0} ({1} to {2})" -f $duration, $startDate, $endDate)
Write-Host ("  Capacity:       {0} ({1})" -f $teamCapacity, $capacityType)
Write-Host ("  Stories:        {0} committed" -f $stories.Count)
Write-Host ""

if (-not (Confirm-SM-Save "Does this look correct? (y=save / n=redo)")) {
  Write-SM-Dim "Restarting Phase 1..."
  & $PSScriptRoot\sprint-planning.ps1
  exit 0
}

# ── Write output ──────────────────────────────────────────────────────────────
$dateNow = (Get-Date).ToString("yyyy-MM-dd HH:mm")
$storiesText = if ($stories -is [array]) { $stories -join "`n" } else { $stories }
$risksText = if ($risks -is [array]) { $risks -join "`n" } else { $risks }

$output = @"
# Sprint Planning

> Captured: $dateNow

## Sprint Overview

**Sprint:** $sprintNum
**Duration:** $duration ($startDate → $endDate)
**Goal:** $sprintGoal

## Team Capacity

**Measurement:** $capacityType
**Available Capacity:** $teamCapacity

## Committed Stories

$storiesText

## Quality Standards

**Acceptance Criteria:** $acReview
**Definition of Done:** $dodText

## Sprint Risks & Dependencies

$risksText

---

## Sprint Health Baseline

| Metric | Value |
|--------|-------|
| Capacity | $teamCapacity |
| Scope Locked | $(if ($stories.Count -eq 0) { "No" } else { "Yes" }) |
| DoD Confirmed | $dodConfirmed |
| Risks Identified | $(if ($risks[0] -eq "None identified") { "No" } else { "Yes" }) |

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8
Write-SM-SuccessRule "✅ Sprint plan saved to $OutputFile"

$endDebts = Get-SM-DebtCount
$newDebts = $endDebts - $startDebts
if ($newDebts -gt 0) {
  Write-SM-Dim "  ⚠️  $newDebts new debt(s) created. Review in $script:SMDebtFile"
}
