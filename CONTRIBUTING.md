# Contributing to Agatha Track

Thank you for contributing. This project uses **trunk-based development**: merge small PRs to `main` frequently; full browser E2E runs on UAT release branches only.

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
# Backend
cd server && npm ci && npm audit --audit-level=high
cd server && npx jest --env=node --forceExit

# Frontend (codegen required when mocks change)
cd flutter_app && flutter pub get
cd flutter_app && dart run build_runner build --delete-conflicting-outputs
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration

# Format (required — CI enforces)
dart format flutter_app/lib flutter_app/test server/lib
```

## Pull request expectations

Use the PR template checklist. In summary:

| Change type | Requirement |
|---|---|
| Node route | Jest tests + Dart parity when HTTP behaviour changes |
| Flutter widget | Widget test in mirrored `test/features/` path |
| User journey | Gherkin scenario + Playwright spec with `@bdd` comment |
| Security fix | No raw errors in 5xx; audit clean for high+ |
| Refactor | Reduce file size if touching files >500 lines; update `docs/refactoring-log.md` |

## CI gates on `main`

- Flutter analyze + unit/widget tests + web build
- Flutter integration test (blocking)
- Node Jest tests
- `dart analyze lib` on `server/`
- `npm audit --audit-level=high` (server + e2e)
- CodeQL (JavaScript)
- `dart format --set-exit-if-changed` (blocks merge)
- Coverage artifacts (report-only, no threshold yet)

## E2E and UAT

- Full Playwright suite: UAT deploy (`release/uat-*`) and manual `workflow_dispatch`.
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
