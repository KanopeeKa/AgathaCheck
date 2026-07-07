# AGENTS.md

## Cursor Cloud specific instructions

This repo is **Agatha Track**: a Flutter web frontend (`flutter_app/`) + a backend API
(`server/`, available as both a Node.js/Express and a Dart/Shelf implementation) backed by
PostgreSQL. The Node backend is the canonical, fully-tested one and also serves the compiled
Flutter web bundle, so it is the recommended target for end-to-end work. Standard commands live
in `README.md` and `replit.md`; only the non-obvious cloud caveats are captured here.

### Toolchain locations
- Flutter 3.32.0 / Dart 3.8.0 live at `/opt/flutter/bin` and are added to `PATH` via `~/.bashrc`
  and `~/.profile`. A fresh login shell resolves `flutter`/`dart` automatically.
- Node 22 and `npm` are preinstalled. `psql` (PostgreSQL 16 client/server) is installed system-wide.

### PostgreSQL (must be started each session)
The update script intentionally does not start services. PostgreSQL data persists in the VM
snapshot but the server is not auto-started, so begin each session with:
```
sudo pg_ctlcluster 16 main start
```
The dev database matches the backend's built-in defaults, so **no `.env` is needed**:
database `agatha_db`, role `user` / password `password`, on `localhost:5432`. The schema is
already applied and persists in the snapshot.

### Database schema / migrations
- `dart run bin/migrate.dart fresh` is **broken** with the pinned `postgres` Dart driver (it sends
  the multi-statement canonical schema as a prepared statement and fails with
  `42601: cannot insert multiple commands into a prepared statement`). To (re)initialize a fresh DB,
  apply the canonical schema directly with psql and then mark the incremental migrations applied:
  ```
  psql -h localhost -U user -d agatha_db -f db/migrations/v3__initial_uuid_schema.sql
  # then INSERT each 001..007 NNN_*.sql name into the _migrations table
  ```
- For incremental migrations on an existing DB use the Node runner:
  `cd server && node scripts/migrate.js up` (or `status`). It reads `PG*`/`DATABASE_URL` env vars.
  
- gen_random_uuid() is not  available on the project PostgreSQL deployment - do not use and ensure unique id is generated in code. 

### Running the backend (single-origin E2E)
- Start with `cd server && node bin/start.js` — **not** `npm start`. `bin/server.js` only *exports*
  the Express app; `bin/start.js` is the file that calls `app.listen` (default `PORT=3000`).
- Pass the DB env vars when launching, e.g.
  `PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db node bin/start.js`.
- The Node server serves the Flutter web build from `flutter_app/build/web` and mounts the API under
  `/backend/api/...` on the **same origin**. On web the frontend resolves the API at `/backend`
  (see `flutter_app/lib/core/providers/api_base_url_provider.dart`), so for an E2E UI test you must
  build the web bundle and open the app through the Node server (http://localhost:3000/), not the
  Flutter dev server.

### Frontend (Flutter)
- Run codegen before analyzing/testing: `cd flutter_app && dart run build_runner build --delete-conflicting-outputs`.
  Without the generated `*.mocks.dart` files, `flutter analyze` and `flutter test` report missing-file
  errors. The generated files persist in the snapshot, so this is only needed after dependency/test changes.
- Build the web app with `flutter build web --release --no-tree-shake-icons` (matches CI).
- Lint/test: `flutter analyze --no-fatal-warnings --no-fatal-infos` and
  `flutter test --concurrency=1 --exclude-tags=integration`.

### Backend tests
`cd server && npx jest --env=node --forceExit` — uses a mock pool, so it does **not** require a
running database.

### Calendar dates (due dates, DOB, weight day, etc.)
User-facing dates are **calendar days**, not UTC timestamps. Serialize them as `YYYY-MM-DD` on the
API wire. All calendar fields must use PostgreSQL `DATE` columns (not `TIMESTAMPTZ`). See the full
personal + org field inventory in `docs/calendar-dates.md` and the shared helpers in
`flutter_app/lib/core/utils/calendar_date.dart`, `server/lib/calendarDate.js`, and
`server/lib/calendar_date.dart`.

### Modularity & refactoring (always apply)
- Follow `docs/architecture/modularity.md`: prefer small files, domain-by-domain changes, tests leading refactors.
- Hand-written files should stay under ~500 lines; split immediately if over ~800.
- Node route changes that affect HTTP behaviour require matching Dart Shelf parity in the same change when feasible.
- Park stubs and uncertain items in `docs/refactoring-debt.md` rather than deleting without review.
- Deferrals for product/infra (PostHog, GDPR, etc.) go in `docs/technical-debt.md`.
- Sprint refactor plan and status: `docs/refactoring-log.md`.
- Cursor project rules: `.cursor/rules/` (modularity, testing, security, dual-backend, accessibility, merge-policy).
- See `CONTRIBUTING.md` for full PR checklist.

### Merge policy & conflict avoidance
- Trunk-based: merge small PRs to `main` frequently; full Playwright E2E runs on UAT (`release/uat-*`) only.
- **Before every push:** `git fetch origin main && git rebase origin/main` (or merge) and resolve conflicts — duplicate commits on `main` are common.
- CI on `main`: Flutter analyze/test, blocking integration test, Jest, `dart analyze lib`, `npm audit --audit-level=high`, CodeQL.
- `dart format` is warn-only in CI for Sprint 1 (see `docs/refactoring-log.md`).

### Pre-push commands
```bash
cd server && npm audit --audit-level=high && npx jest --env=node --forceExit
cd flutter_app && dart run build_runner build --delete-conflicting-outputs
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration
```
