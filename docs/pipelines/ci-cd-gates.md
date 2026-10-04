---
title: CI/CD gates
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [ci, gates, pipeline]
---
# CI/CD gate contract

Single source of truth for **blocking vs advisory** automation and PROD promotion
prerequisites. GitHub branch/environment settings must match the check names below.

See also: [ci-cd-baseline.md](./ci-cd-baseline.md) (metrics), [CONTRIBUTING.md](../CONTRIBUTING.md) (contributor checklist),
[promotion-contract.md](./promotion-contract.md) (auto-promotion tags, idempotency, semver).

**Program status:** Phases -1–6 merged (#162–#168). Phase 7 (#169) closes build-artifact
hygiene. Gate contract below is the maintained source of truth for branch protection
and environment checks.

### Suggested next iteration track (post-program)

The hardening program (Phases -1–7) focused on gates, artifacts, and PR signal.
**Recommended follow-up initiative:** UAT deploy reliability.

| Metric | Baseline (2026-07-14) | Post-program sample (2026-07-15) | **Target (next 20 runs)** |
|--------|----------------------|----------------------------------|---------------------------|
| UAT deploy failure rate | 85% | 80% | **≤ 40%** |
| UAT deploy median duration | 42m | —* | **≤ 30m** (stretch) |

\* Re-measure with `scripts/ci/collect-baseline.sh` after a window of non-cancelled runs.

**Scope ideas (not yet scheduled):** live `@smoke` flake reduction (TLS/hosting),
localhost E2E stability on deploy-uat, supervised PROD promotion dry-run, regenerate
baseline table in [ci-cd-baseline.md](./ci-cd-baseline.md) when targets are met.

**Approved initiative (phased plan):** [e2e-ci-canary-plan.md](./e2e-ci-canary-plan.md) —
`@smoke-ci` on PR CI (retries 0), `@smoke-uat` on live UAT (retries 0), full E2E
shards unchanged for prod-ready. Prod security scans noted in Phase 6 (future).

## Quick reference

| Stage | Blocking? | Workflow |
|-------|-----------|----------|
| PR → `main` | **Yes** (2 required checks) | `ci.yml` → `ci-gate`, `codeql.yml` |
| Merge → `main` | **Yes** (async, does not block merge) | `pre-uat-e2e.yml` → `promote-uat.yml` → `uat-*` tag → `deploy-uat.yml` |
| PR granular CI jobs | Visible, not individually required | `ci.yml` (startup-smoke, test-suite, flutter-*, …) |
| PR startup smoke | **Yes** (via `ci-gate`) | `ci.yml` → `_reusable-pr-startup-smoke.yml` |
| PR hints | No (advisory) | `pr-governance-hints.yml` |
| Agent `cursor/*` PRs | **Yes** (forbidden paths — migrations, security config, infra, auth/billing/secrets routes) | `agent-pr-safety-gate.yml` |
| `uat-*` tag deploy | **Yes** (UAT + `prod-ready`) | `deploy-uat.yml` (tag push or `workflow_run` after promote) |
| Weekly E2E on `main` | **No** (signal only) | `e2e.yml` |
| PROD deploy / stub tag | **Yes** (environment when live) | `deploy-prod.yml` (auto after UAT `prod-ready`) |

---

## 1. Blocking — pull request to `main`

Triggered by `.github/workflows/ci.yml` → `_reusable-pr-startup-smoke.yml`,
`_reusable-test.yml`, and `codeql.yml`.

### GitHub required check names (branch protection)

**Required for merge (2 checks):**

| GitHub required check name | Workflow |
|----------------------------|----------|
| `ci-gate / CI passed` | `ci.yml` → `_reusable-ci-gate.yml` (aggregator — see maintenance note below) |
| `Analyze JavaScript` | `codeql.yml` (separate workflow; weekly schedule preserved) |

**Conditional:** `Forbidden path check` — agent `cursor/*` PRs only (`agent-pr-safety-gate.yml`).

#### `ci-gate` maintenance (dependency list drift)

The `ci-gate` job uses `needs:` on every blocking caller job in `ci.yml` and
`scripts/ci/assert-ci-gate.sh` mirrors the same list. **When you add, remove, or
rename a blocking CI job**, update **all three** in the same PR:

1. `.github/workflows/ci.yml` — new caller job + add to `ci-gate` `needs:` and `_reusable-ci-gate.yml` inputs
2. `scripts/ci/assert-ci-gate.sh` — `RESULTS` map and summary table row
3. This file — granular jobs table below (if the job is user-visible)

Missing an entry lets a failing job slip through while `ci-gate` stays green.

Reusable workflow jobs appear as **`{caller_job_id} / {reusable_job_name}`** on PRs.
The umbrella gate uses caller id `ci-gate` and reusable job name **`CI passed`**
→ required check **`ci-gate / CI passed`**. Granular flutter/test jobs remain visible
but are not individually required once the ruleset is migrated.

#### Granular CI jobs (visible on PR, not individually required)

| GitHub check name (job) | Caller job (`ci.yml`) | Reusable job `name:` | Workflow file |
|----------------------------|----------------------|----------------------|---------------|
| `startup-smoke / PR startup smoke` | `startup-smoke` | `PR startup smoke` | `_reusable-pr-startup-smoke.yml` |
| `test-suite / Governance (BDD + file size)` | `test-suite` | `Governance (BDD + file size)` | `_reusable-test.yml` |
| `flutter-analyze / Flutter (analyze & format)` | `flutter-analyze` | `Flutter (analyze & format)` | `_reusable-flutter-analyze.yml` |
| `flutter-coverage / Flutter domain coverage` | `flutter-coverage` | `Flutter domain coverage` | `_reusable-flutter-coverage.yml` |
| `flutter-integration / Flutter integration` | `flutter-integration` | `Flutter integration` | `_reusable-flutter-integration.yml` |
| `flutter-build-web / Build Flutter web` | `flutter-build-web` | `Build Flutter web` | `_reusable-build-web.yml` |
| `ci-e2e-canary / Playwright @smoke-ci canary (localhost)` | `ci-e2e-canary` | `Playwright @smoke-ci canary (localhost)` | `_reusable-e2e-local.yml` |
| `test-suite / Backend (Node.js Jest + Dart analyze)` | `test-suite` | `Backend (Node.js Jest + Dart analyze)` | `_reusable-test.yml` |
| `test-suite / E2E package audit` | `test-suite` | `E2E package audit` | `_reusable-test.yml` |
| `test-suite / Backend integration (PostgreSQL)` | `test-suite` | `Backend integration (PostgreSQL)` | `_reusable-test.yml` |
| `test-suite / ESLint (Pet Care policy ratchet)` | `test-suite` | `ESLint (Pet Care policy ratchet)` | `_reusable-test.yml` |
| `Analyze JavaScript` | — | `Analyze JavaScript` | `codeql.yml` (direct job; **required separately**) |

**Legacy branch protection (replace in ruleset):** the nine individual flutter/test
checks listed in **Main protection** ruleset should be removed when
**`ci-gate / CI passed`** is added. Keep `Analyze JavaScript`.

**Optional (visible, not required individually):** `flutter-test (<shard>) / Flutter tests (<shard>)` —
one matrix leg per shard in [`flutter_app/test/ci_shards.json`](../../flutter_app/test/ci_shards.json); the
aggregate `flutter-test` result and `flutter-coverage / Flutter domain coverage` are enforced via `ci-gate`.

**Blocking via `ci-gate`:** `ci-e2e-canary / Playwright @smoke-ci canary (localhost)` —
PR Playwright canary (`@smoke-ci`, retries 0), including three org journeys (discovery, profile, dashboard). Required when `flutter-build-web` succeeds; skipped when build fails (gate still fails on build). Enforced in `scripts/ci/assert-ci-gate.sh`. See [e2e-ci-canary-plan.md](./e2e-ci-canary-plan.md).

**Full org journey E2E** (frozen Shelter specs; 13 specs in `org-e2e-specs.mjs`) runs in **`ci-full-audit.yml`** only (scheduled/manual), **not** in active `pre-uat-e2e.yml` (9 **duration-balanced** Pet Care shards — see `node e2e/scripts/shard-files.mjs --summary`; indices shift when specs/timings change). Governance still runs `check-org-e2e-locators.mjs` when org Flutter changes without a matching E2E touch.

#### Path-scoped PR CI (`ci-scope`)

**Which PRs get CI:** PRs into `main`, into programme integration branches (`cursor/*-integration-*`) and
into agent work branches (`claude/**`) — the same PR tier everywhere, so phase PRs into an integration line
are no longer gated only by local pre-push (parallel-programmes §6 TEST.2).

`ci.yml` job **`ci-scope / Resolve CI scope`** classifies the PR diff (shared rules in
`scripts/ci/ci-scope-lib.sh`, also used by `pre-push-changed.sh`). Flutter jobs may be
**skipped** when out of scope; `ci-gate` accepts `skipped` only for jobs listed in
`skip_jobs` in the scope JSON.

| Always runs | May skip on narrow diffs |
|-------------|--------------------------|
| `startup-smoke`, `test-suite` (governance + backend + e2e audit), CodeQL | Flutter analyze*, shards, coverage, integration, build-web, `@smoke-ci` canary, `ci-e2e-affected` |

\*Flutter **analyze** still runs when `server/routes/**` or `server/lib/**` changed (API contract), even if `flutter_app/**` is untouched.

**E2E-only PRs** (`e2e/**` without `flutter_app/**`): skip the Flutter unit stack; run **cached web build** (when Flutter inputs unchanged) + `@smoke-ci` canary + **`ci-e2e-affected`** matrix legs chosen by `e2e/scripts/select-affected-specs.mjs` (≤720 s budget, ≤3 legs; broad infra edits keep tiers 0–1 only). `resolve-ci-scope.sh` drops `server/**` paths before selection so **backend-only PRs stay short** (canary + post-merge Pre-UAT cover server changes). `e2e/package.json` / `e2e/package-lock.json` still force the **full** CI stack.

**Web build cache:** `pre-uat-e2e.yml` on `main` **saves** `flutter_app/build/web`; PR `ci.yml` **restores** it (`web_cache: restore`). First PR after a cache miss builds normally. On cache **hit**, Flutter setup/build steps are skipped but **`verify-web-artifact.sh` still runs** on the restored tree. Cache key includes PostHog presence (`ph0`/`ph1`) and hashes build scripts plus `flutter_app` inputs.

**Force full suite:** PR label `ci-full`, commit message token `[ci-full]`, or `workflow_dispatch` with `force_full: true`.

**Never skip (force full):** migrations, `server/config/security.js`, `flutter_app/lib/core/**`, `e2e/package.json`, `e2e/package-lock.json`, `.github/workflows/**`, server/flutter lockfiles, `scripts/ci/**`.

#### Flutter shards (manifest-driven matrix)

Shards are defined once in [`flutter_app/test/ci_shards.json`](../../flutter_app/test/ci_shards.json)
(shard id → test roots). `scripts/ci/flutter-shards.mjs` serves every consumer: the `flutter-test` matrix
in `ci.yml` / `ci-full-audit.yml` (via ci-scope `run_shards`), `run_tests_ci_shard.sh`,
`merge_flutter_coverage.sh` and `pre-push.sh`. Governance runs `node scripts/ci/flutter-shards.mjs check`:
every active `*_test.dart` must be owned by **exactly one** shard (frozen roots from the frozen-domains
manifest and the integration dir are excluded). Adding or splitting a shard = editing the manifest only.

**Batched runner.** `run_tests_ci_shard.sh` → `scripts/ci/flutter-shard-runner.mjs` runs each shard in
batches of up to 24 files, one `flutter test --concurrency 4 --coverage` process per batch (instead of one
process per file, ~5–6 s startup each). Linux `flutter_tester` intermittently segfaults while collecting
coverage and the tool can then hang, so every batch runs under a no-progress watchdog (90 s): a failed batch
re-runs only its non-passing files one per process; a killed batch re-runs all its files one per process.
A file that passes only in isolation is reported as a warning in the job summary. Roots in the manifest's
`perFileRoots` (currently `test/features/auth`, which crashes the collector when batched) always run one
file per process. Coverage is merged in Node (`scripts/ci/lcov-merge.mjs`), so shards and the coverage job no
longer install apt `lcov`. Measured on a 4-vCPU box (2026-09-30): the six shards take 46–75 s each
(`auth`, whose files run one per process, is the longest); the `health` shard alone took 315 s with one process per file.

**All shards run whenever the Flutter stack runs.** Per-domain shard selection was removed in plan
`test-health-ci-5f3a`: with batched shards a full run costs about the wall-clock of one shard, and running
every shard keeps the domain coverage gate and cross-domain widget tests on every Flutter PR (they were
skipped on narrow PRs, and CI does not run on push to `main`). `pre-push-changed.sh` still narrows locally
by running `flutter test` under `test/features/<domain>/`.

**Drift backstop:** non-blocking **`CI full audit (main)`** (`ci-full-audit.yml`) runs the **full** suite on `main` every **12 merges** (counter in Actions cache `.ci-full-audit-state`) or when the last audit is older than **7 days**. Failures open an `agent-approved` issue for `agent-dispatch.yml`. Weekly `audit-advisory.yml` runs non-blocking `npm audit` on `main`.

#### Accepted trade-off: no CI re-run on merge to `main`

Auto-promotion (`promote-uat.yml`) does **not** re-run CI on the merge commit.
See [promotion-contract.md](./promotion-contract.md). PR gates + strict up-to-date merge
are the trust boundary.

#### Atomic branch-protection migration (`ci-gate`)

**Pre-merge (on the introducing PR):**

1. Wait for a **green CI run** showing **`ci-gate / CI passed`**.
2. Copy exact check name from the run:

```bash
gh pr checks <PR_NUMBER> | rg '^ci-gate'
```

**Merge + ruleset (single edit):**

1. **Settings → Rules → Rulesets** → **Main protection**
2. **Add** `ci-gate / CI passed`
3. **Remove** the nine legacy individual flutter/test checks (keep `Analyze JavaScript`)
4. Save once

**Verify:**

```bash
gh api repos/KanopeeKa/AgathaCheck/rulesets/18979034 --jq '.rules[] | select(.type=="required_status_checks")'
```

**Troubleshooting — “Expected — Waiting for status to be reported” for `CI passed`:**

The workflow reports **`ci-gate / CI passed`**, not bare **`CI passed`**. If the
ruleset lists `CI passed`, GitHub waits forever while `ci-gate / CI passed` is
already green (two different checks). Fix: remove `CI passed` from the ruleset,
add **`ci-gate / CI passed`** exactly (copy from `gh pr checks <PR>`).

```bash
gh pr checks 193 | rg '^ci-gate'
# ci-gate / CI passed    pass    …
```

#### Atomic branch-protection migration (Flutter parallel shards — historical)

Merging this change **removes** the legacy monolithic Flutter job from CI. Until branch
protection is updated, `main` may be briefly under-protected (no Flutter gate) or PRs may
be blocked (legacy required check never reports). Treat protection update as part of the
same rollout window as the merge — not a follow-up chore.

**Pre-merge (on the introducing PR — e.g. #170):**

1. Wait for a **green CI run** on the PR targeting `main`.
2. Copy exact check names from the run (do not guess):

```bash
gh pr checks <PR_NUMBER> | rg '^flutter-'
```

Expected new contexts — **verified on PR #170** (no `(pull_request)` suffix on this repo):

- `flutter-analyze / Flutter (analyze & format)`
- `flutter-coverage / Flutter domain coverage`
- `flutter-integration / Flutter integration`
- `flutter-build-web / Build Flutter web`

Re-verify before editing branch protection (names can differ by org/ruleset):

```bash
gh pr checks 170 | rg '^flutter-'
# or via API (authoritative check-run names):
gh api repos/KanopeeKa/AgathaCheck/commits/$(gh pr view 170 --json headRefOid -q .headRefOid)/check-runs \
  --jq '.check_runs[] | select(.name | startswith("flutter-")) | .name'
```

If your ruleset UI shows a `(pull_request)` suffix, use the **exact** string from
`gh pr checks` / the API — do not strip or add suffixes by hand.

**Merge + protection (single operator session, one ruleset save):**

1. Merge the PR to `main`.
2. Open **Settings → Branches** (classic) or **Settings → Rules → Rulesets**.
3. In **one edit**, before saving:
   - **Add** all four `flutter-*` checks listed above (and keep existing non-Flutter checks).
   - **Remove** `test-suite / Flutter (analyze, test, build web)` only after the four are added.
4. **Save once** (atomic). Do not remove the legacy check in a separate save first.

**Verify immediately after save:**

```bash
gh api repos/KanopeeKa/AgathaCheck/branches/main/protection \
  --jq '.required_status_checks.contexts'
# or for rulesets: inspect the ruleset required-check list in the UI
```

**Optional shard checks** (`flutter-test (<shard>) / Flutter tests (<shard>)`) need
not be required individually — `ci-gate` fails when any matrix leg fails.

**Codegen contract:** `flutter-prep` (`_reusable-flutter-prep.yml`) runs canonical `build_runner` +
legal sync once and uploads `flutter-prep-<sha>.tar.gz`; the `flutter-test` matrix and
`flutter-integration` download, verify, and restore that archive (no redundant prep in shards).
`flutter-analyze` runs its own codegen in parallel (it analyzes the mocks) and no longer gates shards.
`flutter-build-web` needs no prep: `build_runner` only generates test mocks and the web build uses the
committed legal assets, so it starts right after `ci-scope` (its canary path is the PR critical path).
Missing or corrupt prep artifacts fail at download/verify/restore with `::error::` annotations.

**Stability note:** Keep `ci.yml` caller ids (`startup-smoke`, `test-suite`, `flutter-analyze`, etc.) and reusable
job `name:` fields aligned with this table when renaming — branch protection matches these
display strings exactly.

| GitHub check name (job) | Workflow file | What it enforces |
|-------------------------|---------------|------------------|
| `startup-smoke / PR startup smoke` | `_reusable-pr-startup-smoke.yml` | Postgres bootstrap, `node bin/start.js`, `/backend/health` + root |
| `test-suite / Governance (BDD + file size)` | `_reusable-test.yml` | BDD mapping gate (`check_bdd_coverage.js`; run `--report-only` for live counts — gate is 68% of active scenarios), priority tags, file size ≤ 500 lines |
| `flutter-prep / Flutter prep (codegen + legal assets)` | `_reusable-flutter-prep.yml` | canonical codegen + legal sync; uploads `flutter-prep-<sha>` for shards and integration |
| `flutter-analyze / Flutter (analyze & format)` | `_reusable-flutter-analyze.yml` | format, codegen, analyze |
| `flutter-test (<shard>) / Flutter tests (<shard>)` | `_reusable-flutter-test-shard.yml` | matrix leg per shard in `flutter_app/test/ci_shards.json`, per-shard coverage |
| `flutter-coverage / Flutter domain coverage` | `_reusable-flutter-coverage.yml` | merge shard lcov, domain coverage ≥ 70% |
| `flutter-integration / Flutter integration` | `_reusable-flutter-integration.yml` | pet profile integration tests |
| `flutter-build-web / Build Flutter web` | `_reusable-build-web.yml` | web release build + `web-build-<sha>` artifact |
| `test-suite / Backend (Node.js Jest)` | `_reusable-test.yml` | Database-free unit coverage (`server npm run test:unit -- --forceExit --coverage`, excludes `test/db`), npm audit high+ |
| `test-suite / Backend integration (PostgreSQL)` | `_reusable-test.yml` | `server/test/db` suite on ephemeral PostgreSQL 16 (bootstrap-db + canonical schema), F-17 |
| `test-suite / ESLint (Pet Care policy ratchet)` | `_reusable-test.yml` | `validate_eslint.js` ratchet on policy modules, F-20 |
| `test-suite / E2E package audit` | `_reusable-test.yml` | e2e `npm audit` high+ and blocking helper unit tests (`e2e npm run test:unit`) |
| `Analyze JavaScript` | `codeql.yml` | CodeQL static analysis |

Required database tests remain strict: the PostgreSQL integration job runs
`server/test/db` against real PostgreSQL, and local full pre-push still runs
`npm test` with those suites included. Do not turn a missing database into a
passing or skipped required test. The unit-only CI command separates execution
environments; it does not replace transaction or concurrency verification.

**Note:** Exact check names appear in the GitHub PR checks UI. Verify periodically with:

```bash
gh pr checks <PR_NUMBER>
```

**Not run on every PR commit:** full Playwright E2E (too slow). Full E2E runs on UAT deploy and weekly cron.

#### Branch protection setup (`main`)

After Phase 6 merged (#168), add the startup smoke check using the **exact** string from
`gh pr checks` (not the job `name:` alone):

**Required new check:** `startup-smoke / PR startup smoke`

**GitHub UI (classic branch protection):**

1. Open **Settings → Branches** → edit the rule for **`main`** (or **Add rule**).
2. Enable **Require status checks to pass before merging**.
3. Enable **Require branches to be up to date before merging** (recommended).
4. In **Status checks that are required**, search for and add (see **Atomic branch-protection migration** above — add all four before removing legacy):
   - `startup-smoke / PR startup smoke` ← **new (Phase 6)**
   - Flutter parallel checks:
     - `flutter-analyze / Flutter (analyze & format)`
     - `flutter-coverage / Flutter domain coverage`
     - `flutter-integration / Flutter integration`
     - `flutter-build-web / Build Flutter web`
   - Existing CI checks if not already listed (see table above), e.g.:
     - `test-suite / Governance (BDD + file size)`
     - `test-suite / Backend (Node.js Jest + Dart analyze)`
     - `test-suite / E2E package audit`
     - `Analyze JavaScript`
5. **Remove** `test-suite / Flutter (analyze, test, build web)` in the **same** ruleset edit (step 4), then save once.
6. **Save changes**.

**Rulesets (if your org uses Rules → Rulesets instead of Branches):**

1. **Settings → Rules → Rulesets** → open the ruleset targeting **`main`**.
2. Under **Require status checks to pass** → **Add checks**.
3. Search `startup-smoke / PR startup smoke` and select it.
4. Save / publish the ruleset.

**Verify (admin or maintainer):**

```bash
gh pr checks 168   # or any open PR to main — copy exact check names
gh api repos/KanopeeKa/AgathaCheck/branches/main/protection \
  --jq '.required_status_checks.contexts'
```

If the search box does not show the new check, push a commit to a PR targeting `main` and
wait for one green **CI** run — GitHub only lists checks that have reported at least once.

---

## 2. Advisory — pull request to `main`

| Check / action | Workflow | Behavior |
|----------------|----------|----------|
| `Governance hints (advisory)` | `pr-governance-hints.yml` | PR comment only; does not block merge |
| `Forbidden path check` | `agent-pr-safety-gate.yml` | **Blocks** PRs from `cursor/*` branches that touch forbidden paths (migrations, `server/config/security.js`, `infra/`, auth/billing/secrets routes). Workflow edits under `.github/workflows/` are allowed when paired with gate doc updates. Human branches unaffected |

---

## 3. Blocking — UAT release pipeline

Full tier model: [e2e/uat-deploy-tiers.md](./e2e/uat-deploy-tiers.md).

**CI owns promotion:** every merge to `main` triggers async **Pre-UAT E2E**
(`pre-uat-e2e.yml` on `push`). Green E2E at current `origin/main` HEAD chains to
**Promote UAT** (`promote-uat.yml` via `workflow_run`) → `uat-*` tag → **Deploy UAT**
(`deploy-uat.yml` via `workflow_run`). Throttle: stale runs skip when `main` advanced.

Pre-UAT does **not** block merge — it runs post-merge only. Manual replay:
`workflow_dispatch` on `pre-uat-e2e.yml` or `promote-uat.yml`; ops localhost replay:
`scripts/agent-uat-babysit.sh` (see [e2e/uat-agent-babysit.md](./e2e/uat-agent-babysit.md)).

| Stage / job | Blocking? | Purpose |
|-------------|-----------|---------|
| Pre-UAT E2E (`pre-uat-e2e.yml`) | **No** (post-merge async) | Full localhost Playwright on `origin/main` HEAD |
| Promote UAT (`promote-uat.yml`) | **Yes** (implicit) | Create `uat-*` tag after green Pre-UAT at HEAD |
| `Build Flutter web` (`build-web`) | **Yes** | Web build + artifact for UAT deploy |
| `Build and deploy to UAT` (`deploy`) | **Yes** | FTP/SSH deploy |
| `UAT post-deploy smoke` (`smoke`) | **Yes** | HTTP health on live UAT (`scripts/uat-post-deploy-smoke.sh`) |
| `Prod ready` (`prod-ready`) | **Yes** (aggregate) | Required for PROD environment gate |

**Advisory (non-blocking):** `uat-live-e2e.yml` — nightly in-host SSH loopback API smoke (WAF-proof); optional manual browser `@smoke-uat` (WAF inconclusive).

**`prod-ready` validation:** `scripts/ci/assert-uat-gates.sh` — deploy + HTTP smoke + migrations only.

**Phase 4 build experiment:** UAT `build-web` skips `flutter clean` by default (`run_clean=false`).
Set repo variable `UAT_FLUTTER_CLEAN=true` on push, or `workflow_dispatch` input
`run_clean=true`, to restore the pre-experiment path. Manifest + job summaries record
`run_clean` for duration comparisons.

**Backend FTP staging (Phase 5):** UAT and PROD use `scripts/ci/stage-backend-deploy.sh`
(`--target uat` → `.uat-backend-deploy/`, `--target prod` → `.prod-backend-deploy/`).
Excludes `node_modules`, tests, and `.env`; copies `db/migrations/` into the staging tree.
Job summaries record `staging_dir` and `migration_count`.

**UAT database migrations (Phase 5):** when `UAT_SSH_ENABLED=true`, the SSH deploy
bundle runs `node scripts/migrate.js status` and records `migrate_pending_count` in
`~/.uat-deploy-state.env`. Set UAT environment variable `UAT_AUTO_MIGRATE=true` to
also run `migrate.js up` over SSH (mirrors prod). `prod-ready` fails when live
status shows pending migrations and auto-migrate is off. FTP-only deploys still
require manual SQL; the migration gate is skipped when status cannot be collected.

---

## 4. Signal only — weekly / manual E2E

Workflow: **E2E (Playwright)** — `.github/workflows/e2e.yml`

| Job | Blocks merge? |
|-----|---------------|
| `Playwright E2E (localhost)` | No |
| `Weekly E2E failed` (`notify-on-failure`) | No — warning on scheduled failure only |

### Weekly security and performance (advisory)

| Workflow | Schedule | Blocks merge? |
|----------|----------|---------------|
| `security-dast.yml` — ZAP baseline vs localhost stack | Mon 07:00 UTC | No (`continue-on-error`) |
| `perf-weekly.yml` — k6 `e2e/perf/api-smoke.k6.js` vs localhost | Mon 08:00 UTC | No (`continue-on-error`) |
| `audit-advisory.yml` — npm audit on `main` | Mon 06:00 UTC | No |

Web release builds also run `scripts/ci/check-web-bundle-budget.mjs` (ratchet via
`scripts/ci/web-bundle-budget.json`) inside `_reusable-build-web.yml`.

---

## 5. PROD deploy prerequisites

Workflow: **Deploy Production (agathatrack.com)** — `.github/workflows/deploy-prod.yml`

### Auto-promotion (default)

After **Deploy UAT** completes with green **`Prod ready`**, `deploy-prod.yml` runs via
`workflow_run` (no manual dispatch). If UAT failed or `Prod ready` was not green, the
**Block promotion when UAT failed** job fails the production workflow (no FTP/SSH, no stub
tag) so a green prod run always means promotion was allowed. Behaviour depends on repo variable
`PROD_DEPLOY_ENABLED`:

| `PROD_DEPLOY_ENABLED` | FTP/SSH deploy | Release tag |
|-----------------------|----------------|-------------|
| unset / not `true` | **Skipped** (intentional success) | `vX.Y.Z-rc.N` stub tag |
| `true` | Full deploy + smoke | Stable `vX.Y.Z` |

Stub mode writes an explicit step summary: no FTP/SSH steps ran. Semver is automatic
— see [promotion-contract.md](./promotion-contract.md).

### Manual `workflow_dispatch` / release publish

1. **Same commit SHA** validated on UAT (via `uat-*` tag deploy).
2. GitHub Environment **`PROD`** must require status check (live deploy only):
   - **`Deploy UAT / Prod ready`** (exact name — verify in Settings → Environments → PROD).
3. **Promoted web artifact** `web-build-<sha>` from a UAT run with green `Prod ready`.
4. Optional: environment reviewers / wait timer.

### PROD frontend promotion

| Path | When | Behavior |
|------|------|----------|
| **Promoted (default)** | UAT artifact exists | `download-uat-artifact.sh` → manifest provenance check → FTP deploy |
| **Fail closed** | Release publish, or dispatch without fallback | Job fails if artifact missing/expired |
| **Rebuild fallback** | `workflow_dispatch` + `rebuild_if_missing: true` | Rebuilds via `build-flutter-web.sh`; summary records `non-promoted-rebuild` |

`workflow_dispatch` inputs:

| Input | Purpose |
|-------|---------|
| `ref` | Commit SHA, tag, or branch (must match UAT-validated SHA) |
| `uat_run_id` | Pin specific UAT workflow run (recommended when multiple runs exist) |
| `rebuild_if_missing` | Audited override when artifact expired (default `false`) |

Build contract: [ci-build-artifact-contract.md](./ci-build-artifact-contract.md).

**Backend FTP staging:** `scripts/ci/stage-backend-deploy.sh --target prod` stages to
`.prod-backend-deploy/` (same exclusions as UAT). SSH runs `migrate.js up` + Passenger
restart over SSH after whitelisting the runner IP via `PROD_CPANEL_API_TOKEN` and
`scripts/o2switch-ssh-whitelist.sh` (no `npm ci` on CloudLinux — use cPanel Run NPM
Install when `package.json` changes).

Post-deploy blocking job:

| Job | Purpose |
|-----|---------|
| `Production post-deploy smoke` | `curl` health + landing |

---

## 6. Failure taxonomy

| Category | Examples |
|----------|----------|
| **Infra / transient** | Runner timeout, network flake |
| **Test regression** | Jest/Playwright/analyze failure |
| **Environment / hosting** | Passenger down, `node_modules` symlink, WAF, TLS |
| **Gate misconfiguration** | Wrong required check on environment, masked job failures |

---

## 7. Operator verification (`gh` CLI)

```bash
# Recent UAT deploy outcomes
gh run list --workflow=deploy-uat.yml --limit 10

# Gate jobs for a specific run
gh run view <RUN_ID> --json jobs --jq '.jobs[] | {name, conclusion}'

# PR required checks
gh pr checks <PR_NUMBER>

# Branch protection (admin)
gh api repos/KanopeeKa/AgathaCheck/branches/main/protection

# PROD environment protection rules
gh api repos/KanopeeKa/AgathaCheck/environments/PROD
```

Confirm **`Deploy UAT / Prod ready`** appears in the PROD environment required checks.

---

## 8. BDD coverage gate

Live counts: `node e2e/scripts/check_bdd_coverage.js --report-only`

Gate: **68% of active scenarios mapped** (computed by `e2e/scripts/check_bdd_coverage.js`; run `--report-only` for live counts). Do not hard-code scenario totals in docs or workflow comments.

---

## 9. Workflow run summaries

Major jobs append a standardized table to the Actions **Summary** tab via
`scripts/ci/append-summary.sh`. Fields include:

| Field | Meaning |
|-------|---------|
| `workflow` | Logical workflow id (e.g. `deploy-uat`) |
| `job` | Job name |
| `duration_sec` | Wall-clock job duration |
| `artifact` | Uploaded artifact name when applicable |
| `run_id` | GitHub Actions run id |

UAT `prod-ready` also writes a gate table via `scripts/ci/assert-uat-gates.sh`.

---

## Document maintenance

Update this file when:

- Adding/removing required jobs
- Changing PROD promotion rules
- Renaming workflows or jobs (GitHub check names follow `Workflow name / Job name`)
