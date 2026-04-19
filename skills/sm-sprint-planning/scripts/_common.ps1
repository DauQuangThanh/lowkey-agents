# =============================================================================
# _common.ps1 — Shared helpers for Scrum Master skills.
#
# Features:
#   - PowerShell 5.1+ compatible (Windows built-in)
#   - Respects $env:SM_OUTPUT_DIR, falls back to ./sm-output
#   - Consistent SMDEBT numbering across all skills
#   - Shared helper functions for interactive prompts
# =============================================================================

#requires -version 5.1

# ── Paths ─────────────────────────────────────────────────────────────────────
$script:SMOutputDir = $env:SM_OUTPUT_DIR ? $env:SM_OUTPUT_DIR : (Join-Path (Get-Location) "sm-output")
$script:SMDebtFile = Join-Path $script:SMOutputDir "06-sm-debts.md"
if (-not (Test-Path $script:SMOutputDir)) {
  New-Item -ItemType Directory -Path $script:SMOutputDir -Force | Out-Null
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Ask-SM-Text: Interactive text prompt
function Ask-SM-Text {
  param([string]$Prompt)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  $answer = Read-Host
  return $answer.Trim()
}

# Ask-SM-YN: Y/N prompt, returns "yes" or "no"
function Ask-SM-YN {
  param([string]$Prompt)
  while ($true) {
    Write-Host "▶ $Prompt (y/n): " -ForegroundColor Yellow -NoNewline
    $answer = Read-Host
    $norm = $answer.ToLower()
    if ($norm -eq 'y' -or $norm -eq 'yes') {
      return "yes"
    } elseif ($norm -eq 'n' -or $norm -eq 'no') {
      return "no"
    } else {
      Write-Host "  Please type y or n." -ForegroundColor Red
    }
  }
}

# Ask-SM-Choice: Numbered choice prompt
function Ask-SM-Choice {
  param([string]$Prompt, [string[]]$Options)
  Write-Host "▶ $Prompt" -ForegroundColor Yellow
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host ("  {0}) {1}" -f ($i + 1), $Options[$i])
  }
  while ($true) {
    $choice = Read-Host
    if ($choice -match '^\d+$') {
      $num = [int]$choice
      if ($num -ge 1 -and $num -le $Options.Count) {
        return $Options[$num - 1]
      }
    }
    Write-Host ("  Please enter a number between 1 and {0}." -f $Options.Count) -ForegroundColor Red
  }
}

# Confirm-SM-Save: Confirmation prompt
function Confirm-SM-Save {
  param([string]$Prompt)
  $answer = Ask-SM-YN $Prompt
  return $answer -eq "yes"
}

# Get-SM-DebtCount: Count existing SMDEBT entries
function Get-SM-DebtCount {
  if (Test-Path $script:SMDebtFile) {
    $content = Get-Content $script:SMDebtFile -Raw
    $matches = [regex]::Matches($content, '## SMDEBT-')
    return $matches.Count
  }
  return 0
}

# Add-SM-Debt: Add a new debt entry
function Add-SM-Debt {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)

  $current = Get-SM-DebtCount
  $next = $current + 1
  $id = "{0:D2}" -f $next

  $debtEntry = @"

## SMDEBT-$id`: $Title
**Area:** $Area
**Description:** $Description
**Impact:** $Impact
**Owner:** TBD
**Priority:** 🟡 Important
**Target Date:** TBD
**Status:** Open

"@

  Add-Content $script:SMDebtFile $debtEntry
}

# Write-SM-Banner: Styled banner output
function Write-SM-Banner {
  param([string]$Text)
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow -BackgroundColor DarkYellow
  Write-Host ("║  {0,-56}║" -f $Text) -ForegroundColor Yellow -BackgroundColor DarkYellow
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow -BackgroundColor DarkYellow
  Write-Host ""
}

# Write-SM-SuccessRule: Green success rule
function Write-SM-SuccessRule {
  param([string]$Text)
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host "  $Text" -ForegroundColor Green
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host ""
}

# Write-SM-Dim: Dimmed text output
function Write-SM-Dim {
  param([string]$Text)
  Write-Host $Text -ForegroundColor DarkGray
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-SM-Answer /
# Get-SM-YN / Get-SM-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "SMAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:SMAuto = $false
}
if ($env:SM_AUTO -and $env:SM_AUTO -match '^(1|true|yes)$') { $script:SMAuto = $true }

if (-not (Get-Variable -Name "SMAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:SMAnswers = $env:SM_ANSWERS
}

if (-not (Get-Variable -Name "SMUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:SMUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-SM-ParseFlags @args
function Invoke-SM-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:SMAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:SMAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:SMAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-SM-Auto { return [bool]$script:SMAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-SM-Extract {
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
function Resolve-SM-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:SMAnswers -and (Test-Path $script:SMAnswers)) {
    $v = Read-SM-Extract -Path $script:SMAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:SMUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-SM-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-SM-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-SM-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-SM-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-SM-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-SM-Auto) {
    if (-not $Default) {
      Add-SM-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-SM-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-SM-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-SM-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-SM-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-SM-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-SM-YN $Prompt)
}

function Get-SM-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-SM-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-SM-Auto) {
      Add-SM-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-SM-Auto) {
    Add-SM-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-SM-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-SM-Extract {
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
