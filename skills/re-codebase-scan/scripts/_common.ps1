# Reverse Engineering Common Functions for PowerShell 5.1+
# Used by all RE scripts for consistency, colors, and utilities

# Version check: PowerShell 5.1+
if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    Write-Error "This script requires PowerShell 5.1 or later"
    exit 1
}

# ============================================================================
# Environment Setup
# ============================================================================

$script:REOutputDir = $env:RE_OUTPUT_DIR
if ([string]::IsNullOrEmpty($script:REOutputDir)) {
    $script:REOutputDir = ".\re-output"
}
$env:RE_OUTPUT_DIR = $script:REOutputDir

$script:REDebtFile = Join-Path $script:REOutputDir "07-re-debts.md"
$env:RE_DEBT_FILE = $script:REDebtFile

# ============================================================================
# Color Definitions
# ============================================================================

# Colors for output
$script:REColorBanner = [System.ConsoleColor]::Cyan
$script:REColorSuccess = [System.ConsoleColor]::Green
$script:REColorError = [System.ConsoleColor]::Red
$script:REColorWarning = [System.ConsoleColor]::Yellow
$script:REColorInfo = [System.ConsoleColor]::Blue
$script:REColorDim = [System.ConsoleColor]::DarkGray

# ============================================================================
# Utility Functions
# ============================================================================

function ConvertTo-Lower {
    param([string]$InputString)
    return $InputString.ToLower()
}

function ConvertTo-Upper {
    param([string]$InputString)
    return $InputString.ToUpper()
}

function Test-IsYes {
    param([string]$InputString)
    $lower = ConvertTo-Lower $InputString
    return $lower -in @("y", "yes", "true", "1")
}

function Test-IsNo {
    param([string]$InputString)
    $lower = ConvertTo-Lower $InputString
    return $lower -in @("n", "no", "false", "0")
}

# ============================================================================
# Interactive Input Functions
# ============================================================================

function Ask-RE-Text {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    if ($Default) {
        Write-Host "$Prompt [$Default]: " -ForegroundColor $script:REColorInfo -NoNewline
    }
    else {
        Write-Host "${Prompt}: " -ForegroundColor $script:REColorInfo -NoNewline
    }

    $input = Read-Host
    if ([string]::IsNullOrEmpty($input) -and $Default) {
        return $Default
    }
    return $input
}

function Ask-RE-YN {
    param(
        [string]$Prompt,
        [string]$Default = "n"
    )

    while ($true) {
        Write-Host "$Prompt [$Default]: " -ForegroundColor $script:REColorInfo -NoNewline
        $input = Read-Host
        $input = if ($input) { $input } else { $Default }

        if (Test-IsYes $input) {
            return "yes"
        }
        elseif (Test-IsNo $input) {
            return "no"
        }
        else {
            Write-Host "Please answer 'y' or 'n'" -ForegroundColor $script:REColorError
        }
    }
}

function Ask-RE-Choice {
    param(
        [string]$Prompt,
        [string[]]$Options
    )

    Write-Host $Prompt -ForegroundColor $script:REColorInfo
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  $($i+1)) $($Options[$i])"
    }

    while ($true) {
        Write-Host "Select (1-$($Options.Count)): " -ForegroundColor $script:REColorInfo -NoNewline
        $choice = Read-Host

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
            return $Options[[int]$choice - 1]
        }
        else {
            Write-Host "Invalid choice. Please enter a number between 1 and $($Options.Count)." -ForegroundColor $script:REColorError
        }
    }
}

function Confirm-RE-Save {
    param([string]$Filename)

    $response = Ask-RE-YN "Save to $Filename?" "y"
    return ($response -eq "yes")
}

# ============================================================================
# Debt Management Functions
# ============================================================================

function Initialize-RE-DebtFile {
    if (-not (Test-Path $script:REOutputDir)) {
        New-Item -ItemType Directory -Path $script:REOutputDir -Force | Out-Null
    }

    if (-not (Test-Path $script:REDebtFile)) {
        $content = @"
# Reverse Engineering Debts

This file tracks areas of the codebase that were difficult to document or require further investigation.
Each debt is assigned a unique ID (REDEBT-NN) and categorized by type.

## Legend
- **Undocumented Module**: Code with no comments, docstrings, or clear purpose
- **Unclear Logic**: Complex code that lacks explanation
- **Magic Number**: Hardcoded values without context
- **Dead Code**: Unused functions, imports, or modules
- **Missing Tests**: Code without corresponding unit tests
- **Deployment Gap**: Unclear how code is deployed in production
- **Integration Mystery**: External service integrations without clear contracts
- **Performance Unknown**: Code that may have performance impact but is undocumented

---

"@
        Set-Content -Path $script:REDebtFile -Value $content
    }
}

function Get-RE-DebtCount {
    if (Test-Path $script:REDebtFile) {
        $content = Get-Content $script:REDebtFile -Raw
        $matches = [regex]::Matches($content, '^## REDEBT-', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        return $matches.Count
    }
    return 0
}

function Add-RE-Debt {
    param(
        [string]$Title,
        [string]$FilePath,
        [string]$LineRange,
        [string]$DebtType,
        [string]$Evidence,
        [string]$Impact = "Medium",
        [string]$Recommendation
    )

    Initialize-RE-DebtFile

    $debtNum = Get-RE-DebtCount
    $debtId = "REDEBT-$($debtNum.ToString('D2'))"

    $content = @"

## ${debtId}: ${Title}

- **File**: ${FilePath} (line ${LineRange})
- **Type**: ${DebtType}
- **Evidence**: ${Evidence}
- **Impact**: ${Impact}
- **Recommendation**: ${Recommendation}

"@

    Add-Content -Path $script:REDebtFile -Value $content

    Write-Host "Added $debtId" -ForegroundColor $script:REColorSuccess
}

# ============================================================================
# Output Functions
# ============================================================================

function Write-RE-Banner {
    param([string]$Text)

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $script:REColorBanner
    Write-Host ("║ {0,-64} ║" -f $Text) -ForegroundColor $script:REColorBanner
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $script:REColorBanner
    Write-Host ""
}

function Write-RE-SuccessRule {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $script:REColorSuccess
}

function Write-RE-Dim {
    param([string]$Text)
    Write-Host $Text -ForegroundColor $script:REColorDim
}

function Write-RE-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $script:REColorSuccess
}

function Write-RE-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $script:REColorError
}

function Write-RE-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $script:REColorWarning
}

function Write-RE-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $script:REColorInfo
}

function Write-RE-KV {
    param(
        [string]$Key,
        [string]$Value
    )
    Write-Host ("{0,-30}: {1}" -f $Key, $Value)
}

# ============================================================================
# File Operations
# ============================================================================

function New-RE-File {
    param(
        [string]$Filename,
        [string]$Title
    )

    Initialize-RE-DebtFile

    $filepath = Join-Path $script:REOutputDir $Filename
    $content = @"
# ${Title}

Generated by technical-analyst reverse engineering agent.
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---

"@

    Set-Content -Path $filepath -Value $content
    return $filepath
}

function Add-RE-FileContent {
    param(
        [string]$FilePath,
        [string]$Content
    )

    Add-Content -Path $FilePath -Value $Content
}

# ============================================================================
# Codebase Analysis Functions
# ============================================================================

function Get-RE-FileCountByExt {
    param(
        [string]$RootDir,
        [string]$Extension
    )

    $files = Get-ChildItem -Path $RootDir -Filter "*.${Extension}" -Recurse -ErrorAction SilentlyContinue
    return $files.Count
}

function Get-RE-LinesOfCode {
    param([string]$RootDir)

    $patterns = @("*.js", "*.ts", "*.py", "*.java", "*.go", "*.rs", "*.cpp", "*.c")
    $files = Get-ChildItem -Path $RootDir -Include $patterns -Recurse -ErrorAction SilentlyContinue

    $totalLines = 0
    foreach ($file in $files) {
        $totalLines += (Get-Content $file -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    }
    return $totalLines
}

function Find-RE-ConfigFiles {
    param([string]$RootDir)

    $configPatterns = @(
        "package.json",
        "pom.xml",
        "build.gradle",
        "requirements.txt",
        "Cargo.toml",
        "go.mod",
        "*.csproj",
        "Makefile",
        "docker-compose.yml",
        "Dockerfile",
        "*.tf",
        "*.yaml",
        "*.yml"
    )

    $configFiles = @()
    foreach ($pattern in $configPatterns) {
        $files = Get-ChildItem -Path $RootDir -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        $configFiles += $files
    }
    return $configFiles
}

function Get-RE-PrimaryLanguage {
    param([string]$RootDir)

    $languages = @{
        "JavaScript" = "js"
        "TypeScript" = "ts"
        "Python" = "py"
        "Java" = "java"
        "Go" = "go"
        "Rust" = "rs"
        "C++" = "cpp"
    }

    $maxCount = 0
    $primaryLang = "Unknown"

    foreach ($lang in $languages.GetEnumerator()) {
        $count = Get-RE-FileCountByExt -RootDir $RootDir -Extension $lang.Value
        if ($count -gt $maxCount) {
            $maxCount = $count
            $primaryLang = $lang.Key
        }
    }

    return $primaryLang
}

function Show-RE-DirectoryTree {
    param(
        [string]$RootDir,
        [int]$MaxDepth = 2
    )

    $excludePatterns = @('node_modules', '.git', 'vendor', '.venv', '.env')

    function Get-TreeLevel {
        param(
            [string]$Path,
            [int]$Depth,
            [int]$MaxDepth,
            [string]$Prefix
        )

        if ($Depth -gt $MaxDepth) { return }

        try {
            $items = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                $shouldExclude = $false
                foreach ($pattern in $excludePatterns) {
                    if ($item.Name -like $pattern) {
                        $shouldExclude = $true
                        break
                    }
                }

                if (-not $shouldExclude) {
                    Write-Host "$Prefix├─ $($item.Name)"
                    if ($item.PSIsContainer -and $Depth -lt $MaxDepth) {
                        Get-TreeLevel -Path $item.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth -Prefix "$Prefix│  "
                    }
                }
            }
        }
        catch {
            Write-RE-Error "Cannot access $Path"
        }
    }

    Write-Host "$RootDir"
    Get-TreeLevel -Path $RootDir -Depth 0 -MaxDepth $MaxDepth -Prefix ""
}

# ============================================================================
# Validation Functions
# ============================================================================

function Test-RE-Path {
    param([string]$Path)

    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-RE-Error "Path does not exist: $Path"
        return $false
    }

    return $true
}

function Test-RE-File {
    param([string]$FilePath)

    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-RE-Error "File does not exist: $FilePath"
        return $false
    }

    return $true
}

# ============================================================================
# JSON Parsing (Simple)
# ============================================================================

function Get-RE-JsonValue {
    param(
        [string]$JsonFile,
        [string]$Key
    )

    if (Test-Path $JsonFile) {
        $content = Get-Content $JsonFile -Raw
        $json = $content | ConvertFrom-Json
        return $json.$Key
    }
}

function Get-RE-NpmDeps {
    param([string]$PackageJsonPath)

    if (Test-Path $PackageJsonPath) {
        $json = Get-Content $PackageJsonPath | ConvertFrom-Json
        return $json.dependencies
    }
}

# ============================================================================
# Error Handling
# ============================================================================

function Write-RE-LogError {
    param(
        [int]$LineNum,
        [string]$ErrorMsg
    )

    Write-RE-Error "Error at line ${LineNum}: ${ErrorMsg}"
    $logFile = Join-Path $script:REOutputDir "ERRORS.log"
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Error at line ${LineNum}: ${ErrorMsg}"
}

# ============================================================================
# Make functions available in this session
# ============================================================================

# Functions are automatically available in the current scope

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1 (PowerShell mirror)
#
# Same contract as the Bash version. Scripts use Get-RE-Answer /
# Get-RE-YN / Get-RE-Choice with a stable Key; values are
# resolved from env var → answers file → upstream extracts → default, with
# interactive prompting only when not in auto mode.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
if (-not (Get-Variable -Name "REAuto" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:REAuto = $false
}
if ($env:RE_AUTO -and $env:RE_AUTO -match '^(1|true|yes)$') { $script:REAuto = $true }

if (-not (Get-Variable -Name "REAnswers" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:REAnswers = $env:RE_ANSWERS
}

if (-not (Get-Variable -Name "REUpstreamExtracts" -Scope Script -ErrorAction SilentlyContinue)) {
  $script:REUpstreamExtracts = @()
}

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts call:  Invoke-RE-ParseFlags @args
function Invoke-RE-ParseFlags {
  param([string[]]$Args)
  $i = 0
  while ($i -lt $Args.Count) {
    $a = $Args[$i]
    switch -Regex ($a) {
      '^--auto$'        { $script:REAuto = $true; $i++ }
      '^--answers$'     { if ($i + 1 -lt $Args.Count) { $script:REAnswers = $Args[$i+1]; $i += 2 } else { $i++ } }
      '^--answers=(.+)$' { $script:REAnswers = $Matches[1]; $i++ }
      default           { $i++ }
    }
  }
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
function Test-RE-Auto { return [bool]$script:REAuto }

# ── Extract-file reader ──────────────────────────────────────────────────────
function Read-RE-Extract {
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
function Resolve-RE-Answer {
  param([string]$Key, [string]$Default = "")
  # 1) Env var
  $envVal = [System.Environment]::GetEnvironmentVariable($Key)
  if ($envVal) { return $envVal }
  # 2) Answers file
  if ($script:REAnswers -and (Test-Path $script:REAnswers)) {
    $v = Read-RE-Extract -Path $script:REAnswers -Key $Key
    if ($v) { return $v }
  }
  # 3) Upstream extracts
  foreach ($f in $script:REUpstreamExtracts) {
    if (-not $f) { continue }
    $v = Read-RE-Extract -Path $f -Key $Key
    if ($v) { return $v }
  }
  # 4) Default
  return $Default
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# Maps 4-arg (Area, Title, Description, Impact) onto RE's native
# Add-RE-Debt(Title, FilePath, LineRange, DebtType, Evidence, Impact, Recommendation) signature.
function Add-RE-DebtAuto {
  param([string]$Area, [string]$Title, [string]$Description, [string]$Impact)
  Add-RE-Debt -Title "[$Area] $Title" -FilePath "auto-resolve" -LineRange "N/A" `
    -DebtType "Auto-resolve" -Evidence $Description -Impact $Impact `
    -Recommendation "Review and resolve manually"
}

# ── Unified getters ──────────────────────────────────────────────────────────
function Get-RE-Answer {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-RE-Answer -Key $Key -Default $Default
  if ($v) { return $v }
  if (Test-RE-Auto) {
    if (-not $Default) {
      Add-RE-DebtAuto -Area "Auto-resolve" -Title "Missing answer: $Key" `
        -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
        -Impact "Downstream output for this field will be blank"
    }
    return $Default
  }
  if ($Default) { Write-Host "  (default: $Default — press Enter to accept)" -ForegroundColor DarkGray }
  $ans = Ask-RE-Text $Prompt
  if (-not $ans) { $ans = $Default }
  return $ans
}

function Get-RE-YN {
  param([string]$Key, [string]$Prompt, [string]$Default = "")
  $v = Resolve-RE-Answer -Key $Key -Default $Default
  $norm = if ($v) { $v.ToLower() } else { "" }
  if ($norm -in "y","yes","true","1") { return "yes" }
  if ($norm -in "n","no","false","0") { return "no"  }
  if (Test-RE-Auto) {
    $dn = if ($Default) { $Default.ToLower() } else { "" }
    if ($dn -in "y","yes","true","1") { return "yes" }
    if ($dn -in "n","no","false","0") { return "no"  }
    Add-RE-DebtAuto -Area "Auto-resolve" -Title "Missing y/n: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode, and no default is documented" `
      -Impact "Defaulting to 'no'"
    return "no"
  }
  return (Ask-RE-YN $Prompt)
}

function Get-RE-Choice {
  param([string]$Key, [string]$Prompt, [string[]]$Options)
  $v = Resolve-RE-Answer -Key $Key -Default ""
  if ($v) {
    foreach ($o in $Options) { if ($o -eq $v) { return $o } }
    foreach ($o in $Options) { if ($o.StartsWith($v)) { return $o } }
    if (Test-RE-Auto) {
      Add-RE-DebtAuto -Area "Auto-resolve" -Title "Unmatched choice for $Key" `
        -Description "Resolved value '$v' does not match any known option" `
        -Impact "Defaulting to first option: $($Options[0])"
      return $Options[0]
    }
  }
  if (Test-RE-Auto) {
    Add-RE-DebtAuto -Area "Auto-resolve" -Title "Missing choice: $Key" `
      -Description "Could not resolve '$Key' from env/answers/upstream in auto mode" `
      -Impact "Defaulting to first option: $($Options[0])"
    return $Options[0]
  }
  return (Ask-RE-Choice -Prompt $Prompt -Options $Options)
}

# ── Extract-file writer ──────────────────────────────────────────────────────
function Write-RE-Extract {
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
