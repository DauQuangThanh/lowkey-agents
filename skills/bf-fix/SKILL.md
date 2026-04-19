---
name: bf-fix
description: Phase 2 of the Bug-Fixer workflow — walks the triage batch, applies patches on a named fix branch, and commits per bug. In interactive mode the operator (or Claude) edits the files between prompts; in auto mode the script records the current working-tree diff after each presumed edit, enforces file/line caps, and aborts for unsafe patches. Never pushes, never rewrites history, never touches the current branch directly.
license: MIT
compatibility: Bash 3.2+ / PowerShell 5.1+. Requires git 2.20+.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Fix loop

Applies patches for the triage batch. Safety rails:

- Refuses a dirty working tree (use `--dry-run` to inspect).
- Auto mode requires `--branch NAME`.
- `MAX_FILES_PER_FIX` and `MAX_LINES_PER_FIX` gate over-large patches in auto mode — they're deferred as BFDEBT.

## Canonical answer keys

- `BRANCH` (required for auto mode)
- `MAX_FILES_PER_FIX` (default `1`)
- `MAX_LINES_PER_FIX` (default `20`)
- `COMMIT_STYLE` (default `conventional`)

## Invocation

```bash
bash <SKILL_DIR>/bf-fix/scripts/fix.sh [--auto --branch NAME] [--dry-run]
pwsh <SKILL_DIR>/bf-fix/scripts/fix.ps1 [-Auto -Branch NAME] [-DryRun]
```
