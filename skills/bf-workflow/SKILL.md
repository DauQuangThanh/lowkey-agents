---
name: bf-workflow
description: Orchestrates the full Bug-Fixer workflow end-to-end. Runs all 5 phases in sequence (triage, fix, regression tests, change register, validation) and compiles BF-FINAL.md. Use when the user wants to burn down the bug/debt backlog in one session. Supports --auto (with mandatory --branch) for orchestrated/CI use and an interactive mode where the human drives each fix.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+. Requires git 2.20+.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Bug-Fixer — Full Workflow Orchestrator

Runs the 5 bug-fixer phases in sequence:

1. **bf-triage** — prioritise items from `test-output/bugs.md`, `cqr-output/05-cq-debts.md`, and `csr-output/*.md`
2. **bf-fix** — apply patches on a fix branch (one commit per fix)
3. **bf-regression** — create regression test stubs per applied fix
4. **bf-change-register** — aggregate change log with upstream + downstream impact
5. **bf-validation** — checks + compile `BF-FINAL.md`

## How to invoke

```bash
# Linux / macOS
bash <SKILL_DIR>/bf-workflow/scripts/run-all.sh --auto --branch bf/auto-20260419
bash <SKILL_DIR>/bf-workflow/scripts/run-all.sh --dry-run
bash <SKILL_DIR>/bf-workflow/scripts/run-all.sh  # interactive

# Windows / PowerShell
pwsh <SKILL_DIR>/bf-workflow/scripts/run-all.ps1 -Auto -Branch bf/auto-20260419
```

## Flags

| Flag | Meaning |
|---|---|
| `--auto` / `-Auto` | Non-interactive; no prompts |
| `--answers FILE` / `-Answers FILE` | Pre-filled KEY=VALUE answers |
| `--branch NAME` / `-Branch NAME` | Fix branch name (required in auto mode) |
| `--dry-run` / `-DryRun` | Show diffs, don't apply; don't touch git |

## Outputs

All under `bf-output/`:

- `01-triage.md` + `.extract` — prioritised batch
- `02-fixes.md` + `.extract` — per-fix diffs and commits
- `03-regression-tests.md` + `.extract` — test stubs for the tester
- `04-change-register.md` + `.extract` — **read by downstream reviewers**
- `05-upstream-impact.md` — **read by BA / architect / developer / UX on their next run**
- `06-validation-report.md` — automated checks + verdict
- `BF-FINAL.md` — executive summary
- `07-bf-debts.md` — deferred work
- `all-patches.diff` — consolidated batch diff
- `patches/<BUG-ID>.diff` — per-fix diffs

## Requirements

- Bash 3.2+ or PowerShell 5.1+/7+
- git 2.20+ (branches + per-fix commits)

## Environment overrides

- `BF_OUTPUT_DIR` — default `./bf-output`
- `TEST_OUTPUT_DIR`, `CQR_OUTPUT_DIR`, `CSR_OUTPUT_DIR` — auto-discovered upstream sources
