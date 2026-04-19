# =============================================================================
# validate.ps1 — Phase 6: Architecture Validation & Sign-Off (PowerShell)
# Output: $ArchOutputDir\06-architecture-validation.md + ARCHITECTURE-FINAL.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:ARCH_AUTO = '1' }
if ($Answers) { $env:ARCH_ANSWERS = $Answers }


$ReportFile = Join-Path $script:ArchOutputDir "06-architecture-validation.md"
$FinalFile  = Join-Path $script:ArchOutputDir "ARCHITECTURE-FINAL.md"

Write-Arch-Banner "✅  Step 6 of 6 — Architecture Validation & Sign-Off"
Write-Arch-Dim "  Run automated checks + manual sign-off questions, then compile the final doc."
Write-Host ""

$passed = 0
$failed = 0
$warnings = 0
$reportLines = @()

function Check-FileExists {
  param([string]$Label, [string]$Path)
  if ((Test-Path $Path) -and (Get-Item $Path).Length -gt 0) {
    $script:reportLines += "- ✅ $Label exists (``$(Split-Path $Path -Leaf)``)"
    $script:passed++
  } else {
    $script:reportLines += "- ❌ $Label missing or empty (``$(Split-Path $Path -Leaf)``)"
    $script:failed++
  }
}

$IntakeF    = Join-Path $script:ArchOutputDir   "01-architecture-intake.md"
$ResearchF  = Join-Path $script:ArchOutputDir   "02-technology-research.md"
$AdrIndexF  = Join-Path $script:ArchOutputDir   "03-adr-index.md"
$ArchDocF   = Join-Path $script:ArchOutputDir   "04-architecture.md"
$ContextMmd = Join-Path $script:ArchDiagramsDir "context.mmd"
$ContainersMmd = Join-Path $script:ArchDiagramsDir "containers.mmd"

Write-Host "── Automated Checks ──" -ForegroundColor Cyan

Check-FileExists "Architecture intake"      $IntakeF
Check-FileExists "Technology research"      $ResearchF
Check-FileExists "ADR index"                $AdrIndexF
Check-FileExists "C4 architecture document" $ArchDocF
Check-FileExists "Context diagram"          $ContextMmd
Check-FileExists "Container diagram"        $ContainersMmd

$adrTotal = Get-Arch-ADRCount
if ($adrTotal -eq 0) {
  $reportLines += "- ❌ No ADRs were captured"
  $failed++
} else {
  $reportLines += "- ✅ $adrTotal ADR(s) captured"
  $passed++

  $missingSections = 0
  $staleProposed = 0
  $today = Get-Date

  $adrFiles = Get-ChildItem -Path $script:ArchADRDir -Filter "ADR-????-*.md" -ErrorAction SilentlyContinue
  foreach ($f in $adrFiles) {
    $raw = Get-Content -Path $f.FullName -Raw
    $hasCtx = $raw -match '(?m)^## Context'
    $hasDec = $raw -match '(?m)^## Decision'
    $hasAlt = $raw -match '(?m)^## Alternatives Considered'
    $hasCon = $raw -match '(?m)^## Consequences'
    if (-not ($hasCtx -and $hasDec -and $hasAlt -and $hasCon)) { $missingSections++ }

    $statusMatch = [regex]::Match($raw, '(?m)^- \*\*Status:\*\* (.+)$')
    if ($statusMatch.Success -and $statusMatch.Groups[1].Value.Trim() -match '^Proposed') {
      $tdateMatch = [regex]::Match($raw, '(?m)^- \*\*Target decision date:\*\* (.+)$')
      if ($tdateMatch.Success) {
        $tdate = $tdateMatch.Groups[1].Value.Trim()
        if ($tdate -ne "TBD") {
          try {
            $parsed = [DateTime]::ParseExact($tdate, "yyyy-MM-dd", $null)
            if ($parsed -lt $today) { $staleProposed++ }
          } catch { }
        }
      }
    }
  }

  if ($missingSections -eq 0) {
    $reportLines += "- ✅ All ADRs have Context / Decision / Alternatives / Consequences sections"
    $passed++
  } else {
    $reportLines += "- ❌ $missingSections ADR(s) missing one or more required sections"
    $failed++
  }

  if ($staleProposed -eq 0) {
    $reportLines += "- ✅ No ADRs stuck in *Proposed* past their target date"
    $passed++
  } else {
    $reportLines += "- ⚠️ $staleProposed ADR(s) *Proposed* with target date in the past"
    $warnings++
  }
}

if (Test-Path $ArchDocF) {
  $docRaw = Get-Content -Path $ArchDocF -Raw
  $tbdMatches = [regex]::Matches($docRaw, '(?m)^\| .+ \| .+ \| .+ \| TBD \|')
  if ($tbdMatches.Count -eq 0) {
    $reportLines += "- ✅ All containers in the C4 doc reference an ADR"
    $passed++
  } else {
    $reportLines += "- ❌ $($tbdMatches.Count) container(s) in the C4 doc have TBD ADR references"
    $failed++
  }
}

if (Test-Path $script:ArchTDebtFile) {
  $tdRaw = Get-Content -Path $script:ArchTDebtFile -Raw
  $blockingCount = ([regex]::Matches($tdRaw, 'Blocking')).Count
  if ($blockingCount -eq 0) {
    $reportLines += "- ✅ No 🔴 Blocking technical debts"
    $passed++
  } else {
    $reportLines += "- ❌ $blockingCount 🔴 Blocking technical debt(s) present"
    $failed++
  }

  # Un-mitigated High/High risks
  $unmitigated = 0
  $riskBlocks = [regex]::Matches($tdRaw, '(?s)## RISK-\d+:.*?(?=\n## |\z)')
  foreach ($b in $riskBlocks) {
    $txt = $b.Value
    if ($txt -match '\*\*Likelihood:\*\*\s*High' -and $txt -match '\*\*Impact:\*\*\s*High' -and $txt -match '\*\*Mitigation \(proactive\):\*\*\s*TBD') {
      $unmitigated++
    }
  }
  if ($unmitigated -eq 0) {
    $reportLines += "- ✅ No High-likelihood/High-impact risk without mitigation"
    $passed++
  } else {
    $reportLines += "- ❌ $unmitigated High/High risk(s) with TBD mitigation"
    $failed++
  }
}

foreach ($line in $reportLines) { Write-Host "  $line" }
Write-Host ""
Write-Host "  Passed:   $passed" -ForegroundColor Green
Write-Host "  Warnings: $warnings" -ForegroundColor Yellow
Write-Host "  Failed:   $failed" -ForegroundColor Red
Write-Host ""

# ── Manual sign-off questions ────────────────────────────────────────────────
Write-Host "── Manual Sign-Off Questions ──" -ForegroundColor Cyan
Write-Host ""
$m1 = Ask-Arch-YN "Does the architecture trace cleanly to the problem statement?"
$m2 = Ask-Arch-YN "Are all stakeholders aware of decisions that affect them?"
$m3 = Ask-Arch-YN "Is the cost envelope acceptable?"
$m4 = Ask-Arch-YN "Is there a walkaway plan if a key vendor fails?"
Write-Host ""
Write-Arch-Dim "  Sign-off status per reviewer:"
$signEng = Ask-Arch-Choice "  Engineering lead"   @("Signed off", "Pending", "Not required")
$signSec = Ask-Arch-Choice "  Security"           @("Signed off", "Pending", "Not required")
$signOps = Ask-Arch-Choice "  Ops / Platform"     @("Signed off", "Pending", "Not required")
$signPrd = Ask-Arch-Choice "  Product / Business" @("Signed off", "Pending", "Not required")

$manualNoCount = 0
if ($m1 -eq "no") { $manualNoCount++ }
if ($m2 -eq "no") { $manualNoCount++ }
if ($m3 -eq "no") { $manualNoCount++ }
if ($m4 -eq "no") { $manualNoCount++ }

$verdict = "❌ NOT READY"
$verdictReason = "Automated or manual checks failed"
if ($failed -eq 0 -and $manualNoCount -eq 0 -and $warnings -eq 0) {
  $verdict = "✅ APPROVED"
  $verdictReason = "All automated and manual checks passed"
} elseif ($failed -eq 0 -and $manualNoCount -le 1 -and $warnings -le 2) {
  $verdict = "⚠️ CONDITIONALLY APPROVED"
  $verdictReason = "Minor gaps — track each as a TDEBT"
}

Write-Arch-SuccessRule $verdict
Write-Host "  $verdictReason"
Write-Host ""

# ── Write validation report ───────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$reportOut = @()
$reportOut += "# Architecture Validation Report"
$reportOut += ""
$reportOut += "> Captured: $DateNow"
$reportOut += ""
$reportOut += "## Verdict: $verdict"
$reportOut += ""
$reportOut += "_${verdictReason}_"
$reportOut += ""
$reportOut += "## Automated Checks"
$reportOut += ""
foreach ($line in $reportLines) { $reportOut += $line }
$reportOut += ""
$reportOut += "Passed: $passed  |  Warnings: $warnings  |  Failed: $failed"
$reportOut += ""
$reportOut += "## Manual Sign-Off Questions"
$reportOut += ""
$reportOut += "| Question | Answer |"
$reportOut += "|---|---|"
$reportOut += "| Architecture traces to problem statement | $m1 |"
$reportOut += "| Stakeholders aware of affecting decisions | $m2 |"
$reportOut += "| Cost envelope acceptable | $m3 |"
$reportOut += "| Walkaway plan for key-vendor failure | $m4 |"
$reportOut += ""
$reportOut += "## Sign-Off"
$reportOut += ""
$reportOut += "| Reviewer | Status |"
$reportOut += "|---|---|"
$reportOut += "| Engineering lead | $signEng |"
$reportOut += "| Security | $signSec |"
$reportOut += "| Ops / Platform | $signOps |"
$reportOut += "| Product / Business | $signPrd |"
$reportOut += ""

$reportOut -join "`n" | Set-Content -Path $ReportFile -Encoding UTF8
Write-Host "  Report saved to: $ReportFile" -ForegroundColor Green

# ── Compile final document ────────────────────────────────────────────────────
$finalLines = @()
$finalLines += "# Architecture — Final Deliverable"
$finalLines += ""
$finalLines += "> Auto-compiled $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$finalLines += "> Verdict: $verdict"
$finalLines += ""
$finalLines += "---"
$finalLines += ""

foreach ($f in @($IntakeF, $ResearchF, $AdrIndexF, $ArchDocF, $script:ArchTDebtFile, $ReportFile)) {
  if (Test-Path $f) {
    $finalLines += ""
    $finalLines += (Get-Content -Path $f -Raw)
    $finalLines += ""
    $finalLines += "---"
    $finalLines += ""
  }
}

if ($adrTotal -gt 0) {
  $finalLines += ""
  $finalLines += "## Appendix — Full ADR Contents"
  $finalLines += ""
  $adrFiles = Get-ChildItem -Path $script:ArchADRDir -Filter "ADR-????-*.md" -ErrorAction SilentlyContinue | Sort-Object Name
  foreach ($adr in $adrFiles) {
    $finalLines += (Get-Content -Path $adr.FullName -Raw)
    $finalLines += ""
    $finalLines += "---"
    $finalLines += ""
  }
}

$finalLines -join "`n" | Set-Content -Path $FinalFile -Encoding UTF8

Write-Host "  Final document: $FinalFile" -ForegroundColor Green
Write-Host ""
