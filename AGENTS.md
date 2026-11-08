---
title: AGENTS.md
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-13
tags: [agent,workflow]
---
# AGENTS.md

Shared rulebook for **every** coding agent on this repo (Cursor, Claude Code, Copilot, Replit, others). Agent files
(`CLAUDE.md`, `.github/copilot-instructions.md`, `replit.md`, `.cursor/rules/*`) add only agent-specific mechanics and
link here. Before changing any instruction file: `docs/agent-efficiency/agent-instructions.md`.

**Agatha Track:** Flutter web (`flutter_app/`) + Node.js API (`server/`) + PostgreSQL. Map: `docs/architecture/index.md`.

## Operating rules (all agents)

### Precedence

When written instructions conflict, the higher one wins; then fix the losing text (a doc conflict is a PR, not a question).

1. The user's explicit instruction in the current conversation
2. Safety gates — sensitive paths (`.github/scripts/agent-safety-lib.js`), §Escalation in `docs/agent-efficiency/autonomous-pr-policy.md`
3. Active execute-plan v2 worker or driver session — §Execute-plan below
4. This file
5. Path-scoped rules (`.cursor/rules/*.mdc`)
6. Skills and procedures
7. Reference docs (`docs/agent-efficiency/`, `docs/architecture/`, `.cursor/agent-kernel/`)
8. Memory (`.agents/memory/`) — lessons only

Your product's default instructions apply except where this section narrows them.

### When to ask — critical only

Stop and ask the user **only** when one of these is true:

- An item on the §Escalation list in `docs/agent-efficiency/autonomous-pr-policy.md` (security/crypto, breaking API,
  production data migration, CI gate change, product or legal decision the canonical doc does not answer), or a
  sensitive-path change the task did not ask for.
- An action is destructive or irreversible beyond the task (data loss, production data migration, force-push to a shared branch, deleting others' work).
- The goal itself is unclear — you cannot state the outcome in one sentence.

Everything else — low confidence on in-scope work, review triage, follow-ups, minor wording conflicts between docs —
you decide, proceed, and record (PR body, issue or debt issue). Ask one question at a time, with your recommendation.

### Autonomy and merging

- Work you were asked to do includes opening the PR, pushing fixes and driving CI to green.
- **Merge** (squash, when `autonomous-pr-policy.md` §Merge gates pass) only when: the user asked you to merge or babysit that PR (invoking `/babysit`, `/babysit-plus` or `/babysit-uat` on it counts); an active execute-plan v2 worker/driver session requires it; or `/light-plan`, `/e2e-debug` or `/dependabot-batch` is in an **active session** (user invoked or resumed the skill; `/e2e-debug` delegated from `/babysit-uat` or execute-plan; `/dependabot-batch` started by `dependabot-batch-dispatch.yml`), and then only for PRs that skill opens (light-plan: phase/sync PRs into its integration branch, release PR via `/babysit-uat`; e2e-debug and dependabot-batch: PRs that skill opens, merge via `/babysit-uat` when the skill says so). Otherwise the user merges.
- One validated push per logical fix (`./scripts/pre-push-changed.sh` first) — every push costs full CI minutes. No push for comment/label-only changes.

### Reporting

- Evidence goes in the PR body (and the control issue for plans), not only in chat.
- Final message: outcome, verification run, docs updated (or why not), blockers. Do not end with an optional offer or a question unless it meets *When to ask*.

### Execute-plan (v2)

v2 plans: `env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent` decides; workers do
one agent action per launch and end the turn when the decision `actor` is `driver` or `stop` is set.
`gate` is an alias of `tick`. Spec: `docs/agent-efficiency/plans/execute-plan-v2.md` (shipped 2026-11-01).

## Toolchain

- Flutter 3.44.0 (`/opt/flutter/bin` on Cursor Cloud), Node 22, PostgreSQL 16 (`psql`)
- Cursor Cloud image, rebuild steps and version gate: `docs/engineering/cursor-cloud-environment.md`

### PostgreSQL (start each session)

```bash
sudo pg_ctlcluster 16 main start
```

Dev DB defaults (no `.env` needed): `agatha_db`, user `user` / password `password`, `localhost:5432`.

**Migrations:** `cd server && node scripts/migrate.js up`. Do not use `gen_random_uuid()` in SQL — generate UUIDs in code.

### Running the backend (single-origin E2E)

```bash
cd server && PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db node bin/start.js
```

Use `bin/start.js` (not `npm start`). Serves Flutter web build at `http://localhost:3000/` with API at `/backend`.

### Pre-push

| When | Command |
|------|---------|
| During iteration | `./scripts/pre-push-changed.sh` |
| Before merge to `main` | `./scripts/pre-push.sh` |

Full human checklist: `CONTRIBUTING.md`.

### Flutter

```bash
cd flutter_app && dart run build_runner build --delete-conflicting-outputs   # when mocks change
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration
```

Web build: `flutter build web --release --no-tree-shake-icons`

### Backend tests

`cd server && npx jest --env=node --forceExit` — mock pool, no live DB required.

### Calendar dates

User-facing dates are calendar days (`YYYY-MM-DD` on the wire). See `docs/architecture/calendar-dates.md`.

### Cursor Cloud GitHub identity

On **Cursor Cloud**, default `gh`/API identity is **`pawpet-bot`** (dashboard **`GH_TOKEN`** = bot classic PAT, **`repo` only**); git pushes and Cursor-created PRs always go through the Cursor GitHub App. GitHub Actions agent launches pass the bot token via **`EXECUTE_PLAN_BOT_TOKEN`** → Cursor `envVars`.

- **Owner mode:** user must opt in with **`/runasme`** — follow `.cursor/skills/run-as-me/SKILL.md` and use **`OWNER_GH_TOKEN`**.
- **Policy and secret layout:** `.cursor/skills/cloud-github-identity/SKILL.md` · `docs/engineering/cursor-cloud-environment.md`.

## GitHub issues

Agents can comment, close and add/remove labels; they cannot move GitHub Project board columns (no Projects write on
agent tokens — humans or Actions do that). The `busy` label signals active work:

```bash
node scripts/github_issue_workflow.js start-work --issue <n> --body "Work started …"
node scripts/github_issue_workflow.js comment --issue <n> --body "…"
```

Full lifecycle: `docs/agent-efficiency/github-issue-workflow.md`.

## Policy index

| Topic | Home |
|-------|------|
| Execute-plan v2 (`tick`, driver, babysit+ / babysit-uat) | `.cursor/skills/execute-plan/SKILL.md` · `docs/agent-efficiency/plans/execute-plan-v2.md` |
| Pre-PR self-review, review triage (Copilot; Bugbot retired) | `.cursor/rules/pr-hygiene.mdc` · `docs/agent-efficiency/pr-review-cost-efficiency.md` |
| One outcome per PR, snag ladder, zero untracked debt | `docs/agent-efficiency/atomic-pr-policy.md` |
| Canonical docs (product spec) | `docs/domains/documentation/standards.md` · canonical-docs skill |
| Branch targets (single-agent → `main`; sprints and execute-plan → integration `base_branch`) | `.cursor/rules/merge-policy.mdc` |
| Halt, escalation, merge gates, debt issues | `docs/agent-efficiency/autonomous-pr-policy.md` |
| CI cost (batch pushes, integration programmes) | `docs/agent-efficiency/pr-review-cost-efficiency.md` § GitHub Actions minutes |
| File size ≤500 lines · BDD gate | `node scripts/check_file_size.js` · `node e2e/scripts/check_bdd_coverage.js --report-only` |
| Single backend (Node.js only, no Dart in `server/`) | `.cursor/rules/single-backend.mdc` |
| UAT pipeline (pre-UAT E2E gates promotion) | `docs/e2e/uat-deploy-tiers.md` |
| Memory (lessons only) · sprint log | `.agents/memory/MEMORY.md` · `docs/debt/refactoring-log.md` |
