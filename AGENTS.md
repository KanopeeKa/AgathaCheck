# AGENTS.md

## Cursor Cloud specific instructions

This repo is **Agatha Track**: Flutter web (`flutter_app/`) + Node/Dart API (`server/`) + PostgreSQL.

**Agent quick-start:** `docs/architecture/index.md` · Skills in `.cursor/skills/` · Plan in `docs/agent-efficiency-plan.md`

### Toolchain

- Flutter 3.32.0 / Dart 3.8.0 at `/opt/flutter/bin` (on `PATH` via `~/.bashrc`)
- Node 22, `psql` (PostgreSQL 16)

### PostgreSQL (start each session)

```bash
sudo pg_ctlcluster 16 main start
```

Dev DB defaults (no `.env` needed): `agatha_db`, user `user` / password `password`, `localhost:5432`.

**Migrations:** `cd server && node scripts/migrate.js up`. Do not use `dart run bin/migrate.dart fresh` (broken with pinned postgres driver). Do not use `gen_random_uuid()` in SQL — generate UUIDs in code.

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

### Policies (details in `.cursor/rules/` + Skills)

- Modularity ≤500 lines · dual-backend parity · BDD 81/161 gate
- Single-agent PRs → `main`; multi-agent → integration branch (`/spawn-sprint-agents`)
- Memories: `.agents/memory/MEMORY.md`
- Sprint log: `docs/refactoring-log.md`
