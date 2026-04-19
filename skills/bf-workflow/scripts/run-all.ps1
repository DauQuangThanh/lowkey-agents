# =============================================================================
# run-all.ps1 — Bug-Fixer orchestrator (PowerShell 5.1+)
# =============================================================================

param([switch]$Auto, [string]$Answers = "", [string]$Branch = "", [switch]$DryRun)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:BF_AUTO = '1' }
if ($Answers) { $env:BF_ANSWERS = $Answers }
if ($Branch)  { $env:BF_BRANCH = $Branch }
if ($DryRun)  { $env:BF_DRY_RUN = '1' }

$TriageScript     = Join-Path $SkillsRoot "bf-triage\scripts\triage.ps1"
$FixScript        = Join-Path $SkillsRoot "bf-fix\scripts\fix.ps1"
$RegressionScript = Join-Path $SkillsRoot "bf-regression\scripts\regression.ps1"
$RegisterScript   = Join-Path $SkillsRoot "bf-change-register\scripts\register.ps1"
$ValidateScript   = Join-Path $SkillsRoot "bf-validation\scripts\validate.ps1"

Write-BF-Banner "🐛 Bug-Fixer — Full Workflow"

Write-Host @"

Runs 5 phases in sequence:
  1. Triage       — prioritise bugs/CQDEBT/CSDEBT
  2. Fix          — apply patches on a fix branch
  3. Regression   — regression test stubs per fix
  4. Register     — upstream/downstream impact
  5. Validation   — checks + BF-FINAL.md

Safety:
  - Requires a clean git working tree (or -DryRun).
  - Auto mode requires -Branch NAME.
  - Never pushes; branches are handed off for PR.

"@

foreach ($s in @($TriageScript, $FixScript, $RegressionScript, $RegisterScript, $ValidateScript)) {
  if (-not (Test-Path $s)) {
    Write-Host "ERROR: Phase script not found: $s" -ForegroundColor Red
    exit 1
  }
}

Write-Host "✓ All phase scripts present`n" -ForegroundColor Green

Write-Host "▶ Phase 1: Triage`n"
& pwsh $TriageScript

Write-Host "`n▶ Phase 2: Fix`n"
& pwsh $FixScript

Write-Host "`n▶ Phase 3: Regression tests`n"
& pwsh $RegressionScript

Write-Host "`n▶ Phase 4: Change register`n"
& pwsh $RegisterScript

Write-Host "`n▶ Phase 5: Validation`n"
& pwsh $ValidateScript

Write-BF-SuccessRule "🎉 Bug-Fixer workflow complete"
Write-Host "`nAll outputs in: $script:BFOutputDir`n"
