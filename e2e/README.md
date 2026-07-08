# Agatha Track E2E / BDD Tests

Browser-level end-to-end tests for Agatha Track using [Playwright](https://playwright.dev). These tests drive the **real Flutter web UI** served by the Node backend on a single origin (`http://localhost:3000`), matching production deployment.

## Relationship to BDD feature files

Gherkin specifications live in:

```
flutter_app/test/bdd/features/
```

Playwright specs in `playwright/tests/` are annotated with `@bdd <feature>` comments and implement priority user journeys from those files. Over time we can wire [@cucumber/cucumber](https://github.com/cucumber/cucumber-js) to execute the `.feature` files directly; the page objects in `playwright/pages/` are the reusable layer for either approach.

### Current coverage

| Playwright spec | BDD feature | Journey |
|-----------------|-------------|---------|
| `auth.login.spec.ts` | `authentication.feature` | Log in with valid credentials; reject bad password |
| `auth.signup.spec.ts` | `authentication.feature` | Sign up success; password mismatch; email/password validation; duplicate email |
| `pet.profiles.spec.ts` | `pet_profiles.feature` | Empty list; create pet; view detail; edit name |
| `health.tracking.spec.ts` | `health_tracking.feature` | View due entry; mark one-time entry complete (API + UI); verify created entry on dashboard |
| `sharing.spec.ts` | `sharing.feature` | Create share link; view shared pet (anonymous); health/vet/owner on preview; accept share; invalid link |

## Flutter web notes

- Enable the semantics tree on load via `flt-semantics-placeholder` (handled in `playwright/support/flutter.ts`).
- Use `input[aria-label="…"]` for form fields; `fill()` alone is unreliable — the helper falls back to `pressSequentially`.
- Auth rate limiting is disabled when the server runs with `E2E=1` (set in `run-local.sh` and CI).

## Project layout

```
e2e/
  playwright/
    fixtures/       # Playwright fixtures (auth, seeded users)
    pages/          # Page objects (LandingPage, HealthDashboardPage, …)
    support/        # API seeding, Flutter wait helpers
    tests/          # Executable specs
  scripts/
    run-local.sh    # One-shot local runner
  playwright.config.ts
  package.json
```

## Prerequisites

- PostgreSQL 16 (`agatha_db` with default dev credentials)
- Flutter 3.32+ at `/opt/flutter/bin`
- Node 22+
- Flutter web build at `flutter_app/build/web`

## Quick start

```bash
# From repo root
chmod +x e2e/scripts/run-local.sh
./e2e/scripts/run-local.sh
```

Or step by step:

```bash
sudo pg_ctlcluster 16 main start

cd flutter_app && flutter build web --release --no-tree-shake-icons

cd server
PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db node bin/start.js

cd e2e
npm ci
npx playwright install chromium --with-deps
npm test
```

## Useful commands

```bash
cd e2e
npm run test:ui      # interactive UI mode
npm run test:headed  # watch the browser
npm run report       # open HTML report after a run
```

## CI

| Workflow | Trigger | Role |
|----------|---------|------|
| `ci.yml` | PR → `main` (+ manual dispatch) | Flutter analyze + unit/widget tests + web build; backend Jest |
| `codeql.yml` | PR → `main` (+ weekly schedule) | Static security analysis (JavaScript/TypeScript) |
| `e2e.yml` | manual + weekly cron (non-blocking) | Full Playwright against **localhost** |
| `deploy-uat.yml` | push → `release/uat-*` | Fast FTP deploy → post-deploy smoke + live `@smoke` E2E + full localhost E2E → `prod-ready` gate |
| `deploy-prod.yml` | manual `workflow_dispatch` (preferred) or release publish | FTP + SSH deploy; post-deploy HTTP smoke |

### UAT deploy flow

1. Cut `release/uat-*` from green `main` — **no unit-test re-run** (CI already validated the code).
2. `deploy` job FTP-publishes frontend + backend (~5 min).
3. In parallel: `smoke` (HTTP), `uat-e2e-smoke` (Playwright `@smoke` on live UAT), `uat-e2e-full` (full suite on localhost).
4. When all three pass, `prod-ready` goes green — configure the **PROD** GitHub Environment to require this check before `workflow_dispatch` deploys.
5. Apply UAT DB migrations manually when `db/migrations/` changes (FTP-only hosting).

### Prod deploy

Use **Actions → Deploy Production → Run workflow** with the UAT-validated commit SHA. Post-deploy smoke hits `https://agathatrack.com/backend/health` and `/landing`.

### `@smoke` tests

Tag fast, critical journeys with `@smoke` in the test title (e.g. login). Run locally:

```bash
cd e2e && npm run test:smoke
```

`@smoke` tests run **axe** accessibility scans after the journey completes. CI fails on **critical** and **serious** violations (see `playwright/support/axe.ts`).

Live UAT smoke E2E uses `E2E_BASE_URL=https://uat.agathatrack.com`. The UAT deploy workflow sets `E2E_TLS_INSECURE=1` because cPanel auto-SSL may present a certificate chain that GitHub Actions runners do not trust (curl exit 60 / Node `self-signed certificate`). Localhost E2E does not need this flag.

Set `E2E=1` on the UAT Node app if auth rate limits interfere.

## Writing new journeys

1. Add or extend a scenario in `flutter_app/test/bdd/features/`.
2. Add page object methods under `playwright/pages/` if needed.
3. Seed data via `playwright/support/api.ts` when setup is faster than UI.
4. Add a spec in `playwright/tests/` with a `@bdd` comment linking to the feature file.

## Selector strategy

Flutter web exposes an accessibility tree. Prefer, in order:

1. `getByRole('button', { name: '…' })`
2. `getByLabel('…')` for form fields
3. `getByText('…')` for visible copy from `app_en.arb`

Add `Semantics(identifier: …)` in Flutter only when the tree is insufficient.
