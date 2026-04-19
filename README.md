# lowkey-agents

A complete **software project team** implemented as 14 portable agent definitions. Each agent plays a distinct role — from gathering requirements to designing architecture, writing code plans, managing sprints, reviewing code quality and security, reverse-engineering existing codebases, and **applying bug fixes with full upstream/downstream change tracking**.

Every agent is backed by **Agent Skills** with cross-platform Bash and PowerShell scripts. The agents are **IDE-agnostic** and can be installed into any project that supports agent definitions (Claude Code, Windsurf, Cursor, OpenCode, Cline, Roo Code, and others).

**Status:** 14/14 agents run end-to-end in `--auto` mode via their `run-all.{sh,ps1}` orchestrator. See [INTEGRATION-TEST-REPORT.md](INTEGRATION-TEST-REPORT.md) for the full verification against a live scenario.

---

## Installation

Use the included installer scripts to copy agents and skills into your project:

```bash
# Linux / macOS
bash install.sh

# Windows / PowerShell
pwsh install.ps1
```

The installer auto-detects your project's IDE framework (`.claude/`, `.windsurf/`, `.cursor/`, `.opencode/`, `.cline/`, `.roo/`, etc.) and copies files into the correct structure.

**Non-interactive mode** (for CI/CD or scripting):

```bash
bash install.sh --target /path/to/my-project --force
```

**Uninstall:**

```bash
bash uninstall.sh --target /path/to/my-project
```

---

## Running an agent

Every agent can run in two ways:

```bash
# Interactive — you answer numbered-choice questions
bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh

# Auto — orchestrator or CI; values come from env vars, an answers file, or upstream .extract files
bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh --auto
bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh --auto --answers ./answers.env
```

PowerShell equivalents use `-Auto` and `-Answers`. See each agent's `# Auto Mode` section for the canonical answer keys.

---

## The Team

Every agent supports **two modes**: interactive (a human drives) and auto (an orchestrator or CI drives via `--auto` / `-Auto`). The **Audience** column below indicates who the interactive mode is designed for; auto mode reads from `.extract` files, env vars, and an optional answers file so the audience assumption doesn't apply.

| Agent | Role | Audience | Output | Skills |
|-------|------|----------|--------|--------|
| **business-analyst** | Gathers and validates business requirements | Non-technical | `ba-output/` | 7 phases + orchestrator |
| **product-owner** | Backlog management, acceptance criteria, roadmap | Non-technical | `po-output/` | 5 phases + orchestrator |
| **scrum-master** | Sprint planning, standups, retros, impediments, team health | Non-technical | `sm-output/` | 5 phases + orchestrator |
| **ux-designer** | Creates personas, wireframes, prototypes | Non-technical | `ux-output/` | 4 phases + orchestrator |
| **project-manager** | Project planning, tracking, risk, communication | Non-technical | `pm-output/` | 5 phases + orchestrator |
| **tester** | Test planning, case design, execution tracking | Mixed (QA + analysts) | `test-output/` | 4 phases + orchestrator |
| **architect** | System architecture, ADRs, C4 diagrams | Technical (architects, tech leads) | `arch-output/` | 6 phases + orchestrator |
| **developer** | Detailed design, coding standards, unit-test strategy | Technical (developers, tech leads) | `dev-output/` | 4 phases + orchestrator |
| **devops** | CI/CD, IaC, containers, monitoring, deployment | Technical (DevOps / SRE) | `ops-output/` | 6 phases + orchestrator |
| **test-architect** | Test strategy, automation framework, coverage, quality gates | Technical (test architects, QA leads) | `ta-output/` | 5 phases + orchestrator |
| **code-quality-reviewer** | Standards, complexity, patterns, quality scoring | Technical (engineers, tech leads) | `cqr-output/` | 4 phases + orchestrator |
| **code-security-reviewer** | OWASP, auth, data protection, dependency audit | Technical (AppSec engineers) | `csr-output/` | 5 phases + orchestrator |
| **technical-analyst** | Reverse-engineers source code into documentation | Technical (senior engineers, architects) | `re-output/` | 6 phases + orchestrator |
| **bug-fixer** | Triages bugs/CQDEBT/CSDEBT, **applies real code patches on a fix branch**, writes regression tests, and emits upstream/downstream change impact | Technical (developers, tech leads) | `bf-output/` + source code | 5 phases + orchestrator |

---

## Execution Order

See **[AGENT-TEAM-EXECUTION-ORDER.md](AGENT-TEAM-EXECUTION-ORDER.md)** for the full dependency graph, input/output matrix, and hand-off rules. Summary:

1. **Foundation:** business-analyst → architect (sequential, interactive)
2. **Parallel Design:** ux-designer, developer, devops, test-architect, project-manager
3. **Delivery Planning:** product-owner → scrum-master (PO before SM)
4. **Quality Assurance:** tester, code-quality-reviewer, code-security-reviewer (parallel)
5. **Reverse Engineering:** technical-analyst (standalone, for existing codebases)
6. **Bug Fixing:** bug-fixer (loops after any tester / CQR / CSR round — reads their outputs, patches source on a fix branch, feeds change impact back upstream and downstream)

---

## Features

- **IDE-agnostic** — works with Claude Code, Windsurf, Cursor, OpenCode, Cline, Roo Code, and others
- **One-click install** — cross-platform installer scripts with auto-detection
- **Dual-mode** — every agent supports interactive (human-driven) AND auto mode (orchestrator/CI-driven) via `--auto` / `-Auto`
- **End-to-end verified** — all 14 agents run cleanly via their `run-all.{sh,ps1}` orchestrator in auto mode and produce a FINAL deliverable ([integration test report](INTEGRATION-TEST-REPORT.md))
- **Answer sources** — env vars, `--answers FILE`, upstream `.extract` files, documented defaults (in that priority)
- **One-question-at-a-time** conversational flow for interactive agents; numbered choices, plain language
- **Cross-platform scripts** — Bash 3.2+ (macOS/Linux) and PowerShell 5.1+ (Windows), with behavioural parity between the two
- **Methodology-aware** — adapts for Agile/Scrum, Kanban, Waterfall, Hybrid
- **Debt tracking** — each agent tracks unknowns with unique prefixes (DEBT-NN, TDEBT-NN, DDEBT-NN, etc.); gaps in auto mode auto-log debts
- **Extract files** — each phase writes a machine-readable `.extract` companion next to its markdown output, so downstream agents consume structured data rather than re-parsing markdown
- **Elicitation rescues** — every agent has an "If the user is stuck" section with domain-specific coaching techniques
- **Automated validation** — final phases run completeness checks and compile deliverables
- **Self-contained skills** — each skill folder is independently runnable

---

## Project Structure

```
lowkey-agents/
├── README.md                        # This file
├── AGENT-TEAM-EXECUTION-ORDER.md    # Dependency graph & execution sequence
├── INTEGRATION-TEST-REPORT.md       # End-to-end pipeline verification report
├── CLAUDE.md                        # Project notes
├── install.sh / install.ps1         # Installer (Bash / PowerShell)
├── uninstall.sh / uninstall.ps1     # Uninstaller (Bash / PowerShell)
├── agents/                          # 14 agent definitions (one .md per agent)
└── skills/                          # 85 skill directories, grouped by agent:
    ├── ba-workflow + 7 BA phases       # project-intake, stakeholder-mapping, requirements-elicitation,
    │                                   # user-story-builder, nfr-checklist, requirement-debt-tracker,
    │                                   # requirements-validation
    ├── architecture-workflow + 6       # architecture-intake, technology-research, adr-builder,
    │                                   # c4-architecture, risk-tradeoff-register, architecture-validation
    ├── ux-workflow + 4                 # ux-research, ux-wireframe, ux-prototype, ux-validation
    ├── dev-workflow + 4                # dev-design, dev-coding, dev-unit-test, dev-validation
    ├── ops-workflow + 6                # ops-cicd, ops-infrastructure, ops-containerization,
    │                                   # ops-monitoring, ops-deployment, ops-environment
    ├── pm-workflow + 5                 # pm-planning, pm-tracking, pm-risk, pm-communication,
    │                                   # pm-change-management
    ├── po-workflow + 5                 # po-backlog, po-acceptance, po-roadmap,
    │                                   # po-stakeholder-comms, po-sprint-review
    ├── sm-workflow + 5                 # sm-sprint-planning, sm-standup, sm-retrospective,
    │                                   # sm-impediments, sm-team-health
    ├── ta-workflow + 5                 # ta-strategy, ta-framework, ta-coverage,
    │                                   # ta-quality-gates, ta-environment
    ├── test-workflow + 4               # test-planning, test-case-design, test-execution, test-report
    ├── cqr-workflow + 4                # cqr-standards, cqr-complexity, cqr-patterns, cqr-report
    ├── csr-workflow + 5                # csr-vulnerability, csr-auth-review, csr-data-protection,
    │                                   # csr-dependency-audit, csr-report
    ├── re-workflow + 6                 # re-codebase-scan, re-architecture-extraction,
    │                                   # re-api-documentation, re-data-model,
    │                                   # re-dependency-analysis, re-documentation-gen
    └── bf-workflow + 5                 # bf-triage, bf-fix, bf-regression,
                                        # bf-change-register, bf-validation
```

Each skill directory contains:
- `SKILL.md` — metadata and usage instructions
- `scripts/_common.sh` + `_common.ps1` — shared helper functions (or a shim that sources a sibling's)
- `scripts/<phase>.sh` + `<phase>.ps1` — phase implementation in both Bash and PowerShell

---

## Prerequisites

| Platform | Required | Recommended |
|----------|----------|-------------|
| Linux | Bash 3.2+ | Bash 4+ |
| macOS | Bash 3.2 (built-in) | — |
| Windows | PowerShell 5.1 (built-in) | PowerShell 7+ |

---

## License

MIT

## Author

Dau Quang Thanh