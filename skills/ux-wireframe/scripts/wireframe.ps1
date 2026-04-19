#Requires -Version 5.1
# =============================================================================
# wireframe.ps1 — Phase 2: Wireframes & IA (PowerShell)
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\..\ux-research\scripts\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:UX_AUTO = '1' }
if ($Answers) { $env:UX_ANSWERS = $Answers }


$OutputFile = Join-Path $script:UXOutputDir "02-wireframes.md"
$Area = "Wireframe & IA"

$startDebts = Get-UX-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-UX-Banner "🎨  Phase 2 — Wireframes & Information Architecture"
Write-UX-Dim "  Let's sketch the screens and navigation structure that serve your users."
Write-UX-Dim "  Most answers are numbered choices or short descriptions. Skip with Enter if unsure."
Write-Host ""

# ── Check Phase 1 ────────────────────────────────────────────────────────────
$ResearchFile = Join-Path $script:UXOutputDir "01-user-research.md"
if (Test-Path $ResearchFile) {
  Write-Host "$($script:UX_GREEN)  ✔ Found Phase 1 output: $ResearchFile$($script:UX_NC)"
  Write-UX-Dim "  I'll reference your personas and scenarios. Continuing..."
} else {
  Write-Host "$($script:UX_YELLOW)  ⚠ No Phase 1 output found at: $ResearchFile$($script:UX_NC)"
  Write-UX-Dim "  For best results, run Phase 1 (User Research) first. Continuing anyway..."
  Add-UX-Debt $Area "No Phase 1 user research found" `
    "ux-output/01-user-research.md was not present" `
    "Wireframes lack user grounding"
}
Write-Host ""

# ── Q1: Navigation structure ─────────────────────────────────────────────────
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 1 / 4 — Navigation structure$($script:UX_NC)"
Write-Host ""

$NavStructure = Ask-UX-Choice "What is the primary navigation pattern?" @(
  "Sidebar menu (persistent left or right)",
  "Top horizontal menu",
  "Bottom tabs (mobile app style)",
  "Hamburger menu (mobile)",
  "Linear / wizard (step-by-step)",
  "Not sure yet"
)

if ($NavStructure -eq "Not sure yet") {
  Add-UX-Debt $Area "Navigation structure not decided" `
    "Primary navigation pattern is open" `
    "Cannot design wireframes without knowing how users navigate"
}

# ── Q2: Key screens ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 2 / 4 — Key screens to wireframe$($script:UX_NC)"
Write-UX-Dim "  List 3–6 primary screens you want wireframed (comma-separated)."
Write-UX-Dim "  Examples: 'Login, Dashboard, Product List, Product Detail, Cart, Checkout'"
Write-Host ""

$KeyScreens = Ask-UX-Text "Your screens:"
if (-not $KeyScreens) {
  $KeyScreens = "TBD"
  Add-UX-Debt $Area "Key screens not identified" `
    "No primary screens were listed for wireframing" `
    "Cannot produce wireframes without screen list"
}

# ── Q3: Layout preferences ───────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 3 / 4 — Page layout$($script:UX_NC)"
Write-Host ""

$Layout = Ask-UX-Choice "Primary layout pattern?" @(
  "Header + Sidebar + Main + Footer",
  "Header + Main (full width) + Footer",
  "Two-column: narrow left (sidebar) + wide right (main)",
  "Card-based grid layout",
  "Floating elements (no strict grid)",
  "Not decided yet"
)

$Hierarchy = Ask-UX-Text "Content hierarchy: where should the main CTA (call-to-action) be? (e.g. 'top-right corner', 'inline with product card')"
if (-not $Hierarchy) {
  $Hierarchy = "Not specified"
  Add-UX-Debt $Area "Content hierarchy not specified" `
    "CTA placement and hierarchy unclear" `
    "Design may lack visual guidance for primary action"
}

# ── Q4: Interaction patterns ─────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:UX_CYAN)$($script:UX_BOLD)Question 4 / 4 — Interaction patterns$($script:UX_NC)"
Write-Host ""

$Forms = Ask-UX-Choice "Form interaction style?" @(
  "Single-page form with real-time validation",
  "Multi-step wizard with progress bar",
  "Simple submit with validation on submit",
  "Not yet decided"
)

$Lists = Ask-UX-Choice "For lists/tables, what interactions matter most?" @(
  "Sorting and filtering",
  "Search only",
  "Pagination to view more",
  "Infinite scroll (load more automatically)",
  "All of the above",
  "Not applicable for this product"
)

$Responsive = Ask-UX-Choice "Responsive design approach?" @(
  "Mobile-first (design for mobile, enhance for desktop)",
  "Desktop-first (design for desktop, adapt for mobile)",
  "Separate designs per breakpoint",
  "Not decided yet"
)

if ($Responsive -eq "Not decided yet") {
  Add-UX-Debt $Area "Responsive strategy not decided" `
    "Mobile-first vs. desktop-first not chosen" `
    "Cannot finalize layout without responsiveness strategy"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-UX-SuccessRule "✅ Wireframe Plan Summary"
Write-Host "$($script:UX_BOLD)  Navigation:$($script:UX_NC)        $NavStructure"
Write-Host "$($script:UX_BOLD)  Key screens:$($script:UX_NC)       $KeyScreens"
Write-Host "$($script:UX_BOLD)  Layout pattern:$($script:UX_NC)    $Layout"
Write-Host "$($script:UX_BOLD)  CTA placement:$($script:UX_NC)     $Hierarchy"
Write-Host "$($script:UX_BOLD)  Forms:$($script:UX_NC)            $Forms"
Write-Host "$($script:UX_BOLD)  Lists/Tables:$($script:UX_NC)      $Lists"
Write-Host "$($script:UX_BOLD)  Responsive:$($script:UX_NC)        $Responsive"
Write-Host ""

if (-not (Confirm-UX-Save "Does this look correct? (y=save / n=redo)")) {
  Write-UX-Dim "  Restarting Phase 2..."
  & $PSScriptRoot\wireframe.ps1
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = (Get-Date).ToString("yyyy-MM-dd")
$Content = @"
# Wireframes & Information Architecture

> Captured: $DateNow
$(if (Test-Path $ResearchFile) { "> User research basis: \`$ResearchFile\`" })

## Navigation Structure

**Primary pattern:** $NavStructure

## Key Screens

**Screens to wireframe:** $KeyScreens

## Layout & Hierarchy

**Layout pattern:** $Layout

**Content hierarchy / CTA placement:** $Hierarchy

## Interaction Patterns

| Pattern | Choice |
|---|---|
| Forms | $Forms |
| Lists / Tables | $Lists |
| Responsive strategy | $Responsive |

## Wireframe Sketches

*(Detailed wireframe descriptions for each screen will be added in next iteration)*

## Navigation Flowchart

\`\`\`mermaid
flowchart TD
  Home[Home] --> Nav{Navigation}
  Nav -->|Screen1| S1[Screen 1]
  Nav -->|Screen2| S2[Screen 2]
  S1 --> End[End]
  S2 --> End
\`\`\`

## Information Architecture

\`\`\`mermaid
graph TD
  Root[App] --> S1[$KeyScreens]
\`\`\`

## Responsive Considerations

- **Strategy:** $Responsive
- **Breakpoints:** [Mobile: <768px, Tablet: 768-1024px, Desktop: >1024px]
- **Touch targets:** Minimum 48px for mobile

"@

Set-Content -Path $OutputFile -Value $Content -Encoding UTF8

$endDebts = Get-UX-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "$($script:UX_GREEN)  Saved to: $OutputFile$($script:UX_NC)"
if ($newDebts -gt 0) {
  Write-Host "$($script:UX_YELLOW)  ⚠  $newDebts UX debt(s) logged to: $script:UXDebtFile$($script:UX_NC)"
}
Write-Host ""
