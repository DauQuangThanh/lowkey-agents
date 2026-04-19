#!/bin/bash
# =============================================================================
# auth-review.sh — Phase 2: Authentication & Authorization Review
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
csr_parse_flags "$@"


OUTPUT_FILE="$CSR_OUTPUT_DIR/02-auth-review.md"

csr_banner "PHASE 2: AUTHENTICATION & AUTHORIZATION REVIEW"

# Initialize output file
cat > "$OUTPUT_FILE" << 'EOF'
# Authentication & Authorization Review

This document assesses authentication mechanisms, password policies, MFA implementation, RBAC design, session management, and token handling.

## Executive Summary

- **Auth Mechanism:** [TBD]
- **Password Policy Strength:** [TBD]
- **MFA Status:** [TBD]
- **RBAC Design Completeness:** [TBD]

## Questions & Answers

EOF

# Question 1: Authentication Mechanism
printf '%b▶ What is the primary authentication mechanism?%b\n' "$CSR_YELLOW" "$CSR_NC"
printf '  1) Session-based (Cookies)\n'
printf '  2) JWT (JSON Web Tokens)\n'
printf '  3) OAuth 2.0\n'
printf '  4) SAML\n'
printf '  5) API Keys\n'
printf '  6) Multi-factor (combination)\n'
printf '  7) Other\n'
AUTH_MECHANISM=$(csr_ask_choice "Select authentication mechanism:" "Session-based (Cookies)" "JWT" "OAuth 2.0" "SAML" "API Keys" "Multi-factor (combination)" "Other")

# Question 2: Password Policy
printf '\n'
PASSWORD_POLICY=$(csr_ask "Describe the password policy (min length, complexity, expiration, history):")

# Question 3: MFA Implementation
printf '\n'
MFA_STATUS=$(csr_ask_choice "Is Multi-Factor Authentication (MFA) implemented?" "Yes, enforced for all users" "Yes, optional" "Yes, for admins only" "No")

# Question 4: RBAC Design
printf '\n'
RBAC=$(csr_ask "How are roles and permissions defined? (describe RBAC design or 'undefined'):")

# Question 5: Session Management
printf '\n'
printf '%b▶ Session Management: How are sessions handled?%b\n' "$CSR_YELLOW" "$CSR_NC"
SESSION_TIMEOUT=$(csr_ask "  • Session timeout duration:")
SESSION_INVALIDATION=$(csr_ask "  • Logout/invalidation mechanism (immediate, graceful, etc.):")
SESSION_FIXATION=$(csr_ask_yn "  • Is session fixation protection implemented?")

# Question 6: Token Handling
printf '\n'
printf '%b▶ Token Handling (if JWT/OAuth/API keys):)%b\n' "$CSR_YELLOW" "$CSR_NC"
TOKEN_STORAGE=$(csr_ask "  • Where are tokens stored? (memory, localStorage, sessionStorage, secure cookie, etc.):")
TOKEN_EXPIRY=$(csr_ask "  • Token expiration time (access token, refresh token):")
TOKEN_REFRESH=$(csr_ask_yn "  • Is token rotation/refresh mechanism implemented?")
TOKEN_SIGNING=$(csr_ask "  • Token signing algorithm (RS256, HS256, etc.):")

# Build final report
cat >> "$OUTPUT_FILE" << EOF

### Authentication Mechanism
**Answer:** $AUTH_MECHANISM

### Password Policy
**Answer:** $PASSWORD_POLICY

### Multi-Factor Authentication (MFA)
**Answer:** $MFA_STATUS

### Role-Based Access Control (RBAC) Design
**Answer:** $RBAC

### Session Management
- **Timeout Duration:** $SESSION_TIMEOUT
- **Logout/Invalidation:** $SESSION_INVALIDATION
- **Session Fixation Protection:** $SESSION_FIXATION

### Token Handling
- **Storage Method:** $TOKEN_STORAGE
- **Expiration Times:** $TOKEN_EXPIRY
- **Token Rotation Implemented:** $TOKEN_REFRESH
- **Signing Algorithm:** $TOKEN_SIGNING

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
*Assessment completed at: $(date)*
EOF

csr_success_rule "Phase 2 Complete: Authentication & Authorization Review saved."
printf '%b  Output: %s%b\n' "$CSR_GREEN" "$OUTPUT_FILE" "$CSR_NC"
