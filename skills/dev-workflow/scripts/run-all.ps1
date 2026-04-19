#Requires -Version 5.1
# =============================================================================
# run-all.ps1 — Developer Workflow Orchestrator
# Runs all four Developer phases in sequence with confirmations between each.
# Phases: Design → Coding → Unit Test → Validation
# =============================================================================

param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:DEV_AUTO = '1' }
if ($Answers) { $env:DEV_ANSWERS = $Answers }
if (Get-Command Invoke-DEV-ParseFlags -ErrorAction SilentlyContinue) { Invoke-DEV-ParseFlags -Args $args }

$ErrorActionPreference = "Stop"

# Phase script siblings live under ../../<skill>/scripts/ relative to this
# orchestrator. Avoid hardcoding .claude/ — these scripts are IDE-agnostic
# and may be installed into .windsurf/, .cursor/, etc.
$SkillsRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$DesignScript     = Join-Path $SkillsRoot "dev-design"     | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "design.ps1"
$CodingScript     = Join-Path $SkillsRoot "dev-coding"     | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "coding.ps1"
$UnitTestScript   = Join-Path $SkillsRoot "dev-unit-test"  | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "unit-test.ps1"
$ValidationScript = Join-Path $SkillsRoot "dev-validation" | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "validate.ps1"

function Write-Banner {
  param([string]$Text)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
  Write-Host ("║  {0,-56}║" -f $Text) -ForegroundColor Yellow
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
  Write-Host ""
}

function Ask-Continue {
  param([string]$Prompt)
  # Auto mode: always advance to the next phase.
  if ($env:DEV_AUTO -eq '1' -or $env:DEV_AUTO -eq 'true' -or $env:DEV_AUTO -eq 'yes') {
    return "yes"
  }
  while ($true) {
    Write-Host "▶ $Prompt (y/n/s/q): " -ForegroundColor Yellow -NoNewline
    $answer = Read-Host
    switch ($answer.ToLower()) {
      "y" { return "yes" }
      "yes" { return "yes" }
      "n" { return "no" }
      "no" { return "no" }
      "s" { return "skip" }
      "q" { Write-Host "  Exiting workflow." -ForegroundColor Red; exit 0 }
      default { Write-Host "  Please enter y, n, s, or q." -ForegroundColor Red }
    }
  }
}

Write-Banner "🚀  Developer Workflow — Complete Design & Implementation Spec"
Write-Host "  Four phases: Design → Coding → Unit Test → Validation" -ForegroundColor DarkGray
Write-Host "  Run individual skills to focus on one phase." -ForegroundColor DarkGray
Write-Host ""

# ── Phase 1: Detailed Design ─────────────────────────────────────────────────
Write-Banner "📐  PHASE 1 — Detailed Design"
& $DesignScript
$phase2Result = Ask-Continue "Proceed to Phase 2 (Coding Standards)?"
if ($phase2Result -eq "skip") {
  Write-Host "  Skipping Phase 2." -ForegroundColor Yellow
  $phase2Skip = $true
} elseif ($phase2Result -eq "no") {
  Write-Host "  Exiting after Phase 1." -ForegroundColor Yellow
  exit 0
}

# ── Phase 2: Coding Standards & Implementation Plan ──────────────────────────
if (-not $phase2Skip) {
  Write-Banner "🛠  PHASE 2 — Coding Standards & Implementation Plan"
  & $CodingScript
  $phase3Result = Ask-Continue "Proceed to Phase 3 (Unit Test Strategy)?"
  if ($phase3Result -eq "skip") {
    Write-Host "  Skipping Phase 3." -ForegroundColor Yellow
    $phase3Skip = $true
  } elseif ($phase3Result -eq "no") {
    Write-Host "  Exiting after Phase 2." -ForegroundColor Yellow
    exit 0
  }
}

# ── Phase 3: Unit Test Strategy ──────────────────────────────────────────────
if (-not $phase3Skip) {
  Write-Banner "🧪  PHASE 3 — Unit Test Strategy"
  & $UnitTestScript
  $phase4Result = Ask-Continue "Proceed to Phase 4 (Validation & Sign-Off)?"
  if ($phase4Result -eq "skip") {
    Write-Host "  Skipping Phase 4 (validation)." -ForegroundColor Yellow
    $phase4Skip = $true
  } elseif ($phase4Result -eq "no") {
    Write-Host "  Exiting after Phase 3." -ForegroundColor Yellow
    exit 0
  }
}

# ── Phase 4: Validation & Sign-Off ───────────────────────────────────────────
if (-not $phase4Skip) {
  Write-Banner "✅  PHASE 4 — Design & Code Quality Validation"
  & $ValidationScript
}

Write-Banner "🎉  Workflow Complete!"
Write-Host "  All outputs are in: dev-output/" -ForegroundColor Green
Write-Host "  Review DEVELOPER-FINAL.md for sign-off document." -ForegroundColor Green
Write-Host ""
