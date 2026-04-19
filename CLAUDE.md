## Project Overview

**Name:** lowkey-agents
**Description:** A portable, IDE-agnostic collection of 10+ software project team agents and 70+ agent skills. The agents cover the full software development lifecycle — from business analysis and architecture through development, testing, DevOps, project management, and code review. Each agent is backed by cross-platform Bash and PowerShell scripts. The project includes installer scripts that copy agents and skills into any target project, auto-detecting the IDE framework (.claude/, .windsurf/, .cursor/, .opencode/, .cline/, .roo/, etc.).
**Stack:** Bash (.sh) and PowerShell (.ps1)
**Owner / Team:** Dau Quang Thanh

---

## Structure

- `agents/` — 14 agent definition files (.md)
- `skills/` — 79 skill directories, each with SKILL.md + scripts/
- `AGENT-TEAM-EXECUTION-ORDER.md` — Dependency graph and execution sequence

---

## Agent Inventory Mapping (Folder/File Convention)

Because each project can use different folder layouts and naming conventions, use the mapping below as the default reference and adapt paths as needed in your target repository.

| Agent | Agent Definition File | Primary Workflow Skill Folder | Typical Output Folder |
|---|---|---|---|
| business-analyst | `agents/business-analyst.md` | `skills/ba-workflow/` | `ba-output/` |
| architect | `agents/architect.md` | `skills/architecture-workflow/` | `arch-output/` |
| ux-designer | `agents/ux-designer.md` | `skills/ux-workflow/` | `ux-output/` |
| developer | `agents/developer.md` | `skills/dev-workflow/` | `dev-output/` |
| devops | `agents/devops.md` | `skills/ops-workflow/` | `ops-output/` |
| project-manager | `agents/project-manager.md` | `skills/pm-workflow/` | `pm-output/` |
| product-owner | `agents/product-owner.md` | `skills/po-workflow/` | `po-output/` |
| scrum-master | `agents/scrum-master.md` | `skills/sm-workflow/` | `sm-output/` |
| test-architect | `agents/test-architect.md` | `skills/ta-workflow/` | `ta-output/` |
| tester | `agents/tester.md` | `skills/test-workflow/` | `test-output/` |
| code-quality-reviewer | `agents/code-quality-reviewer.md` | `skills/cqr-workflow/` | `cqr-output/` |
| code-security-reviewer | `agents/code-security-reviewer.md` | `skills/csr-workflow/` | `csr-output/` |
| technical-analyst | `agents/technical-analyst.md` | `skills/re-workflow/` | `re-output/` |
| bug-fixer | `agents/bug-fixer.md` | `skills/bf-workflow/` | `bf-output/` |

Keep this mapping consistent across installer scripts, orchestrators, and documentation to avoid path drift.

---

## Important Notes

- If any requirements, goals, definition of done, forbidden actions, failure modes & recovery, inputs/outputs, style, tone, process, or audience are unclear, ask before proceeding.
- If unsure about scope, ask before making large refactors.
- Agents and skills are IDE-agnostic — do NOT hardcode `.claude/` paths in agent definitions.
- Script paths within agents should use `skills/<name>/scripts/` (relative to where they are installed).
- MacOS doesn't support timeout command.
