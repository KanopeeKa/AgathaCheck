# CI/CD baseline metrics

Pre-refactor snapshot for the CI/CD hardening program (Phases -1–6). Re-run
`scripts/ci/collect-baseline.sh` after each major phase to measure improvement.

## Capture metadata

| Field | Value |
|-------|-------|
| **Repository** | KanopeeKa/AgathaCheck |
| **Captured at (UTC)** | 2026-07-14T00:24:00Z |
| **Base commit** | `main` at program start |
| **Window** | Last 20 workflow runs per workflow (14 for E2E — fewer scheduled runs) |
| **Data source** | `gh run list` / `gh run view` via `scripts/ci/collect-baseline.sh` |

## Workflow duration summary

| Workflow | File | Runs | Median | p95 | Failure rate | Sample failing jobs (latest failed run) |
|----------|------|------|--------|-----|--------------|-----------------------------------------|
| CI | `ci.yml` | 20 | 13m | 20m | 20% | test-suite / Flutter (analyze, test, build web) |
| Deploy UAT | `deploy-uat.yml` | 20 | 42m | 72m | 85% | UAT live smoke E2E |
| Deploy Production | `deploy-prod.yml` | 0 | — | — | — | No runs in window |
| E2E (Playwright) | `e2e.yml` | 14 | 6m | 18m | 7% | Playwright E2E (localhost) |

### Interpretation

- **CI** is relatively healthy (~80% success); failures are mostly dependency PRs and cancelled superseded runs.
- **UAT deploy** is the dominant pain point: long runs (median ~42m) and high failure rate, often on live `@smoke` Playwright against UAT hosting/TLS.
- **PROD deploy** has no recent runs in the sample window — promotion path not exercised recently.
- **Weekly E2E** is fast when it passes; occasional localhost E2E failures.

## Failure taxonomy

Use this when classifying regressions during later phases:

| Category | Symptoms | Typical owner action |
|----------|----------|----------------------|
| **Infra / transient** | Runner timeout, GitHub API flake, curl retry exhausted | Re-run workflow |
| **Test regression** | Jest/Playwright assertion failure, analyze/format gate | Fix code/tests |
| **Environment / hosting** | Passenger crash, directory listing on `/backend`, WAF page, TLS chain | cPanel / o2switch / DNS |
| **Gate misconfiguration** | `continue-on-error` masking failures, wrong required check name on environment | Fix workflow or GitHub Settings |

## Phase experiment log

Append rows as phases complete:

| Phase | Date | Change | Median UAT deploy | Median PROD deploy | Notes |
|-------|------|--------|-------------------|--------------------|-------|
| -1 | 2026-07-14 | Baseline captured | 42m | n/a | Starting point |
| 0 | 2026-07-14 | Smoke gate integrity fix | | | PR #162 |
| 0.5 | 2026-07-14 | Observability summaries | | | PR #163 |
| 1 | 2026-07-14 | Concurrency + actionlint | | | PR #163 |
| 2 | 2026-07-14 | Shared build + manifest | | | PR #164 |
| 3 | 2026-07-14 | UAT→PROD artifact promotion | | | PR pending — split UAT build job; PROD promotes `web-build-<sha>` |
| 4 | | `flutter clean` experiment | | | |

## Regenerating this table

```bash
# From repo root with gh authenticated:
bash scripts/ci/collect-baseline.sh --limit 20 > /tmp/baseline-snapshot.md
```

Paste the workflow summary into this doc or attach as a PR artifact.
