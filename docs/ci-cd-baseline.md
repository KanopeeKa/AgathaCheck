# CI/CD baseline metrics

Pre-refactor snapshot and post-program metrics for the CI/CD hardening program
(Phases -1–6). Re-run `scripts/ci/collect-baseline.sh` after major workflow changes.

## Program status

**Phases -1 through 6 complete** (PRs #162–#168). Phase 7 closes hygiene debt:
untrack `flutter_app/build/` so UAT artifact materialize never sees stale checkout
web roots.

| Phase | PR | Summary |
|-------|-----|---------|
| -1 | #162 | Baseline metrics |
| 0 | #162 | UAT smoke gate integrity |
| 0.5–1 | #163 | Summaries, concurrency, actionlint |
| 2 | #164 | Shared Flutter web build + manifest |
| 3 | #165 | UAT→PROD artifact promotion |
| 4 | #166 | UAT `flutter clean` experiment (default off) |
| 5 | #167 | Backend staging unify |
| 6 | #168 | PR startup smoke |
| 7 | pending | Untrack `flutter_app/build/` + program closure |

## Capture metadata

| Field | Value |
|-------|-------|
| **Repository** | KanopeeKa/AgathaCheck |
| **Initial capture (UTC)** | 2026-07-14T00:24:00Z |
| **Post-program capture (UTC)** | 2026-07-15T09:39:27Z |
| **Window** | Last 20 workflow runs per workflow (14 for E2E) |
| **Data source** | `gh run list` / `gh run view` via `scripts/ci/collect-baseline.sh` |

## Workflow duration summary (initial — 2026-07-14)

| Workflow | File | Runs | Median | p95 | Failure rate | Sample failing jobs (latest failed run) |
|----------|------|------|--------|-----|--------------|-----------------------------------------|
| CI | `ci.yml` | 20 | 13m | 20m | 20% | test-suite / Flutter (analyze, test, build web) |
| Deploy UAT | `deploy-uat.yml` | 20 | 42m | 72m | 85% | UAT live smoke E2E |
| Deploy Production | `deploy-prod.yml` | 0 | — | — | — | No runs in window |
| E2E (Playwright) | `e2e.yml` | 14 | 6m | 18m | 7% | Playwright E2E (localhost) |

## Workflow duration summary (post-program — 2026-07-15)

| Workflow | File | Runs | Median | p95 | Failure rate | Sample failing jobs (latest failed run) |
|----------|------|------|--------|-----|--------------|-----------------------------------------|
| CI | `ci.yml` | 20 | —* | —* | 10% | test-suite / Flutter (analyze, test, build web) |
| Deploy UAT | `deploy-uat.yml` | 20 | —* | —* | 80% | Build Flutter web, UAT full E2E, Prod ready |
| Deploy Production | `deploy-prod.yml` | 0 | — | — | — | No runs in window |
| E2E (Playwright) | `e2e.yml` | 14 | —* | —* | 7% | Playwright E2E (localhost) |

\* Median/p95 unreliable when many runs are `cancelled` or in-flight (same `createdAt`/`updatedAt`).
Regenerate with `collect-baseline.sh` after a stable window of completed runs.

### Interpretation

- **CI** failure rate improved (20% → 10% in sample); startup smoke adds fast boot regression signal.
- **UAT deploy** remains the dominant pain point (80% failure rate); failures shifted toward build + localhost E2E gates after Phase 3–4 workflow splits.
- **PROD deploy** still not exercised in sample — run supervised promotion path when ready.
- **Tracked build artifacts removed (Phase 7)** — prevents false-positive `materialize-web-artifact` skips on checkout.

## Failure taxonomy

Use this when classifying regressions during later phases:

| Category | Symptoms | Typical owner action |
|----------|----------|----------------------|
| **Infra / transient** | Runner timeout, GitHub API flake, curl retry exhausted | Re-run workflow |
| **Test regression** | Jest/Playwright assertion failure, analyze/format gate | Fix code/tests |
| **Environment / hosting** | Passenger crash, directory listing on `/backend`, WAF page, TLS chain | cPanel / o2switch / DNS |
| **Gate misconfiguration** | Wrong required check on environment, masked job failures | Fix workflow or GitHub Settings |
| **Stale checkout artifacts** | UAT deploy skips downloaded web artifact | Ensure `flutter_app/build/` is not tracked (Phase 7) |

## Phase experiment log

| Phase | Date | Change | Median UAT deploy | Median PROD deploy | Notes |
|-------|------|--------|-------------------|--------------------|-------|
| -1 | 2026-07-14 | Baseline captured | 42m | n/a | Starting point |
| 0 | 2026-07-14 | Smoke gate integrity fix | | | PR #162 |
| 0.5 | 2026-07-14 | Observability summaries | | | PR #163 |
| 1 | 2026-07-14 | Concurrency + actionlint | | | PR #163 |
| 2 | 2026-07-14 | Shared build + manifest | | | PR #164 |
| 3 | 2026-07-14 | UAT→PROD artifact promotion | | | PR #165 |
| 4 | 2026-07-14 | UAT `flutter clean` experiment (default off) | | | PR #166 |
| 5 | 2026-07-14 | Backend staging unify (UAT + PROD) | | | PR #167 |
| 6 | 2026-07-15 | PR startup smoke on `main` PRs | | | PR #168 |
| 7 | 2026-07-15 | Untrack `flutter_app/build/` | | | PR pending — fixes checkout stale web root |

## Regenerating this table

```bash
# From repo root with gh authenticated:
bash scripts/ci/collect-baseline.sh --limit 20 > /tmp/baseline-snapshot.md
```

Paste the workflow summary into this doc or attach as a PR artifact.
