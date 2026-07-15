# CI/CD gate contract

Single source of truth for **blocking vs advisory** automation and PROD promotion
prerequisites. GitHub branch/environment settings must match the check names below.

See also: [ci-cd-baseline.md](./ci-cd-baseline.md) (metrics), [CONTRIBUTING.md](../CONTRIBUTING.md) (contributor checklist).

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
| `test-suite / Flutter (analyze, test, build web)` | `test-suite` | `Flutter (analyze, test, build web)` | `_reusable-test.yml` |
| `test-suite / Backend (Node.js Jest + Dart analyze)` | `test-suite` | `Backend (Node.js Jest + Dart analyze)` | `_reusable-test.yml` |
| `test-suite / E2E package audit` | `test-suite` | `E2E package audit` | `_reusable-test.yml` |
| `Analyze JavaScript` | — | `Analyze JavaScript` | `codeql.yml` (direct job) |

**Stability note:** Keep `ci.yml` caller ids (`startup-smoke`, `test-suite`) and reusable
job `name:` fields aligned with this table when renaming — branch protection matches these
display strings exactly.

| GitHub check name (job) | Workflow file | What it enforces |
|-------------------------|---------------|------------------|
| `startup-smoke / PR startup smoke` | `_reusable-pr-startup-smoke.yml` | Postgres bootstrap, `node bin/start.js`, `/backend/health` + root |
| `test-suite / Governance (BDD + file size)` | `_reusable-test.yml` | BDD mapping ≥ 105 scenarios, priority tags, file size ≤ 500 lines |
| `test-suite / Flutter (analyze, test, build web)` | `_reusable-test.yml` | analyze, tests, domain coverage 65%, format, integration tests, web build |
| `test-suite / Backend (Node.js Jest + Dart analyze)` | `_reusable-test.yml` | Jest, npm audit high+, `dart analyze lib` |
| `test-suite / E2E package audit` | `_reusable-test.yml` | e2e `npm audit` high+ |
| `Analyze JavaScript` | `codeql.yml` | CodeQL static analysis |

**Note:** Exact check names appear in the GitHub PR checks UI. Verify periodically with:

```bash
gh pr checks <PR_NUMBER>
```

**Not run on every PR commit:** full Playwright E2E (too slow). Full E2E runs on UAT deploy and weekly cron.

#### Branch protection setup (`main`)

After **PR #168** (or any PR) has run CI once on `main`, add the new check using the
**exact** string from `gh pr checks` (not the job `name:` alone):

**Required new check:** `startup-smoke / PR startup smoke`

**GitHub UI (classic branch protection):**

1. Open **Settings → Branches** → edit the rule for **`main`** (or **Add rule**).
2. Enable **Require status checks to pass before merging**.
3. Enable **Require branches to be up to date before merging** (recommended).
4. In **Status checks that are required**, search for and add:
   - `startup-smoke / PR startup smoke` ← **new (Phase 6)**
   - Existing CI checks if not already listed (see table above), e.g.:
     - `test-suite / Governance (BDD + file size)`
     - `test-suite / Flutter (analyze, test, build web)`
     - `test-suite / Backend (Node.js Jest + Dart analyze)`
     - `test-suite / E2E package audit`
     - `Analyze JavaScript`
5. **Save changes**.

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
| `UAT full E2E (localhost)` (`uat-e2e-full`) | **Yes** | Full Playwright on localhost stack |
| `Prod ready` (`prod-ready`) | **Yes** (aggregate) | Required for PROD environment gate |

**Parallelism:** `uat-e2e-full` runs in parallel with `deploy` (does not wait for HTTP smoke). All four gates must pass for `prod-ready`.

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
