# Refactoring log (by sprint)

Tracks planned and completed refactor / quality work. See also `docs/refactoring-debt.md` and `docs/architecture/modularity.md`.

**Policy:** One domain or screen per PR; merge to `main` frequently; full E2E on UAT only.

---

## Sprint 1 — Governance & CI (2026-07-07)

**Goal:** Codify standards in Cursor + CI; security and a11y pipelines; no product refactors.

| # | Action | Status | PR / notes |
|---|--------|--------|------------|
| 1.1 | Cursor rules (modularity, testing, security, dual-backend, a11y, merge-policy) | Done | `.cursor/rules/` |
| 1.2 | `CONTRIBUTING.md` + PR template | Done | |
| 1.3 | `docs/quality/scorecard.md` | Done | |
| 1.4 | CI: `npm audit --audit-level=high` (server + e2e) | Done | `_reusable-test.yml` |
| 1.5 | CI: CodeQL JavaScript | Done | `codeql.yml` |
| 1.6 | Dependabot (server, e2e, flutter_app pub) | Done | `dependabot.yml` |
| 1.7 | CI: `dart analyze lib` on server | Done | |
| 1.8 | CI: Node 22 alignment | Done | |
| 1.9 | CI: Flutter integration test blocking | Done | removed `continue-on-error` |
| 1.10 | CI: `dart format` check — **warn only** | Done | enforce in Sprint 2 |
| 1.11 | CI: coverage artifacts (report-only) | Done | |
| 1.12 | axe on UAT `@smoke` (critical + serious) | Done | `@axe-core/playwright` |
| 1.13 | Weekly non-blocking E2E cron on `main` | Done | `e2e.yml` |
| 1.14 | Extend `AGENTS.md` with merge/conflict policy | Done | |
| 1.15 | Fix npm audit highs (bcrypt 6, uuid 11, remove mocha) | Done | Unblocks CI audit gate |
| 1.16 | Fix blocking integration test (`petListProvider` override) | Done | |

**Sprint 1 exit criteria:** All items above merged; CI green on `main`.

---

## Sprint 2 — Legacy cleanup + first screen split (planned)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 2.1 | Remove root legacy `lib/` / `pubspec.yaml` if unused | Planned | `refactoring-debt.md` P1 |
| 2.2 | Remove `attached_assets/` from git | Planned | |
| 2.3 | Drop `npm run test:mocha` | **Done (Sprint 1)** | Removed with mocha/chai |
| 2.4 | Split `pet_form_screen.dart` (929 → <500) | Planned | Extract to `widgets/pet_form/` |
| 2.5 | Split `health_entry_form_screen.dart` (756 → <500) | Planned | Per widget README |
| 2.6 | Widget tests: `about`, `help`, `subscription` (smoke) | Planned | 0 tests today |
| 2.7 | **Enforce** `dart format` in CI (remove warn-only) | Planned | End of Sprint 2 |
| 2.8 | Playwright: `sharing.feature` implementation | Planned | + `@smoke` tag |
| 2.9 | Coverage threshold discussion (ratchet to 65% Flutter domain) | Planned | report-only → gate |

---

## Sprint 3 — Screen splits + backend test modularization (planned)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 3.1 | Split `pet_detail_screen.dart` | Planned | |
| 3.2 | Split `health_dashboard_screen.dart` | Planned | |
| 3.3 | Split `my_details_screen.dart` | Planned | |
| 3.4 | Split `server/lib/auth_routes.dart` → mirror `routes/auth/` | Planned | Dart parity |
| 3.5 | Split `server/test/auth.test.js` → `test/auth/` | Planned | 1012 lines |
| 3.6 | Split `server/test/pets.test.js` → `test/pets/` | Planned | 1072 lines |
| 3.7 | Playwright: `organisation_management.feature` | Planned | |
| 3.8 | Expand `notifications` widget tests | Planned | |

---

## Sprint 4 — Backend routes + BDD expansion (planned)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 4.1 | Split `server/routes/healthEntries.js` | Planned | |
| 4.2 | Playwright: `notifications.feature`, `weight_tracking.feature` | Planned | |
| 4.3 | BDD coverage target 50% of priority scenarios | Planned | |
| 4.4 | Resolve moderate `npm audit` findings (bcrypt 6.x, uuid) | **Done (Sprint 1)** | bcrypt ^6, uuid ^11 |

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-07 | Sprint 1 plan created; governance + CI implementation |
