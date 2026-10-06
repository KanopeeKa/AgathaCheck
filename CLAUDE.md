---
title: CLAUDE.md
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-09-15
tags: [agent,workflow]
---
# CLAUDE.md

This project's actual policies live in `AGENTS.md` and `.cursor/rules/*.mdc`
(Cursor's rule files). This file re-exports them via `@import` so Claude Code
picks up the current rules automatically every session — edit the source
files, not this one, unless you're adding a Claude-Code-only note below.

@AGENTS.md

## Cursor policy rules (imported live from `.cursor/rules/`)

Each imported file below keeps its own Cursor frontmatter (`globs: …` or
`alwaysApply: true`). Claude Code has no equivalent of Cursor's glob-based
conditional loading — every file here is always present in context — so
**apply a glob-scoped rule only to the surface its `globs:` line names**
(e.g. `security.mdc`'s `globs: server/**,server/lib/**` means its content
governs `server/**` changes, not a Flutter-only or docs-only diff). Rules
marked `alwaysApply: true` genuinely apply to every change regardless of
surface.

@.cursor/rules/agent-core.mdc
@.cursor/rules/merge-policy.mdc
@.cursor/rules/atomic-pr.mdc
@.cursor/rules/pr-hygiene.mdc
@.cursor/rules/documentation.mdc
@.cursor/rules/modularity.mdc
@.cursor/rules/security.mdc
@.cursor/rules/accessibility.mdc
@.cursor/rules/design.mdc
@.cursor/rules/testing.mdc
@.cursor/rules/single-backend.mdc
@.cursor/rules/pet-care-architecture.mdc
@.cursor/rules/agent-coordination.mdc

## Notes for Claude Code specifically

- The "Tier 1 commands" above (`/execute-plan`, `/babysit-plus`, `/babysit-uat`,
  `/e2e-debug`, `/ui-design-deep`) are Cursor slash-command workflows driven by
  `.cursor/agent-kernel/` and the Cursor Cloud Agents product — Claude Code
  cannot run them as slash commands. The underlying verification is
  tool-agnostic though: run `./scripts/pre-push-changed.sh` /
  `./scripts/pre-push.sh`, `node scripts/check_file_size.js`, and
  `node e2e/scripts/check_bdd_coverage.js --report-only` directly instead of
  waiting for a skill to do it.
- `/canonical-docs` is **not** Cursor-only: its procedure is tool-agnostic and
  Claude Code runs it via `.claude/skills/canonical-docs/`. PRs Claude opens or
  drives follow `.claude/skills/steward/SKILL.md`.
- `composer-2.5` is a Cursor-specific model setting for PR babysitting; it
  doesn't apply to Claude Code sessions.
- `.cursor/agent-kernel/protocols/*.md` are deep, per-surface checklists
  (`security.md`, `testing.md`, `authorization.md`, `api-contract.md`,
  `data-lifecycle.md`, `flutter-mobile.md`, `observability.md`,
  `dependency-review.md`, `database-and-migrations.md`,
  `accessibility.md`, `documentation.md`, `date-time.md`,
  `private-files.md`, `release-verification.md`) that Cursor's Router loads
  conditionally by risk tier. They're intentionally **not** imported above
  (to keep this file lean) — open the relevant one yourself when a change
  touches that surface, e.g. read `security.md` before touching auth or
  file uploads, `database-and-migrations.md` before a schema change.
- `.agents/memory/MEMORY.md` is shared institutional memory (both tools
  should consult and update it); it's referenced, not imported, since it
  changes independently of policy.

### Documentation duty (every turn)

The canonical doc is the product spec. Policy: `docs/domains/documentation/standards.md`. Procedure: `.cursor/skills/canonical-docs/SKILL.md`, run from Claude Code as `/canonical-docs`.

**Start of any task that touches product behaviour**
- Find the capability's canonical doc (domain `README.md`, then `docs/architecture/index.md`) and read it **before** designing or coding. Treat it as the spec.
- If the code, tests and the canonical doc disagree on intent, that is a product conflict. Do not silently pick one. Record it and ask, per the skill.

**When the user agrees a spec, decision or behaviour change in conversation**
- Write it where it will live: as `Planned` requirements and decision-log rows in the canonical doc.
- Only a proposal still under discussion, or a multi-PR delivery plan, goes in `changes/`, with `status: proposed` and the canonical doc it will fold into.
- Never create a new `*-decisions.md`, a per-evolution spec, or a loose `docs/*.md`.

**Before every commit or push that changes behaviour**
- Run canonical-docs **sync** (Mode A) *before* `./scripts/pre-push-changed.sh`.
- Update the canonical doc to the state after merge, fold in any `changes/` doc the work delivers, and delete it only if fully delivered.
- Add `## Docs` to the PR body (or `Docs: N/A — <reason>`).

**While driving a PR (CI, review events, check-ins)**
- Before each push, the docs gate must hold for the current diff.
- A missing or stale doc update on a behaviour PR is blocking. Fix it; don't defer it.
- Add the PR number to `related_prs` on the next push that happens anyway. Never push only for that.

**When delegating to a subagent**
- The brief names the canonical doc(s) and requires sync before handing back.

**When answering questions or reviewing**
- Answer from the canonical doc, and cite it.
- If you notice that a canonical doc is stale or contradicts the code, tell the user in your reply. Fix it only if the fix is inside the current task's scope. Otherwise suggest a `consolidate` PR for that capability; never mass-migrate.

**End of turn**
- If docs changed, the final message names the canonical doc(s) updated and any change docs folded or deleted. If behaviour changed but docs didn't, say why.
