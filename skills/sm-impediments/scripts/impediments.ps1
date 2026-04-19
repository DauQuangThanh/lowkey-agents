#requires -version 5.1

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:SM_AUTO = '1' }
if ($Answers) { $env:SM_ANSWERS = $Answers }


$OutputFile = Join-Path $script:SMOutputDir "04-impediment-log.md"
$Area = "Impediments"

$startDebts = Get-SM-DebtCount

Write-SM-Banner "Phase 4 of 5 — Impediment Tracker"
Write-SM-Dim "Let's capture and prioritize all blockers and impediments."
Write-SM-Dim "I'll help you assign owners and escalate where needed."
Write-Host ""

$impediments = @()
$escalationCount = 0
$blockingCount = 0
$logDate = (Get-Date).ToString("yyyy-MM-dd")

$impedimentCount = 0
while ($true) {
  $description = Ask-SM-Text "Impediment description (or blank to finish)"
  if ([string]::IsNullOrWhiteSpace($description)) { break }

  $impedimentCount++
  Write-Host ""
  Write-Host "Impediment $impedimentCount`: $description" -ForegroundColor Magenta

  $severity = Ask-SM-Choice "What is the severity?" @(
    "Blocking — stops all progress",
    "Degrading — slows progress",
    "Minor — low impact"
  )

  $sevEmoji, $sevValue = switch ($severity) {
    { $_ -match "Blocking" } { "🔴", "Blocking"; $blockingCount++; break }
    { $_ -match "Degrading" } { "🟡", "Degrading"; break }
    { $_ -match "Minor" } { "🟢", "Minor"; break }
  }

  Write-Host ""
  $affected = Ask-SM-Text "  Which stories/tasks are affected?"
  if ([string]::IsNullOrWhiteSpace($affected)) { $affected = "Unclear" }

  Write-Host ""
  $escalate = Ask-SM-YN "  Does this need escalation? (y/n)"
  $escMark = if ($escalate -eq "yes") { "⬆️  YES"; $escalationCount++ } else { "No" }

  Write-Host ""
  $owner = Ask-SM-Text "  Who should resolve this? (name or role)"
  if ([string]::IsNullOrWhiteSpace($owner)) { $owner = "TBD" }

  Write-Host ""
  $target = Ask-SM-Text "  Target resolution date? (blank for TBD)"
  if ([string]::IsNullOrWhiteSpace($target)) { $target = "TBD" }

  $impediments += @{
    Number = $impedimentCount
    Description = $description
    Severity = $sevValue
    SevEmoji = $sevEmoji
    Affected = $affected
    Escalate = $escMark
    Owner = $owner
    Target = $target
  }

  Add-SM-Debt $Area $description `
    "Impediment: $description (affects: $affected)" `
    "Work blocked or degraded until resolved"

  Write-Host ""
}

Write-SM-SuccessRule "✅ Impediment Summary"
Write-Host ("  Date:                {0}" -f $logDate)
Write-Host ("  Total impediments:   {0}" -f $impedimentCount)
Write-Host ("  Blocking issues:     {0}" -f $blockingCount)
Write-Host ("  Escalations needed:  {0}" -f $escalationCount)
Write-Host ""

if (-not (Confirm-SM-Save "Save impediment log? (y=save / n=redo)")) {
  Write-SM-Dim "Restarting Phase 4..."
  & $PSScriptRoot\impediments.ps1
  exit 0
}

$dateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm")

$impedimentText = ""
if ($impediments.Count -gt 0) {
  foreach ($imp in $impediments) {
    $impedimentText += @"
### $($imp.SevEmoji) Impediment $($imp.Number): $($imp.Description)

**Severity:** $($imp.Severity)

**Affected Work:** $($imp.Affected)

**Escalation:** $($imp.Escalate)

**Owner:** $($imp.Owner)

**Target Resolution:** $($imp.Target)

"@
  }
} else {
  $impedimentText = "(No impediments logged)"
}

$smActions = ""
if ($impedimentCount -gt 0) {
  $smActions = "- [ ] Follow up on $impedimentCount impediment(s)`n"
  if ($blockingCount -gt 0) {
    $smActions += "- [ ] Immediately address $blockingCount blocking issue(s)`n"
  }
  if ($escalationCount -gt 0) {
    $smActions += "- [ ] Escalate $escalationCount issue(s) to leadership`n"
  }
  $smActions += "- [ ] Daily check-in on resolution progress"
} else {
  $smActions = "- [ ] No impediments identified — team is unblocked"
}

$output = @"
# Impediment Log

> Captured: $dateTime

## Summary

**Log Date:** $logDate
**Total Impediments:** $impedimentCount
**Blocking Issues:** $blockingCount
**Escalations Required:** $escalationCount

---

## Impediments

$impedimentText

---

## SM Actions

$smActions

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8
Write-SM-SuccessRule "✅ Impediment log saved to $OutputFile"

$endDebts = Get-SM-DebtCount
$newDebts = $endDebts - $startDebts
if ($newDebts -gt 0) {
  Write-SM-Dim "  ⚠️  $newDebts impediment(s) logged as debts. Review in $script:SMDebtFile"
}
