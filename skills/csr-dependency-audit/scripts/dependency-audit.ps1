#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:CSR_AUTO = '1' }
if ($Answers) { $env:CSR_ANSWERS = $Answers }


$OutputFile = "$script:CSROutputDir\04-dependency-audit.md"

Write-CSR-Banner "PHASE 4: DEPENDENCY & SUPPLY CHAIN AUDIT"

@'
# Dependency & Supply Chain Audit

This document assesses package manager usage, dependency scanning tools, known vulnerabilities, license compliance, and supply chain security practices.

## Executive Summary

- **Package Managers in Use:** [TBD]
- **Dependency Scanning Tool:** [TBD]
- **Known Vulnerable Dependencies:** [TBD]
- **License Compliance Status:** [TBD]

## Questions & Answers

'@ | Set-Content -Path $OutputFile -Encoding UTF8

# Question 1: Package Managers in Use
Write-Host "$([char]27)[1;33m▶ What package managers are used in this project? (enter comma-separated list)$([char]27)[0m"
Write-Host "  Examples: npm, pip, maven, gradle, rubygems, nuget, go, cargo, composer"
$PkgManagers = Ask-CSR-Text "List the package managers or 'none':"

# Question 2: Dependency Scanning Tool
Write-Host ""
$ScanningTool = Ask-CSR-Choice "What tool is used for dependency vulnerability scanning?" @(
  "Snyk"
  "GitHub Dependabot"
  "OWASP Dependency-Check"
  "Trivy"
  "WhiteSource/Mend"
  "None - manual review"
  "Other"
)

# Question 3: Known Vulnerable Dependencies
Write-Host ""
$KnownVulns = Ask-CSR-Text "Are there any known vulnerable dependencies currently in the project? (list or 'none'):"

# Question 4: License Compliance Requirements
Write-Host ""
$LicenseCheck = Ask-CSR-YN "Is license compliance being monitored? (e.g., SPDX, commercial license restrictions)"

# Question 5: Supply Chain Security Measures
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Supply Chain Security Practices$([char]27)[0m"
$Lockfiles = Ask-CSR-YN "  • Are lock files (package-lock.json, Pipfile.lock, etc.) version-controlled?"
$IntegrityCheck = Ask-CSR-YN "  • Are package integrity checks enforced (SHA/hash verification)?"
$Provenance = Ask-CSR-YN "  • Is package provenance verification implemented (SLSA, in-toto, etc.)?"

# Question 6: Update & Patch Cadence
Write-Host ""
$UpdateCadence = Ask-CSR-Text "What is the dependency update cadence? (e.g., 'weekly', 'monthly', 'ad-hoc'):"

# Build final report
$Report = @"

### Package Managers in Use
**Answer:** $PkgManagers

### Dependency Vulnerability Scanning
**Tool:** $ScanningTool

### Known Vulnerable Dependencies
**Answer:** $KnownVulns

### License Compliance Monitoring
**Answer:** $LicenseCheck

### Supply Chain Security Measures
- **Lock Files Version-Controlled:** $Lockfiles
- **Package Integrity Checks:** $IntegrityCheck
- **Provenance Verification:** $Provenance

### Dependency Update Cadence
**Answer:** $UpdateCadence

## Findings Summary

Supply chain security is critical for preventing transitive dependency attacks and maintaining code integrity. This assessment captures current practices and identifies gaps.

## Security Checklist

### Dependency Management
- [ ] All dependencies are listed in manifest files (package.json, requirements.txt, pom.xml, etc.)
- [ ] Lock files are version-controlled and committed to repository
- [ ] Direct dependencies are minimized (no over-importing)
- [ ] Unused dependencies are removed regularly
- [ ] Major version constraints are documented for compatibility reasons

### Vulnerability Scanning
- [ ] SAST/dependency scanning tool is integrated in CI/CD pipeline
- [ ] Scans run on every commit or at least daily
- [ ] High/Critical vulnerabilities block build
- [ ] Medium vulnerabilities are tracked and scheduled for remediation
- [ ] Scan reports are retained for audit trail

### License Compliance
- [ ] All dependencies have documented licenses
- [ ] License compatibility with project license is verified
- [ ] Commercial/restricted licenses are identified and approved
- [ ] License changes in dependency updates are tracked

### Supply Chain Integrity
- [ ] Package integrity verification is enabled (checksum validation)
- [ ] Package sources are trusted repositories (not mirrored/proxied without verification)
- [ ] Private packages/modules are signed if applicable
- [ ] Dependency resolution is deterministic (no floating version constraints)

### Update & Patching
- [ ] Security patches are applied promptly (within 24-48 hours for critical)
- [ ] Update automation (Dependabot, Renovate) is configured
- [ ] Test coverage is sufficient to catch breaking changes
- [ ] Incident response plan exists for supply chain compromises

## Recommendations

1. **Enable Automated Dependency Scanning** (Snyk, Dependabot, or Trivy) in CI/CD.
2. **Enforce Lock Files** — commit and use lock files for reproducible builds.
3. **Implement Version Pinning** — avoid floating/wildcard version constraints.
4. **Monitor for Supply Chain Attacks** — watch for suspicious version releases, unusual changes in maintainer activity.
5. **Establish Patch Management SLA** — critical: 24 hours, high: 1 week, medium: 30 days.
6. **License Compliance Review** — document all third-party dependencies and their licenses.
7. **Use Private/Trusted Registries** — consider proxying public registries through a private mirror for additional control.
8. **SBOM Generation** — generate Software Bill of Materials (SBOM) in SPDX/CycloneDX format.

---
*Assessment completed at: $(Get-Date)*
"@

Add-Content -Path $OutputFile -Value $Report -Encoding UTF8

Write-CSR-SuccessRule "Phase 4 Complete: Dependency & Supply Chain Audit saved."
Write-Host "$([char]27)[0;32m  Output: $OutputFile$([char]27)[0m"
