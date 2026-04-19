# =============================================================================
# Phase 2: Architecture Reverse Engineering (PowerShell)
# Detects tech stack, layer structure, frameworks, and deployment artefacts.
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
$OutputFile  = Join-Path $script:REOutputDir "02-architecture.md"
$ExtractFile = Join-Path $script:REOutputDir "02-architecture.extract"

$SourceRoot = Get-RE-Answer -Key "SOURCE_ROOT" -Prompt "Source root" -Default "."
if (-not (Test-RE-Path $SourceRoot)) {
  Write-RE-Error "Cannot analyse architecture: SOURCE_ROOT invalid"
  exit 1
}

Write-RE-Info "Phase 2: Extracting architecture from $SourceRoot"

# ── Framework / tech stack detection ─────────────────────────────────────────
$frameworks = New-Object System.Collections.Generic.List[string]
function Detect-File {
  param([string]$Name, [string]$Label)
  $hit = Get-ChildItem -Path $SourceRoot -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue `
           -Filter $Name | Select-Object -First 1
  if ($hit) { $frameworks.Add($Label) | Out-Null }
}
Detect-File "package.json"        "Node.js / npm project"
Detect-File "tsconfig.json"       "TypeScript"
Detect-File "pyproject.toml"      "Python (PEP 621)"
Detect-File "requirements.txt"    "Python (pip)"
Detect-File "Pipfile"             "Python (pipenv)"
Detect-File "poetry.lock"         "Python (poetry)"
Detect-File "go.mod"              "Go modules"
Detect-File "Cargo.toml"          "Rust (cargo)"
Detect-File "pom.xml"             "Java (Maven)"
Detect-File "build.gradle"        "Java/Kotlin (Gradle)"
Detect-File "Gemfile"             "Ruby (Bundler)"
Detect-File "composer.json"       "PHP (Composer)"
Detect-File "mix.exs"             "Elixir (mix)"
Detect-File "Dockerfile"          "Docker"
Detect-File "docker-compose.yml"  "Docker Compose"
Detect-File "docker-compose.yaml" "Docker Compose"

$gitHubActionsDir = Join-Path $SourceRoot ".github\workflows"
if (Test-Path $gitHubActionsDir) { $frameworks.Add("GitHub Actions") | Out-Null }

$pkgJson = Join-Path $SourceRoot "package.json"
if (Test-Path $pkgJson) {
  $pjContent = Get-Content $pkgJson -Raw -ErrorAction SilentlyContinue
  if ($pjContent -match '"react"')        { $frameworks.Add("React") | Out-Null }
  if ($pjContent -match '"vue"')          { $frameworks.Add("Vue") | Out-Null }
  if ($pjContent -match '"@angular/')     { $frameworks.Add("Angular") | Out-Null }
  if ($pjContent -match '"next"')         { $frameworks.Add("Next.js") | Out-Null }
  if ($pjContent -match '"express"')      { $frameworks.Add("Express") | Out-Null }
  if ($pjContent -match '"fastify"')      { $frameworks.Add("Fastify") | Out-Null }
  if ($pjContent -match '"@nestjs/|"nestjs"') { $frameworks.Add("NestJS") | Out-Null }
}

# ── Layer / package structure ────────────────────────────────────────────────
$layers = New-Object System.Collections.Generic.List[string]
$commonLayers = @(
  "controllers","services","models","views","routes","api","handlers",
  "middleware","repositories","domain","entities","components","pages",
  "utils","lib","core","infra","infrastructure","config","tests","test",
  "__tests__","spec"
)
foreach ($l in $commonLayers) {
  $found = Get-ChildItem -Path $SourceRoot -Directory -Recurse -Depth 4 -Force `
             -ErrorAction SilentlyContinue -Filter $l | Select-Object -First 1
  if ($found) { $layers.Add($l) | Out-Null }
}

# ── Deployment artefacts ─────────────────────────────────────────────────────
$deployment = New-Object System.Collections.Generic.List[string]
if (Test-Path (Join-Path $SourceRoot "Dockerfile"))          { $deployment.Add("Dockerfile") | Out-Null }
if (Test-Path (Join-Path $SourceRoot "docker-compose.yml"))  { $deployment.Add("docker-compose.yml") | Out-Null }
if (Test-Path (Join-Path $SourceRoot "docker-compose.yaml")) { $deployment.Add("docker-compose.yaml") | Out-Null }
if (Test-Path (Join-Path $SourceRoot ".github\workflows"))   { $deployment.Add("GitHub Actions workflows") | Out-Null }
if (Test-Path (Join-Path $SourceRoot ".circleci"))           { $deployment.Add(".circleci") | Out-Null }
if (Test-Path (Join-Path $SourceRoot ".gitlab-ci.yml"))      { $deployment.Add(".gitlab-ci.yml") | Out-Null }
if (Test-Path (Join-Path $SourceRoot "Jenkinsfile"))         { $deployment.Add("Jenkinsfile") | Out-Null }
if ((Test-Path (Join-Path $SourceRoot "k8s")) -or (Test-Path (Join-Path $SourceRoot "kubernetes"))) {
  $deployment.Add("Kubernetes manifests") | Out-Null
}
$terraform = Get-ChildItem -Path $SourceRoot -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue `
                -Filter "*.tf" | Select-Object -First 1
if ($terraform) { $deployment.Add("Terraform") | Out-Null }

# ── Write output ─────────────────────────────────────────────────────────────
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$lines = @(
  "# Phase 2: Architecture Extraction",
  "",
  "**Generated:** $now",
  "**Source root:** ``$SourceRoot``",
  "",
  "## Detected Frameworks & Tech Stack",
  ""
)
if ($frameworks.Count -gt 0) {
  foreach ($f in $frameworks) { $lines += "- $f" }
} else {
  $lines += "_No known framework markers detected (static files / raw source only)._"
}
$lines += ""
$lines += "## Layer Structure"
$lines += ""
if ($layers.Count -gt 0) {
  $lines += "Directories matching common architectural layers:"
  $lines += ""
  foreach ($l in $layers) { $lines += "- ``$l/``" }
} else {
  $lines += "_No conventional layer directories found. The project likely has a flat or custom structure._"
}
$lines += ""
$lines += "## Deployment Artefacts"
$lines += ""
if ($deployment.Count -gt 0) {
  foreach ($d in $deployment) { $lines += "- $d" }
} else {
  $lines += "_No deployment manifests found. Project may rely on external CI or static hosting._"
}
$lines += ""
$lines += "## Notes"
$lines += ""
$lines += "Detection is marker-based and best-effort. Entries are proof of presence, not of good design."
$lines += "See ``07-re-debts.md`` for anything that could not be determined."
$lines += ""
Set-Content -Path $OutputFile -Value $lines -Encoding UTF8

Write-RE-Extract -Path $ExtractFile -Pairs @{
  "FRAMEWORKS" = ($frameworks -join ",")
  "LAYERS"     = ($layers -join ",")
  "DEPLOYMENT" = ($deployment -join ",")
}

if ($frameworks.Count -eq 0 -and $layers.Count -eq 0) {
  Add-RE-DebtAuto -Area "Architecture" -Title "No architectural markers detected" `
    -Description "Neither framework manifests nor layer directories were found in $SourceRoot" `
    -Impact "Architecture cannot be inferred from the tree; manual review needed"
}

Write-RE-Success "Phase 2 complete — $OutputFile"
Write-Host ""
Write-Host "Output: $OutputFile"
