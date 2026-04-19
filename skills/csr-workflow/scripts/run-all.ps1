#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:CSR_AUTO = '1' }
if ($Answers) { $env:CSR_ANSWERS = $Answers }
if (Get-Command Invoke-CSR-ParseFlags -ErrorAction SilentlyContinue) { Invoke-CSR-ParseFlags -Args $args }

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

Write-CSR-Banner "CODE SECURITY REVIEW WORKFLOW — ALL PHASES"

Write-Host "$([char]27)[0;36mExecuting Phases 1–5 of the Code Security Review...$([char]27)[0m`n"

$Phases = @(
  @{ Name = "Phase 1: Vulnerability Assessment"; Path = "..\..\csr-vulnerability\scripts\vulnerability.ps1" }
  @{ Name = "Phase 2: Authentication & Authorization Review"; Path = "..\..\csr-auth-review\scripts\auth-review.ps1" }
  @{ Name = "Phase 3: Data Protection & Privacy Review"; Path = "..\..\csr-data-protection\scripts\data-protection.ps1" }
  @{ Name = "Phase 4: Dependency & Supply Chain Audit"; Path = "..\..\csr-dependency-audit\scripts\dependency-audit.ps1" }
  @{ Name = "Phase 5: Security Report & Remediation Plan"; Path = "..\..\csr-report\scripts\report.ps1" }
)

$Failed = 0
foreach ($Phase in $Phases) {
  Write-Host "$([char]27)[0;36m$([char]27)[1m$($Phase.Name)$([char]27)[0m"

  $PhaseFullPath = Join-Path $ScriptDir $Phase.Path
  if (Test-Path $PhaseFullPath) {
    try {
      & $PhaseFullPath
      Write-Host "$([char]27)[0;32m✓ $($Phase.Name) completed successfully$([char]27)[0m`n"
    }
    catch {
      Write-Host "$([char]27)[1;31m✗ $($Phase.Name) failed$([char]27)[0m`n"
      Write-Host "$([char]27)[0;31m$($_.Exception.Message)$([char]27)[0m`n"
      $Failed++
    }
  }
  else {
    Write-Host "$([char]27)[1;31m✗ $($Phase.Name) script not found at $PhaseFullPath$([char]27)[0m`n"
    $Failed++
  }
}

Write-Host ""

if ($Failed -eq 0) {
  Write-CSR-SuccessRule "ALL PHASES COMPLETE - Code Security Review finished successfully!"
  Write-Host "$([char]27)[0;32m`nOutput files:$([char]27)[0m"
  Get-ChildItem -Path "$script:CSROutputDir\*.md" | ForEach-Object { Write-Host "  $($_.FullName)" }
  Write-Host "`n$([char]27)[0;36mNext: Review CSR-FINAL.md and create remediation tickets.$([char]27)[0m`n"
}
else {
  Write-Host "$([char]27)[1;31m$Failed phase(s) failed. Review logs above for details.$([char]27)[0m`n"
  exit 1
}
