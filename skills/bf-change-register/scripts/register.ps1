# =============================================================================
# register.ps1 — Phase 4: aggregate change register (PowerShell 5.1+)
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:BF_AUTO = '1' }
if ($Answers) { $env:BF_ANSWERS = $Answers }

$RegisterMd      = Join-Path $script:BFOutputDir "04-change-register.md"
$RegisterExtract = Join-Path $script:BFOutputDir "04-change-register.extract"
$UpstreamMd      = Join-Path $script:BFOutputDir "05-upstream-impact.md"
$FixExtract      = Join-Path $script:BFOutputDir "02-fixes.extract"
$RegTestExtract  = Join-Path $script:BFOutputDir "03-regression-tests.extract"
$AllPatches      = Join-Path $script:BFOutputDir "all-patches.diff"

Write-BF-Banner "Phase 4 — Change register"

if (-not (Test-Path $FixExtract)) {
  Write-Host "ERROR: Phase 2 extract not found. Run bf-fix first." -ForegroundColor Red
  exit 1
}

$FixedIds = Read-BF-Extract -Path $FixExtract -Key "FIXED_IDS"
$Branch   = Read-BF-Extract -Path $FixExtract -Key "BRANCH"
$Commits  = Read-BF-Extract -Path $FixExtract -Key "COMMITS"
$TestIds  = if (Test-Path $RegTestExtract) { Read-BF-Extract -Path $RegTestExtract -Key "TEST_IDS" } else { "" }

# Collect all files from the consolidated patch
$AllFiles = ""
if (Test-Path $AllPatches) {
  $files = Get-Content $AllPatches | Where-Object { $_ -match '^\+\+\+ b/' } |
           ForEach-Object { $_ -replace '^\+\+\+ b/','' } | Sort-Object -Unique
  $AllFiles = [string]::Join(";", $files)
}
if (-not $AllFiles) { $AllFiles = "(none)" }

function Classify-Upstream {
  param([string]$Files)
  $ba = @(); $arch = @(); $dev = @(); $ux = @()
  foreach ($f in ($Files -split ";")) {
    if (-not $f) { continue }
    if ($f -match "docs/requirements|ba-output|REQUIREMENTS") { $ba += $f }
    if ($f -match "docs/architecture|arch-output|ADR-|adr/") { $arch += $f }
    if ($f -match "(^|/)src/|(^|/)lib/|(^|/)app/|(^|/)internal/|(^|/)pkg/") { $dev += $f }
    if ($f -match "(^|/)ui/|(^|/)frontend/|components|views|pages|\.tsx$|\.jsx$|\.vue$|\.svelte$") { $ux += $f }
  }
  return @{
    ba   = if ($ba.Count)   { [string]::Join(";", $ba) }   else { "(none apparent)" }
    arch = if ($arch.Count) { [string]::Join(";", $arch) } else { "(none apparent)" }
    dev  = if ($dev.Count)  { [string]::Join(";", $dev) }  else { "(none apparent)" }
    ux   = if ($ux.Count)   { [string]::Join(";", $ux) }   else { "(none apparent)" }
  }
}

$up = Classify-Upstream -Files $AllFiles
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$filesList = if ($AllFiles -eq "(none)") { "_No files modified._" } else {
  ($AllFiles -split ";" | Where-Object { $_ } | ForEach-Object { "- `$_`" }) -join "`n"
}

$registerContent = @"
# Change Register

**Timestamp:** $ts
**Branch:** $Branch
**Fixed IDs:** $FixedIds
**Commits:**   $Commits
**Regression test IDs:** $(if ($TestIds) { $TestIds } else { '(none)' })

## Files Modified (Batch)

$filesList

## Downstream Reviewers

- **code-quality-reviewer:** re-run on touched files (see extract ``FILES_MODIFIED``)
- **code-security-reviewer:** re-run on touched files
- **tester:** merge regression tests from ``03-regression-tests.md`` into ``test-output/02-test-cases.md``, then re-execute

---
"@
Set-Content -Path $RegisterMd -Value $registerContent -Encoding UTF8

function Format-UpBlock {
  param([string]$Val)
  if ($Val -eq "(none apparent)") { return "- $Val" }
  return (($Val -split ";" | Where-Object { $_ } | ForEach-Object { "- `$_`" }) -join "`n")
}

$upstreamContent = @"
# Upstream Impact

**Timestamp:** $ts
**Branch:** $Branch

Each section below is consumed by the named agent on its next run.

## business-analyst

$(Format-UpBlock $up.ba)

Action: if any fix changes user-observable behaviour, re-visit the matching
user story's acceptance criteria.

## architect

$(Format-UpBlock $up.arch)

Action: check ADRs referenced by the fix commit messages — any new pattern
probably needs a superseding ADR.

## developer

$(Format-UpBlock $up.dev)

Action: update ``dev-output/01-detailed-design.md`` if module boundaries /
class structure / APIs changed.

## ux-designer

$(Format-UpBlock $up.ux)

Action: re-check wireframes if user-facing UI changed.

---
"@
Set-Content -Path $UpstreamMd -Value $upstreamContent -Encoding UTF8

Write-BF-Extract -Path $RegisterExtract -Pairs @{
  FILES_MODIFIED     = $AllFiles
  UPSTREAM_AFFECTED  = "ba:$($up.ba);arch:$($up.arch);dev:$($up.dev);ux:$($up.ux)"
  DOWNSTREAM_AFFECTED = "cqr;csr;tester"
  BRANCH             = $Branch
  FIXED_IDS          = $FixedIds
  COMMITS            = $Commits
  TEST_IDS           = $TestIds
}

Write-BF-SuccessRule "✅ Phase 4 Complete"
Write-Host "  Change register: $RegisterMd"
Write-Host "  Upstream impact: $UpstreamMd"
Write-Host "  Extract:         $RegisterExtract"
Write-Host "`nNext: Phase 5 — pwsh <SKILL_DIR>/bf-validation/scripts/validate.ps1`n"
