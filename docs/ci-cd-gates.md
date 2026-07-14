# CI/CD gate contract

Single source of truth for **blocking vs advisory** automation and PROD promotion
prerequisites. GitHub branch/environment settings must match the check names below.

See also: [ci-cd-baseline.md](./ci-cd-baseline.md) (metrics), [CONTRIBUTING.md](../CONTRIBUTING.md) (contributor checklist).

## Quick reference

| Stage | Blocking? | Workflow |
|-------|-----------|----------|
| PR → `main` | **Yes** (required checks) | `ci.yml`, `codeql.yml` |
| PR hints | No (advisory) | `pr-governance-hints.yml` |
| Agent `cursor/*` PRs | **Yes** (forbidden paths) | `agent-pr-safety-gate.yml` |
| `release/uat-*` deploy | **Yes** (UAT + `prod-ready`) | `deploy-uat.yml` |
| Weekly E2E on `main` | **No** (signal only) | `e2e.yml` |
| PROD deploy | **Yes** (environment + smoke) | `deploy-prod.yml` |

---

## 1. Blocking — pull request to `main`

Triggered by `.github/workflows/ci.yml` → `_reusable-test.yml` and `codeql.yml`.

| GitHub check name (job) | Workflow file | What it enforces |
|-------------------------|---------------|------------------|
| `Governance (BDD + file size)` | `_reusable-test.yml` | BDD mapping ≥ 105 scenarios, priority tags, file size ≤ 500 lines |
| `Flutter (analyze, test, build web)` | `_reusable-test.yml` | analyze, tests, domain coverage 65%, format, integration tests, web build |
| `Backend (Node.js Jest + Dart analyze)` | `_reusable-test.yml` | Jest, npm audit high+, `dart analyze lib` |
| `E2E package audit` | `_reusable-test.yml` | e2e `npm audit` high+ |
| `Analyze JavaScript` | `codeql.yml` | CodeQL static analysis |

**Note:** Exact check names appear in the GitHub PR checks UI. Verify periodically with:

```bash
gh pr checks <PR_NUMBER>
```

**Not run on every PR commit:** full Playwright E2E (too slow). Full E2E runs on UAT deploy and weekly cron.

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
| `Build and deploy to UAT` (`deploy`) | **Yes** | Flutter build + FTP frontend/backend |
| `UAT post-deploy smoke` (`smoke`) | **Yes** | HTTP health on live UAT (`scripts/uat-post-deploy-smoke.sh`) |
| `UAT live smoke E2E` (`uat-e2e-smoke`) | **Yes** | Playwright `@smoke` on live UAT |
| `UAT full E2E (localhost)` (`uat-e2e-full`) | **Yes** | Full Playwright on localhost stack |
| `Prod ready` (`prod-ready`) | **Yes** (aggregate) | Required for PROD environment gate |

**Parallelism:** `uat-e2e-full` runs in parallel with `deploy` (does not wait for HTTP smoke). All four gates must pass for `prod-ready`.

**`prod-ready` validation:** `scripts/ci/assert-uat-gates.sh` — single summary table in the Actions run summary.

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
3. Optional: environment reviewers / wait timer.

Post-deploy blocking job:

| Job | Purpose |
|-----|---------|
| `Production post-deploy smoke` | `curl` health + landing |

**Future (Phase 3+):** PROD will download the UAT-built web artifact for the same SHA (UAT → PROD promotion).

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
