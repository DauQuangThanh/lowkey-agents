#Requires -Version 5.1
# =============================================================================
# validate.ps1 — Phase 4: UX Review & Validation (PowerShell)
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\..\ux-research\scripts\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:UX_AUTO = '1' }
if ($Answers) { $env:UX_ANSWERS = $Answers }


$OutputFile = Join-Path $script:UXOutputDir "04-ux-validation.md"
$FinalFile = Join-Path $script:UXOutputDir "UX-DESIGNER-FINAL.md"
$Area = "UX Validation"

$startDebts = Get-UX-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-UX-Banner "✅  Phase 4 — UX Review & Validation"
Write-UX-Dim "  Let's validate the design is complete, heuristic-sound, and ready for handoff."
Write-Host ""

# ── Check all previous phases ────────────────────────────────────────────────
$ResearchFile = Join-Path $script:UXOutputDir "01-user-research.md"
$WireframeFile = Join-Path $script:UXOutputDir "02-wireframes.md"
$PrototypeFile = Join-Path $script:UXOutputDir "03-prototype-spec.md"

Write-Host "$($script:UX_CYAN)  Phase completeness check:$($script:UX_NC)"
if (Test-Path $ResearchFile) { Write-Host "    ✔ Phase 1 (Research): $(Split-Path -Leaf $ResearchFile)" } else { Write-Host "    ✗ Phase 1 (Research): MISSING" }
if (Test-Path $WireframeFile) { Write-Host "    ✔ Phase 2 (Wireframes): $(Split-Path -Leaf $WireframeFile)" } else { Write-Host "    ✗ Phase 2 (Wireframes): MISSING" }
if (Test-Path $PrototypeFile) { Write-Host "    ✔ Phase 3 (Mockups): $(Split-Path -Leaf $PrototypeFile)" } else { Write-Host "    ✗ Phase 3 (Mockups): MISSING" }
Write-Host ""

# ── Nielsen's 10 Heuristics Checklist ────────────────────────────────────────
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Nielsen's 10 Usability Heuristics Review$($script:UX_NC)"
Write-Host ""

$Heuristics = @(
  "System visibility and status — Are users informed of what is happening?",
  "Match system and real world — Does language match user mental models?",
  "User control and freedom — Can users undo, back out, cancel?",
  "Error prevention and recovery — Errors prevented? Messages clear?",
  "Help and documentation — Is there guidance for non-obvious tasks?",
  "Flexibility and shortcuts — Can power users skip steps?",
  "Aesthetic and minimalist design — Is interface focused, not cluttered?",
  "Error messages — Are they clear, non-technical, constructive?",
  "Help and support — Can users find answers without leaving the app?",
  "Accessibility — Is design inclusive (color, motor, cognitive)?"
)

$HeuristicScores = @()
for ($i = 0; $i -lt $Heuristics.Count; $i++) {
  $h = $i + 1
  $prompt = $Heuristics[$i]

  $Status = Ask-UX-Choice "  $h. $prompt" @(
    "✅ Pass",
    "⚠️  Minor gap",
    "🔴 Major gap",
    "N/A for this product"
  )

  $HeuristicScores += "| $h | $prompt | $Status |"
}

# ── Requirement coverage ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Requirement Coverage$($script:UX_NC)"
Write-Host ""

$BAFinal = Join-Path $script:UXBAInputDir "REQUIREMENTS-FINAL.md"
if (Test-Path $BAFinal) {
  $StoryCoverage = Ask-UX-YN "Do all user stories map to at least one wireframe screen?"
  $ScenarioCoverage = Ask-UX-YN "Are all user scenarios covered by the user journeys?"
} else {
  $StoryCoverage = "N/A — no BA requirements"
  $ScenarioCoverage = "N/A — no BA requirements"
}

# ── Accessibility & Responsiveness ────────────────────────────────────────────
Write-Host ""
$Accessibility = Ask-UX-YN "Do wireframes address all accessibility needs from Phase 1?"
$Responsive = Ask-UX-YN "Are responsive design breakpoints explicitly defined?"
$Interactions = Ask-UX-YN "Are all interaction patterns specified (forms, validation, errors)?"

# ── Open Debts ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Open UX Debts$($script:UX_NC)"
Write-Host ""

$TotalDebts = Get-UX-DebtCount
$BlockingDebts = 0
if ($TotalDebts -gt 0 -and (Test-Path $script:UXDebtFile)) {
  $BlockingDebts = (Select-String -Path $script:UXDebtFile -Pattern '🔴 Blocking' -ErrorAction SilentlyContinue | Measure-Object).Count
}

Write-Host "  Total UX Debts: $TotalDebts"
Write-Host "  Blocking (🔴): $BlockingDebts"
Write-Host ""

# ── Stakeholder sign-off ──────────────────────────────────────────────────────
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Stakeholder Sign-Off$($script:UX_NC)"
Write-Host ""

$StakeholderReview = Ask-UX-YN "Have all key stakeholders reviewed and approved the designs?"
$DesignFinal = Ask-UX-YN "Are there any open design questions blocking handoff to engineering?"
$HandoffReady = Ask-UX-YN "Is this design package ready for developer handoff?"

# ── Determine overall status ──────────────────────────────────────────────────
Write-Host ""
Write-UX-SuccessRule "✅ Validation Summary"

if ($BlockingDebts -gt 0) {
  $OverallStatus = "❌ NOT READY"
  Write-Host "$($script:UX_RED)  $OverallStatus — Resolve $BlockingDebts blocking debt(s) before handoff$($script:UX_NC)"
} elseif ($StakeholderReview -eq "no" -or $HandoffReady -eq "no") {
  $OverallStatus = "⚠️  CONDITIONALLY APPROVED"
  Write-Host "$($script:UX_YELLOW)  $OverallStatus — Address stakeholder feedback; some gaps tracked as debts$($script:UX_NC)"
} else {
  $OverallStatus = "✅ APPROVED"
  Write-Host "$($script:UX_GREEN)  $OverallStatus — Design is complete and ready for engineering handoff$($script:UX_NC)"
}
Write-Host ""

# ── Write validation output ───────────────────────────────────────────────────
$DateNow = (Get-Date).ToString("yyyy-MM-dd")
$ValidationContent = @"
# UX Review & Validation

> Date: $DateNow
> Status: $OverallStatus

## Nielsen's 10 Usability Heuristics

| # | Heuristic | Assessment |
|---|---|---|
$($HeuristicScores -join @"
`n
"@)

## Requirement Coverage

- **User stories mapped to wireframes:** $StoryCoverage
- **Scenarios covered in journeys:** $ScenarioCoverage

## Accessibility & Responsiveness

- **Accessibility needs addressed:** $Accessibility
- **Responsive breakpoints defined:** $Responsive
- **All interactions specified:** $Interactions

## Open UX Debts

- **Total:** $TotalDebts
- **Blocking (🔴):** $BlockingDebts

## Stakeholder Sign-Off

- **Stakeholders reviewed:** $StakeholderReview
- **Design finalized:** $DesignFinal
- **Ready for handoff:** $HandoffReady

## Recommendation

**Overall Status:** $OverallStatus

$(if ($BlockingDebts -gt 0) { "**Next steps:** Resolve all 🔴 Blocking debts in \`05-ux-debts.md\` before proceeding." } elseif ($StakeholderReview -eq "no") { "**Next steps:** Gather stakeholder feedback and incorporate into design before engineering handoff." } else { "**Next steps:** Hand off to engineering. Design is complete and approved." })

"@

Set-Content -Path $OutputFile -Value $ValidationContent -Encoding UTF8

# ── Compile final deliverable ────────────────────────────────────────────────
$FinalContent = @"
# UX Design Package — Final Deliverable

> Compiled: $DateNow
> Status: $OverallStatus

---

"@

if (Test-Path $ResearchFile) {
  $FinalContent += (Get-Content -Path $ResearchFile -Raw) + @"

---

"@
} else {
  $FinalContent += @"
*Phase 1 (User Research): Not completed*

---

"@
}

if (Test-Path $WireframeFile) {
  $FinalContent += (Get-Content -Path $WireframeFile -Raw) + @"

---

"@
} else {
  $FinalContent += @"
*Phase 2 (Wireframes): Not completed*

---

"@
}

if (Test-Path $PrototypeFile) {
  $FinalContent += (Get-Content -Path $PrototypeFile -Raw) + @"

---

"@
} else {
  $FinalContent += @"
*Phase 3 (Mockups): Not completed*

---

"@
}

$FinalContent += $ValidationContent + @"

---

## All UX Debts

"@

if (Test-Path $script:UXDebtFile) {
  $FinalContent += (Get-Content -Path $script:UXDebtFile -Raw)
} else {
  $FinalContent += "No open UX debts."
}

Set-Content -Path $FinalFile -Value $FinalContent -Encoding UTF8

Write-Host "$($script:UX_GREEN)  Saved validation to: $OutputFile$($script:UX_NC)"
Write-Host "$($script:UX_GREEN)  Compiled final package to: $FinalFile$($script:UX_NC)"
Write-Host ""

$endDebts = Get-UX-DebtCount
$newDebts = $endDebts - $startDebts
if ($newDebts -gt 0) {
  Write-Host "$($script:UX_YELLOW)  ⚠  $newDebts UX debt(s) logged to: $script:UXDebtFile$($script:UX_NC)"
}
Write-Host ""
