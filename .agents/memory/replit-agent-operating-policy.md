---
name: Replit agent operating policy (repo-aligned)
description: Binding rules distilled from AGENTS.md, .cursor/rules/*.mdc, and CI/CD gates that Replit work must follow on every request.
---

Repo docs are the source of truth. `.cursor/rules/*.mdc` + `AGENTS.md` are the authoritative shared engineering policy for ALL agents; `replit.md` is the project overview/preferences layer and must stay consistent with them. If any two sources conflict, stop and ask the user — never improvise a compromise. Inspect first, change second; smallest safe change.

**Per-request startup:** read the `.cursor/rules/*.mdc` relevant to the touched area (dual-backend, security, testing, modularity, atomic-pr), summarize applicable constraints, then implement.

**Binding engineering rules:**
- **Dual-backend parity**: Node (`server/routes/*.js`) is canonical; any route change (path/method/auth/validation/response shape) must be mirrored in Dart (`server/lib/*.dart`) in the same change set. Known allowed Node-only: audit logging, PostHog delete.
- **Modularity**: no new hand-written `.js`/`.dart` file >500 lines (CI-enforced via `scripts/check_file_size.js`); target <300.
- **Calendar dates**: wire dates are `YYYY-MM-DD` (see `docs/calendar-dates.md`).
- **Security**: never return raw `err.message`/`e.toString()`/`$e` in prod 5xx — use `publicError()`; rate-limit DB/filesystem routes; UUID filenames + path containment for uploads.
- **Atomic outcome**: one verifiable outcome per change set; snags >15 lines become separate work items, never silently deferred.

**Sensitive paths — explicit user confirmation required** (mirrors agent-pr-safety-gate): `.github/workflows/`, `db/migrations/`, `server/config/`, auth/session logic, deployment config.

**Migrations**: use `node scripts/migrate.js up` (AGENTS.md: `dart run bin/migrate.dart fresh` is BROKEN with pinned postgres driver — never use fresh). No `gen_random_uuid()` in SQL — generate UUIDs in code.

**Testing commands (current)**: backend `cd server && npx jest --env=node --forceExit`; Flutter `flutter test --concurrency=1 --exclude-tags=integration`; analyze with `--no-fatal-warnings --no-fatal-infos`; run `dart run build_runner build --delete-conflicting-outputs` when mocks change. BDD coverage gate: ≥105/165 mapped scenarios (`node e2e/scripts/check_bdd_coverage.js`).

**CI/CD (do not break)**: only umbrella `ci-gate / CI passed` is required on PRs — any new blocking job must be added to ci-gate `needs` AND `scripts/ci/assert-ci-gate.sh`. Promotion is tag-first and automated: merge to main → `promote-uat` creates `uat-YYMMDD-PR#` tag → `deploy-uat` via workflow_run → `Prod ready` gate → `deploy-prod` (artifact promotion, provenance-checked; `PROD_DEPLOY_ENABLED`, `UAT_SSH_ENABLED`, `UAT_AUTO_MIGRATE` flags). Tags immutable. UAT `node_modules` must stay a symlink.

**PR flow (user decision):** GitHub branch protection enforces PRs to `main`; prefer routing changes through a PR (so ci-gate + CodeQL run) where practical rather than direct-to-main commits.

**Dart/Node parity gap (known state, decision pending):** Dart lags Node — share-by-code is a 501 stub, foster placements partial; Replit preview runs the Dart server so those features look broken in preview but work on UAT/prod. Do not "fix" as a regression; discuss with user first.

**Why:** The user works across Cursor and Replit and requires zero drift between agents; these gates are CI-enforced, so violating them locally produces work that cannot merge.

**How to apply:** Re-read this file at the start of every task; when a task touches an area listed here, follow the rule or stop and ask — do not improvise a compromise between conflicting sources.
