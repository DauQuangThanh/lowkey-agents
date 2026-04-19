#Requires -Version 5.1
# =============================================================================
# research.ps1 — Phase 1: User Research & Personas (PowerShell)
# Captures the user insights that guide all downstream UX decisions.
# Output: $UXOutputDir/01-user-research.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:UX_AUTO = '1' }
if ($Answers) { $env:UX_ANSWERS = $Answers }


$OutputFile = Join-Path $script:UXOutputDir "01-user-research.md"
$Area = "User Research"

$startDebts = Get-UX-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-UX-Banner "🎯  Phase 1 — User Research & Personas"
Write-UX-Dim "  Let's understand your users: who they are, what they want, and how they interact."
Write-UX-Dim "  Most answers are short narratives. Skip with Enter if you'll gather this later."
Write-Host ""

# ── Handover from BA ─────────────────────────────────────────────────────────
$BAFinal = Join-Path $script:UXBAInputDir "REQUIREMENTS-FINAL.md"
if (Test-Path $BAFinal) {
  Write-Host "$($script:UX_GREEN)  ✔ Found BA output: $BAFinal$($script:UX_NC)"
  Write-UX-Dim "  I'll read user stories and stakeholder data from there. Continuing..."
} else {
  Write-Host "$($script:UX_YELLOW)  ⚠ No BA output found at: $BAFinal$($script:UX_NC)"
  Write-UX-Dim "  For best results, run the business-analyst first. Continuing anyway..."
  Add-UX-Debt $Area "No BA requirements input found" `
    "ba-output/REQUIREMENTS-FINAL.md was not present at research time" `
    "Personas may lack grounding in actual user stories and stakeholder feedback"
}
Write-Host ""

# ── Q1: Primary user personas ────────────────────────────────────────────────
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 1 / 5 — Primary user personas$($script:UX_NC)"
Write-UX-Dim "  Name the 2–4 primary user types. For each, I'll ask about their role, goals, pain points."
Write-Host ""

$Personas = @()
for ($i = 1; $i -le 2; $i++) {
  $PersonaName = Ask-UX-Text "Persona $i name? (e.g. 'Alice the Customer', 'Bob the Admin') — or Enter to skip:"
  if (-not $PersonaName) { break }

  $PersonaRole = Ask-UX-Text "  Role/title for $PersonaName? (e.g. 'E-commerce customer', 'Product owner'):"
  if (-not $PersonaRole) { $PersonaRole = "Unknown" }

  $PersonaGoals = Ask-UX-Text "  Top 3 goals? (e.g. 'Find product, add to cart, checkout' — one per line or comma-separated):"
  if (-not $PersonaGoals) { $PersonaGoals = "TBD" }

  $PersonaPains = Ask-UX-Text "  Pain points? (e.g. 'Slow search, confusing checkout, no guest option'):"
  if (-not $PersonaPains) { $PersonaPains = "TBD" }

  $PersonaTech = Ask-UX-Choice "  Tech comfort level?" @(
    "Beginner — barely uses software",
    "Intermediate — can use email, web apps",
    "Advanced — comfortable with most tech",
    "Expert — power user, knows keyboard shortcuts"
  )

  $PersonaDevice = Ask-UX-Choice "  Device preference?" @(
    "Desktop only",
    "Mobile first (mostly phone)",
    "Equal mobile and desktop",
    "Multiple devices depending on context"
  )

  $Personas += @{
    Name = $PersonaName
    Role = $PersonaRole
    Goals = $PersonaGoals
    Pains = $PersonaPains
    Tech = $PersonaTech
    Device = $PersonaDevice
  }
}

if ($Personas.Count -eq 0) {
  $PersonasText = "No personas captured this session."
  Add-UX-Debt $Area "User personas not defined" `
    "No primary user types were captured" `
    "Wireframes and design decisions lack user grounding"
} else {
  $PersonasText = ""
  for ($i = 0; $i -lt $Personas.Count; $i++) {
    $p = $Personas[$i]
    $PersonasText += @"

### Persona $($i + 1): $($p.Name)
- **Role:** $($p.Role)
- **Goals:** $($p.Goals)
- **Pain Points:** $($p.Pains)
- **Tech Comfort:** $($p.Tech)
- **Device Preference:** $($p.Device)
"@
  }
}

# ── Q2: User scenarios ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 2 / 5 — User scenarios$($script:UX_NC)"
Write-UX-Dim "  Describe 2–3 key user scenarios in plain language. e.g. 'A customer browsing for shoes on mobile.'"
Write-Host ""

$Scenarios = @()
for ($i = 1; $i -le 2; $i++) {
  $Scenario = Ask-UX-Text "Scenario $i? (short narrative) — or Enter to skip:"
  if (-not $Scenario) { break }
  $Scenarios += $Scenario
}

if ($Scenarios.Count -eq 0) {
  $ScenariosText = "No scenarios captured."
  Add-UX-Debt $Area "User scenarios not documented" `
    "No key user scenarios were described" `
    "Design decisions lack context for real user tasks"
} else {
  $ScenariosText = ""
  for ($i = 0; $i -lt $Scenarios.Count; $i++) {
    $ScenariosText += @"

### Scenario $($i + 1)
$($Scenarios[$i])
"@
  }
}

# ── Q3: User journey maps ────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 3 / 5 — User journey maps$($script:UX_NC)"
Write-UX-Dim "  For one key scenario, map the steps. Include actions, emotions, pain points, touchpoints."
Write-Host ""

$JourneyScenario = Ask-UX-Text "Which scenario should we map? (e.g. 'checkout flow') — or Enter to skip:"
if (-not $JourneyScenario) {
  $JourneyText = "No journey map created."
  Add-UX-Debt $Area "User journey not mapped" `
    "No detailed user journey steps were documented" `
    "Cannot verify wireframes cover all journey steps"
} else {
  $JourneyText = @"

### Journey: $JourneyScenario

| Step | Action | Emotion | Pain Point | Touchpoint |
|---|---|---|---|---|"

  for ($step = 1; $step -le 5; $step++) {
    $Action = Ask-UX-Text "  Step $step action? (e.g. 'User adds item to cart') — Enter when done:"
    if (-not $Action) { break }

    $Emotion = Ask-UX-Choice "    Emotion?" @("😀 Happy", "😐 Neutral", "😞 Frustrated", "😕 Confused")
    $Pain = Ask-UX-Text "    Pain point? (e.g. 'Can't find add button' — or Enter for none):"
    if (-not $Pain) { $Pain = "None" }

    $Touch = Ask-UX-Text "    Touchpoint? (e.g. 'Product card', 'Mobile app'):"
    if (-not $Touch) { $Touch = "Unknown" }

    $JourneyText += @"
| $step | $Action | $Emotion | $Pain | $Touch |"@
  }
}

# ── Q4: Accessibility needs ─────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 4 / 5 — Accessibility needs$($script:UX_NC)"
Write-UX-Dim "  Does your app need to support any of these? (y/n for each)"
Write-Host ""

$ColorBlind = Ask-UX-YN "  Color-blindness accommodation needed?"
$Motor = Ask-UX-YN "  Keyboard-only navigation (motor impairment)?"
$ScreenReader = Ask-UX-YN "  Screen reader support (blind/low vision)?"
$Dyslexia = Ask-UX-YN "  Dyslexia-friendly fonts (readable typography)?"
$Hearing = Ask-UX-YN "  Captions/transcripts (hearing impairment)?"
$Cognitive = Ask-UX-YN "  Low cognitive load (plain language, simple flows)?"

$AccessibilityText = @"
- **Color-blindness:** $ColorBlind
- **Motor (keyboard-only):** $Motor
- **Screen reader support:** $ScreenReader
- **Dyslexia support:** $Dyslexia
- **Hearing loss support:** $Hearing
- **Cognitive accessibility:** $Cognitive
"@

if (-not ($ColorBlind -eq 'yes' -or $Motor -eq 'yes' -or $ScreenReader -eq 'yes' -or $Dyslexia -eq 'yes' -or $Hearing -eq 'yes' -or $Cognitive -eq 'yes')) {
  Add-UX-Debt $Area "Accessibility requirements not specified" `
    "No accessibility accommodations were requested" `
    "Design may not be inclusive; compliance risk for WCAG"
}

# ── Q5: Device usage patterns ────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 5 / 5 — Device usage patterns$($script:UX_NC)"
Write-UX-Dim "  What percentage of users are on each device type?"
Write-Host ""

$Desktop = Ask-UX-Text "  Desktop users (%)? (e.g. '60' for 60%) — or Enter for unknown:"
if (-not $Desktop) { $Desktop = "Unknown" }

$Mobile = Ask-UX-Text "  Mobile users (%)? (e.g. '35'):"
if (-not $Mobile) { $Mobile = "Unknown" }

$Tablet = Ask-UX-Text "  Tablet users (%)? (e.g. '5'):"
if (-not $Tablet) { $Tablet = "Unknown" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-UX-SuccessRule "✅ User Research Summary"
Write-Host "$($script:UX_BOLD)  Personas captured:$($script:UX_NC) $($Personas.Count)"
Write-Host "$($script:UX_BOLD)  Scenarios captured:$($script:UX_NC) $($Scenarios.Count)"
Write-Host "$($script:UX_BOLD)  Device split:$($script:UX_NC) Desktop $Desktop% | Mobile $Mobile% | Tablet $Tablet%"
Write-Host ""

if (-not (Confirm-UX-Save "Does this look correct? (y=save / n=redo)")) {
  Write-UX-Dim "  Restarting Phase 1..."
  & $PSScriptRoot\research.ps1
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = (Get-Date).ToString("yyyy-MM-dd")
$Content = @"
# User Research & Personas

> Captured: $DateNow
$(if (Test-Path $BAFinal) { "> Requirements basis: \`$BAFinal\`" })

## Primary User Personas
$PersonasText

## User Scenarios
$ScenariosText

## User Journey Maps
$JourneyText

## Accessibility Needs

$AccessibilityText

## Device Usage Patterns

| Device | Percentage |
|---|---|
| Desktop | $Desktop% |
| Mobile | $Mobile% |
| Tablet | $Tablet% |

"@

Set-Content -Path $OutputFile -Value $Content -Encoding UTF8

$endDebts = Get-UX-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "$($script:UX_GREEN)  Saved to: $OutputFile$($script:UX_NC)"
if ($newDebts -gt 0) {
  Write-Host "$($script:UX_YELLOW)  ⚠  $newDebts UX debt(s) logged to: $script:UXDebtFile$($script:UX_NC)"
}
Write-Host ""
