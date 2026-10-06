---
title: Active codebase characterization baseline
owner: Engineering
audience: agent
status: active
last_updated: 2026-10-06
tags: [architecture, baseline, characterization]
---

# Active codebase characterization baseline

Batch **A1** artifact for [active-codebase-batch-a-cbb8](/.agents/plans/active-codebase-batch-a-cbb8.md), refreshed by Batch **D1** of [active-codebase-batch-d-guardrails-e41f](/.agents/plans/active-codebase-batch-d-guardrails-e41f.md). Records the reviewed commit, command ownership, and **current** failure semantics under characterization tests. These tests document behavior; fixes land in later batches (B/C).

## Baseline revision

| Field | Value |
|-------|-------|
| Git commit | Recorded in `baseline-metadata.json` (updated each A1 refresh) |
| Architecture review | `docs/architecture/reviews/active-codebase-review.md` (`status: accepted`) |
| Metrics script | `scripts/architecture/architecture-metrics.py` |

Regenerate headline metrics:

```sh
python3 scripts/architecture/architecture-metrics.py \
  --repo "$(git rev-parse --show-toplevel)" \
  --output docs/engineering/active-codebase-baseline/metrics-headline.md
```

## Metrics history

Cross-feature Flutter import figures from `metrics-headline.md` (same script, same exclusions). "SCC features" is the size of the single strongly connected multi-feature component.

| Baseline | Commit | Unique feature edges | Matching directives | SCC features |
|---|---|---:|---:|---:|
| Architecture review | `a8c7db1` | 50 | 466 | 12 |
| Batch A1 baseline | `71e0020` | 50 | 466 | 12 |
| Batch D1 refresh (2026-09-29) | `f669b3e` (source tree = `main` @ `adaff34`) | 59 | 536 | 13 (`people` joined) |
| Roadmap start (2026-09-29) | `0cc739e` | 59 | 536 | 13 |
| Batch K final acceptance (2026-10-06) | `afc7c4ad` (integration branch) | **35** | **347** | **0** |

## Cross-feature import gate baseline (D6)

`scripts/feature-import-baseline.json` was generated with `node scripts/check_feature_imports.js --init` at `20330e6` (source tree = `main` @ `adaff34`). Rules are documented in `docs/architecture/modularity.md` §Cross-feature imports. The baseline may only shrink.

| Rule | Baselined identities at D2 | Target |
|---|---:|---|
| R1 domain → Experience | 56 | 0 (Batch I1 phase 2) |
| R2 cross-feature `data/` | 6 | 0 (Batch I1 phase 3) |
| R3 cross-feature `presentation/` | 201 | 0 (Batch I1 phase 3) |
| R4 feature edges | 59 | acyclic graph (Batch I2) |

## Command matrix (P1 flows)

Refreshed 2026-10-06 on integration branch `cursor/active-codebase-k-integration-e41f` @ `afc7c4ad` (Batch K phase 4). Component READMEs and ADRs document owners; programme batches D–K merged on the integration branch.

| Command / read | Code path | AuthZ owner | Transaction owner | Commit point | Response contract | Tests |
|---|---|---|---|---|---|---|
| `DELETE /api/pets/:id/data` | `lifecycleRouter` → `petDataLifecycle` | `petAccess` | `withTransaction` + `cleanup_jobs` enqueue | before async file jobs | D13 + ADR 0004 | `server/test/lib/petDataLifecycle.regression.test.js`, `server/test/db/petDataLifecycle.integration.test.js`, `server/test/db/petLifecycle.integration.test.js` |
| `DELETE /api/pets/:id` | `coreRouter` → pet delete use case | `userOwnsPet` | single `withTransaction` (data, pet row, audit) | before `kickCleanupJobs` | D13 | `server/test/db/petLifecycle.integration.test.js` |
| `POST …/complete-weight` | weight completion route → observation service | capability + entry access | `withTransaction` (D12 in-tx side effects) | end of service transaction | 201 / 200 replay / 409 conflict | `server/test/healthEntries/completeWeight.test.js`, real-PG weight fulfilment suites |
| `POST /api/share/invites` | `inviteRoutes` → `shareInviteService` | inviter owns pets | `withTransaction` + advisory lock (D22) | before in-tx notifications | 201 / 200 `replayed: true` | `server/test/sharing/invites/createInvite.test.js`, `server/test/sharing.test.js` |
| `POST /api/share/invites/:id/accept` | sharing accept route | invitee principal | `withTransaction` | grant rows in transaction | 200 + notifier side effects | `server/test/sharing/invites/acceptDecline.test.js`, `server/test/db/shareInviteAccept.integration.test.js` |
| `POST /api/pets/:id/passed-away` | `lifecycleRouter` → notification ledger | `LIFECYCLE_MANAGE` | `withTransaction` + `pet_lifecycle_notifications` | in transaction | D14 delivery counts | `server/test/db/petLifecycle.integration.test.js`, `server/test/openapi/petCareContract.test.js` |
| `GET` pets list (Flutter) | `PetRepositoryImpl` + cache policy | bearer token | n/a | n/a | D18 freshness metadata | `flutter_app/test/features/pet_profile/data/repositories/pet_repository_impl_test.dart`, E2E `e2e/playwright/tests/pet.offline-cache.spec.ts` |
| Health mutations (Flutter) | `CareScheduleController` | n/a | n/a | n/a | D19 `CommandOutcome` | `flutter_app/test/features/health_tracking/presentation/controllers/care_schedule_controller_test.dart`, `flutter_app/test/features/health_tracking/architecture/health_presentation_boundary_test.dart` |
| `POST /api/pets/:id/transfer-to-org` | `transferRouter` | owner check | org transfer lib | varies | JSON 404 when frozen off | `server/test/pets/frozenRouteGate.test.js` |
| `DELETE /api/auth/me` | profile router → erasure service | session + password | acceptance transaction + jobs | user row removed in tx; files/PostHog async | D16 `202` + status token | `server/test/auth/profile.test.js`, `server/test/db/accountErasure.integration.test.js`, `server/test/auth/accountExistence.test.js` |
| Login / logout | auth session routers | credentials / cookie | n/a | token issue / cookie clear | session v2 contract | `server/test/auth/sessionV2.test.js` |

## Measured universes

Every blocking gate measures an explicit file set. Exclusions match `scripts/architecture/architecture-metrics.py` and `docs/engineering/frozen-domains/manifest.json` unless noted.

| Gate | Universe | Exclusions (same family as metrics script) | Enforced by |
|---|---|---|---|
| File size (blocking) | Hand-written `.dart` under `flutter_app/lib/**`; `.js` under `server/routes/**`, `server/lib/**`, `server/services/**` | Generated Dart (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `l10n/`); manifest `sourceRoots` / `serverRoots`; build/tool/deps paths | `scripts/check_file_size.js` |
| File size (D7 allowlist) | Same as blocking server roots — offenders over 500 lines require `scripts/file-size-allowlist.json` with `maxLines`, `owner`, `reason`, `review_date` | Allowlist ratchet: files must not grow past `maxLines`; expired `review_date` warns | `scripts/check_file_size.js` + `size-report.md` |
| ESLint (active server ratchet) | Active `server/lib/**`, `server/services/**`, `server/routes/**` | Manifest frozen `serverRoots`; baselined violations in `server/eslint-baseline.json` (shrinks only) | `scripts/validate_eslint.js` |
| Flutter domain coverage | `lib/features/<feature>/domain/**` for active features | Manifest `sourceRoots`; `activeSurfacesToRemove`; generated Dart suffixes; files absent from `lcov.info` count as 0% | `flutter_app/scripts/check_domain_coverage.js` + generated `test/generated/coverage_helper_imports.dart` |
| Backend coverage ratchet | `server/lib/**`, `server/services/**`, `server/routes/**` | Manifest frozen route roots (`routes/organizations/**`, `fosterPlacements.js`, `custodyTransfers.js`) | `server/scripts/check_coverage_ratchet.js` + `server/coverage-ratchet.json` |
| BDD blocking gate | Gated active Gherkin scenarios with `@bdd` mapping (traceability) | Manifest `bddFeaturePatterns`; frozen E2E spec set; header-only phantom excluded from denominator | `e2e/scripts/check_bdd_coverage.js` |

BDD traceability vs execution (Batch J.3, measured 2026-10-06): traceability **145/182** gated mapped (gate **123** at 68%); execution **145/145** mapped scenarios in Pre-UAT shards (report-only); quality **14** spec files with skeleton/orphan signals (report-only). Detail: `docs/e2e/bdd-traceability-baseline.md`.

Regenerate Flutter domain imports after adding domain files:

```sh
node flutter_app/scripts/generate_coverage_helper.js
```

Flutter domain threshold (D23 / J.1-3): recorded in `flutter-domain-coverage-threshold.json` (measured 8.5% → **8%** gate with review date **2026-12-01**; policy target remains **70%**).

Backend ratchet floors (lines %, measured 2026-10-06): `lib` **53.06**, `services` **73.78**, `routes` **74.86**.

## Test policy

- **Characterization** tests assert **current** behavior and are named `characterization:` in descriptions.
- **Regression** tests for target contracts are added alongside fixes in Batch B/C, not in A1.
- Do not weaken characterization tests to greenwash; replace when behavior intentionally changes.
