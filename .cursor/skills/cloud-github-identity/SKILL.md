---
name: cloud-github-identity
description: Default GitHub identity for Cursor Cloud Agents and Actions-launched agents (pawpet-bot). Read at session start on Cloud; pair with run-as-me when the user opts into owner mode.
---

# Cloud GitHub identity (default bot)

## Cursor dashboard secrets

| Secret | Value | Purpose |
|--------|--------|---------|
| **`GH_TOKEN`** | `pawpet-bot` classic PAT (**`repo` only**) | Default for Cloud Agent git/`gh` |
| **`OWNER_GH_TOKEN`** | Owner classic PAT | **Only** with `/runasme` — see `.cursor/skills/run-as-me/SKILL.md` |
| **`BOT_GH_TOKEN`** | Optional duplicate of bot PAT | Legacy alias; prefer single bot value in **`GH_TOKEN`** |

## GitHub Actions (`automation` environment)

| Secret | Purpose |
|--------|---------|
| **`EXECUTE_PLAN_BOT_TOKEN`** | Same bot PAT; driver + issue/dispatch launches pass it as Cursor `envVars` |
| **`GH_PROJECTS_PAT`**, **`GH_PROJECT_ID`**, **`GH_STATUS_FIELD_ID`** | Project board updates (not the bot PAT) |
| **`cursor_api_key`** / **`CURSOR_API_KEY`** | Cursor API |

## Bot PAT scopes (classic)

- **`repo` only** — branches, PRs, merge, issue labels/comments.
- **No `workflow`** — bot cannot push `.github/workflows/**` (intentional).
- **No `project`** — use **`GH_PROJECTS_PAT`** for Projects v2.

## Owner opt-in

User message includes **`/runasme`** → follow **`.cursor/skills/run-as-me/SKILL.md`**.

## Execute-plan

Workers must tick as **`bot_login`** (`pawpet-bot`). Driver injects bot token at launch; do not override with owner token on plan workers.
