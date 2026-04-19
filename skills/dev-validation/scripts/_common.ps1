# =============================================================================
# _common.ps1 — Shared helpers embedded inside this skill.
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   . $PSScriptRoot\_common.ps1
#
# Features:
#   - PowerShell 5.1 or 7+ compatible
#   - Respects $env:DEV_OUTPUT_DIR, falls back to ./dev-output
#   - Continuous DDEBT numbering across all developer skills
#   - Shared Ask-DEV-Text / Ask-DEV-YN / Ask-DEV-Choice / Add-DEV-Debt functions
# =============================================================================

#Requires -Version 5.1

# ── Version guard ───────────────────────────────────────────────────────────
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Error "PowerShell 5.1 or later is required. Current: $($PSVersionTable.PSVersion)" -ErrorAction Stop
}

# ── Colours (DEV_ prefix for green theme) ────────────────────────────────────
$script:DEVRed = "`e[0;31m"
$script:DEVGreen = "`e[0;32m"
$script:DEVYellow = "`e[1;33m"
$script:DEVBlue = "`e[0;34m"
$script:DEVCyan = "`e[0;36m"
$script:DEVOrange = "`e[0;33m"
$script:DEVBold = "`e[1m"
$script:DEVDim = "`e[2m"
$script:DEVNC = "`e[0m"

# ── Paths ────────────────────────────────────────────────────────────────────
$script:DEVOutputDir = if ($env:DEV_OUTPUT_DIR) { $env:DEV_OUTPUT_DIR } else { Join-Path (Get-Location) "dev-output" }
$script:DEVArchInputDir = if ($env:DEV_ARCH_INPUT_DIR) { $env:DEV_ARCH_INPUT_DIR } else { Join-Path (Get-Location) "arch-output" }
$script:DEVBAInputDir = if ($env:DEV_BA_INPUT_DIR) { $env:DEV_BA_INPUT_DIR } else { Join-Path (Get-Location) "ba-output" }
$script:DEVDebtFile = Join-Path $script:DEVOutputDir "05-design-debts.md"

if (-not (Test-Path $script:DEVOutputDir)) {
  $null = New-Item -ItemType Directory -Path $script:DEVOutputDir -Force
}

# ── Helpers ──────────────────────────────────────────────────────────────────

function To-Lower {
  param([string]$Text)
  return $Text.ToLowerInvariant()
}

function Dev-Slugify {
  param([string]$Text)
  $slug = $Text.ToLowerInvariant()
  $slug = [System.Text.RegularExpressions.Regex]::Replace($slug, '[^a-z0-9]', '-')
  $slug = [System.Text.RegularExpressions.Regex]::Replace($slug, '-{1,}', '-')
  $slug = $slug -replace '^-' -replace '-$'
  return $slug
}

function Ask-DEV-Text {
  param([string]$Prompt)
  Write-Host "`r▶ $Prompt" -ForegroundColor Yellow -NoNewline
  $answer = Read-Host
  return $answer.Trim()
}

function Ask-DEV-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "▶ $Prompt (y/n): " -ForegroundColor Yellow -NoNewline
    $raw = Read-Host
    $norm = To-Lower $raw
    switch ($norm) {
      { $_ -in @('y', 'yes') } { return "yes" }
      { $_ -in @('n', 'no') } { return "no" }
      default { Write-Host "  Please type y or n." -ForegroundColor Red }
    }
  }
}

function Ask-DEV-Choice {
  param([string]$Prompt, [string[]]$Options)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i + 1)) $($Options[$i])"
  }
  while ($true) {
    $choice = Read-Host
    if ([int]::TryParse($choice, [ref]$null) -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
      return $Options[[int]$choice - 1]
    }
    Write-Host "  Please enter a number between 1 and $($Options.Count)." -ForegroundColor Red
  }
}

function Confirm-DEV-Save {
  param([string]$Prompt)
  $answer = Ask-DEV-YN $Prompt
  return $answer -eq "yes"
}

function Get-DEV-DebtCount {
  if (Test-Path $script:DEVDebtFile) {
    $count = @(Get-Content $script:DEVDebtFile | Select-String '^## DDEBT-' | Measure-Object).Count
    return [int]$count
  }
  return 0
}

function Add-DEV-Debt {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  $current = Get-DEV-DebtCount
  $next = $current + 1
  $id = $next.ToString('D2')

  $debt = @"
## DDEBT-$id`: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Linked:** TBD
**Status:** Open

"@
  Add-Content -Path $script:DEVDebtFile -Value $debt
}

function Write-DEV-Banner {
  param([string]$Text)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor ($script:DEVOrange) -BackgroundColor ($script:DEVBold)
  Write-Host ("║  {0,-56}║" -f $Text) -ForegroundColor ($script:DEVOrange)
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor ($script:DEVOrange)
  Write-Host ""
}

function Write-DEV-SuccessRule {
  param([string]$Text)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor ($script:DEVGreen)
  Write-Host "  $Text" -ForegroundColor ($script:DEVGreen)
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor ($script:DEVGreen)
  Write-Host ""
}

function Write-DEV-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor ($script:DEVDim)
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-DEV-Answer /
# Get-DEV-YN / Get-DEV-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "DEVAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:DEVAuto = $false
}
if ($env:DEV_AUTO -and $env:DEV_AUTO -match '^(1|true|yes)$') { $script:DEVAuto = $true }

if (-not (Get-Variable -Name "DEVAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:DEVAnswers = $env:DEV_ANSWERS
}

if (-not (Get-Variable -Name "DEVUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:DEVUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-DEV-ParseFlags @args
function Invoke-DEV-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:DEVAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:DEVAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:DEVAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-DEV-Auto { return [bool]$script:DEVAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-DEV-Extract {
  param([string]$Path, [string]$Key)
  if (-not (Test-Path $Path)) { return "" }
  foreach ($line in Get-Content -Path $Path -ErrorAction SilentlyContinue) {
    $trim = $line.Trim()
    if ($trim -eq "" -or $trim.StartsWith("#")) { continue }
    $eq = $trim.IndexOf("=")
    if ($eq -lt 1) { continue }
    $k = $trim.Substring(0, $eq).Trim()
    if ($k -eq $Key) {
      return $trim.Substring($eq + 1).Trim()
    }
  }
  return ""
}

# ── Resolution chain ─────────────────────────────────────────────────────────
function Resolve-DEV-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:DEVAnswers -and (Test-Path $script:DEVAnswers)) {
    $v = Read-DEV-Extract -Path $script:DEVAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:DEVUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-DEV-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-DEV-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-DEV-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-DEV-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-DEV-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-DEV-Auto) {
    if (-not $Default) {
      Add-DEV-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-DEV-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-DEV-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-DEV-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-DEV-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-DEV-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-DEV-YN $Prompt)
}

function Get-DEV-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-DEV-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-DEV-Auto) {
      Add-DEV-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-DEV-Auto) {
    Add-DEV-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-DEV-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-DEV-Extract {
  param([string]$Path, [hashtable]$Pairs)
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $lines = @(
    "# Auto-generated extract — KEY=VALUE per line. Edit with care.",
    "# Generated: $now"
  )
  foreach ($key in $Pairs.Keys) {
    $lines += "$key=$($Pairs[$key])"
  }
  Set-Content -Path $Path -Value $lines -Encoding UTF8
}

# ── End of auto-mode helpers ─────────────────────────────────────────────────
