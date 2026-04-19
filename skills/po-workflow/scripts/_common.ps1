# =============================================================================
# _common.ps1 — Shared helpers embedded inside the Product Owner skills.
#
# DOT-SOURCING (from a sibling script in the same scripts\ folder):
#   $ScriptDir = $PSScriptRoot
#   . (Join-Path $ScriptDir "_common.ps1")
#
# Features:
#   - PowerShell 7+ recommended; compatible with PowerShell 5.1 on Windows
#   - Respects $env:PO_OUTPUT_DIR, falls back to .\po-output
#   - Consistent PODEBT numbering across all skills (reads existing count)
#   - Shared Ask-PO-Text / Ask-PO-YN / Ask-PO-Choice / Add-PO-Debt helpers
# =============================================================================

# ── Version guard ─────────────────────────────────────────────────────────────
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Host "ERROR: PowerShell 5.1 or later is required." -ForegroundColor Red
  Write-Host "       Current: $($PSVersionTable.PSVersion)"  -ForegroundColor Red
  exit 1
}
if ($PSVersionTable.PSVersion.Major -lt 7) {
  Write-Host "NOTE: PowerShell 7+ is recommended for best cross-platform behaviour." -ForegroundColor DarkYellow
  Write-Host "      Install via https://aka.ms/powershell" -ForegroundColor DarkYellow
  Write-Host ""
}

# ── Paths ─────────────────────────────────────────────────────────────────────
if ($env:PO_OUTPUT_DIR) {
  $script:POOutputDir = $env:PO_OUTPUT_DIR
} else {
  $script:POOutputDir = Join-Path (Get-Location) "po-output"
}
$script:PODebtFile = Join-Path $script:POOutputDir "06-po-debts.md"
New-Item -ItemType Directory -Path $script:POOutputDir -Force | Out-Null

# ── Helpers ───────────────────────────────────────────────────────────────────

function Ask-PO-Text {
  param([string]$Prompt)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  return (Read-Host).Trim()
}

function Ask-PO-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "▶ $Prompt (y/n): " -ForegroundColor Yellow -NoNewline
    $ans = (Read-Host).ToLower().Trim()
    if ($ans -in "y","yes") { return "yes" }
    if ($ans -in "n","no")  { return "no"  }
    Write-Host "  Please type y or n." -ForegroundColor Red
  }
}

function Ask-PO-Choice {
  param(
    [string]$Prompt,
    [string[]]$Options
  )
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  $($i + 1)) $($Options[$i])"
  }
  while ($true) {
    $choice = Read-Host
    if ($choice -match '^\d+$') {
      $idx = [int]$choice - 1
      if ($idx -ge 0 -and $idx -lt $Options.Count) {
        return $Options[$idx]
      }
    }
    Write-Host "  Please enter a number between 1 and $($Options.Count)." -ForegroundColor Red
  }
}

function Confirm-PO-Save {
  param([string]$Prompt)
  return ((Ask-PO-YN $Prompt) -eq "yes")
}

function Get-PO-DebtCount {
  if (-not (Test-Path $script:PODebtFile)) { return 0 }
  $matches = @(Select-String -Path $script:PODebtFile -Pattern "^## PODEBT-" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

function Add-PO-Debt {
  param(
    [string]$Area,
    [string]$Title,
    [string]$Description,
    [string]$Impact
  )
  $current = Get-PO-DebtCount
  $next    = $current + 1
  $id      = $next.ToString("D2")

  $entry = @"

## PODEBT-${id}: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@
  Add-Content -Path $script:PODebtFile -Value $entry -Encoding UTF8
}

function Write-PO-Banner {
  param([string]$Title)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
  Write-Host ("║  {0,-56}║" -f $Title) -ForegroundColor Magenta
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
  Write-Host ""
}

function Write-PO-SuccessRule {
  param([string]$Text)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host "  $Text" -ForegroundColor Green
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host ""
}

function Write-PO-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor DarkGray
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-PO-Answer /
# Get-PO-YN / Get-PO-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "POAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:POAuto = $false
}
if ($env:PO_AUTO -and $env:PO_AUTO -match '^(1|true|yes)$') { $script:POAuto = $true }

if (-not (Get-Variable -Name "POAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:POAnswers = $env:PO_ANSWERS
}

if (-not (Get-Variable -Name "POUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:POUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-PO-ParseFlags @args
function Invoke-PO-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:POAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:POAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:POAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-PO-Auto { return [bool]$script:POAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-PO-Extract {
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
function Resolve-PO-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:POAnswers -and (Test-Path $script:POAnswers)) {
    $v = Read-PO-Extract -Path $script:POAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:POUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-PO-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-PO-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-PO-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-PO-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-PO-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-PO-Auto) {
    if (-not $Default) {
      Add-PO-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-PO-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-PO-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-PO-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-PO-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-PO-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-PO-YN $Prompt)
}

function Get-PO-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-PO-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-PO-Auto) {
      Add-PO-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-PO-Auto) {
    Add-PO-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-PO-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-PO-Extract {
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
