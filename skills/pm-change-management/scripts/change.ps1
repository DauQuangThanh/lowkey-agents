# =============================================================================
# change.ps1 — Phase 5: Change Request Tracking (PowerShell)
# Captures change requests with impact assessment, priority, and approval status.
# Output: pm-output/05-change-log.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PM_AUTO = '1' }
if ($Answers) { $env:PM_ANSWERS = $Answers }


Write-PM-Banner "Phase 5: Change Request Tracking"

$changes = @()
$changeCount = 0

# Loop: Add change requests one at a time
while ($true) {
  Write-Host ""
  Write-PMColor "▶ Add a change request (or press Enter to finish)." $script:PMYellow
  Write-Host ""
  $crDesc = Ask-PM-Text "Change request description (what is changing and why?)"
  if ([string]::IsNullOrWhiteSpace($crDesc)) { break }

  $crReason = Ask-PM-Text "Reason for the change (business justification)"
  Write-PM-Dim "Reason: $crReason"

  $scopeImpact = Ask-PM-Choice `
    "Impact on scope?" `
    @("High (affects major features)", "Medium (affects some functionality)", "Low (affects documentation/minor features)", "None")
  $scopeImpact = $scopeImpact[0]
  Write-PM-Dim "Scope impact: $scopeImpact"

  $scheduleImpact = Ask-PM-Choice `
    "Impact on schedule?" `
    @("High (delays major milestone)", "Medium (delays features by weeks)", "Low (delays by days or none)", "None")
  $scheduleImpact = $scheduleImpact[0]
  Write-PM-Dim "Schedule impact: $scheduleImpact"

  $budgetImpact = Ask-PM-Choice `
    "Impact on budget?" `
    @("High (increases budget >20%)", "Medium (increases 5-20%)", "Low (increases <5%)", "None")
  $budgetImpact = $budgetImpact[0]
  Write-PM-Dim "Budget impact: $budgetImpact"

  $qualityImpact = Ask-PM-Choice `
    "Impact on quality?" `
    @("High (may reduce quality)", "Medium (requires extra testing)", "Low (minimal quality impact)", "None")
  $qualityImpact = $qualityImpact[0]
  Write-PM-Dim "Quality impact: $qualityImpact"

  $priority = Ask-PM-Choice `
    "Priority?" `
    @("🔴 Critical (blocks other work)", "🟡 High (important, needs quick approval)", "🟢 Medium (standard approval)", "🔵 Low (can defer)")
  Write-PM-Dim "Priority: $priority"

  $status = Ask-PM-Choice `
    "Approval status?" `
    @("Pending (awaiting review)", "Approved", "Rejected", "On Hold")
  Write-PM-Dim "Status: $status"

  $approvalReason = ""
  if ($status -ne "Pending (awaiting review)") {
    $approvalReason = Ask-PM-Text "Decision reason / comments"
    Write-PM-Dim "Reason: $approvalReason"
  }

  $approver = Ask-PM-Text "Approved/reviewed by (name/role)"
  Write-PM-Dim "Approver: $approver"

  $changeCount++
  $changeId = "CR-{0:D2}" -f $changeCount
  $changeEntry = @{
    Id = $changeId
    Description = $crDesc
    Reason = $crReason
    ScopeImpact = $scopeImpact
    ScheduleImpact = $scheduleImpact
    BudgetImpact = $budgetImpact
    QualityImpact = $qualityImpact
    Priority = $priority
    Status = $status
    ApprovalReason = $approvalReason
    Approver = $approver
  }
  $changes += $changeEntry

  Write-Host ""
  $continue = Ask-PM-YN "Add another change request?"
  if ($continue -eq "no") { break }
}

if ($changeCount -eq 0) {
  Write-PM-Dim "No change requests logged yet."
}

# Confirmation
Write-Host ""
$saveConfirm = Confirm-PM-Save "Save this change log?"
if (-not $saveConfirm) {
  Write-PM-Dim "Change log discarded. Exiting."
  exit 0
}

# Write Output
$outputFile = Join-Path $script:PMOutputDir "05-change-log.md"

$approved = ($changes | Where-Object { $_.Status -eq "Approved" } | Measure-Object).Count
$pending = ($changes | Where-Object { $_.Status -eq "Pending (awaiting review)" } | Measure-Object).Count
$rejected = ($changes | Where-Object { $_.Status -eq "Rejected" } | Measure-Object).Count

$changesContent = ""
if ($changeCount -gt 0) {
  $changesContent = $changes | ForEach-Object {
    $approvalLine = if ($_.ApprovalReason) { "**Reason:** $($_.ApprovalReason)`n" } else { "" }
    @"
### $($_.Id): $($_.Description)
**Requested By:** TBD
**Request Date:** $(Get-Date -Format 'dd/MM/yyyy')
**Priority:** $($_.Priority)
**Status:** $($_.Status)

**Business Reason:** $($_.Reason)

**Impact Assessment:**
| Area | Impact |
|---|---|
| Scope | $($_.ScopeImpact) |
| Schedule | $($_.ScheduleImpact) |
| Budget | $($_.BudgetImpact) |
| Quality | $($_.QualityImpact) |

**Decision:** $($_.Status)
$approvalLine**Approved By:** $($_.Approver)
**Date Approved:** TBD

"@
  } | Out-String
}

$outputContent = @"
# Change Log

**Date:** $(Get-Date -Format 'dd/MM/yyyy')
**Total Changes:** $changeCount

## Change Summary
| Status | Count |
|---|---|
| Approved | $approved |
| Pending | $pending |
| Rejected | $rejected |

## Changes

$changesContent

## Process
1. Requestor submits CR with description and business case
2. PM assesses impact on scope, schedule, budget, quality
3. CCB (Change Control Board) reviews and votes
4. If approved: PM updates plan and communicates to team
5. If rejected: PM documents reason and archives CR for audit trail
"@

Set-Content -Path $outputFile -Value $outputContent

Write-PM-SuccessRule "Change log written to $outputFile"
Write-Host ""

# Final Summary
Write-PM-Dim "Summary:"
Write-PM-Dim "  Total Changes: $changeCount"
if ($changeCount -gt 0) {
  Write-PM-Dim "  Approved: $approved"
  Write-PM-Dim "  Pending: $pending"
  Write-PM-Dim "  Rejected: $rejected"
}

$debtCount = Get-PM-DebtCount
if ($debtCount -gt 0) {
  Write-Host ""
  Write-Host "⚠ $debtCount open PM debt(s) to resolve — see $script:PMDebtFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Phase 5 complete." -ForegroundColor Green
Write-Host ""
