# =============================================================================
# sprint-review.ps1 — Phase 5: Sprint Review Preparation (PowerShell)
# Output: $POOutputDir\05-sprint-review.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PO_AUTO = '1' }
if ($Answers) { $env:PO_ANSWERS = $Answers }


$OutputFile = Join-Path $script:POOutputDir "05-sprint-review.md"
$Area       = "Sprint Review"

$startDebts = Get-PO-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-PO-Banner "✓   Phase 5 — Sprint Review Preparation"
Write-PO-Dim "  Let's document what was delivered this sprint."
Write-Host ""

# ── Q1: Sprint info ───────────────────────────────────────────────────────────
Write-Host "Question 1 / 6 — Sprint Information" -ForegroundColor Cyan
$SprintNum = Ask-PO-Text "Sprint number (e.g. 'Sprint 5', 'Iteration 3'):"
if ([string]::IsNullOrWhiteSpace($SprintNum)) { $SprintNum = "Current Sprint" }

$SprintDates = Ask-PO-Text "Sprint dates (e.g. 'Apr 7-18, 2026'):"
if ([string]::IsNullOrWhiteSpace($SprintDates)) { $SprintDates = "TBD" }

# ── Q2: Stories completed ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 6 — Stories Completed" -ForegroundColor Cyan
Write-PO-Dim "  Which backlog items or stories were completed this sprint?"
Write-Host ""

$CompletedItems  = @()
$CompletedSizing = @()

$completedCount = 0

while ($true) {
  $itemNum = $completedCount + 1
  $response = Read-Host "▶ Add completed item #$itemNum`? (y/n)"
  if ($response -notin "y", "yes") {
    break
  }

  $Item = Ask-PO-Text "Item title:"
  if ([string]::IsNullOrWhiteSpace($Item)) { $Item = "Unnamed Item" }
  $CompletedItems += $Item

  $Sizing = Ask-PO-Choice "Sizing:" @(
    "S — Small",
    "M — Medium",
    "L — Large",
    "XL — Extra Large"
  )
  $CompletedSizing += $Sizing

  $completedCount++
}

# ── Q3: Stories not completed ─────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 6 — Stories Not Completed" -ForegroundColor Cyan
Write-PO-Dim "  Which items were not completed? Why? (technical blockers, scope, capacity, etc.)"
Write-Host ""

$IncompleteItems  = @()
$IncompleteReasons = @()

$incompleteCount = 0

while ($true) {
  $itemNum = $incompleteCount + 1
  $response = Read-Host "▶ Add incomplete item #$itemNum`? (y/n)"
  if ($response -notin "y", "yes") {
    break
  }

  $Item = Ask-PO-Text "Item title:"
  if ([string]::IsNullOrWhiteSpace($Item)) { $Item = "Unnamed Item" }
  $IncompleteItems += $Item

  $Reason = Ask-PO-Text "Reason for non-completion:"
  if ([string]::IsNullOrWhiteSpace($Reason)) { $Reason = "TBD" }
  $IncompleteReasons += $Reason

  $incompleteCount++
}

# ── Q4: Demo items ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 6 — Demo Items & Highlights" -ForegroundColor Cyan
Write-PO-Dim "  What are the standout items to demo to stakeholders?"
Write-Host ""
$DemoItems = Ask-PO-Text "Your answer (comma-separated, or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($DemoItems)) { $DemoItems = "Items shown in review" }

# ── Q5: Stakeholder feedback ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 6 — Stakeholder Feedback" -ForegroundColor Cyan
Write-PO-Dim "  What feedback did stakeholders provide during the review?"
Write-Host ""
$Feedback = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Feedback)) { $Feedback = "No formal feedback collected" }

# ── Q6: Backlog adjustments ───────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 6 — Backlog Adjustments & Next Sprint" -ForegroundColor Cyan
Write-PO-Dim "  What backlog changes or reprioritization is needed?"
Write-PO-Dim "  What's planned for the next sprint?"
Write-Host ""
$Adjustments = Ask-PO-Text "Your answer (or press Enter to defer):"
if ([string]::IsNullOrWhiteSpace($Adjustments)) { $Adjustments = "To be determined in sprint planning" }

# ── Calculate metrics ─────────────────────────────────────────────────────────
$totalItems = $completedCount + $incompleteCount
if ($totalItems -gt 0) {
  $completionRate = [Math]::Round(($completedCount * 100 / $totalItems), 0)
} else {
  $completionRate = 0
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-PO-SuccessRule "✅ Sprint Review Summary"
Write-Host "  Sprint:           $SprintNum ($SprintDates)"
Write-Host "  Completed:        $completedCount items"
Write-Host "  Incomplete:       $incompleteCount items"
Write-Host "  Completion Rate:  $completionRate%"
Write-Host ""

if (-not (Confirm-PO-Save "Does this look correct? (y=save / n=redo)")) {
  Write-PO-Dim "  Restarting phase 5..."
  & $PSCommandPath
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$output = @"
# Sprint Review

> Captured: $DateNow

## Sprint Information

**Sprint:** $SprintNum

**Dates:** $SprintDates

## Metrics

| Metric | Value |
|--------|-------|
| Items Completed | $completedCount |
| Items Incomplete | $incompleteCount |
| Total Items | $totalItems |
| Completion Rate | $completionRate% |

## Items Completed

"@

if ($completedCount -gt 0) {
  $output += "| Item | Sizing |`n"
  $output += "|------|--------|`n"
  for ($i = 0; $i -lt $completedCount; $i++) {
    $output += "| $($CompletedItems[$i]) | $($CompletedSizing[$i]) |`n"
  }
  $output += "`n"
} else {
  $output += "(No items completed)`n`n"
}

$output += "## Items Not Completed`n`n"

if ($incompleteCount -gt 0) {
  $output += "| Item | Reason |`n"
  $output += "|------|--------|`n"
  for ($i = 0; $i -lt $incompleteCount; $i++) {
    $output += "| $($IncompleteItems[$i]) | $($IncompleteReasons[$i]) |`n"
  }
  $output += "`n"
} else {
  $output += "(All planned items completed)`n`n"
}

$output += @"
## Demo Items & Highlights

"@

$demoList = $DemoItems -split ', '
foreach ($item in $demoList) {
  $output += "- $item`n"
}

$output += @"

## Stakeholder Feedback

$Feedback

## Backlog Adjustments & Next Sprint

$Adjustments

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-PO-SuccessRule "✅ Sprint Review saved"
Write-Host "  Output: $OutputFile" -ForegroundColor Green
Write-Host ""

# ── Log new debts ─────────────────────────────────────────────────────────────
$endDebts = Get-PO-DebtCount
if ($endDebts -gt $startDebts) {
  $newDebts = $endDebts - $startDebts
  Write-PO-Dim "  Logged $newDebts debt(s) — see po-output/06-po-debts.md"
}
Write-Host ""
