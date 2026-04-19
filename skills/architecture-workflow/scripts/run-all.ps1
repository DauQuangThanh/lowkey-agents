# =============================================================================
# run-all.ps1 — Architect Full Workflow Runner (PowerShell)
# Usage: pwsh <SKILL_DIR>/architecture-workflow/scripts/run-all.ps1 [-SkipTo N]
# =============================================================================

param(
  [int]$SkipTo = 1, [switch]$Auto, [string]$Answers = "")

$ScriptDir  = $PSScriptRoot
$SkillsRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
. (Join-Path $ScriptDir "_common.ps1")


# Step 1: accept --auto / --answers
if ($Auto) { $env:ARCH_AUTO = '1' }
if ($Answers) { $env:ARCH_ANSWERS = $Answers }
if (Get-Command Invoke-ARCH-ParseFlags -ErrorAction SilentlyContinue) { Invoke-ARCH-ParseFlags -Args $args }

$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$TotalSteps = 6

function Show-StepHeader {
  param([int]$Step, [int]$Total, [string]$Title)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "  STEP $Step of $Total — $Title" -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host ""
}

function Show-ProgressBar {
  param([int]$Current, [int]$Total)
  $filled = [int]($Current * 20 / $Total)
  $empty  = 20 - $filled
  $bar = ("█" * $filled) + ("░" * $empty)
  Write-Host ("  Progress: [{0}] {1}/{2}" -f $bar, $Current, $Total) -ForegroundColor Green
}

function Ask-StepContinue {
  if (Test-ARCH-Auto) { return "y" }
  Write-Host ""
  Write-Host "▶ Ready to start this step? (y=yes / s=skip / q=quit): " -ForegroundColor Yellow -NoNewline
  return (Read-Host).Trim().ToLower()
}

function Invoke-Step {
  param([int]$Step, [string]$Title, [string]$ScriptPath)
  if ($Step -lt $SkipTo) { return }
  Show-StepHeader $Step $TotalSteps $Title
  Show-ProgressBar $Step $TotalSteps

  $choice = Ask-StepContinue
  switch -regex ($choice) {
    '^(y|yes)$' {
      & pwsh -NoProfile -File $ScriptPath
    }
    '^(s|skip)$' {
      Write-Host "  ⏭  Skipped. You can run this step later." -ForegroundColor DarkGray
      Add-Content -Path (Join-Path $script:ArchOutputDir "skipped-steps.md") `
        -Value "- **SKIPPED:** Step $Step ($Title) — run ``pwsh $ScriptPath`` to complete."
    }
    '^(q|quit)$' {
      Write-Host ""
      Write-Host "  Session paused. Resume anytime with:" -ForegroundColor Yellow
      Write-Host "  pwsh <SKILL_DIR>/architecture-workflow/scripts/run-all.ps1 -SkipTo $Step" -ForegroundColor Cyan
      Write-Host ""
      exit 0
    }
    default {
      Write-Host "  Invalid choice. Skipping step $Step." -ForegroundColor Red
    }
  }
}

Write-Arch-Banner "🏛  Architect — Full Architecture Workflow"

# Check BA handover
$BAFinal = Join-Path $script:ArchBAInputDir "REQUIREMENTS-FINAL.md"
if (Test-Path $BAFinal) {
  Write-Host "  ✔ Found BA requirements: $BAFinal" -ForegroundColor Green
  Write-Arch-Dim "  Confirm this as the basis for the architecture before continuing."
} else {
  Write-Host "  ⚠ No BA requirements found at: $BAFinal" -ForegroundColor Yellow
  Write-Arch-Dim "  For best results, run the business-analyst first."
}
Write-Host ""

# Handle existing output
$existingFiles = @()
if (Test-Path $script:ArchOutputDir) {
  $existingFiles = Get-ChildItem -Path $script:ArchOutputDir -Force -ErrorAction SilentlyContinue
}
if ($existingFiles.Count -gt 0) {
  if (Test-ARCH-Auto) {
    $choice = "1"
    Write-Arch-Dim "  Auto mode: continuing from existing output in $script:ArchOutputDir"
  } else {
    Write-Host "⚠  Found existing architect output in: $script:ArchOutputDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1) Continue from where I left off"
    Write-Host "  2) Start fresh (existing files will be archived)"
    Write-Host ""
    Write-Host "▶ Your choice (1 or 2): " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host
  }
  if ($choice -eq "2") {
    $archive = "${script:ArchOutputDir}_archive_$Timestamp"
    Move-Item -Path $script:ArchOutputDir -Destination $archive
    Write-Arch-Dim "  Archived to: $archive"
    New-Item -ItemType Directory -Path $script:ArchOutputDir -Force | Out-Null
  }
} else {
  New-Item -ItemType Directory -Path $script:ArchOutputDir -Force | Out-Null
}

Write-Arch-Dim "  This workflow has $TotalSteps steps. You can skip any step and return later."
Write-Arch-Dim "  All outputs are saved automatically to: $script:ArchOutputDir/"
Write-Host ""

Invoke-Step 1 "Architecture Intake"           (Join-Path $SkillsRoot "architecture-intake\scripts\intake.ps1")
Invoke-Step 2 "Technology Research"           (Join-Path $SkillsRoot "technology-research\scripts\research.ps1")
Invoke-Step 3 "ADR Building"                  (Join-Path $SkillsRoot "adr-builder\scripts\new-adr.ps1")
Invoke-Step 4 "C4 Architecture Documentation" (Join-Path $SkillsRoot "c4-architecture\scripts\build-c4.ps1")
Invoke-Step 5 "Risk & Trade-off Register"     (Join-Path $SkillsRoot "risk-tradeoff-register\scripts\register.ps1")
Invoke-Step 6 "Validation & Sign-Off"         (Join-Path $SkillsRoot "architecture-validation\scripts\validate.ps1")

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  🎉 All architect steps complete." -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "  Your architecture documents are in:" -ForegroundColor Green
Write-Host "  $script:ArchOutputDir/" -ForegroundColor Cyan
Write-Host ""
Write-Arch-Dim "  📄 Files generated:"
Get-ChildItem -Path $script:ArchOutputDir -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Arch-Dim "     • $($_.Name)"
}
if (Test-Path $script:ArchADRDir) {
  Get-ChildItem -Path $script:ArchADRDir -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Arch-Dim "     • adr/$($_.Name)"
  }
}
if (Test-Path $script:ArchDiagramsDir) {
  Get-ChildItem -Path $script:ArchDiagramsDir -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Arch-Dim "     • diagrams/$($_.Name)"
  }
}
Write-Host ""
Write-Host "  Share arch-output/ARCHITECTURE-FINAL.md with your team." -ForegroundColor Green
Write-Host ""
