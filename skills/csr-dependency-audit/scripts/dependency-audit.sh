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

This document assesses package manager usage, dependency scanning tools, known vulnerabilities, license compliance, and supply chain security practices.

## Executive Summary

- **Package Managers in Use:** [TBD]
- **Dependency Scanning Tool:** [TBD]
- **Known Vulnerable Dependencies:** [TBD]
- **License Compliance Status:** [TBD]

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

# Question 2: Dependency Scanning Tool
printf '\n'
SCANNING_TOOL=$(csr_ask_choice "What tool is used for dependency vulnerability scanning?" \
  "Snyk" \
  "GitHub Dependabot" \
  "OWASP Dependency-Check" \
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
INTEGRITY_CHECK=$(csr_ask_yn "  • Are package integrity checks enforced (SHA/hash verification)?")
PROVENANCE=$(csr_ask_yn "  • Is package provenance verification implemented (SLSA, in-toto, etc.)?")

# Question 6: Update & Patch Cadence
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
- **Package Integrity Checks:** $INTEGRITY_CHECK
- **Provenance Verification:** $PROVENANCE

### Dependency Update Cadence
**Answer:** $UPDATE_CADENCE

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
*Assessment completed at: $(date)*
EOF

csr_success_rule "Phase 4 Complete: Dependency & Supply Chain Audit saved."
printf '%b  Output: %s%b\n' "$CSR_GREEN" "$OUTPUT_FILE" "$CSR_NC"
