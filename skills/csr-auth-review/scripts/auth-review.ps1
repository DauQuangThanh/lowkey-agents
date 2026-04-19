#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:CSR_AUTO = '1' }
if ($Answers) { $env:CSR_ANSWERS = $Answers }


$OutputFile = "$script:CSROutputDir\02-auth-review.md"

Write-CSR-Banner "PHASE 2: AUTHENTICATION & AUTHORIZATION REVIEW"

@'
# Authentication & Authorization Review

This document assesses authentication mechanisms, password policies, MFA implementation, RBAC design, session management, and token handling.

## Executive Summary

- **Auth Mechanism:** [TBD]
- **Password Policy Strength:** [TBD]
- **MFA Status:** [TBD]
- **RBAC Design Completeness:** [TBD]

## Questions & Answers

'@ | Set-Content -Path $OutputFile -Encoding UTF8

# Question 1: Authentication Mechanism
$AuthMechanism = Ask-CSR-Choice "What is the primary authentication mechanism?" @(
  "Session-based (Cookies)"
  "JWT"
  "OAuth 2.0"
  "SAML"
  "API Keys"
  "Multi-factor (combination)"
  "Other"
)

# Question 2: Password Policy
Write-Host ""
$PasswordPolicy = Ask-CSR-Text "Describe the password policy (min length, complexity, expiration, history):"

# Question 3: MFA Implementation
Write-Host ""
$MfaStatus = Ask-CSR-Choice "Is Multi-Factor Authentication (MFA) implemented?" @(
  "Yes, enforced for all users"
  "Yes, optional"
  "Yes, for admins only"
  "No"
)

# Question 4: RBAC Design
Write-Host ""
$Rbac = Ask-CSR-Text "How are roles and permissions defined? (describe RBAC design or 'undefined'):"

# Question 5: Session Management
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Session Management: How are sessions handled?$([char]27)[0m"
$SessionTimeout = Ask-CSR-Text "  • Session timeout duration:"
$SessionInvalidation = Ask-CSR-Text "  • Logout/invalidation mechanism (immediate, graceful, etc.):"
$SessionFixation = Ask-CSR-YN "  • Is session fixation protection implemented?"

# Question 6: Token Handling
Write-Host ""
Write-Host "$([char]27)[1;33m▶ Token Handling (if JWT/OAuth/API keys)$([char]27)[0m"
$TokenStorage = Ask-CSR-Text "  • Where are tokens stored? (memory, localStorage, sessionStorage, secure cookie, etc.):"
$TokenExpiry = Ask-CSR-Text "  • Token expiration time (access token, refresh token):"
$TokenRefresh = Ask-CSR-YN "  • Is token rotation/refresh mechanism implemented?"
$TokenSigning = Ask-CSR-Text "  • Token signing algorithm (RS256, HS256, etc.):"

# Build final report
$Report = @"

### Authentication Mechanism
**Answer:** $AuthMechanism

### Password Policy
**Answer:** $PasswordPolicy

### Multi-Factor Authentication (MFA)
**Answer:** $MfaStatus

### Role-Based Access Control (RBAC) Design
**Answer:** $Rbac

### Session Management
- **Timeout Duration:** $SessionTimeout
- **Logout/Invalidation:** $SessionInvalidation
- **Session Fixation Protection:** $SessionFixation

### Token Handling
- **Storage Method:** $TokenStorage
- **Expiration Times:** $TokenExpiry
- **Token Rotation Implemented:** $TokenRefresh
- **Signing Algorithm:** $TokenSigning

## Security Findings & Checklist

### Critical Controls
- [ ] Authentication enforces strong password policy (min 12 chars, complexity, no dictionary words)
- [ ] MFA is enforced for admin and sensitive accounts
- [ ] Session tokens are stored securely (not in localStorage for web)
- [ ] Sessions invalidate upon logout immediately
- [ ] Token expiration times are reasonable (access: 15-60min, refresh: 7-30 days)
- [ ] RBAC is clearly defined with least-privilege principle
- [ ] Authentication failures are logged (not exposing user existence)
- [ ] Password reset flow validates identity (email + OTP, security questions, etc.)
- [ ] HTTPS/TLS is enforced for all auth flows
- [ ] Session fixation and CSRF protections are in place

### Recommendations
1. **Implement MFA** if not already enforced for sensitive accounts.
2. **Use secure token storage** (httpOnly, secure, sameSite cookies for web).
3. **Enforce strong password requirements** and consider passkey/passwordless authentication.
4. **Implement session timeout with activity tracking** to prevent session abuse.
5. **Log all authentication events** (successful and failed) for audit trails.
6. **Conduct security testing** for auth bypass, session fixation, credential stuffing.
7. **Use OWASP Authentication Cheat Sheet** for implementation guidance.

---
*Assessment completed at: $(Get-Date)*
"@

Add-Content -Path $OutputFile -Value $Report -Encoding UTF8

Write-CSR-SuccessRule "Phase 2 Complete: Authentication & Authorization Review saved."
Write-Host "$([char]27)[0;32m  Output: $OutputFile$([char]27)[0m"
