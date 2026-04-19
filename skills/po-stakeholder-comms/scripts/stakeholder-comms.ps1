# =============================================================================
# stakeholder-comms.ps1 — Phase 4: Stakeholder Communication (PowerShell)
# Output: $POOutputDir\04-stakeholder-comms.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PO_AUTO = '1' }
if ($Answers) { $env:PO_ANSWERS = $Answers }


$OutputFile = Join-Path $script:POOutputDir "04-stakeholder-comms.md"
$Area       = "Stakeholder Communication"

$startDebts = Get-PO-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-PO-Banner "📣  Phase 4 — Stakeholder Communication Plan"
Write-PO-Dim "  Let's define how we communicate product progress to key groups."
Write-Host ""

# ── Q1: Stakeholder groups ────────────────────────────────────────────────────
Write-Host "Question 1 / 6 — Stakeholder Groups" -ForegroundColor Cyan
Write-PO-Dim "  Who are the key stakeholders for this product?"
Write-PO-Dim "  Example: executives, customers, support team, partners, etc."
Write-Host ""

$Groups       = @()
$GroupFreq    = @()
$GroupFormat  = @()
$GroupNeeds   = @()

$groupCount = 0

while ($true) {
  $groupNum = $groupCount + 1
  $response = Read-Host "▶ Add stakeholder group #$groupNum`? (y/n)"
  if ($response -notin "y", "yes") {
    break
  }

  $Group = Ask-PO-Text "Group name (e.g. 'Executives', 'Customers', 'Support Team'):"
  if ([string]::IsNullOrWhiteSpace($Group)) { $Group = "Unnamed Group" }
  $Groups += $Group

  $Freq = Ask-PO-Choice "Communication frequency:" @(
    "Weekly",
    "Bi-weekly",
    "Monthly",
    "Quarterly",
    "Ad-hoc (only on major updates)"
  )
  $GroupFreq += $Freq

  $Format = Ask-PO-Choice "Preferred format:" @(
    "Email update",
    "In-person meeting",
    "Video call",
    "Dashboard / self-serve",
    "Mixed (combination)"
  )
  $GroupFormat += $Format

  $Needs = Ask-PO-Text "What do they need to know? (progress, metrics, blockers, timeline, etc.):"
  if ([string]::IsNullOrWhiteSpace($Needs)) { $Needs = "Standard updates" }
  $GroupNeeds += $Needs

  $groupCount++
}

if ($groupCount -eq 0) {
  Add-PO-Debt -Area $Area -Title "No stakeholder groups defined" `
    -Description "Stakeholder communication groups are not identified" `
    -Impact "Communication strategy, stakeholder alignment"
}

# ── Q2: Sprint review format ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 6 — Sprint Review Format" -ForegroundColor Cyan
Write-PO-Dim "  How do you run sprint reviews? Who attends? What's the agenda?"
Write-Host ""
$SprintFormat = Ask-PO-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($SprintFormat)) {
  $SprintFormat = "Not yet defined"
  Add-PO-Debt -Area $Area -Title "Sprint review format not defined" `
    -Description "Sprint review process is not documented" `
    -Impact "Demo preparation, stakeholder engagement"
}

# ── Q3: Demo preparation ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 6 — Demo Preparation Checklist" -ForegroundColor Cyan
Write-PO-Dim "  What needs to be prepared before each demo or review?"
Write-PO-Dim "  Example: 'Test environment ready', 'Demo script written', 'Backup plan ready'"
Write-Host ""
$DemoChecklist = Ask-PO-Text "Your answer (comma-separated, or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($DemoChecklist)) {
  $DemoChecklist = "Demo environment tested, Demo script prepared, Backup scenarios ready"
}

# ── Q4: Feedback collection ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 6 — Feedback Collection Method" -ForegroundColor Cyan
Write-PO-Dim "  How do you gather feedback from stakeholders?"
Write-PO-Dim "  Example: 'During review', 'Post-demo survey', 'Weekly sync call'"
Write-Host ""
$FeedbackMethod = Ask-PO-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($FeedbackMethod)) { $FeedbackMethod = "During sprint reviews" }

# ── Q5: Escalation triggers ───────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 6 — Escalation Triggers" -ForegroundColor Cyan
Write-PO-Dim "  When should issues be escalated to stakeholders?"
Write-PO-Dim "  Example: 'Milestone missed', 'Major blocker', 'Scope change > 20%'"
Write-Host ""
$Escalation = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Escalation)) { $Escalation = "Not yet defined" }

# ── Q6: Additional communication practices ────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 6 — Other Communication Practices" -ForegroundColor Cyan
Write-PO-Dim "  Any other communication channels or practices? (dashboards, newsletters, etc.)"
Write-Host ""
$Other = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Other)) { $Other = "None defined" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-PO-SuccessRule "✅ Stakeholder Communication Summary"
Write-Host "  Groups:           $groupCount groups"
Write-Host "  Sprint Review:    $($SprintFormat.Substring(0, [Math]::Min(40, $SprintFormat.Length)))..."
Write-Host "  Feedback Method:  $FeedbackMethod"
Write-Host ""

if (-not (Confirm-PO-Save "Does this look correct? (y=save / n=redo)")) {
  Write-PO-Dim "  Restarting phase 4..."
  & $PSCommandPath
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$output = @"
# Stakeholder Communication Plan

> Captured: $DateNow

## Stakeholder Groups

"@

if ($groupCount -gt 0) {
  $output += "| Group | Frequency | Format | Communication Needs |`n"
  $output += "|-------|-----------|--------|---------------------|`n"
  for ($i = 0; $i -lt $groupCount; $i++) {
    $needsShort = $GroupNeeds[$i].Substring(0, [Math]::Min(30, $GroupNeeds[$i].Length))
    $output += "| $($Groups[$i]) | $($GroupFreq[$i]) | $($GroupFormat[$i]) | $needsShort... |`n"
  }
  $output += "`n### Detailed Communication Plans`n`n"
  for ($i = 0; $i -lt $groupCount; $i++) {
    $output += @"
#### $($Groups[$i])

**Frequency:** $($GroupFreq[$i])

**Format:** $($GroupFormat[$i])

**Needs:** $($GroupNeeds[$i])

"@
  }
} else {
  $output += "(No stakeholder groups defined)`n`n"
}

$output += @"
## Sprint Review Format

$SprintFormat

## Demo Preparation Checklist

"@

$checkItems = $DemoChecklist -split ', '
foreach ($item in $checkItems) {
  $output += "- $item`n"
}

$output += @"

## Feedback Collection

$FeedbackMethod

## Escalation Triggers

$Escalation

## Other Communication Practices

$Other

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-PO-SuccessRule "✅ Stakeholder Communication Plan saved"
Write-Host "  Output: $OutputFile" -ForegroundColor Green
Write-Host ""

# ── Log new debts ─────────────────────────────────────────────────────────────
$endDebts = Get-PO-DebtCount
if ($endDebts -gt $startDebts) {
  $newDebts = $endDebts - $startDebts
  Write-PO-Dim "  Logged $newDebts debt(s) — see po-output/06-po-debts.md"
}
Write-Host ""
