# =============================================================================
# planning.ps1 — Phase 1: Project Planning (PowerShell)
# Captures: project name, methodology, WBS, milestones, dependencies,
# resource allocation, communication cadence, and definition of done.
# Output: pm-output/01-project-plan.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load common helpers
. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PM_AUTO = '1' }
if ($Answers) { $env:PM_ANSWERS = $Answers }


# ── Try to load project context from ba-output if it exists ──────────────────
$baIntakeFile = Join-Path (Split-Path (Split-Path $PSScriptRoot)) ".." "ba-output" "01-project-intake.md"
$projectName = ""
$methodology = ""

if (Test-Path $baIntakeFile) {
  Write-PM-Dim "Found Business Analyst context at $baIntakeFile"
  $content = Get-Content $baIntakeFile -Raw
  if ($content -match '# Project: (.+)') {
    $projectName = $matches[1].Trim()
  }
  if ($content -match '\*\*Methodology:\*\*\s+(.+)') {
    $methodology = $matches[1].Trim()
  }
}

Write-PM-Banner "Phase 1: Project Planning"

# ── Question 1: Project Name ──────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($projectName)) {
  $projectName = Ask-PM-Text "What is the project name?"
}
Write-PM-Dim "Project: $projectName"

# ── Question 2: Methodology ───────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($methodology)) {
  $methodology = Ask-PM-Choice `
    "Which development methodology will you use?" `
    @("Agile/Scrum", "Kanban", "Waterfall", "Hybrid", "Not decided yet")
}
Write-PM-Dim "Methodology: $methodology"

# ── Question 3: WBS Items ─────────────────────────────────────────────────────
Write-Host ""
Write-PMColor "▶ Define the top-level work items in your project." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: Planning, Design, Development, Testing, Deployment)"
Write-PM-Dim "   Enter each item on a new line. When done, press Enter with empty input."
Write-Host ""

$wbsItems = @()
while ($true) {
  $item = Ask-PM-Text "Add WBS item (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $wbsItems += $item
  Write-PM-Dim "Added: $item"
}

if ($wbsItems.Count -eq 0) {
  Write-PM-Dim "No WBS items defined — logging as debt."
  Add-PM-Debt "Planning" "WBS not defined" "No top-level work items provided" "Cannot plan timeline or resource allocation"
  $wbsItems = @("(TBD)")
}

# ── Question 4: Milestones ────────────────────────────────────────────────────
Write-Host ""
Write-PMColor "▶ Define key milestones with target dates." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Format: Milestone Name | DD/MM/YYYY | Acceptance Criteria | Owner)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$milestones = @()
while ($true) {
  $milestone = Ask-PM-Text "Add milestone (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($milestone)) { break }
  $milestones += $milestone
  Write-PM-Dim "Added: $milestone"
}

if ($milestones.Count -eq 0) {
  Write-PM-Dim "No milestones defined — logging as debt."
  Add-PM-Debt "Planning" "Milestones not defined" "No key milestones or target dates provided" "Cannot track progress or manage expectations"
  $milestones = @("(TBD)")
}

# ── Question 5: Resource Allocation ───────────────────────────────────────────
$resourceApproach = Ask-PM-Choice `
  "How should resources be allocated?" `
  @("Dedicated team (full-time)", "Shared resources (split across projects)", "Mixed (some dedicated, some shared)", "Not decided yet")
Write-PM-Dim "Resource approach: $resourceApproach"

# ── Question 6: Dependencies & Critical Path ──────────────────────────────────
Write-Host ""
Write-PMColor "▶ Identify critical path items and dependencies." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Example: Design must complete before Development starts)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$dependencies = @()
while ($true) {
  $dep = Ask-PM-Text "Add dependency (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($dep)) { break }
  $dependencies += $dep
  Write-PM-Dim "Added: $dep"
}

if ($dependencies.Count -eq 0) {
  Write-PM-Dim "No explicit dependencies defined — will assess during planning."
}

# ── Question 7: Communication Cadence ─────────────────────────────────────────
$communication = Ask-PM-Choice `
  "What is your communication plan cadence?" `
  @("Daily standup", "Weekly meetings", "Bi-weekly", "Monthly", "As-needed")
Write-PM-Dim "Communication: $communication"

# ── Question 8: Definition of Done ────────────────────────────────────────────
Write-Host ""
Write-PMColor "▶ Define what `"done`" means for this project." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: All tests pass, Security review complete, Users trained, etc.)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$dod = @()
while ($true) {
  $criterion = Ask-PM-Text "Add Definition of Done criterion (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($criterion)) { break }
  $dod += $criterion
  Write-PM-Dim "Added: $criterion"
}

if ($dod.Count -eq 0) {
  Write-PM-Dim "Definition of Done not provided — logging as debt."
  Add-PM-Debt "Planning" "Definition of Done unclear" "No explicit DoD provided" "Cannot determine when deliverables are complete"
  $dod = @("(TBD)")
}

# ── Confirmation ──────────────────────────────────────────────────────────────
Write-Host ""
$saveConfirm = Confirm-PM-Save "Save this plan?"
if (-not $saveConfirm) {
  Write-PM-Dim "Plan discarded. Exiting."
  exit 0
}

# ── Write Output ──────────────────────────────────────────────────────────────
$outputFile = Join-Path $script:PMOutputDir "01-project-plan.md"

$outputContent = @"
# Project Plan: $projectName

**Date:** $(Get-Date -Format 'dd/MM/yyyy')
**Methodology:** $methodology
**Output Directory:** $script:PMOutputDir

## Scope Statement
[One paragraph describing what is being delivered and why — to be completed by project stakeholders]

## Work Breakdown Structure (WBS)
### Top-Level Items
$($wbsItems | ForEach-Object { "- $_" } | Out-String)
## Milestones & Schedule
| Milestone | Target Date | Acceptance Criteria | Owner |
|---|---|---|---|
$(if ($milestones[0] -ne "(TBD)") {
  $milestones | ForEach-Object { "| $_ | TBD | TBD | TBD |" }
} else {
  "| (TBD) | | | |"
})

## Dependencies & Critical Path
$(if ($dependencies.Count -gt 0) {
  $dependencies | ForEach-Object { "- $_" }
} else {
  "- (None identified yet)"
})

## Resource Allocation
**Approach:** $resourceApproach

| Role | Name | FTE | Notes |
|---|---|---|---|
| Developer | TBD | TBD | TBD |
| QA / Tester | TBD | TBD | TBD |
| Product Owner | TBD | TBD | TBD |
| Project Manager | TBD | TBD | TBD |

## Communication Plan
**Cadence:** $communication
- Standup/Status meetings: [To be scheduled]
- Status reports: [To be scheduled]
- Steering committee: [To be scheduled]

## Definition of Done (Project Level)
$($dod | ForEach-Object { "- [ ] $_" } | Out-String)
## Next Steps
1. Flesh out scope statement
2. Identify and assign resource owners
3. Add target dates and acceptance criteria to milestones
4. Refine WBS to Level 2 and 3
5. Create detailed schedule (Gantt chart or sprint plan)
"@

Set-Content -Path $outputFile -Value $outputContent

Write-PM-SuccessRule "Project plan written to $outputFile"
Write-Host ""

# ── Final Summary ─────────────────────────────────────────────────────────────
Write-PM-Dim "Summary:"
Write-PM-Dim "  Project: $projectName"
Write-PM-Dim "  Methodology: $methodology"
Write-PM-Dim "  WBS Items: $($wbsItems.Count) items"
Write-PM-Dim "  Milestones: $(if ($milestones[0] -eq '(TBD)') { 'TBD' } else { $milestones.Count }) defined"
Write-PM-Dim "  Resource Approach: $resourceApproach"
Write-PM-Dim "  Communication: $communication"

$debtCount = Get-PM-DebtCount
if ($debtCount -gt 0) {
  Write-Host ""
  Write-Host "⚠ $debtCount open PM debt(s) to resolve — see $script:PMDebtFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Phase 1 complete." -ForegroundColor Green
Write-Host ""
