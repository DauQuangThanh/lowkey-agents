# =============================================================================
# run-all.ps1 — Product Owner Full Workflow Runner (PowerShell)
# Runs all 5 PO phases in sequence and compiles the final document.
# Usage: pwsh <SKILL_DIR>/po-workflow/scripts/run-all.ps1 [-SkipTo N]
# =============================================================================

param(
  [int]$SkipTo = 1, [switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")


# Step 1: accept --auto / --answers
if ($Auto) { $env:PO_AUTO = '1' }
if ($Answers) { $env:PO_ANSWERS = $Answers }
if (Get-Command Invoke-PO-ParseFlags -ErrorAction SilentlyContinue) { Invoke-PO-ParseFlags -Args $args }

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$TotalSteps = 5
$StartStep = $SkipTo

if ($SkipTo -gt 1) {
  Write-PO-Dim "  Skipping to step $SkipTo..."
}

# ── Step runner ───────────────────────────────────────────────────────────────
function Step-Header {
  param([int]$Step, [int]$Total, [string]$Title)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
  Write-Host "  STEP $Step of $Total — $Title" -ForegroundColor Magenta
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
  Write-Host ""
}

function Progress-Bar {
  param([int]$Current, [int]$Total)
  $filled = [Math]::Floor($Current * 20 / $Total)
  $empty = 20 - $filled
  $bar = ("█" * $filled) + ("░" * $empty)
  Write-Host "  Progress: [$bar] $Current/$Total" -ForegroundColor Green
}

function Ask-Step-Continue {
  if (Test-PO-Auto) { return "y" }
  while ($true) {
    $choice = Read-Host "▶ Ready to start this step? (y=yes / s=skip / q=quit)"
    $choice = $choice.ToLower().Trim()
    if ($choice -in "y", "yes", "s", "skip", "q", "quit") {
      return $choice
    }
  }
}

function Run-Step {
  param([int]$Step, [string]$Title, [string]$ScriptPath)
  if ($Step -lt $StartStep) { return }

  Step-Header $Step $TotalSteps $Title
  Progress-Bar $Step $TotalSteps

  $choice = Ask-Step-Continue
  switch -Regex ($choice) {
    "^y" {
      & $ScriptPath
    }
    "^s" {
      Write-PO-Dim "  ⏭  Skipped. You can run this step later."
      Write-Host ""
      "- **SKIPPED:** Step $Step ($Title) — run ``pwsh $ScriptPath`` to complete." >> (Join-Path $script:POOutputDir "skipped-steps.md")
    }
    "^q" {
      Write-Host ""
      Write-Host "  Session paused. Resume anytime with:" -ForegroundColor Yellow
      Write-Host "  pwsh <SKILL_DIR>/po-workflow/scripts/run-all.ps1 -SkipTo $Step" -ForegroundColor Cyan
      Write-Host ""
      exit 0
    }
    default {
      Write-Host "  Invalid choice. Skipping step $Step." -ForegroundColor Red
    }
  }
}

function Compile-FinalDoc {
  $finalFile = Join-Path $script:POOutputDir "PO-FINAL.md"
  $content = @"
# Product Owner Documentation

> Auto-compiled from PO workflow — $(Get-Date -Format 'yyyy-MM-dd HH:mm')

---

"@

  $files = @(
    "01-product-backlog.md",
    "02-acceptance-criteria.md",
    "03-product-roadmap.md",
    "04-stakeholder-comms.md",
    "05-sprint-review.md",
    "06-po-debts.md"
  )

  foreach ($file in $files) {
    $filePath = Join-Path $script:POOutputDir $file
    if (Test-Path $filePath) {
      $content += "`n"
      $content += (Get-Content $filePath -Raw)
      $content += "`n`n---`n`n"
    }
  }

  Set-Content -Path $finalFile -Value $content -Encoding UTF8
  Write-Host "  ✅ Final document compiled: $finalFile" -ForegroundColor Green
}

# ── Startup ───────────────────────────────────────────────────────────────────
Write-PO-Banner "🎯  Product Owner — Full Workflow"

# Handle existing output
if ((Test-Path $script:POOutputDir) -and ((Get-ChildItem $script:POOutputDir -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)) {
  if (Test-PO-Auto) {
    $resumeChoice = "1"
    Write-PO-Dim "  Auto mode: continuing from existing output in $($script:POOutputDir)"
  } else {
    Write-Host "⚠  Found existing PO output files in: $($script:POOutputDir)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1) Continue from where I left off"
    Write-Host "  2) Start fresh (existing files will be archived)"
    Write-Host ""
    $resumeChoice = Read-Host "▶ Your choice (1 or 2)"
  }
  if ($resumeChoice -eq "2") {
    $archiveDir = "$($script:POOutputDir)_archive_$Timestamp"
    Move-Item $script:POOutputDir $archiveDir
    Write-PO-Dim "  Archived to: $archiveDir"
    New-Item -ItemType Directory -Path $script:POOutputDir -Force | Out-Null
  }
} else {
  New-Item -ItemType Directory -Path $script:POOutputDir -Force | Out-Null
}

Write-PO-Dim "  This workflow has $TotalSteps steps. You can skip any step and return later."
Write-PO-Dim "  All answers are saved automatically to: $($script:POOutputDir)/"
Write-Host ""

# Get skills root directory
$SkillsRoot = Split-Path (Split-Path $ScriptDir -Parent) -Parent

Run-Step 1 "Product Backlog Management"  (Join-Path $SkillsRoot "po-backlog/scripts/backlog.ps1")
Run-Step 2 "Acceptance Criteria"         (Join-Path $SkillsRoot "po-acceptance/scripts/acceptance.ps1")
Run-Step 3 "Product Roadmap"             (Join-Path $SkillsRoot "po-roadmap/scripts/roadmap.ps1")
Run-Step 4 "Stakeholder Communication"   (Join-Path $SkillsRoot "po-stakeholder-comms/scripts/stakeholder-comms.ps1")
Run-Step 5 "Sprint Review Preparation"   (Join-Path $SkillsRoot "po-sprint-review/scripts/sprint-review.ps1")

# ── Compile final document ────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  🎉 All steps complete! Compiling final PO document..." -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""

Compile-FinalDoc

Write-Host ""
Write-Host "  Your PO documents are in:" -ForegroundColor Green
Write-Host "  → $($script:POOutputDir)" -ForegroundColor Green
Write-Host ""

Write-PO-SuccessRule "✅ Workflow Complete"
