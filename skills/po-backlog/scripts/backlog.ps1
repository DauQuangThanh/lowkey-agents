# =============================================================================
# backlog.ps1 — Phase 1: Product Backlog Management (PowerShell)
# Output: $POOutputDir\01-product-backlog.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PO_AUTO = '1' }
if ($Answers) { $env:PO_ANSWERS = $Answers }


$OutputFile = Join-Path $script:POOutputDir "01-product-backlog.md"
$Area       = "Product Backlog"

$startDebts = Get-PO-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-PO-Banner "📋  Phase 1 — Product Backlog Management"
Write-PO-Dim "  Let's define what we're building and prioritize the work."
Write-PO-Dim "  You can add as many backlog items as needed."
Write-Host ""

# ── Q1: Product vision ────────────────────────────────────────────────────────
Write-Host "Question 1 / 8 — Product Vision" -ForegroundColor Cyan
Write-PO-Dim "  In one or two sentences, what is the vision for this product?"
Write-PO-Dim "  Example: 'A mobile app that helps teams collaborate on projects in real-time.'"
Write-Host ""
$Vision = Ask-PO-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Vision)) {
  $Vision = "TBD"
  Add-PO-Debt -Area $Area -Title "Product vision not defined" `
    -Description "Product vision statement is missing" `
    -Impact "Backlog prioritization, release planning, and stakeholder alignment"
}

# ── Q2: Backlog items ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 8 — Backlog Items" -ForegroundColor Cyan
Write-PO-Dim "  Let's add backlog items. You can add as many as you'd like."
Write-PO-Dim "  For each, I'll ask: title, description, type, priority, value, and estimate."
Write-Host ""

$ItemsTitle    = @()
$ItemsDesc     = @()
$ItemsType     = @()
$ItemsPriority = @()
$ItemsValue    = @()
$ItemsEst      = @()

$itemCount = 0

while ($true) {
  $itemNum = $itemCount + 1
  Write-Host ""
  $response = Read-Host "▶ Add backlog item #$itemNum`? (y/n)"
  if ($response -notin "y", "yes") {
    break
  }

  $Title = Ask-PO-Text "Title (e.g. 'User login feature'):"
  if ([string]::IsNullOrWhiteSpace($Title)) { $Title = "Untitled Item" }
  $ItemsTitle += $Title

  $Desc = Ask-PO-Text "Description:"
  if ([string]::IsNullOrWhiteSpace($Desc)) { $Desc = "No description" }
  $ItemsDesc += $Desc

  $Type = Ask-PO-Choice "Type:" @(
    "Epic — Large feature or initiative",
    "Story — User-facing feature",
    "Bug — Defect or issue",
    "Tech-Debt — Internal improvement"
  )
  $ItemsType += $Type

  $Priority = Ask-PO-Choice "Priority (MoSCoW):" @(
    "Must Have — Critical, non-negotiable",
    "Should Have — Important, but flexible",
    "Could Have — Nice-to-have",
    "Won't Have — Explicitly excluded"
  )
  $ItemsPriority += $Priority

  $Value = Ask-PO-Choice "Business Value:" @(
    "High — Directly solves core problem",
    "Medium — Supports core capability",
    "Low — Nice feature, supporting role"
  )
  $ItemsValue += $Value

  $Est = Ask-PO-Choice "Estimation (T-shirt):" @(
    "S — Small (1-3 days)",
    "M — Medium (1-2 weeks)",
    "L — Large (3+ weeks)",
    "XL — Extra Large (1+ month)"
  )
  $ItemsEst += $Est

  $itemCount++
}

if ($itemCount -eq 0) {
  Add-PO-Debt -Area $Area -Title "No backlog items defined" `
    -Description "Backlog has no items" `
    -Impact "Sprint planning, roadmap definition, and MVP scope"
}

# ── Q3: Dependencies ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 8 — Dependencies" -ForegroundColor Cyan
Write-PO-Dim "  Are there any dependencies between items?"
Write-PO-Dim "  Example: 'User auth must be done before user profile.'"
Write-Host ""
$Dependencies = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Dependencies)) { $Dependencies = "None identified" }

# ── Q4: MVP definition ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 8 — MVP Definition" -ForegroundColor Cyan
Write-PO-Dim "  Which backlog items are in the Minimum Viable Product (MVP)?"
Write-Host ""
$MVP = Ask-PO-Text "Your answer (comma-separated item titles, or press Enter if unclear):"
if ([string]::IsNullOrWhiteSpace($MVP)) {
  $MVP = "To be determined"
  Add-PO-Debt -Area $Area -Title "MVP not clearly defined" `
    -Description "Which items are in the MVP is unclear" `
    -Impact "Release planning, scope management, and stakeholder expectations"
}

# ── Q5: Total effort ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 8 — Total Estimated Effort" -ForegroundColor Cyan
$TotalEffort = Ask-PO-Text "Estimate total effort for all backlog items (e.g. '10 sprints', '6 months'):"
if ([string]::IsNullOrWhiteSpace($TotalEffort)) { $TotalEffort = "To be calculated" }

# ── Q6: Release priorities ────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 8 — Release Priorities" -ForegroundColor Cyan
Write-PO-Dim "  How should backlog items be released? What are the themes?"
Write-Host ""
$ReleaseStrategy = Ask-PO-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($ReleaseStrategy)) { $ReleaseStrategy = "Not yet planned" }

# ── Q7: Backlog refinement ────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 7 / 8 — Backlog Refinement Cadence" -ForegroundColor Cyan
$Refinement = Ask-PO-Choice "How often should the backlog be refined?" @(
  "Weekly — Continuous refinement",
  "Bi-weekly — During sprint planning",
  "Monthly — Structured grooming",
  "Not yet decided"
)

# ── Q8: MVP acceptance criteria ───────────────────────────────────────────────
Write-Host ""
Write-Host "Question 8 / 8 — MVP Acceptance Criteria" -ForegroundColor Cyan
Write-PO-Dim "  What criteria must be met for the MVP to be accepted?"
Write-Host ""
$MVPCriteria = Ask-PO-Text "Your answer (or press Enter to defer to Phase 2):"
if ([string]::IsNullOrWhiteSpace($MVPCriteria)) { $MVPCriteria = "To be defined in acceptance criteria phase" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-PO-SuccessRule "✅ Backlog Summary"
Write-Host "  Vision:         $Vision"
Write-Host "  Items:          $itemCount items"
Write-Host "  MVP:            $MVP"
Write-Host "  Total Effort:   $TotalEffort"
Write-Host "  Refinement:     $Refinement"
Write-Host ""

if (-not (Confirm-PO-Save "Does this look correct? (y=save / n=redo)")) {
  Write-PO-Dim "  Restarting phase 1..."
  & $PSCommandPath
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$output = @"
# Product Backlog

> Captured: $DateNow

## Product Vision

$Vision

## Backlog Items

"@

if ($itemCount -gt 0) {
  $output += @"
| # | Title | Type | Priority | Value | Estimation |
|---|-------|------|----------|-------|------------|
"@
  for ($i = 0; $i -lt $itemCount; $i++) {
    $output += "| $($i+1) | $($ItemsTitle[$i]) | $($ItemsType[$i]) | $($ItemsPriority[$i]) | $($ItemsValue[$i]) | $($ItemsEst[$i]) |`n"
  }
  $output += @"

## Detailed Item Descriptions

"@
  for ($i = 0; $i -lt $itemCount; $i++) {
    $output += @"
### $($i+1). $($ItemsTitle[$i])

**Type:** $($ItemsType[$i])

**Priority:** $($ItemsPriority[$i])

**Business Value:** $($ItemsValue[$i])

**Estimation:** $($ItemsEst[$i])

**Description:** $($ItemsDesc[$i])

"@
  }
} else {
  $output += "(No backlog items added)`n`n"
}

$output += @"
## MVP Definition

$MVP

## Dependencies

$Dependencies

## Total Estimated Effort

$TotalEffort

## Release Strategy

$ReleaseStrategy

## Backlog Refinement Cadence

$Refinement

## MVP Acceptance Criteria

$MVPCriteria

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-PO-SuccessRule "✅ Product Backlog saved"
Write-Host "  Output: $OutputFile" -ForegroundColor Green
Write-Host ""

# ── Log new debts ─────────────────────────────────────────────────────────────
$endDebts = Get-PO-DebtCount
if ($endDebts -gt $startDebts) {
  $newDebts = $endDebts - $startDebts
  Write-PO-Dim "  Logged $newDebts debt(s) — see po-output/06-po-debts.md"
}
Write-Host ""
