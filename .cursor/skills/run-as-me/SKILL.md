---
name: run-as-me
description: Run Cloud Agent GitHub API operations as the repo owner (OWNER_GH_TOKEN) when the user explicitly requests /runasme or run-as-me. Default is pawpet-bot via GH_TOKEN.
---

# Run as me (owner GitHub identity)

Applies **only** when the **current** user message opts in: `/runasme`, `run-as-me`, or “act as me on GitHub”
for this task. Opt-in is never implied from earlier chats. Default identity: `.cursor/skills/cloud-github-identity/SKILL.md`.

## What owner mode changes

Only `gh` and GitHub API calls (issues, labels, comments, reviews, merges, settings reads). **Git pushes and
Cursor-created PRs are unchanged** — they go through the Cursor GitHub App (`cursor[bot]`), whatever `GH_TOKEN` holds.

## Procedure

1. `OWNER_GH_TOKEN` must be set in Cursor Cloud secrets. Never print token values (lengths only).
2. In each shell block that touches GitHub:

   ```bash
   export GH_TOKEN="$OWNER_GH_TOKEN" GITHUB_TOKEN="$OWNER_GH_TOKEN"
   ```

3. Before the first owner write: `gh api user --jq .login` must be an owner in
   `.github/execute-plan.config.json` → `owners`, not `bot_login`.
4. **Allowed:** merges and reviews only the owner may perform, owner-only settings reads, debugging as the owner.
5. **Needs a second explicit confirmation in the same message:**
   - Any write that changes `.github/workflows/**`, `.github/scripts/agent-safety-lib.js`, environments or secrets
   - Force-push, deleting others' branches, merging a security/CI PR the user did not name
6. **Execute-plan:** never run `tick` or worker steps in owner mode — workers must act as `bot_login`.
7. The next chat defaults back to the bot (dashboard `GH_TOKEN`).

## If `OWNER_GH_TOKEN` is missing

Stop and ask the user to add it under Cursor → Cloud Agents → Secrets (owner classic PAT, `repo`; add `workflow`
only if they accept workflow-edit risk). Secrets reach new VMs only — an already-running agent will not see it.
