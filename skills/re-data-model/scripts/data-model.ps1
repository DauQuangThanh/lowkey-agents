# =============================================================================
# Phase 4: Data Model Extraction (PowerShell)
# Detects database engines, ORMs, model files, migrations, and client-side
# storage schemas.
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
$OutputFile  = Join-Path $script:REOutputDir "04-data-model.md"
$ExtractFile = Join-Path $script:REOutputDir "04-data-model.extract"

$SourceRoot = Get-RE-Answer -Key "SOURCE_ROOT" -Prompt "Source root" -Default "."
if (-not (Test-RE-Path $SourceRoot)) {
  Write-RE-Error "Cannot analyse data model: SOURCE_ROOT invalid"
  exit 1
}

Write-RE-Info "Phase 4: Extracting data model from $SourceRoot"

$excludeDirs = @("node_modules",".git","dist","build",".venv","vendor","target")
$allFiles = Get-ChildItem -Path $SourceRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object {
    $f = $_
    foreach ($d in $excludeDirs) {
      if ($f.FullName -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $d + [IO.Path]::DirectorySeparatorChar)) {
        return $false
      }
    }
    return $true
  }
$allPaths = @($allFiles | Select-Object -ExpandProperty FullName)

function Probe {
  param([string]$Pattern, [string]$Label, [ref]$List)
  if (-not $allPaths) { return }
  $hit = Select-String -Path $allPaths -Pattern $Pattern -List -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hit) { $List.Value.Add($Label) | Out-Null }
}

# ── Database engines ─────────────────────────────────────────────────────────
$databases = New-Object System.Collections.Generic.List[string]
Probe 'postgres(ql)?://|psycopg2|PostgreSQL' "PostgreSQL" ([ref]$databases)
Probe 'mysql://|mysql2|mysql\.createConnection' "MySQL" ([ref]$databases)
Probe 'sqlite3?://|sqlite3\.|better-sqlite3' "SQLite" ([ref]$databases)
Probe 'mongodb(\+srv)?://|mongoose\.|MongoClient' "MongoDB" ([ref]$databases)
Probe 'redis://|createClient\(.*redis|Redis\(' "Redis" ([ref]$databases)
Probe 'cassandra://|cassandra-driver' "Cassandra" ([ref]$databases)
Probe 'dynamodb|DynamoDB' "DynamoDB" ([ref]$databases)

# ── ORMs / data-access libraries ─────────────────────────────────────────────
$orms = New-Object System.Collections.Generic.List[string]
Probe 'from sqlalchemy|import sqlalchemy' "SQLAlchemy (Python)" ([ref]$orms)
Probe 'from django\.db|models\.Model' "Django ORM" ([ref]$orms)
Probe '"sequelize"|require\([''"]sequelize' "Sequelize (Node)" ([ref]$orms)
Probe '"mongoose"|require\([''"]mongoose' "Mongoose (Node)" ([ref]$orms)
Probe '"typeorm"|@Entity\(' "TypeORM" ([ref]$orms)
Probe 'PrismaClient|prisma\.[a-z]' "Prisma" ([ref]$orms)
Probe '"@mikro-orm/' "MikroORM" ([ref]$orms)
Probe 'ActiveRecord::Base' "Rails ActiveRecord" ([ref]$orms)
Probe 'gorm\.DB|gorm\.Open' "GORM (Go)" ([ref]$orms)
Probe 'diesel::' "Diesel (Rust)" ([ref]$orms)
Probe '@Entity|@Table\(name' "JPA/Hibernate" ([ref]$orms)

# ── Entity / model files ────────────────────────────────────────────────────
$modelFiles = $allFiles | Where-Object {
  $rel = $_.FullName.Replace($SourceRoot, "")
  ($rel -match '[\\/](?:models|model|entities|entity|schemas|schema)[\\/]') -and
  ($_.Extension -in ".py",".js",".ts",".rb",".go",".java",".kt",".rs")
} | Select-Object -First 100

# ── Migration directories ───────────────────────────────────────────────────
$migrations = New-Object System.Collections.Generic.List[string]
foreach ($d in @("migrations","db\migrate","prisma\migrations","alembic")) {
  if (Get-ChildItem -Path $SourceRoot -Recurse -Directory -Depth 4 -Force `
        -ErrorAction SilentlyContinue -Filter (Split-Path $d -Leaf) | Select-Object -First 1) {
    $migrations.Add($d) | Out-Null
  }
}

# ── Client-side storage schema ──────────────────────────────────────────────
$jsTsHtml = $allFiles | Where-Object { $_.Extension -in ".js",".ts",".html",".htm" }
$storageAccesses = @()
$storageConsts   = @()
if ($jsTsHtml) {
  $storageAccesses = Select-String -Path ($jsTsHtml.FullName) `
    -Pattern '(localStorage|sessionStorage)\.(setItem|getItem|removeItem)\(' -ErrorAction SilentlyContinue
  $storageConstsRaw = Select-String -Path (($jsTsHtml | Where-Object { $_.Extension -in ".js",".ts" }).FullName) `
    -Pattern '^\s*(const|let|var)\s+[A-Z_]+\s*=\s*["'']' -ErrorAction SilentlyContinue
  $storageConsts = $storageConstsRaw | Where-Object { $_.Line -match '(?i)key|storage' }
}

# ── Write output ─────────────────────────────────────────────────────────────
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$lines = @(
  "# Phase 4: Data Model Extraction",
  "",
  "**Generated:** $now",
  "**Source root:** ``$SourceRoot``",
  "",
  "## Detected Databases",
  ""
)
if ($databases.Count -gt 0) { foreach ($d in $databases) { $lines += "- $d" } } else { $lines += "_No database connection markers found._" }
$lines += ""
$lines += "## Detected ORMs / Data-Access Libraries"
$lines += ""
if ($orms.Count -gt 0) { foreach ($o in $orms) { $lines += "- $o" } } else { $lines += "_No ORM markers found._" }
$lines += ""
$lines += "## Model / Entity Files (up to 100 shown)"
$lines += ""
if ($modelFiles) {
  foreach ($m in $modelFiles) {
    $rel = $m.FullName.Replace($SourceRoot, "").TrimStart('\','/')
    $lines += "- ``$rel``"
  }
} else {
  $lines += "_No files found under conventional model/entity/schema directories._"
}
$lines += ""
$lines += "## Migration Directories"
$lines += ""
if ($migrations.Count -gt 0) { foreach ($m in $migrations) { $lines += "- ``$m/``" } } else { $lines += "_No migration directory found._" }
$lines += ""
if (($storageAccesses | Measure-Object).Count -gt 0 -or ($storageConsts | Measure-Object).Count -gt 0) {
  $lines += "## Client-Side Storage Schema"
  $lines += ""
  $lines += "This project uses browser storage APIs. Key definitions and accesses found:"
  $lines += ""
  $lines += '```text'
  $combined = @()
  $combined += $storageConsts
  $combined += $storageAccesses
  $lines += ($combined | Select-Object -First 30 | ForEach-Object {
    $name = Split-Path $_.Path -Leaf
    "$($name):$($_.LineNumber):$($_.Line.Trim())"
  })
  $lines += '```'
  $lines += ""
}
$lines += "## Notes"
$lines += ""
$lines += "Detection is text-based. If a DB is accessed via an abstraction layer that hides"
$lines += "connection strings, it may not appear above — see ``07-re-debts.md``."
$lines += ""
Set-Content -Path $OutputFile -Value $lines -Encoding UTF8

$storageRefCount = ($storageAccesses | Measure-Object).Count
Write-RE-Extract -Path $ExtractFile -Pairs @{
  "DATABASES"             = ($databases -join ",")
  "ORMS"                  = ($orms -join ",")
  "MODEL_FILE_COUNT"      = ($modelFiles | Measure-Object).Count
  "MIGRATION_DIRS"        = ($migrations -join ",")
  "CLIENT_STORAGE_KEY_REFS" = $storageRefCount
}

if ($databases.Count -eq 0 -and $orms.Count -eq 0 -and $storageRefCount -eq 0) {
  Add-RE-DebtAuto -Area "Data Model" -Title "No data layer detected" `
    -Description "No database, ORM, or client-storage markers found in $SourceRoot" `
    -Impact "The project may be stateless; confirm manually"
}

Write-RE-Success "Phase 4 complete — $OutputFile"
Write-Host ""
Write-Host "Output: $OutputFile"
