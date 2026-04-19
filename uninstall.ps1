#!/usr/bin/env pwsh
#
# lowkey-agents uninstaller (PowerShell 5.1+, Windows/Cross-platform)
# Removes 14 agents and 85 skills from 25+ AI coding platforms
#
# Usage:
#   .\uninstall.ps1                          # Interactive mode
#   .\uninstall.ps1 -Target "C:\path\to\proj"  # Non-interactive
#   .\uninstall.ps1 -Help                    # Show help
#   .\uninstall.ps1 -Force -Target "C:\path"  # Skip confirmations
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
$Script:AgentsRemoved = 0
$Script:AgentsNotFound = 0
$Script:SkillsRemoved = 0
$Script:SkillsNotFound = 0

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
    Write-Host "║         LOWKEY-AGENTS UNINSTALLER.                     ║" -ForegroundColor $Colors['Cyan']
    Write-Host "║   Remove 14 Agents + 85 Skills from 25+ AI Platforms   ║" -ForegroundColor $Colors['Cyan']
    Write-Host "║   Developed by Dau Quang Thanh                         ║" -ForegroundColor $Colors['Cyan']
    Write-Host "║   Version 2.0 — Production Ready                       ║" -ForegroundColor $Colors['Cyan']
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $Colors['Cyan']
    Write-Host ""
}

function Write-Help {
    $helpText = @"
Usage: .\uninstall.ps1 [OPTIONS]

OPTIONS:
  -Target <path>      Target project path (non-interactive)
  -Force              Skip all confirmation prompts
  -Help               Show this help message

EXAMPLES:
  Interactive mode:
    .\uninstall.ps1

  Non-interactive with target path:
    .\uninstall.ps1 -Target C:\my-project

  Force removal without prompts:
    .\uninstall.ps1 -Force -Target C:\my-project

NOTE:
  This script only removes lowkey-agents files that match names
  in the source. It never deletes the IDE config directory itself
  (e.g., .claude\, .windsurf\, etc.)
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
}

function Get-TargetPath {
    if ([string]::IsNullOrWhiteSpace($Target)) {
        Write-Host ""
        Write-Host "Target Project Path" -ForegroundColor White
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

function Get-AgentsSubdir {
    param([string]$ConfigDir)

    foreach ($platform in $Script:Platforms) {
        if ($platform.ConfigDir -eq $ConfigDir) {
            return $platform.AgentsSubdir
        }
    }

    return "agents"
}

function Find-IDEDirs {
    param([string]$TargetPath)

    $ideDirs = @()

    # Check in priority order defined by $Script:Platforms
    foreach ($platform in $Script:Platforms) {
        $idePath = Join-Path $TargetPath $platform.ConfigDir
        if (Test-Path $idePath) {
            $ideDirs += $platform.ConfigDir
        }
    }

    return $ideDirs
}

function Show-RemovalSummary {
    param(
        [string]$TargetPath,
        [array]$IDEDirs
    )

    Write-Host ""
    Write-Host "Removal Summary" -ForegroundColor White
    Write-Host "─────────────────────────────────────" -ForegroundColor DarkGray
    Write-Info "Target project: $TargetPath"
    Write-Host ""
    Write-Host "IDE frameworks found:" -ForegroundColor White

    foreach ($dir in $IDEDirs) {
        Write-Host "  • $dir\" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "Files that will be removed:" -ForegroundColor White
    Write-Host "  Agents:" -ForegroundColor Cyan

    Get-ChildItem -Path $Script:AgentsSrc -Filter "*.md" -File |
        ForEach-Object { $_.BaseName } |
        Sort-Object |
        ForEach-Object { Write-Host "    • $_" }

    Write-Host ""
    Write-Host "  Skills:" -ForegroundColor Cyan

    Get-ChildItem -Path $Script:SkillsSrc -Directory |
        ForEach-Object { $_.Name } |
        Sort-Object |
        ForEach-Object { Write-Host "    • $_\" }

    Write-Host ""
}

function Confirm-Removal {
    if ($Force) {
        return $true
    }

    $response = Read-Host "Proceed with removal? This action cannot be undone. (y/n)"
    return $response -match "^[yY]"
}

function Remove-Agents {
    param(
        [string]$TargetPath,
        [array]$IDEDirs
    )

    foreach ($ide in $IDEDirs) {
        $agentsSubdir = Get-AgentsSubdir $ide
        $agentsPath = Join-Path $TargetPath $ide $agentsSubdir

        if (-not (Test-Path $agentsPath)) {
            continue
        }

        Get-ChildItem -Path $Script:AgentsSrc -Filter "*.md" -File | ForEach-Object {
            $agentName = $_.BaseName
            $targetFile = Join-Path $agentsPath $_.Name

            if (Test-Path $targetFile) {
                Remove-Item $targetFile -Force
                Write-Success "Removed agent: $agentName (from $ide\)"
                $Script:AgentsRemoved++
            }
            else {
                $Script:AgentsNotFound++
            }
        }
    }
}

function Remove-Skills {
    param(
        [string]$TargetPath,
        [array]$IDEDirs
    )

    foreach ($ide in $IDEDirs) {
        $skillsPath = Join-Path $TargetPath $ide "skills"

        if (-not (Test-Path $skillsPath)) {
            continue
        }

        Get-ChildItem -Path $Script:SkillsSrc -Directory | ForEach-Object {
            $skillName = $_.Name
            $targetSkill = Join-Path $skillsPath $skillName

            if (Test-Path $targetSkill) {
                Remove-Item $targetSkill -Recurse -Force
                Write-Success "Removed skill: $skillName (from $ide\)"
                $Script:SkillsRemoved++
            }
            else {
                $Script:SkillsNotFound++
            }
        }
    }
}

function Show-Completion {
    param([string]$TargetPath)

    Write-Host ""
    Write-Host "Removal Complete!" -ForegroundColor Green
    Write-Host "─────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Agents removed: $($Script:AgentsRemoved)" -ForegroundColor Green

    if ($Script:AgentsNotFound -gt 0) {
        Write-Host "  Agents not found: $($Script:AgentsNotFound)" -ForegroundColor DarkGray
    }

    Write-Host "  Skills removed: $($Script:SkillsRemoved)" -ForegroundColor Green

    if ($Script:SkillsNotFound -gt 0) {
        Write-Host "  Skills not found: $($Script:SkillsNotFound)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "Removal from: $TargetPath\" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor DarkGray
    Write-Host "  • IDE configuration directories (.claude\, .windsurf\, etc) were left in place"
    Write-Host "  • You can safely delete them manually if needed"
    Write-Host "  • To reinstall, run .\install.ps1"
    Write-Host ""
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

    $ideDirs = Find-IDEDirs $targetPath

    if ($ideDirs.Count -eq 0) {
        Write-Warning-Custom "No IDE framework directories found in $targetPath"
        Write-Info "Checked for: .claude\, .cursor\, .windsurf\, .github\, .copilot\, .cline\, .roo\, .opencode\, .codex\, .gemini\, .amp\, .augment\, .agent\, .bob\, .codebuddy\, .forge\, .junie\, .kilocode\, .kiro\, .omp\, .qoder\, .qwen\, .tabnine\, .trae\, .vibe\"
        exit 0
    }

    Show-RemovalSummary $targetPath $ideDirs

    if (-not (Confirm-Removal)) {
        Write-Warning-Custom "Removal cancelled"
        exit 0
    }

    Write-Host ""
    Write-Host "Removing..." -ForegroundColor White
    Write-Host ""

    Remove-Agents $targetPath $ideDirs
    Write-Host ""
    Remove-Skills $targetPath $ideDirs

    Show-Completion $targetPath
}

Main
