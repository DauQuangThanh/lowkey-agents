#Requires -Version 5.1
# =============================================================================
# standards.ps1 — Phase 1: Coding Standards Review (PowerShell)
#
# Usage:
#   pwsh <SKILL_DIR>/cqr-standards/scripts/standards.ps1 [-Auto] [-Answers <file>]
#
# Outputs:
#   - $CQROutputDir/01-standards-review.md
#   - $CQROutputDir/01-standards-review.extract
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/_common.ps1"

if ($Auto) { $env:CQR_AUTO = '1'; $script:CQRAuto = $true }
if ($Answers) { $env:CQR_ANSWERS = $Answers; $script:CQRAnswers = $Answers }

$OutputFile  = Join-Path $script:CQROutputDir "01-standards-review.md"
$ExtractFile = Join-Path $script:CQROutputDir "01-standards-review.extract"

$DefLanguage   = "JavaScript/TypeScript"
$DefStyle      = "Airbnb (JavaScript)"
$DefNaming     = "PascalCase classes + camelCase rest"
$DefStructure  = "By feature (users/, products/, ...)"
$DefImports    = "Stdlib → third-party → local"
$DefDocs       = "Google docstrings / JSDoc"
$DefLinter     = "ESLint + Prettier"
$DefDeviations = "None"

Write-CQR-Banner "Phase 1: Coding Standards Review"

if (Test-CQR-Auto) {
  Write-Host "`n[Auto mode] Reading from upstream + answers file; no prompts.`n"
} else {
  Write-Host @"

Eight numbered-choice questions. Pick a number, choose "Other — specify" to enter
a custom value, or "Not sure" to accept a documented default and log a debt.

"@
}

function Resolve-OrDefault {
  param([string]$Value, [string]$OtherKey, [string]$Default, [string]$Area, [string]$KeyName)
  if ($Value -eq "Other — specify") {
    return (Get-CQR-Answer -Key $OtherKey -Prompt "Specify:" -Default $Default)
  } elseif ($Value -like "Not sure*") {
    Add-CQR-DebtAuto -Area $Area -Title "$KeyName not confirmed" `
      -Description "User did not confirm $KeyName" -Impact "Defaulting to $Default"
    return $Default
  }
  return $Value
}

$LANGUAGE = Get-CQR-Choice -Key "LANGUAGE" -Prompt "Primary language:" -Options @(
  "JavaScript","TypeScript","Python","Go","Java","C#","Rust","Ruby","PHP",
  "Other — specify","Not sure — use default ($DefLanguage) and log debt")
$LANGUAGE = Resolve-OrDefault $LANGUAGE "LANGUAGE_SPECIFY" $DefLanguage "Standards" "LANGUAGE"

$STYLE = Get-CQR-Choice -Key "STYLE" -Prompt "Style guide:" -Options @(
  "PEP 8 (Python)","Black (Python)","Airbnb (JavaScript)","Google (multi-language)",
  "Standard JS","Microsoft (C#/.NET)","Go conventions (Effective Go)","Custom internal guide",
  "Other — specify","Not sure — use default ($DefStyle) and log debt")
$STYLE = Resolve-OrDefault $STYLE "STYLE_SPECIFY" $DefStyle "Standards" "STYLE"

$NAMING = Get-CQR-Choice -Key "NAMING" -Prompt "Naming convention bundle:" -Options @(
  "All camelCase","All snake_case",
  "PascalCase classes + camelCase functions/variables",
  "PascalCase classes + snake_case functions/variables",
  "Mixed by file / language",
  "Other — specify","Not sure — use default ($DefNaming) and log debt")
$NAMING = Resolve-OrDefault $NAMING "NAMING_SPECIFY" $DefNaming "Standards" "NAMING"

$STRUCTURE = Get-CQR-Choice -Key "STRUCTURE" -Prompt "Folder layout:" -Options @(
  "By layer (controllers/, services/, data/)",
  "By feature (users/, products/, ...)",
  "Domain-driven (entities/, services/, repositories/)",
  "Flat (everything in src/)",
  "Monorepo with packages",
  "Other — specify","Not sure — use default ($DefStructure) and log debt")
$STRUCTURE = Resolve-OrDefault $STRUCTURE "STRUCTURE_SPECIFY" $DefStructure "Standards" "STRUCTURE"

$IMPORTS = Get-CQR-Choice -Key "IMPORTS" -Prompt "Import ordering:" -Options @(
  "Stdlib → third-party → local","Alphabetical (all)",
  "Grouped by type, unordered within","None enforced",
  "Other — specify","Not sure — use default ($DefImports) and log debt")
$IMPORTS = Resolve-OrDefault $IMPORTS "IMPORTS_SPECIFY" $DefImports "Standards" "IMPORTS"

$DOCS = Get-CQR-Choice -Key "DOCS" -Prompt "Documentation format:" -Options @(
  "JSDoc (JavaScript)","Google docstrings (Python)","NumPy docstrings (Python)",
  "Sphinx (Python)","XML doc comments (C#/.NET)","GoDoc (Go)",
  "Inline comments only (WHY, not WHAT)","None required",
  "Other — specify","Not sure — use default ($DefDocs) and log debt")
$DOCS = Resolve-OrDefault $DOCS "DOCS_SPECIFY" $DefDocs "Standards" "DOCS"

$LINTER = Get-CQR-Choice -Key "LINTER" -Prompt "Linter / formatter:" -Options @(
  "ESLint + Prettier","Pylint + Black","Ruff + Black",
  "golangci-lint + gofmt","Checkstyle + Spotless (Java)",
  "StyleCop + Roslyn analyzers (C#)","Rustfmt + Clippy (Rust)",
  "None / ad hoc","Other — specify",
  "Not sure — use default ($DefLinter) and log debt")
$LINTER = Resolve-OrDefault $LINTER "LINTER_SPECIFY" $DefLinter "Standards" "LINTER"

$DEVIATIONS = Get-CQR-Answer -Key "DEVIATIONS" -Prompt "Known deviations (press Enter for 'None'):" -Default $DefDeviations
if (-not $DEVIATIONS) { $DEVIATIONS = $DefDeviations }

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mode = if (Test-CQR-Auto) { "Auto" } else { "Interactive" }

$md = @"
# Phase 1: Coding Standards Review

**Timestamp:** $timestamp
**Status:** Complete
**Mode:** $mode

## Standards Baseline

| Standard | Value |
|---|---|
| **Language(s)** | $LANGUAGE |
| **Style Guide** | $STYLE |
| **Naming Conventions** | $NAMING |
| **File Structure** | $STRUCTURE |
| **Import Ordering** | $IMPORTS |
| **Documentation** | $DOCS |
| **Linting Tools** | $LINTER |
| **Known Deviations** | $DEVIATIONS |

## Next Phase

Run: ``pwsh <SKILL_DIR>/cqr-complexity/scripts/complexity.ps1``

---
"@

$md | Out-File -Path $OutputFile -Encoding UTF8 -Force

Write-CQR-Extract -Path $ExtractFile -Pairs @{
  LANGUAGE   = $LANGUAGE
  STYLE      = $STYLE
  NAMING     = $NAMING
  STRUCTURE  = $STRUCTURE
  IMPORTS    = $IMPORTS
  DOCS       = $DOCS
  LINTER     = $LINTER
  DEVIATIONS = $DEVIATIONS
}

Write-CQR-SuccessRule
Write-Host "✅ Phase 1 Complete."
Write-Host "  Markdown: $OutputFile"
Write-Host "  Extract:  $ExtractFile"
Write-Host "`nNext: Phase 2 — pwsh <SKILL_DIR>/cqr-complexity/scripts/complexity.ps1`n"
