# =============================================================================
# Phase 6: Documentation Generation & Compilation (PowerShell)
# Stitches phases 1–5 into 06-documentation.md and writes RE-FINAL.md.
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

if ($Auto)    { $env:RE_AUTO    = '1' }
if ($Answers) { $env:RE_ANSWERS = $Answers }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "_common.ps1")

if (Get-Command Invoke-RE-ParseFlags -ErrorAction SilentlyContinue) {
  Invoke-RE-ParseFlags -Args $args
}

Initialize-RE-DebtFile
$DocFile   = Join-Path $script:REOutputDir "06-documentation.md"
$FinalFile = Join-Path $script:REOutputDir "RE-FINAL.md"

$phase1 = Join-Path $script:REOutputDir "01-codebase-inventory.md"
$phase2 = Join-Path $script:REOutputDir "02-architecture.md"
$phase3 = Join-Path $script:REOutputDir "03-api-documentation.md"
$phase4 = Join-Path $script:REOutputDir "04-data-model.md"
$phase5 = Join-Path $script:REOutputDir "05-dependency-map.md"
$debtFile = Join-Path $script:REOutputDir "07-re-debts.md"

$missing = @()
foreach ($f in @($phase1, $phase2, $phase3, $phase4, $phase5)) {
  if (-not (Test-Path $f)) { $missing += (Split-Path -Leaf $f) }
}
if ($missing.Count -gt 0) {
  Write-RE-Warning "Missing upstream phases: $($missing -join ', ')"
  Add-RE-DebtAuto -Area "Documentation" -Title "Missing upstream phase outputs" `
    -Description "Phase 6 ran without: $($missing -join ', ')" `
    -Impact "Final documentation will have gaps for these phases"
}

function Read-Ext {
  param([string]$File, [string]$Key, [string]$Default = "")
  if (-not (Test-Path $File)) { return $Default }
  $line = Get-Content $File -ErrorAction SilentlyContinue | Where-Object { $_ -match "^$Key=" } | Select-Object -First 1
  if (-not $line) { return $Default }
  $v = $line.Substring($Key.Length + 1)
  if (-not $v) { return $Default }
  return $v
}

$ext1 = Join-Path $script:REOutputDir "01-codebase-inventory.extract"
$ext2 = Join-Path $script:REOutputDir "02-architecture.extract"
$ext3 = Join-Path $script:REOutputDir "03-api-documentation.extract"
$ext4 = Join-Path $script:REOutputDir "04-data-model.extract"
$ext5 = Join-Path $script:REOutputDir "05-dependency-map.extract"

$totalFiles   = Read-Ext $ext1 "TOTAL_FILES" "(unknown)"
$totalLOC     = Read-Ext $ext1 "TOTAL_LOC"   "(unknown)"
$primaryLang  = Read-Ext $ext1 "PRIMARY_LANGUAGE" (Read-Ext $ext1 "LANGUAGES" "(unknown)")
$frameworks   = Read-Ext $ext2 "FRAMEWORKS" "(none detected)"
$layers       = Read-Ext $ext2 "LAYERS"     "(none detected)"
$deployment   = Read-Ext $ext2 "DEPLOYMENT" "(none detected)"
$restCount    = Read-Ext $ext3 "REST_ROUTE_COUNT" "0"
$storageFiles = Read-Ext $ext3 "CLIENT_STORAGE_FILES" "0"
$databases    = Read-Ext $ext4 "DATABASES" "(none detected)"
$orms         = Read-Ext $ext4 "ORMS"      "(none detected)"
$storageRefs  = Read-Ext $ext4 "CLIENT_STORAGE_KEY_REFS" "0"
$manifests    = Read-Ext $ext5 "MANIFESTS"   "(none found)"
$directDeps   = Read-Ext $ext5 "DIRECT_DEPS" "0"
$devDeps      = Read-Ext $ext5 "DEV_DEPS"    "0"
$debtCount    = Get-RE-DebtCount

$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# ── 06-documentation.md ─────────────────────────────────────────────────────
$doc = @(
  "# Reverse Engineering Report — Full Documentation",
  "",
  "**Generated:** $now",
  "",
  "This document stitches together every RE phase output for a project",
  "you can hand to a new engineer as-is.",
  "",
  "---",
  ""
)
foreach ($f in @($phase1, $phase2, $phase3, $phase4, $phase5)) {
  if (Test-Path $f) {
    $doc += Get-Content $f
    $doc += ""
    $doc += "---"
    $doc += ""
  }
}
if (Test-Path $debtFile) { $doc += Get-Content $debtFile }
Set-Content -Path $DocFile -Value $doc -Encoding UTF8

# ── RE-FINAL.md ─────────────────────────────────────────────────────────────
$sourceRoot = Read-Ext $ext1 "SOURCE_ROOT" ($env:SOURCE_ROOT)
if (-not $sourceRoot) { $sourceRoot = "unknown" }

$final = @(
  "# RE-FINAL — Reverse Engineering Executive Summary",
  "",
  "**Generated:** $now",
  "**Source root:** ``$sourceRoot``",
  "",
  "## At a Glance",
  "",
  "| Dimension | Value |",
  "|---|---|",
  "| Primary language    | $primaryLang |",
  "| Total files         | $totalFiles |",
  "| Total lines of code | $totalLOC |",
  "| Frameworks detected | $frameworks |",
  "| Layer directories   | $layers |",
  "| Deployment artefacts | $deployment |",
  "| REST routes         | $restCount |",
  "| Client storage refs | $storageRefs ($storageFiles files) |",
  "| Databases           | $databases |",
  "| ORMs                | $orms |",
  "| Package manifests   | $manifests |",
  "| Direct dependencies | $directDeps |",
  "| Dev dependencies    | $devDeps |",
  "| RE debts logged     | $debtCount |",
  "",
  "## Phase Completeness",
  ""
)
$phaseLabels = @(
  @{ Name = "Codebase Inventory"; File = "01-codebase-inventory.md" },
  @{ Name = "Architecture";       File = "02-architecture.md" },
  @{ Name = "APIs";                File = "03-api-documentation.md" },
  @{ Name = "Data Model";          File = "04-data-model.md" },
  @{ Name = "Dependencies";        File = "05-dependency-map.md" }
)
foreach ($p in $phaseLabels) {
  $full = Join-Path $script:REOutputDir $p.File
  if (Test-Path $full) {
    $final += "- ✅ $($p.Name) (``$($p.File)``)"
  } else {
    $final += "- ❌ $($p.Name) (``$($p.File)`` missing — phase didn't run)"
  }
}
$final += ""
$final += "## Next Steps"
$final += ""
$final += "1. Review ``06-documentation.md`` for the complete stitched report."
$final += "2. Clear ``07-re-debts.md`` ($debtCount item(s)) — areas the scripts could not determine automatically."
$step = 3
if ($restCount -eq "0" -and $storageRefs -ne "0") {
  $final += "${step}. This is a client-only application — its ""API"" is the browser storage contract, not HTTP."
  $step++
}
if ($directDeps -eq "0" -and $primaryLang -ne "(unknown)") {
  $final += "${step}. Zero external dependencies — suitable for air-gapped / offline deployment."
}
$final += ""
$final += "---"
$final += ""
$final += "_Generated by the RE workflow. See individual phase files in ``$script:REOutputDir`` for detail._"
$final += ""

Set-Content -Path $FinalFile -Value $final -Encoding UTF8

Write-RE-Success "Phase 6 complete — documentation compiled"
Write-Host ""
Write-Host "Outputs:"
Write-Host "  - $DocFile (full documentation)"
Write-Host "  - $FinalFile (executive summary)"
Write-Host "  - $debtFile ($debtCount debt(s) tracked)"
