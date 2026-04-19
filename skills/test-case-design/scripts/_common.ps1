# =============================================================================
# _common.ps1 — Shared helpers for test skills (PowerShell 5.1+)
#
# Dot-source this file from a sibling script in the same scripts/ folder:
#   $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
#   . "$ScriptDir\_common.ps1"
#
# Features:
#   - PowerShell 5.1+ and Core 7+ compatible
#   - Respects $env:TEST_OUTPUT_DIR, falls back to ./test-output
#   - Consistent TQDEBT numbering across all skills
#   - Shared Ask-TST-Text, Ask-TST-YN, Ask-TST-Choice helpers
# =============================================================================

# ── Colours ──────────────────────────────────────────────────────────────────
$script:TSTRed = "`e[0;31m"
$script:TSTGreen = "`e[0;32m"
$script:TSTYellow = "`e[1;33m"
$script:TSTBlue = "`e[0;34m"
$script:TSTCyan = "`e[0;36m"
$script:TSTMagenta = "`e[0;35m"
$script:TSTBold = "`e[1m"
$script:TSTDim = "`e[2m"
$script:TSTNc = "`e[0m"

# ── Paths ─────────────────────────────────────────────────────────────────────
$script:TSTOutputDir = if ($env:TEST_OUTPUT_DIR) { $env:TEST_OUTPUT_DIR } else { "$(Get-Location)\test-output" }
$script:TSTDebtFile = "$script:TSTOutputDir\05-test-debts.md"

if (-not (Test-Path $script:TSTOutputDir)) {
  New-Item -ItemType Directory -Path $script:TSTOutputDir -Force | Out-Null
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Ask-TST-Text: Prompt for a text response, return trimmed answer.
function Ask-TST-Text {
  param([string]$Prompt)
  Write-Host "$($script:TSTYellow)▶ $Prompt$($script:TSTNc)"
  $answer = Read-Host
  return $answer.Trim()
}

# Ask-TST-YN: Prompt for y/n, return "yes" or "no". Loops until valid.
function Ask-TST-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "$($script:TSTYellow)▶ $Prompt (y/n): $($script:TSTNc)"
    $raw = Read-Host
    $norm = $raw.ToLower().Trim()
    if ($norm -eq 'y' -or $norm -eq 'yes') {
      return "yes"
    } elseif ($norm -eq 'n' -or $norm -eq 'no') {
      return "no"
    } else {
      Write-Host "$($script:TSTRed)  Please type y or n.$($script:TSTNc)"
    }
  }
}

# Ask-TST-Choice: Prompt for numbered choice, return selected option string.
function Ask-TST-Choice {
  param([string]$Prompt, [string[]]$Options)

  Write-Host "$($script:TSTYellow)▶ $Prompt$($script:TSTNc)"
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i + 1)) $($Options[$i])"
  }

  while ($true) {
    $choice = Read-Host
    if ([int]::TryParse($choice, [ref]$null) -and $choice -ge 1 -and $choice -le $Options.Count) {
      return $Options[$choice - 1]
    }
    Write-Host "$($script:TSTRed)  Please enter a number between 1 and $($Options.Count).$($script:TSTNc)"
  }
}

# Confirm-TST-Save: Ask y/n, return $true if "yes", $false if "no".
function Confirm-TST-Save {
  param([string]$Prompt)
  $answer = Ask-TST-YN $Prompt
  return ($answer -eq "yes")
}

# Get-TST-DebtCount: Read current number of TQDEBT-NN entries in debt file.
function Get-TST-DebtCount {
  if (-not (Test-Path $script:TSTDebtFile)) {
    return 0
  }
  $count = (Get-Content $script:TSTDebtFile | Select-String '^## TQDEBT-' | Measure-Object).Count
  return if ($count) { $count } else { 0 }
}

# Add-TST-Debt: Append a new debt with next sequential ID.
function Add-TST-Debt {
  param(
    [string]$Area,
    [string]$Title,
    [string]$Description,
    [string]$Impact
  )

  $current = Get-TST-DebtCount
  $next = $current + 1
  $id = $next.ToString("D2")

  $debt = @"

## TQDEBT-$id`: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@

  Add-Content -Path $script:TSTDebtFile -Value $debt
}

# Write-TST-Banner: Print a two-line boxed banner.
function Write-TST-Banner {
  param([string]$Text)
  Write-Host ""
  Write-Host "$($script:TSTCyan)$($script:TSTBold)╔══════════════════════════════════════════════════════════╗$($script:TSTNc)"
  Write-Host "$($script:TSTCyan)$($script:TSTBold)║  $(($Text).PadRight(56))║$($script:TSTNc)"
  Write-Host "$($script:TSTCyan)$($script:TSTBold)╚══════════════════════════════════════════════════════════╝$($script:TSTNc)"
  Write-Host ""
}

# Write-TST-SuccessRule: Print a green horizontal rule.
function Write-TST-SuccessRule {
  param([string]$Text)
  Write-Host ""
  Write-Host "$($script:TSTGreen)$($script:TSTBold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TSTNc)"
  Write-Host "$($script:TSTGreen)$($script:TSTBold)  $Text$($script:TSTNc)"
  Write-Host "$($script:TSTGreen)$($script:TSTBold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TSTNc)"
  Write-Host ""
}

# Write-TST-Dim: Print text in dim grey.
function Write-TST-Dim {
  param([string]$Text)
  Write-Host "$($script:TSTDim)$Text$($script:TSTNc)"
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-TEST-Answer /
# Get-TEST-YN / Get-TEST-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "TESTAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:TESTAuto = $false
}
if ($env:TEST_AUTO -and $env:TEST_AUTO -match '^(1|true|yes)$') { $script:TESTAuto = $true }

if (-not (Get-Variable -Name "TESTAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:TESTAnswers = $env:TEST_ANSWERS
}

if (-not (Get-Variable -Name "TESTUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:TESTUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-TEST-ParseFlags @args
function Invoke-TEST-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:TESTAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:TESTAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:TESTAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-TEST-Auto { return [bool]$script:TESTAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-TEST-Extract {
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
function Resolve-TEST-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:TESTAnswers -and (Test-Path $script:TESTAnswers)) {
    $v = Read-TEST-Extract -Path $script:TESTAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:TESTUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-TEST-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-TEST-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-TEST-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-TEST-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-TEST-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-TEST-Auto) {
    if (-not $Default) {
      Add-TEST-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-TEST-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-TEST-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-TEST-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-TEST-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-TEST-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-TEST-YN $Prompt)
}

function Get-TEST-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-TEST-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-TEST-Auto) {
      Add-TEST-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-TEST-Auto) {
    Add-TEST-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-TEST-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-TEST-Extract {
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
