---
name: run-as-me
description: Run Cloud Agent GitHub operations as the repo owner (OWNER_GH_TOKEN) when the user explicitly requests /runasme or run-as-me. Default is pawpet-bot via GH_TOKEN.
---

# Run as me (owner GitHub identity)

Use this skill **only** when the user’s message clearly opts in: `/runasme`, `run-as-me`, or “act as me on GitHub” for **this** task.

## Default (no skill)

Cloud Agents use dashboard **`GH_TOKEN`** = **`pawpet-bot`** classic PAT (`repo` only). GitHub Actions launches also pass **`EXECUTE_PLAN_BOT_TOKEN`** as `envVars` (`GH_TOKEN`, `EXECUTE_PLAN_TOKEN`). Do **not** use owner credentials unless this skill applies.

## When this skill applies

1. Confirm opt-in in the **current** user message (not implied from earlier chats).
2. Read **`.cursor/skills/run-as-me/SKILL.md`** and follow it for the rest of the turn.

## Owner mode procedure

1. **Verify secret exists:** `OWNER_GH_TOKEN` must be set in Cursor Cloud secrets. Never log or print token values.
2. **Export for shell and `gh` only** (each block that touches GitHub):

   ```bash
   export GH_TOKEN="$OWNER_GH_TOKEN"
   export GITHUB_TOKEN="$OWNER_GH_TOKEN"
   ```

3. **Verify identity once per session before the first owner write:**

   ```bash
   gh api user --jq .login
   ```

   Must **not** be `pawpet-bot` (must match the repo owner login in `.github/execute-plan.config.json` → `owners`).

4. **Allowed:** merges only you should perform, owner-only settings, workflow edits when the user explicitly asked for this task, debugging as yourself.

5. **Forbidden without a second explicit confirmation in the same message:**
   - Editing **`.github/workflows/**` or **`.github/scripts/agent-safety-lib.js`**
   - Rotating or reading repository/environment secrets
   - Force-push, deleting others’ branches, or merging security/CI PRs the user did not name

6. **Execute-plan workers:** if `EXECUTE_PLAN_TOKEN` / worker `tick` requires `bot_login`, **do not** run owner `tick` — owner mode is for manual Cloud Agent work, not substituting execute-plan automation.

7. **End of task:** do not document tokens; next chat defaults back to bot via dashboard `GH_TOKEN`.

## If `OWNER_GH_TOKEN` is missing

Stop and tell the user to add it under Cursor → Cloud Agents → Secrets (owner classic PAT; scopes at least **`repo`**; avoid **`workflow`** unless they accept workflow-edit risk).

## Related docs

- `AGENTS.md` §Cursor Cloud GitHub identity
- `docs/engineering/cursor-cloud-environment.md`
- `docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md` §7.1
