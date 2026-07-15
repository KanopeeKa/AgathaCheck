# CI/CD gate contract

Single source of truth for **blocking vs advisory** automation and PROD promotion
prerequisites. GitHub branch/environment settings must match the check names below.

See also: [ci-cd-baseline.md](./ci-cd-baseline.md) (metrics), [CONTRIBUTING.md](../CONTRIBUTING.md) (contributor checklist).

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

## Quick reference

| Stage | Blocking? | Workflow |
|-------|-----------|----------|
| PR → `main` | **Yes** (required checks) | `ci.yml`, `codeql.yml` |
| PR startup smoke | **Yes** (with CI) | `ci.yml` → `_reusable-pr-startup-smoke.yml` |
| PR hints | No (advisory) | `pr-governance-hints.yml` |
| Agent `cursor/*` PRs | **Yes** (forbidden paths) | `agent-pr-safety-gate.yml` |
| `release/uat-*` deploy | **Yes** (UAT + `prod-ready`) | `deploy-uat.yml` |
| Weekly E2E on `main` | **No** (signal only) | `e2e.yml` |
| PROD deploy | **Yes** (environment + smoke) | `deploy-prod.yml` |

---

## 1. Blocking — pull request to `main`

Triggered by `.github/workflows/ci.yml` → `_reusable-pr-startup-smoke.yml`,
`_reusable-test.yml`, and `codeql.yml`.

### GitHub required check names (branch protection)

Reusable workflow jobs appear as **`{caller_job_id} / {reusable_job_name}`** on PRs.
Do **not** use the reusable workflow file name (`_reusable-pr-startup-smoke.yml`) in
branch protection — use the strings below.

| GitHub required check name | Caller job (`ci.yml`) | Reusable job `name:` | Workflow file |
|----------------------------|----------------------|----------------------|---------------|
| `startup-smoke / PR startup smoke` | `startup-smoke` | `PR startup smoke` | `_reusable-pr-startup-smoke.yml` |
| `test-suite / Governance (BDD + file size)` | `test-suite` | `Governance (BDD + file size)` | `_reusable-test.yml` |
| `flutter-analyze / Flutter (analyze & format)` | `flutter-analyze` | `Flutter (analyze & format)` | `_reusable-flutter-analyze.yml` |
| `flutter-coverage / Flutter domain coverage` | `flutter-coverage` | `Flutter domain coverage` | `_reusable-flutter-coverage.yml` |
| `flutter-integration / Flutter integration` | `flutter-integration` | `Flutter integration` | `_reusable-flutter-integration.yml` |
| `flutter-build-web / Build Flutter web` | `flutter-build-web` | `Build Flutter web` | `_reusable-build-web.yml` |
| `test-suite / Backend (Node.js Jest + Dart analyze)` | `test-suite` | `Backend (Node.js Jest + Dart analyze)` | `_reusable-test.yml` |
| `test-suite / E2E package audit` | `test-suite` | `E2E package audit` | `_reusable-test.yml` |
| `Analyze JavaScript` | — | `Analyze JavaScript` | `codeql.yml` (direct job) |

**Optional (visible, not required individually):** `flutter-test-{pet,health,org,rest} / Flutter tests (<shard>)` —
the merge gate `flutter-coverage / Flutter domain coverage` covers shard failures.

**Removed (replace in branch protection):** `test-suite / Flutter (analyze, test, build web)` — split into the
`flutter-*` checks above (parallel shards initiative).

#### Atomic branch-protection migration (Flutter parallel shards)

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

**Optional shard checks** (`flutter-test-{pet,health,org,rest} / Flutter tests (<shard>)`) need
not be required individually — `flutter-coverage` fails when any shard fails.

**Codegen contract:** `flutter-analyze` runs canonical `build_runner` + legal sync once and
uploads `flutter-prep-<sha>.tar.gz`; downstream `flutter-test-*`, `flutter-integration`, and
`flutter-build-web` download, verify, and restore that archive (no redundant prep in shards).
Missing or corrupt prep artifacts fail at download/verify/restore with `::error::` annotations.

**Stability note:** Keep `ci.yml` caller ids (`startup-smoke`, `test-suite`, `flutter-analyze`, etc.) and reusable
job `name:` fields aligned with this table when renaming — branch protection matches these
display strings exactly.

| GitHub check name (job) | Workflow file | What it enforces |
|-------------------------|---------------|------------------|
| `startup-smoke / PR startup smoke` | `_reusable-pr-startup-smoke.yml` | Postgres bootstrap, `node bin/start.js`, `/backend/health` + root |
| `test-suite / Governance (BDD + file size)` | `_reusable-test.yml` | BDD mapping ≥ 105 scenarios, priority tags, file size ≤ 500 lines |
| `flutter-analyze / Flutter (analyze & format)` | `_reusable-flutter-analyze.yml` | format, legal sync, codegen, analyze; uploads `flutter-prep-<sha>` |
| `flutter-test-* / Flutter tests (<shard>)` | `_reusable-flutter-test-shard.yml` | domain test shards (pet, health, org, rest) with per-shard coverage |
| `flutter-coverage / Flutter domain coverage` | `_reusable-flutter-coverage.yml` | merge shard lcov, domain coverage ≥ 65% |
| `flutter-integration / Flutter integration` | `_reusable-flutter-integration.yml` | pet profile integration tests |
| `flutter-build-web / Build Flutter web` | `_reusable-build-web.yml` | web release build + `web-build-<sha>` artifact |
| `test-suite / Backend (Node.js Jest + Dart analyze)` | `_reusable-test.yml` | Jest, npm audit high+, `dart analyze lib` |
| `test-suite / E2E package audit` | `_reusable-test.yml` | e2e `npm audit` high+ |
| `Analyze JavaScript` | `codeql.yml` | CodeQL static analysis |

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
| `Forbidden path check` | `agent-pr-safety-gate.yml` | **Blocks** PRs from `cursor/*` branches that touch forbidden paths; human branches unaffected |

---

## 3. Blocking — UAT deploy (`release/uat-*`)

Workflow: **Deploy UAT (uat.agathatrack.com)** — `.github/workflows/deploy-uat.yml`

| Job | Blocking for `prod-ready`? | Purpose |
|-----|----------------------------|---------|
| `Build Flutter web` (`build-web`) | **Yes** | Shared web build + `web-build-<sha>` artifact |
| `Build and deploy to UAT` (`deploy`) | **Yes** | Download artifact + FTP frontend/backend |
| `UAT post-deploy smoke` (`smoke`) | **Yes** | HTTP health on live UAT (`scripts/uat-post-deploy-smoke.sh`) |
| `UAT live smoke E2E` (`uat-e2e-smoke`) | **Yes** | Playwright `@smoke` on live UAT |
| `UAT full E2E (localhost)` (`uat-e2e-full`) | **Yes** | Full Playwright on localhost stack (10 file-balanced shards) |
| `Prod ready` (`prod-ready`) | **Yes** (aggregate) | Required for PROD environment gate |

**Parallelism:** `uat-e2e-full` runs ten file-balanced Playwright shards in parallel (manifest: `e2e/scripts/shard-files.mjs`; each shard gets its own Postgres + server) after `build-web` completes; shards still overlap with `deploy` FTP work. All four UAT gates must pass for `prod-ready`.

**`prod-ready` validation:** `scripts/ci/assert-uat-gates.sh` — single summary table in the Actions run summary.

**Phase 4 build experiment:** UAT `build-web` skips `flutter clean` by default (`run_clean=false`).
Set repo variable `UAT_FLUTTER_CLEAN=true` on push, or `workflow_dispatch` input
`run_clean=true`, to restore the pre-experiment path. Manifest + job summaries record
`run_clean` for duration comparisons.

**Backend FTP staging (Phase 5):** UAT and PROD use `scripts/ci/stage-backend-deploy.sh`
(`--target uat` → `.uat-backend-deploy/`, `--target prod` → `.prod-backend-deploy/`).
Excludes `node_modules`, tests, and `.env`; copies `db/migrations/` into the staging tree.
Job summaries record `staging_dir` and `migration_count`.

---

## 4. Signal only — weekly / manual E2E

Workflow: **E2E (Playwright)** — `.github/workflows/e2e.yml`

| Job | Blocks merge? |
|-----|---------------|
| `Playwright E2E (localhost)` | No |
| `Weekly E2E failed` (`notify-on-failure`) | No — warning on scheduled failure only |

---

## 5. PROD deploy prerequisites

Workflow: **Deploy Production (agathatrack.com)** — `.github/workflows/deploy-prod.yml`

Before `workflow_dispatch` or release publish:

1. **Same commit SHA** validated on UAT (via `release/uat-*` deploy).
2. GitHub Environment **`PROD`** must require status check:
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
`.prod-backend-deploy/` (same exclusions as UAT). SSH `npm ci` + `migrate.js up` run on
the live host after FTP.

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

Gate: **≥ 105 mapped scenarios** (ratchet defined in `e2e/scripts/check_bdd_coverage.js`). Do not hard-code scenario totals in workflow comments — they drift as features grow.

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
