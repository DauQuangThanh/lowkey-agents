# =============================================================================
# _common.ps1 — Shared helpers embedded inside this skill.
#
# DOT-SOURCING (from a sibling script in the same scripts\ folder):
#   $ScriptDir = $PSScriptRoot
#   . (Join-Path $ScriptDir "_common.ps1")
#
# Features:
#   - PowerShell 7+ recommended; compatible with PowerShell 5.1 on Windows
#   - Respects $env:ARCH_OUTPUT_DIR, falls back to .\arch-output
#   - Continuous TDEBT / RISK / ADR numbering across all architect skills
#   - Shared Ask-Arch-* / Add-Arch-TDebt helpers
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
if ($env:ARCH_OUTPUT_DIR) {
  $script:ArchOutputDir = $env:ARCH_OUTPUT_DIR
} else {
  $script:ArchOutputDir = Join-Path (Get-Location) "arch-output"
}
if ($env:ARCH_BA_INPUT_DIR) {
  $script:ArchBAInputDir = $env:ARCH_BA_INPUT_DIR
} else {
  $script:ArchBAInputDir = Join-Path (Get-Location) "ba-output"
}
$script:ArchTDebtFile   = Join-Path $script:ArchOutputDir "05-technical-debts.md"
$script:ArchADRDir      = Join-Path $script:ArchOutputDir "adr"
$script:ArchDiagramsDir = Join-Path $script:ArchOutputDir "diagrams"
New-Item -ItemType Directory -Path $script:ArchOutputDir -Force | Out-Null

# ── Helpers ───────────────────────────────────────────────────────────────────

function Get-Arch-Slug {
  param([string]$Text)
  $s = $Text.ToLower()
  $s = [Regex]::Replace($s, '[^a-z0-9]', '-')
  $s = [Regex]::Replace($s, '-+', '-')
  return $s.Trim('-')
}

function Ask-Arch-Text {
  param([string]$Prompt)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  return (Read-Host).Trim()
}

function Ask-Arch-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "▶ $Prompt (y/n): " -ForegroundColor Yellow -NoNewline
    $ans = (Read-Host).ToLower().Trim()
    if ($ans -in "y","yes") { return "yes" }
    if ($ans -in "n","no")  { return "no"  }
    Write-Host "  Please type y or n." -ForegroundColor Red
  }
}

function Ask-Arch-Choice {
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

function Confirm-Arch-Save {
  param([string]$Prompt)
  return ((Ask-Arch-YN $Prompt) -eq "yes")
}

function Get-Arch-TDebtCount {
  if (-not (Test-Path $script:ArchTDebtFile)) { return 0 }
  $matches = @(Select-String -Path $script:ArchTDebtFile -Pattern "^## TDEBT-" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

function Get-Arch-RiskCount {
  if (-not (Test-Path $script:ArchTDebtFile)) { return 0 }
  $matches = @(Select-String -Path $script:ArchTDebtFile -Pattern "^## RISK-" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

function Get-Arch-ADRCount {
  if (-not (Test-Path $script:ArchADRDir)) { return 0 }
  $files = @(Get-ChildItem -Path $script:ArchADRDir -Filter "ADR-????-*.md" -ErrorAction SilentlyContinue)
  return $files.Count
}

function Get-Arch-NextADRId {
  $n = (Get-Arch-ADRCount) + 1
  return "ADR-{0:D4}" -f $n
}

function Add-Arch-TDebt {
  param(
    [string]$Area,
    [string]$Title,
    [string]$Description,
    [string]$Impact
  )
  $current = Get-Arch-TDebtCount
  $next    = $current + 1
  $id      = $next.ToString("D2")

  $entry = @"

## TDEBT-${id}: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Linked:** TBD
**Status:** Open

"@
  Add-Content -Path $script:ArchTDebtFile -Value $entry -Encoding UTF8
}

function Write-Arch-Banner {
  param([string]$Title)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
  Write-Host ("║  {0,-56}║" -f $Title) -ForegroundColor Magenta
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
  Write-Host ""
}

function Write-Arch-SuccessRule {
  param([string]$Text)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host "  $Text" -ForegroundColor Green
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host ""
}

function Write-Arch-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor DarkGray
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-ARCH-Answer /
# Get-ARCH-YN / Get-ARCH-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "ARCHAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:ARCHAuto = $false
}
if ($env:ARCH_AUTO -and $env:ARCH_AUTO -match '^(1|true|yes)$') { $script:ARCHAuto = $true }

if (-not (Get-Variable -Name "ARCHAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:ARCHAnswers = $env:ARCH_ANSWERS
}

if (-not (Get-Variable -Name "ARCHUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:ARCHUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-ARCH-ParseFlags @args
function Invoke-ARCH-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:ARCHAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:ARCHAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:ARCHAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-ARCH-Auto { return [bool]$script:ARCHAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-ARCH-Extract {
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
function Resolve-ARCH-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:ARCHAnswers -and (Test-Path $script:ARCHAnswers)) {
    $v = Read-ARCH-Extract -Path $script:ARCHAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:ARCHUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-ARCH-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-ARCH-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-ARCH-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-ARCH-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-ARCH-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-ARCH-Auto) {
    if (-not $Default) {
      Add-ARCH-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-ARCH-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-ARCH-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-ARCH-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-ARCH-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-ARCH-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-ARCH-YN $Prompt)
}

function Get-ARCH-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-ARCH-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-ARCH-Auto) {
      Add-ARCH-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-ARCH-Auto) {
    Add-ARCH-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-ARCH-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-ARCH-Extract {
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
