---
title: Active codebase characterization baseline
owner: Engineering
audience: agent
status: active
last_updated: 2026-09-29
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

## Command matrix (P1 flows)

Refreshed 2026-09-29 against `main` @ `adaff34` (Batch D phase 1). Code paths are the current owners; "Remaining gap" names the roadmap child that closes it ([`active-codebase-completion-e41f`](/.agents/plans/active-codebase-completion-e41f.md)).

| Command / read | Code path | AuthZ owner | Transaction owner | Commit point | Response contract (today) | Remaining gap (child) | Tests |
|---|---|---|---|---|---|---|---|
| `DELETE /api/pets/:id/data` | `server/routes/pets/lifecycleRouter.js` → `deleteAllPetData` (`server/lib/petDataLifecycle.js`) | `petAccess` capability check in route | `withTransaction` (single `PoolClient`) | before on-disk file purge | `{ deleted, pet_id, rows_removed, files_removed }` — `files_removed` counts URLs **scheduled**, not verified | audit write not awaited inside the transaction; files purged best-effort after commit, no retry (E) | `server/test/lib/petDataLifecycle.characterization.test.js`, `server/test/db/petDataLifecycle.integration.test.js` |
| `DELETE /api/pets/:id` | `server/routes/pets/coreRouter.js` | `userOwnsPet` | `deleteAllPetData` transaction, then a **separate** `pool.query` deletes the pet row | two commits | `{ deleted: true }` | pet row delete is outside the data transaction; `pet.deleted` audit is written before the outcome (E) | `server/test/db/petDataLifecycle.integration.test.js` (data part only) |
| `POST …/occurrences/:occurrenceId/complete-weight` | `server/routes/healthEntries/completeWeightRouter.js` | capability + entry access | hand-written `pool.connect` + `BEGIN`/`COMMIT` in the route module | before weight cache, establishment and audit | 201 committed result; 200 on semantically equal replay; 409 on different payload | establishment and weight cache refresh fail silently after commit (E) | `server/test/healthEntries/completeWeight.test.js` |
| `POST /api/share/invites` (create) | `server/routes/sharing/inviteRoutes.js` → `createShareInvite` (`server/services/sharing/shareInviteService.js`) | inviter owns pets | hand-written `BEGIN`/`COMMIT` | before notification rows and email | 201 with `delivery` metadata after commit | code-collision retry runs inside an aborted transaction; no replay/concurrency control; notifications written after commit (E) | `server/test/sharing/invites/createInvite.test.js`, `server/test/sharing.test.js` |
| `POST /api/pets/:id/passed-away` | `server/routes/pets/lifecycleRouter.js` → `notifyPassedAwayCollaborators` | `LIFECYCLE_MANAGE` capability | none (notification only) | n/a | `{ notification_sent, pet_id, notified_count, delivery_status }` (D1) | repeat POST re-notifies every collaborator (E) | `server/test/openapi/petCareContract.test.js` |
| `GET` pets list (Flutter) | `PetRepositoryImpl.fetchAllPets` | bearer token | n/a | n/a | D2 hybrid: 401/403/5xx/parse throw; transport errors may return stale cache with `isStale` | cached `fetchedAt` is `now()`; no freshness limit; pet detail not migrated (G) | `flutter_app/test/features/pet_profile/data/repositories/pet_repository_impl_test.dart` |
| Health entry selectors (Flutter) | `healthEntriesNotifierProvider` + derived selectors | n/a | n/a | n/a | one canonical store; per-pet selectors derived | `refresh()` drops data on failure; no out-of-order/session guard; 15 widget-level repository calls (G) | `flutter_app/test/features/health_tracking/presentation/providers/health_entries_canonical_store_test.dart` |
| `POST /api/pets/:id/transfer-to-org` | `server/routes/pets/transferRouter.js` | owner check | org transfer lib | varies | JSON 404 when `ENABLE_FROZEN_DOMAINS` is off (`rejectFrozenShelterApi`) | none — Package 2 done | `server/test/pets/frozenRouteGate.test.js` |
| `DELETE /api/auth/me` | `server/routes/auth/profileRouter.js` | session + password | none — sequential pool queries | user row delete, **after** file purge and PostHog call | 200 `{ message }` synchronous | not resumable; access JWTs stay valid; PostHog failures swallowed (F) | `server/test/auth/profile.test.js` |

## Test policy

- **Characterization** tests assert **current** behavior and are named `characterization:` in descriptions.
- **Regression** tests for target contracts are added alongside fixes in Batch B/C, not in A1.
- Do not weaken characterization tests to greenwash; replace when behavior intentionally changes.
