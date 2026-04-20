---
name: ta-rubric
description: Reference rubric for the Test Architect — output templates for phases 1–5 plus the shared knowledge base (test pyramid, common automation frameworks comparison, ISTQB test levels and types, glossary) and three worked examples (startup / regulated / high-scale). Read this skill when you need the exact markdown layout to emit, or the canonical definition of a testing term the agent uses in a numbered-choice prompt.
license: MIT
compatibility: Content-only skill; no scripts. Read directly when writing any `ta-output/` markdown.
allowed-tools: Read
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "ref"
---

# Test Architect — Rubric, Templates & Knowledge Base

This skill holds the reference content the `test-architect` agent uses when
writing output files or looking up testing terminology. It has no scripts —
read the relevant section and emit the template verbatim (with placeholders
filled).

## When to use

Read this skill whenever the agent needs to:

- Emit the markdown body of `ta-output/01-test-strategy.md`, `02-automation-framework.md`, `03-coverage-matrix.md`, `04-quality-gates.md`, or `05-environment-plan.md`
- Look up a testing term or acronym (BDD, POM, ISTQB level, flaky test, etc.)
- Cite a framework from the common-frameworks comparison table
- Reference one of the three worked examples (startup / regulated / high-scale) when tailoring a strategy

Sections below: (1) Output Templates (Phases 1–5), (2) Knowledge Base (test
pyramid, frameworks table, ISTQB levels/types, glossary), (3) Examples.

---

# 1. Output Templates

## Template: Test Strategy (Phase 1)

```markdown
# 1. Test Strategy

**Project:** [Name]
**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Role/Name]

## Overview

[Executive summary: What testing will we do? Why? What are the constraints?]

## 1.1 Test Approach

We will use **[Risk-based | Requirement-based | Exploratory | Hybrid]** testing because:
- [Reason 1: e.g. "high-risk areas have tight feedback loops"]
- [Reason 2]
- [Reason 3]

## 1.2 Test Levels & Scope

| Level | Scope | Owner | Tool/Framework | Automation % |
|-------|-------|-------|---|---|
| Unit | [describe] | Dev | JUnit / Pytest | 100% |
| Integration | [describe] | Dev + QA | [Tool] | 90% |
| System | [describe] | QA | [Tool] | 60% |
| E2E | [describe] | QA | Cypress / Playwright | 70% |
| UAT | [describe] | Business | Manual | 0% |

## 1.3 Test Types

- **Functional (Critical):** All user-facing features
- **Performance:** API response time < 200ms, page load < 3s
- **Security:** OWASP scanning, penetration testing (annually)
- **Accessibility:** WCAG 2.1 AA compliance (automated + manual)
- **Compatibility:** [list browsers/devices]

## 1.4 Automation vs. Manual Ratio

- **Target:** 80% automated, 20% manual
- **Rationale:** Repeatable functional tests automated; exploratory and UX testing manual
- **Known exceptions:** Security (manual pen testing), accessibility (manual review)

## 1.5 Test Data Management

- **Approach:** Synthetic generation + masked production replica
- **Tool:** [Faker, factory_bot, or custom]
- **Refresh:** Nightly
- **PII Handling:** All emails anonymized; credit cards masked to last 4 digits

## 1.6 Defect Management

- **Tool:** [Jira | Azure DevOps | GitHub Issues]
- **Severity Matrix:**
  - **Critical:** Blocker for release; fixed immediately
  - **High:** Should fix before release; may slip if low-impact
  - **Medium:** Fix in next release; can defer
  - **Low:** Fix later; backlog candidate

## 1.7 Test Metrics & KPIs

- **Code coverage:** Target 80% branch coverage (unit + integration)
- **Requirement coverage:** 100% of critical requirements tested
- **Defect escape rate:** Target < 5% of bugs found in production
- **Test execution time:** < 30 min for commit-stage tests
- **Defect density:** Track bugs per 1000 lines of code

## 1.8 Test Exit Criteria

- ✅ All critical & high-priority test cases pass
- ✅ Code coverage meets threshold (80% branch, 90% critical paths)
- ✅ Zero critical/high-severity defects outstanding
- ✅ Performance benchmarks met
- ✅ UAT sign-off from stakeholders
- ✅ Smoke tests passed for 3 consecutive runs with zero regressions
```

## Template: Test Automation Framework (Phase 2)

```markdown
# 2. Test Automation Framework Design

**Project:** [Name]
**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Role/Name]

## 2.1 Tech Stack Summary

| Component | Technology |
|-----------|---|
| Frontend | React 18 (SPA) |
| Backend | Node.js + Express |
| API | REST + JSON |
| Database | PostgreSQL 16 |
| Hosting | AWS (ECS, RDS) |

## 2.2 Automation Tool Selection

### UI/E2E Testing

**Chosen:** Playwright
- **Rationale:** Multi-browser (Chrome, Firefox, Safari), fast, excellent debugging
- **Alternatives considered:**
  - Cypress: Excellent DX but single-browser (at the time of this project)
  - Selenium: Mature but slower; Java-based, team knows JS better
- **Setup:** Community edition, self-hosted runners in CI/CD

### API Testing

**Chosen:** Postman + Newman (CLI)
- **Rationale:** Non-developers can write tests; collection version control; CI integration
- **Alternatives considered:**
  - REST Assured: More powerful but Java-only
  - Karate: Excellent for API; less UI-friendly
- **Setup:** Postman collections in git; Newman in CI/CD

### Unit Testing

**Chosen:** Jest (Node.js backend), React Testing Library (frontend)
- **Rationale:** Industry standard; Jest snapshot testing for React components
- **Setup:** npm scripts, 90%+ coverage threshold

## 2.3 Framework Pattern

**Chosen:** Page Object Model (POM)
- **Structure:**
  ```
  e2e/
  ├── pages/
  │   ├── LoginPage.ts
  │   ├── DashboardPage.ts
  │   └── ...
  ├── tests/
  │   ├── auth.spec.ts
  │   ├── checkout.spec.ts
  │   └── ...
  └── fixtures/
      └── test-data.json
  ```
- **Rationale:** Maintainable; locators in one place; high readability
- **Alternative considered:** Screenplay (more OOP, steeper learning curve)

## 2.4 Test Runner & Reporting

- **Runner:** Playwright Test (built-in; supports parallel execution)
- **Reporting:** HTML report + JUnit XML (for CI)
- **Artifacts:** Videos on failure, screenshots at key steps
- **Tool:** Allure Reports (optional enhancement for dashboards)

## 2.5 CI/CD Integration

- **Trigger:** On every commit to develop and main
- **Parallel execution:** 4 workers (browser-level parallelization)
- **Timeout:** 60 min max
- **On failure:** Block merge until resolved
- **Artifacts:** Collect logs, videos, screenshots to CI storage (S3 / Azure Blob)

## 2.6 Parallel Execution Strategy

- **Browsers in parallel:** Chrome, Firefox, Safari run in 3 separate jobs
- **Test isolation:** Each test gets a fresh database snapshot; no shared state
- **Data:** Test accounts created on-the-fly; cleaned up after each test
- **Reporting:** JUnit merge before final result

## 2.7 Test Environment Requirements

- **Browsers:** Chrome (latest), Firefox (latest), Safari (latest)
- **Devices:** Desktop only (for now); mobile testing deferred (TADEBT-05)
- **Test data:** 100 synthetic test users created daily
- **Network:** No throttling (production-like network assumed)
- **Third-party services:** Mocked (Stripe, Twilio, SendGrid)

## 2.8 Known Debts & Risks

- **TADEBT-05:** Mobile test coverage deferred to Phase 2 (3 sprints out)
- **Risk:** Team has no Playwright experience; training required (2 days estimated)
```

## Template: Test Coverage Matrix (Phase 3)

```markdown
# 3. Test Coverage Analysis

**Project:** [Name]
**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Role/Name]

## 3.1 Requirements Traceability

### Functional Requirements

| Requirement | Description | Test Case | Coverage | Priority |
|---|---|---|---|---|
| FR-001 | User login | AuthTest.validCredentials | E2E + API | CRITICAL |
| FR-002 | Password reset | AuthTest.passwordReset | E2E + API | HIGH |
| FR-003 | Product search | SearchTest.* | E2E + API | HIGH |
| ... | ... | ... | ... | ... |

**Summary:**
- Total FR: 45
- Covered: 43 (95.6%)
- Gaps: FR-xyz (deferred to next release)

### Non-Functional Requirements

| Requirement | Metric | Target | Approach | Status |
|---|---|---|---|---|
| NFR-001 | API response time | < 200ms p95 | Load testing (k6) | PLANNED |
| NFR-002 | Availability | 99.9% | Monitoring + alerts | IN SCOPE |
| NFR-003 | Security (OWASP) | Zero critical | SAST + DAST | PLANNED |
| ... | ... | ... | ... | ... |

## 3.2 Code Coverage Targets

| Area | Metric | Target | Current | Gap |
|---|---|---|---|---|
| Backend unit tests | Branch coverage | 80% | 75% | +5% |
| Frontend unit tests | Statement coverage | 80% | 68% | +12% |
| Integration tests | Path coverage | 70% | 60% | +10% |
| **Overall** | **Branch coverage** | **80%** | **72%** | **+8%** |

## 3.3 Risk-Based Prioritization

### High-Risk Areas (100% coverage required)

- **Critical business flows:**
  - User registration & login
  - Payment processing (checkout)
  - Order fulfillment
- **Complex logic:**
  - Tax calculation
  - Inventory management
  - Recommendation engine

### Medium-Risk Areas (80% coverage)

- Account management
- Report generation
- Admin functions

### Low-Risk Areas (60% coverage)

- Static content pages
- Help documentation
- Non-critical admin tasks

## 3.4 Coverage Gap Analysis

| Gap | Area | Effort to Close | Priority | Target Date |
|---|---|---|---|---|
| Mobile E2E | App native tests | 3 sprints | LOW | Q3 2026 |
| Performance baseline | API load testing | 1 sprint | MEDIUM | Q2 2026 |
| Security pen testing | Penetration test | 2 weeks | MEDIUM | Q2 2026 |

## 3.5 Test Case Inventory

- **Unit tests:** 320 (backend), 180 (frontend)
- **Integration tests:** 85
- **E2E tests:** 45
- **API tests:** 120
- **Total:** 750 test cases
- **Automation rate:** 95%
```

## Template: Quality Gates (Phase 4)

```markdown
# 4. Quality Gate Definitions

**Project:** [Name]
**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Role/Name]

## 4.1 Gate Structure

```
Feature Branch
  ↓ [Unit & Integration Tests]
Develop Branch (Commit Gate)
  ↓ [E2E, Smoke, Code Quality]
QA Environment
  ↓ [Regression, Performance]
Staging Environment (Release Gate)
  ↓ [UAT, Security Scan]
Production (Production Gate)
```

## 4.2 Commit Gate (per-push)

**Trigger:** Every push to develop or PR branch

| Criteria | Metric | Pass Condition | Tool |
|---|---|---|---|
| Unit test success | All pass | Zero failures | Jest |
| Code coverage | Branch coverage | >= 80% | Jest + SonarQube |
| Lint/style | Code style | Zero violations | ESLint + Prettier |
| Build success | Compilation | Zero errors | npm build |

**Decision:** PASS → merge to develop | FAIL → block merge

## 4.3 Sprint Gate (end of sprint)

**Trigger:** Before sprint sign-off

| Criteria | Metric | Pass Condition | Tool |
|---|---|---|---|
| Feature acceptance | Stories | All marked Done in Jira | Manual review |
| E2E test suite | All pass | Zero failures | Playwright |
| Regression suite | All pass | Zero critical regressions | Playwright |
| Code coverage | Branch coverage | >= 80% overall | Jest + SonarQube |
| Defects | Open bugs | Zero critical/high | Jira |

**Decision:** PASS → sprint complete | FAIL → extend sprint or defer stories

## 4.4 Release Gate (pre-production)

**Trigger:** Before deploy to staging/production

| Criteria | Metric | Pass Condition | Tool/Owner |
|---|---|---|---|
| E2E suite | All pass | 100% pass rate | Playwright |
| Performance test | API response time | p95 < 200ms, p99 < 500ms | k6 load test |
| Security scan | SAST + DAST | Zero high/critical vulnerabilities | SonarQube + OWASP ZAP |
| Dependency scan | CVE check | Zero critical CVEs | Snyk |
| UAT sign-off | Stakeholder approval | Sign-off received | Manual |
| Defects | Open bugs | Zero critical/high | Jira |

**Manual approval required:** Security lead + Product owner

**Decision:** PASS → proceed to production | FAIL → do not release

## 4.5 Production Gate (canary deploy)

**Trigger:** Deploy to 5% of prod traffic first

| Criteria | Metric | Pass Condition | Tool |
|---|---|---|---|
| Smoke tests | Key flows | All pass (login, checkout, etc.) | Synthetic monitoring |
| Error rate | Production errors | < 0.1% | DataDog APM |
| Latency | API response time | p95 < 300ms | DataDog APM |
| Business metrics | Conversion rate | No significant drop | Analytics platform |

**Decision:** PASS → full rollout | FAIL → rollback

## 4.6 Known Debts

- **TADEBT-12:** Performance SLAs under negotiation; gates listed are preliminary
- **TADEBT-13:** Security pen testing cadence (quarterly vs. annual) TBD
```

## Template: Test Environment Plan (Phase 5)

```markdown
# 5. Test Environment Plan

**Project:** [Name]
**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Role/Name]

## 5.1 Environment Tiers

| Environment | Purpose | Stability | Data Volume | Access | Refresh Freq |
|---|---|---|---|---|---|
| Dev | Developer machines + shared dev server | Unstable | Small (10 users) | Public | On-demand |
| QA/Test | QA regression & exploratory testing | Stable | Medium (100 users) | Team only | Nightly |
| Staging | E2E, UAT, load testing, production-like | Stable | Large (10k users) | Team + Stakeholders | Weekly |
| Production | Smoke tests, synthetic monitoring, canary | Stable | Real users | Monitoring only | N/A |

## 5.2 Data Requirements

### Dev Environment
- **Volume:** 10 synthetic users, 100 products, minimal transaction history
- **Freshness:** On-demand (seeded at startup)
- **Masking:** N/A (synthetic data only)
- **Reset:** Via docker-compose down/up

### QA Environment
- **Volume:** 100 users, 1000 products, 3 months of transaction history
- **Freshness:** Nightly refresh from staging template
- **Masking:** All emails anonymized; credit cards masked
- **Reset:** Automated script runs 2 AM UTC

### Staging Environment
- **Volume:** 10k users (realistic scale)
- **Freshness:** Weekly snapshot from production (24 hours delayed)
- **Masking:** PII anonymized; credit cards, SSN removed/masked
- **Reset:** On-demand via API
- **Seeding:** Additional test accounts created on-the-fly (API factory)

### Production
- **Volume:** Real users (no test data injection)
- **Freshness:** N/A
- **Masking:** N/A
- **Testing:** Synthetic monitoring only (no test data)

## 5.3 Infrastructure & Services

### Compute

| Component | Dev | QA | Staging |
|---|---|---|---|
| App servers | Local Docker | 2x t3.medium (AWS) | 4x t3.large |
| Database | Local PostgreSQL | RDS db.t3.small | RDS db.t3.large (MultiAZ) |
| Cache (Redis) | Local (optional) | ElastiCache micro | ElastiCache small |
| Message broker | Local RabbitMQ | None | RabbitMQ managed |

### Third-Party Service Mocks

| Service | Dev | QA | Staging |
|---|---|---|---|
| Stripe (payments) | Stripe test mode | Stripe test mode | Stripe test mode |
| Twilio (SMS) | Twilio test account | Twilio test account | Twilio test account |
| SendGrid (email) | localhost:1025 | SendGrid sandbox | SendGrid sandbox |

### Test Execution Infrastructure

- **Selenium Grid / Browser farm:** Browserstack (shared account)
- **Device farm:** Not in scope (deferred to Phase 2)
- **CI/CD runners:** GitHub Actions (Linux runners)
- **Artifact storage:** AWS S3 (logs, videos, screenshots)

## 5.4 Test Data Management

### Data Generation
- **Tool:** Factory Bot (Ruby on Rails) / Faker (JS)
- **Approach:** On-demand creation during test setup
- **Version control:** Fixtures in `tests/fixtures/` (git-tracked)
- **Reset:** Database truncate + fresh seed per test run (Playwright + API factories)

### Credentials & Secrets

| Secret | Storage | Rotation | Access |
|---|---|---|---|
| Test user credentials | GitHub Secrets | Weekly | CI runners |
| API tokens (QA) | HashiCorp Vault | Monthly | Automated tests |
| Database passwords | Vault | Quarterly | QA team + CI |
| AWS IAM keys | Vault | Quarterly | CI runners |

**Policy:** No hardcoded credentials in code; all via environment variables or secrets manager.

## 5.5 Environment Refresh & Maintenance

| Activity | Frequency | Owner | Time Window |
|---|---|---|---|
| QA data refresh | Nightly | DevOps | 2 AM UTC (30 min) |
| Staging data snapshot | Weekly | DevOps | Monday 1 AM UTC |
| Database backups | Daily | DevOps | 3 AM UTC |
| Test user password reset | Monthly | QA Lead | First Friday |
| Infrastructure patch | Quarterly | DevOps | Scheduled maint window |

## 5.6 Access Control & Security

### QA Team Access

- **Dev:** Full access (developers' machines)
- **QA:** SSH + database read-write via VPN
- **Staging:** Web UI + API access via VPN; no direct database access
- **Production:** No direct access (monitoring via DataDog)

### Credential Distribution

- **Never:** Commit credentials to git
- **Instead:** Use `echo $SECRET_VAR` in CI/CD; load from secrets manager in dev
- **Audit:** All secret access logged to Vault audit trail

### Network Access

- **Dev:** Open (localhost)
- **QA:** Private VPC; whitelist QA team IPs + CI runners
- **Staging:** Private VPC; whitelist team IPs + stakeholder VPNs
- **Production:** VPN + SSO + MFA required

## 5.7 Known Debts

- **TADEBT-14:** Mobile device farm not set up; deferred to Phase 2
- **TADEBT-15:** Production canary infrastructure (traffic splitting) TBD
```

---

# 2. Knowledge Base

## Test Pyramid

```
        /\
       /  \        E2E (5%)
      /    \       - Slow, brittle
     /______\      - High value (user journeys)
    /  \    /\
   /    \  /  \    Integration (15%)
  /      \/    \   - Moderate speed
 /________\____/   - Component + API coupling
/    \    \   /\
/      \    \ /  \  Unit (80%)
/________\___/____\ - Fast, reliable
                    - Individual functions/classes
```

**Strategy:** Invest mostly in unit tests (fast feedback), supplement with integration & E2E.

## Common Test Automation Frameworks

| Framework | Language | Best For | Maturity | Cost |
|---|---|---|---|---|
| **Playwright** | JS/TS/Python | Multi-browser E2E | Established | Free |
| **Cypress** | JS/TS | Single-browser E2E (web) | Established | Free + optional cloud |
| **Selenium** | Any language | Legacy, cross-browser | Mature | Free |
| **Appium** | Any language | Mobile native/web | Established | Free |
| **Jest** | JS/TS | Unit testing (Node, React) | Established | Free |
| **Pytest** | Python | Unit + integration | Established | Free |
| **JUnit** | Java | Unit testing | Mature | Free |
| **TestNG** | Java | Unit + integration + parallel | Established | Free |
| **REST Assured** | Java | API testing | Established | Free |
| **Postman** | Any | API testing + mocking | Established | Free + premium |
| **k6** | Go/JS | Performance/load testing | Emerging | Free + cloud |
| **JMeter** | Java | Performance/load testing | Mature | Free |

## ISTQB Test Levels

- **Unit:** Individual components in isolation (developers)
- **Integration:** Multiple components together (dev + QA)
- **System:** End-to-end, entire system integrated (QA)
- **UAT:** User acceptance testing by stakeholders (Business)

## ISTQB Test Types

- **Functional:** Does it do what it should? (happy path + error cases)
- **Non-Functional:** Performance, security, reliability, usability, accessibility
- **Structural:** Code coverage, white-box testing
- **Change-Related:** Regression (did we break anything?), smoke (critical paths)

## Glossary

- **Acceptance Criteria:** Conditions that a feature must satisfy to be deemed complete (from BA/PO)
- **Code Coverage:** % of source code executed by tests (statement, branch, path)
- **E2E (End-to-End):** Testing the full user journey through the UI
- **Exit Criteria:** Conditions that must be met for a test phase to complete (e.g. coverage > 80%)
- **Flaky test:** A test that fails intermittently without code changes (common in E2E due to timing)
- **Gate:** A checkpoint where testing results determine readiness to proceed
- **Regression:** Testing that previously-working features still work after changes
- **Risk-based testing:** Allocating effort proportional to likelihood + impact of failure
- **Smoke test:** Quick sanity check of critical paths (usually automated)
- **Test data:** Inputs used by tests (can be synthetic, masked production, or fixtures)
- **Traceability:** Linking requirements → test cases → code → results (for auditability)

---

# 3. Worked Examples of Test Architect Work

### Example 1: Startup (Lean, Agile)

- **Test approach:** Hybrid (risk + requirement-based)
- **Test levels:** Unit + E2E (no integration layer yet)
- **Automation:** Cypress for E2E, Jest for unit
- **Gates:** Commit-stage only (no release gates initially)
- **Environments:** Dev + staging (no QA env yet)
- **Coverage target:** 70% (pragmatic, growing with each sprint)

### Example 2: Regulated Industry (Healthcare, Finance)

- **Test approach:** Requirement-based with traceability matrix
- **Test levels:** Unit + integration + system + UAT (all required)
- **Automation:** Selenium + REST Assured (mature, compliant)
- **Gates:** Commit + sprint + release + UAT (heavyweight)
- **Environments:** Dev + QA + staging + production (full stack)
- **Coverage target:** 90%+ (compliance mandate)

### Example 3: High-Scale Platform (100M+ users)

- **Test approach:** Risk-based (focus on critical flows, high-concurrency areas)
- **Test levels:** Unit + integration + system + performance + chaos (Netflix/AWS style)
- **Automation:** Cypress (web) + k6 (performance) + property-based testing (Hypothesis)
- **Gates:** Continuous (every commit) with auto-rollback on failure
- **Environments:** Dev + QA + canary (production staging pre-deploy)
- **Coverage target:** 80% (high-velocity, continuous deployment)
