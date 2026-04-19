# =============================================================================
# _common.ps1 — Shared PowerShell helpers for code quality reviewer skills
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   . "$PSScriptRoot/_common.ps1"
#
# Features:
#   - PowerShell 5.1+ compatible
#   - Respects $env:CQR_OUTPUT_DIR, falls back to ./cqr-output
#   - Continuous CQDEBT numbering across all skills
#   - Shared Ask-CQR-Text, Ask-CQR-YN, Ask-CQR-Choice helpers
# =============================================================================

#Requires -Version 5.1

# ── Paths ─────────────────────────────────────────────────────────────────────
$script:CQROutputDir = if ($env:CQR_OUTPUT_DIR) { $env:CQR_OUTPUT_DIR } else { "$(Get-Location)/cqr-output" }
$script:CQRDebtFile = "$script:CQROutputDir/05-cq-debts.md"

# Ensure output directory exists
if (-not (Test-Path -Path $script:CQROutputDir -PathType Container)) {
  New-Item -Path $script:CQROutputDir -ItemType Directory -Force | Out-Null
}

# ── Colours ───────────────────────────────────────────────────────────────────
$script:CQRRed = "`e[0;31m"
$script:CQRGreen = "`e[0;32m"
$script:CQRYellow = "`e[1;33m"
$script:CQRBlue = "`e[0;34m"
$script:CQRCyan = "`e[0;36m"
$script:CQRBold = "`e[1m"
$script:CQRDim = "`e[2m"
$script:CQRBrightGreen = "`e[1;32m"
$script:CQRNc = "`e[0m"

# ── Helper Functions ──────────────────────────────────────────────────────────

# Ask-CQR-Text: Prompt for text input
function Ask-CQR-Text {
  param([string]$Prompt)
  Write-Host "$($script:CQRYellow)▶ $Prompt$($script:CQRNc)"
  return (Read-Host).Trim()
}

# Ask-CQR-YN: Prompt for yes/no answer
function Ask-CQR-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "$($script:CQRYellow)▶ $Prompt (y/n): $($script:CQRNc)"
    $response = (Read-Host).Trim().ToLower()
    if ($response -eq 'y' -or $response -eq 'yes') {
      return 'yes'
    } elseif ($response -eq 'n' -or $response -eq 'no') {
      return 'no'
    } else {
      Write-Host "$($script:CQRRed)  Please type y or n.$($script:CQRNc)"
    }
  }
}

# Ask-CQR-Choice: Prompt for choice from list
function Ask-CQR-Choice {
  param(
    [string]$Prompt,
    [string[]]$Options
  )
  Write-Host "$($script:CQRYellow)▶ $Prompt$($script:CQRNc)"
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i+1)) $($Options[$i])"
  }
  while ($true) {
    $choice = (Read-Host).Trim()
    if ([int]::TryParse($choice, [ref]$null) -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
      return $Options[[int]$choice - 1]
    } else {
      Write-Host "$($script:CQRRed)  Please enter a number between 1 and $($Options.Count).$($script:CQRNc)"
    }
  }
}

# Confirm-CQR-Save: Confirm answer before saving
function Confirm-CQR-Save {
  param([string]$Answer)
  Write-Host "`n$($script:CQRCyan)You answered: $($script:CQRBold)$Answer$($script:CQRNc)"
  $yn = Ask-CQR-YN "Is this correct?"
  if ($yn -eq 'yes') {
    return 'yes'
  } else {
    return 'redo'
  }
}

# Get-CQR-DebtCount: Count existing debt entries
function Get-CQR-DebtCount {
  if (Test-Path -Path $script:CQRDebtFile -PathType Leaf) {
    return (Select-String -Path $script:CQRDebtFile -Pattern '^## CQDEBT-' | Measure-Object).Count
  } else {
    return 0
  }
}

# Add-CQR-Debt: Add a debt entry
# Usage: Add-CQR-Debt -Title "Title" -Description "Description" -Severity "Major" -Effort "M"
function Add-CQR-Debt {
  param(
    [string]$Title,
    [string]$Description,
    [string]$Severity,
    [string]$Effort
  )
  $count = Get-CQR-DebtCount
  $nextId = $count + 1
  $idFormatted = "{0:D2}" -f $nextId
  $timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

  # Ensure debt file exists with header
  if (-not (Test-Path -Path $script:CQRDebtFile -PathType Leaf)) {
    @"
# Code Quality Debt Register (CQDEBT-NN)

This file tracks technical debt entries discovered during code quality reviews.
Format: CQDEBT-NN (2-digit incrementing ID)
Status: tracked (awaiting resolution)

---

"@ | Out-File -Path $script:CQRDebtFile -Encoding UTF8 -Force
  }

  # Append debt entry
  $debtEntry = @"

## CQDEBT-$idFormatted: $Title

| Field | Value |
|---|---|
| **Status** | Tracked |
| **Severity** | $Severity |
| **Effort** | $Effort |
| **Found** | $timestamp |
| **Description** | $Description |

"@

  Add-Content -Path $script:CQRDebtFile -Value $debtEntry -Encoding UTF8
}

# Write-CQR-Banner: Print section banner
function Write-CQR-Banner {
  param([string]$Text)
  Write-Host "`n$($script:CQRBrightGreen)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:CQRNc)"
  Write-Host "$($script:CQRBrightGreen)$Text$($script:CQRNc)"
  Write-Host "$($script:CQRBrightGreen)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:CQRNc)"
}

# Write-CQR-SuccessRule: Print success divider
function Write-CQR-SuccessRule {
  Write-Host "`n$($script:CQRGreen)─────────────────────────────────────────$($script:CQRNc)"
}

# Write-CQR-Dim: Print dimmed text
function Write-CQR-Dim {
  param([string]$Text)
  Write-Host "$($script:CQRDim)$Text$($script:CQRNc)"
}

# Export module members
Export-ModuleMember -Function @(
  'Ask-CQR-Text',
  'Ask-CQR-YN',
  'Ask-CQR-Choice',
  'Confirm-CQR-Save',
  'Get-CQR-DebtCount',
  'Add-CQR-Debt',
  'Write-CQR-Banner',
  'Write-CQR-SuccessRule',
  'Write-CQR-Dim'
) -Variable @(
  'CQROutputDir',
  'CQRDebtFile',
  'CQRRed',
  'CQRGreen',
  'CQRYellow',
  'CQRBlue',
  'CQRCyan',
  'CQRBold',
  'CQRDim',
  'CQRBrightGreen',
  'CQRNc'
)

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-CQR-Answer /
# Get-CQR-YN / Get-CQR-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "CQRAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:CQRAuto = $false
}
if ($env:CQR_AUTO -and $env:CQR_AUTO -match '^(1|true|yes)$') { $script:CQRAuto = $true }

if (-not (Get-Variable -Name "CQRAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:CQRAnswers = $env:CQR_ANSWERS
}

if (-not (Get-Variable -Name "CQRUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $_CqrDevOut  = if ($env:DEV_OUTPUT_DIR)  { $env:DEV_OUTPUT_DIR }  else { Join-Path (Get-Location) "dev-output" }
  $_CqrArchOut = if ($env:ARCH_OUTPUT_DIR) { $env:ARCH_OUTPUT_DIR } else { Join-Path (Get-Location) "arch-output" }
  $script:CQRUpstreamExtracts = @(
    (Join-Path $_CqrDevOut  "01-detailed-design.extract"),
    (Join-Path $_CqrDevOut  "02-coding-plan.extract"),
    (Join-Path $_CqrDevOut  "03-unit-test-plan.extract"),
    (Join-Path $_CqrArchOut "01-architecture-intake.extract")
  )
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-CQR-ParseFlags @args
function Invoke-CQR-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:CQRAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:CQRAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:CQRAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-CQR-Auto { return [bool]$script:CQRAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-CQR-Extract {
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
function Resolve-CQR-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:CQRAnswers -and (Test-Path $script:CQRAnswers)) {
    $v = Read-CQR-Extract -Path $script:CQRAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:CQRUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-CQR-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# Maps 4-arg (Area, Title, Description, Impact) onto CQR's native
# Add-CQR-Debt(Title, Description, Severity, Effort) signature.
function Add-CQR-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-CQR-Debt -Title "[$Area] $Title" -Description "$Description — Impact: $Impact" -Severity "Major" -Effort "M"
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-CQR-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-CQR-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-CQR-Auto) {
    if (-not $Default) {
      Add-CQR-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-CQR-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-CQR-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-CQR-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-CQR-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-CQR-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-CQR-YN $Prompt)
}

function Get-CQR-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-CQR-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-CQR-Auto) {
      Add-CQR-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-CQR-Auto) {
    Add-CQR-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-CQR-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-CQR-Extract {
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
