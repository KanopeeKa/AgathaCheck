---
title: Agent instruction architecture
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-13
tags: [agent-efficiency, agents, instructions, policy]
---

# Agent instruction architecture

**Purpose:** how instruction files for coding agents (Cursor, Claude Code, Copilot, Replit, others) are organised so
they do not drift or contradict. Read this before adding or changing **any** agent instruction file. The operating
rules themselves (precedence, when to ask, autonomy, execute-plan contract) live in [`AGENTS.md`](../../AGENTS.md)
§Operating rules — not here.

Decision: `DOCUMENTATION-STANDARDS-D-008` in [standards.md](../domains/documentation/standards.md) (rule 11).

---

## Layers

| Layer | Files | Holds | Loaded |
|-------|-------|-------|--------|
| L0 Platform | Product system prompts (not in repo) | Tool defaults | Always — repo narrows them only via `AGENTS.md` §Operating rules |
| L1 Shared entry | `AGENTS.md` | Operating rules, toolchain, commands, policy index | Always, every agent |
| L1 Agent entry | `CLAUDE.md`, `.github/copilot-instructions.md`, `replit.md`, `.cursor/rules/agent-core.mdc` | **Only** that agent's mechanics + a pointer to `AGENTS.md` | Always, that agent |
| L2 Rules | `.cursor/rules/*.mdc` | One home per engineering rule, path-scoped | By path (Claude via `.claude/rules/` pointer wrappers) |
| L3 Procedures | `.cursor/skills/*/SKILL.md` (canonical), `.claude/skills/*` (pointers + adaptations), `.cursor/commands/*` | Step-by-step workflows | On invocation |
| L4 Reference | `docs/agent-efficiency/*`, `docs/architecture/*`, `.cursor/agent-kernel/*` | Policy detail, schemas, checklists | Read on demand — never imported |
| L5 Memory | `.agents/memory/` | Agent lessons only (standards rule 10) | Index on demand |

## Rules for instruction files

1. **One home per rule.** Every other file links to the home; it never restates the rule in new words. If you need a
   rule in a second place, add a link — not a paraphrase.
2. **Agent entry files carry deltas only**: tool names, branch/push mechanics, how to wait, what does not apply.
   Anything true for every agent goes in `AGENTS.md` (or its L2/L4 home).
3. **Fix conflicts at the source.** A contradiction between two instruction files is a doc bug: fix the losing text in
   the same PR (precedence in `AGENTS.md`), do not add an override layer on top.
4. **Never add a layer to arbitrate layers.** New precedence tables, "override cards" or per-tool copies of policy are
   rejected in review; shrink the conflicting files instead.
5. **Budgets** (words of always-loaded text, frontmatter excluded — checked by gate I below):

   | Surface | Budget |
   |---------|--------|
   | `AGENTS.md` | ≤ 1,300 |
   | `CLAUDE.md` (own text, excluding imports) | ≤ 450 |
   | Claude always-loaded set (`CLAUDE.md` + its `@` imports) | ≤ 2,500 |
   | Cursor always-loaded set (`AGENTS.md` + `alwaysApply` rules) | ≤ 2,400 |
   | `.github/copilot-instructions.md` | ≤ 350 |
   | `replit.md` | ≤ 900 |
   | Any `SKILL.md` | ≤ 300 lines (target), 500 hard (file-size gate) |

6. **Platform-specific files must actually load.** Copilot path files need `applyTo:`; Claude path rules need `paths:`
   (a symlinked `.mdc` or an `@import` inside a rule file does **not** load — verified 2026-10-13); Replit reads only
   root `replit.md`.

## Owner map

| Topic | Home |
|-------|------|
| Precedence, when to ask, autonomy & merge, reporting, execute-plan contract, forbidden closers | `AGENTS.md` §Operating rules |
| Execute-plan valid-stop table, phase loop | `.cursor/skills/execute-plan/SKILL.md` §Stop rules |
| Platform-vs-repo overrides during execute-plan, Claude Code execute-plan mechanics | `execute-plan-instruction-stack.md` |
| Halt / escalation list, review triage, merge gates, debt issues | `autonomous-pr-policy.md` |
| Pre-PR self-review, review bots, model choice (Cursor) | `.cursor/rules/pr-hygiene.mdc` → `pr-review-cost-efficiency.md` |
| One-outcome PRs, snag ladder | `.cursor/rules/atomic-pr.mdc` → `atomic-pr-policy.md` |
| Branch targets, integration branches | `.cursor/rules/merge-policy.mdc` |
| Canonical docs duty | `.cursor/rules/documentation.mdc` → `standards.md` + canonical-docs skill |
| Toolchain, commands, pre-push | `AGENTS.md` |
| Sensitive paths | `.github/scripts/agent-safety-lib.js` |
| Cursor Cloud environment | [cursor-cloud-environment.md](../engineering/cursor-cloud-environment.md) |

## Enforcement

Gate **I** in `scripts/check_docs_canonical.js` (`scripts/lib/docs-canonical/gates-instructions.js`), all **WARN**
until promoted. Runs on every docs-gate run whose diff touches an instruction file; `--instructions` checks the whole
repo.

| Rule | Checks |
|------|--------|
| R-I1 | Budgets above (skill line target included) |
| R-I2 | `.github/instructions/*` filenames have no glob characters and each file has `applyTo:` |
| R-I3 | `.claude/rules/*.md` have `paths:` frontmatter and point at an existing `.cursor/rules/*.mdc` |
| R-I4 | Repo paths cited in agent entry files and `.claude/` exist |
| R-I5 | Forbidden closers (quoted in `AGENTS.md`) restated in other instruction files — link instead |
| R-I6 | Retired terms: `composer-2.5` outside Cursor files and its home doc; Bugbot as an active reviewer |

Delivery of the remaining consolidation (Cursor layer, promotion to blocking):
[agent-instruction-consolidation.md](../domains/documentation/changes/agent-instruction-consolidation.md).
