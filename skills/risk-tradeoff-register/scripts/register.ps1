# =============================================================================
# register.ps1 — Phase 5: Risk & Trade-off Register (PowerShell)
# Output: $ArchOutputDir\05-technical-debts.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:ARCH_AUTO = '1' }
if ($Answers) { $env:ARCH_ANSWERS = $Answers }


$Area = "Risk & Trade-off Register"

Write-Arch-Banner "🚦  Step 5 of 6 — Risk & Trade-off Register"
Write-Arch-Dim "  Risks (RISK-NN): things that could hurt us — with mitigation + contingency."
Write-Arch-Dim "  Technical Debts (TDEBT-NN): things we knowingly deferred."
Write-Host ""

$ExistingTDebts = Get-Arch-TDebtCount
$ExistingRisks  = Get-Arch-RiskCount

if ($ExistingTDebts -gt 0) {
  Write-Host "  ⚠  Found $ExistingTDebts technical debt(s) from earlier steps:" -ForegroundColor Yellow
  Write-Host ""
  $raw = Get-Content -Path $script:ArchTDebtFile -Raw
  $matches = [Regex]::Matches($raw, '(?m)^## TDEBT-\d+: .+$')
  foreach ($m in $matches) {
    Write-Host "  🔴  $($m.Value.Substring(3))"
  }
  Write-Host ""
} else {
  Write-Host "  ✅ No technical debts logged in earlier steps." -ForegroundColor Green
  Write-Host ""
}

# ── Update owners ─────────────────────────────────────────────────────────────
if ($ExistingTDebts -gt 0) {
  Write-Host "── Assigning Owners ──" -ForegroundColor Cyan
  Write-Arch-Dim "  We'll set a default owner for all debts that are still TBD."
  Write-Host ""
  $defaultOwner = Ask-Arch-Text "  Who is the default owner? (name or role, e.g. 'Architect', 'Thanh')"
  if ([string]::IsNullOrWhiteSpace($defaultOwner)) { $defaultOwner = "Architect" }

  $content = Get-Content -Path $script:ArchTDebtFile -Raw
  $updated = $content -replace '\*\*Owner:\*\* TBD', "**Owner:** $defaultOwner"
  $updated | Set-Content -Path $script:ArchTDebtFile -Encoding UTF8
  Write-Host "  ✅ Default owner set to `"$defaultOwner`" for all TBD debts." -ForegroundColor Green
  Write-Host ""
}

# ── Add RISK ──────────────────────────────────────────────────────────────────
function Add-Risk {
  $current = Get-Arch-RiskCount
  $new = $current + 1
  $id = $new.ToString("D2")

  Write-Host ""
  Write-Host "  New Risk: RISK-$id" -ForegroundColor Cyan
  $title = Ask-Arch-Text "  Briefly describe the risk:"
  if ([string]::IsNullOrWhiteSpace($title)) { $title = "Unnamed risk" }

  $likelihood = Ask-Arch-Choice "  Likelihood?" @("Low", "Medium", "High")
  $impact     = Ask-Arch-Choice "  Impact?"     @("Low", "Medium", "High")

  $mitigation = Ask-Arch-Text "  Proactive mitigation (what we do to prevent it):"
  if ([string]::IsNullOrWhiteSpace($mitigation)) { $mitigation = "TBD" }

  if ($likelihood -eq "High" -and $impact -eq "High" -and $mitigation -eq "TBD") {
    Write-Host "  ⚠  WARNING: High/High risk with no mitigation — please revisit." -ForegroundColor Red
  }

  $contingency = Ask-Arch-Text "  Reactive contingency (what we do if it happens):"
  if ([string]::IsNullOrWhiteSpace($contingency)) { $contingency = "TBD" }

  $owner = Ask-Arch-Text "  Owner:"
  if ([string]::IsNullOrWhiteSpace($owner)) { $owner = "Architect" }

  $linked = Ask-Arch-Text "  Linked ADR or requirement ID (e.g. 'ADR-0002, NFR-07'):"
  if ([string]::IsNullOrWhiteSpace($linked)) { $linked = "None" }

  $status = Ask-Arch-Choice "  Status?" @("Open", "Mitigated", "Accepted", "Closed")

  $entry = @"

## RISK-${id}: $title
**Likelihood:** $likelihood
**Impact:** $impact
**Mitigation (proactive):** $mitigation
**Contingency (reactive):** $contingency
**Owner:** $owner
**Linked:** $linked
**Status:** $status

"@
  Add-Content -Path $script:ArchTDebtFile -Value $entry -Encoding UTF8
  Write-Host "  ✅ Risk RISK-$id logged." -ForegroundColor Green
}

Write-Host "── Risks ──" -ForegroundColor Cyan
Write-Arch-Dim "  Examples: vendor lock-in, unproven technology, performance unknowns, staffing"
Write-Arch-Dim "  gaps, compliance gap, data migration complexity."
Write-Host ""
$more = Ask-Arch-YN "Do you want to add a new risk?"
while ($more -eq "yes") {
  Add-Risk
  Write-Host ""
  $more = Ask-Arch-YN "Add another risk?"
}

# ── Add TDEBT ─────────────────────────────────────────────────────────────────
function Add-TDebt-Manual {
  $current = Get-Arch-TDebtCount
  $new = $current + 1
  $id = $new.ToString("D2")

  Write-Host ""
  Write-Host "  New Technical Debt: TDEBT-$id" -ForegroundColor Cyan
  $title = Ask-Arch-Text "  Briefly describe what is unknown or deferred:"
  if ([string]::IsNullOrWhiteSpace($title)) { $title = "Unnamed debt" }

  $area = Ask-Arch-Choice "  Area?" @(
    "Decision — technology choice open",
    "Component — part of the architecture is unspecified",
    "Operations — running/monitoring concern",
    "Compliance — regulatory/legal gap",
    "Other"
  )

  $impact = Ask-Arch-Text "  What is blocked until this is resolved?"
  if ([string]::IsNullOrWhiteSpace($impact)) { $impact = "Unknown — needs assessment" }

  $owner = Ask-Arch-Text "  Owner:"
  if ([string]::IsNullOrWhiteSpace($owner)) { $owner = "Architect" }

  $priority = Ask-Arch-Choice "  Priority?" @(
    "🔴 Blocking — must resolve before implementation starts",
    "🟡 Important — must resolve before affected feature is built",
    "🟢 Can Wait — resolve before go-live"
  )

  $due = Ask-Arch-Text "  Target resolution date? (YYYY-MM-DD or Enter for TBD):"
  if ([string]::IsNullOrWhiteSpace($due)) { $due = "TBD" }

  $linked = Ask-Arch-Text "  Linked ADR / requirement (e.g. 'ADR-0002'):"
  if ([string]::IsNullOrWhiteSpace($linked)) { $linked = "None" }

  $entry = @"

## TDEBT-${id}: $title
**Area:** $area
**Description:** $title
**Impact:** $impact
**Owner:** $owner
**Priority:** $priority
**Target Date:** $due
**Linked:** $linked
**Status:** Open

"@
  Add-Content -Path $script:ArchTDebtFile -Value $entry -Encoding UTF8
  Write-Host "  ✅ TDEBT-$id logged." -ForegroundColor Green
}

Write-Host ""
Write-Host "── Technical Debts ──" -ForegroundColor Cyan
$more = Ask-Arch-YN "Do you want to add a new technical debt?"
while ($more -eq "yes") {
  Add-TDebt-Manual
  Write-Host ""
  $more = Ask-Arch-YN "Add another technical debt?"
}

# ── Summary ───────────────────────────────────────────────────────────────────
$FinalTDebts = Get-Arch-TDebtCount
$FinalRisks  = Get-Arch-RiskCount
$Blocking  = 0; $Important = 0; $Wait = 0
if (Test-Path $script:ArchTDebtFile) {
  $raw = Get-Content -Path $script:ArchTDebtFile -Raw
  $Blocking  = ([regex]::Matches($raw, 'Blocking')).Count
  $Important = ([regex]::Matches($raw, 'Important')).Count
  $Wait      = ([regex]::Matches($raw, 'Can Wait')).Count
}

# Add header if missing
if ((Test-Path $script:ArchTDebtFile) -and -not (Select-String -Path $script:ArchTDebtFile -Pattern '^# Risk & Technical Debt Register' -Quiet -ErrorAction SilentlyContinue)) {
  $existing = Get-Content -Path $script:ArchTDebtFile -Raw
  $header = @"
# Risk & Technical Debt Register

> Last updated: $(Get-Date -Format 'yyyy-MM-dd')

**RISK-NN** entries are things that could hurt us (with likelihood, impact,
mitigation, contingency). **TDEBT-NN** entries are things we knowingly deferred
(with area, impact, owner, priority, target date).

| Priority | Meaning |
|---|---|
| 🔴 Blocking | Must resolve before implementation starts |
| 🟡 Important | Must resolve before the affected feature is built |
| 🟢 Can Wait | Should resolve before go-live |

---

"@
  ($header + $existing) | Set-Content -Path $script:ArchTDebtFile -Encoding UTF8
}

Write-Arch-SuccessRule "✅ Risk & Technical Debt Register"
Write-Host "  Total risks:           $FinalRisks"
Write-Host "  Total technical debts: $FinalTDebts"
Write-Host "  🔴 Blocking:           $Blocking"
Write-Host "  🟡 Important:          $Important"
Write-Host "  🟢 Can Wait:           $Wait"
Write-Host ""
if ($Blocking -gt 0) {
  Write-Host "  ⚠  WARNING: $Blocking blocking debt(s) open — resolve before implementation." -ForegroundColor Red
  Write-Host ""
}
Write-Host "  Register saved to: $script:ArchTDebtFile" -ForegroundColor Green
Write-Host ""
