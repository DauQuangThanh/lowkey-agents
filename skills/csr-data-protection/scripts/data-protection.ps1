#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:CSR_AUTO = '1' }
if ($Answers) { $env:CSR_ANSWERS = $Answers }


$OutputFile = "$script:CSROutputDir\03-data-protection.md"

Write-CSR-Banner "PHASE 3: DATA PROTECTION & PRIVACY REVIEW"

@'
# Data Protection & Privacy Review

This document assesses sensitive data handling, encryption at rest and in transit, data masking, retention policies, and compliance with privacy frameworks.

## Executive Summary

- **Sensitive Data Types Handled:** [TBD]
- **Encryption at Rest:** [TBD]
- **Encryption in Transit:** [TBD]
- **Compliance Status:** [TBD]

## Questions & Answers

'@ | Set-Content -Path $OutputFile -Encoding UTF8

# Question 1: Sensitive Data Types
$DataTypes = Ask-CSR-Choice "What types of sensitive data does the application handle?" @(
  "PII"
  "PHI"
  "PCI-DSS"
  "Credentials"
  "Proprietary Business Data"
  "Multiple types"
  "None"
)

# Question 2: Encryption at Rest
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Encryption at Rest (database, file storage)$([char]27)[0m"
$EncryptionAtRest = Ask-CSR-YN "  • Is encryption at rest implemented?"
$EncryptionAlgorithm = Ask-CSR-Text "  • Encryption algorithm (AES-256, TDE, etc.) or 'N/A':"
$KeyManagement = Ask-CSR-Text "  • Key management solution (HSM, AWS KMS, Vault, etc.) or 'manual':"

# Question 3: Encryption in Transit (TLS)
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Encryption in Transit (network communication)$([char]27)[0m"
$TlsEnforced = Ask-CSR-YN "  • Is HTTPS/TLS enforced for all sensitive data transmission?"
$TlsVersion = Ask-CSR-Text "  • Minimum TLS version (1.2, 1.3, etc.):"
$CertificatePinning = Ask-CSR-YN "  • Is certificate pinning implemented (especially for mobile)?"

# Question 4: Data Masking & Tokenization
Write-Host ""
$DataMasking = Ask-CSR-Text "Is data masking or tokenization used in logs/backups/lower environments? (describe or 'none'):"

# Question 5: Data Retention Policy
Write-Host ""
$RetentionPolicy = Ask-CSR-Text "What is the data retention policy? (e.g., '2 years', 'lifetime', 'event-based'):"

# Question 6: Compliance Requirements
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Compliance Requirements$([char]27)[0m"
$Gdpr = Ask-CSR-YN "  • Subject to GDPR (EU users or operations)?"
$Hipaa = Ask-CSR-YN "  • Subject to HIPAA (healthcare data)?"
$PciDss = Ask-CSR-YN "  • Subject to PCI-DSS (payment processing)?"
$Soc2 = Ask-CSR-YN "  • Subject to SOC2 compliance?"
$OtherCompliance = Ask-CSR-Text "  • Other compliance requirements (or 'none'):"

# Build final report
$Report = @"

### Sensitive Data Types
**Answer:** $DataTypes

### Encryption at Rest
- **Implemented:** $EncryptionAtRest
- **Algorithm:** $EncryptionAlgorithm
- **Key Management:** $KeyManagement

### Encryption in Transit
- **HTTPS/TLS Enforced:** $TlsEnforced
- **Minimum TLS Version:** $TlsVersion
- **Certificate Pinning:** $CertificatePinning

### Data Masking & Tokenization
**Answer:** $DataMasking

### Data Retention Policy
**Answer:** $RetentionPolicy

### Compliance Requirements
- **GDPR:** $Gdpr
- **HIPAA:** $Hipaa
- **PCI-DSS:** $PciDss
- **SOC2:** $Soc2
- **Other:** $OtherCompliance

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
*Assessment completed at: $(Get-Date)*
"@

Add-Content -Path $OutputFile -Value $Report -Encoding UTF8

Write-CSR-SuccessRule "Phase 3 Complete: Data Protection & Privacy Review saved."
Write-Host "$([char]27)[0;32m  Output: $OutputFile$([char]27)[0m"
