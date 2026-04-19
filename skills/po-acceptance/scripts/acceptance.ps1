# =============================================================================
# acceptance.ps1 — Phase 2: Acceptance Criteria & Definition of Done (PowerShell)
# Output: $POOutputDir\02-acceptance-criteria.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PO_AUTO = '1' }
if ($Answers) { $env:PO_ANSWERS = $Answers }


$OutputFile = Join-Path $script:POOutputDir "02-acceptance-criteria.md"
$Area       = "Acceptance Criteria"
$BacklogFile = Join-Path $script:POOutputDir "01-product-backlog.md"

$startDebts = Get-PO-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-PO-Banner "📋  Phase 2 — Acceptance Criteria & Definition of Done"
Write-PO-Dim "  Let's define what 'done' means for each story."
Write-PO-Dim "  We'll use BDD (Given/When/Then) scenarios."
Write-Host ""

# Check if backlog exists
if (-not (Test-Path $BacklogFile)) {
  Write-PO-Dim "  Note: No backlog file found at $BacklogFile"
  Write-PO-Dim "  I'll ask you which stories to define acceptance for."
  Write-Host ""
}

# ── Q1: Story selection ───────────────────────────────────────────────────────
Write-Host "Question 1 / 6 — Story Selection" -ForegroundColor Cyan
Write-PO-Dim "  Which story would you like to define acceptance criteria for?"
Write-Host ""
$Story = Ask-PO-Text "Story title or ID:"
if ([string]::IsNullOrWhiteSpace($Story)) {
  $Story = "Unnamed Story"
  Add-PO-Debt -Area $Area -Title "Story not identified" `
    -Description "No story was selected for acceptance criteria" `
    -Impact "Development team cannot start work"
}

# ── Q2: BDD scenarios ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 6 — BDD Scenarios (Given/When/Then)" -ForegroundColor Cyan
Write-PO-Dim "  Let's define acceptance scenarios using Given/When/Then format."
Write-PO-Dim "  Example:"
Write-PO-Dim "    Given: user is logged in"
Write-PO-Dim "    When: user clicks 'Save'"
Write-PO-Dim "    Then: data is saved and confirmation shown"
Write-Host ""

$ScenariosGiven = @()
$ScenariosWhen  = @()
$ScenariosThen  = @()

$scenarioCount = 0

while ($true) {
  $scenarioNum = $scenarioCount + 1
  $response = Read-Host "▶ Add BDD scenario #$scenarioNum`? (y/n)"
  if ($response -notin "y", "yes") {
    break
  }

  $Given = Ask-PO-Text "Given (precondition):"
  if ([string]::IsNullOrWhiteSpace($Given)) { $Given = "(precondition not specified)" }
  $ScenariosGiven += $Given

  $When = Ask-PO-Text "When (action):"
  if ([string]::IsNullOrWhiteSpace($When)) { $When = "(action not specified)" }
  $ScenariosWhen += $When

  $Then = Ask-PO-Text "Then (expected result):"
  if ([string]::IsNullOrWhiteSpace($Then)) { $Then = "(result not specified)" }
  $ScenariosThen += $Then

  $scenarioCount++
}

if ($scenarioCount -eq 0) {
  Add-PO-Debt -Area $Area -Title "No BDD scenarios defined" `
    -Description "Story has no acceptance scenarios" `
    -Impact "Dev team lacks clear acceptance criteria"
}

# ── Q3: Edge cases ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 6 — Edge Cases & Error Handling" -ForegroundColor Cyan
Write-PO-Dim "  What edge cases or error conditions should be handled?"
Write-Host ""
$EdgeCases = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($EdgeCases)) { $EdgeCases = "Not specified" }

# ── Q4: Non-functional acceptance criteria ────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 6 — Non-Functional Acceptance Criteria" -ForegroundColor Cyan
Write-PO-Dim "  Performance, security, accessibility, etc. Example:"
Write-PO-Dim "    - Response time < 200ms"
Write-PO-Dim "    - Must be mobile-friendly"
Write-PO-Dim "    - Accessibility: WCAG AA compliant"
Write-Host ""
$NFR = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($NFR)) { $NFR = "Not specified" }

# ── Q5: Global DoD checklist ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 6 — Global Definition of Done" -ForegroundColor Cyan
Write-PO-Dim "  Items that apply to ALL stories (code review, tests, docs, etc)."
Write-Host ""
$GlobalDoD = Ask-PO-Text "Your answer (comma-separated, or press Enter to use defaults):"
if ([string]::IsNullOrWhiteSpace($GlobalDoD)) {
  $GlobalDoD = "Code reviewed, Unit tests passed, Documentation updated, No critical warnings"
}

# ── Q6: Story-specific DoD ────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 6 — Story-Specific Definition of Done" -ForegroundColor Cyan
Write-PO-Dim "  Additional DoD items specific to this story."
Write-Host ""
$StoryDoD = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($StoryDoD)) { $StoryDoD = "None additional" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-PO-SuccessRule "✅ Acceptance Criteria Summary"
Write-Host "  Story:              $Story"
Write-Host "  Scenarios:          $scenarioCount scenarios"
Write-Host "  Edge Cases:         $($EdgeCases.Substring(0, [Math]::Min(40, $EdgeCases.Length)))..."
Write-Host "  Non-Functional:     $($NFR.Substring(0, [Math]::Min(40, $NFR.Length)))..."
Write-Host ""

if (-not (Confirm-PO-Save "Does this look correct? (y=save / n=redo)")) {
  Write-PO-Dim "  Restarting phase 2..."
  & $PSCommandPath
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$output = @"
# Acceptance Criteria & Definition of Done

> Captured: $DateNow

## Story: $Story

### BDD Scenarios

"@

if ($scenarioCount -gt 0) {
  for ($i = 0; $i -lt $scenarioCount; $i++) {
    $output += @"
#### Scenario $($i+1)

**Given:** $($ScenariosGiven[$i])

**When:** $($ScenariosWhen[$i])

**Then:** $($ScenariosThen[$i])

"@
  }
} else {
  $output += "(No scenarios defined)`n`n"
}

$output += @"
### Edge Cases & Error Handling

$EdgeCases

### Non-Functional Acceptance Criteria

$NFR

### Definition of Done

#### Global DoD (applies to all stories)

"@

$dodItems = $GlobalDoD -split ', '
foreach ($item in $dodItems) {
  $output += "- $item`n"
}

$output += @"

#### Story-Specific DoD

"@

if ($StoryDoD -ne "None additional") {
  $storyDodItems = $StoryDoD -split ', '
  foreach ($item in $storyDodItems) {
    $output += "- $item`n"
  }
} else {
  $output += "(None additional)`n"
}

$output += "`n"

Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-PO-SuccessRule "✅ Acceptance Criteria saved"
Write-Host "  Output: $OutputFile" -ForegroundColor Green
Write-Host ""

# ── Log new debts ─────────────────────────────────────────────────────────────
$endDebts = Get-PO-DebtCount
if ($endDebts -gt $startDebts) {
  $newDebts = $endDebts - $startDebts
  Write-PO-Dim "  Logged $newDebts debt(s) — see po-output/06-po-debts.md"
}
Write-Host ""
