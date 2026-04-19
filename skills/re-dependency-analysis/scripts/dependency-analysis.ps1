# =============================================================================
# Phase 5: Dependency & Integration Map (PowerShell)
# Parses common package manifests for direct dependency counts.
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

if ($Auto)    { $env:RE_AUTO    = '1' }
if ($Answers) { $env:RE_ANSWERS = $Answers }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "_common.ps1")

if (Get-Command Invoke-RE-ParseFlags -ErrorAction SilentlyContinue) {
  Invoke-RE-ParseFlags -Args $args
}

Initialize-RE-DebtFile
$OutputFile  = Join-Path $script:REOutputDir "05-dependency-map.md"
$ExtractFile = Join-Path $script:REOutputDir "05-dependency-map.extract"

$SourceRoot = Get-RE-Answer -Key "SOURCE_ROOT" -Prompt "Source root" -Default "."
if (-not (Test-RE-Path $SourceRoot)) {
  Write-RE-Error "Cannot analyse dependencies: SOURCE_ROOT invalid"
  exit 1
}

Write-RE-Info "Phase 5: Cataloguing dependencies in $SourceRoot"

$manifestsFound = New-Object System.Collections.Generic.List[string]
$directTotal = 0
$devTotal    = 0

$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$lines = @(
  "# Phase 5: Dependency & Integration Map",
  "",
  "**Generated:** $now",
  "**Source root:** ``$SourceRoot``",
  ""
)

# ── Node.js: package.json ────────────────────────────────────────────────────
$pkgJson = Join-Path $SourceRoot "package.json"
if (Test-Path $pkgJson) {
  $manifestsFound.Add("package.json") | Out-Null
  try {
    $pj = Get-Content $pkgJson -Raw | ConvertFrom-Json
    $deps = if ($pj.dependencies) { $pj.dependencies.PSObject.Properties } else { @() }
    $devs = if ($pj.devDependencies) { $pj.devDependencies.PSObject.Properties } else { @() }
    $nDeps = ($deps | Measure-Object).Count
    $nDev  = ($devs | Measure-Object).Count
    $directTotal += $nDeps
    $devTotal    += $nDev

    $lines += "## Node.js (``package.json``)"
    $lines += ""
    $lines += "- Runtime dependencies: $nDeps"
    $lines += "- Dev dependencies: $nDev"
    $lines += ""
    if ($nDeps -gt 0) {
      $lines += "### Runtime"
      $lines += ""
      $lines += '```json'
      foreach ($d in $deps) { $lines += """$($d.Name)"": ""$($d.Value)""" }
      $lines += '```'
      $lines += ""
    }
    if ($nDev -gt 0) {
      $lines += "### Dev"
      $lines += ""
      $lines += '```json'
      foreach ($d in $devs) { $lines += """$($d.Name)"": ""$($d.Value)""" }
      $lines += '```'
      $lines += ""
    }
  } catch {
    $lines += "## Node.js (``package.json``)"
    $lines += ""
    $lines += "_Could not parse JSON: $($_.Exception.Message)_"
    $lines += ""
  }
}

# ── Python: requirements.txt / pyproject.toml ────────────────────────────────
$reqTxt = Join-Path $SourceRoot "requirements.txt"
if (Test-Path $reqTxt) {
  $manifestsFound.Add("requirements.txt") | Out-Null
  $content = Get-Content $reqTxt -ErrorAction SilentlyContinue
  $n = ($content | Where-Object { $_ -match '^[a-zA-Z0-9_.-]+' } | Measure-Object).Count
  $directTotal += $n
  $lines += "## Python (``requirements.txt``)"
  $lines += ""
  $lines += "- Direct dependencies: $n"
  $lines += ""
  $lines += '```text'
  $lines += ($content | Select-Object -First 50)
  $lines += '```'
  $lines += ""
}
$pyprojectToml = Join-Path $SourceRoot "pyproject.toml"
if (Test-Path $pyprojectToml) {
  $manifestsFound.Add("pyproject.toml") | Out-Null
  $lines += "## Python (``pyproject.toml``)"
  $lines += ""
  $lines += '```toml'
  $lines += (Get-Content $pyprojectToml -ErrorAction SilentlyContinue | Select-Object -First 80)
  $lines += '```'
  $lines += ""
}

# ── Go modules ───────────────────────────────────────────────────────────────
$goMod = Join-Path $SourceRoot "go.mod"
if (Test-Path $goMod) {
  $manifestsFound.Add("go.mod") | Out-Null
  $content = Get-Content $goMod -ErrorAction SilentlyContinue
  $n = ($content | Where-Object { $_ -match '^\s*[a-z].*v\d' } | Measure-Object).Count
  $directTotal += $n
  $lines += "## Go (``go.mod``)"
  $lines += ""
  $lines += '```go'
  $lines += ($content | Select-Object -First 50)
  $lines += '```'
  $lines += ""
}

# ── Rust / Cargo ─────────────────────────────────────────────────────────────
$cargoToml = Join-Path $SourceRoot "Cargo.toml"
if (Test-Path $cargoToml) {
  $manifestsFound.Add("Cargo.toml") | Out-Null
  $lines += "## Rust (``Cargo.toml``)"
  $lines += ""
  $lines += '```toml'
  $lines += (Get-Content $cargoToml -ErrorAction SilentlyContinue | Select-Object -First 80)
  $lines += '```'
  $lines += ""
}

# ── Java: pom.xml ────────────────────────────────────────────────────────────
$pom = Join-Path $SourceRoot "pom.xml"
if (Test-Path $pom) {
  $manifestsFound.Add("pom.xml") | Out-Null
  $content = Get-Content $pom -Raw -ErrorAction SilentlyContinue
  $n = ([regex]::Matches($content, '<dependency>') | Measure-Object).Count
  $directTotal += $n
  $lines += "## Java (``pom.xml``)"
  $lines += ""
  $lines += "- Declared dependencies: $n"
  $lines += ""
}

# ── Ruby: Gemfile ────────────────────────────────────────────────────────────
$gemfile = Join-Path $SourceRoot "Gemfile"
if (Test-Path $gemfile) {
  $manifestsFound.Add("Gemfile") | Out-Null
  $content = Get-Content $gemfile -ErrorAction SilentlyContinue
  $n = ($content | Where-Object { $_ -match "^\s*gem [""']" } | Measure-Object).Count
  $directTotal += $n
  $lines += "## Ruby (``Gemfile``)"
  $lines += ""
  $lines += "- Direct gems: $n"
  $lines += ""
}

# ── Summary ──────────────────────────────────────────────────────────────────
$lines += "## Summary"
$lines += ""
$lines += "- Manifests found: $($manifestsFound.Count)"
$lines += "- Total direct dependencies (across all manifests): $directTotal"
$lines += "- Total dev dependencies: $devTotal"
$lines += ""
if ($manifestsFound.Count -eq 0) {
  $lines += "_No package manifests found. The project may have zero external dependencies_"
  $lines += "_(common for static HTML/CSS/JS apps) or use an unusual build system._"
  $lines += ""
}
$lines += "## Notes"
$lines += ""
$lines += "Only direct (declared) dependencies are counted. Transitive/full dependency"
$lines += "graph, outdated-package analysis, and vulnerability scanning are out of scope for"
$lines += "this phase — use dedicated tools (``npm audit``, ``pip-audit``, ``cargo audit``, etc.)."
$lines += ""

Set-Content -Path $OutputFile -Value $lines -Encoding UTF8

Write-RE-Extract -Path $ExtractFile -Pairs @{
  "MANIFESTS"   = ($manifestsFound -join ",")
  "DIRECT_DEPS" = $directTotal
  "DEV_DEPS"    = $devTotal
}

if ($manifestsFound.Count -eq 0) {
  Add-RE-DebtAuto -Area "Dependencies" -Title "No package manifest detected" `
    -Description "Neither package.json, requirements.txt, go.mod, pom.xml, Cargo.toml nor Gemfile found in $SourceRoot" `
    -Impact "Project may be dependency-free; confirm manually"
}

Write-RE-Success "Phase 5 complete — $OutputFile"
Write-Host ""
Write-Host "Output: $OutputFile"
