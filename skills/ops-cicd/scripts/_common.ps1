# PowerShell 5.1+ utility functions for OPS skills
# Dot-source this file in skill scripts: . .\_common.ps1

# Version guard
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "This script requires PowerShell 5.1 or later." -ErrorAction Stop
    exit 1
}

# Colors (ANSI escape codes)
$script:OPS_RED = "`e[1;31m"
$script:OPS_GREEN = "`e[1;32m"
$script:OPS_YELLOW = "`e[1;33m"
$script:OPS_BLUE = "`e[1;34m"
$script:OPS_CYAN = "`e[1;36m"
$script:OPS_MAGENTA = "`e[1;35m"
$script:OPS_BOLD = "`e[1;37m"
$script:OPS_DIM = "`e[2m"
$script:OPS_NC = "`e[0m"

# Paths
$script:OPSOutputDir = $env:OPS_OUTPUT_DIR -or "./ops-output"
$script:OPSDebtFile = $env:OPS_DEBT_FILE -or (Join-Path $script:OPSOutputDir "07-ops-debts.md")

# Create output directory if it doesn't exist
if (-not (Test-Path $script:OPSOutputDir)) {
    New-Item -ItemType Directory -Path $script:OPSOutputDir -Force | Out-Null
}

# Utility: Ask a question and get response
function Ask-OPS-Text {
    param([string]$Prompt)
    Write-Host -NoNewline -ForegroundColor Blue "$Prompt "
    return Read-Host
}

# Utility: Ask yes/no question
function Ask-OPS-YN {
    param([string]$Prompt)
    while ($true) {
        Write-Host -NoNewline -ForegroundColor Blue "$Prompt [y/n]: "
        $response = Read-Host
        switch ($response.ToLower()) {
            { $_ -in 'y', 'yes' } { return $true }
            { $_ -in 'n', 'no' } { return $false }
            default { Write-Host "Please answer y or n." }
        }
    }
}

# Utility: Ask multiple choice question
function Ask-OPS-Choice {
    param(
        [string]$Prompt,
        [string[]]$Options
    )
    Write-Host -ForegroundColor Blue $Prompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  $($i + 1). $($Options[$i])"
    }

    while ($true) {
        Write-Host -NoNewline -ForegroundColor Blue "Enter choice (1-$($Options.Count)): "
        $choice = Read-Host
        if ([int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
            return $Options[[int]$choice - 1]
        } else {
            Write-Host "Invalid choice. Please try again."
        }
    }
}

# Utility: Confirm before saving
function Confirm-OPS-Save {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        Write-Host -ForegroundColor Yellow "File already exists: $FilePath"
        if (-not (Ask-OPS-YN "Overwrite?")) {
            Write-Host "Skipped."
            return $false
        }
    }
    return $true
}

# Utility: Count existing debt items
function Get-OPS-DebtCount {
    if (-not (Test-Path $script:OPSDebtFile)) {
        return 0
    }
    $content = Get-Content $script:OPSDebtFile -Raw
    return ($content | Select-String "^## OPSDEBT-" -AllMatches).Matches.Count
}

# Utility: Add debt item
function Add-OPS-Debt {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Severity = "medium",  # low, medium, high, critical
        [string]$Owner = "unassigned"
    )

    if (-not (Test-Path $script:OPSDebtFile)) {
        New-Item -ItemType Directory -Path (Split-Path $script:OPSDebtFile) -Force | Out-Null
        @"
# OPS Debt Tracker

Debt items that reduce operational efficiency or increase risk.

"@ | Set-Content $script:OPSDebtFile
    }

    $count = (Get-OPS-DebtCount) + 1
    $debtId = "OPSDEBT-{0:00}" -f $count
    $date = Get-Date -Format "yyyy-MM-dd"

    $debtEntry = @"

## $debtId`: $Title

**Severity**: $Severity
**Owner**: $Owner
**Created**: $date

$Description

"@

    Add-Content $script:OPSDebtFile $debtEntry
    Write-Host -ForegroundColor Yellow "Added: $debtId"
}

# Utility: Print banner
function Write-OPS-Banner {
    param([string]$Text)
    Write-Host ""
    Write-Host -ForegroundColor White "════════════════════════════════════════════════════════════"
    Write-Host -ForegroundColor White $Text
    Write-Host -ForegroundColor White "════════════════════════════════════════════════════════════"
    Write-Host ""
}

# Utility: Print success rule
function Write-OPS-SuccessRule {
    param([string]$Text)
    Write-Host ""
    Write-Host -ForegroundColor Green "✓ $Text"
    Write-Host ""
}

# Utility: Print dim text
function Write-OPS-Dim {
    param([string]$Text)
    Write-Host -ForegroundColor DarkGray $Text
}

# Utility: Print colored section
function Write-OPS-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host -ForegroundColor Cyan "### $Title"
    Write-Host ""
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-OPS-Answer /
# Get-OPS-YN / Get-OPS-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "OPSAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:OPSAuto = $false
}
if ($env:OPS_AUTO -and $env:OPS_AUTO -match '^(1|true|yes)$') { $script:OPSAuto = $true }

if (-not (Get-Variable -Name "OPSAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:OPSAnswers = $env:OPS_ANSWERS
}

if (-not (Get-Variable -Name "OPSUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:OPSUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-OPS-ParseFlags @args
function Invoke-OPS-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:OPSAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:OPSAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:OPSAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-OPS-Auto { return [bool]$script:OPSAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-OPS-Extract {
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
function Resolve-OPS-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:OPSAnswers -and (Test-Path $script:OPSAnswers)) {
    $v = Read-OPS-Extract -Path $script:OPSAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:OPSUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-OPS-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
function Add-OPS-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-OPS-Debt -Area $Area -Title $Title -Description $Description -Impact $Impact
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-OPS-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-OPS-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-OPS-Auto) {
    if (-not $Default) {
      Add-OPS-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-OPS-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-OPS-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-OPS-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-OPS-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-OPS-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-OPS-YN $Prompt)
}

function Get-OPS-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-OPS-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-OPS-Auto) {
      Add-OPS-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-OPS-Auto) {
    Add-OPS-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-OPS-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-OPS-Extract {
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
