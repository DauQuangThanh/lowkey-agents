#requires -version 5.1

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:SM_AUTO = '1' }
if ($Answers) { $env:SM_ANSWERS = $Answers }


$OutputFile = Join-Path $script:SMOutputDir "02-standup-log.md"
$Area = "Standup"

$startDebts = Get-SM-DebtCount

Write-SM-Banner "Phase 2 of 5 — Daily Standup"
Write-SM-Dim "Let's capture standup updates from each team member."
Write-SM-Dim "I'll ask: What did you do? What will you do? Any blockers?"
Write-Host ""

Write-Host "Setup" -ForegroundColor Cyan -BackgroundColor DarkCyan
$standupDate = (Get-Date).ToString("yyyy-MM-dd")
Write-Host ""

$teamMembers = @()
$blockers = @()
$memberCount = 0

while ($true) {
  $member = Ask-SM-Text "Team member name (or blank to finish)"
  if ([string]::IsNullOrWhiteSpace($member)) { break }

  $memberCount++
  Write-Host ""
  Write-Host "Team Member $memberCount`: $member" -ForegroundColor Magenta

  $yesterday = Ask-SM-Text "  What did you accomplish yesterday?"
  if ([string]::IsNullOrWhiteSpace($yesterday)) { $yesterday = "(Nothing to report)" }

  Write-Host ""
  $today = Ask-SM-Text "  What will you work on today?"
  if ([string]::IsNullOrWhiteSpace($today)) { $today = "(TBD)" }

  Write-Host ""
  $blocker = Ask-SM-Text "  Any blockers or impediments? (blank if none)"

  $memberUpdate = @{
    Name = $member
    Yesterday = $yesterday
    Today = $today
    Blocker = if ([string]::IsNullOrWhiteSpace($blocker)) { "None" } else { $blocker }
  }

  $teamMembers += $memberUpdate

  if (-not [string]::IsNullOrWhiteSpace($blocker)) {
    $blockers += @{ Member = $member; Blocker = $blocker }
    Add-SM-Debt $Area "Blocker: $blocker" `
      "$member blocked on: $blocker" `
      "Unblocking decision or task needed"
  }

  Write-Host ""
}

Write-SM-SuccessRule "✅ Standup Summary"
Write-Host ("  Date:          {0}" -f $standupDate)
Write-Host ("  Team members:  {0}" -f $memberCount)
Write-Host ("  Blockers:      {0}" -f $blockers.Count)
Write-Host ""

if (-not (Confirm-SM-Save "Save standup notes? (y=save / n=redo)")) {
  Write-SM-Dim "Restarting Phase 2..."
  & $PSScriptRoot\standup.ps1
  exit 0
}

$dateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm")
$teamMemberText = ""
foreach ($tm in $teamMembers) {
  $teamMemberText += @"
### $($tm.Name)

**Yesterday:** $($tm.Yesterday)

**Today:** $($tm.Today)

**Blockers:** $(if ($tm.Blocker -eq "None") { "None" } else { "⚠️ $($tm.Blocker)" })

"@
}

$blockersText = ""
if ($blockers.Count -gt 0) {
  foreach ($b in $blockers) {
    $blockersText += "- $($b.Member): $($b.Blocker)`n"
  }
} else {
  $blockersText = "None identified"
}

$smActions = ""
if ($blockers.Count -gt 0) {
  $smActions = "- [ ] Follow up on $($blockers.Count) blocker(s)`n- [ ] Escalate if needed to stakeholders"
} else {
  $smActions = "- [ ] Team is unblocked and moving forward"
}

$output = @"
# Daily Standup

> Captured: $dateTime

## Standup Date

**Date:** $standupDate
**Team Members Reporting:** $memberCount

## Team Updates

$teamMemberText---

## Impediments Summary

**Blockers Identified:** $($blockers.Count)

$blockersText

## SM Actions

$smActions

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8
Write-SM-SuccessRule "✅ Standup log saved to $OutputFile"

$endDebts = Get-SM-DebtCount
$newDebts = $endDebts - $startDebts
if ($newDebts -gt 0) {
  Write-SM-Dim "  ⚠️  $newDebts blocker(s) logged as debts. Review in $script:SMDebtFile"
}
