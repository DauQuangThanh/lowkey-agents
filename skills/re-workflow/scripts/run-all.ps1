# =============================================================================
# run-all.ps1 — Reverse Engineering Workflow Orchestrator
# Runs all 6 RE phases sequentially and compiles RE-FINAL.md.
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

# Step 1: accept --auto / --answers
if ($Auto)    { $env:RE_AUTO    = '1' }
if ($Answers) { $env:RE_ANSWERS = $Answers }
if (Get-Command Invoke-RE-ParseFlags -ErrorAction SilentlyContinue) {
  Invoke-RE-ParseFlags -Args $args
}

Write-Host "Phase 0: RE Workflow Orchestrator"
Write-Host ""

# Phase scripts live as siblings in skills/<phase>/scripts/. Each phase
# tolerates missing upstream output (it logs a debt and continues), so
# ErrorAction Continue keeps the chain running on partial failures.
$SkillsRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

& (Join-Path $SkillsRoot "re-codebase-scan"          | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "codebase-scan.ps1")         -ErrorAction Continue
& (Join-Path $SkillsRoot "re-architecture-extraction" | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "architecture.ps1")          -ErrorAction Continue
& (Join-Path $SkillsRoot "re-api-documentation"      | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "api-docs.ps1")              -ErrorAction Continue
& (Join-Path $SkillsRoot "re-data-model"             | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "data-model.ps1")            -ErrorAction Continue
& (Join-Path $SkillsRoot "re-dependency-analysis"    | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "dependency-analysis.ps1")   -ErrorAction Continue
& (Join-Path $SkillsRoot "re-documentation-gen"      | Join-Path -ChildPath "scripts" | Join-Path -ChildPath "doc-gen.ps1")               -ErrorAction Continue

Write-Host ""
$OutDir = if ($env:RE_OUTPUT_DIR) { $env:RE_OUTPUT_DIR } else { "./re-output" }
Write-Host "RE Workflow Complete. Outputs in $OutDir/"
