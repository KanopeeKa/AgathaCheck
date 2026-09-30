---
title: Agatha Track E2E / BDD Tests
owner: Documentation Team
audience: human
status: active
last_updated: 2026-08-21
tags: [testing,e2e,playwright]
---
# Agatha Track E2E / BDD Tests

Browser-level end-to-end tests for Agatha Track using [Playwright](https://playwright.dev). These tests drive the **real Flutter web UI** served by the Node backend on a single origin (`http://localhost:3000`), matching production deployment.

## Relationship to BDD feature files

Gherkin specifications live in:

```
flutter_app/test/bdd/features/
```

Playwright specs in `playwright/tests/` are annotated with `@bdd <feature>` comments and implement priority user journeys from those files. Over time we can wire [@cucumber/cucumber](https://github.com/cucumber/cucumber-js) to execute the `.feature` files directly; the page objects in `playwright/pages/` are the reusable layer for either approach.

**Navigation contract:** page-object actions must wait for route + ready state before returning. See [`docs/e2e/navigation-contract.md`](../docs/e2e/navigation-contract.md).

**UAT live ops:** symptom triage, env checklist, and prevention patterns — [`docs/e2e/uat-live-operations-runbook.md`](../docs/e2e/uat-live-operations-runbook.md). **WAF + queue lessons (Jul 2026):** [`docs/e2e/uat-waf-queue-lessons.md`](../docs/e2e/uat-waf-queue-lessons.md).

### Current coverage

Run `node e2e/scripts/check_bdd_coverage.js --report-only` for live gate counts (gate is 68% of active scenarios, computed by the script).

| Playwright spec | BDD feature | Scenarios mapped |
|-----------------|-------------|-----------------|
| `auth.login.spec.ts` | `authentication.feature` | 1 |
| `auth.signup.spec.ts` | `authentication.feature` | 5 |
| `health.tracking.spec.ts` | `health_tracking.feature` | 2 |
| `notifications.spec.ts` | `notifications.feature` | 9 |
| `organisation.management.spec.ts` | `organisation_management.feature` | 11 |
| `pet.profiles.spec.ts` | `pet_profiles.feature` | 4 |
| `sharing.spec.ts` | `sharing.feature` | 7 |
| `weight.tracking.spec.ts` | `weight_tracking.feature` | 9 |

## Flutter web notes

- Enable the semantics tree on load via `flt-semantics-placeholder` (handled in `playwright/support/flutter.ts`).
- Use `input[aria-label="…"]` for form fields; `fill()` alone is unreliable — the helper falls back to `pressSequentially`.
- Auth rate limiting is disabled when the server runs with `E2E=1` (set in `run-local.sh` and localhost CI).
- Live UAT E2E may send `X-E2E-Bypass-Token` on signup API calls when `E2E_BYPASS_TOKEN` is available to the smoke job. The UAT Node app must have matching `E2E_BYPASS_TOKEN` and `E2E_BYPASS_ALLOWED=true` (never on production). `deploy-uat.yml` passes `E2E_BYPASS_TOKEN` from GitHub secrets to the live smoke step.

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
- Flutter 3.44+ at `/opt/flutter/bin`
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
npm run test:ci-shard -- 1    # run CI shard 1 locally (requires stack running)
npm run report       # open HTML report after a run
```

## CI

Shard count for full localhost E2E is **nine** (active Pet Care specs only; frozen Shelter/Fostering specs are in `frozen-e2e-specs.mjs`). Shards are **duration-balanced** (LPT on `e2e/scripts/spec-durations.json`) — always inspect the live layout with:

```bash
node e2e/scripts/shard-files.mjs --summary
```

When changing shard count, update `SHARD_TOTAL` in `shard-files.mjs`, `matrix.shard` / `shard_total` in `pre-uat-e2e.yml`, `e2e.yml`, and `_reusable-e2e-local.yml` together.

**PR pre-merge E2E:** `ci.yml` job `ci-e2e-affected` runs a bounded subset of specs on localhost (`e2e/scripts/select-affected-specs.mjs`: ≤720 s, ≤3 legs) when the PR diff is E2E-only. E2E-only PRs skip the Flutter unit stack but still build web (often from cache) and run `@smoke-ci`. Backend-only PRs do not run affected legs.

```bash
cd e2e && npm run shard:plan    # list file groups per shard
cd e2e && npm run test:ci-shard -- 3   # run one shard locally (stack must be running)
```

| Workflow | Trigger | Role |
|----------|---------|------|
| `ci.yml` | PR → `main`, integration branches, `claude/**` | Path-scoped Flutter + web build + `@smoke-ci`; **affected E2E** on E2E-only diffs |
| `codeql.yml` | PR → `main` (+ weekly schedule) | Static security analysis (JavaScript/TypeScript) |
| `e2e.yml` | manual + weekly cron (non-blocking) | Full Playwright against **localhost** (9 duration-balanced shards) |
| `promote-uat.yml` | after Pre-UAT E2E green (`workflow_run`) + manual dispatch | Create `uat-YYMMDD-PR#` tag (see `docs/pipelines/promotion-contract.md`) |
| `pre-uat-e2e.yml` | `push` → `main` + `workflow_dispatch` | Full localhost Playwright (9 shards) — async post-merge, does not block merges |
| `deploy-uat.yml` | push → `uat-*` tag | FTP deploy → HTTP post-deploy smoke → `prod-ready` gate |
| `uat-live-e2e.yml` | nightly + manual (advisory) | Live `@smoke-uat` with WAF warmup — does not block promotion |
| `deploy-prod.yml` | auto after UAT `prod-ready` (+ manual dispatch / release) | Stub `vX.Y.Z-rc.N` tag or live FTP + SSH deploy; post-deploy HTTP smoke |

### UAT deploy flow

1. Merge PR to `main` → **Pre-UAT E2E** (`pre-uat-e2e.yml`) runs full localhost Playwright on `origin/main` HEAD.
2. On green E2E at HEAD → **`promote-uat.yml`** (`workflow_run`) creates `uat-YYMMDD-PR#` tag.
3. Tag triggers **`deploy-uat.yml`**; deploy job FTP-publishes frontend + backend (~5–15 min).
4. HTTP post-deploy smoke only (`scripts/uat-post-deploy-smoke.sh`) — no live WAF smoke on deploy path.
5. When `prod-ready` is green, **`deploy-prod.yml`** runs automatically (stub or live per `PROD_DEPLOY_ENABLED`).
6. **Advisory:** `uat-live-e2e.yml` exercises live UAT + Tiger Protect nightly.
7. UAT DB migrations: automatic when `UAT_SSH_ENABLED=true` and `UAT_AUTO_MIGRATE=true`; otherwise apply manually when `db/migrations/` changes.

### Prod deploy

**Default:** `deploy-prod.yml` runs automatically after green UAT **`Prod ready`** (stub semver tag when `PROD_DEPLOY_ENABLED` is not `true`; full deploy when `true`).

**Manual override:** **Actions → Deploy Production → Run workflow** with the UAT-validated commit SHA. Post-deploy smoke hits `https://agathatrack.com/backend/health` and `/landing`.

### Smoke tiers (`@smoke-ci`, `@smoke-uat`, `@smoke-a11y`)

Tag fast, critical journeys with tier tags in the test title. Run locally:

```bash
cd e2e && npm run test:smoke-ci    # PR canary (~3 journeys, retries 0, <2 min)
cd e2e && npm run test:smoke-uat    # UAT live smoke (retries 0)
cd e2e && npm run test:live-uat-gate # warmup-uat + smoke-uat (uat-live-e2e.yml advisory)
cd e2e && npm run test:smoke        # alias for test:smoke-uat
```

| Tag | Role |
|-----|------|
| `@smoke-ci` | PR CI canary subset (must also include `@smoke-uat`) |
| `@smoke-uat` | UAT live smoke (nightly advisory) + broader guardian paths; also runs in localhost `full` project (not `uat-smoke`, which is WAF/warmup-specific) |
| `@smoke-a11y` | axe accessibility scans (weekly / UAT + localhost `full`; not PR canary) |

`@smoke-a11y` tests run **axe** after the journey completes. CI fails on **critical** and **serious** violations (see `playwright/support/axe.ts`). `@smoke-ci` excludes axe for speed.

Before live `@smoke-uat` workers start, Playwright `globalSetup` probes `GET /backend/health` (15s timeout) and fails fast with a typed error when UAT is down, misconfigured, or serving a WAF challenge.

Live UAT smoke E2E uses `E2E_BASE_URL=https://uat.agathatrack.com`. The UAT deploy workflow sets `E2E_TLS_INSECURE=1` because cPanel auto-SSL may present a certificate chain that GitHub Actions runners do not trust (curl exit 60 / Node `self-signed certificate`). Localhost E2E does not need this flag. For live runs, also set `NODE_TLS_REJECT_UNAUTHORIZED=0` when probing UAT from Node (Playwright `globalSetup` pre-flight and `api.ts` seeding); browser tests use `ignoreHTTPSErrors` via the same `E2E_TLS_INSECURE=1` flag.

Set `E2E=1` on the UAT Node app if auth rate limits interfere.

## Writing new journeys

1. Add or extend a scenario in `flutter_app/test/bdd/features/`.
2. Add page object methods under `playwright/pages/` if needed.
3. Seed data via `playwright/support/api.ts` when setup is faster than UI.
4. Add a spec in `playwright/tests/` with a `@bdd` comment linking to the feature file.

Run browser tests with the same disposable `PGHOST`, `PGPORT`, `PGUSER` and
`PGDATABASE` as the local backend, and unset an unrelated `DATABASE_URL`.
`E2E_BASE_URL` controls HTTP requests only; non-care notification fixtures still
use SQL and must not inherit a different workspace database.

### Care occurrence journeys

Use `playwright/support/care-api.ts` to create care and perform occurrence
commands (complete, skip, plan another date, change date, postpone, resume and
undo). Do not insert, update or pin `health_occurrences` with SQL, or set
`next_due_date` to simulate completion; the server maintains those facts.
Use the general API helpers for users, pets and absences.

For deterministic scheduling cases, `withCareClock` supplies `X-Care-As-Of`
to both browser requests and care API helpers for the duration of the case.
The value is a local date-time in the pet's home timezone. Start the local
test server with `APP_ENV=ci` and `E2E=1`. The care clock is accepted only in
development/test/CI and is ignored and logged on UAT/production.
Live UAT and `@smoke-ci` canaries must remain clock-independent.

Fixed schedules intentionally store the next day's slots as well as today's
open slots. Assert dose rows by their calendar date, then verify the exact
completed occurrence and the remaining pending rows. An after-it's-done away
projection may contain both a real open occurrence and later estimated dates;
assert their IDs, sources and date basis separately.

Before landing CARE, run the full pre-push gate and all nine active localhost
shards. A manual `e2e.yml` run uses the same localhost stack on CI; verify its
web artifact and test checkout match the candidate commit. The active shard
manifest excludes frozen Shelter/Fostering specs, including adoption and
organisation pet management; do not enable those domains for this gate.

## Selector strategy

Flutter web exposes an accessibility tree. Prefer, in order:

1. `getByRole('button', { name: '…' })`
2. `getByLabel('…')` for form fields
3. `getByText('…')` for visible copy from `app_en.arb`

Add `Semantics(identifier: …)` in Flutter only when the tree is insufficient.
