#requires -version 5.1

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:SM_AUTO = '1' }
if ($Answers) { $env:SM_ANSWERS = $Answers }


$OutputFile = Join-Path $script:SMOutputDir "03-retrospective.md"
$Area = "Retrospective"

$startDebts = Get-SM-DebtCount

Write-SM-Banner "Phase 3 of 5 — Sprint Retrospective"
Write-SM-Dim "Let's reflect on this sprint using Start/Stop/Continue format."
Write-SM-Dim "What went well? What didn't? What should we try next?"
Write-Host ""

Write-Host "Setup" -ForegroundColor Cyan -BackgroundColor DarkCyan
$sprintNum = Ask-SM-Text "Which sprint are we retro-ing? (e.g. Sprint 5)"
if ([string]::IsNullOrWhiteSpace($sprintNum)) { $sprintNum = "Sprint-Unknown" }
$retroDate = (Get-Date).ToString("yyyy-MM-dd")
Write-Host ""

Write-Host "Question 1 / 5 — Sprint Metrics" -ForegroundColor Cyan -BackgroundColor DarkCyan
$planned = Ask-SM-Text "How many story points were planned? (or leave blank if using hours)"
if ([string]::IsNullOrWhiteSpace($planned)) { $planned = "TBD" }

$completed = Ask-SM-Text "How many story points were actually completed?"
if ([string]::IsNullOrWhiteSpace($completed)) { $completed = "TBD" }

Write-Host ""
Write-Host "Question 2 / 5 — What Went Well? (CONTINUE doing)" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "List things that went well this sprint. One per line. (blank to finish)"
Write-Host ""

$continueItems = @()
while ($true) {
  $item = Ask-SM-Text "What went well?"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $continueItems += "✅ $item"
}

Write-Host ""
Write-Host "Question 3 / 5 — What Didn't Go Well? (STOP doing)" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "List things that were painful or inefficient. (blank to finish)"
Write-Host ""

$stopItems = @()
while ($true) {
  $item = Ask-SM-Text "What didn't go well?"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $stopItems += "🔴 $item"
}

Write-Host ""
Write-Host "Question 4 / 5 — What Should We Try? (START doing)" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "What new practices or changes should we try next sprint? (blank to finish)"
Write-Host ""

$startItems = @()
while ($true) {
  $item = Ask-SM-Text "What should we try?"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $startItems += "🟡 $item"
}

Write-Host ""
Write-Host "Question 5 / 5 — Action Items" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "Concrete steps to improve. Include owner and due date."
Write-SM-Dim "Format: 'Action | Owner | Due Date' (blank to finish)"
Write-Host ""

$actionItems = @()
while ($true) {
  $action = Ask-SM-Text "Action item (or blank to finish)"
  if ([string]::IsNullOrWhiteSpace($action)) { break }

  $owner = Ask-SM-Text "  Owner"
  if ([string]::IsNullOrWhiteSpace($owner)) { $owner = "TBD" }

  $due = Ask-SM-Text "  Due date (or blank for next sprint)"
  if ([string]::IsNullOrWhiteSpace($due)) { $due = "Next Sprint" }

  $actionItems += @{ Action = $action; Owner = $owner; Due = $due }
}

Write-SM-SuccessRule "✅ Retrospective Summary"
Write-Host ("  Sprint:              {0}" -f $sprintNum)
Write-Host ("  Date:                {0}" -f $retroDate)
Write-Host ("  Planned vs Completed: {0} / {1} points" -f $planned, $completed)
Write-Host ""

if (-not (Confirm-SM-Save "Save retrospective? (y=save / n=redo)")) {
  Write-SM-Dim "Restarting Phase 3..."
  & $PSScriptRoot\retro.ps1
  exit 0
}

$dateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm")

$continueText = if ($continueItems.Count -eq 0) { "(No items captured)" } else { $continueItems -join "`n- " }
$stopText = if ($stopItems.Count -eq 0) { "(No issues identified)" } else { $stopItems -join "`n- " }
$startText = if ($startItems.Count -eq 0) { "(No improvements proposed)" } else { $startItems -join "`n- " }

$actionText = ""
if ($actionItems.Count -gt 0) {
  foreach ($ai in $actionItems) {
    $actionText += "- [ ] $($ai.Action) | *Owner:* $($ai.Owner) | *Due:* $($ai.Due)`n"
  }
} else {
  $actionText = "(No action items)"
}

$output = @"
# Sprint Retrospective

> Captured: $dateTime

## Sprint Information

**Sprint:** $sprintNum
**Retro Date:** $retroDate

### Velocity

| Metric | Value |
|--------|-------|
| Planned | $planned points |
| Completed | $completed points |

---

## Start / Stop / Continue

### Continue (What went well?)

- $continueText

### Stop (What didn't go well?)

- $stopText

### Start (What should we try?)

- $startText

---

## Action Items for Next Sprint

$actionText

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8
Write-SM-SuccessRule "✅ Retrospective saved to $OutputFile"

$endDebts = Get-SM-DebtCount
$newDebts = $endDebts - $startDebts
if ($newDebts -gt 0) {
  Write-SM-Dim "  ⚠️  $newDebts process improvement(s) logged. Review in $script:SMDebtFile"
}
