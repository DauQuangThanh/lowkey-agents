#!/usr/bin/env pwsh
#
# lowkey-agents installer (PowerShell 5.1+, Windows/Cross-platform)
# Installs 14 agents and 85 skills to 25+ AI coding platforms
#
# Usage:
#   .\install.ps1                          # Interactive mode
#   .\install.ps1 -Target "C:\path\to\proj"  # Non-interactive
#   .\install.ps1 -Help                    # Show help
#   .\install.ps1 -Force -Target "C:\path"  # Skip confirmations
#

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Target = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script configuration
$Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommandPath
$Script:AgentsSrc = Join-Path $ScriptDir "agents"
$Script:SkillsSrc = Join-Path $ScriptDir "skills"
$Script:AgentCount = 0
$Script:SkillCount = 0
$Script:AllOverwrite = $false

# Platform data array: platform info as PSCustomObjects
# Priority order for detection: most common first
$Script:Platforms = @(
    [PSCustomObject]@{ConfigDir='.claude'; DisplayName='Claude Code'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.cursor'; DisplayName='Cursor'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.windsurf'; DisplayName='Windsurf'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.github'; DisplayName='GitHub Copilot (IDE)'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.copilot'; DisplayName='GitHub Copilot CLI'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.cline'; DisplayName='Cline'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.roo'; DisplayName='Roo Code'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.opencode'; DisplayName='opencode'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.codex'; DisplayName='Codex CLI'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.gemini'; DisplayName='Gemini CLI'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.amp'; DisplayName='Amp'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.augment'; DisplayName='Augment Code'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.agent'; DisplayName='Antigravity'; AgentsSubdir='workflows'}
    [PSCustomObject]@{ConfigDir='.bob'; DisplayName='IBM Bob'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.codebuddy'; DisplayName='CodeBuddy'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.forge'; DisplayName='Forge'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.junie'; DisplayName='Junie'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.kilocode'; DisplayName='Kilo Code'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.kiro'; DisplayName='Kiro'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.omp'; DisplayName='Pi Agent'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.qoder'; DisplayName='Qoder'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.qwen'; DisplayName='Qwen Code'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.tabnine'; DisplayName='Tabnine'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.trae'; DisplayName='Trae'; AgentsSubdir='agents'}
    [PSCustomObject]@{ConfigDir='.vibe'; DisplayName='Mistral Vibe'; AgentsSubdir='agents'}
)

# Color mapping
$Colors = @{
    'Red'     = 'Red'
    'Green'   = 'Green'
    'Yellow'  = 'Yellow'
    'Blue'    = 'Cyan'
    'Cyan'    = 'Cyan'
    'White'   = 'White'
    'DarkGray' = 'DarkGray'
}

function Write-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor $Colors['Cyan']
    Write-Host "║           LOWKEY-AGENTS INSTALLER                      ║" -ForegroundColor $Colors['Cyan']
    Write-Host "║   14 Agents + 85 Skills for 25+ AI Coding Platforms    ║" -ForegroundColor $Colors['Cyan']
    Write-Host "║   Developed by Dau Quang Thanh                         ║" -ForegroundColor $Colors['Cyan']
    Write-Host "║   Version 2.0 — Production Ready                       ║" -ForegroundColor $Colors['Cyan']
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $Colors['Cyan']
    Write-Host ""
}

function Write-Help {
    $helpText = @"
Usage: .\install.ps1 [OPTIONS]

OPTIONS:
  -Target <path>      Target project path (non-interactive)
  -Force              Skip all confirmation prompts
  -Help               Show this help message

EXAMPLES:
  Interactive mode:
    .\install.ps1

  Non-interactive with target path:
    .\install.ps1 -Target C:\my-project

  Force installation without prompts:
    .\install.ps1 -Force -Target C:\my-project

SUPPORTED PLATFORMS (25 total):
  - Amp (.amp\)
  - Antigravity (.agent\)
  - Augment Code (.augment\)
  - Claude Code (.claude\) - most common
  - Cline (.cline\)
  - CodeBuddy (.codebuddy\)
  - Codex CLI (.codex\)
  - Cursor (.cursor\)
  - Forge (.forge\)
  - Gemini CLI (.gemini\)
  - GitHub Copilot (IDE) (.github\)
  - GitHub Copilot CLI (.copilot\)
  - IBM Bob (.bob\)
  - Junie (.junie\)
  - Kilo Code (.kilocode\)
  - Kiro (.kiro\)
  - Mistral Vibe (.vibe\)
  - opencode (.opencode\)
  - Pi Agent (.omp\)
  - Qoder (.qoder\)
  - Qwen Code (.qwen\)
  - Roo Code (.roo\)
  - Tabnine (.tabnine\)
  - Trae (.trae\)
  - Windsurf (.windsurf\)

If none detected, installer defaults to .claude\ and asks for confirmation
"@
    Write-Host $helpText
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Colors['Green']
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $Colors['Red']
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Colors['Yellow']
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $Colors['Blue']
}

function Validate-SourceDirs {
    if (-not (Test-Path $Script:AgentsSrc)) {
        Write-Error-Custom "Agents directory not found: $($Script:AgentsSrc)"
        exit 1
    }

    if (-not (Test-Path $Script:SkillsSrc)) {
        Write-Error-Custom "Skills directory not found: $($Script:SkillsSrc)"
        exit 1
    }

    $agentFiles = @(Get-ChildItem -Path $Script:AgentsSrc -Filter "*.md" -File)
    $skillDirs = @(Get-ChildItem -Path $Script:SkillsSrc -Directory)

    $Script:AgentCount = $agentFiles.Count
    $Script:SkillCount = $skillDirs.Count

    Write-Success "Found $($Script:AgentCount) agents and $($Script:SkillCount) skills in source"
}

function Get-TargetPath {
    if ([string]::IsNullOrWhiteSpace($Target)) {
        Write-Host ""
        Write-Host "Target Project Path" -ForegroundColor White -BackgroundColor $null
        Write-Host "Enter the path to your target project (or press Enter for current directory):"
        $userTarget = Read-Host "> "
        $Target = if ([string]::IsNullOrWhiteSpace($userTarget)) { "." } else { $userTarget }
    }

    # Resolve to absolute path
    $Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target)

    if (-not (Test-Path $Target)) {
        Write-Error-Custom "Path does not exist: $Target"
        exit 1
    }

    Write-Success "Target path: $Target"
    return $Target
}

function Confirm-DefaultClaudeInstall {
    if ($Force) {
        return $true
    }

    Write-Host ""
    Write-Warning-Custom "No supported IDE/agent folder detected."
    Write-Host "Installer will use .claude\ as default target." -ForegroundColor White
    $response = Read-Host "Continue with .claude\? (y/n)"
    return $response -match "^[yY]"
}

function Find-IDEDirs {
    param([string]$TargetPath)

    $ideDirs = @()

    # Check all platforms defined by $Script:Platforms
    foreach ($platform in $Script:Platforms) {
        $idePath = Join-Path $TargetPath $platform.ConfigDir
        if (Test-Path $idePath) {
            $ideDirs += $platform.ConfigDir
        }
    }

    return $ideDirs
}

function Choose-IDEDir {
    if ($Force) {
        return ".claude"
    }

    Write-Host ""
    Write-Host "No IDE framework directory detected" -ForegroundColor White
    Write-Host "Which framework would you like to use?"
    Write-Host ""
    Write-Host "  Popular Platforms:" -ForegroundColor White
    Write-Host "  1) .claude\     (Claude Code - recommended)" -ForegroundColor Cyan
    Write-Host "  2) .cursor\     (Cursor)" -ForegroundColor Cyan
    Write-Host "  3) .windsurf\   (Windsurf)" -ForegroundColor Cyan
    Write-Host "  4) .github\     (GitHub Copilot IDE)" -ForegroundColor Cyan
    Write-Host "  5) .copilot\    (GitHub Copilot CLI)" -ForegroundColor Cyan
    Write-Host "  6) .cline\      (Cline)" -ForegroundColor Cyan
    Write-Host "  7) .roo\        (Roo Code)" -ForegroundColor Cyan
    Write-Host "  8) .opencode\   (opencode)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  More Platforms:" -ForegroundColor White
    Write-Host "  9) .codex\      (Codex CLI)" -ForegroundColor Cyan
    Write-Host "  10) .gemini\     (Gemini CLI)" -ForegroundColor Cyan
    Write-Host "  11) .amp\        (Amp)" -ForegroundColor Cyan
    Write-Host "  12) .augment\    (Augment Code)" -ForegroundColor Cyan
    Write-Host "  13) .agent\      (Antigravity)" -ForegroundColor Cyan
    Write-Host "  14) .bob\        (IBM Bob)" -ForegroundColor Cyan
    Write-Host "  15) .codebuddy\  (CodeBuddy)" -ForegroundColor Cyan
    Write-Host "  16) .forge\      (Forge)" -ForegroundColor Cyan
    Write-Host "  17) .junie\      (Junie)" -ForegroundColor Cyan
    Write-Host "  18) .kilocode\   (Kilo Code)" -ForegroundColor Cyan
    Write-Host "  19) .kiro\       (Kiro)" -ForegroundColor Cyan
    Write-Host "  20) .omp\        (Pi Agent)" -ForegroundColor Cyan
    Write-Host "  21) .qoder\      (Qoder)" -ForegroundColor Cyan
    Write-Host "  22) .qwen\       (Qwen Code)" -ForegroundColor Cyan
    Write-Host "  23) .tabnine\    (Tabnine)" -ForegroundColor Cyan
    Write-Host "  24) .trae\       (Trae)" -ForegroundColor Cyan
    Write-Host "  25) .vibe\       (Mistral Vibe)" -ForegroundColor Cyan
    Write-Host ""


    $choice = Read-Host "Choose (1-25, default=1)"
    $choice = if ([string]::IsNullOrWhiteSpace($choice)) { "1" } else { $choice }

    $idx = [int]$choice - 1
    if ($idx -ge 0 -and $idx -lt $Script:Platforms.Count) {
        return $Script:Platforms[$idx].ConfigDir
    }

    return ".claude"
}

function Get-AgentsSubdir {
    param([string]$ConfigDir)

    foreach ($platform in $Script:Platforms) {
        if ($platform.ConfigDir -eq $ConfigDir) {
            return $platform.AgentsSubdir
        }
    }

    return "agents"
}

function Get-DisplayName {
    param([string]$ConfigDir)

    foreach ($platform in $Script:Platforms) {
        if ($platform.ConfigDir -eq $ConfigDir) {
            return $platform.DisplayName
        }
    }

    return $ConfigDir
}

function Show-Summary {
    param(
        [string]$TargetPath,
        [array]$IDEDirs
    )

    Write-Host ""
    Write-Host "Installation Summary" -ForegroundColor White
    Write-Host "─────────────────────────────────────" -ForegroundColor DarkGray
    Write-Info "Target project: $TargetPath"

    Write-Host ""
    Write-Host "Target IDE frameworks ($($IDEDirs.Count)):" -ForegroundColor White
    foreach ($ide in $IDEDirs) {
        $displayName = Get-DisplayName $ide
        $agentsSubdir = Get-AgentsSubdir $ide
        Write-Host "  • $displayName ($ide\) → $ide\$agentsSubdir\ + $ide\skills\" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "What will be installed to each:" -ForegroundColor White
    Write-Host "  Agents: $($Script:AgentCount) files" -ForegroundColor Cyan

    Get-ChildItem -Path $Script:AgentsSrc -Filter "*.md" -File |
        ForEach-Object { $_.BaseName } |
        Sort-Object |
        ForEach-Object { Write-Host "    • $_" }

    Write-Host ""
    Write-Host "  Skills: $($Script:SkillCount) directories" -ForegroundColor Cyan
    Write-Host "    (All skill directories with SKILL.md and scripts/)"
    Write-Host ""
}

function Confirm-Installation {
    if ($Force) {
        return $true
    }

    $response = Read-Host "Proceed with installation? (y/n)"
    return $response -match "^[yY]"
}

function Ask-Overwrite {
    param(
        [string]$FileName,
        [ref]$AllMode
    )

    if ($Force -or $AllMode.Value) {
        return "all"
    }

    $response = Read-Host "$FileName already exists. Overwrite? (y/n/all)"
    return $response.ToLower()
}

function Copy-Agents {
    param(
        [string]$TargetPath,
        [string]$IDEDir
    )

    $agentsSubdir = Get-AgentsSubdir $IDEDir
    $targetAgents = Join-Path $TargetPath $IDEDir $agentsSubdir

    if (-not (Test-Path $targetAgents)) {
        New-Item -Path $targetAgents -ItemType Directory -Force | Out-Null
    }

    $agentsInstalled = 0
    $agentsSkipped = 0
    $allOverwrite = $false

    Get-ChildItem -Path $Script:AgentsSrc -Filter "*.md" -File | ForEach-Object {
        $agentFile = $_
        $targetFile = Join-Path $targetAgents $agentFile.Name

        if (Test-Path $targetFile) {
            $response = Ask-Overwrite $agentFile.Name ([ref]$allOverwrite)

            if ($response -eq "all" -or $response -eq "y" -or $response -eq "yes") {
                if ($response -eq "all") {
                    $allOverwrite = $true
                }
                Copy-Item $agentFile.FullName $targetFile -Force
                Write-Success "Installed agent: $($agentFile.BaseName)"
                $agentsInstalled++
            }
            else {
                Write-Warning-Custom "Skipped agent: $($agentFile.BaseName)"
                $agentsSkipped++
            }
        }
        else {
            Copy-Item $agentFile.FullName $targetFile
            Write-Success "Installed agent: $($agentFile.BaseName)"
            $agentsInstalled++
        }
    }

    return @{ Installed = $agentsInstalled; Skipped = $agentsSkipped }
}

function Copy-Skills {
    param(
        [string]$TargetPath,
        [string]$IDEDir
    )

    $targetSkills = Join-Path $TargetPath $IDEDir "skills"

    if (-not (Test-Path $targetSkills)) {
        New-Item -Path $targetSkills -ItemType Directory -Force | Out-Null
    }

    $skillsInstalled = 0
    $skillsSkipped = 0
    $allOverwrite = $false

    Get-ChildItem -Path $Script:SkillsSrc -Directory | ForEach-Object {
        $skillDir = $_
        $targetSkill = Join-Path $targetSkills $skillDir.Name

        if (Test-Path $targetSkill) {
            $response = Ask-Overwrite "$($skillDir.Name)/" ([ref]$allOverwrite)

            if ($response -eq "all" -or $response -eq "y" -or $response -eq "yes") {
                if ($response -eq "all") {
                    $allOverwrite = $true
                }
                Remove-Item $targetSkill -Recurse -Force
                Copy-Item $skillDir.FullName $targetSkill -Recurse
                Write-Success "Installed skill: $($skillDir.Name)"
                $skillsInstalled++
            }
            else {
                Write-Warning-Custom "Skipped skill: $($skillDir.Name)"
                $skillsSkipped++
            }
        }
        else {
            Copy-Item $skillDir.FullName $targetSkill -Recurse
            Write-Success "Installed skill: $($skillDir.Name)"
            $skillsInstalled++
        }
    }

    return @{ Installed = $skillsInstalled; Skipped = $skillsSkipped }
}

function Show-Completion {
    param(
        [int]$AgentsInstalled,
        [int]$AgentsSkipped,
        [int]$SkillsInstalled,
        [int]$SkillsSkipped,
        [string]$TargetPath,
        [array]$IDEDirs
    )

    Write-Host ""
    Write-Host "Installation Complete!" -ForegroundColor Green -BackgroundColor $null
    Write-Host "─────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Agents installed: $AgentsInstalled" -ForegroundColor Green

    if ($AgentsSkipped -gt 0) {
        Write-Host "  Agents skipped: $AgentsSkipped" -ForegroundColor Yellow
    }

    Write-Host "  Skills installed: $SkillsInstalled" -ForegroundColor Green

    if ($SkillsSkipped -gt 0) {
        Write-Host "  Skills skipped: $SkillsSkipped" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Installed to:" -ForegroundColor White
    foreach ($ide in $IDEDirs) {
        $displayName = Get-DisplayName $ide
        Write-Host "  • $TargetPath\$ide\ ($displayName)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor DarkGray
    Write-Host "  1. Review installed agents and skills in each IDE directory"
    Write-Host "  2. Start with the business-analyst or architect agent"
    Write-Host "  3. See AGENT-TEAM-EXECUTION-ORDER.md for workflow"
    Write-Host ""
}

function Prompt-ChangeDirectory {
    param([string]$TargetPath)

    $absTarget = (Resolve-Path $TargetPath).Path

    # Skip if already there
    if ((Get-Location).Path -eq $absTarget) {
        return
    }

    if ($Force) {
        Write-Host "To change directory, run:" -ForegroundColor DarkGray
        Write-Host "  cd $absTarget" -ForegroundColor Cyan
        Write-Host ""
        return
    }

    $response = Read-Host "Change directory to target folder? (y/n)"
    if ($response -match "^[yY]") {
        Write-Info "Opening a new shell in: $absTarget"
        Write-Info "(Type 'exit' to return to your previous shell)"
        Set-Location $absTarget
        $shellExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
        & $shellExe -NoLogo
    }
    else {
        Write-Host "To change directory manually, run:" -ForegroundColor DarkGray
        Write-Host "  cd $absTarget" -ForegroundColor Cyan
        Write-Host ""
    }
}

# Main execution
function Main {
    if ($Help) {
        Write-Help
        exit 0
    }

    Write-Banner
    Validate-SourceDirs

    $targetPath = Get-TargetPath

    # Detect all IDE directories in target
    $ideDirs = Find-IDEDirs $targetPath

    if ($ideDirs.Count -eq 0) {
        # No IDE directories found — default to .claude\ after explicit confirmation
        if (-not (Confirm-DefaultClaudeInstall)) {
            Write-Warning-Custom "Installation cancelled"
            exit 0
        }
        $ideDirs = @('.claude')
        Write-Info "Will create .claude\ directory"
    }
    else {
        Write-Host ""
        Write-Host "Detected IDE frameworks:" -ForegroundColor White
        foreach ($dir in $ideDirs) {
            $displayName = Get-DisplayName $dir
            Write-Success "  $displayName ($dir\)"
        }
    }

    Show-Summary $targetPath $ideDirs

    if (-not (Confirm-Installation)) {
        Write-Warning-Custom "Installation cancelled"
        exit 0
    }

    Write-Host ""
    Write-Host "Installing..." -ForegroundColor White

    $totalAgentsInstalled = 0
    $totalAgentsSkipped = 0
    $totalSkillsInstalled = 0
    $totalSkillsSkipped = 0

    foreach ($ideDir in $ideDirs) {
        $displayName = Get-DisplayName $ideDir
        Write-Host ""
        Write-Host "── $displayName ($ideDir\) ──" -ForegroundColor Cyan
        Write-Host ""

        $agentResults = Copy-Agents $targetPath $ideDir
        Write-Host ""
        $skillResults = Copy-Skills $targetPath $ideDir

        $totalAgentsInstalled += $agentResults.Installed
        $totalAgentsSkipped += $agentResults.Skipped
        $totalSkillsInstalled += $skillResults.Installed
        $totalSkillsSkipped += $skillResults.Skipped
    }

    Show-Completion $totalAgentsInstalled $totalAgentsSkipped $totalSkillsInstalled $totalSkillsSkipped $targetPath $ideDirs

    Prompt-ChangeDirectory $targetPath
}

Main
