# =============================================================================
# _common.ps1 — Shared helpers for the bug-fixer (BF) skill family.
# Canonical PowerShell _common for bug-fixer. Sibling bf-* skills dot-source
# this via thin shims.
# =============================================================================

if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Host "ERROR: PowerShell 5.1 or later is required." -ForegroundColor Red
  exit 1
}

# ── Paths ─────────────────────────────────────────────────────────────────────
if ($env:BF_OUTPUT_DIR) {
  $script:BFOutputDir = $env:BF_OUTPUT_DIR
} else {
  $script:BFOutputDir = Join-Path (Get-Location) "bf-output"
}
$script:BFDebtFile = Join-Path $script:BFOutputDir "07-bf-debts.md"
New-Item -ItemType Directory -Path $script:BFOutputDir -Force | Out-Null

# ── Colours ──────────────────────────────────────────────────────────────────
$script:BFRed = "$([char]27)[0;31m"; $script:BFGreen  = "$([char]27)[0;32m"
$script:BFYellow = "$([char]27)[1;33m"; $script:BFBlue = "$([char]27)[0;34m"
$script:BFCyan = "$([char]27)[0;36m"; $script:BFOrange = "$([char]27)[38;5;208m"
$script:BFBold = "$([char]27)[1m"; $script:BFDim = "$([char]27)[2m"
$script:BFNc = "$([char]27)[0m"

# ── Interactive helpers ──────────────────────────────────────────────────────
function Ask-BF-Text {
  param([string]$Prompt)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  return (Read-Host).Trim()
}

function Ask-BF-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "▶ $Prompt (y/n): " -ForegroundColor Yellow -NoNewline
    $ans = (Read-Host).ToLower().Trim()
    if ($ans -in "y","yes") { return "yes" }
    if ($ans -in "n","no")  { return "no"  }
    Write-Host "  Please type y or n." -ForegroundColor Red
  }
}

function Ask-BF-Choice {
  param([string]$Prompt, [string[]]$Options)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i + 1)) $($Options[$i])"
  }
  while ($true) {
    $choice = Read-Host
    if ($choice -match '^\d+$') {
      $idx = [int]$choice - 1
      if ($idx -ge 0 -and $idx -lt $Options.Count) { return $Options[$idx] }
    }
    Write-Host "  Please enter a number between 1 and $($Options.Count)." -ForegroundColor Red
  }
}

function Confirm-BF-Save {
  param([string]$Prompt)
  return ((Ask-BF-YN $Prompt) -eq "yes")
}

function Get-BF-DebtCount {
  if (-not (Test-Path $script:BFDebtFile)) { return 0 }
  $matches = @(Select-String -Path $script:BFDebtFile -Pattern "^## BFDEBT-" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

function Add-BF-Debt {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  $current = Get-BF-DebtCount
  $next = $current + 1
  $id = $next.ToString("D2")
  $entry = @"

## BFDEBT-${id}: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@
  Add-Content -Path $script:BFDebtFile -Value $entry -Encoding UTF8
}

function Write-BF-Banner {
  param([string]$Title)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
  Write-Host ("║  {0,-56}║" -f $Title) -ForegroundColor Yellow
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
  Write-Host ""
}

function Write-BF-SuccessRule {
  param([string]$Text = "")
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  if ($Text) { Write-Host "  $Text" -ForegroundColor Green }
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host ""
}

function Write-BF-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor DarkGray
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS (mirror of the Bash contract)
# ═════════════════════════════════════════════════════════════════════════════

if (-not (Get-Variable -Name "BFAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BFAuto = $false
}
if ($env:BF_AUTO -and $env:BF_AUTO -match '^(1|true|yes)$') { $script:BFAuto = $true }

if (-not (Get-Variable -Name "BFAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BFAnswers = $env:BF_ANSWERS
}

if (-not (Get-Variable -Name "BFDryRun" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BFDryRun = $false
}
if ($env:BF_DRY_RUN -and $env:BF_DRY_RUN -match '^(1|true|yes)$') { $script:BFDryRun = $true }

if (-not (Get-Variable -Name "BFBranch" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BFBranch = $env:BF_BRANCH
}

if (-not (Get-Variable -Name "BFUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $_BfTestOut = if ($env:TEST_OUTPUT_DIR) { $env:TEST_OUTPUT_DIR } else { Join-Path (Get-Location) "test-output" }
  $_BfCqrOut  = if ($env:CQR_OUTPUT_DIR)  { $env:CQR_OUTPUT_DIR }  else { Join-Path (Get-Location) "cqr-output" }
  $_BfCsrOut  = if ($env:CSR_OUTPUT_DIR)  { $env:CSR_OUTPUT_DIR }  else { Join-Path (Get-Location) "csr-output" }
  $script:BFUpstreamExtracts = @(
    (Join-Path $_BfTestOut "bugs.extract"),
    (Join-Path $_BfCqrOut  "05-cq-debts.md"),
    (Join-Path $_BfCsrOut  "CSR-FINAL.md")
  )
}

function Invoke-BF-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'          { $script:BFAuto = $true; $env:BF_AUTO = '1'; $i++ }
      '^--answers$'       { if ($i + 1 -lt $Args.Count) { $script:BFAnswers = $Args[$i+1]; $env:BF_ANSWERS = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$'  { $script:BFAnswers = $Matches[1]; $env:BF_ANSWERS = $Matches[1]; $i++ }
      '^--branch$'        { if ($i + 1 -lt $Args.Count) { $script:BFBranch = $Args[$i+1]; $env:BF_BRANCH = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--branch=(.+)$'   { $script:BFBranch = $Matches[1]; $env:BF_BRANCH = $Matches[1]; $i++ }
      '^--dry-run$'       { $script:BFDryRun = $true; $env:BF_DRY_RUN = '1'; $i++ }
      default             { $i++ }
    }
  }
}

function Test-BF-Auto   { return [bool]$script:BFAuto }
function Test-BF-DryRun { return [bool]$script:BFDryRun }

function Read-BF-Extract {
  param([string]$Path, [string]$Key)
  if (-not (Test-Path $Path)) { return "" }
  foreach ($line in Get-Content -Path $Path -ErrorAction SilentlyContinue) {
    $trim = $line.Trim()
    if ($trim -eq "" -or $trim.StartsWith("#")) { continue }
    $eq = $trim.IndexOf("=")
    if ($eq -lt 1) { continue }
    $k = $trim.Substring(0, $eq).Trim()
    if ($k -eq $Key) { return $trim.Substring($eq + 1).Trim() }
  }
  return ""
}

function Resolve-BF-Answer {
  param([string]$Key, [string]$Default = "")
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  if ($script:BFAnswers -and (Test-Path $script:BFAnswers)) {
    $v = Read-BF-Extract -Path $script:BFAnswers -Key $Key
    if ($v) { return $v }
  }
  foreach ($f in $script:BFUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-BF-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  return $Default
}

function Add-BF-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-BF-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

function Get-BF-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-BF-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-BF-Auto) {
    if (-not $Default) {
      Add-BF-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' in auto mode, no default documented" `
        -Impact "Downstream field blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-BF-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-BF-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-BF-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-BF-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-BF-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' in auto mode" -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-BF-YN $Prompt)
}

function Get-BF-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-BF-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-BF-Auto) {
      Add-BF-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved '$v' not in option list" -Impact "Defaulting to first option"
      return $Options[0]
    }
  }
  if (Test-BF-Auto) {
    Add-BF-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' in auto mode" -Impact "Defaulting to first option"
    return $Options[0]
  }
  return (Ask-BF-Choice -Prompt $Prompt -Options $Options)
}

function Write-BF-Extract {
  param([string]$Path, [hashtable]$Pairs)
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $lines = @(
    "# Auto-generated extract — KEY=VALUE per line. Edit with care.",
    "# Generated: $now"
  )
  foreach ($key in $Pairs.Keys) { $lines += "$key=$($Pairs[$key])" }
  Set-Content -Path $Path -Value $lines -Encoding UTF8
}
