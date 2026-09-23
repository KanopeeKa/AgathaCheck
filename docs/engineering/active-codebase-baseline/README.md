---
title: Active codebase characterization baseline
owner: Engineering
audience: agent
status: active
last_updated: 2026-09-22
tags: [architecture, baseline, characterization]
---

# Active codebase characterization baseline

Batch **A1** artifact for [active-codebase-batch-a-cbb8](/.agents/plans/active-codebase-batch-a-cbb8.md). Records the reviewed commit, command ownership, and **current** failure semantics under characterization tests. These tests document behavior; fixes land in later batches (B/C).

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

## Command matrix (P1 flows)

| Command / read | AuthZ owner | Transaction owner | Commit point | Response contract (today) | Known gap (finding) | Characterization test |
|---|---|---|---|---|---|---|
| `deleteAllPetData` | route + `petAccess` | `withTransaction` / single `PoolClient` | before file purge | `{ deleted, files_removed }` counts scheduled URLs | A01 fixed in B2 | `server/test/lib/petDataLifecycle.characterization.test.js` |
| `POST …/complete-weight` | capability + entry access | `pool.connect` in service | before cache/establishment | 201 with committed result; post-commit best-effort | A02 fixed in B3 | `server/test/healthEntries/completeWeight.test.js` |
| `POST /pets/:id/passed-away` | pet access | none (notify only) | n/a | `notification_sent` + `delivery_status` | A08 fixed in B4 (D1) | `server/test/openapi/petCareContract.test.js` |
| `GET` pets list (Flutter) | bearer token | n/a | n/a | returns local cache on remote error | A06 — 401/403 indistinguishable from offline | `pet_repository_impl_test.dart` characterization group |
| Health entry selectors | n/a | n/a | n/a | dual fetch paths | A05 — `petHealthEntriesProvider` vs global notifier | documented; fix in C2 |
| `POST /pets/:id/transfer-to-org` | owner check | org transfer lib | varies | mounted when frozen off | A03 — boundary | fix in A2 |
| Account `DELETE /profile` | session | sequential steps | user row delete | 200 synchronous | erasure job gap | fix in parallel Package 5 |

## Test policy

- **Characterization** tests assert **current** behavior and are named `characterization:` in descriptions.
- **Regression** tests for target contracts are added alongside fixes in Batch B/C, not in A1.
- Do not weaken characterization tests to greenwash; replace when behavior intentionally changes.
