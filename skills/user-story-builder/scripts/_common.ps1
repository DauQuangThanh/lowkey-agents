# =============================================================================
# _common.ps1 — Shared helpers embedded inside this skill.
#
# DOT-SOURCING (from a sibling script in the same scripts\ folder):
#   $ScriptDir = $PSScriptRoot
#   . (Join-Path $ScriptDir "_common.ps1")
#
# Features:
#   - PowerShell 7+ recommended; compatible with PowerShell 5.1 on Windows
#   - Respects $env:BA_OUTPUT_DIR, falls back to .\ba-output
#   - Consistent DEBT numbering across all skills (reads existing count)
#   - Shared Ask-BA-Text / Ask-BA-YN / Ask-BA-Choice / Add-BA-Debt helpers
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
if ($env:BA_OUTPUT_DIR) {
  $script:BAOutputDir = $env:BA_OUTPUT_DIR
} else {
  $script:BAOutputDir = Join-Path (Get-Location) "ba-output"
}
$script:BADebtFile = Join-Path $script:BAOutputDir "06-requirement-debts.md"
New-Item -ItemType Directory -Path $script:BAOutputDir -Force | Out-Null

# ── Helpers ───────────────────────────────────────────────────────────────────

function Ask-BA-Text {
  param([string]$Prompt)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  return (Read-Host).Trim()
}

function Ask-BA-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "▶ $Prompt (y/n): " -ForegroundColor Yellow -NoNewline
    $ans = (Read-Host).ToLower().Trim()
    if ($ans -in "y","yes") { return "yes" }
    if ($ans -in "n","no")  { return "no"  }
    Write-Host "  Please type y or n." -ForegroundColor Red
  }
}

function Ask-BA-Choice {
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

function Confirm-BA-Save {
  param([string]$Prompt)
  return ((Ask-BA-YN $Prompt) -eq "yes")
}

function Get-BA-DebtCount {
  if (-not (Test-Path $script:BADebtFile)) { return 0 }
  $matches = @(Select-String -Path $script:BADebtFile -Pattern "^## DEBT-" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

function Add-BA-Debt {
  param(
    [string]$Area,
    [string]$Title,
    [string]$Description,
    [string]$Impact
  )
  $current = Get-BA-DebtCount
  $next    = $current + 1
  $id      = $next.ToString("D2")

  $entry = @"

## DEBT-${id}: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@
  Add-Content -Path $script:BADebtFile -Value $entry -Encoding UTF8
}

function Write-BA-Banner {
  param([string]$Title)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
  Write-Host ("║  {0,-56}║" -f $Title) -ForegroundColor Blue
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
  Write-Host ""
}

function Write-BA-SuccessRule {
  param([string]$Text)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host "  $Text" -ForegroundColor Green
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host ""
}

function Write-BA-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor DarkGray
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-BA-Answer /
# Get-BA-YN / Get-BA-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "BAAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BAAuto = $false
}
if ($env:BA_AUTO -and $env:BA_AUTO -match '^(1|true|yes)$') { $script:BAAuto = $true }

if (-not (Get-Variable -Name "BAAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BAAnswers = $env:BA_ANSWERS
}

if (-not (Get-Variable -Name "BAUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BAUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-BA-ParseFlags @args
function Invoke-BA-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:BAAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:BAAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:BAAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-BA-Auto { return [bool]$script:BAAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-BA-Extract {
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
function Resolve-BA-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:BAAnswers -and (Test-Path $script:BAAnswers)) {
    $v = Read-BA-Extract -Path $script:BAAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:BAUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-BA-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-BA-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-BA-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-BA-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-BA-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-BA-Auto) {
    if (-not $Default) {
      Add-BA-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-BA-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-BA-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-BA-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-BA-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-BA-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-BA-YN $Prompt)
}

function Get-BA-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-BA-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-BA-Auto) {
      Add-BA-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-BA-Auto) {
    Add-BA-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-BA-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-BA-Extract {
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
