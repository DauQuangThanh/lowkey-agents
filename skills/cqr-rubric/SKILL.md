---
name: cqr-rubric
description: Reference rubric for the Code Quality Reviewer — output templates for phases 1–4 and the final report, plus complexity scoring methodology, SOLID quick reference, code smells catalog, refactoring patterns, and glossary. Read this skill when you need the exact markdown layout to emit, or the canonical definitions of CC/SOLID/code smells the agent scores against.
license: MIT
compatibility: Content-only skill; no scripts. Read directly when writing any `cqr-output/` markdown.
allowed-tools: Read
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "ref"
---

# Code Quality Reviewer — Rubric & Templates

This skill holds the reference content the `code-quality-reviewer` agent uses
when writing output files or scoring findings. It has no scripts — read the
relevant section and emit the template verbatim (with placeholders filled).

## When to use

Read this skill whenever the agent needs to:

- Emit the markdown body of `cqr-output/01-standards-review.md`, `02-complexity-report.md`, `03-patterns-review.md`, `04-quality-report.md`, or `CQR-FINAL.md`
- Look up the canonical definition of cyclomatic complexity, function-length, file-size, or coupling thresholds
- Cite a SOLID principle, code smell, or refactoring pattern by name
- Pull glossary terms for inline definitions

Sections below are ordered: (1) Output Templates, (2) Complexity Scoring,
(3) SOLID Quick Reference, (4) Code Smells Catalog, (5) Refactoring Patterns,
(6) Glossary.

---

# 1. Output Templates

## Phase 1 — Standards Review (`01-standards-review.md`)

```markdown
# Phase 1: Coding Standards Review

**Timestamp:** [ISO date/time]
**Status:** Complete

## Executive Summary

[1–3 sentences on overall standards compliance and any major gaps]

## Standards Baseline

| Standard | Value | Status |
|---|---|---|
| Language(s) | Python, JavaScript | ✅ Clear |
| Style Guide | PEP 8 (Python), Airbnb (JS) | ✅ Documented |
| Naming Rules | snake_case (Python), camelCase (JS) | ✅ Mostly followed |
| File Structure | `src/{module}/` pattern | ⚠️ Inconsistent in legacy modules |
| Import Ordering | Stdlib → third-party → local | ✅ Enforced by isort |
| Documentation | Google-style docstrings | ⚠️ Missing in 15% of functions |
| Linting | Pylint (Python), ESLint (JS) | ✅ CI/CD enforced |
| Known Deviations | Legacy `api/` folder predates standard | 📌 Noted |

## Findings by Severity

### ❌ Critical (0 findings)

### ⚠️ Major (3 findings)

**STD-MAJ-01: Inconsistent naming in legacy auth module**
- **File:** `src/auth/old_login.py`
- **Issue:** Uses `camelCase` for functions instead of `snake_case`
- **Examples:** `checkPassword()`, `validateToken()` (should be `check_password()`, `validate_token()`)
- **Impact:** Breaks naming convention, confuses developers unfamiliar with code
- **Recommendation:** Refactor function names to match standard; update all callers

**STD-MAJ-02: Missing docstrings in data access layer**
- **Files:** `src/db/*.py` (8 functions)
- **Issue:** No docstring on public functions like `find_by_id()`, `save()`
- **Impact:** Developers must read code to understand contracts
- **Recommendation:** Add Google-style docstrings with Args, Returns, Raises sections

**STD-MAJ-03: Import ordering not enforced in TypeScript**
- **File:** `src/components/Dashboard.tsx`
- **Issue:** Imports mixed (local, third-party, stdlib not separated)
- **Recommendation:** Run `eslint --fix` and add rule to `eslintrc.json`

### 📌 Minor (4 findings)

**STD-MIN-01:** `src/utils/helpers.js` — overly long file (620 lines), should split into smaller modules
**STD-MIN-02:** Magic numbers in `src/pricing/calculator.py` — hardcoded tax rates should be constants
**STD-MIN-03:** Inconsistent blank line spacing in `src/services/email.py`
**STD-MIN-04:** TODO comments without dates or assignees (3 instances)

### ℹ️ Info (2 findings)

**STD-INFO-01:** Consider adopting Prettier for JavaScript formatting (not yet adopted)
**STD-INFO-02:** Opportunity to add pre-commit hooks for linting

## Debt Entries Created

- CQDEBT-01: Legacy auth module needs naming refactor (Major, Medium effort)
- CQDEBT-02: TypeScript imports need enforcement (Minor, Small effort)

## Next Steps

1. Add docstrings to data access layer (2–3 hours)
2. Refactor legacy auth naming (1 day)
3. Add import-order rule to ESLint config (30 min)

---
```

## Phase 2 — Complexity Report (`02-complexity-report.md`)

```markdown
# Phase 2: Complexity & Maintainability Analysis

**Timestamp:** [ISO date/time]
**Status:** Complete
**Thresholds:** CC max 10/function, max 200/file

## Executive Summary

[1–3 sentences on overall complexity health and hottest spots]

## Complexity Metrics by Module

### Module: `order-service` (850 LOC)

| File | CC | Avg Len | % Over Threshold | Issues |
|---|---|---|---|---|
| `order.py` | 8 | 25 | 0% | ✅ Healthy |
| `order_service.py` | 18 | 45 | 40% (2 of 5 functions) | ⚠️ Complex |
| `payment_handler.py` | 22 | 60 | 60% (3 of 5) | ❌ Very complex |
| `refund_processor.py` | 15 | 35 | 20% | ⚠️ Moderate |

### Module: `auth` (320 LOC)

| File | CC | Avg Len | % Over Threshold | Issues |
|---|---|---|---|---|
| `login.py` | 12 | 28 | 20% (1 of 4) | ⚠️ Moderate |
| `jwt_handler.py` | 6 | 18 | 0% | ✅ Healthy |

### Module: `reporting` (1200 LOC)

| File | CC | Avg Len | % Over Threshold | Issues |
|---|---|---|---|---|
| `report_generator.py` | 35 | 85 | 80% (4 of 5) | ❌ Very complex (hottest spot) |
| `filters.py` | 18 | 40 | 40% | ⚠️ Complex |

## Hotspots Ranked by Impact

**🔴 Critical (CC >20):**

1. **payment_handler.py::ProcessPayment()** — CC=22
   - Handles 8 distinct payment scenarios (credit card, PayPal, crypto, bank transfer, etc.) in one function
   - 60 lines, 3 nested loops
   - Hard to test edge cases; error paths unclear
   - **Recommendation:** Extract payment type handlers into Strategy pattern; inject via factory
   - **Effort:** 2–3 days

2. **report_generator.py::GenerateReport()** — CC=35
   - Applies 12 different filters, 6 formatting options, 4 export formats in cascade
   - 120 lines, deeply nested if/switch statements
   - **Recommendation:** Use Builder pattern; split format logic into separate classes
   - **Effort:** 3–4 days

**🟡 Major (CC 11–20):**

3. **order_service.py::UpdateOrder()** — CC=18
   - 8 state transitions, complex precondition checks
   - **Recommendation:** Extract state machine; use decorator pattern for pre/post-conditions
   - **Effort:** 1–2 days

4. **filters.py::ApplyFilters()** — CC=18
   - **Recommendation:** Compose into separate filter objects

**🟢 Minor (CC 6–10):** [List any approaching threshold]

## Dependency Coupling Analysis

### High Coupling (>5 dependencies):

- `order_service.py` → payment_handler, auth, inventory, notification, reporting (5 modules)
  - **Risk:** Changes in any of these ripple through
  - **Recommendation:** Consider facade or event-driven decoupling

### Circular Dependencies:

- `auth.py` ↔ `user_service.py` — imports each other
  - **Recommendation:** Extract shared types into `models.py`

### Low Coupling (1–2 dependencies):

- `jwt_handler.py` → none (standalone utility) ✅
- `email_sender.py` → logger only ✅

## File Size Analysis

| File | LOC | Status | Recommendation |
|---|---|---|---|
| `report_generator.py` | 280 | ⚠️ At limit | Consider splitting |
| `payment_handler.py` | 150 | ✅ OK | — |
| `order_service.py` | 200 | ✅ OK | — |
| `helpers.js` | 620 | ❌ Too large | Split into 3–4 modules |

## Function Length Analysis

| File::Function | LOC | Status |
|---|---|---|
| `payment_handler.py::ProcessPayment()` | 60 | ❌ 3x limit |
| `report_generator.py::GenerateReport()` | 120 | ❌ 6x limit |
| `order_service.py::UpdateOrder()` | 45 | ⚠️ 2.25x limit |

## Debt Entries Created

- CQDEBT-03: High complexity in ProcessPayment() (Critical, Medium effort)
- CQDEBT-04: Very high complexity in GenerateReport() (Critical, Large effort)
- CQDEBT-05: Circular dependency auth ↔ user_service (Major, Small effort)
- CQDEBT-06: helpers.js too large, needs split (Minor, Medium effort)

## Refactoring Roadmap

| Phase | Work | Effort | Outcome |
|---|---|---|---|
| 1 | Extract strategy handlers from ProcessPayment | 2 days | CC: 22 → 8 |
| 2 | Refactor GenerateReport into builder + format classes | 3 days | CC: 35 → 10 |
| 3 | Break circular auth dependency | 1 day | Decoupled |
| 4 | Split helpers.js into modules | 1 day | Maintainable |

---
```

## Phase 3 — Patterns Review (`03-patterns-review.md`)

```markdown
# Phase 3: Design Pattern & Architecture Compliance

**Timestamp:** [ISO date/time]
**Status:** Complete

## Executive Summary

[1–3 sentences on overall pattern adherence and architectural gaps]

## Expected Patterns (from architecture)

From `arch-output/`, this codebase follows:
- **Ports & Adapters** (Hexagonal) for core business logic separation
- **Repository pattern** for data access
- **Service layer** for business orchestration
- **Event-driven** for async operations

## SOLID Principles Audit

### S — Single Responsibility

| Component | Assessment | Evidence |
|---|---|---|
| `OrderService` | ❌ Violates | Handles order creation, state transitions, payment delegation, notification sending (4 reasons to change) |
| `PaymentHandler` | ⚠️ Partial | Handles multiple payment types (should be one per strategy class) |
| `JWTHandler` | ✅ Compliant | Only JWT encode/decode |
| `EmailSender` | ✅ Compliant | Only email formatting and sending |

**Findings:**
- CQDEBT-07: OrderService has multiple responsibilities (Major, Large effort to refactor)
- CQDEBT-08: PaymentHandler should use Strategy pattern (Major, Medium effort)

### O — Open/Closed

| Component | Assessment | Evidence |
|---|---|---|
| Payment types | ❌ Violates | Adding new payment type requires modifying `ProcessPayment()` switch statement |
| Report format | ❌ Violates | New export format = edit `GenerateReport()` |
| Notification channels | ✅ Compliant | Strategy pattern in place; new channels extend without modifying core |

**Findings:**
- CQDEBT-09: Payment handling not open for extension (Major, Medium effort)

### L — Liskov Substitution

| Component | Assessment | Evidence |
|---|---|---|
| PaymentAdapter hierarchy | ⚠️ At risk | All payment types return `bool`, but some need to return transaction ID — inconsistent contracts |
| NotificationProvider | ✅ Compliant | All providers implement same `send()` signature with identical semantics |

**Findings:**
- CQDEBT-10: PaymentAdapter return type inconsistency (Minor, Small effort)

### I — Interface Segregation

| Component | Assessment | Evidence |
|---|---|---|
| `OrderService` public API | ⚠️ Fat interface | Clients forced to depend on `cancel()`, `refund()`, `export()` even if they only need `create()` |
| `Repository` | ✅ Compliant | Separated `BaseRepository` (CRUD) vs. `OrderRepository` (domain-specific queries) |

**Findings:**
- CQDEBT-11: OrderService interface is too broad (Minor, Medium effort)

### D — Dependency Inversion

| Component | Assessment | Evidence |
|---|---|---|
| `OrderService` → `PaymentHandler` | ❌ Violates | Direct coupling to concrete class; hard to mock in tests |
| `Repositories` | ✅ Compliant | Injected via constructor; mockable |
| `NotificationManager` | ✅ Compliant | Depends on `INotificationProvider` interface |

**Findings:**
- CQDEBT-12: OrderService tightly coupled to PaymentHandler (Major, Medium effort)

## DRY (Don't Repeat Yourself)

| Issue | Files | Lines | Recommendation |
|---|---|---|---|
| Validation logic duplication | `user_validators.py`, `order_validators.py`, `payment_validators.py` | ~50 lines each | Extract to `validation/common_rules.py` |
| Error response formatting | `user_api.py`, `order_api.py`, `payment_api.py` (HTTP handlers) | 3–5 lines each | Create error formatter utility |
| Date/time formatting | 4 modules | Various | Centralize in `utils/date_utils.py` |
| SQL queries for "list by user" | `user_repo.py`, `order_repo.py`, `payment_repo.py` | Similar 3–5 line blocks | Extract to base `Repository::find_by_user()` |

**Findings:**
- CQDEBT-13: Validation logic duplicated across 3 modules (Minor, Small effort)
- CQDEBT-14: Error formatting inconsistent across API handlers (Minor, Small effort)

## Separation of Concerns

### Business Logic ↔ Persistence

| Issue | Assessment | Evidence |
|---|---|---|
| Query logic in services | ❌ Violates | `OrderService.GetActiveOrders()` contains SQL-like filtering logic instead of delegating to repo |
| Transaction handling | ⚠️ Mixed | Some use decorator pattern (good), some inline try/catch (bad) |
| Caching logic | ❌ Leaks | Cache keys hardcoded in business logic |

### Business Logic ↔ HTTP/API

| Issue | Assessment | Evidence |
|---|---|---|
| Request parsing | ✅ Compliant | Validation layer converts HTTP to domain models |
| Response formatting | ⚠️ Mixed | Some endpoints transform; others return domain objects directly |
| Error codes | ⚠️ Mixed | No unified HTTP → domain error mapping |

### Cross-Cutting Concerns (Logging, Metrics, Auth)

| Concern | Assessment | Evidence |
|---|---|---|
| Logging | ⚠️ Scattered | Ad hoc `logger.info()` calls; no structured logging |
| Metrics | ❌ Missing | No request latency, error rate, or business metrics captured |
| Authentication | ✅ Middleware-based | Centralized in decorator/middleware, not sprinkled through logic |

**Findings:**
- CQDEBT-15: Query logic in OrderService should move to repository (Major, Medium effort)
- CQDEBT-16: No structured logging framework (Major, Medium effort)
- CQDEBT-17: Missing metrics instrumentation (Minor, Large effort, can defer)

## Error Handling Patterns

| Pattern | Expected | Found | Assessment |
|---|---|---|---|
| Exception handling | Custom exceptions for domain errors | ✅ Mostly present | Good: `OrderNotFound`, `PaymentFailed` |
| Error context | Stack trace + business context | ⚠️ Partial | Stack trace yes; business context missing in some paths |
| Recovery | Graceful fallbacks or retries | ⚠️ Ad hoc | Implemented in some modules, missing in others |
| Propagation | Clear error boundaries | ❌ Unclear | Errors sometimes swallowed silently |

**Findings:**
- CQDEBT-18: Inconsistent error handling across modules (Major, Medium effort)
- CQDEBT-19: Some errors silently swallowed in async handlers (Major, Small effort, high priority)

## Logging Patterns

| Pattern | Expected | Found | Assessment |
|---|---|---|---|
| Structured logging | JSON logs with fields | ❌ Not used | Using plain text `logger.info()`; not machine-readable |
| Log levels | DEBUG, INFO, WARN, ERROR, CRITICAL used correctly | ⚠️ Partial | Correct usage, but inconsistent across modules |
| Sensitive data | No passwords, tokens, PII in logs | ⚠️ Risk | Payment card tokens appear in debug logs (⚠️ SECURITY) |
| Context propagation | Request ID, user ID, tracing | ❌ Missing | No correlation IDs for distributed tracing |

**Findings:**
- CQDEBT-16: Missing structured logging framework (Major, Medium effort)
- CQDEBT-20: Sensitive payment data in logs (CRITICAL, Small effort, immediate fix)

## Code Smells Catalog

### God Objects

| Class | Responsibilities | Assessment |
|---|---|---|
| `OrderService` | 4–5 (order logic, payment, notification, refund) | ❌ God object |
| `ReportGenerator` | 6+ (filtering, formatting, export, caching) | ❌ God object |

### Feature Envy

| Class | Accesses | Issue |
|---|---|---|
| `PaymentValidator` | 5+ fields/methods of `Order` | Knows too much about Order structure |
| `ReportFilter` | Multiple fields of different models | Hard to extend with new model types |

### Duplicate Code

| Block | Files | Issue |
|---|---|---|
| Validation try/catch | 3 validators | Extract to decorator or base class |
| List endpoint logic | 8 API handlers | Create generic list handler |

### Long Parameter Lists

| Function | Params | Issue |
|---|---|---|
| `ProcessPayment(type, amount, currency, userId, orderId, metadata, retry, timeout, idempotencyKey)` | 9 | ❌ Too many; use object parameter |
| `GenerateReport(filters, formats, sort, group, limit, offset, cache)` | 7 | ⚠️ Consider builder pattern |

### Dead Code

| Location | Status | Action |
|---|---|---|
| `order_service.py::deprecated_calculate_tax()` | Never called | Remove (found in grep search) |
| `utils/old_date_parser.py` | No imports | Remove |

## Pattern Recommendations

### High Priority

1. **Extract PaymentStrategy** — Convert `PaymentHandler` switch/if cascade into Strategy pattern classes
2. **Split OrderService** — Separate into `OrderCreationService`, `OrderStateService`, `RefundService`
3. **Fix error logging** — Audit all error handling; ensure context is preserved and logged
4. **Add structured logging** — Integrate structured logging library (e.g., Python: structlog, JS: winston)

### Medium Priority

5. **Refactor complex queries** — Move filtering from `OrderService` to `OrderRepository`
6. **Centralize validation** — Create reusable `Validation` module
7. **Add metrics** — Instrument request latency, error rates, business KPIs

### Low Priority (Can defer)

8. **Optimize Report caching** — Currently inefficient; add caching layer
9. **Split ReportGenerator** — Extract format/export logic

## Debt Entries Created

(See earlier CQDEBT-07 through CQDEBT-20, plus CQDEBT-21 below)

- CQDEBT-21: Dead code in order_service.py and utils/ (Info, Small effort)

---
```

## Phase 4 — Quality Report (`04-quality-report.md`)

```markdown
# Phase 4: Quality Report & Recommendations

**Timestamp:** [ISO date/time]
**Status:** Complete

## Executive Summary

This codebase shows **moderate-to-good architectural intent** (Hexagonal / Repository patterns in place) but suffers from **inconsistent execution** in code quality practices. The primary issues are:

1. **High complexity hotspots** — 2–3 "god functions" with CC >20 that demand immediate refactoring
2. **Single Responsibility violations** — Core services blend business logic, orchestration, and cross-cutting concerns
3. **Scattered error & logging practices** — No structured approach; sensitive data risks
4. **Code duplication** — Validation, error formatting, and query logic repeated across modules

**Overall Quality Score: 62/100** (Below target; achievable with 2–4 weeks of focused refactoring)

---

## Findings Aggregated by Severity

### 🔴 Critical (3 findings — immediate action)

| Finding | Phase | Module | Impact | Effort | Recommendation |
|---|---|---|---|---|---|
| **Sensitive data in logs** | 3 | logging | Payment card tokens exposed in debug logs; GDPR/PCI-DSS risk | S | Add log sanitization filter immediately; remove token logging |
| **Very high complexity** | 2 | payment_handler | CC=22; ProcessPayment() handles 8+ scenarios; unmaintainable and error-prone | M | Refactor into Strategy pattern (2–3 days) |
| **Very high complexity** | 2 | reporting | CC=35; GenerateReport() has 120 lines, 4+ levels of nesting | L | Use Builder + Strategy pattern (3–4 days) |

### 🟠 Major (8 findings — fix in current/next sprint)

| Finding | Phase | Module | Impact | Effort | Recommendation |
|---|---|---|---|---|---|
| **Single Responsibility violation** | 3 | order_service | 4–5 reasons to change; hard to test, modify, understand | L | Refactor into micro-services or separate domain objects |
| **Tight coupling** | 3 | order_service | OrderService → PaymentHandler direct dependency; hard to mock/test | M | Inject PaymentAdapter interface; use dependency inversion |
| **Open/Closed violation** | 3 | payment_handler | Adding payment type requires code change, not extension | M | Implement Strategy pattern; registry-based dispatch |
| **Inconsistent error handling** | 3 | multiple | Some errors logged, some silently caught; unclear error flow | M | Define error handling policy; audit all catch blocks |
| **Missing structured logging** | 3 | multiple | Plain text logs; not machine-readable; no request tracing | M | Integrate logging framework (structlog, winston, serilog) |
| **Validation duplication** | 3 | validators | 50+ lines of similar logic across 3 modules; maintenance burden | S | Extract to `validation/common_rules.py` |
| **Legacy auth naming** | 1 | auth | Inconsistent camelCase vs. snake_case; breaks convention | M | Rename functions; update callers (1 day) |
| **High coupling** | 2 | order_service | 5+ module dependencies; ripple risk on changes | M | Consider event-driven or facade pattern |

### 🟡 Minor (6 findings — fix this quarter)

| Finding | Phase | Module | Impact | Effort | Recommendation |
|---|---|---|---|---|---|
| **Missing docstrings** | 1 | data_access | 8 public functions lack documentation | S | Add Google-style docstrings (2–3 hours) |
| **Interface too broad** | 3 | order_service | Clients forced to depend on all public methods | M | Segregate interfaces (separate service classes) |
| **Circular dependency** | 2 | auth ↔ user_service | Imports each other; subtle coupling | S | Extract shared types to models.py (1 day) |
| **Too-large files** | 2 | helpers.js | 620 lines; should be 3–4 modules | M | Refactor into logical modules (1 day) |
| **Inconsistent response formatting** | 3 | api_handlers | 3 handlers format errors differently | S | Create error formatter utility (2 hours) |
| **Function length** | 2 | order_service::UpdateOrder() | 45 lines (2.25x limit); hard to follow | S | Extract pre-condition checks and state transitions (1 day) |

### ℹ️ Info (3 findings — consider for backlog)

| Finding | Phase | Module | Impact | Effort | Recommendation |
|---|---|---|---|---|---|
| **Dead code** | 3 | utils/ | Deprecated functions never called | S | Remove (2 hours) |
| **Missing metrics** | 3 | all | No request latency, error rate, business KPI instrumentation | L | Add metrics framework (3–5 days); can defer |
| **Pre-commit hooks** | 1 | ci/cd | Opportunity to enforce linting/formatting earlier | S | Configure `.pre-commit-config.yaml` (2 hours) |

---

## Quality Scorecard

| Category | Score | Weight | Contribution | Status |
|---|---|---|---|---|
| **Standards Compliance** | 72/100 | 25% | 18 pts | ⚠️ Good naming, but legacy exceptions; missing docs |
| **Complexity Health** | 55/100 | 25% | 13.75 pts | ❌ 2 hotspots with CC >20 |
| **Pattern Adherence** | 58/100 | 25% | 14.5 pts | ⚠️ SOLID violations in core services |
| **Technical Debt** | 60/100 | 25% | 15 pts | ⚠️ 21 debt entries; 3 critical, 8 major |
| **Composite Score** | **62/100** | — | — | ⚠️ Below target (80+) |

---

## Improvement Roadmap

### Week 1 — Critical Fixes
- [ ] Add log sanitization filter (prevent card token logging)
- [ ] Document error handling policy
- [ ] Start Strategy pattern refactor on PaymentHandler

### Week 2–3 — Major Refactoring
- [ ] Complete PaymentHandler → Strategy pattern
- [ ] Begin OrderService decomposition
- [ ] Add structured logging framework

### Week 4 — Consolidation
- [ ] Complete GenerateReport refactoring
- [ ] Fix circular auth dependency
- [ ] Add/update docstrings
- [ ] Re-run complexity analysis (target: all CC <10)

### Future (Backlog)
- [ ] Add metrics instrumentation
- [ ] Optimize report caching
- [ ] Dead code cleanup

---

## Quality Target (Proposed)

| Metric | Current | Target | Rationale |
|---|---|---|---|
| Overall Score | 62 | 80+ | Industry standard for maintainable code |
| Max CC per function | 35 | ≤10 | Reduce complexity for testing/maintenance |
| Functions >50 LOC | 3 | 0 | Improve readability and single responsibility |
| Standards compliance | 72% | 95%+ | Enforce conventions; easier onboarding |
| Test coverage | TBD | 80%+ | Coverage tends to rise as complexity falls |

---

## Dependencies & Risks

- **Refactoring PaymentHandler** depends on completing unit test strategy (from developer workflow)
- **Adding metrics** depends on selecting instrumentation library (architecture decision)
- **Structured logging** requires migration of all logging calls (1–2 day effort)

---
```

## CQR-FINAL.md

```markdown
# Code Quality Review — Final Report

**Project:** [Project Name]
**Timestamp:** [ISO date/time]
**Reviewer:** Code Quality Agent

---

## Executive Summary

This code quality review assessed the codebase across **Standards Compliance**, **Complexity & Maintainability**, and **Design Pattern & Architecture Adherence**.

**Overall Quality Score: 62/100** ⚠️ (Below target; 21 debt entries logged; 3 critical issues)

### Key Findings

✅ **Strengths:**
- Clear architectural intent (Hexagonal/Repository patterns recognized)
- Good use of dependency injection in some modules
- Consistent API/HTTP layer separation

❌ **Critical Issues:**
1. Sensitive data (payment tokens) logged in debug output — immediate security fix needed
2. Two "god functions" with cyclomatic complexity >20 (PaymentHandler::ProcessPayment=22, ReportGenerator=35)
3. Multiple SOLID violations; OrderService handles 4–5 responsibilities

⚠️ **Major Gaps:**
- Inconsistent error handling; no structured logging framework
- Code duplication in validation logic across 3 modules
- No metrics instrumentation for observability

---

## Quality Scorecard

| Dimension | Score | Trend | Status |
|---|---|---|---|
| **Standards Compliance** | 72/100 | → Stable | Mostly good; legacy exceptions |
| **Complexity Health** | 55/100 | ↘ Declining | 2 hotspots; needs refactoring |
| **Pattern Adherence** | 58/100 | ↘ At risk | SOLID violations in services |
| **Technical Debt** | 60/100 | ↗ Growing | 21 entries; prioritize 11 major+ |
| **Composite** | **62/100** | ⚠️ Needs improvement | Target: 80+ |

---

## Phase Summaries

### Phase 1 — Standards Review
✅ **Status:** Complete
- 8 standards documented (language, style guide, naming, structure, imports, docs, linting, deviations)
- 3 major findings, 4 minor, 2 info
- Primary: Legacy auth module naming, missing TypeScript import enforcement, missing docstrings

**Output:** `cqr-output/01-standards-review.md`

### Phase 2 — Complexity Analysis
⚠️ **Status:** Complete | **Alert:** 2 hotspots exceed safe thresholds
- Modules analyzed: order-service (850 LOC), auth (320), reporting (1200)
- Hottest spot: ReportGenerator::GenerateReport() with CC=35 (3.5x threshold)
- 6 major findings, 2 circular dependencies identified

**Output:** `cqr-output/02-complexity-report.md`

### Phase 3 — Pattern & Architecture Review
❌ **Status:** Complete | **Alert:** Multiple SOLID violations
- SOLID audit: S violated (OrderService), O violated (PaymentHandler), D violated (direct coupling)
- Identified: God objects, fat interfaces, tight coupling, scattered error handling
- 11 debt entries created for pattern issues

**Output:** `cqr-output/03-patterns-review.md`

### Phase 4 — Quality Report
✅ **Status:** Complete
- Aggregated 21 findings across severity levels
- Composite score calculated: 62/100
- Improvement roadmap: 4-week plan with milestones

**Output:** `cqr-output/04-quality-report.md` (this file)

---

## Top 10 Priority Actions

| # | Action | Impact | Effort | Owner | Timeline |
|---|---|---|---|---|---|
| 1 | Remove payment tokens from logs (log sanitizer) | 🔴 Critical | S | Backend | This week |
| 2 | Refactor PaymentHandler → Strategy pattern | 🟠 Major | M | Backend | Week 2–3 |
| 3 | Define & enforce error handling policy | 🟠 Major | M | Architecture | Week 2 |
| 4 | Add structured logging framework | 🟠 Major | M | DevOps | Week 3 |
| 5 | Decompose OrderService (SRP violation) | 🟠 Major | L | Backend | Week 4+ |
| 6 | Fix circular auth ↔ user_service dependency | 🟠 Major | S | Backend | Week 2 |
| 7 | Centralize validation logic | 🟡 Minor | S | Backend | Week 3 |
| 8 | Add/update docstrings for public API | 🟡 Minor | S | All | Week 3 |
| 9 | Extract format logic from ReportGenerator | 🟠 Major | L | Backend | Week 4+ |
| 10 | Add metrics instrumentation (can defer) | ℹ️ Info | L | Observability | Q2 |

---

## Technical Debt Register (21 entries)

```
CQDEBT-01:  Legacy auth module naming (Major, Medium, Phase 1)
CQDEBT-02:  TypeScript import enforcement missing (Minor, Small, Phase 1)
CQDEBT-03:  High CC in OrderService::processRefund() (Major, Medium, Phase 2)
CQDEBT-04:  Very high CC in GenerateReport() (Critical, Large, Phase 2)
CQDEBT-05:  Circular dependency auth ↔ user_service (Major, Small, Phase 2)
CQDEBT-06:  helpers.js too large (Minor, Medium, Phase 2)
CQDEBT-07:  OrderService multiple responsibilities (Major, Large, Phase 3)
CQDEBT-08:  PaymentHandler missing Strategy pattern (Major, Medium, Phase 3)
CQDEBT-09:  Payment handling not open/closed principle (Major, Medium, Phase 3)
CQDEBT-10:  PaymentAdapter return type inconsistency (Minor, Small, Phase 3)
CQDEBT-11:  OrderService interface too broad (Minor, Medium, Phase 3)
CQDEBT-12:  OrderService tight coupling (Major, Medium, Phase 3)
CQDEBT-13:  Validation logic duplicated (Minor, Small, Phase 3)
CQDEBT-14:  Error response formatting inconsistent (Minor, Small, Phase 3)
CQDEBT-15:  Query logic in OrderService (Major, Medium, Phase 3)
CQDEBT-16:  Missing structured logging (Major, Medium, Phase 3)
CQDEBT-17:  Missing metrics instrumentation (Minor, Large, Phase 3)
CQDEBT-18:  Inconsistent error handling (Major, Medium, Phase 3)
CQDEBT-19:  Async error handling gaps (Major, Small, Phase 3)
CQDEBT-20:  Sensitive payment data in logs (Critical, Small, Phase 3)
CQDEBT-21:  Dead code in utils/ (Info, Small, Phase 3)
```

Full details in `cqr-output/05-cq-debts.md`.

---

## Recommendations by Timeline

### Immediate (This Week)
1. **Fix CQDEBT-20** — Remove payment token logging (security risk; 1–2 hours)
2. **Start CQDEBT-08** — PaymentHandler Strategy refactor (complex, start early)

### Short-term (Next 2–3 Weeks)
3. **Fix CQDEBT-05** — Circular dependency (clear blocker; 1 day)
4. **Complete CQDEBT-08** — PaymentHandler refactor (2–3 days)
5. **Implement CQDEBT-16** — Structured logging (high ROI; 2–3 days)
6. **Fix CQDEBT-13, CQDEBT-14** — Validation & error formatting (quick wins; 1 day each)

### Medium-term (Next Month)
7. **CQDEBT-04** — GenerateReport refactoring (large, plan carefully; 3–4 days)
8. **CQDEBT-07** — OrderService decomposition (architectural, needs design; 4–5 days)
9. **CQDEBT-15** — Move query logic to repository (refactoring; 2–3 days)

### Backlog (This Quarter)
10. **CQDEBT-17** — Metrics instrumentation (valuable, but can wait; 3–5 days)
11. **Cleanup dead code** (low-value maintenance; 2 hours)

---

## Success Criteria

| Criterion | Current | Target | Rationale |
|---|---|---|---|
| Quality Score | 62 | 80+ | Industry standard |
| Max CC/function | 35 | ≤10 | Testable, understandable |
| Functions >50 LOC | 3 | 0 | Single responsibility |
| Standards compliance | 72% | 95%+ | Consistency, onboarding |
| Critical debts | 3 | 0 | Security & stability |
| Major debts | 8 | ≤2 | Maintainability |

---

## Appendices

### A. Methodology

This review applied a 4-phase assessment:
1. **Phase 1: Standards Compliance** — Audited naming, structure, imports, docs, linting
2. **Phase 2: Complexity Analysis** — Measured cyclomatic complexity, function/file size, coupling
3. **Phase 3: Pattern & Architecture** — Checked SOLID, DRY, KISS, error handling, logging
4. **Phase 4: Quality Report** — Aggregated findings, scored, and prioritized recommendations

### B. Tools Used

- Static analysis: grep, ast analysis
- Metrics: Manual cyclomatic complexity audit (via control flow inspection)
- Patterns: Code review against SOLID, DDD, architectural ADRs

### C. Limitations

- Metrics are hand-calculated; automated tooling recommended (Pylint, ESLint, SonarQube, etc.)
- Review focused on maintainability; security & performance require separate audits
- Test coverage not measured (recommend separate test framework audit)

---

**Report Generated:** [ISO timestamp]
**Next Review:** Recommended in 2–4 weeks after critical/major debt resolution
```

---

# 2. Complexity Scoring Methodology

## Cyclomatic Complexity (CC)

CC measures the number of linearly independent code paths through a function. Calculated by counting decision points (if, else, switch case, loop, boolean operator).

```
CC = 1 (base) + 1 per if/else + 1 per switch case + 1 per loop + 1 per logical operator
```

**Interpretation:**
- 1–5: Simple, easy to test
- 6–10: Moderate, testable with care
- 11–15: Complex, refactoring recommended
- 16–20: Very complex, refactoring urgent
- 20+: Unmaintainable, refactor immediately

## Function Length

Measured in lines of code (LOC). Includes function signature and body, excludes blank lines and comments (sometimes).

**Common thresholds:**
- JavaScript/TypeScript: 20–50 LOC (max ~100)
- Python: 20–40 LOC (max ~50, PEP 8 cultural preference)
- Go: 20–50 LOC
- Java: 30–60 LOC

## File Size

Total LOC per file (including all functions/classes).

**Thresholds:**
- Python: 300–500 LOC; some prefer 200
- JavaScript/TypeScript: 300–500 LOC; Airbnb recommends ~300
- Go: 500–1000 LOC (Go files tend larger due to explicit error handling)
- Java: 500–1000 LOC (classes can be larger)

## Dependency Coupling

Count the number of other modules a given module imports/depends on.

**Levels:**
- 1–2: Excellent (high cohesion, low coupling)
- 3–4: Good
- 5+: At risk (ripple effect on changes; tight coupling)
- Circular (A → B, B → A): Problematic, refactor required

---

# 3. SOLID Principles Quick Reference

**S — Single Responsibility Principle (SRP)**
- A class/module should have only one reason to change
- Example violation: OrderService handling orders, payments, notifications (3 reasons to change)
- Example fix: Separate into OrderService, PaymentService, NotificationService

**O — Open/Closed Principle**
- Open for extension, closed for modification
- Example violation: Adding a new payment type requires editing ProcessPayment() function
- Example fix: Strategy pattern — each payment type is a class, dispatch via registry

**L — Liskov Substitution Principle (LSP)**
- Subtypes must be usable in place of base types without breaking contracts
- Example violation: PaymentAdapter subclasses have different return signatures
- Example fix: Ensure all implementations have identical method signatures and semantics

**I — Interface Segregation Principle (ISP)**
- Clients should not depend on interfaces they don't use (fat interfaces are bad)
- Example violation: OrderService exposes 10 public methods; clients only need 2–3
- Example fix: Separate interfaces: IOrderCreation, IOrderCancellation, IOrderExport

**D — Dependency Inversion Principle (DIP)**
- Depend on abstractions, not concrete implementations
- Example violation: OrderService directly instantiates PaymentHandler (concrete class)
- Example fix: Inject IPaymentHandler interface; clients are mockable, swappable

---

# 4. Code Smells Catalog

A **code smell** is a surface-level indicator that deeper problems may exist. Not always a bug, but signals for review.

| Smell | Definition | Example | Refactoring |
|---|---|---|---|
| **God Object** | Class with too many responsibilities | OrderService (orders + payments + notifications) | Split into separate classes |
| **God Function** | Function doing too much; CC >15 | ProcessPayment() handling 8 scenarios | Extract into strategy pattern |
| **Feature Envy** | Class knows too much about another class | PaymentValidator accessing 10 Order fields | Move logic into Order class |
| **Duplicate Code** | Same logic in multiple places | Validation try/catch in 3 handlers | Extract to utility/decorator |
| **Long Parameter List** | Function with 5+ parameters | `ProcessPayment(type, amount, currency, user, order, meta, retry)` | Use object parameter or builder |
| **Lazy Class** | Class with minimal functionality; why exists? | SingletonLogger wrapper | Inline or delete |
| **Data Clumps** | Same fields/parameters grouped in multiple places | `(userId, orderId, amount)` in 4 functions | Extract to Value Object |
| **Switch Statement** | Long switch on type; violates open/closed | Payment type dispatcher | Use Strategy pattern + registry |
| **Primitive Obsession** | Using primitives instead of types | String for user IDs; bool for states | Create UserId, OrderState types |
| **Comment Smell** | Code with excessive comments explaining logic | "// This loop iterates N times" | Refactor code to be self-explanatory |
| **Dead Code** | Unused functions/imports | `deprecated_calculate_tax()` never called | Delete |
| **Speculative Generality** | Over-engineered "for future use" | Abstract base class never used | Simplify |

---

# 5. Refactoring Patterns (Quick Reference)

| Pattern | Problem | Solution | Effort |
|---|---|---|---|
| **Extract Method** | Function too long | Pull complex block into new function | S |
| **Replace Conditional with Polymorphism** | Long if/switch | Use strategy pattern or inheritance | M |
| **Replace Data Value with Object** | Primitive obsession | Create UserId, OrderState types | S |
| **Introduce Parameter Object** | Long parameter list | Group related params into object | S |
| **Replace Magic Numbers with Constants** | Hard-coded values | Define named constants | S |
| **Extract Class** | God object | Split responsibilities into separate classes | L |
| **Introduce Service Locator/Dependency Injection** | Tight coupling | Inject dependencies via constructor | M |
| **Extract Superclass** | Duplication across classes | Pull common code into parent | M |
| **Introduce Design Pattern** | Ad hoc logic | Apply Strategy, Factory, Observer, etc. | M–L |

---

# 6. Glossary

| Term | Definition |
|---|---|
| **Cyclomatic Complexity (CC)** | Count of linearly independent code paths; lower is better |
| **Code Smell** | Surface-level indicator that deeper code quality issue exists |
| **Technical Debt (CQDEBT-NN)** | Intentional or accumulated quality issues that reduce maintainability |
| **SOLID** | Set of 5 principles for object-oriented design (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) |
| **DRY (Don't Repeat Yourself)** | Principle that repeated logic should be refactored into reusable functions/modules |
| **KISS (Keep It Simple, Stupid)** | Principle that simpler solutions are preferred; avoid over-engineering |
| **God Object/Function** | Class/function with too many responsibilities; violates SRP |
| **Coupling** | Degree to which modules depend on each other; high coupling = fragile |
| **Cohesion** | Degree to which a module's parts are related; high cohesion = maintainable |
| **Linting** | Automated static analysis to find code style/quality violations |
| **Refactoring** | Improving code structure without changing behavior |
| **Ports & Adapters (Hexagonal)** | Architecture pattern isolating domain logic from external dependencies |
| **Repository Pattern** | Abstraction over data access; decouples business logic from persistence |
