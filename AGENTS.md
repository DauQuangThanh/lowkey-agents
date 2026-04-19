## Project Overview

**Name:** lowkey-agents
**Description:** A portable, IDE-agnostic collection of 10+ software project team agents and 70+ agent skills. The agents cover the full software development lifecycle — from business analysis and architecture through development, testing, DevOps, project management, and code review. Each agent is backed by cross-platform Bash and PowerShell scripts. The project includes installer scripts that copy agents and skills into any target project, auto-detecting the IDE framework (.claude/, .windsurf/, .cursor/, .opencode/, .cline/, .roo/, etc.).
**Stack:** Bash (.sh) and PowerShell (.ps1)
**Owner / Team:** Dau Quang Thanh

---

## Structure

- `agents/` — 13 agent definition files (.md)
- `skills/` — 79 skill directories, each with SKILL.md + scripts/
- `install.sh` / `install.ps1` — Cross-platform installer
- `uninstall.sh` / `uninstall.ps1` — Cross-platform uninstaller
- `AGENT-TEAM-EXECUTION-ORDER.md` — Dependency graph and execution sequence

---

## Important Notes

- If any requirements, goals, definition of done, forbidden actions, failure modes & recovery, inputs/outputs, style, tone, process, or audience are unclear, ask before proceeding.
- If unsure about scope, ask before making large refactors.
- Agents and skills are IDE-agnostic — do NOT hardcode `.claude/` paths in agent definitions.
- Script paths within agents should use `skills/<name>/scripts/` (relative to where they are installed).
- MacOS doesn't support timeout command.
