---
name: bf-change-register
description: Phase 4 of the Bug-Fixer workflow — aggregates the per-fix diffs into a single change register with upstream and downstream impact. Writes 04-change-register.md (the table downstream reviewers read) and 05-upstream-impact.md (the per-agent feed BA / architect / developer / UX read on their next run).
license: MIT
compatibility: Bash 3.2+ / PowerShell 5.1+
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Change register

Uses path heuristics to group modified files by upstream owner (BA / architect / developer / UX). Operators should refine the heuristic mapping via the `UPSTREAM_AGENTS` / `DOWNSTREAM_AGENTS` env vars when the repo's layout doesn't match common conventions.

## Canonical answer keys

- `UPSTREAM_AGENTS` (default `ba,architect,developer,ux-designer`)
- `DOWNSTREAM_AGENTS` (default `tester,code-quality-reviewer,code-security-reviewer`)

## Invocation

```bash
bash <SKILL_DIR>/bf-change-register/scripts/register.sh
pwsh <SKILL_DIR>/bf-change-register/scripts/register.ps1
```
