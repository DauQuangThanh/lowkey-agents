# =============================================================================
# Phase 3: API & Interface Documentation (PowerShell)
# Scans REST / GraphQL / gRPC route definitions and client-side storage use.
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
$OutputFile  = Join-Path $script:REOutputDir "03-api-documentation.md"
$ExtractFile = Join-Path $script:REOutputDir "03-api-documentation.extract"

$SourceRoot = Get-RE-Answer -Key "SOURCE_ROOT" -Prompt "Source root" -Default "."
if (-not (Test-RE-Path $SourceRoot)) {
  Write-RE-Error "Cannot analyse APIs: SOURCE_ROOT invalid"
  exit 1
}

Write-RE-Info "Phase 3: Scanning $SourceRoot for API endpoints"

# Ignore generated / vendor directories.
$excludeDirs = @("node_modules",".git","dist","build",".venv","vendor","target")
function Get-CandidateFiles {
  param([string[]]$Includes)
  Get-ChildItem -Path $SourceRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object {
      $f = $_
      foreach ($d in $excludeDirs) {
        if ($f.FullName -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $d + [IO.Path]::DirectorySeparatorChar)) {
          return $false
        }
      }
      if ($Includes) {
        foreach ($ext in $Includes) { if ($f.Name -like $ext) { return $true } }
        return $false
      }
      return $true
    }
}

$allCode   = Get-CandidateFiles @("*.js","*.ts","*.mjs","*.cjs","*.py","*.java","*.kt","*.rb","*.go","*.rs","*.cs","*.php")
$htmlFiles = Get-CandidateFiles @("*.html","*.htm")

# ── REST route patterns ─────────────────────────────────────────────────────
$restHits = @()
if ($allCode) {
  $restHits += Select-String -Path ($allCode.FullName) -Pattern '^\s*(app|router|api|server)\.(get|post|put|patch|delete|head|options)\(' -ErrorAction SilentlyContinue
  $restHits += Select-String -Path ($allCode.FullName) -Pattern '^\s*@(app|router|api|blueprint|bp)\.(route|get|post|put|patch|delete)\(' -ErrorAction SilentlyContinue
  $restHits += Select-String -Path ($allCode.FullName) -Pattern '^\s*@(Get|Post|Put|Patch|Delete|Request)Mapping\(' -ErrorAction SilentlyContinue
}
$rubyFiles = $allCode | Where-Object { $_.Extension -eq ".rb" }
if ($rubyFiles) {
  $restHits += Select-String -Path ($rubyFiles.FullName) -Pattern "^\s*(get|post|put|patch|delete|match)\s+['`"]" -ErrorAction SilentlyContinue
}
$urlsPy = $allCode | Where-Object { $_.Name -eq "urls.py" }
if ($urlsPy) {
  $restHits += Select-String -Path ($urlsPy.FullName) -Pattern '^\s*(path|re_path|url)\(' -ErrorAction SilentlyContinue
}
$restCount = ($restHits | Measure-Object).Count

# ── GraphQL / gRPC ──────────────────────────────────────────────────────────
$gqlFiles = Get-ChildItem -Path $SourceRoot -Recurse -File -Force -ErrorAction SilentlyContinue `
              -Include "*.graphql","*.gql"
$gqlCount = ($gqlFiles | Measure-Object).Count

$gqlInline = 0
$jsTsFiles = $allCode | Where-Object { $_.Extension -in ".js",".ts" }
if ($jsTsFiles) {
  $gqlInlineHits = Select-String -Path ($jsTsFiles.FullName) `
                     -Pattern 'type\s+(Query|Mutation|Subscription)\s*\{' -List -ErrorAction SilentlyContinue
  $gqlInline = ($gqlInlineHits | Measure-Object).Count
}
$protoFiles = Get-ChildItem -Path $SourceRoot -Recurse -File -Force -ErrorAction SilentlyContinue -Filter "*.proto"
$protoCount = ($protoFiles | Measure-Object).Count

# ── Client-side storage usage ───────────────────────────────────────────────
$storageCandidates = @($jsTsFiles) + $htmlFiles
$storageHits = 0
if ($storageCandidates) {
  $storageMatches = Select-String -Path ($storageCandidates.FullName) `
    -Pattern 'localStorage\.|sessionStorage\.|indexedDB\.' -List -ErrorAction SilentlyContinue
  $storageHits = ($storageMatches | Measure-Object).Count
}

# ── Write output ─────────────────────────────────────────────────────────────
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$lines = @(
  "# Phase 3: API & Interface Documentation",
  "",
  "**Generated:** $now",
  "**Source root:** ``$SourceRoot``",
  "",
  "## Summary",
  "",
  "| Interface type | Count |",
  "|---|---|",
  "| REST route definitions | $restCount |",
  "| GraphQL schema files   | $gqlCount |",
  "| GraphQL inline SDL     | $gqlInline |",
  "| gRPC ``.proto`` files     | $protoCount |",
  "| Client-side storage uses | $storageHits |",
  ""
)

if ($restCount -gt 0) {
  $lines += "## REST Endpoints (first 50)"
  $lines += ""
  $lines += '```text'
  $lines += ($restHits | Select-Object -First 50 | ForEach-Object { "$($_.Filename):$($_.LineNumber):$($_.Line.Trim())" })
  $lines += '```'
  $lines += ""
  if ($restCount -gt 50) {
    $lines += "_Showing 50 of $restCount matches._"
    $lines += ""
  }
}
if ($gqlCount -gt 0) {
  $lines += "## GraphQL Schemas"
  $lines += ""
  foreach ($f in $gqlFiles) {
    $rel = $f.FullName.Replace($SourceRoot, "").TrimStart('\','/')
    $lines += "- ``$rel``"
  }
  $lines += ""
}
if ($protoCount -gt 0) {
  $lines += "## gRPC Definitions"
  $lines += ""
  foreach ($f in $protoFiles) {
    $rel = $f.FullName.Replace($SourceRoot, "").TrimStart('\','/')
    $lines += "- ``$rel``"
  }
  $lines += ""
}
if ($restCount -eq 0 -and $gqlCount -eq 0 -and $gqlInline -eq 0 -and $protoCount -eq 0) {
  $lines += "## No Server APIs Found"
  $lines += ""
  if ($storageHits -gt 0) {
    $lines += "The codebase has no detectable server-side API surface."
    $lines += "However, $storageHits file(s) use browser storage APIs"
    $lines += "(``localStorage`` / ``sessionStorage`` / ``indexedDB``) — this is likely a"
    $lines += "client-only application whose ""API"" is the browser storage contract."
  } else {
    $lines += "No server-side API surface nor client storage usage detected."
    $lines += "The project may be a library, a static site, or an asset bundle."
  }
  $lines += ""
}

Set-Content -Path $OutputFile -Value $lines -Encoding UTF8

Write-RE-Extract -Path $ExtractFile -Pairs @{
  "REST_ROUTE_COUNT"     = $restCount
  "GRAPHQL_SCHEMA_COUNT" = $gqlCount
  "GRAPHQL_INLINE_COUNT" = $gqlInline
  "GRPC_PROTO_COUNT"     = $protoCount
  "CLIENT_STORAGE_FILES" = $storageHits
}

if ($restCount -eq 0 -and $gqlCount -eq 0 -and $gqlInline -eq 0 -and $protoCount -eq 0 -and $storageHits -eq 0) {
  Add-RE-DebtAuto -Area "API Surface" -Title "No API patterns detected" `
    -Description "No REST routes, GraphQL SDL, .proto files, or client storage uses found in $SourceRoot" `
    -Impact "If this project exposes an API, the detection patterns don't match it"
}

Write-RE-Success "Phase 3 complete — $OutputFile"
Write-Host ""
Write-Host "Output: $OutputFile"
