# =============================================================================
# _common.ps1 — Shared helpers for Project Manager skills (PowerShell).
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   . $PSScriptRoot\_common.ps1
#
# Features:
#   - PowerShell 5.1+ compatible
#   - Respects $env:PM_OUTPUT_DIR, falls back to ./pm-output
#   - Consistent PMDEBT numbering across all skills (reads existing count)
#   - Shared Ask-PM-Text / Ask-PM-YN / Ask-PM-Choice / Add-PM-Debt helpers
# =============================================================================

# ── Version guard ─────────────────────────────────────────────────────────────
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Host "ERROR: PowerShell 5.1 or later is required." -ForegroundColor Red
  exit 1
}

# ── Global state ──────────────────────────────────────────────────────────────
$script:PMOutputDir = $env:PM_OUTPUT_DIR -or (Join-Path (Get-Location) "pm-output")
$script:PMDebtFile = Join-Path $script:PMOutputDir "06-pm-debts.md"
$null = New-Item -ItemType Directory -Path $script:PMOutputDir -Force -ErrorAction SilentlyContinue

# ── Colors ────────────────────────────────────────────────────────────────────
$script:PMRed     = 31
$script:PMGreen   = 32
$script:PMYellow  = 33
$script:PMBlue    = 34
$script:PMCyan    = 36
$script:PMBold    = 1

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-PMColor {
  param([string]$Text, [int]$Color = 39, [int]$Style = 0)
  $esc = [char]27
  if ($Style -gt 0) {
    Write-Host "${esc}[$($Style);${Color}m$Text${esc}[0m" -NoNewline
  } else {
    Write-Host "${esc}[${Color}m$Text${esc}[0m" -NoNewline
  }
}

function Ask-PM-Text {
  param([string]$Prompt)
  Write-PMColor "▶ $Prompt" $script:PMYellow
  Write-Host ""
  $answer = Read-Host
  return $answer.Trim()
}

function Ask-PM-YN {
  param([string]$Prompt)
  while ($true) {
    Write-PMColor "▶ $Prompt (y/n): " $script:PMYellow
    Write-Host ""
    $answer = Read-Host
    $norm = $answer.ToLower().Trim()
    if ($norm -eq 'y' -or $norm -eq 'yes') { return "yes" }
    if ($norm -eq 'n' -or $norm -eq 'no') { return "no" }
    Write-Host "  Please type y or n." -ForegroundColor Red
  }
}

function Ask-PM-Choice {
  param([string]$Prompt, [string[]]$Options)
  Write-PMColor "▶ $Prompt" $script:PMYellow
  Write-Host ""
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i+1)) $($Options[$i])"
  }
  while ($true) {
    $choice = Read-Host
    if ($choice -match '^\d+$') {
      $num = [int]$choice
      if ($num -ge 1 -and $num -le $Options.Count) {
        return $Options[$num - 1]
      }
    }
    Write-Host "  Please enter a number between 1 and $($Options.Count)." -ForegroundColor Red
  }
}

function Confirm-PM-Save {
  param([string]$Prompt)
  $answer = Ask-PM-YN $Prompt
  return $answer -eq "yes"
}

function Get-PM-DebtCount {
  if (Test-Path $script:PMDebtFile) {
    $count = (Select-String -Path $script:PMDebtFile -Pattern '^## PMDEBT-' -ErrorAction SilentlyContinue | Measure-Object).Count
    return $count
  }
  return 0
}

function Add-PM-Debt {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  $current = Get-PM-DebtCount
  $next = $current + 1
  $id = "{0:D2}" -f $next

  $debtContent = @"

## PMDEBT-$($id): $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@
  Add-Content -Path $script:PMDebtFile -Value $debtContent
}

function Write-PM-Banner {
  param([string]$Text)
  Write-Host ""
  Write-PMColor "╔══════════════════════════════════════════════════════════╗" $script:PMBlue $script:PMBold
  Write-Host ""
  Write-PMColor "║  " $script:PMBlue $script:PMBold
  Write-Host -NoNewline ("{0,-56}" -f $Text)
  Write-PMColor "║" $script:PMBlue $script:PMBold
  Write-Host ""
  Write-PMColor "╚══════════════════════════════════════════════════════════╝" $script:PMBlue $script:PMBold
  Write-Host ""
  Write-Host ""
}

function Write-PM-SuccessRule {
  param([string]$Text)
  Write-Host "✓ " -NoNewline -ForegroundColor Green
  Write-Host $Text -ForegroundColor Green
}

function Write-PM-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor DarkGray
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-PM-Answer /
# Get-PM-YN / Get-PM-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "PMAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:PMAuto = $false
}
if ($env:PM_AUTO -and $env:PM_AUTO -match '^(1|true|yes)$') { $script:PMAuto = $true }

if (-not (Get-Variable -Name "PMAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:PMAnswers = $env:PM_ANSWERS
}

if (-not (Get-Variable -Name "PMUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:PMUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-PM-ParseFlags @args
function Invoke-PM-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:PMAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:PMAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:PMAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-PM-Auto { return [bool]$script:PMAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-PM-Extract {
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
function Resolve-PM-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:PMAnswers -and (Test-Path $script:PMAnswers)) {
    $v = Read-PM-Extract -Path $script:PMAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:PMUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-PM-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-PM-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-PM-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-PM-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-PM-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-PM-Auto) {
    if (-not $Default) {
      Add-PM-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-PM-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-PM-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-PM-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-PM-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-PM-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-PM-YN $Prompt)
}

function Get-PM-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-PM-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-PM-Auto) {
      Add-PM-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-PM-Auto) {
    Add-PM-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-PM-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-PM-Extract {
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
