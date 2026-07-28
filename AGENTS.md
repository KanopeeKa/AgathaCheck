# AGENTS.md

## Cursor Cloud specific instructions

This repo is **Agatha Track**: Flutter web (`flutter_app/`) + Node.js API (`server/`) + PostgreSQL.

**Agent quick-start:** `docs/architecture/index.md` · Skills in `.cursor/skills/` · Plan in `docs/agent-efficiency-plan.md`

### Toolchain

- Flutter 3.44.0 at `/opt/flutter/bin` (provisioned by `.cursor/Dockerfile` on Cloud Agents)
- Node 22, `psql` (PostgreSQL 16)
- Cloud environment: `.cursor/environment.json` + `.cursor/Dockerfile` — install/start via `.cursor/scripts/cloud-*.sh`

If a Cloud Agent pod reports missing `flutter` or `pg_ctlcluster`, confirm the repo uses Dockerfile mode (no `snapshot` field in `.cursor/environment.json`) and rebuild — see **Cloud environment rebuild** below.

### Cloud environment rebuild

The Flutter SDK is baked into the image via `.cursor/Dockerfile` (`FLUTTER_VERSION=3.44.0`). After a toolchain bump, **new pods must rebuild** from that Dockerfile — `cloud-install.sh` only runs `pub get` / `npm ci`, it does not upgrade `/opt/flutter`.

**Operator steps** (when agents still show Flutter 3.32 or `cloud-install.sh` fails the version gate):

1. Open [Cloud Agents → Environments](https://cursor.com/dashboard/cloud-agents#environments) for this repo.
2. Delete the saved environment for AgathaCheck, **or** create a fresh environment from the repo (do not use the interactive wizard snapshot — it ignores `build.dockerfile`).
3. Confirm `.cursor/environment.json` has `build.dockerfile` only — **no** `snapshot` field.
4. Start a new Cloud Agent from `main` (or a branch that includes the latest `.cursor/Dockerfile`).
5. Verify: `flutter --version` → **3.44.0** and `dart --version` → **3.12.x**.

`cloud-install.sh` fails fast when `/opt/flutter` exists but is the wrong version, with the message above.

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

Skill: `/pre-push-verify`. Full human checklist: `CONTRIBUTING.md`.

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

User-facing dates are calendar days (`YYYY-MM-DD` on the wire). See `docs/calendar-dates.md`.

### GitHub issues (Cloud Agents)

Agents can **comment**, **close**, and add/remove **labels** via `GH_TOKEN`. They **cannot** update GitHub Project board status (Projects write is not available on agent tokens).

Use comments + the `busy` label as the agent signal for active work:

```bash
node scripts/github_issue_workflow.js start-work --issue <n> --body "Work started …"
node scripts/github_issue_workflow.js comment --issue <n> --body "…"
```

Move Project board columns manually when you want **In Progress** / **Done** on the board. GitHub Actions workflows may still update the board when `GH_PROJECTS_PAT` is configured in repo secrets.

See `docs/github-issue-workflow.md` for the full issue lifecycle.

### Policies (details in `.cursor/rules/` + Skills)

- **Atomic PRs:** one verifiable outcome per PR; cross-domain OK when serving that outcome. Snag ladder + zero untracked debt → `docs/agent-efficiency/atomic-pr-policy.md`
- Modularity ≤500 lines · BDD 105/165 gate
- Single-agent PRs → `main`; multi-agent → integration branch (`/spawn-sprint-agents`)
- Memories: `.agents/memory/MEMORY.md`
- Sprint log: `docs/refactoring-log.md`
- Single-backend (Node.js only): no Dart port in `server/`
- **UAT pipeline:** `docs/e2e/uat-deploy-tiers.md` — pre-UAT E2E gates promotion; deploy is HTTP smoke only
