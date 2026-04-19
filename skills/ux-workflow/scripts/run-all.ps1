#Requires -Version 5.1
# =============================================================================
# run-all.ps1 — UX Workflow Orchestrator (PowerShell)
# Executes all 4 UX phases in sequence.
# =============================================================================

param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:UX_AUTO = '1' }
if ($Answers) { $env:UX_ANSWERS = $Answers }
if (Get-Command Invoke-UX-ParseFlags -ErrorAction SilentlyContinue) { Invoke-UX-ParseFlags -Args $args }

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Source common helpers from ux-research
. "$SkillsDir\ux-research\scripts\_common.ps1"

Write-UX-Banner "🚀  UX Designer Workflow — Complete"
Write-UX-Dim "  Running all phases in sequence. This will take 30–45 minutes."
Write-Host ""

# ── Phase 1: User Research ─────────────────────────────────────────────────────
Write-Host ""
Write-UX-Dim "  ▶ Starting Phase 1: User Research & Personas..."
Write-Host ""
try {
  & "$SkillsDir\ux-research\scripts\research.ps1"
  Write-UX-SuccessRule "✅ Phase 1 Complete"
} catch {
  Write-Host "$($script:UX_RED)❌ Phase 1 failed. Aborting workflow.$($script:UX_NC)"
  exit 1
}

# ── Phase 2: Wireframes ────────────────────────────────────────────────────────
Write-Host ""
Write-UX-Dim "  ▶ Starting Phase 2: Wireframes & Information Architecture..."
Write-Host ""
try {
  & "$SkillsDir\ux-wireframe\scripts\wireframe.ps1"
  Write-UX-SuccessRule "✅ Phase 2 Complete"
} catch {
  Write-Host "$($script:UX_RED)❌ Phase 2 failed. Aborting workflow.$($script:UX_NC)"
  exit 1
}

# ── Phase 3: Mockups ───────────────────────────────────────────────────────────
Write-Host ""
Write-UX-Dim "  ▶ Starting Phase 3: Mockup & Prototype Specification..."
Write-Host ""
try {
  & "$SkillsDir\ux-prototype\scripts\prototype.ps1"
  Write-UX-SuccessRule "✅ Phase 3 Complete"
} catch {
  Write-Host "$($script:UX_RED)❌ Phase 3 failed. Aborting workflow.$($script:UX_NC)"
  exit 1
}

# ── Phase 4: Validation ────────────────────────────────────────────────────────
Write-Host ""
Write-UX-Dim "  ▶ Starting Phase 4: UX Review & Validation..."
Write-Host ""
try {
  & "$SkillsDir\ux-validation\scripts\validate.ps1"
  Write-UX-SuccessRule "✅ Phase 4 Complete"
} catch {
  Write-Host "$($script:UX_RED)❌ Phase 4 failed. Aborting workflow.$($script:UX_NC)"
  exit 1
}

# ── Final Summary ──────────────────────────────────────────────────────────────
Write-Host ""
Write-UX-Banner "🎉  UX Workflow Complete!"
Write-UX-Dim "  All phases executed successfully."
Write-Host "$($script:UX_GREEN)  Deliverables saved to: $script:UXOutputDir$($script:UX_NC)"
Write-Host "$($script:UX_GREEN)  Final package: $script:UXOutputDir\UX-DESIGNER-FINAL.md$($script:UX_NC)"
Write-Host ""
