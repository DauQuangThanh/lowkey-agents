# =============================================================================
# _common.ps1 — Shared helpers for UX skills (PowerShell)
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   . "$PSScriptRoot\_common.ps1"
#
# Features:
#   - PowerShell 5.1+ compatible
#   - Respects $env:UX_OUTPUT_DIR, falls back to ./ux-output
#   - Continuous UXDEBT numbering across all UX skills
#   - Functions: Ask-UX-Text, Ask-UX-YN, Ask-UX-Choice, Add-UX-Debt, etc.
# =============================================================================

#Requires -Version 5.1

# ── Paths ─────────────────────────────────────────────────────────────────────
$script:UXOutputDir = if ($env:UX_OUTPUT_DIR) { $env:UX_OUTPUT_DIR } else { Join-Path (Get-Location) "ux-output" }
$script:UXBAInputDir = if ($env:UX_BA_INPUT_DIR) { $env:UX_BA_INPUT_DIR } else { Join-Path (Get-Location) "ba-output" }
$script:UXDebtFile = Join-Path $script:UXOutputDir "05-ux-debts.md"

if (-not (Test-Path $script:UXOutputDir)) {
  New-Item -ItemType Directory -Path $script:UXOutputDir -Force | Out-Null
}

# ── Colours (using ANSI codes) ────────────────────────────────────────────────
$script:UX_RED = "`e[0;31m"
$script:UX_GREEN = "`e[0;32m"
$script:UX_YELLOW = "`e[1;33m"
$script:UX_BLUE = "`e[0;34m"
$script:UX_CYAN = "`e[0;36m"
$script:UX_MAGENTA = "`e[0;35m"
$script:UX_BOLD = "`e[1m"
$script:UX_DIM = "`e[2m"
$script:UX_NC = "`e[0m"

# ── Helper Functions ──────────────────────────────────────────────────────────

function Ask-UX-Text {
  param([string]$Prompt)
  Write-Host "$($script:UX_YELLOW)▶ $Prompt$($script:UX_NC)"
  return (Read-Host).Trim()
}

function Ask-UX-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "$($script:UX_YELLOW)▶ $Prompt (y/n):$($script:UX_NC)"
    $response = (Read-Host).Trim().ToLower()
    if ($response -eq 'y' -or $response -eq 'yes') { return 'yes' }
    if ($response -eq 'n' -or $response -eq 'no') { return 'no' }
    Write-Host "$($script:UX_RED)  Please type y or n.$($script:UX_NC)"
  }
}

function Ask-UX-Choice {
  param(
    [string]$Prompt,
    [string[]]$Options
  )
  Write-Host "$($script:UX_YELLOW)▶ $Prompt$($script:UX_NC)"
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i + 1)) $($Options[$i])"
  }
  while ($true) {
    $choice = (Read-Host).Trim()
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
      return $Options[[int]$choice - 1]
    }
    Write-Host "$($script:UX_RED)  Please enter a number between 1 and $($Options.Count).$($script:UX_NC)"
  }
}

function Confirm-UX-Save {
  param([string]$Prompt)
  return (Ask-UX-YN $Prompt) -eq 'yes'
}

function Get-UX-DebtCount {
  if (Test-Path $script:UXDebtFile) {
    $count = (Select-String -Path $script:UXDebtFile -Pattern '^## UXDEBT-' -ErrorAction SilentlyContinue | Measure-Object).Count
    return [int]$count
  }
  return 0
}

function Add-UX-Debt {
  param(
    [string]$Area,
    [string]$Title,
    [string]$Description,
    [string]$Impact
  )
  $current = Get-UX-DebtCount
  $next = $current + 1
  $id = $next.ToString("00")

  $content = @"

## UXDEBT-$id`: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Linked:** TBD
**Status:** Open

"@
  Add-Content -Path $script:UXDebtFile -Value $content -Encoding UTF8
}

function Write-UX-Banner {
  param([string]$Title)
  Write-Host ""
  Write-Host "$($script:UX_MAGENTA)$($script:UX_BOLD)╔══════════════════════════════════════════════════════════╗$($script:UX_NC)"
  Write-Host "$($script:UX_MAGENTA)$($script:UX_BOLD)║  $('{0,-56}' -f $Title)║$($script:UX_NC)"
  Write-Host "$($script:UX_MAGENTA)$($script:UX_BOLD)╚══════════════════════════════════════════════════════════╝$($script:UX_NC)"
  Write-Host ""
}

function Write-UX-SuccessRule {
  param([string]$Message)
  Write-Host ""
  Write-Host "$($script:UX_GREEN)$($script:UX_BOLD)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:UX_NC)"
  Write-Host "$($script:UX_GREEN)$($script:UX_BOLD)  $Message$($script:UX_NC)"
  Write-Host "$($script:UX_GREEN)$($script:UX_BOLD)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:UX_NC)"
  Write-Host ""
}

function Write-UX-Dim {
  param([string]$Message)
  Write-Host "$($script:UX_DIM)$Message$($script:UX_NC)"
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-UX-Answer /
# Get-UX-YN / Get-UX-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "UXAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:UXAuto = $false
}
if ($env:UX_AUTO -and $env:UX_AUTO -match '^(1|true|yes)$') { $script:UXAuto = $true }

if (-not (Get-Variable -Name "UXAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:UXAnswers = $env:UX_ANSWERS
}

if (-not (Get-Variable -Name "UXUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:UXUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-UX-ParseFlags @args
function Invoke-UX-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:UXAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:UXAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:UXAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-UX-Auto { return [bool]$script:UXAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-UX-Extract {
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
function Resolve-UX-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:UXAnswers -and (Test-Path $script:UXAnswers)) {
    $v = Read-UX-Extract -Path $script:UXAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:UXUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-UX-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-UX-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-UX-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-UX-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-UX-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-UX-Auto) {
    if (-not $Default) {
      Add-UX-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-UX-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-UX-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-UX-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-UX-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-UX-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-UX-YN $Prompt)
}

function Get-UX-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-UX-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-UX-Auto) {
      Add-UX-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-UX-Auto) {
    Add-UX-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-UX-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-UX-Extract {
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
