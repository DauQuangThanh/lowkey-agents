# =============================================================================
# new-adr.ps1 — Phase 3: ADR Builder (PowerShell)
# Output: $ArchADRDir\ADR-NNNN-<slug>.md + $ArchOutputDir\03-adr-index.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:ARCH_AUTO = '1' }
if ($Answers) { $env:ARCH_ANSWERS = $Answers }


$IndexFile = Join-Path $script:ArchOutputDir "03-adr-index.md"
$Area      = "ADR Builder"

$startTDebts = Get-Arch-TDebtCount

New-Item -ItemType Directory -Path $script:ArchADRDir -Force | Out-Null

Write-Arch-Banner "📜  Step 3 of 6 — ADR Builder"
Write-Arch-Dim "  An Architecture Decision Record (ADR) captures ONE significant decision"
Write-Arch-Dim "  using the Michael Nygard template. ADRs are append-only — to change a"
Write-Arch-Dim "  decision, write a new ADR that supersedes the old one."
Write-Host ""

$existing = Get-Arch-ADRCount
if ($existing -gt 0) {
  Write-Host "  Found $existing existing ADR(s) in $script:ArchADRDir" -ForegroundColor Cyan
  Write-Host ""
}

function Capture-ADR {
  $adrId = Get-Arch-NextADRId
  Write-Host "── New ADR: $adrId ──" -ForegroundColor Cyan
  Write-Host ""

  $title = Ask-Arch-Text "  Short title (noun phrase, e.g. 'Use PostgreSQL as primary database'):"
  if ([string]::IsNullOrWhiteSpace($title)) {
    Write-Host "  Title is required — skipping this ADR." -ForegroundColor Red
    return $false
  }
  $slug = Get-Arch-Slug -Text $title

  $statusRaw = Ask-Arch-Choice "  Status?" @(
    "Proposed — decision is open for discussion",
    "Accepted — decision is in effect",
    "Deprecated — no longer recommended",
    "Superseded — replaced by a newer ADR"
  )
  $status = ($statusRaw -split ' — ')[0]

  $dateVal = Ask-Arch-Text "  Decision date (YYYY-MM-DD)? Enter for today:"
  if ([string]::IsNullOrWhiteSpace($dateVal)) { $dateVal = Get-Date -Format "yyyy-MM-dd" }

  $deciders = Ask-Arch-Text "  Deciders (names or roles, comma-separated):"
  if ([string]::IsNullOrWhiteSpace($deciders)) { $deciders = "TBD" }

  $targetDate = "N/A"
  if ($status -eq "Proposed") {
    $targetDate = Ask-Arch-Text "  Target decision date (YYYY-MM-DD)? Enter for TBD:"
    if ([string]::IsNullOrWhiteSpace($targetDate)) {
      $targetDate = "TBD"
      Add-Arch-TDebt -Area $Area -Title "$adrId Proposed without target date" `
        -Description "ADR '$title' is Proposed with no target decision date" `
        -Impact "Open decision may block downstream work indefinitely"
    }
  }

  $supersedes = "None"
  if ($status -eq "Superseded") {
    $supersedes = Ask-Arch-Text "  Which ADR does this supersede? (e.g. ADR-0003)"
    if ([string]::IsNullOrWhiteSpace($supersedes)) { $supersedes = "TBD" }
  }

  Write-Host ""
  Write-Arch-Dim "  CONTEXT — the forces at play: requirements, constraints, NFRs."
  $context = Ask-Arch-Text "  Context (2–4 sentences — or a short summary; refine in editor later):"
  if ([string]::IsNullOrWhiteSpace($context)) { $context = "TBD — context not captured" }

  Write-Host ""
  Write-Arch-Dim "  DECISION — one clear paragraph, active voice."
  $decision = Ask-Arch-Text "  Decision:"
  if ([string]::IsNullOrWhiteSpace($decision)) { $decision = "TBD — decision not captured" }

  Write-Host ""
  Write-Arch-Dim "  ALTERNATIVES — 2 or 3 rejected options, each with 'rejected because...'"
  $alt1 = Ask-Arch-Text "  Alternative 1 (or Enter to skip):"
  $alt2 = Ask-Arch-Text "  Alternative 2 (or Enter to skip):"
  $alt3 = Ask-Arch-Text "  Alternative 3 (or Enter to skip):"

  Write-Host ""
  $consPos = Ask-Arch-Text "  Positive consequences (what improves):"
  if ([string]::IsNullOrWhiteSpace($consPos)) { $consPos = "TBD" }
  $consNeg = Ask-Arch-Text "  Negative consequences / trade-offs (what we accept):"
  if ([string]::IsNullOrWhiteSpace($consNeg)) { $consNeg = "TBD" }
  $consFollow = Ask-Arch-Text "  Follow-up actions (other ADRs, migrations, training):"
  if ([string]::IsNullOrWhiteSpace($consFollow)) { $consFollow = "None" }

  Write-Host ""
  $refs = Ask-Arch-Text "  References (requirement IDs, docs, URLs — comma-separated):"
  if ([string]::IsNullOrWhiteSpace($refs)) { $refs = "None" }

  $adrFile = Join-Path $script:ArchADRDir "$adrId-$slug.md"

  $lines = @()
  $lines += "# ${adrId}: ${title}"
  $lines += ""
  $lines += "- **Status:** $status"
  if ($targetDate -ne "N/A") { $lines += "- **Target decision date:** $targetDate" }
  if ($supersedes -ne "None") { $lines += "- **Supersedes:** $supersedes" }
  $lines += "- **Date:** $dateVal"
  $lines += "- **Deciders:** $deciders"
  $lines += ""
  $lines += "## Context"
  $lines += ""
  $lines += $context
  $lines += ""
  $lines += "## Decision"
  $lines += ""
  $lines += $decision
  $lines += ""
  $lines += "## Alternatives Considered"
  $lines += ""

  $altEmpty = $true
  foreach ($a in @($alt1, $alt2, $alt3)) {
    if (-not [string]::IsNullOrWhiteSpace($a)) { $lines += "- $a"; $altEmpty = $false }
  }
  if ($altEmpty) {
    $lines += "- _None captured — a TDEBT has been logged for this ADR._"
    Add-Arch-TDebt -Area $Area -Title "$adrId has no alternatives" `
      -Description "No alternative options captured" `
      -Impact "Decision appears unconsidered / non-justifiable"
  }
  $lines += ""
  $lines += "## Consequences"
  $lines += ""
  $lines += "- ✅ **Positive:** $consPos"
  $lines += "- ⚠️ **Negative / trade-offs:** $consNeg"
  $lines += "- 🔁 **Follow-up actions:** $consFollow"
  $lines += ""
  $lines += "## References"
  $lines += ""
  $lines += $refs
  $lines += ""

  $lines -join "`n" | Set-Content -Path $adrFile -Encoding UTF8
  Write-Host ""
  Write-Host "  ✅ Saved: $adrFile" -ForegroundColor Green
  Write-Host ""
  return $true
}

# Capture loop
Capture-ADR | Out-Null
while ($true) {
  $more = Ask-Arch-YN "Add another ADR?"
  if ($more -eq "no") { break }
  Capture-ADR | Out-Null
}

# Regenerate index
$totalADRs = Get-Arch-ADRCount
$indexLines = @()
$indexLines += "# ADR Index"
$indexLines += ""
$indexLines += "> Regenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$indexLines += ""
$indexLines += "All Architecture Decision Records for this project. ADRs are append-only — to"
$indexLines += "change a decision, write a new ADR with status *Accepted* that supersedes the old."
$indexLines += ""
$indexLines += "| ID | Title | Status | Date |"
$indexLines += "|---|---|---|---|"

$files = Get-ChildItem -Path $script:ArchADRDir -Filter "ADR-????-*.md" -ErrorAction SilentlyContinue | Sort-Object Name
foreach ($f in $files) {
  $content = Get-Content -Path $f.FullName -Raw
  $id = if ($f.Name -match '^(ADR-\d{4})') { $Matches[1] } else { $f.BaseName }
  $titleMatch  = [Regex]::Match($content, "^# $id`: (.+)$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
  $statusMatch = [Regex]::Match($content, '^\- \*\*Status:\*\* (.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
  $dateMatch   = [Regex]::Match($content, '^\- \*\*Date:\*\* (.+)$',   [System.Text.RegularExpressions.RegexOptions]::Multiline)
  $title  = if ($titleMatch.Success)  { $titleMatch.Groups[1].Value.Trim()  } else { "(no title)" }
  $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim() } else { "(no status)" }
  $dateV  = if ($dateMatch.Success)   { $dateMatch.Groups[1].Value.Trim()   } else { "(no date)" }
  $indexLines += "| [$id](adr/$($f.Name)) | $title | $status | $dateV |"
}
$indexLines += ""
$indexLines += "Total: $totalADRs ADR(s)"

$indexLines -join "`n" | Set-Content -Path $IndexFile -Encoding UTF8

$endTDebts = Get-Arch-TDebtCount
$newTDebts = $endTDebts - $startTDebts

Write-Arch-SuccessRule "✅ ADR Index Updated"
Write-Host "  Index:    $IndexFile" -ForegroundColor Green
Write-Host "  ADR dir:  $script:ArchADRDir" -ForegroundColor Green
Write-Host "  Total:    $totalADRs ADR(s)" -ForegroundColor Green
if ($newTDebts -gt 0) {
  Write-Host "  ⚠  $newTDebts technical debt(s) logged to: $script:ArchTDebtFile" -ForegroundColor Yellow
}
Write-Host ""
