# =============================================================================
# validate-requirements.ps1 — Phase 7: Requirements Validation & Sign-Off (PS)
# Runs a completeness checklist and compiles the final requirements document.
# Output: $BAOutputDir\07-validation-report.md + REQUIREMENTS-FINAL.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$ValidationFile = Join-Path $script:BAOutputDir "07-validation-report.md"
$FinalFile      = Join-Path $script:BAOutputDir "REQUIREMENTS-FINAL.md"

$script:Passed   = 0
$script:Failed   = 0
$script:Skipped  = 0
$script:Results  = @()

function Record-Check {
  param([string]$Status, [string]$Description)
  switch ($Status) {
    "pass" {
      $script:Passed++
      $script:Results += ("| ✅ PASS | {0} |" -f $Description)
      Write-Host "    ✅ PASS" -ForegroundColor Green
    }
    "warn" {
      $script:Failed++
      $script:Results += ("| ⚠️ WARN | {0} |" -f $Description)
      Write-Host "    ⚠  WARNING — may need attention" -ForegroundColor Yellow
    }
    default {
      $script:Failed++
      $script:Results += ("| ❌ FAIL | {0} |" -f $Description)
      Write-Host "    ❌ FAIL — add to requirement debts" -ForegroundColor Red
    }
  }
}

function Check-Item {
  param([string]$Description, [scriptblock]$CheckBlock)
  Write-BA-Dim ("  Checking: {0}..." -f $Description)
  $result = & $CheckBlock
  Record-Check -Status $result -Description $Description
}

# ── Automated check helpers ───────────────────────────────────────────────────
function Check-FileExists {
  param([string]$FileName, [string]$MissingStatus = "fail")
  $path = Join-Path $script:BAOutputDir $FileName
  if (Test-Path $path) { return "pass" } else { return $MissingStatus }
}

function Check-ProblemStatement {
  $path = Join-Path $script:BAOutputDir "01-project-intake.md"
  if (-not (Test-Path $path)) { return "fail" }
  $content = Get-Content $path -Raw -Encoding UTF8
  if ($content -match "(?ms)## Problem Statement\s*\r?\n\s*TBD") { return "warn" }
  return "pass"
}

function Check-AcceptanceCriteria {
  $path = Join-Path $script:BAOutputDir "04-user-stories.md"
  if (-not (Test-Path $path)) { return "fail" }
  $content = Get-Content $path -Raw -Encoding UTF8
  if ($content -match "not yet defined") { return "warn" }
  return "pass"
}

function Check-NoBlockingDebts {
  if (-not (Test-Path $script:BADebtFile)) { return "pass" }
  $content = Get-Content $script:BADebtFile -Raw -Encoding UTF8
  if ($content -match "Blocking") { return "warn" }
  return "pass"
}

function Check-OutOfScope {
  $path = Join-Path $script:BAOutputDir "01-project-intake.md"
  if (-not (Test-Path $path)) { return "fail" }
  $content = Get-Content $path -Raw -Encoding UTF8
  if ($content -match "(?ms)## Out of Scope\s*\r?\n\s*To be defined") { return "warn" }
  return "pass"
}

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "✅  Step 7 of 7 — Validation & Sign-Off"
Write-BA-Dim "  We're nearly done! Let me check that all key areas are covered."
Write-Host ""

# ── Automated completeness checks ─────────────────────────────────────────────
Write-Host "── Automated Completeness Checks ──" -ForegroundColor Cyan
Write-Host ""
Check-Item "Project intake completed"                  { Check-FileExists "01-project-intake.md" }
Check-Item "Stakeholders identified"                   { Check-FileExists "02-stakeholders.md"   }
Check-Item "Functional requirements captured"          { Check-FileExists "03-requirements.md"   }
Check-Item "User stories created"                      { Check-FileExists "04-user-stories.md"   }
Check-Item "Non-functional requirements captured"      { Check-FileExists "05-nfr.md" "warn"     }
Check-Item "Problem statement is defined"              { Check-ProblemStatement }
Check-Item "All user stories have acceptance criteria" { Check-AcceptanceCriteria }
Check-Item "No blocking requirement debts open"        { Check-NoBlockingDebts }
Check-Item "Out-of-scope items defined"                { Check-OutOfScope }
Write-Host ""

# ── Manual validation questions ───────────────────────────────────────────────
Write-Host "── Manual Validation Questions ──" -ForegroundColor Cyan
Write-BA-Dim "  Please answer these questions based on your knowledge of the project."
Write-Host ""

function Manual-Check {
  param([string]$Question, [string]$Description)
  Write-Host ("▶ {0}" -f $Question) -ForegroundColor Yellow
  # Auto mode: mark as TBD (unsure) to preserve the manual-review intent.
  if (Test-BA-Auto) {
    $script:Skipped++
    $script:Results += ("| ❓ TBD  | {0} |" -f $Description)
    Write-Host "    ❓ Auto: marked as TBD (needs human review)" -ForegroundColor Yellow
    return
  }
  while ($true) {
    Write-Host "  (y=yes / n=no / u=unsure): " -NoNewline
    $raw  = Read-Host
    $norm = $raw.ToLower().Trim()
    switch ($norm) {
      { $_ -in "y","yes" } {
        $script:Passed++
        $script:Results += ("| ✅ PASS | {0} |" -f $Description)
        Write-Host "    ✅ Confirmed" -ForegroundColor Green
        return
      }
      { $_ -in "n","no" } {
        $script:Failed++
        $script:Results += ("| ❌ FAIL | {0} |" -f $Description)
        Write-Host "    ❌ Logged as gap" -ForegroundColor Red
        return
      }
      { $_ -in "u","unsure" } {
        $script:Skipped++
        $script:Results += ("| ❓ TBD  | {0} |" -f $Description)
        Write-Host "    ❓ Marked as TBD" -ForegroundColor Yellow
        return
      }
      default { Write-Host "  Please enter y, n, or u." -ForegroundColor Red }
    }
  }
}

Manual-Check `
  "Does every stakeholder group have at least one user story representing their needs?" `
  "All stakeholder groups represented in user stories"

Manual-Check `
  "Do all the requirements trace back to the problem statement (nothing included just 'because it would be nice')?" `
  "Requirements traceable to problem statement"

Manual-Check `
  "Does the team agree on what is IN scope vs OUT of scope?" `
  "Scope clearly defined and agreed"

Manual-Check `
  "Are all requirements free of direct contradictions? (answer YES if there are NO conflicts)" `
  "No conflicting requirements"

Manual-Check `
  "Have the main stakeholders reviewed and agreed with these requirements?" `
  "Key stakeholder sign-off obtained or planned"

Manual-Check `
  "Are all 'must have' user stories specific enough for a developer to start building?" `
  "Must-have stories are specific enough to develop"

# ── Collect reviewer info ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Sign-Off Details ──" -ForegroundColor Cyan
Write-Host ""
$reviewerName = Ask-BA-Text "Your name (person completing this validation):"
if ([string]::IsNullOrWhiteSpace($reviewerName)) { $reviewerName = "Anonymous" }
$reviewDate = Get-Date -Format "yyyy-MM-dd"

Write-Host ""
Write-BA-Dim ("  Pass: {0}  |  Issues: {1}  |  TBD: {2}" -f $script:Passed, $script:Failed, $script:Skipped)
Write-Host ""

if ($script:Failed -eq 0 -and $script:Skipped -eq 0) {
  $signoffStatus = "✅ APPROVED"
  Write-Host "  🎉 All checks passed! Requirements are ready for development." -ForegroundColor Green
} elseif ($script:Failed -le 2 -and $script:Skipped -le 2) {
  $signoffStatus = "⚠️ CONDITIONALLY APPROVED"
  Write-Host "  ⚠  Minor gaps detected. Review the issues above before starting development." -ForegroundColor Yellow
} else {
  $signoffStatus = "❌ NOT READY"
  Write-Host "  ❌ Several gaps found. Resolve the issues above before starting development." -ForegroundColor Red
}
Write-Host ""

# ── Write validation report ───────────────────────────────────────────────────
$lines  = @()
$lines += "# Validation Report"
$lines += ""
$lines += "> Review date: $reviewDate | Reviewer: $reviewerName"
$lines += ""
$lines += "## Status: $signoffStatus"
$lines += ""
$lines += "| Checks Passed | Issues Found | TBD |"
$lines += "|---|---|---|"
$lines += ("| {0} | {1} | {2} |" -f $script:Passed, $script:Failed, $script:Skipped)
$lines += ""
$lines += "## Checklist Results"
$lines += ""
$lines += "| Result | Item |"
$lines += "|---|---|"
foreach ($r in $script:Results) { $lines += $r }
$lines += ""
$lines += "## Sign-Off"
$lines += ""
$lines += "| Field | Value |"
$lines += "|---|---|"
$lines += ("| Reviewer | {0} |" -f $reviewerName)
$lines += ("| Date | {0} |" -f $reviewDate)
$lines += ("| Status | {0} |" -f $signoffStatus)
$lines += ""
$lines += "> **Next Step:** Share ``REQUIREMENTS-FINAL.md`` with the development team."
$lines += "> Resolve all ❌ items and 🔴 blocking debts before sprint planning."
$lines += ""
$lines | Set-Content -Path $ValidationFile -Encoding UTF8

# ── Compile final document ────────────────────────────────────────────────────
Write-Host "── Compiling Final Requirements Document ──" -ForegroundColor Cyan
Write-Host ""

$projectName = "My Project"
$intakePath = Join-Path $script:BAOutputDir "01-project-intake.md"
if (Test-Path $intakePath) {
  $intakeLines = Get-Content $intakePath -Encoding UTF8
  foreach ($line in $intakeLines) {
    if ($line -match '^\|\s*\*\*Project Name\*\*\s*\|\s*(.+?)\s*\|') {
      $projectName = $Matches[1]
      break
    }
  }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$final  = @()
$final += "# Requirements Document"
$final += ""
$final += "> Project: $projectName"
$final += "> Compiled: $timestamp"
$final += "> Status: $signoffStatus"
$final += ""
$final += "---"
$final += ""

$sections = @(
  "01-project-intake.md",
  "02-stakeholders.md",
  "03-requirements.md",
  "04-user-stories.md",
  "05-nfr.md",
  "06-requirement-debts.md",
  "07-validation-report.md"
)

foreach ($section in $sections) {
  $localPath = Join-Path $script:BAOutputDir $section
  if (Test-Path $localPath) {
    $final += (Get-Content $localPath -Encoding UTF8)
    $final += ""
    $final += "---"
    $final += ""
  }
}

$final | Set-Content -Path $FinalFile -Encoding UTF8

Write-BA-SuccessRule "🎉 BA Session Complete!"
Write-Host "  Key files generated:"
Write-Host ("  📄 {0}" -f $FinalFile)       -ForegroundColor Cyan
Write-Host ("  📋 {0}" -f $ValidationFile)  -ForegroundColor Cyan
Write-Host ("  📁 {0}/" -f $script:BAOutputDir) -ForegroundColor Cyan
Write-Host ""
Write-Host "  Recommended next steps:"
Write-Host "  1. Share REQUIREMENTS-FINAL.md with your development team"
Write-Host "  2. Resolve all 🔴 Blocking debts before the first sprint"
Write-Host "  3. Book a requirements review meeting with stakeholders"
Write-Host "  4. Import user stories into your project management tool (Jira, Linear, etc.)"
Write-Host ""
