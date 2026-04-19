# =============================================================================
# validate.ps1 — Phase 5: validation + BF-FINAL.md (PowerShell 5.1+)
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:BF_AUTO = '1' }
if ($Answers) { $env:BF_ANSWERS = $Answers }

$ReportFile    = Join-Path $script:BFOutputDir "06-validation-report.md"
$FinalFile     = Join-Path $script:BFOutputDir "BF-FINAL.md"
$FixExtract    = Join-Path $script:BFOutputDir "02-fixes.extract"
$RegTestExtract= Join-Path $script:BFOutputDir "03-regression-tests.extract"
$ChangeExtract = Join-Path $script:BFOutputDir "04-change-register.extract"

Write-BF-Banner "Phase 5 — Validation"

foreach ($f in @($FixExtract, $ChangeExtract)) {
  if (-not (Test-Path $f)) {
    Write-Host "ERROR: Required extract not found: $f" -ForegroundColor Red
    exit 1
  }
}

$FixedIds       = Read-BF-Extract -Path $FixExtract    -Key "FIXED_IDS"
$DeferredIds    = Read-BF-Extract -Path $FixExtract    -Key "DEFERRED_IDS"
$SkippedIds     = Read-BF-Extract -Path $FixExtract    -Key "SKIPPED_IDS"
$Branch         = Read-BF-Extract -Path $FixExtract    -Key "BRANCH"
$Commits        = Read-BF-Extract -Path $FixExtract    -Key "COMMITS"
$TestIds        = if (Test-Path $RegTestExtract) { Read-BF-Extract -Path $RegTestExtract -Key "TEST_IDS" } else { "" }
$TestsCreated   = if (Test-Path $RegTestExtract) { Read-BF-Extract -Path $RegTestExtract -Key "TESTS_CREATED" } else { "0" }
$FilesModified  = Read-BF-Extract -Path $ChangeExtract -Key "FILES_MODIFIED"

function Count-Ids { param([string]$Ids)
  if (-not $Ids -or $Ids -eq "(none)") { return 0 }
  return ($Ids -split ",").Count
}

$nFixed    = Count-Ids $FixedIds
$nDeferred = Count-Ids $DeferredIds
$nSkipped  = Count-Ids $SkippedIds
$nTests    = [int]$TestsCreated

$missingTests = 0
if ($nFixed -gt 0 -and $nTests -lt $nFixed) {
  $missingTests = $nFixed - $nTests
  Add-BF-Debt -Area "Validation" -Title "Fix/test mismatch" `
    -Description "$nFixed fixes applied but only $nTests regression tests created" `
    -Impact "Cannot guarantee the bugs won't return; add the missing test(s)"
}

$ValidationCmd = Get-BF-Answer -Key "VALIDATION_COMMAND" -Prompt "Validation command (blank to skip):" -Default ""
$validationStatus = "skipped (no command configured)"
if ($ValidationCmd) {
  Write-BF-Dim "  Running: $ValidationCmd"
  try {
    Invoke-Expression $ValidationCmd *> $null
    if ($LASTEXITCODE -eq 0) { $validationStatus = "✅ passed" }
    else {
      $validationStatus = "❌ failed"
      Add-BF-Debt -Area "Validation" -Title "Validation command failed" `
        -Description "The configured test command returned non-zero after the fix batch" `
        -Impact "Batch may introduce a regression; review before merging"
    }
  } catch {
    $validationStatus = "❌ failed"
    Add-BF-Debt -Area "Validation" -Title "Validation command raised" `
      -Description "$_" -Impact "Cannot trust the fix batch; investigate"
  }
}

$verdict = "✅ READY"
$notes = @()
if ($missingTests -gt 0) { $verdict = "⚠️  CONDITIONAL"; $notes += "- Missing regression tests: $missingTests" }
if ($validationStatus -eq "❌ failed") { $verdict = "❌ NOT READY"; $notes += "- Validation command failed" }
if ($nFixed -eq 0) { $verdict = "ℹ️  NO CHANGES"; $notes += "- No fixes applied this round" }

$debtTotal = Get-BF-DebtCount
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$notesStr = if ($notes.Count) { [string]::Join("`n", $notes) } else { "" }

$reportContent = @"
# Phase 5 — Validation Report

**Timestamp:** $ts
**Branch:** $Branch

## Counts

| Outcome | Count | IDs |
|---|---|---|
| Fixed | $nFixed | $FixedIds |
| Deferred | $nDeferred | $DeferredIds |
| Skipped | $nSkipped | $SkippedIds |
| Regression tests created | $nTests | $TestIds |

## Automated Checks

$(if ($nFixed -gt 0) {
  if ($missingTests -eq 0) { "- ✅ Every applied fix has at least one regression test" }
  else { "- ❌ $missingTests fix(es) missing a regression test" }
} else { "- ℹ️ No fixes applied — test-coverage check skipped" })
- Validation command: $validationStatus

## Verdict

**$verdict**

$notesStr

## Next Steps

1. Review ``04-change-register.md`` with the team.
2. Open a PR for branch ``$Branch``.
3. Trigger downstream re-runs as listed in ``04-change-register.md``.
4. Share ``05-upstream-impact.md`` with business-analyst / architect / developer / ux-designer.
"@
Set-Content -Path $ReportFile -Value $reportContent -Encoding UTF8

$filesList = if (-not $FilesModified -or $FilesModified -eq "(none)") { "_No files modified._" } else {
  (($FilesModified -split ";" | Where-Object { $_ } | ForEach-Object { "- `$_`" }) -join "`n")
}

$finalContent = @"
# Bug-Fixer — Final Report

**Timestamp:** $ts
**Branch:** $Branch
**Verdict:** $verdict

## Headline

- Fixes applied: **$nFixed**  ($FixedIds)
- Deferred:      $nDeferred ($DeferredIds)
- Skipped:       $nSkipped ($SkippedIds)
- Regression tests: $nTests ($TestIds)
- BFDEBT entries: $debtTotal

## Files Modified

$filesList

## Commits on ``$Branch``

$Commits

## Hand-off Checklist

- [ ] Open PR for ``$Branch``
- [ ] Run ``cqr-workflow -Auto`` on the modified files
- [ ] Run ``csr-workflow -Auto`` on the same files
- [ ] Hand ``03-regression-tests.md`` to the tester
- [ ] Send ``05-upstream-impact.md`` to BA / architect / developer / UX

---
"@
Set-Content -Path $FinalFile -Value $finalContent -Encoding UTF8

Write-BF-SuccessRule "✅ Phase 5 Complete — Verdict: $verdict"
Write-Host "  Report: $ReportFile"
Write-Host "  Final:  $FinalFile"
Write-Host ""
Write-Host "Share $script:BFOutputDir/05-upstream-impact.md with upstream agents."
Write-Host "Share $script:BFOutputDir/04-change-register.md with downstream reviewers.`n"
