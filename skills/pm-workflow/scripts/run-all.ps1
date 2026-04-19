# =============================================================================
# run-all.ps1 — Project Manager Full Workflow Runner (PowerShell)
# Runs all 5 PM phases in sequence and compiles the final document.
# Usage: pwsh <SKILL_DIR>/pm-workflow/scripts/run-all.ps1 [-SkipTo N]
# =============================================================================

param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:PM_AUTO = '1' }
if ($Answers) { $env:PM_ANSWERS = $Answers }
if (Get-Command Invoke-PM-ParseFlags -ErrorAction SilentlyContinue) { Invoke-PM-ParseFlags -Args $args }

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. $PSScriptRoot\_common.ps1

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$totalSteps = 5
$startStep = 1

# Parse args
if ($args.Count -ge 2 -and $args[0] -eq "-SkipTo") {
  $startStep = [int]$args[1]
  Write-PM-Dim "  Skipping to step $startStep..."
}

# Check for existing pm-output
if ((Test-Path $script:PMOutputDir) -and (Get-ChildItem $script:PMOutputDir -ErrorAction SilentlyContinue)) {
  if (Test-PM-Auto) {
    Write-PM-Dim "  Auto mode: continuing from existing output in $script:PMOutputDir"
  } else {
    Write-Host ""
    Write-Host "⚠ Found existing project management output at:" -ForegroundColor Yellow
    Write-Host "  $script:PMOutputDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Archive and start fresh? (y/n): " -NoNewline -ForegroundColor Yellow
    $archiveChoice = Read-Host
    if ($archiveChoice -eq "y" -or $archiveChoice -eq "yes") {
      $archiveDir = "$($script:PMOutputDir)_archive_$timestamp"
      if (Test-Path $script:PMOutputDir) {
        Rename-Item -Path $script:PMOutputDir -NewName $archiveDir
      }
      $null = New-Item -ItemType Directory -Path $script:PMOutputDir -Force
      Write-PM-Dim "  Archived to: $archiveDir"
    }
  }
}

# Step header function
function Step-Header {
  param([int]$step, [int]$total, [string]$title)
  Write-Host ""
  Write-PMColor "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" $script:PMCyan $script:PMBold
  Write-Host ""
  Write-PMColor "  STEP $step of $total — $title" $script:PMCyan $script:PMBold
  Write-Host ""
  Write-PMColor "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" $script:PMCyan $script:PMBold
  Write-Host ""
  Write-Host ""
}

# Progress bar function
function Progress-Bar {
  param([int]$current, [int]$total)
  $filled = [math]::Floor($current * 20 / $total)
  $empty = 20 - $filled
  $bar = [string]::new('█', $filled) + [string]::new('░', $empty)
  Write-Host "  Progress: [$bar] $current/$total" -ForegroundColor Green
}

# Ask step continue
function Ask-StepContinue {
  if (Test-PM-Auto) { return "y" }
  Write-Host ""
  Write-Host "▶ Ready to start this step? (y=yes / s=skip / q=quit): " -NoNewline -ForegroundColor Yellow
  $choice = Read-Host
  return $choice.ToLower()
}

# Run step function
function Run-Step {
  param([int]$step, [string]$title, [string]$scriptPath)

  if ($step -lt $startStep) { return }

  Step-Header $step $totalSteps $title
  Progress-Bar $step $totalSteps

  $choice = Ask-StepContinue
  switch ($choice) {
    { $_ -eq 'y' -or $_ -eq 'yes' } {
      & $scriptPath
    }
    { $_ -eq 's' -or $_ -eq 'skip' } {
      Write-Host "  ⏭  Skipped. You can run this step later." -ForegroundColor DarkGray
      Write-Host ""
      Add-Content -Path "$script:PMOutputDir/skipped-steps.md" -Value "- **SKIPPED:** Step $step ($title) — run ``pwsh $scriptPath`` to complete.`n"
    }
    { $_ -eq 'q' -or $_ -eq 'quit' } {
      Write-Host ""
      Write-Host "  Session paused. Resume anytime with:" -ForegroundColor Yellow
      Write-Host "  pwsh <SKILL_DIR>/pm-workflow/scripts/run-all.ps1 -SkipTo $step" -ForegroundColor Cyan
      Write-Host ""
      exit 0
    }
    default {
      Write-Host "  Invalid choice. Skipping step $step." -ForegroundColor Red
    }
  }
}

# Get skills root
$skillsRoot = Split-Path (Split-Path $PSScriptRoot)

# Run all phases
Run-Step 1 "Project Planning" "$skillsRoot/pm-planning/scripts/planning.ps1"
Run-Step 2 "Status Tracking & Reporting" "$skillsRoot/pm-tracking/scripts/tracking.ps1"
Run-Step 3 "Risk Management" "$skillsRoot/pm-risk/scripts/risk.ps1"
Run-Step 4 "Communication & Stakeholder Management" "$skillsRoot/pm-communication/scripts/communication.ps1"
Run-Step 5 "Change Request Tracking" "$skillsRoot/pm-change-management/scripts/change.ps1"

# Compile final document
function Compile-FinalDoc {
  $finalFile = Join-Path $script:PMOutputDir "PM-FINAL.md"
  $content = @"
# Project Management Deliverable

> Auto-compiled from PM workflow — $(Get-Date -Format 'yyyy-MM-dd HH:mm')

---

"@

  $phaseFiles = @(
    "$script:PMOutputDir/01-project-plan.md",
    "$script:PMOutputDir/02-status-report.md",
    "$script:PMOutputDir/03-risk-register.md",
    "$script:PMOutputDir/04-communication-plan.md",
    "$script:PMOutputDir/05-change-log.md",
    "$script:PMOutputDir/06-pm-debts.md"
  )

  foreach ($f in $phaseFiles) {
    if (Test-Path $f) {
      $content += "`n$(Get-Content $f -Raw)`n`n---`n"
    }
  }

  Set-Content -Path $finalFile -Value $content
  Write-PM-SuccessRule "Compiled PM-FINAL.md"
}

# Summary
Write-Host ""
Write-PM-Banner "Project Management Workflow Complete"

if ((Test-Path "$script:PMOutputDir/01-project-plan.md") -or
    (Test-Path "$script:PMOutputDir/02-status-report.md") -or
    (Test-Path "$script:PMOutputDir/03-risk-register.md") -or
    (Test-Path "$script:PMOutputDir/04-communication-plan.md") -or
    (Test-Path "$script:PMOutputDir/05-change-log.md")) {

  Compile-FinalDoc

  Write-Host ""
  Write-Host "All deliverables:" -ForegroundColor Cyan
  Get-ChildItem "$script:PMOutputDir/*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  ✓ $($_.Name)"
  }
  Write-Host ""
}

if (Test-Path "$script:PMOutputDir/skipped-steps.md") {
  Write-Host ""
  Write-Host "Skipped steps — complete them later:" -ForegroundColor Yellow
  Get-Content "$script:PMOutputDir/skipped-steps.md"
}

$debtCount = Get-PM-DebtCount
if ($debtCount -gt 0) {
  Write-Host ""
  Write-Host "⚠ $debtCount open PM debt(s) — see $script:PMDebtFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Workflow complete. Your project management setup is ready." -ForegroundColor Green
Write-Host ""
