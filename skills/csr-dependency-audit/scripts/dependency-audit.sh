#!/bin/bash
# =============================================================================
# dependency-audit.sh — Phase 4: Dependency & Supply Chain Audit
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
csr_parse_flags "$@"


OUTPUT_FILE="$CSR_OUTPUT_DIR/04-dependency-audit.md"

csr_banner "PHASE 4: DEPENDENCY & SUPPLY CHAIN AUDIT"

# Initialize output file
cat > "$OUTPUT_FILE" << 'EOF'
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

EOF

# Question 1: Package Managers in Use
printf '%b▶ What package managers are used in this project? (select all that apply)%b\n' "$CSR_YELLOW" "$CSR_NC"
printf '  1) npm/yarn (Node.js)\n'
printf '  2) pip (Python)\n'
printf '  3) Maven (Java)\n'
printf '  4) Gradle (Java/Android)\n'
printf '  5) RubyGems (Ruby)\n'
printf '  6) Nuget (.NET)\n'
printf '  7) Go Modules (Go)\n'
printf '  8) Cargo (Rust)\n'
printf '  9) Composer (PHP)\n'
printf '  10) Other\n'
PKG_MANAGERS=$(csr_ask "List the package managers (comma-separated) or 'none':")

# Question 2: Dependency Scanning Tool (SCA)
printf '\n'
SCANNING_TOOL=$(csr_ask_choice "What tool is used for dependency / SCA vulnerability scanning?" \
  "Snyk" \
  "GitHub Dependabot" \
  "OWASP Dependency-Check" \
  "OWASP Dependency-Track" \
  "Trivy" \
  "WhiteSource/Mend" \
  "None - manual review" \
  "Other")

# Question 3: Known Vulnerable Dependencies
printf '\n'
KNOWN_VULNS=$(csr_ask "Are there any known vulnerable dependencies currently in the project? (list or 'none'):")

# Question 4: License Compliance Requirements
printf '\n'
LICENSE_CHECK=$(csr_ask_yn "Is license compliance being monitored? (e.g., SPDX, commercial license restrictions)")

# Question 5: Supply Chain Security Measures
printf '\n'
printf '%b▶ Supply Chain Security Practices:%b\n' "$CSR_YELLOW" "$CSR_NC"
LOCKFILES=$(csr_ask_yn "  • Are lock files (package-lock.json, Pipfile.lock, etc.) version-controlled?")
INTEGRITY_CHECK=$(csr_ask_yn "  • Are package integrity checks enforced (SHA/hash verification, signed packages)?")
PROVENANCE=$(csr_ask_yn "  • Is package provenance verification implemented (SLSA, in-toto, etc.)?")
TRANSITIVE=$(csr_ask_yn "  • Are transitive dependencies explicitly tracked and scanned (not just direct ones)?")
TRUSTED_SOURCES=$(csr_ask_yn "  • Are components sourced only from trusted / official registries over secure links?")

# Question 6: SBOM (NEW for A03:2025)
printf '\n'
SBOM=$(csr_ask_choice "Is a Software Bill of Materials (SBOM) generated for this project?" \
  "Yes — SPDX format, updated on every build" \
  "Yes — CycloneDX format, updated on every build" \
  "Yes — generated on release only" \
  "Yes — ad-hoc / manual" \
  "No")

# Question 7: Build Pipeline & Developer-Tooling Hardening (A03:2025)
printf '\n'
printf '%b▶ Build Pipeline & Developer-Tooling Hardening (A03:2025):%b\n' "$CSR_YELLOW" "$CSR_NC"
MFA_REPO=$(csr_ask_yn "  • Is MFA enforced on the source code repository and CI/CD platform?")
PROTECTED_BRANCHES=$(csr_ask_yn "  • Are protected branches + mandatory code review enforced (no solo merges to main)?")
SIGNED_BUILDS=$(csr_ask_yn "  • Are build artifacts signed and immutable (promoted across environments rather than rebuilt)?")
SCOPED_SECRETS=$(csr_ask_yn "  • Are CI/CD secrets environment-scoped and rotated, with tamper-evident build logs?")
STAGED_ROLLOUTS=$(csr_ask_yn "  • Are updates rolled out in stages / canary rather than all-at-once?")

# Question 8: Update & Patch Cadence
printf '\n'
UPDATE_CADENCE=$(csr_ask "What is the dependency update cadence? (e.g., 'weekly', 'monthly', 'ad-hoc'):")

# Build final report
cat >> "$OUTPUT_FILE" << EOF

### Package Managers in Use
**Answer:** $PKG_MANAGERS

### Dependency Vulnerability Scanning
**Tool:** $SCANNING_TOOL

### Known Vulnerable Dependencies
**Answer:** $KNOWN_VULNS

### License Compliance Monitoring
**Answer:** $LICENSE_CHECK

### Supply Chain Security Measures
- **Lock Files Version-Controlled:** $LOCKFILES
- **Package Integrity Checks / Signed Packages:** $INTEGRITY_CHECK
- **Provenance Verification (SLSA / in-toto):** $PROVENANCE
- **Transitive Dependency Tracking:** $TRANSITIVE
- **Trusted Registries Only:** $TRUSTED_SOURCES

### SBOM (Software Bill of Materials)
**Answer:** $SBOM

### Build Pipeline & Developer-Tooling Hardening
- **MFA on Repo / CI/CD:** $MFA_REPO
- **Protected Branches + Mandatory Review:** $PROTECTED_BRANCHES
- **Signed, Immutable Build Artifacts:** $SIGNED_BUILDS
- **Environment-Scoped / Rotated Secrets:** $SCOPED_SECRETS
- **Staged / Canary Rollouts:** $STAGED_ROLLOUTS

### Dependency Update Cadence
**Answer:** $UPDATE_CADENCE

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
- [ ] Branch protection + mandatory code review (separation of duties — no single person ships to prod)
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

1. **Enable Automated SCA Scanning** (Snyk, Dependabot, Trivy, OWASP Dependency-Check or Dependency-Track) in CI/CD — covering direct **and** transitive dependencies.
2. **Generate an SBOM** for every build in SPDX or CycloneDX format; store alongside artifacts.
3. **Subscribe to vulnerability feeds** for the components you actually use — OSV, NVD, GitHub Advisory Database, vendor bulletins.
4. **Enforce Lock Files** — commit and use lock files for reproducible builds.
5. **Implement Version Pinning** — avoid floating/wildcard version constraints.
6. **Prefer Signed Packages + Verify Provenance** — SLSA level targets, in-toto attestations.
7. **Stage Rollouts / Canary Deployments** — limit blast radius if a trusted vendor is compromised (SolarWinds, Shai-Hulud npm worm).
8. **Harden the Build Pipeline** — MFA everywhere, environment-scoped secrets, protected branches, signed/immutable artifacts, tamper-evident logs.
9. **Harden Developer Workstations** — regular patching, MFA, monitoring; developers are themselves prime supply-chain targets.
10. **Establish Patch Management SLA** — critical: 24 hours, high: 1 week, medium: 30 days.
11. **License Compliance Review** — document all third-party dependencies and their licenses.
12. **Use Private/Trusted Registries** — consider proxying public registries through a private mirror for additional control.
13. **Monitor for unmaintained / abandoned dependencies** (CWE-1104) and plan migrations before they become unpatchable.

---
*Assessment completed at: $(date)*
EOF

csr_success_rule "Phase 4 Complete: Dependency & Supply Chain Audit saved."
printf '%b  Output: %s%b\n' "$CSR_GREEN" "$OUTPUT_FILE" "$CSR_NC"
