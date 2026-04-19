#requires -version 5.1

param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:SM_AUTO = '1' }
if ($Answers) { $env:SM_ANSWERS = $Answers }
if (Get-Command Invoke-SM-ParseFlags -ErrorAction SilentlyContinue) { Invoke-SM-ParseFlags -Args $args }

. $PSScriptRoot\_common.ps1

Write-SM-Banner "Scrum Master Workflow (Full Sprint Cycle)"
Write-SM-Dim "Running all 5 phases: Planning → Standups → Retro → Impediments → Health"
Write-SM-Dim "Each phase will save its output file. At the end, I'll compile a final report."
Write-Host ""

Write-Host ""
Write-SM-Dim "Starting Phase 1: Sprint Planning..."
& (Join-Path (Split-Path (Split-Path $PSScriptRoot)) "sm-sprint-planning" "scripts" "sprint-planning.ps1")
Write-Host ""

Write-SM-Dim "Starting Phase 2: Daily Standup..."
& (Join-Path (Split-Path (Split-Path $PSScriptRoot)) "sm-standup" "scripts" "standup.ps1")
Write-Host ""

Write-SM-Dim "Starting Phase 3: Sprint Retrospective..."
& (Join-Path (Split-Path (Split-Path $PSScriptRoot)) "sm-retrospective" "scripts" "retro.ps1")
Write-Host ""

Write-SM-Dim "Starting Phase 4: Impediment Tracker..."
& (Join-Path (Split-Path (Split-Path $PSScriptRoot)) "sm-impediments" "scripts" "impediments.ps1")
Write-Host ""

Write-SM-Dim "Starting Phase 5: Team Health & Velocity..."
& (Join-Path (Split-Path (Split-Path $PSScriptRoot)) "sm-team-health" "scripts" "team-health.ps1")
Write-Host ""

$FinalOutput = Join-Path $script:SMOutputDir "SM-FINAL.md"

$now = (Get-Date).ToString("yyyy-MM-dd HH:mm")

$output = @"
# Scrum Master Summary Report

> **Compiled:** $now

---

## Sprint Cycle Overview

This report compiles all five Scrum Master phases for a complete sprint cycle:

1. **Sprint Planning** — Goals, capacity, story commitment
2. **Daily Standups** — Team updates and impediments
3. **Sprint Retrospective** — Start/Stop/Continue and improvement actions
4. **Impediment Tracking** — Blockers and escalations
5. **Team Health** — Velocity, morale, and coaching needs

---

## Phase Outputs

### Phase 1: Sprint Plan

✅ Generated: `01-sprint-plan.md`

### Phase 2: Standup Log

✅ Generated: `02-standup-log.md`

### Phase 3: Retrospective

✅ Generated: `03-retrospective.md`

### Phase 4: Impediment Log

✅ Generated: `04-impediment-log.md`

### Phase 5: Team Health

✅ Generated: `05-team-health.md`

---

## Scrum Master Debts

See \`06-sm-debts.md\` for complete tracking.

---

## Next Steps

1. Review individual phase files for detailed information
2. Address any SMDEBT items before the next sprint
3. Follow up on action items from retrospective
4. Share key metrics with stakeholders

"@

Set-Content -Path $FinalOutput -Value $output -Encoding UTF8

Write-SM-SuccessRule "✅ Scrum Master Workflow Complete!"
Write-SM-Dim "All phases completed and final report compiled."
Write-SM-Dim ""
Write-SM-Dim "Output files:"
Write-SM-Dim "  - 01-sprint-plan.md (sprint goals and commitment)"
Write-SM-Dim "  - 02-standup-log.md (team updates and blockers)"
Write-SM-Dim "  - 03-retrospective.md (retrospective and improvements)"
Write-SM-Dim "  - 04-impediment-log.md (blockers and escalations)"
Write-SM-Dim "  - 05-team-health.md (velocity and morale)"
Write-SM-Dim "  - 06-sm-debts.md (outstanding debts)"
Write-SM-Dim "  - SM-FINAL.md (consolidated report)"
Write-Host ""
