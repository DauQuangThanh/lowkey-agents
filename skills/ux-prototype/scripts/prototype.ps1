#Requires -Version 5.1
# =============================================================================
# prototype.ps1 — Phase 3: Mockup & Prototype Specification (PowerShell)
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\..\ux-research\scripts\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:UX_AUTO = '1' }
if ($Answers) { $env:UX_ANSWERS = $Answers }


$OutputFile = Join-Path $script:UXOutputDir "03-prototype-spec.md"
$Area = "Prototype Specification"

$startDebts = Get-UX-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-UX-Banner "🎭  Phase 3 — Mockup & Prototype Specification"
Write-UX-Dim "  Let's define the visual design and interaction details for your interface."
Write-UX-Dim "  Most answers are numbered choices or short descriptions. Skip with Enter if unsure."
Write-Host ""

# ── Check Phase 2 ────────────────────────────────────────────────────────────
$WireframeFile = Join-Path $script:UXOutputDir "02-wireframes.md"
if (Test-Path $WireframeFile) {
  Write-Host "$($script:UX_GREEN)  ✔ Found Phase 2 output: $WireframeFile$($script:UX_NC)"
  Write-UX-Dim "  I'll reference your wireframes and layout decisions. Continuing..."
} else {
  Write-Host "$($script:UX_YELLOW)  ⚠ No Phase 2 output found at: $WireframeFile$($script:UX_NC)"
  Write-UX-Dim "  For best results, run Phase 2 (Wireframes) first. Continuing anyway..."
  Add-UX-Debt $Area "No Phase 2 wireframes found" `
    "ux-output/02-wireframes.md was not present" `
    "Design specifications may lack layout grounding"
}
Write-Host ""

# ── Q1: Visual style ─────────────────────────────────────────────────────────
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 1 / 4 — Visual style preference$($script:UX_NC)"
Write-Host ""

$VisualStyle = Ask-UX-Choice "Choose or describe a visual style:" @(
  "Minimal — clean, whitespace, sans-serif, 2–3 colors, flat",
  "Corporate — professional, structured, blues/grays, clear hierarchy",
  "Playful — approachable, rounded, warm colors, illustrations",
  "Modern — bold typography, asymmetric, gradients, animations",
  "Custom — I'll describe my own aesthetic"
)

if ($VisualStyle -eq "Custom — I'll describe my own aesthetic") {
  $VisualStyle = Ask-UX-Text "Describe your visual style preference:"
  if (-not $VisualStyle) { $VisualStyle = "TBD" }
}

if ($VisualStyle -eq "TBD") {
  Add-UX-Debt $Area "Visual style not defined" `
    "Design aesthetic is open" `
    "Developers cannot implement design without style direction"
}

# ── Q2: Color scheme ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 2 / 4 — Color scheme$($script:UX_NC)"
Write-UX-Dim "  Examples: '#0055CC blue, #6C63FF purple, #F5F5F5 light gray'"
Write-Host ""

$PrimaryColor = Ask-UX-Text "Primary color (hex or name)? e.g. '#0055CC' or 'brand blue':"
if (-not $PrimaryColor) { $PrimaryColor = "TBD" }

$SecondaryColor = Ask-UX-Text "Secondary color? e.g. '#6C63FF':"
if (-not $SecondaryColor) { $SecondaryColor = "TBD" }

$AccentColor = Ask-UX-Text "Accent color (e.g. for highlights)? e.g. '#FFD700':"
if (-not $AccentColor) { $AccentColor = "TBD" }

$DarkMode = Ask-UX-YN "Does the app need a dark mode?"

if ($PrimaryColor -eq "TBD" -or $SecondaryColor -eq "TBD") {
  Add-UX-Debt $Area "Color palette not finalized" `
    "Primary and/or secondary colors not specified" `
    "Design implementation and accessibility review cannot proceed"
}

# ── Q3: Typography ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 3 / 4 — Typography$($script:UX_NC)"
Write-UX-Dim "  Examples: 'Roboto', 'System fonts', 'Helvetica Neue + Georgia'"
Write-Host ""

$Fonts = Ask-UX-Text "Font preference? (e.g. 'Roboto', 'System fonts', 'Inter + Courier'):"
if (-not $Fonts) { $Fonts = "System fonts (default)" }

$HeadingSize = Ask-UX-Text "Heading font size (e.g. '32px for H1')? Or Enter for standard scale:"
if (-not $HeadingSize) { $HeadingSize = "32px / 24px / 18px (standard)" }

# ── Q4: Interactions & component states ────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 4 / 4 — Component interactions$($script:UX_NC)"
Write-UX-Dim "  Which component states are most important to spec?"
Write-Host ""

$ButtonStates = Ask-UX-YN "Specify button states (hover, active, disabled)?"
$FormValidation = Ask-UX-YN "Specify form validation states (error, success)?"
$Loading = Ask-UX-YN "Specify loading states (spinners, skeletons)?"

$PrototypingTool = Ask-UX-Choice "Where will this be prototyped for user testing?" @(
  "Figma (design tool with prototype features)",
  "InVision (interactive prototype platform)",
  "Clickable HTML/CSS (basic prototype)",
  "Not yet decided"
)

# ── Summary ───────────────────────────────────────────────────────────────────
Write-UX-SuccessRule "✅ Design Specification Summary"
Write-Host "$($script:UX_BOLD)  Visual style:$($script:UX_NC)        $VisualStyle"
Write-Host "$($script:UX_BOLD)  Colors:$($script:UX_NC)             Primary: $PrimaryColor | Secondary: $SecondaryColor | Accent: $AccentColor"
Write-Host "$($script:UX_BOLD)  Dark mode:$($script:UX_NC)          $DarkMode"
Write-Host "$($script:UX_BOLD)  Fonts:$($script:UX_NC)             $Fonts"
Write-Host "$($script:UX_BOLD)  Prototyping tool:$($script:UX_NC)   $PrototypingTool"
Write-Host ""

if (-not (Confirm-UX-Save "Does this look correct? (y=save / n=redo)")) {
  Write-UX-Dim "  Restarting Phase 3..."
  & $PSScriptRoot\prototype.ps1
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = (Get-Date).ToString("yyyy-MM-dd")
$Content = @"
# Mockup & Prototype Specification

> Captured: $DateNow
$(if (Test-Path $WireframeFile) { "> Wireframe basis: \`$WireframeFile\`" })

## Visual Design Direction

**Style:** $VisualStyle

## Color Palette

| Role | Color | Usage |
|---|---|---|
| Primary | $PrimaryColor | Buttons, links, active states |
| Secondary | $SecondaryColor | Accents, secondary actions |
| Accent | $AccentColor | Highlights, emphasis |

**Dark mode:** $DarkMode

## Typography

**Fonts:** $Fonts

**Size scale:**
- Heading 1: $HeadingSize
- Heading 2: [20px / 28px]
- Body: 16px (14px on mobile)
- Label: 12px

## Component Interactions

| Component | Spec Status |
|---|---|
| Button states | $ButtonStates |
| Form validation | $FormValidation |
| Loading states | $Loading |

## Prototyping Approach

**Tool:** $PrototypingTool

## Mockup Specifications

*(Add detailed mockups for each key screen with spacing, typography, and color assignments here)*

"@

Set-Content -Path $OutputFile -Value $Content -Encoding UTF8

$endDebts = Get-UX-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "$($script:UX_GREEN)  Saved to: $OutputFile$($script:UX_NC)"
if ($newDebts -gt 0) {
  Write-Host "$($script:UX_YELLOW)  ⚠  $newDebts UX debt(s) logged to: $script:UXDebtFile$($script:UX_NC)"
}
Write-Host ""
