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

This document is the primary evidence base for **OWASP A03:2025 Software Supply Chain Failures**. It assesses package manager usage, SCA / dependency scanning tools, known (direct and transitive) vulnerable dependencies, SBOM coverage, license compliance, signing / provenance, build-pipeline and developer-tooling hardening, and patch management practices.

## Executive Summary

- **Package Managers in Use:** [TBD]
- **Dependency Scanning Tool:** [TBD]
- **Known Vulnerable Dependencies:** [TBD]
- **SBOM Status:** [TBD]
- **License Compliance Status:** [TBD]
- **Build Pipeline Hardening:** [TBD]

## Questions & Answers

'@ | Set-Content -Path $OutputFile -Encoding UTF8

# Question 1: Package Managers in Use
Write-Host "$([char]27)[1;33m▶ What package managers are used in this project? (enter comma-separated list)$([char]27)[0m"
Write-Host "  Examples: npm, pip, maven, gradle, rubygems, nuget, go, cargo, composer"
$PkgManagers = Ask-CSR-Text "List the package managers or 'none':"

# Question 2: Dependency Scanning Tool (SCA)
Write-Host ""
$ScanningTool = Ask-CSR-Choice "What tool is used for dependency / SCA vulnerability scanning?" @(
  "Snyk"
  "GitHub Dependabot"
  "OWASP Dependency-Check"
  "OWASP Dependency-Track"
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
$IntegrityCheck = Ask-CSR-YN "  • Are package integrity checks enforced (SHA/hash verification, signed packages)?"
$Provenance = Ask-CSR-YN "  • Is package provenance verification implemented (SLSA, in-toto, etc.)?"
$Transitive = Ask-CSR-YN "  • Are transitive dependencies explicitly tracked and scanned (not just direct ones)?"
$TrustedSources = Ask-CSR-YN "  • Are components sourced only from trusted / official registries over secure links?"

# Question 6: SBOM (NEW for A03:2025)
Write-Host ""
$Sbom = Ask-CSR-Choice "Is a Software Bill of Materials (SBOM) generated for this project?" @(
  "Yes - SPDX format, updated on every build"
  "Yes - CycloneDX format, updated on every build"
  "Yes - generated on release only"
  "Yes - ad-hoc / manual"
  "No"
)

# Question 7: Build Pipeline & Developer-Tooling Hardening (A03:2025)
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Build Pipeline & Developer-Tooling Hardening (A03:2025)$([char]27)[0m"
$MfaRepo = Ask-CSR-YN "  • Is MFA enforced on the source code repository and CI/CD platform?"
$ProtectedBranches = Ask-CSR-YN "  • Are protected branches + mandatory code review enforced (no solo merges to main)?"
$SignedBuilds = Ask-CSR-YN "  • Are build artifacts signed and immutable (promoted across environments rather than rebuilt)?"
$ScopedSecrets = Ask-CSR-YN "  • Are CI/CD secrets environment-scoped and rotated, with tamper-evident build logs?"
$StagedRollouts = Ask-CSR-YN "  • Are updates rolled out in stages / canary rather than all-at-once?"

# Question 8: Update & Patch Cadence
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
- **Package Integrity Checks / Signed Packages:** $IntegrityCheck
- **Provenance Verification (SLSA / in-toto):** $Provenance
- **Transitive Dependency Tracking:** $Transitive
- **Trusted Registries Only:** $TrustedSources

### SBOM (Software Bill of Materials)
**Answer:** $Sbom

### Build Pipeline & Developer-Tooling Hardening
- **MFA on Repo / CI/CD:** $MfaRepo
- **Protected Branches + Mandatory Review:** $ProtectedBranches
- **Signed, Immutable Build Artifacts:** $SignedBuilds
- **Environment-Scoped / Rotated Secrets:** $ScopedSecrets
- **Staged / Canary Rollouts:** $StagedRollouts

### Dependency Update Cadence
**Answer:** $UpdateCadence

## Findings Summary

Supply chain security is critical for preventing transitive dependency attacks, malicious package updates (e.g., npm "Shai-Hulud" worm, SolarWinds, Log4Shell), and compromised build pipelines. This assessment captures current practices and identifies gaps against OWASP A03:2025 Software Supply Chain Failures.

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
- [ ] Package integrity verification is enabled (checksum validation, signed packages preferred)
- [ ] Package sources are trusted repositories (not mirrored/proxied without verification)
- [ ] Private packages/modules are signed if applicable
- [ ] Dependency resolution is deterministic (no floating version constraints)
- [ ] SBOM is generated for every build (SPDX or CycloneDX)
- [ ] Transitive dependencies are tracked, not just direct ones
- [ ] Provenance (SLSA, in-toto) is verified for critical artifacts
- [ ] Updates are staged / canaried rather than pushed to all systems simultaneously

### Build Pipeline & Developer-Tooling Hardening (A03:2025)
- [ ] MFA enforced on source code repository and CI/CD platform
- [ ] Branch protection + mandatory code review (separation of duties - no single person ships to prod)
- [ ] Build artifacts are signed and immutable; promoted across envs rather than rebuilt
- [ ] CI/CD secrets are environment-scoped, rotated, and never logged
- [ ] Build logs are tamper-evident
- [ ] IaC is under version control and reviewed like application code
- [ ] Developer workstations and IDE/IDE extensions are patched regularly
- [ ] Code repository, sandboxes, and artifact registries are inventoried and access-controlled

### Update & Patching
- [ ] Security patches are applied promptly (within 24-48 hours for critical)
- [ ] Update automation (Dependabot, Renovate) is configured
- [ ] Test coverage is sufficient to catch breaking changes from patches
- [ ] Incident response plan exists for supply chain compromises

## Recommendations

1. **Enable Automated SCA Scanning** (Snyk, Dependabot, Trivy, OWASP Dependency-Check or Dependency-Track) in CI/CD - covering direct **and** transitive dependencies.
2. **Generate an SBOM** for every build in SPDX or CycloneDX format; store alongside artifacts.
3. **Subscribe to vulnerability feeds** for the components you actually use - OSV, NVD, GitHub Advisory Database, vendor bulletins.
4. **Enforce Lock Files** - commit and use lock files for reproducible builds.
5. **Implement Version Pinning** - avoid floating/wildcard version constraints.
6. **Prefer Signed Packages + Verify Provenance** - SLSA level targets, in-toto attestations.
7. **Stage Rollouts / Canary Deployments** - limit blast radius if a trusted vendor is compromised (SolarWinds, Shai-Hulud npm worm).
8. **Harden the Build Pipeline** - MFA everywhere, environment-scoped secrets, protected branches, signed/immutable artifacts, tamper-evident logs.
9. **Harden Developer Workstations** - regular patching, MFA, monitoring; developers are themselves prime supply-chain targets.
10. **Establish Patch Management SLA** - critical: 24 hours, high: 1 week, medium: 30 days.
11. **License Compliance Review** - document all third-party dependencies and their licenses.
12. **Use Private/Trusted Registries** - consider proxying public registries through a private mirror for additional control.
13. **Monitor for unmaintained / abandoned dependencies** (CWE-1104) and plan migrations before they become unpatchable.

---
*Assessment completed at: $(Get-Date)*
"@

Add-Content -Path $OutputFile -Value $Report -Encoding UTF8

Write-CSR-SuccessRule "Phase 4 Complete: Dependency & Supply Chain Audit saved."
Write-Host "$([char]27)[0;32m  Output: $OutputFile$([char]27)[0m"
