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

@.cursor/rules/agent-core.mdc
@.cursor/rules/merge-policy.mdc
@.cursor/rules/atomic-pr.mdc
@.cursor/rules/pr-hygiene.mdc
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
