#!/bin/bash
# =============================================================================
# data-protection.sh — Phase 3: Data Protection & Privacy Review
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
csr_parse_flags "$@"


OUTPUT_FILE="$CSR_OUTPUT_DIR/03-data-protection.md"

csr_banner "PHASE 3: DATA PROTECTION & PRIVACY REVIEW"

# Initialize output file
cat > "$OUTPUT_FILE" << 'EOF'
# Data Protection & Privacy Review

This document assesses sensitive data handling, encryption at rest and in transit, data masking, retention policies, and compliance with privacy frameworks.

## Executive Summary

- **Sensitive Data Types Handled:** [TBD]
- **Encryption at Rest:** [TBD]
- **Encryption in Transit:** [TBD]
- **Compliance Status:** [TBD]

## Questions & Answers

EOF

# Question 1: Sensitive Data Types
printf '%b▶ What types of sensitive data does the application handle?%b\n' "$CSR_YELLOW" "$CSR_NC"
printf '  1) PII (Personally Identifiable Information: name, email, phone, address)\n'
printf '  2) PHI (Protected Health Information: medical records, diagnoses)\n'
printf '  3) PCI-DSS (Payment Card Industry: credit/debit card data)\n'
printf '  4) Credentials (passwords, API keys, tokens)\n'
printf '  5) Proprietary Business Data\n'
printf '  6) Multiple types (select all that apply)\n'
printf '  7) None - no sensitive data\n'
DATA_TYPES=$(csr_ask_choice "Select sensitive data types:" "PII" "PHI" "PCI-DSS" "Credentials" "Proprietary Business Data" "Multiple types" "None")

# Question 2: Encryption at Rest
printf '\n'
printf '%b▶ Encryption at Rest (database, file storage):)%b\n' "$CSR_YELLOW" "$CSR_NC"
ENCRYPTION_AT_REST=$(csr_ask_yn "  • Is encryption at rest implemented?")
ENCRYPTION_ALGORITHM=$(csr_ask "  • Encryption algorithm (AES-256, TDE, etc.) or 'N/A':")
KEY_MANAGEMENT=$(csr_ask "  • Key management solution (HSM, AWS KMS, Vault, etc.) or 'manual':")

# Question 3: Encryption in Transit (TLS)
printf '\n'
printf '%b▶ Encryption in Transit (network communication):)%b\n' "$CSR_YELLOW" "$CSR_NC"
TLS_ENFORCED=$(csr_ask_yn "  • Is HTTPS/TLS enforced for all sensitive data transmission?")
TLS_VERSION=$(csr_ask "  • Minimum TLS version (1.2, 1.3, etc.):")
CERTIFICATE_PINNING=$(csr_ask_yn "  • Is certificate pinning implemented (especially for mobile)?")

# Question 4: Data Masking & Tokenization
printf '\n'
DATA_MASKING=$(csr_ask "Is data masking or tokenization used in logs/backups/lower environments? (describe or 'none'):")

# Question 5: Data Retention Policy
printf '\n'
RETENTION_POLICY=$(csr_ask "What is the data retention policy? (e.g., '2 years', 'lifetime', 'event-based'):")

# Question 6: Compliance Requirements
printf '\n'
printf '%b▶ Compliance Requirements:)%b\n' "$CSR_YELLOW" "$CSR_NC"
GDPR=$(csr_ask_yn "  • Subject to GDPR (EU users or operations)?")
HIPAA=$(csr_ask_yn "  • Subject to HIPAA (healthcare data)?")
PCI_DSS=$(csr_ask_yn "  • Subject to PCI-DSS (payment processing)?")
SOC2=$(csr_ask_yn "  • Subject to SOC2 compliance?")
OTHER_COMPLIANCE=$(csr_ask "  • Other compliance requirements (or 'none'):")

# Build final report
cat >> "$OUTPUT_FILE" << EOF

### Sensitive Data Types
**Answer:** $DATA_TYPES

### Encryption at Rest
- **Implemented:** $ENCRYPTION_AT_REST
- **Algorithm:** $ENCRYPTION_ALGORITHM
- **Key Management:** $KEY_MANAGEMENT

### Encryption in Transit
- **HTTPS/TLS Enforced:** $TLS_ENFORCED
- **Minimum TLS Version:** $TLS_VERSION
- **Certificate Pinning:** $CERTIFICATE_PINNING

### Data Masking & Tokenization
**Answer:** $DATA_MASKING

### Data Retention Policy
**Answer:** $RETENTION_POLICY

### Compliance Requirements
- **GDPR:** $GDPR
- **HIPAA:** $HIPAA
- **PCI-DSS:** $PCI_DSS
- **SOC2:** $SOC2
- **Other:** $OTHER_COMPLIANCE

## Security & Privacy Checklist

### Critical Controls
- [ ] All sensitive data is encrypted at rest (AES-256 or equivalent)
- [ ] Encryption keys are managed securely (HSM, KMS, or Vault)
- [ ] Key rotation policy is defined and implemented
- [ ] All data in transit uses TLS 1.2+ with strong cipher suites
- [ ] Certificate pinning is implemented for mobile/API clients
- [ ] Sensitive data is masked in logs, backups, and non-production environments
- [ ] Data retention policy is documented and enforced
- [ ] User data can be deleted upon request (right to be forgotten)
- [ ] Data classification scheme exists (public, internal, confidential, restricted)
- [ ] Third-party data processors have data processing agreements (DPA)

### Compliance Checklist
If GDPR: [ ] Privacy notice, [ ] Consent management, [ ] DPA with processors, [ ] DPIA for high-risk processing, [ ] Breach notification process (72 hours)
If HIPAA: [ ] BAA with all processors, [ ] Access controls & audit logs, [ ] Encryption at rest & in transit, [ ] Business continuity plan
If PCI-DSS: [ ] Network segmentation, [ ] Encryption of cardholder data, [ ] Secure deletion process, [ ] Annual penetration testing
If SOC2: [ ] Access controls, [ ] Audit logging, [ ] Change management, [ ] Incident response procedures

### Recommendations
1. **Conduct Data Classification** — identify all sensitive data and apply appropriate protections.
2. **Implement Secrets Management** — use Vault, AWS Secrets Manager, or equivalent for credentials.
3. **Enforce TLS 1.2+** with modern cipher suites; disable older TLS versions.
4. **Implement Data Masking** in logs, test data, and backups to prevent accidental exposure.
5. **Define & Enforce Retention Policies** with automated deletion where possible.
6. **Establish Data Processing Agreements** with all third-party vendors.
7. **Conduct Privacy Impact Assessment (PIA)** for new features handling sensitive data.
8. **Regular Security Audits** of data flows and encryption implementation.

---
*Assessment completed at: $(date)*
EOF

csr_success_rule "Phase 3 Complete: Data Protection & Privacy Review saved."
printf '%b  Output: %s%b\n' "$CSR_GREEN" "$OUTPUT_FILE" "$CSR_NC"
