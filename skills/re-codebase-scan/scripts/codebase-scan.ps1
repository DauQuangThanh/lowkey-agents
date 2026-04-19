# Phase 1: Codebase Discovery & Inventory (PowerShell)
# Scans directory structure and file types to build an inventory

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

# Source common functions
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$script:ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:RE_AUTO = '1' }
if ($Answers) { $env:RE_ANSWERS = $Answers }


# ============================================================================
# Phase 1 Main Execution
# ============================================================================

Write-RE-Banner "PHASE 1: CODEBASE DISCOVERY & INVENTORY"

# Initialize output directory and debt file
Initialize-RE-DebtFile
Write-RE-Info "Output directory: $script:REOutputDir"

# Step 1: Get source code root path
Write-RE-Info "Gathering information about your codebase..."
$sourceRoot = Get-RE-Answer -Key "SOURCE_ROOT" -Prompt "What is the root path of the source code?" -Default "."

if (-not (Test-RE-Path $sourceRoot)) {
    Write-RE-Error "Cannot access source code root"
    exit 1
}

Write-RE-Success "Source code root: $sourceRoot"

# Step 2: Ask about primary languages
$languages = Get-RE-Answer -Key "LANGUAGES" -Prompt "What are the primary programming languages used?" -Default "JavaScript, Python, Java"
Write-RE-Success "Primary languages: $languages"

# Step 3: Ask about project type
$projectTypes = @("Web Application", "REST API", "Mobile App", "Desktop Application", "Library", "Microservices", "Other")
$projectType = Ask-RE-Choice "What is the project type?" $projectTypes
Write-RE-Success "Project type: $projectType"

# Step 4: Ask about build system
$buildSystems = @("npm/yarn", "pip", "Maven", "Gradle", "Cargo", ".NET", "Make", "Other")
$buildSystem = Ask-RE-Choice "What build system is used?" $buildSystems
Write-RE-Success "Build system: $buildSystem"

# Step 5: Ask about repository structure
$repoStructure = Ask-RE-Text "Describe the repository structure (monorepo/multi-repo/nested/standard)" "standard"
Write-RE-Success "Repository structure: $repoStructure"

# Step 6: Ask about known entry points
$entryPoints = Ask-RE-Text "What are the known entry points? (e.g., main.js, src/App.tsx, etc.)" ""
Write-RE-Success "Entry points: $(if ($entryPoints) { $entryPoints } else { "Not specified" })"

# Step 7: Ask about existing documentation
$hasDocs = Ask-RE-YN "Does existing documentation exist?" "n"
$docLocations = ""
if ($hasDocs -eq "yes") {
    $docLocations = Ask-RE-Text "Where is existing documentation located?" "docs/"
    Write-RE-Success "Documentation locations: $docLocations"
}

# Step 8: Ask about areas to focus/skip
$focusAreas = Ask-RE-Text "Areas to focus on or skip? (enter 'none' to skip)" "none"
Write-RE-Success "Focus areas: $focusAreas"

# ============================================================================
# Automated Analysis
# ============================================================================

Write-RE-Info "Starting automated analysis..."

# Create output file
$outputFile = New-RE-File "01-codebase-inventory.md" "Codebase Inventory"

# Count files by extension
Write-RE-Info "Analyzing file distribution..."
Add-RE-FileContent -FilePath $outputFile -Content "## File Statistics`n`n"

# Detect files by extension
$extensions = @("js", "ts", "jsx", "tsx", "py", "java", "go", "rs", "cpp", "c", "h", "cs", "rb", "php")
$fileCounts = @{}

foreach ($ext in $extensions) {
    $count = Get-RE-FileCountByExt -RootDir $sourceRoot -Extension $ext
    if ($count -gt 0) {
        $fileCounts[$ext] = $count
    }
}

# Calculate total LOC
Write-RE-Info "Counting lines of code..."
$totalLOC = Get-RE-LinesOfCode -RootDir $sourceRoot

$totalFiles = (Get-ChildItem -Path $sourceRoot -Recurse -File -ErrorAction SilentlyContinue).Count

Add-RE-FileContent -FilePath $outputFile -Content "- **Total Files**: $totalFiles`n"
Add-RE-FileContent -FilePath $outputFile -Content "- **Total Lines of Code**: $("{0:N0}" -f $totalLOC)`n"
Add-RE-FileContent -FilePath $outputFile -Content "- **Primary Language**: $languages`n`n"

# File type breakdown
Add-RE-FileContent -FilePath $outputFile -Content "## Language Breakdown`n`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Language | Files | % | Est. LOC |`n"
Add-RE-FileContent -FilePath $outputFile -Content "|----------|-------|---|----------|`n"

foreach ($ext in $fileCounts.Keys) {
    $count = $fileCounts[$ext]
    $percent = [math]::Floor(($count * 100) / $totalFiles)
    $estimatedLOC = $count * 30

    $langName = switch ($ext) {
        "js" { "JavaScript" }
        "jsx" { "JavaScript" }
        "ts" { "TypeScript" }
        "tsx" { "TypeScript" }
        "py" { "Python" }
        "java" { "Java" }
        "go" { "Go" }
        "rs" { "Rust" }
        "cpp" { "C++" }
        "cc" { "C++" }
        "c" { "C" }
        "cs" { "C#" }
        "rb" { "Ruby" }
        "php" { "PHP" }
        "h" { "Header Files" }
        default { $ext }
    }

    Add-RE-FileContent -FilePath $outputFile -Content "| $langName | $count | ${percent}% | ~${estimatedLOC} |`n"
}

Add-RE-FileContent -FilePath $outputFile -Content "`n"

# Directory structure
Write-RE-Info "Mapping directory structure..."
Add-RE-FileContent -FilePath $outputFile -Content "## Directory Structure`n`n"
Add-RE-FileContent -FilePath $outputFile -Content "``````n"
Add-RE-FileContent -FilePath $outputFile -Content "$(Show-RE-DirectoryTree -RootDir $sourceRoot -MaxDepth 2)`n"
Add-RE-FileContent -FilePath $outputFile -Content "``````n`n"

# Configuration files
Write-RE-Info "Finding configuration files..."
Add-RE-FileContent -FilePath $outputFile -Content "## Configuration Files Detected`n`n"

$configFiles = Find-RE-ConfigFiles -RootDir $sourceRoot
if ($configFiles.Count -eq 0) {
    Add-RE-FileContent -FilePath $outputFile -Content "No configuration files found.`n`n"
}
else {
    foreach ($config in $configFiles) {
        $relPath = $config.FullName -replace [regex]::Escape($sourceRoot), ""
        Add-RE-FileContent -FilePath $outputFile -Content "- \`$($relPath.TrimStart('\/\\'))\`"
    }
    Add-RE-FileContent -FilePath $outputFile -Content "`n`n"
}

# Framework detection
Write-RE-Info "Detecting frameworks and libraries..."
Add-RE-FileContent -FilePath $outputFile -Content "## Frameworks & Libraries Detected`n`n"

$packageJsonPath = Join-Path $sourceRoot "package.json"
if (Test-Path $packageJsonPath) {
    Add-RE-FileContent -FilePath $outputFile -Content "### Node.js Ecosystem`n"
    Add-RE-FileContent -FilePath $outputFile -Content "- \`package.json\` found (npm/yarn project)`n`n"
}

$requirementsPath = Join-Path $sourceRoot "requirements.txt"
if (Test-Path $requirementsPath) {
    Add-RE-FileContent -FilePath $outputFile -Content "### Python Ecosystem`n"
    Add-RE-FileContent -FilePath $outputFile -Content "- \`requirements.txt\` found (pip project)`n`n"
}

$pomPath = Join-Path $sourceRoot "pom.xml"
if (Test-Path $pomPath) {
    Add-RE-FileContent -FilePath $outputFile -Content "### Java Ecosystem (Maven)`n"
    Add-RE-FileContent -FilePath $outputFile -Content "- \`pom.xml\` found (Maven project)`n`n"
}

$dockerfilePath = Join-Path $sourceRoot "Dockerfile"
if (Test-Path $dockerfilePath) {
    Add-RE-FileContent -FilePath $outputFile -Content "### Docker`n"
    Add-RE-FileContent -FilePath $outputFile -Content "- \`Dockerfile\` found (containerized application)`n`n"
}

$dockerComposePath = Join-Path $sourceRoot "docker-compose.yml"
if (Test-Path $dockerComposePath) {
    Add-RE-FileContent -FilePath $outputFile -Content "- \`docker-compose.yml\` found (multi-container orchestration)`n`n"
}

# Entry points summary
Add-RE-FileContent -FilePath $outputFile -Content "## Entry Points`n`n"
if ($entryPoints) {
    Add-RE-FileContent -FilePath $outputFile -Content "$entryPoints`n`n"
}
else {
    Add-RE-FileContent -FilePath $outputFile -Content "### Detected Entry Point Candidates`n`n"

    $candidates = @(
        "src/index.js",
        "src/main.js",
        "src/App.tsx",
        "server.js",
        "main.py",
        "src/main/java"
    )

    foreach ($candidate in $candidates) {
        $fullPath = Join-Path $sourceRoot $candidate
        if (Test-Path $fullPath) {
            Add-RE-FileContent -FilePath $outputFile -Content "- \`$candidate\`"
        }
    }
    Add-RE-FileContent -FilePath $outputFile -Content "`n`n"
}

# Documentation summary
Add-RE-FileContent -FilePath $outputFile -Content "## Known Documentation`n`n"
if ($hasDocs -eq "yes" -and $docLocations) {
    Add-RE-FileContent -FilePath $outputFile -Content "Documentation found at: \`$docLocations\`"

    $docPath = Join-Path $sourceRoot $docLocations
    if (Test-Path $docPath) {
        Add-RE-FileContent -FilePath $outputFile -Content "`n`n### Documentation Files`n`n"
        Get-ChildItem -Path $docPath -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
            Add-RE-FileContent -FilePath $outputFile -Content "- \`$($_.Name)\`"
        }
    }
    Add-RE-FileContent -FilePath $outputFile -Content "`n`n"
}
else {
    Add-RE-FileContent -FilePath $outputFile -Content "No existing documentation found.`n`n"
}

# Focus areas
Add-RE-FileContent -FilePath $outputFile -Content "## Focus Areas`n`n"
if ($focusAreas -ne "none" -and $focusAreas) {
    Add-RE-FileContent -FilePath $outputFile -Content "- $focusAreas`n`n"
}
else {
    Add-RE-FileContent -FilePath $outputFile -Content "- Full codebase analysis (no specific areas skipped)`n`n"
}

# Statistics summary
Add-RE-FileContent -FilePath $outputFile -Content "## Summary Statistics`n`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Metric | Value |`n"
Add-RE-FileContent -FilePath $outputFile -Content "|--------|-------|`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Total Files | $totalFiles |`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Total LOC | $totalLOC |`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Project Type | $projectType |`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Build System | $buildSystem |`n"
Add-RE-FileContent -FilePath $outputFile -Content "| Repository Structure | $repoStructure |`n"

# ── Write companion extract so phase 6 can aggregate without re-parsing md ──
$extractFile = [System.IO.Path]::ChangeExtension($outputFile, "extract")
Write-RE-Extract -Path $extractFile -Pairs @{
  "SOURCE_ROOT"      = $sourceRoot
  "LANGUAGES"        = $languages
  "PRIMARY_LANGUAGE" = $languages
  "TOTAL_FILES"      = $totalFiles
  "TOTAL_LOC"        = $totalLOC
  "PROJECT_TYPE"     = $projectType
  "BUILD_SYSTEM"     = $buildSystem
  "REPO_STRUCTURE"   = $repoStructure
}

# ============================================================================
# Phase Complete
# ============================================================================

Write-RE-SuccessRule
Write-RE-Success "Phase 1 complete! Codebase inventory saved to: $outputFile"
Write-RE-Info "Ready for Phase 2: Architecture Extraction"

exit 0
