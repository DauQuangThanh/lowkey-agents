# =============================================================================
# triage.ps1 — Phase 1: triage bugs / CQDEBT / CSDEBT (PowerShell 5.1+)
# =============================================================================

param([switch]$Auto, [string]$Answers = "", [string]$Branch = "", [switch]$DryRun)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:BF_AUTO = '1' }
if ($Answers) { $env:BF_ANSWERS = $Answers }
if ($Branch)  { $env:BF_BRANCH = $Branch }
if ($DryRun)  { $env:BF_DRY_RUN = '1' }

$OutputFile  = Join-Path $script:BFOutputDir "01-triage.md"
$ExtractFile = Join-Path $script:BFOutputDir "01-triage.extract"
$HeadFile    = Join-Path $script:BFOutputDir ".triage-head.tmp"

$TestOutputDir = if ($env:TEST_OUTPUT_DIR) { $env:TEST_OUTPUT_DIR } else { Join-Path (Get-Location) "test-output" }
$CqrOutputDir  = if ($env:CQR_OUTPUT_DIR)  { $env:CQR_OUTPUT_DIR }  else { Join-Path (Get-Location) "cqr-output" }
$CsrOutputDir  = if ($env:CSR_OUTPUT_DIR)  { $env:CSR_OUTPUT_DIR }  else { Join-Path (Get-Location) "csr-output" }
$BugsFile      = Join-Path $TestOutputDir "bugs.md"
$CqDebtFile    = Join-Path $CqrOutputDir  "05-cq-debts.md"

Write-BF-Banner "Phase 1 — Triage"

$TriageMax = Get-BF-Answer -Key "TRIAGE_MAX_ITEMS" -Prompt "Max items in batch:" -Default "10"
$TriageMinSev = Get-BF-Choice -Key "TRIAGE_MIN_SEVERITY" -Prompt "Minimum severity:" -Options @("Critical","Major","Minor","Trivial")
$TriageSources = Get-BF-Choice -Key "TRIAGE_INCLUDE_SOURCES" -Prompt "Sources:" -Options @(
  "bugs","bugs,cqdebt","bugs,cqdebt,csdebt","bugs,cqdebt,csdebt-all")

function Parse-Bugs {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return @() }
  $lines = Get-Content -Path $Path
  $items = New-Object System.Collections.Generic.List[object]
  $cur = $null
  foreach ($line in $lines) {
    if ($line -match "^## (BUG-\d+): (.+)$") {
      if ($cur -and ($cur.Status -eq "Open" -or $cur.Status -eq "In Progress")) { $items.Add($cur) }
      $cur = [pscustomobject]@{ Id=$Matches[1]; Title=$Matches[2]; Source="bug"; Severity=""; Priority=""; Component=""; Status="" }
    }
    elseif ($cur -and $line -match "^\*\*Severity:\*\* *(.+?) *$")   { $cur.Severity  = $Matches[1] }
    elseif ($cur -and $line -match "^\*\*Priority:\*\* *(.+?) *$")   { $cur.Priority  = $Matches[1] }
    elseif ($cur -and $line -match "^\*\*Component:\*\* *(.+?) *$")  { $cur.Component = $Matches[1] }
    elseif ($cur -and $line -match "^\*\*Status:\*\* *(.+?) *$")     { $cur.Status    = $Matches[1] }
  }
  if ($cur -and ($cur.Status -eq "Open" -or $cur.Status -eq "In Progress")) { $items.Add($cur) }
  return $items
}

function Parse-CqDebts {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return @() }
  $lines = Get-Content -Path $Path
  $items = New-Object System.Collections.Generic.List[object]
  $cur = $null
  foreach ($line in $lines) {
    if ($line -match "^## (CQDEBT-\d+): (.+)$") {
      if ($cur) { $items.Add($cur) }
      $cur = [pscustomobject]@{ Id=$Matches[1]; Title=$Matches[2]; Source="cqdebt"; Severity=""; Priority="P2"; Component=""; Status="Open" }
    }
    elseif ($cur -and $line -match "\*\*Severity\*\* \| (.+?) *\|") { $cur.Severity = $Matches[1] }
  }
  if ($cur) { $items.Add($cur) }
  return $items
}

function Parse-CsDebts {
  param([string]$Dir)
  if (-not (Test-Path $Dir)) { return @() }
  $items = New-Object System.Collections.Generic.List[object]
  foreach ($f in (Get-ChildItem -Path $Dir -Filter "*.md" -ErrorAction SilentlyContinue)) {
    foreach ($line in Get-Content -Path $f.FullName) {
      if ($line -match "^## (CSDEBT-\d+): (.+)$") {
        $items.Add([pscustomobject]@{ Id=$Matches[1]; Title=$Matches[2]; Source="csdebt"; Severity="Major"; Priority="P1"; Component=""; Status="Open" })
      }
    }
  }
  return $items
}

function Get-SevRank {
  param([string]$Sev)
  switch ($Sev) {
    "Critical" { return 1 }
    "Major"    { return 2 }
    "Minor"    { return 3 }
    "Trivial"  { return 4 }
    default    { return 5 }
  }
}

$all = @()
$all += Parse-Bugs $BugsFile
if ($TriageSources -match "cqdebt") { $all += Parse-CqDebts $CqDebtFile }
if ($TriageSources -match "csdebt") { $all += Parse-CsDebts $CsrOutputDir }

$minRank = Get-SevRank $TriageMinSev
$filtered = @($all | Where-Object { (Get-SevRank $_.Severity) -le $minRank })
$sorted = $filtered | Sort-Object @{Expression={ Get-SevRank $_.Severity }}, Priority
$batch = @($sorted | Select-Object -First ([int]$TriageMax))

$batchIds = if ($batch.Count -gt 0) { [string]::Join(",", ($batch | ForEach-Object { $_.Id })) } else { "(empty)" }

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$mode = if (Test-BF-Auto) { "Auto" } else { "Interactive" }

$rows = if ($batch.Count -gt 0) {
  $i = 1
  ($batch | ForEach-Object {
    $row = "| $i | $($_.Id) | $($_.Source) | $($_.Severity) | $($_.Priority) | $(if ($_.Component) { $_.Component } else { 'unknown' }) | $($_.Title) |"
    $i++
    $row
  }) -join "`n"
} else { "_No items matched the current filters._" }

$deferredMsg = if (($sorted.Count - $batch.Count) -le 0) {
  "_None — all matching items included in this batch._"
} else {
  "Items below the cap remain in the source files and re-appear in the next triage run."
}

$md = @"
# Phase 1 — Triage

**Timestamp:** $ts
**Mode:** $mode
**Min severity:** $TriageMinSev
**Sources:** $TriageSources
**Cap:** $TriageMax

## Selected Batch ($($batch.Count) of $($sorted.Count) matching items)

$(if ($batch.Count -gt 0) { @"
| # | ID | Source | Severity | Priority | Component | Title |
|---|---|---|---|---|---|---|
$rows
"@ } else { $rows })

## Deferred ($($sorted.Count - $batch.Count) items)

$deferredMsg

## Next Phase

Run: ``pwsh <SKILL_DIR>/bf-fix/scripts/fix.ps1``

---
"@

Set-Content -Path $OutputFile -Value $md -Encoding UTF8

# Write machine-readable head file for bf-fix
$headLines = @()
$rank = 1
foreach ($b in $batch) {
  $r = Get-SevRank $b.Severity
  $headLines += "$r|$($b.Id)|$($b.Source)|$($b.Severity)|$($b.Priority)|$($b.Component)|$($b.Title)"
}
Set-Content -Path $HeadFile -Value $headLines -Encoding UTF8

Write-BF-Extract -Path $ExtractFile -Pairs @{
  BATCH_IDS              = $batchIds
  BATCH_SIZE             = $batch.Count
  DEFERRED_COUNT         = ($sorted.Count - $batch.Count)
  TRIAGE_MAX_ITEMS       = $TriageMax
  TRIAGE_MIN_SEVERITY    = $TriageMinSev
  TRIAGE_INCLUDE_SOURCES = $TriageSources
  BUGS_FILE              = $BugsFile
  CQR_DEBT_FILE          = $CqDebtFile
  CSR_FINDINGS_DIR       = $CsrOutputDir
  BATCH_LIST_FILE        = $HeadFile
}

Write-BF-SuccessRule "✅ Phase 1 Complete — Batch: $($batch.Count), Deferred: $($sorted.Count - $batch.Count)"
Write-Host "  Markdown: $OutputFile"
Write-Host "  Extract:  $ExtractFile"
Write-Host ""
Write-Host "Next: Phase 2 — pwsh <SKILL_DIR>/bf-fix/scripts/fix.ps1`n"
