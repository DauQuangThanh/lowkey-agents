#requires -version 5.1

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:SM_AUTO = '1' }
if ($Answers) { $env:SM_ANSWERS = $Answers }


$OutputFile = Join-Path $script:SMOutputDir "05-team-health.md"
$Area = "Team Health"

$startDebts = Get-SM-DebtCount

Write-SM-Banner "Phase 5 of 5 — Team Health & Velocity"
Write-SM-Dim "Let's measure how the team is doing — velocity, morale, collaboration."
Write-SM-Dim "These metrics help us coach the team toward sustainable high performance."
Write-Host ""

Write-Host "Question 1 / 3 — Velocity" -ForegroundColor Cyan -BackgroundColor DarkCyan
$sprintNum = Ask-SM-Text "Which sprint? (e.g. Sprint 5)"
if ([string]::IsNullOrWhiteSpace($sprintNum)) { $sprintNum = "Sprint-Unknown" }

$plannedVel = Ask-SM-Text "How many points were planned? (or leave blank)"
if ([string]::IsNullOrWhiteSpace($plannedVel)) { $plannedVel = "TBD" }

$actualVel = Ask-SM-Text "How many points were completed?"
if ([string]::IsNullOrWhiteSpace($actualVel)) { $actualVel = "TBD" }

$completionRate = "N/A"
if ($plannedVel -ne "TBD" -and $actualVel -ne "TBD" -and [int]::TryParse($plannedVel, [ref]0)) {
  [int]$p = $plannedVel
  [int]$a = $actualVel
  if ($p -gt 0) {
    $completionRate = "{0}%" -f (($a * 100) / $p)
  }
}

Write-Host ""
Write-Host "Question 2 / 3 — Team Sentiment" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "Rate on a scale of 1-5 (1=very low, 5=excellent)"
Write-Host ""

$morale = Ask-SM-Text "Team morale / engagement? (1-5)"
if ([string]::IsNullOrWhiteSpace($morale)) { $morale = "TBD" }

$moraleEmoji = switch ($morale) {
  "1" { "😢" }
  "2" { "😕" }
  "3" { "😐" }
  "4" { "🙂" }
  "5" { "😄" }
  default { "❓" }
}

$collaboration = Ask-SM-Text "Collaboration / teamwork? (1-5)"
if ([string]::IsNullOrWhiteSpace($collaboration)) { $collaboration = "TBD" }

$technical = Ask-SM-Text "Technical practices (testing, code review, etc)? (1-5)"
if ([string]::IsNullOrWhiteSpace($technical)) { $technical = "TBD" }

Write-Host ""
Write-Host "Question 3 / 3 — Trends & Coaching Notes" -ForegroundColor Cyan -BackgroundColor DarkCyan
Write-SM-Dim "Are velocity, morale, or practices improving, stable, or declining?"
Write-Host ""

$trend = Ask-SM-Choice "Overall trend?" @(
  "Improving — team getting stronger",
  "Stable — consistent performance",
  "Declining — needs coaching"
)

Write-Host ""
$coaching = Ask-SM-Text "Any specific coaching observations or areas to focus on?"
if ([string]::IsNullOrWhiteSpace($coaching)) { $coaching = "(None recorded)" }

Write-SM-SuccessRule "✅ Team Health Summary"
Write-Host ("  Sprint:                {0}" -f $sprintNum)
Write-Host ("  Velocity:              {0} / {1} points ({2})" -f $actualVel, $plannedVel, $completionRate)
Write-Host ("  Morale:                {0}/5 {1}" -f $morale, $moraleEmoji)
Write-Host ("  Collaboration:         {0}/5" -f $collaboration)
Write-Host ("  Technical practices:   {0}/5" -f $technical)
Write-Host ("  Trend:                 {0}" -f $trend)
Write-Host ""

if (-not (Confirm-SM-Save "Save team health report? (y=save / n=redo)")) {
  Write-SM-Dim "Restarting Phase 5..."
  & $PSScriptRoot\team-health.ps1
  exit 0
}

$dateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm")

$coachingActions = ""
if ($morale -ne "TBD" -and [int]::TryParse($morale, [ref]0) -and [int]$morale -lt 3) {
  $coachingActions += "- [ ] Check in 1:1 with team members on morale concerns`n"
}
if ($collaboration -ne "TBD" -and [int]::TryParse($collaboration, [ref]0) -and [int]$collaboration -lt 3) {
  $coachingActions += "- [ ] Facilitate team building or communication workshop`n"
}
if ($technical -ne "TBD" -and [int]::TryParse($technical, [ref]0) -and [int]$technical -lt 3) {
  $coachingActions += "- [ ] Coach team on technical practices (testing, code review, etc)`n"
}
if ($completionRate -match "50") {
  $coachingActions += "- [ ] Investigate why completion rate is low (capacity? scope creep?)`n"
}

if ([string]::IsNullOrWhiteSpace($coachingActions)) {
  $coachingActions = "- [ ] Team is performing well — continue current practices"
}

$output = @"
# Team Health & Velocity

> Captured: $dateTime

## Sprint Summary

**Sprint:** $sprintNum

### Velocity

| Metric | Value |
|--------|-------|
| Planned | $plannedVel points |
| Completed | $actualVel points |
| Completion Rate | $completionRate |

---

## Team Health Metrics

| Dimension | Rating | Status |
|-----------|--------|--------|
| Morale / Engagement | $morale/5 | $moraleEmoji |
| Collaboration / Teamwork | $collaboration/5 | |
| Technical Practices | $technical/5 | |

---

## Trend Analysis

**Overall Trend:** $trend

### Coaching Notes

$coaching

---

## SM Coaching Actions

$coachingActions

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8
Write-SM-SuccessRule "✅ Team health report saved to $OutputFile"

$endDebts = Get-SM-DebtCount
$newDebts = $endDebts - $startDebts
if ($newDebts -gt 0) {
  Write-SM-Dim "  ⚠️  $newDebts health concern(s) noted. Review in $script:SMDebtFile"
}
