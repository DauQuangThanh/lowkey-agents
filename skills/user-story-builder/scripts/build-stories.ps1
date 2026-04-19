# =============================================================================
# build-stories.ps1 — Phase 4: User Story Builder (PowerShell)
# Output: $BAOutputDir\04-user-stories.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$OutputFile = Join-Path $script:BAOutputDir "04-user-stories.md"
$Area       = "User Stories"

$startDebts = Get-BA-DebtCount

$script:StoryCount = 0
$script:Stories    = @()

function Build-Story {
  $script:StoryCount++
  $storyId = "US-{0:D3}" -f $script:StoryCount

  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host ("  Story {0}" -f $storyId) -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host ""
  Write-BA-Dim "  A user story follows this pattern:"
  Write-BA-Dim "  `"As a [WHO], I want to [WHAT], so that [WHY].`""
  Write-Host ""

  # WHO
  Write-Host "  Part 1 — WHO is performing this action?" -ForegroundColor Cyan
  Write-BA-Dim "  Example: 'registered user', 'admin', 'warehouse manager'"
  $role = Ask-BA-Text "  As a..."
  if ([string]::IsNullOrWhiteSpace($role)) {
    $role = "user"
    Add-BA-Debt -Area $Area -Title "User role missing in story $storyId" `
      -Description "The user type for story $storyId was not specified" `
      -Impact "Story cannot be properly prioritised without knowing the user"
  }

  # WHAT
  Write-Host ""
  Write-Host "  Part 2 — WHAT do they want to do?" -ForegroundColor Cyan
  Write-BA-Dim "  Example: 'view all my pending orders', 'reset my password'"
  $action = Ask-BA-Text "  I want to..."
  if ([string]::IsNullOrWhiteSpace($action)) {
    $action = "[action not specified]"
    Add-BA-Debt -Area $Area -Title "Action missing in story $storyId" `
      -Description "The action/feature for story $storyId was not specified" `
      -Impact "Story cannot be developed without knowing what to build"
  }

  # WHY
  Write-Host ""
  Write-Host "  Part 3 — WHY do they want it?" -ForegroundColor Cyan
  Write-BA-Dim "  Example: 'so I can track delivery status', 'so I can regain access'"
  $benefit = Ask-BA-Text "  So that..."
  if ([string]::IsNullOrWhiteSpace($benefit)) {
    $benefit = "[benefit not specified]"
    Add-BA-Debt -Area $Area -Title "Benefit missing in story $storyId" `
      -Description "The business value for story $storyId was not specified" `
      -Impact "Without knowing the 'why', acceptance criteria are hard to define"
  }

  # PRIORITY
  Write-Host ""
  Write-Host "  Part 4 — Priority (MoSCoW method)" -ForegroundColor Cyan
  Write-BA-Dim "  Must = core, Should = important, Could = nice to have, Won't = out of scope"
  Write-Host ""
  $priority = Ask-BA-Choice "  Priority level:" @(
    "Must Have — Cannot launch without this",
    "Should Have — Important but not blocking launch",
    "Could Have — Nice to have if time allows",
    "Won't Have (this release) — Out of scope for now"
  )

  # COMPLEXITY
  Write-Host ""
  Write-Host "  Part 5 — Complexity estimate" -ForegroundColor Cyan
  Write-Host ""
  $complexity = Ask-BA-Choice "  How complex does this feel?" @(
    "Small — A few hours of work",
    "Medium — A few days of work",
    "Large — A week or more of work",
    "Unknown — I'm not sure"
  )

  # ACCEPTANCE CRITERIA
  Write-Host ""
  Write-Host "  Part 6 — Acceptance Criteria" -ForegroundColor Cyan
  Write-BA-Dim "  These are the conditions that must be true for this story to be 'done'."
  Write-Host ""

  $criteria = @()
  $acCount  = 0
  Write-BA-Dim "  Add at least 2 acceptance criteria (press Enter with no text to stop):"
  while ($true) {
    $acCount++
    Write-Host ("  Criterion {0} (or press Enter to finish):" -f $acCount) -ForegroundColor Yellow
    $criterion = Read-Host
    if ([string]::IsNullOrWhiteSpace($criterion)) { break }
    $criteria += "- [ ] $criterion"
  }

  if ($criteria.Count -eq 0) {
    $criteria += "- [ ] [Acceptance criteria not yet defined]"
    Add-BA-Debt -Area $Area -Title "No acceptance criteria for $storyId" `
      -Description "Story '$storyId' has no acceptance criteria" `
      -Impact "Cannot determine when this story is done; blocks testing and sign-off"
  }

  # NOTES
  Write-Host ""
  Write-BA-Dim "  Any assumptions, dependencies, or notes? (Press Enter to skip)"
  $notes = Ask-BA-Text "  Notes:"
  if ([string]::IsNullOrWhiteSpace($notes)) { $notes = "None" }

  $storyBlock = @"
## ${storyId}: $action
**As a** $role,
**I want to** $action,
**so that** $benefit.

### Acceptance Criteria
$($criteria -join "`n")

**Priority:** $priority
**Complexity:** $complexity
**Notes:** $notes

"@

  $script:Stories += [PSCustomObject]@{
    Id = $storyId; Role = $role; Action = $action; Benefit = $benefit;
    Priority = $priority; Complexity = $complexity; Block = $storyBlock
  }

  Write-Host ""
  Write-Host "  ✅ Story $storyId saved!" -ForegroundColor Green
  Write-Host "     `"As a $role, I want to $action`"" -ForegroundColor Green
}

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "📖  Step 4 of 7 — User Story Builder"
Write-BA-Dim "  A user story describes a feature from the perspective of the person using it."
Write-BA-Dim "  We'll build them one at a time. You can add as many as you like."
Write-Host ""

if (Test-Path (Join-Path $script:BAOutputDir "03-requirements.md")) {
  Write-BA-Dim "  Tip: I found your requirements from Step 3. You can use them as a guide."
  Write-Host ""
}

# ── Story loop ────────────────────────────────────────────────────────────────
Build-Story
while ($true) {
  Write-Host ""
  if ((Ask-BA-YN "Would you like to add another user story?") -eq "no") { break }
  Build-Story
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-BA-SuccessRule ("✅ User Story Summary ({0} stories created)" -f $script:StoryCount)

if (-not (Confirm-BA-Save "Save all stories? (y=save / n=redo)")) {
  & $PSCommandPath
  return
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$lines  = @()
$lines += "# User Stories"
$lines += ""
$lines += "> Captured: $DateNow | Total: $($script:StoryCount) stories"
$lines += ""
$lines += "## Quick Reference"
$lines += ""
$lines += "| ID | As a... | I want to... | Priority | Complexity |"
$lines += "|---|---|---|---|---|"
foreach ($s in $script:Stories) {
  $lines += ("| {0} | {1} | {2} | {3} | {4} |" -f $s.Id, $s.Role, $s.Action, $s.Priority, $s.Complexity)
}
$lines += ""
$lines += "---"
$lines += ""
foreach ($s in $script:Stories) {
  $lines += $s.Block
  $lines += ""
  $lines += "---"
  $lines += ""
}
$lines | Set-Content -Path $OutputFile -Encoding UTF8

$endDebts = Get-BA-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newDebts -gt 0) { Write-Host "  ⚠  $newDebts debt(s) logged." -ForegroundColor Yellow }
Write-Host ""
