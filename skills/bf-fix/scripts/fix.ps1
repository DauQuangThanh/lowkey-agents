# =============================================================================
# fix.ps1 — Phase 2: per-item fix loop (PowerShell 5.1+)
# =============================================================================

param([switch]$Auto, [string]$Answers = "", [string]$Branch = "", [switch]$DryRun)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:BF_AUTO = '1' }
if ($Answers) { $env:BF_ANSWERS = $Answers }
if ($Branch)  { $env:BF_BRANCH = $Branch }
if ($DryRun)  { $env:BF_DRY_RUN = '1' }

$OutputFile  = Join-Path $script:BFOutputDir "02-fixes.md"
$ExtractFile = Join-Path $script:BFOutputDir "02-fixes.extract"
$PatchDir    = Join-Path $script:BFOutputDir "patches"
$AllPatches  = Join-Path $script:BFOutputDir "all-patches.diff"
$BatchFile   = Join-Path $script:BFOutputDir ".triage-head.tmp"

New-Item -ItemType Directory -Path $PatchDir -Force | Out-Null

Write-BF-Banner "Phase 2 — Fix loop"

if (-not (Test-Path $BatchFile)) {
  Write-Host "ERROR: Triage batch file not found: $BatchFile" -ForegroundColor Red
  Write-Host "Run Phase 1 first."
  exit 1
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "ERROR: git not on PATH. bug-fixer requires git." -ForegroundColor Red
  exit 1
}

$RepoRoot = (git rev-parse --show-toplevel 2>$null).Trim()
if (-not $RepoRoot) {
  Write-Host "ERROR: Not inside a git repository." -ForegroundColor Red
  exit 1
}

if (-not (Test-BF-DryRun)) {
  $dirty = git -C $RepoRoot status --porcelain
  if ($dirty) {
    Write-Host "ERROR: working tree is dirty. Commit or stash first, or use -DryRun." -ForegroundColor Red
    exit 1
  }
}

if ((Test-BF-Auto) -and (-not (Test-BF-DryRun))) {
  if (-not $script:BFBranch) {
    Write-Host "ERROR: auto mode requires -Branch NAME." -ForegroundColor Red
    exit 1
  }
}

$FixBranch = if (Test-BF-DryRun) { "(dry-run — no branch switch)" } else {
  if (-not $script:BFBranch) {
    "bf/auto-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
  } else { $script:BFBranch }
}

if (-not (Test-BF-DryRun)) {
  $exists = git -C $RepoRoot show-ref --verify --quiet "refs/heads/$FixBranch" 2>$null
  if ($LASTEXITCODE -eq 0) {
    git -C $RepoRoot checkout $FixBranch 2>$null | Out-Null
  } else {
    git -C $RepoRoot checkout -b $FixBranch 2>$null | Out-Null
  }
  Write-BF-Dim "  Branch: $FixBranch"
}

$MaxFiles = Get-BF-Answer -Key "MAX_FILES_PER_FIX" -Prompt "Max files per fix:" -Default "1"
$MaxLines = Get-BF-Answer -Key "MAX_LINES_PER_FIX" -Prompt "Max lines changed per fix:" -Default "20"

$fixed = New-Object System.Collections.Generic.List[string]
$deferred = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$commits = New-Object System.Collections.Generic.List[string]
$bfNum = 0
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$mode = if (Test-BF-Auto) { "Auto" } else { "Interactive" }

$header = @"
# Phase 2 — Fixes

**Timestamp:** $ts
**Mode:** $mode
**Branch:** $FixBranch
**Dry-run:** $(if (Test-BF-DryRun) { 'yes' } else { 'no' })

"@
Set-Content -Path $OutputFile -Value $header -Encoding UTF8
Set-Content -Path $AllPatches -Value "" -Encoding UTF8

foreach ($line in Get-Content $BatchFile) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split "\|"
  $rank = $parts[0]; $id = $parts[1]; $source = $parts[2]
  $severity = $parts[3]; $priority = $parts[4]; $component = $parts[5]; $title = $parts[6]
  $bfNum++
  $bfId = "BF-{0:D2}" -f $bfNum

  Write-Host ""
  Write-Host "─── $bfId — resolves $id ──────────────" -ForegroundColor Yellow
  Write-Host "  Source:    $source"
  Write-Host "  Severity:  $severity"
  Write-Host "  Priority:  $priority"
  Write-Host "  Component: $(if ($component) { $component } else { 'unknown' })"
  Write-Host "  Title:     $title`n"

  $decision = if (Test-BF-Auto) { "apply" } else {
    $c = Ask-BF-Choice -Prompt "Action:" -Options @(
      "Apply patch (edit files, then confirm)",
      "Skip","Defer (log BFDEBT)")
    if ($c.StartsWith("Apply")) { "apply" }
    elseif ($c.StartsWith("Skip")) { "skip" }
    else { "defer" }
  }

  $patchFile = Join-Path $PatchDir "$id.diff"
  $outcome = "skipped"; $filesChanged = 0; $linesChanged = 0; $commitSha = ""

  switch ($decision) {
    "apply" {
      if (-not (Test-BF-Auto)) {
        Write-BF-Dim "  → Make the code edits now, then press Enter to capture the diff."
        Read-Host | Out-Null
      }
      git -C $RepoRoot diff HEAD 2>$null | Set-Content -Path $patchFile -Encoding UTF8

      $filesChanged = (git -C $RepoRoot diff --name-only HEAD 2>$null | Measure-Object).Count
      $numstat = git -C $RepoRoot diff --numstat HEAD 2>$null
      $linesChanged = 0
      foreach ($row in $numstat) {
        $parts2 = $row -split "\s+"
        if ($parts2[0] -match '^\d+$') { $linesChanged += [int]$parts2[0] + [int]$parts2[1] }
      }

      if ($filesChanged -eq 0) {
        Add-BF-Debt -Area "Fix" -Title "$id — no diff produced" `
          -Description "Apply-patch chosen but no working-tree changes" `
          -Impact "Fix not applied; bug still open"
        $deferred.Add($id); $outcome = "deferred"
        Remove-Item -Path $patchFile -ErrorAction SilentlyContinue
      } else {
        $rejected = $false
        if (Test-BF-Auto) {
          if ($filesChanged -gt [int]$MaxFiles) {
            Add-BF-Debt -Area "Fix" -Title "$id exceeds file limit" `
              -Description "Patch touches $filesChanged files (limit $MaxFiles)" `
              -Impact "Patch not committed; review manually"
            if (-not (Test-BF-DryRun)) { git -C $RepoRoot reset --hard HEAD 2>$null | Out-Null }
            $deferred.Add($id); $outcome = "rejected-size"; $rejected = $true
          } elseif ($linesChanged -gt [int]$MaxLines) {
            Add-BF-Debt -Area "Fix" -Title "$id exceeds line limit" `
              -Description "Patch touches $linesChanged lines (limit $MaxLines)" `
              -Impact "Patch not committed; review manually"
            if (-not (Test-BF-DryRun)) { git -C $RepoRoot reset --hard HEAD 2>$null | Out-Null }
            $deferred.Add($id); $outcome = "rejected-size"; $rejected = $true
          }
        }
        if (-not $rejected) {
          if (-not (Test-BF-DryRun)) {
            git -C $RepoRoot add -A 2>$null | Out-Null
            $typePrefix = switch ($source) { "csdebt" {"security"} "cqdebt" {"refactor"} default {"fix"} }
            $msg = "${typePrefix}(${id}): ${title}"
            git -C $RepoRoot commit -m $msg 2>$null | Out-Null
            $commitSha = (git -C $RepoRoot rev-parse --short HEAD 2>$null).Trim()
          } else { $commitSha = "(dry-run)" }
          $fixed.Add($id); $commits.Add($commitSha); $outcome = "applied"
          Add-Content -Path $AllPatches -Value "# === $bfId — $id ==="
          Get-Content $patchFile | Add-Content -Path $AllPatches
          Add-Content -Path $AllPatches -Value "`n"
        }
      }
    }
    "skip"  { $skipped.Add($id);  $outcome = "skipped" }
    "defer" {
      Add-BF-Debt -Area "Fix" -Title "$id deferred" `
        -Description "Operator chose to defer this item" `
        -Impact "Bug remains open; re-triage next round"
      $deferred.Add($id); $outcome = "deferred"
    }
  }

  $section = @"
## ${bfId}: ${id} — ${title}

| Field | Value |
|---|---|
| Resolves | $id |
| Source | $source |
| Severity | $severity |
| Priority | $priority |
| Component | $(if ($component) { $component } else { 'unknown' }) |
| Outcome | $outcome |
$(if ($outcome -eq 'applied') {
"| Files changed | $filesChanged |
| Lines changed | $linesChanged |
| Branch | $FixBranch |
| Commit | $commitSha |

### Diff

``````diff
$(Get-Content $patchFile -Raw)
``````"
})

---

"@
  Add-Content -Path $OutputFile -Value $section -Encoding UTF8
}

$fixedStr    = if ($fixed.Count -gt 0) { [string]::Join(",", $fixed) } else { "(none)" }
$deferredStr = if ($deferred.Count -gt 0) { [string]::Join(",", $deferred) } else { "(none)" }
$skippedStr  = if ($skipped.Count -gt 0) { [string]::Join(",", $skipped) } else { "(none)" }
$commitsStr  = if ($commits.Count -gt 0) { [string]::Join(",", $commits) } else { "(none)" }

Write-BF-Extract -Path $ExtractFile -Pairs @{
  FIXED_IDS         = $fixedStr
  DEFERRED_IDS      = $deferredStr
  SKIPPED_IDS       = $skippedStr
  BRANCH            = $FixBranch
  COMMITS           = $commitsStr
  DRY_RUN           = $(if (Test-BF-DryRun) { 1 } else { 0 })
  PATCH_DIR         = $PatchDir
  CONSOLIDATED_PATCH = $AllPatches
}

Write-BF-SuccessRule "✅ Phase 2 Complete"
Write-Host "  Fixed:    $fixedStr"
Write-Host "  Deferred: $deferredStr"
Write-Host "  Skipped:  $skippedStr"
Write-Host "  Branch:   $FixBranch"
Write-Host "  Markdown: $OutputFile"
Write-Host "  Patches:  $PatchDir/"
Write-Host "`nNext: Phase 3 — pwsh <SKILL_DIR>/bf-regression/scripts/regression.ps1`n"
