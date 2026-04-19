# =============================================================================
# communication.ps1 — Phase 4: Communication & Stakeholder Management (PowerShell)
# Captures stakeholder groups, communication channels, cadence, escalation,
# RACI matrix, and change request process.
# Output: pm-output/04-communication-plan.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PM_AUTO = '1' }
if ($Answers) { $env:PM_ANSWERS = $Answers }


Write-PM-Banner "Phase 4: Communication & Stakeholder Management"

# Question 1: Stakeholder Groups
Write-Host ""
Write-PMColor "▶ Define stakeholder groups and their communication preferences." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: Exec Steering, Development Team, QA, Product Owner, Clients)"
Write-PM-Dim "   For each group, provide: Name | Key Interests | Communication Channel | Frequency"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$stakeholders = @()
while ($true) {
  $item = Ask-PM-Text "Add stakeholder group (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $stakeholders += $item
  Write-PM-Dim "Added: $item"
}

if ($stakeholders.Count -eq 0) {
  Write-PM-Dim "No stakeholder groups defined — logging as debt."
  Add-PM-Debt "Communication" "Stakeholder groups undefined" "No stakeholder groups or communication preferences captured" "Cannot ensure all stakeholders are informed"
  $stakeholders = @("(TBD)")
}

# Question 2: Communication Channels
Write-Host ""
Write-PMColor "▶ Which communication channels will you use?" $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: Email, Slack, Jira, Weekly meetings, SharePoint wiki, Town halls)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$channels = @()
while ($true) {
  $item = Ask-PM-Text "Add communication channel (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $channels += $item
  Write-PM-Dim "Added: $item"
}

if ($channels.Count -eq 0) {
  Write-PM-Dim "No channels defined — logging as debt."
  Add-PM-Debt "Communication" "Communication channels undefined" "No specific communication channels identified" "Cannot ensure consistent and accessible information flow"
  $channels = @("(TBD)")
}

# Question 3: Meeting Cadence
$cadence = Ask-PM-Choice `
  "What is your primary meeting cadence?" `
  @("Daily standup", "Weekly", "Bi-weekly", "Monthly", "As-needed")
Write-PM-Dim "Meeting cadence: $cadence"

# Question 4: Escalation Path
Write-Host ""
Write-PMColor "▶ Define your escalation path." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: Blocker → PM → Sponsor, within 2 hours; Critical issue → CCB)"
Write-Host ""

$escalation = Ask-PM-Text "Describe your escalation rules (or type 'skip' to use defaults)"
if ($escalation -eq "skip" -or [string]::IsNullOrWhiteSpace($escalation)) {
  $escalation = @"
Tier 1: Blocker → PM → Sponsor (within 2 hours)
Tier 2: Critical issue → CCB review (within 1 day)
"@
  Write-PM-Dim "Using default escalation rules."
} else {
  Write-PM-Dim "Escalation: $escalation"
}

# Question 5: RACI for Key Deliverables
Write-Host ""
Write-PMColor "▶ Define RACI for key deliverables." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (R=Responsible, A=Accountable, C=Consulted, I=Informed)"
Write-PM-Dim "   (Example: Project Plan - R:PM, A:Sponsor, C:Tech Lead, I:Team)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$raciItems = @()
while ($true) {
  $item = Ask-PM-Text "Add RACI entry (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $raciItems += $item
  Write-PM-Dim "Added: $item"
}

if ($raciItems.Count -eq 0) {
  Write-PM-Dim "No RACI matrix entries — logging as debt."
  Add-PM-Debt "Communication" "RACI matrix incomplete" "No clear responsibility assignments for key deliverables" "Roles and accountability are unclear"
  $raciItems = @("(TBD)")
}

# Question 6: Change Request Process
Write-Host ""
Write-PMColor "▶ How will change requests be handled?" $script:PMYellow
Write-Host ""

$crApproval = Ask-PM-Text "Who approves change requests? (role/name/board)"
Write-PM-Dim "CR Approval: $crApproval"

$crTriggers = Ask-PM-Text "What triggers a change request? (Scope change, Budget change, Schedule change, all of above, etc.)"
Write-PM-Dim "CR Triggers: $crTriggers"

# Confirmation
Write-Host ""
$saveConfirm = Confirm-PM-Save "Save this communication plan?"
if (-not $saveConfirm) {
  Write-PM-Dim "Plan discarded. Exiting."
  exit 0
}

# Write Output
$outputFile = Join-Path $script:PMOutputDir "04-communication-plan.md"

$stakeholderTable = if ($stakeholders[0] -ne "(TBD)") {
  $stakeholders | ForEach-Object { "| $_ | TBD | TBD | TBD |" } | Out-String
} else {
  "| (TBD) | | | |"
}

$channelsList = if ($channels[0] -ne "(TBD)") {
  $channels | ForEach-Object { "- $_" } | Out-String
} else {
  "- (TBD)"
}

$raciTable = if ($raciItems[0] -ne "(TBD)") {
  $raciItems | ForEach-Object { "| $_ | TBD | TBD | TBD |" } | Out-String
} else {
  "| (TBD) | | | |"
}

$escalationFormatted = $escalation -replace "^", "- "

$outputContent = @"
# Communication Plan

**Date:** $(Get-Date -Format 'dd/MM/yyyy')

## Stakeholder Groups
| Group | Key Interests | Communication Channel | Frequency |
|---|---|---|---|
$stakeholderTable

## Communication Channels
$channelsList

## Meeting Cadence
**Primary Cadence:** $cadence
- Standup/Status meetings: [To be scheduled]
- Steering committee: [To be scheduled]

## Escalation Path
$escalationFormatted

## RACI Matrix (Key Deliverables)
| Deliverable | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
$raciTable

## Change Request Process
**Approval Authority:** $crApproval
**Triggers:** $crTriggers
**Process:**
1. Requestor submits CR with description and rationale
2. PM assesses impact (scope, schedule, budget, quality)
3. CCB (Change Control Board) reviews and votes
4. If approved: PM updates plan, communicates change
5. If rejected: PM documents reason and archives CR
"@

Set-Content -Path $outputFile -Value $outputContent

Write-PM-SuccessRule "Communication plan written to $outputFile"
Write-Host ""

# Final Summary
Write-PM-Dim "Summary:"
Write-PM-Dim "  Stakeholder Groups: $(if ($stakeholders[0] -eq '(TBD)') { 'TBD' } else { $stakeholders.Count }) defined"
Write-PM-Dim "  Communication Channels: $(if ($channels[0] -eq '(TBD)') { 'TBD' } else { $channels.Count }) defined"
Write-PM-Dim "  Meeting Cadence: $cadence"
Write-PM-Dim "  CR Approval: $crApproval"

$debtCount = Get-PM-DebtCount
if ($debtCount -gt 0) {
  Write-Host ""
  Write-Host "⚠ $debtCount open PM debt(s) to resolve — see $script:PMDebtFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Phase 4 complete." -ForegroundColor Green
Write-Host ""
