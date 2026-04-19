# =============================================================================
# _common.ps1 — Shared helpers for Test Architect skills (PowerShell 5.1+/7+)
# =============================================================================

# Version guard
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Error "PowerShell 5.1 or later is required. Current: $($PSVersionTable.PSVersion)"
  exit 1
}

# Paths
$script:TAOutputDir = $env:TA_OUTPUT_DIR -or (Join-Path (Get-Location) "ta-output")
$script:TABAInputDir = $env:TA_BA_INPUT_DIR -or (Join-Path (Get-Location) "ba-output")
$script:TAArchInputDir = $env:TA_ARCH_INPUT_DIR -or (Join-Path (Get-Location) "arch-output")
$script:TADebtFile = Join-Path $script:TAOutputDir "06-ta-debts.md"

if (-not (Test-Path $script:TAOutputDir -PathType Container)) {
  New-Item -ItemType Directory -Path $script:TAOutputDir -Force | Out-Null
}

# Colour definitions
$script:TAColours = @{
  Red     = "`e[0;31m"
  Green   = "`e[0;32m"
  Yellow  = "`e[1;33m"
  Blue    = "`e[0;34m"
  Cyan    = "`e[0;36m"
  Magenta = "`e[0;35m"
  Bold    = "`e[1m"
  Dim     = "`e[2m"
  NC      = "`e[0m"
}

# Helper functions

function Ask-TA-Text {
  param([string]$Prompt)
  Write-Host "$($script:TAColours.Yellow)▶ $Prompt$($script:TAColours.NC)"
  return (Read-Host)
}

function Ask-TA-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "$($script:TAColours.Yellow)▶ $Prompt (y/n): $($script:TAColours.NC)" -NoNewline
    $response = (Read-Host).ToLower()
    if ($response -eq "y" -or $response -eq "yes") {
      return "yes"
    } elseif ($response -eq "n" -or $response -eq "no") {
      return "no"
    } else {
      Write-Host "$($script:TAColours.Red)  Please type y or n.$($script:TAColours.NC)"
    }
  }
}

function Ask-TA-Choice {
  param([string]$Prompt, [string[]]$Options)
  Write-Host "$($script:TAColours.Yellow)▶ $Prompt$($script:TAColours.NC)"
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i+1)) $($Options[$i])"
  }
  while ($true) {
    $choice = Read-Host
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
      return $Options[[int]$choice - 1]
    }
    Write-Host "$($script:TAColours.Red)  Please enter a number between 1 and $($Options.Count).$($script:TAColours.NC)"
  }
}

function Confirm-TA-Save {
  param([string]$Prompt)
  return (Ask-TA-YN $Prompt) -eq "yes"
}

function Get-TA-DebtCount {
  if (Test-Path $script:TADebtFile) {
    $count = @(Select-String -Path $script:TADebtFile -Pattern '^## TADEBT-' -ErrorAction SilentlyContinue).Count
    return $count
  }
  return 0
}

function Add-TA-Debt {
  param([string]$Title, [string]$Description, [string]$Impact)
  $count = Get-TA-DebtCount
  $nextId = "TADEBT-{0:D2}" -f ($count + 1)

  $debt = @"

## $nextId : $Title
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@

  Add-Content -Path $script:TADebtFile -Value $debt
}

function Write-TA-Banner {
  param([string]$Message)
  Write-Host "`n$($script:TAColours.Cyan)$($script:TAColours.Bold)╔══════════════════════════════════════════════════════════╗$($script:TAColours.NC)"
  Write-Host "$($script:TAColours.Cyan)$($script:TAColours.Bold)║  $($Message.PadRight(56))║$($script:TAColours.NC)"
  Write-Host "$($script:TAColours.Cyan)$($script:TAColours.Bold)╚══════════════════════════════════════════════════════════╝$($script:TAColours.NC)`n"
}

function Write-TA-SuccessRule {
  param([string]$Message)
  Write-Host "`n$($script:TAColours.Green)$($script:TAColours.Bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TAColours.NC)"
  Write-Host "$($script:TAColours.Green)$($script:TAColours.Bold)  $Message$($script:TAColours.NC)"
  Write-Host "$($script:TAColours.Green)$($script:TAColours.Bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TAColours.NC)`n"
}

function Write-TA-Dim {
  param([string]$Message)
  Write-Host "$($script:TAColours.Dim)$Message$($script:TAColours.NC)"
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-TA-Answer /
# Get-TA-YN / Get-TA-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "TAAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:TAAuto = $false
}
if ($env:TA_AUTO -and $env:TA_AUTO -match '^(1|true|yes)$') { $script:TAAuto = $true }

if (-not (Get-Variable -Name "TAAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:TAAnswers = $env:TA_ANSWERS
}

if (-not (Get-Variable -Name "TAUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:TAUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-TA-ParseFlags @args
function Invoke-TA-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:TAAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:TAAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:TAAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-TA-Auto { return [bool]$script:TAAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-TA-Extract {
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
function Resolve-TA-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:TAAnswers -and (Test-Path $script:TAAnswers)) {
    $v = Read-TA-Extract -Path $script:TAAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:TAUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-TA-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-TA-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-TA-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-TA-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-TA-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-TA-Auto) {
    if (-not $Default) {
      Add-TA-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-TA-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-TA-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-TA-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-TA-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-TA-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-TA-YN $Prompt)
}

function Get-TA-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-TA-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-TA-Auto) {
      Add-TA-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-TA-Auto) {
    Add-TA-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-TA-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-TA-Extract {
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
