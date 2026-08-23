---
name: spawn-sprint-agents
description: Coordinate parallel cloud agents on an integration branch with file ownership, foundation-first workflow, and single PR to main. Use when one request spawns multiple agents or sprint parallel work (E2E, route splits, screen splits).
---

# Spawn sprint agents

## When to use

- User requests parallel work across domains (E2E features, route splits, multiple screens).
- Sprint items in `docs/debt/refactoring-log.md` marked with parallel agents.

## Workflow

1. **Create integration branch** from `main`:
   ```
   cursor/sprint-<N>-<topic>-integration-13e3
   ```
2. **Publish ownership map** in `docs/debt/refactoring-log.md` before spawning:

   | Agent | Branch | Owns | Avoid |
   |-------|--------|------|-------|
   | foundation | merge first | `e2e/playwright/support/api.ts`, shared fixtures | — |
   | e2e-org | parallel | `organisation*.spec.ts`, `adoption*.spec.ts` | `api.ts` |
   | node-pets | parallel | `server/routes/pets/` | other domains |

3. **Foundation agent first** when shared files needed (`api.ts`, CI scripts, page object base classes).
4. **Spawn parallel agents** on **disjoint directories only**.
5. Each agent branch: `cursor/<descriptive-name>-13e3` from integration parent.
6. **Per-agent prompt must include:**
   - Sprint item ID (e.g. 6.1)
   - Integration branch name
   - Exact directory ownership
   - Exit criteria (scenarios mapped, tests green, files not to touch)
   - `./scripts/pre-push-changed.sh` during iteration
7. **Verify commits** landed on intended branch:
   ```bash
   git fetch origin
   git log --oneline origin/<branch> -5
   ```
8. **Single PR** integration → `main` when sprint gate met; coordinator runs `./scripts/pre-push.sh`.

## Default ownership splits

| Agent | Owns |
|-------|------|
| e2e-health | `health*.spec.ts`, health page objects |
| e2e-auth-pet | `auth.*.spec.ts`, `pet.profiles.spec.ts` |
| e2e-org | `organisation*.spec.ts`, `adoption*.spec.ts` |
| node-&lt;domain&gt; | `server/routes/<domain>/`, `server/test/<domain>/` |
| flutter-&lt;screen&gt; | one screen + `widgets/` subtree |

## Never parallelize

- Same spec file or page object
- `e2e/playwright/support/api.ts` (after foundation)
- `.github/workflows/`, `scripts/file-size-allowlist.json`
- Backend edits to the **same** endpoint across agents

## Recovery

Cherry-pick misplaced commits onto integration; do not re-run full work.

## Prompt templates

Copy-paste templates: `docs/agent-efficiency/prompt-templates.md`
