# =============================================================================
# run-all.ps1 — Business Analyst Full Workflow Runner (PowerShell)
# Runs all 7 BA phases in sequence and compiles the final document.
# Usage: pwsh <SKILL_DIR>/ba-workflow/scripts/run-all.ps1 [-SkipTo <step>]
# =============================================================================

param([int]$SkipTo = 1, [switch]$Auto, [string]$Answers = "")

$ScriptDir  = $PSScriptRoot
$SkillsRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
. (Join-Path $ScriptDir "_common.ps1")


# Step 1: accept --auto / --answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }
if (Get-Command Invoke-BA-ParseFlags -ErrorAction SilentlyContinue) { Invoke-BA-ParseFlags -Args $args }

$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$TotalSteps = 7

function Write-StepHeader {
  param([int]$Step, [string]$Title)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host ("  STEP {0} of {1} — {2}" -f $Step, $TotalSteps, $Title) -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host ""
}

function Write-ProgressBar {
  param([int]$Current, [int]$Total)
  $filled = [math]::Floor($Current * 20 / $Total)
  $empty  = 20 - $filled
  $bar    = ("█" * $filled) + ("░" * $empty)
  Write-Host ("  Progress: [{0}] {1}/{2}" -f $bar, $Current, $Total) -ForegroundColor Green
}

function Ask-Continue {
  if (Test-BA-Auto) { return "y" }
  Write-Host ""
  $raw = Read-Host "▶ Ready to start this step? (y=yes / s=skip / q=quit)"
  return $raw.ToLower().Trim()
}

function Compile-FinalDoc {
  $finalFile = Join-Path $script:BAOutputDir "REQUIREMENTS-FINAL.md"
  $content   = @()
  $content  += "# Requirements Document"
  $content  += ""
  $content  += "> Auto-compiled from BA workflow — $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
  $content  += ""
  $content  += "---"
  $content  += ""

  $steps = @(
    "01-project-intake.md",
    "02-stakeholders.md",
    "03-requirements.md",
    "04-user-stories.md",
    "05-nfr.md",
    "06-requirement-debts.md",
    "07-validation-report.md"
  )

  foreach ($step in $steps) {
    $path = Join-Path $script:BAOutputDir $step
    if (Test-Path $path) {
      $content += ""
      $content += Get-Content $path
      $content += ""
      $content += "---"
      $content += ""
    }
  }

  $content | Set-Content -Path $finalFile -Encoding UTF8
  Write-Host "  ✅ Final document compiled: $finalFile" -ForegroundColor Green
}

function Run-Step {
  param(
    [int]$Step,
    [string]$Title,
    [string]$ScriptPath
  )
  if ($Step -lt $SkipTo) { return }

  Write-StepHeader -Step $Step -Title $Title
  Write-ProgressBar -Current $Step -Total $TotalSteps
  Write-Host ""

  $choice = Ask-Continue

  switch ($choice) {
    { $_ -in "y","yes" } {
      & pwsh -File $ScriptPath
    }
    { $_ -in "s","skip" } {
      Write-Host "  ⏭  Skipped. Run later: pwsh $ScriptPath" -ForegroundColor DarkGray
      Write-Host ""
      $skippedFile = Join-Path $script:BAOutputDir "skipped-steps.md"
      "- **SKIPPED:** Step $Step ($Title) — run ``pwsh $ScriptPath`` to complete." |
        Add-Content -Path $skippedFile -Encoding UTF8
    }
    { $_ -in "q","quit" } {
      Write-Host ""
      Write-Host "  Session paused. Resume anytime with:" -ForegroundColor Yellow
      Write-Host "  pwsh <SKILL_DIR>/ba-workflow/scripts/run-all.ps1 -SkipTo $Step" -ForegroundColor Cyan
      Write-Host ""
      exit 0
    }
    default {
      Write-Host "  Invalid choice. Skipping step $Step." -ForegroundColor Red
    }
  }
}

# ── Startup ───────────────────────────────────────────────────────────────────
Write-BA-Banner "🗂  Business Analyst — Full Requirements Workflow"

if ((Test-Path $script:BAOutputDir) -and ((Get-ChildItem $script:BAOutputDir -ErrorAction SilentlyContinue).Count -gt 0)) {
  if (Test-BA-Auto) {
    $resumeChoice = "1"
    Write-BA-Dim "  Auto mode: continuing from existing output in $script:BAOutputDir"
  } else {
    Write-Host "⚠  Found existing BA output files in: $script:BAOutputDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1) Continue from where I left off"
    Write-Host "  2) Start fresh (existing files will be archived)"
    Write-Host ""
    $resumeChoice = Read-Host "▶ Your choice (1 or 2)"
  }

  if ($resumeChoice -eq "2") {
    $archiveDir = "{0}_archive_{1}" -f $script:BAOutputDir, $Timestamp
    Move-Item $script:BAOutputDir $archiveDir
    Write-Host "  Archived to: $archiveDir" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Path $script:BAOutputDir | Out-Null
  }
} else {
  New-Item -ItemType Directory -Path $script:BAOutputDir -Force | Out-Null
}

Write-BA-Dim "  This workflow has $TotalSteps steps. You can skip any step and return later."
Write-BA-Dim "  All answers are saved automatically to: $script:BAOutputDir"
Write-Host ""

Run-Step -Step 1 -Title "Project Intake"              -ScriptPath (Join-Path $SkillsRoot "project-intake\scripts\intake.ps1")
Run-Step -Step 2 -Title "Stakeholder Mapping"         -ScriptPath (Join-Path $SkillsRoot "stakeholder-mapping\scripts\map-stakeholders.ps1")
Run-Step -Step 3 -Title "Requirements Elicitation"    -ScriptPath (Join-Path $SkillsRoot "requirements-elicitation\scripts\elicit-requirements.ps1")
Run-Step -Step 4 -Title "User Story Building"         -ScriptPath (Join-Path $SkillsRoot "user-story-builder\scripts\build-stories.ps1")
Run-Step -Step 5 -Title "Non-Functional Requirements" -ScriptPath (Join-Path $SkillsRoot "nfr-checklist\scripts\nfr-checklist.ps1")
Run-Step -Step 6 -Title "Requirement Debt Review"     -ScriptPath (Join-Path $SkillsRoot "requirement-debt-tracker\scripts\debt-tracker.ps1")
Run-Step -Step 7 -Title "Validation & Sign-Off"       -ScriptPath (Join-Path $SkillsRoot "requirements-validation\scripts\validate-requirements.ps1")

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  🎉 All steps complete! Compiling final requirements document..." -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Compile-FinalDoc

Write-Host ""
Write-Host "  Your requirements documents are in:" -ForegroundColor Green
Write-Host "  $script:BAOutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "  📄 Files generated:" -ForegroundColor DarkGray
Get-ChildItem (Join-Path $script:BAOutputDir "*.md") -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host "     • $($_.Name)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  Thank you! Share ba-output/REQUIREMENTS-FINAL.md with your team." -ForegroundColor Green
Write-Host ""
