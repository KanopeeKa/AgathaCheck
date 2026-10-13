---
title: CLAUDE.md
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-13
tags: [agent,workflow]
---
# CLAUDE.md

Claude Code entry point. The shared rulebook is `AGENTS.md` (imported below) — its §Operating rules narrow Claude
Code's default instructions. This file holds **only** Claude Code mechanics; edit the source files, not copies here.
Layer model and budgets: `docs/agent-efficiency/agent-instructions.md`.

@AGENTS.md
@.cursor/rules/atomic-pr.mdc
@.cursor/rules/documentation.mdc

## Rules that are not imported

- **Path-scoped rules** load from `.claude/rules/` when you read matching files. Each is a pointer — read its
  `.cursor/rules/*.mdc` source before editing there.
- **`pr-hygiene.mdc`**: read §Pre-PR critical self-review before opening a PR (order in the steward skill).
- **`merge-policy.mdc`**: branch targets for sprints and execute-plan integration branches.
- **`agent-core.mdc`**: Cursor commands index; its shared content is in `AGENTS.md`.
- **Protocols** (`.cursor/agent-kernel/protocols/*.md`): open the one for the surface you touch, e.g. `security.md`
  before auth or uploads, `database-and-migrations.md` before a schema change.
- **Memory** (`.agents/memory/MEMORY.md`): consult and update; referenced, not imported.

## Claude Code mechanics

- **Skills:** `/execute-plan` (`.claude/skills/execute-plan/`), `/canonical-docs`, steward (PRs Claude opens or
  drives). Other Cursor skills (`/babysit-plus`, `/babysit-uat`, `/e2e-debug`, `/ui-design-deep`): follow their
  `SKILL.md` procedure with Claude Code tools.
- **Not applicable:** `composer-2.5`, `ManagePullRequest`, merge-lease scripts, `/opt/cursor/artifacts/`.
- **GitHub:** GitHub MCP tools; `gh` as fallback.
- **PRs:** opening the PR is part of an implementation task you were asked to deliver (narrows "no PR unless asked").
  Merging follows `AGENTS.md` §Autonomy and merging.
- **Waiting on CI or review:** background watch (`run_in_background`, Monitor) or PR-activity subscription — never
  `sleep`. Execute-plan parking line, when a turn must end: `Parked on CI for <PR>; resuming on event.`
- **Subagents:** the brief names the canonical doc(s) and requires canonical-docs sync before handing back.

## Documentation duty

The canonical doc is the product spec (`docs/domains/documentation/standards.md`; procedure: `/canonical-docs`).

- **Before designing** a behaviour change, read the capability's canonical doc (domain `README.md`, then
  `docs/architecture/index.md`). Code, tests and doc disagreeing on intent is a product decision → *When to ask*.
- **Agreed spec or decision in chat** → `Planned` requirements + decision-log rows in the canonical doc; only a
  proposal or multi-PR plan goes in `changes/`. Never a new `*-decisions.md` or loose `docs/*.md`.
- **Before every behaviour commit or push:** canonical-docs sync, then `./scripts/pre-push-changed.sh`; `## Docs` in
  the PR body (or `Docs: N/A — <reason>`). A missing or stale doc update on a behaviour PR is blocking.
- **Final message:** name the canonical doc(s) updated and change docs folded or deleted — or why behaviour changed
  without docs. During execute-plan (gate `0`) this is deferred to `complete-plan` or a halt.
- A stale canonical doc outside the task's scope: say so and suggest a `consolidate` PR; never mass-migrate.
