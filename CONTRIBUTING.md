# Contributing to Agatha Track

Thank you for contributing. This project uses **trunk-based development** on `main`, with **integration branches** for multi-agent sprint work.

## Branch strategy

| Situation | Target branch |
|-----------|---------------|
| Single developer / single agent, one domain | PR directly to `main` |
| One request spawning **multiple parallel agents** | `cursor/sprint-<N>-<topic>-integration-13e3` → agents merge there → **one PR** to `main` |

Rationale: batching reduces repeated CI on `main` as coverage grows. See `.cursor/rules/merge-policy.mdc` and `.cursor/rules/agent-coordination.mdc`.

## Before you start

1. Read `docs/architecture/modularity.md` and `AGENTS.md`.
2. Cursor rules in `.cursor/rules/` encode project standards for agents and humans.

## Avoiding branch conflicts

Conflicts are common when multiple changes land on `main`. **Always sync before push:**

```bash
git fetch origin main
git rebase origin/main    # preferred for linear history
# resolve any conflicts, then:
git push -u origin <your-branch>
```

If you are unsure whether `main` moved while you worked, run the fetch + rebase step again before every push.

## Pre-push checklist

```bash
./scripts/pre-push.sh
```

For faster iteration during development, use `./scripts/pre-push-changed.sh` (runs a subset based on changed files). See `/pre-push-verify` skill and `docs/agent-efficiency-plan.md`.

Manual breakdown if needed:

```bash
cd server && npm ci && npm audit --audit-level=high && npx jest --env=node --forceExit
cd flutter_app && flutter pub get && dart run build_runner build --delete-conflicting-outputs
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration
dart format flutter_app/lib flutter_app/test
node scripts/check_file_size.js && node e2e/scripts/check_bdd_coverage.js
```

## Agent workflow

- Domain map: `docs/architecture/index.md`
- Skills: `.cursor/skills/` (split screens, BDD, spawn agents, security audit, pre-push)
- Parallel sprints: `docs/agent-efficiency/prompt-templates.md`
- Babysit merge-ready PRs: `/babysit` command (lightweight)
- Atomic PRs (one outcome, snag ladder): `docs/agent-efficiency/atomic-pr-policy.md`
- Autonomous PR + multi-phase plans: `docs/agent-efficiency/autonomous-pr-policy.md` (`/babysit-plus` skill, `/execute-plan` skill)

## Atomic PRs

**One PR = one verifiable outcome** (describe it in one sentence). Cross-domain changes are fine when they serve that outcome (e.g. UI + API + E2E for one flow). Split independent outcomes into stacked PRs.

**Snags:** fix trivial same-file issues (≤15 lines, no behavior change) in the PR; otherwise open a micro-PR or a debt issue — no silent deferrals. Full policy: [docs/agent-efficiency/atomic-pr-policy.md](docs/agent-efficiency/atomic-pr-policy.md).

## Pull request expectations

Use the PR template checklist. In summary:

| Change type | Requirement |
|---|---|
| Node route | Jest tests |
| Flutter widget | Widget test in mirrored `test/features/` path |
| User journey | Gherkin scenario + Playwright spec with `@bdd` comment |
| Security fix | No raw errors in 5xx; audit clean for high+ |
| Refactor | Reduce file size if touching files >500 lines; update `docs/refactoring-log.md` |

## CI gates on `main`

**Gate contract (blocking vs advisory, UAT/PROD rules):** [docs/ci-cd-gates.md](docs/ci-cd-gates.md)

- Flutter analyze, format, and parallel domain test shards (`pet-core`, `pet-screens`, `pet-widgets`, `health`, `org`, `rest-a`, `rest-b`) + merged domain coverage
- Flutter integration test (blocking)
- Node Jest tests
- `npm audit --audit-level=high` (server + e2e)
- CodeQL (JavaScript)
- `dart format --set-exit-if-changed` (Flutter code only, blocks merge)
- Flutter domain line coverage ≥ 65% (`check_domain_coverage.js`)
- BDD scenario mapping ≥ 105 mapped scenarios (`e2e/scripts/check_bdd_coverage.js`; live total via `--report-only`)
- Hand-written file size ≤ 500 lines (`scripts/check_file_size.js`; grandfather ratchet for legacy monoliths)
- Coverage artifacts: full Flutter lcov + Jest Istanbul (report-only beyond domain gate)

## E2E and UAT

- Full Playwright suite: UAT deploy (`uat-*` tag push after merge to `main`) and manual `workflow_dispatch`.
- `@smoke` tests run against live UAT and include axe accessibility checks (critical + serious).
- Weekly non-blocking E2E cron on `main` (see `.github/workflows/e2e.yml`).

## Running E2E locally

```bash
./e2e/scripts/run-local.sh
```

See `e2e/README.md` for details.

## Debt and deferrals

- Refactoring uncertainty → `docs/refactoring-debt.md`
- Product/infra deferrals → `docs/technical-debt.md`
- Sprint refactor plan → `docs/refactoring-log.md`
