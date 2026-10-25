---
name: cloud-github-identity
description: Default GitHub identity for Cursor Cloud Agents and Actions-launched agents (pawpet-bot). Read at session start on Cloud; pair with run-as-me when the user opts into owner mode.
---

# Cloud GitHub identity (default bot)

## Two identities on Cloud

| Operation | Identity |
|-----------|----------|
| `git push`, PRs created by Cursor (`ManagePullRequest`, `autoCreatePR`) | Cursor GitHub App (`cursor[bot]`) |
| `gh` and GitHub API calls (labels, comments, merges, execute-plan `tick`) | Token in `GH_TOKEN` |

## Cursor dashboard secrets

| Secret | Value | Purpose |
|--------|--------|---------|
| **`GH_TOKEN`** | `pawpet-bot` classic PAT (**`repo` only**) | Default `gh`/API identity |
| **`OWNER_GH_TOKEN`** | Owner classic PAT | **Only** with `/runasme` — `.cursor/skills/run-as-me/SKILL.md` |
| **`BOT_GH_TOKEN`** | Optional duplicate of the bot PAT | Not read by any code; prefer `GH_TOKEN` |

Check at session start (prints the login only): `gh api user --jq .login` → `pawpet-bot`. Secrets reach new VMs
only; a VM started before a secret change keeps the old values.

## GitHub Actions (`automation` environment)

| Secret | Purpose |
|--------|---------|
| **`EXECUTE_PLAN_BOT_TOKEN`** | Same bot PAT; the driver and issue/dispatch launches pass it as Cursor `envVars` (`GH_TOKEN`, `EXECUTE_PLAN_TOKEN`) |
| **`GH_PROJECTS_PAT`**, **`GH_PROJECT_ID`**, **`GH_STATUS_FIELD_ID`** | Project board updates (not the bot PAT) |
| **`cursor_api_key`** | Cursor API (secret names are case-insensitive) |

Launch `envVars` override dashboard secrets. The field is beta: where it is not enabled it is silently ignored, and
the agent falls back to dashboard `GH_TOKEN` — which is why that must also be the bot PAT.

## Bot PAT scopes (classic)

- **`repo` only** — branches, PRs, merge, issue labels/comments.
- **No `workflow`**, **no `project`** — Projects v2 uses `GH_PROJECTS_PAT`.

## Owner opt-in

User message includes **`/runasme`** → follow `.cursor/skills/run-as-me/SKILL.md`.

## Execute-plan

Workers must tick as **`bot_login`** (`pawpet-bot`). Never override with the owner token on plan workers.
