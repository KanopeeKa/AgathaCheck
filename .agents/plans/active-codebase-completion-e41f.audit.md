---
title: Audit — active-codebase-completion-e41f (Batches D–K)
owner: Engineering
audience: both
status: active
last_updated: 2026-10-06
---

# Audit: architecture programme `active-codebase-completion-e41f`

**Audited:** `origin/main` @ `3a4ee8ba` (one unrelated commit after the Batch K landing `58427e42`, #1724).
**Against:** the plan text as approved (integration branch @ `c81b09ec`), not the reworded text now on `main` (§4).
**Method:** every acceptance criterion in D–K (197), the roadmap's 9 programme exit criteria and 10 cross-cutting gates, checked against code, tests and CI history; gates re-run locally.

## 1. Verdict

**Not finished.** The code delivers most of the review's intent: transactions, the cleanup-job runner, resumable erasure, offline freshness, ports, an acyclic feature graph and blocking governance gates. But the programme does **not** meet its own exit criteria as written:

- 3 of 9 exit criteria are unmet or only partly met (1, 2, 3).
- 2 more are met in the letter but not in the spirit (5, 6).
- The roadmap is not closed: `roadmap-status` reports `complete: false`, #1446 is still open, and the bookkeeping for E, I1 and K is inconsistent.
- Batch K reworded its own K.4 criteria and four exit criteria in its landing PR (#1724), softening them.

## 2. Gates re-run on `main` (all green)

| Gate | Result |
|---|---|
| Backend Jest (CI config, `npm test`) | 254 suites, 1,534 tests passed |
| Real-PostgreSQL suites (`server/test/db`, `CI=true`) | 42 suites, 174 tests passed |
| `validate_openapi.js`, `validate_eslint.js` | OK (364 active files, 27 baselined) |
| `check_feature_imports.js` | R1–R3, R5–R8 = 0; 35 feature edges |
| `architecture-metrics.py` | 0 multi-feature SCCs |
| File size, frozen boundaries, BDD (80.2% vs 68% gate), shard manifest, priority tags | OK |
| Every checker fixture test (imports, size, docs, BDD, frozen, coverage ×2, architecture, ESLint) | pass |
| `./scripts/pre-push.sh` (Flutter analyze, 6 shards, format) | passed (exit 0): codegen, `flutter analyze`, all 6 shards, format |

Pre-UAT on each child's merge SHA (CG10):

- **Green:** E, F, G and K (run 653).
- **Green with an artifact:** D, H and J show red only because `main` advanced during the run and promotion was skipped. Build and E2E passed.
- **Red:**
  - I2 was red and fixed by remedial #1682.
  - I1 merged while `main` was already red from Notifications v2 (run 617). That breaks the one-landing-at-a-time rule. `main` went green at run 622.

Note: `main`'s committed `docs/quality/scorecard.md` says 345 Flutter tests where the generator now counts 346 (likely #1706, outside ARCH). Pre-UAT run 654 on `3a4ee8ba` (#1706) failed shards 3 and 7; that is also outside ARCH.

## 3. Programme exit criteria (original wording)

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Every P1 finding A01–A06 has a passing failure-path test | **Partial** | A02–A06 have failure-path tests. **A01 (pet deletion) has none.** The listed tests are success-path tests plus a generic `withTransaction` rollback on a temp table (E.2-3). |
| 2 | Transaction-ownership test has **zero** exceptions in active code | **Not met** | `transactionOwnership.test.js` exempts `lib/care/occurrence/careItemLock.js` and `careTick.js`, which hand-roll `BEGIN`/`COMMIT`. This was added in Batch E. ADR 0003 promises "a linked issue", but none exists. The PEOPLE entry for `peopleRelationshipsRouter.js` is stale: the file no longer has a transaction. |
| 3 | Stable committed responses, plus real-PG tests **for fault injection and concurrency** | **Partial** | Erasure, invites, weight completion and share links are covered. **Pet deletion has no fault injection.** The **passed-away** test is titled "repeat and concurrent" but runs two sequential calls. |
| 4 | Erasure: 202 after durable acceptance, old tokens rejected, jobs reach completed/failed | Met | `accountErasure.integration.test.js` (per-step fault injection, idempotent retry, status token); `accountExistence` matrix; GDPR E2E polls to `completed` on both prefixes |
| 5 | Boundary test passes **and every health mutation goes through the controller or store** | Letter met | The test passes, but only scans `health_tracking` and `pet_care` widgets. After I2 moved surfaces into `experience`, `care_item_detail_screen.dart:148` reads `healthRepositoryProvider` and `global_events_list.dart:53` invalidates `healthEntriesNotifierProvider`; neither is caught. |
| 6 | 0 SCC; empty baseline for R1–R3, R5, R6 | Letter met | True. But see I1 in §5: the public entrypoints are wide barrels, so "0" is partly achieved by routing deep imports through them. |
| 7 | Checker fixtures fail on violations; all blocking in CI | Met | Fixtures for size, imports, frozen, transaction, server direction, docs, BDD, both coverage gates and ESLint; `assert-ci-gate.test.js` passes |
| 8 | Review `implemented`; no Partial rows; P2/P3 exceptions with owner, reason, date | Mostly met | `shareInviteService.js` is listed as a 597-line exception but is now 9 lines (stale). K.1-2/K.2-2 overruns (§5) are not listed. |
| 9 | Pre-UAT green on the final merge SHA | Met, not recorded | Run 653 on `58427e42` is green, but the item is unticked and the roadmap is not closed |

## 4. Process findings

- **K reworded its own acceptance criteria** in its landing PR (#1724, `58427e42`). These gave K its pass:
  - **K.4-1:** "one revision runs every gate, with results linked in the PR" became "deferred to K.5".
  - **K.4-5:** "every exit item ticked with evidence" became "annotated (item 9 deferred)".
  - **Exit criterion 3** lost "for fault injection and concurrency".
  - **Exit criterion 5** lost "every health mutation goes through the controller or store".

  The roadmap says changes after approval need a new snapshot and a new approval.
- **Unfinished bookkeeping:**
  - E is still `in_progress` on the roadmap, with phase 5 `in_progress`, although it landed in #1503.
  - I1 phase 5 is `in_progress`.
  - K phases 3–4 say `complete`, which is not a valid status, and phase 5 is `pending`.
  - F, H, I1 and I2 are `merged` with no PR URL or merge commit.
  - Roadmap issue #1446 is open.
- **Coverage thresholds:**
  - **Backend:** the `routes` ratchet floor was lowered from 74.86 to 74.58 in K1 without a recorded exception. The plan lists lowering a threshold to get green as a hard stop. Code moving out of routes explains the drop, but it should be recorded.
  - **Flutter:** the domain coverage gate went from 70% to **8%**. J.1-3 permits this with a recorded exception and review date, and one is recorded (review 2026-12-01). I verified the measurement is genuine: `lcov-merge` sums hits correctly, and the domain universe is 142 files, about 2,700 lines. In plain terms, Flutter domain logic is about 8.5% unit-covered, and the 70% target is a long way off.

## 5. Per-child findings

| Child | Criteria | Unmet / partial |
|---|---|---|
| D | 17 | none |
| E | 38 | **E.2-3**: no per-step real-PG fault injection for pet deletion. **E.2-7**: no concurrent passed-away test. **E.4-10**: allowlist holds more than the PEOPLE entry. E.5-3: not closed. Partial: E.1-6 (`EPERM`/`EBUSY` untested), E.2-4 (no "permission failure keeps 200" test), E.2-5/CG4 (the D13/D14 contract tests run on `/api` only, not `/backend/api`), E.2-6 (no "failed delete writes no audit" test) |
| F | 29 | none of substance; F.5-3 lacks a recorded PR URL |
| G | 25 | spirit gap in G.3-2 scope (exit 5) |
| H | 19 | none for H. `secureAccountRouter.js`, added later by Notifications v2, skips `asyncHandler` and typed errors, and no gate catches it. |
| I1 | 16 | **I1.4-2**: no check that entrypoint exports match the README surface. **I1.3-3**: not enforced, and the drift is large (`health_tracking` exports 58 vs 5 README rows; `people` 46 vs 4; `pet_profile` 60 vs 4). The barrels re-export 24–28 presentation widgets plus controllers and providers, against D20's "UI entrypoints exported explicitly". I1.1-2: `care_item` has no README; `vet/README.md` describes an entrypoint that no longer exists. I1.5-3: bookkeeping. |
| I2 | 16 | none. `core/widgets` still imports `experience` (L0 → top layer), but `core` edges are not tracked by the checker, so the layering ADR is not enforced there. |
| J | 17 | letter met; spirit: the 8% Flutter gate (§4) |
| K | 20 | **K.1-2**: `registerFamilyEventsRoutes` 274 lines and `createWeightEntriesWriteRouter` 214 (limit 150). **K.2-2**: five `build` methods at 193–225 lines (limit 120), and `manage_events_filter_dimensions.dart` is 345 lines with no size-report entry. These figures are in K's own `metrics-headline.md`. **K.2-3**: 10 of 20 extracted widgets have no test. Partial K.2-1: `PetListAppBar` and three other extracted widgets read providers. **K.4-1, K.4-5, K.5-3**: not done (§4). |

## 6. What is genuinely done well

- **Batch F (erasure):**
  - the data map is enforced against `pg_constraint`;
  - per-step fault injection;
  - an idempotent retry;
  - a token-checked status endpoint;
  - the race test;
  - the E2E covers both prefixes.
- **Batch E's job runner:** `SKIP LOCKED` claims, a 20-job concurrent drain, lease expiry, redaction, a runbook.
  - The legacy-file erasure bug from my #1496 review is fixed and has a regression test.
- **I2 and the gates:** 0 cycles; R5/R8 cannot be baselined; every checker has a fixture and blocks CI.
- **Batch H:** ports, single refresh authority, `asyncHandler` everywhere in the scoped routers, server-direction test.
- **Hard stop D9(a):** respected; exactly the three planned migrations (085–087).

## 7. Recommended close-out (in order)

1. **Bookkeeping** (no code):
   - close E and I1 phase 5;
   - set K phases 3–5 to `merged`;
   - record PR URLs and merge commits for F, H, I1 and I2;
   - tick exit 9 with run 653;
   - restore the original K.4 and exit-criteria wording, or get your explicit approval for the softened text;
   - only then run `complete-plan` on the roadmap and close #1446.
2. **A01 / E.2-3:** real-PG fault injection at each pet-deletion step, plus "failed delete writes no audit".
3. **E.2-7:** a genuinely concurrent passed-away test.
4. **Exit 2:**
   - remove the stale PEOPLE allowlist entry;
   - either migrate `careItemLock`/`careTick` onto `withTransaction`, which needs CARE (owner) coordination, or open the issue ADR 0003 promises, with owner and date, and have you approve the exception explicitly.
5. **I1 surface:**
   - add the entrypoint↔README check;
   - narrow the barrels to domain, ports and listed UI entrypoints;
   - write a `care_item` README;
   - fix or remove `vet/README.md`.
6. **G.3-2:** extend the boundary scan to `experience` health surfaces and fix the two hits.
7. **K.1-2 / K.2-2 / K.2-3:**
   - split or record the two route registrars and five `build` methods;
   - add a size-report entry for `manage_events_filter_dimensions.dart`;
   - write tests for the 10 untested extractions.
8. **Thresholds:** restore the `routes` floor or record the exception. Decide on a climb plan for the 8% Flutter gate (your call).
9. **CG2 / CG4:**
   - a shared real-PG helper that fails when `CI=true` and the DB is unreachable (several suites skip silently today);
   - `/backend/api` contract tests for the D13/D14 endpoints.
10. **Layering:** track `core → feature` edges so `core/widgets → experience` is caught.
