# Weight monitoring: one weight record, weigh-ins that count, one weight screen — roadmap plan (v1.2)

> **Status: APPROVED — execute-plan active (owner delegated full programme in chat 2026-10-04).** Originally DRAFT FOR `approve-autonomous` — product decisions approved by the owner in chat on 2026-10-04 (§3); v1.1 folds in the plan review of 2026-10-04 (see Revision history).** This file is the single source of truth for the programme. Child plans (§10) hold only their phase tables and runtime state; every rule, contract, test and copy string lives here. Where a child file and this file disagree, **this file wins**.
>
> **Written for implementing agents that did not take part in the design.** Read §0 first. Do not improvise behaviour that this plan does not describe. If something is missing or contradicts the code on `main`, stop and raise it on the control issue (§0.5). Don't guess.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `weight-monitoring-unify-9b2e` |
| **plan_kind** | `roadmap` (parent orchestrator; three child plans, §10) |
| **title** | A weight is recorded once and can count as a due weigh-in, weigh-in undo and dates stay consistent, one unit preference per user, and one weight screen that also shows the weigh-in routines |
| **author** | Claude Code session with the product owner (2026-10-04) |
| **reviewed commit** | `4f3325d` (`main`, 2026-10-04, after ARCH E phases 1–4 [#1503] and CARE E+F [#1504] landed). Every `file:line` reference is against this commit. Re-check line numbers on your own base before editing. |
| **approval** | Product decisions: owner in chat, 2026-10-04 (§3). Autonomy: `approve-autonomous weight-monitoring-unify-9b2e` on control issue [#1537](https://github.com/KanopeeKa/AgathaCheck/issues/1537) (standing grant through programme end). Each child gets its own control issue under that grant when its entry gate is met (§11). |
| **execution model** | execute-plan. **W0 is a docs-only PR straight to `main`** (roadmap phase). Then one **integration branch per child** (§10): phase PRs go into the child's integration branch; the child's integration → `main` PR is the **landing**, babysat with `/babysit-uat` until pre-UAT is green. Commits use `phase(<n>/<m>): …` with the child's own phase index. |
| **coordination** | Follows [parallel-programmes.md](../../docs/agent-efficiency/parallel-programmes.md). Programme code **WEIGHT**. W0 lands WEIGHT's row, areas and slots on `main` before any code phase (hard gate). Entry gates per child are in §10. |

### Revision history

| Version | Change | Why |
|---|---|---|
| v1 (2026-10-04) | First plan | Owner decisions in chat |
| **v1.1** (2026-10-04) | **Pet `PUT` keeps accepting `weight`** for installed clients (deprecated), routed through the shared service as a standalone weight with validation; the server part moves from W5 to **W1**; the profile E2E change moves from W4 to **W7** (§5.7, §8.5, D-WM-009) | Review item 1: W4 asserted server behaviour that only W5 changed. Moving the "ignore weight" change into A instead (the review's suggestion) would have let the still-editable Flutter form silently drop edits between landings A and B. Keeping the server compatible removes both the timing bug and the only breaking API change |
| v1.1 | **Child control issues** follow the PEOPLE pattern: one roadmap grant, one control issue per child at bootstrap (§11) | Review item 2 |
| v1.1 | **ARCH E handoff dropped**: ARCH E phases 1–4 landed (#1503) with the weight transaction work (E.4-7…E.4-9). W1 builds on it. **New hard gates** against PEOPLE `people-server-7f3b` s2/s3 and ARCH G1/G3, and W0 becomes a docs PR to `main` that records WEIGHT's slots before any code (§10) | Review item 3, overtaken by the landings; the principle (gate on `main`, not on a comment) kept |
| v1.1 | CARE E+F gate removed (CARE complete, #1504); care item view path updated to `features/care_item/presentation/detail/` | Landing #1504 |
| v1.1 | **Record weight sheet waits for the weigh-in check** before Save (D-WM-003, §6.4, FW-18) | Review product item: a fast save could miss the default "Counts as" |
| v1.1 | Migration number 087 at time of writing; ARCH E tests kept green instead of re-written (U-7, U-8, U-11); hardening finding F-13 (no silent zero weight) closed by W1 (P-2) | `main` moved; review nit |
| **default_merge_mode** | `auto` |
| **programme_ref** | `docs/domains/weight_tracking/features/weight-monitoring-model.md` (created in W0, the canonical spec once landed) |
| **amends** | `docs/domains/pet_care/features/care-progression.md` §Observations (standalone entries can now count), `care-item-evolution.md` rows "Weight", "Completing care → Weight monitoring" and the Measurement block, `docs/domains/weight_tracking/**` (rewritten), `docs/architecture/api-reference.md` §Weight entries, §Auth profile and §Care occurrences |

---

## 0. How to use this plan (read first)

### 0.1 Reading order

1. §1 Goal, §2 Vocabulary, §3 Decisions. These are the rules; everything else derives from them.
2. §4 Current state, so you know what exists today.
3. The section for your phase in §10, then the detailed spec it points to (§5 server, §6 Flutter, §7 copy, §8 tests).
4. §9 Risks and §12 Out of scope, so you don't widen the PR.

### 0.2 Non-negotiable rules for every phase

- **Backend is authoritative.** Flutter never decides whether a weight counts as a weigh-in. It asks the server (§5.6) and the server re-validates on write.
- **Additive API only.** Installed native clients can't be force-updated. Never remove or rename a response field. Request fields may be added. Every valid request that worked before still works. The only tightened rules are validation of bad input: a weight dated in the future (§5.3), a non-positive or non-numeric pet weight (§5.7, hardening F-13), and unknown skip reasons on weigh-ins (§5.5).
- **Stay inside the phase's `allowed_paths`** (child snapshot). A file outside them is drift: stop and raise it on the control issue.
- **Respect area ownership** ([parallel-programmes.md §3](../../docs/agent-efficiency/parallel-programmes.md)). Each child's entry gate (§10) says when an area is free.
- **No new cross-feature imports** in Flutter. `node scripts/check_feature_imports.js` must stay green. Use the patterns in §6.1. Never run `--accept-new`; that needs a human.
- **Files stay ≤ 500 lines** (`node scripts/check_file_size.js`).
- **Calendar dates are `YYYY-MM-DD`** on the wire ([calendar-dates.md](../../docs/architecture/calendar-dates.md)).
- **UUIDs are generated in code** (`uuid` v4), never `gen_random_uuid()` in SQL.
- **No raw exception text** in 5xx responses (`publicError(err)`).
- **Tests come with the change**, in the same phase. Every numbered case in §8 is a test, named with its ID in the test title (for example `it('F-8 POST with fulfils_occurrence_id completes the weigh-in', …)`).

### 0.3 Verification commands

| When | Command |
|---|---|
| Server change | `cd server && npx jest --env=node --forceExit <paths>`, then the full `npx jest --env=node --forceExit` before the phase PR |
| Real-DB tests | `sudo pg_ctlcluster 16 main start`, then `cd server && npx jest --env=node --forceExit test/db/<file>` (see existing `server/test/db/*.integration.test.js` for the harness) |
| Migration | `cd server && node scripts/migrate.js up`; down/up test in `server/test/migrations/`; then `bash scripts/db/regenerate-canonical.sh` and commit `db/schema/canonical.sql` + `db/schema/migration-manifest.json` |
| Flutter | `cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos` and `flutter test --concurrency=1 --exclude-tags=integration test/features/<area>` |
| Mocks changed | `cd flutter_app && dart run build_runner build --delete-conflicting-outputs` |
| Contracts | `node scripts/validate_openapi.js` |
| Import gate | `node scripts/check_feature_imports.js`. When you remove a baselined violation, run `--update-baseline` (ratchet down only) and commit `scripts/feature-import-baseline.json` |
| Flutter shards | `node scripts/ci/flutter-shards.mjs check` (new test folders must fall under a shard root in `flutter_app/test/ci_shards.json`) |
| BDD gate | `node e2e/scripts/check_bdd_coverage.js` |
| E2E shards | `node e2e/scripts/shard-files.mjs --summary` to find the shard of `weight.tracking.spec.ts`, then `./scripts/pre-push-changed.sh --e2e-shards <n>` |
| Every phase | `./scripts/pre-push-changed.sh` during work; `./scripts/pre-push.sh` before each landing PR |

### 0.4 Commit and PR conventions

- At each child's bootstrap, create its integration branch from a fresh `origin/main` (`git fetch origin main` first). At the start of every phase, merge `origin/main` into the integration branch (no rebase or force-push on shared branches) and re-run the phase's verification after a landing broadcast from another programme.
- Phase branch → PR into the child's integration branch. Title: `phase(<n>/<m>): <phase title> (<plan_id>)`.
- PR body: what changed, which §8 test IDs were added, verification commands run and their result, and the `git diff --stat` of the phase.
- Pre-PR self-review per `docs/agent-efficiency/pr-review-cost-efficiency.md`.
- The landing PR (integration → `main`) follows parallel-programmes §5: no other programme's `main` PR open; merge `main` in first; full `./scripts/pre-push.sh`; the E2E shards touched; then `/babysit-uat`; then the landing broadcast (§10.4).

### 0.5 When to stop and ask (halt with `**Needs you:**` on the control issue)

- An entry gate in §10 isn't met.
- Code on `main` contradicts §4 in a way that changes the design (for example, `undo.js` already handles weights, or `weight_entries` gained columns).
- A rule here conflicts with a canonical spec that changed after 2026-10-04.
- A test from §8 can't pass without changing behaviour that §3 froze.
- A migration finds data it can't convert (§5.2).

---

## 1. Goal

1. **One record per weight, wherever it was entered.** A weight entered on the weight screen, during a weigh-in, or when creating a pet is the same kind of record, saved by one server service.
2. **A weight can count as the due weigh-in.** When a weight is recorded and a weigh-in is due, the user is offered "Counts as …" (on by default when exactly one weigh-in matches). Saving completes the weigh-in in the same transaction.
3. **Weigh-ins stay consistent.** Undo removes or unlinks the weight correctly. A weigh-in has one date (the weight's date equals the completion date, both ways). Deleting a weight that counted asks for confirmation.
4. **"Couldn't weigh" is a skip with a reason**, not a completion without a weight.
5. **One unit preference per user** (kg or lb), used by every weight input and display. Weights are stored in kg.
6. **One weight screen** that shows the trend, the history (labelled by source) and the weigh-in routines, with a single "Record weight" action. The care item view of a weigh-in routine shows a weight section linking to it.
7. **The pet profile weight is read-only** on edit; it always shows the latest recorded weight.

### 1.1 Owner requirements (verbatim, 2026-10-04)

| # | Requirement |
|---|---|
| R1 | "I want to keep the direct weight tracking view" |
| R2 | "There must be a single unified data model for weight tracking, whether it's seen through the Weight tracking screen or a weight monitoring care item … if I enter a weight, it needs to be visible in care items … and there should not be different data models / entries." |
| R3 | "If I want to enter a random weight entry OUTSIDE of a routine — that should be possible." |
| R4 | (on the analysis) "3- agree with you." — weight entries stay independent of occurrences; "couldn't weigh" is a skip with a reason |
| R5 | "5- Agreed with your recommendation. For weight for pet profile: yes agreed, keep read-only for now." |
| R6 | "6- agreed with all" — the recommendation: server rules, Flutter data, UX, generalising later |
| R7 | Decisions: "1- Yes" (toggle on by default with one match) · "2- yes, reuse" (CSM windows) · "3- skip with a reason: yes" · "4- per user" (unit preference) · "5- yes" (pet profile weight read-only) |
| R8 | On generalising the category-screen pattern: "you are right for now, I need to think through better … it's separate from this weight issue point." → out of scope (§12) |

---

## 2. Vocabulary

UI labels are given in EN and FR. Use these words exactly; don't introduce synonyms.

| Concept | Code / API | EN (UI) | FR (UI) |
|---|---|---|---|
| A recorded weight (any source) | `weight_entries` row, `WeightEntry` | weight | poids / pesée enregistrée |
| A care item of family `weight_monitoring` | `health_entries` row | weigh-in routine | routine de pesée |
| One occurrence of that care item | `health_occurrences` row | weigh-in | pesée prévue |
| A weight linked to a weigh-in | `weight_entries.health_occurrence_id` set | "counts as {routine}" | « compte comme {routine} » |
| A weigh-in the weight could count for | fulfilment candidate | — | — |
| The `/pet/:petId/weight` screen | `WeightHubScreen` | Weight tracking (existing `weightTracking` key) | Suivi du poids |
| The primary action | — | Record weight | Enregistrer le poids |
| Where the weight came from | `measurement_source` | Vet · Scale · Imported (guardian shows no label) | Vétérinaire · Balance · Importé |

---

## 3. Decision record (owner, 2026-10-04)

Each decision gets a stable ID. W0 copies this table into the canonical spec.

| ID | Decision |
|---|---|
| **D-WM-001** | **The weight is the record; the weigh-in points to it.** `weight_entries` is the only store of weights. A weigh-in is completed by linking one weight through `weight_entries.health_occurrence_id` (unique when set; FK `ON DELETE SET NULL`, already in place). There are no occurrences without a care item and no weight copies anywhere else. `pets.weight` stays a derived cache of the latest entry. |
| **D-WM-002** | **Done means a weight was recorded.** A weigh-in can't be completed without a weight (keeps D-CIE-031). "Couldn't weigh" is **Skip** with an optional reason (D-WM-015). |
| **D-WM-003** | **Counts-as is suggested by the server and confirmed by the user.** When a weight is recorded from the Record weight sheet, the server returns the matching weigh-ins (candidates, §5.6). Exactly one → a "Counts as {routine}" switch, **on by default**. Two or more → a choice list with nothing preselected plus "Don't count it as a weigh-in". None → nothing shown. Save waits until the check has answered (it starts when the sheet opens, so it is normally done before the weight is typed); if the check fails, an inline note says so with Retry and Save records a standalone weight. The server re-checks eligibility on save. |
| **D-WM-004** | **Matching reuses the CSM windows.** A weight dated `D` can count for a pending weigh-in `O` of an active (not paused, not closed) routine of the same pet when all of these hold: `D ≤ today` (pet's home calendar); `D ≥ O.scheduled_date − floor(nominalIntervalDays(entry, O.scheduled_date) / 2)` (the same half-interval as D-CSM-030; with no interval, the lower bound is `O.scheduled_date`); `D ≥` the routine's `start_date`; `D ≥` the routine's latest `completed_on`. Per routine, only the **earliest** eligible pending weigh-in is a candidate. |
| **D-WM-005** | **Counting is never automatic.** Only an explicit choice on the Record weight sheet, or "Count as weigh-in" on an existing weight, links a weight. The pet form, seeds, imports and future device sources never link. |
| **D-WM-006** | **Undo reverses the whole command, weight included.** Undoing a completion whose weight was **created** by that command deletes the weight. Undoing a completion that linked a **pre-existing** weight only unlinks it (the weight stays as a standalone weight). Completions recorded before this programme (no weight info in the ledger payload) are undone by **unlinking** (never deleting user data). |
| **D-WM-007** | **A weigh-in has one date.** A linked weight's `date` always equals its occurrence's `completed_on`. Changing either changes both in one transaction, with the completion-date rules (not in the future, not before the routine's start). Undoing a date change restores both. |
| **D-WM-008** | **Stored in kg; shown in the user's unit.** The server stores kg only (`unit = 'kg'`, enforced). Write requests may send `unit: 'kg' | 'lb'`; the server converts with `1 lb = 0.45359237 kg`. Responses always say `unit: 'kg'`. Each user has `weight_unit` (`kg` default, or `lb`) on their profile; every weight input and display uses it. The kg/lb switch on the weight screen changes that preference. The old per-device, per-pet setting is dropped. |
| **D-WM-009** | **Pet profile weight is read-only on edit.** The edit form shows the latest weight and a "Record weight" link to the weight screen, and the app stops sending `weight` on update. For installed clients, `PUT /api/pets/:id` **keeps accepting** `weight`/`weightEntryDate` (deprecated): a changed value is recorded through the shared service as a standalone weight (never counted as a weigh-in), and a non-positive or non-numeric value is rejected with 400. The create form keeps an optional "Weight today" field, saved the same way as the pet's first weight. |
| **D-WM-010** | **One weight screen.** `/pet/:petId/weight` shows, top to bottom: summary (latest weight, change since the previous weight, target), chart (all weights; weigh-ins marked differently; target line), weigh-in routines card, history (tap to edit; labelled by routine or source), "Record weight" action. |
| **D-WM-011** | **Deleting a weight that counted asks first.** Copy in §7. Confirming deletes the weight and reopens the weigh-in (existing server behaviour). |
| **D-WM-012** | **The chart shows every weight.** Weights that counted as a weigh-in use a filled marker; other weights use an outlined marker; a legend explains both. The target (`pets.weight_reference_value`) is a dashed line when set. |
| **D-WM-013** | **Measurement-kind slot, not a category screen.** The care item view gets one extension point keyed by the family's `observationKind` (capability matrix). Only `numeric_weight` is filled now (the weight section, §6.6). No generic observations table, no other categories (owner, R8). |
| **D-WM-014** | **Editing a linked weight.** Changing the value changes nothing in care. Changing the date applies D-WM-007. |
| **D-WM-015** | **Skip reasons for weigh-ins:** `could_not_weigh`, `pet_unsettled`, `vet_will_weigh`, `other`, plus an optional note. The reason is optional. Other families keep today's behaviour (any or no `reason_code`). |
| **D-WM-016** | **Refresh both ways.** Any weight write refreshes care data for that pet; any care command on a weigh-in routine refreshes weight data for that pet (§6.1). |

---

## 4. Current state (verified at `4f3325d`)

### 4.1 Data

| Table / column | Today | Notes |
|---|---|---|
| `weight_entries` | `id, pet_id, user_id, weight (double), unit varchar(10) default 'kg' (nullable), date date (nullable), notes, measured_at timestamptz, created_at, measurement_source (guardian/clinic/device/imported), health_occurrence_id uuid` | Unique partial index `idx_weight_entries_health_occurrence_id`; FK → `health_occurrences(id) ON DELETE SET NULL` (`db/schema/canonical.sql:947`, `:1255`, `:1602`) |
| `pets.weight` | double | Cache refreshed by `refreshPetWeightCache` (`server/lib/petWeightSync.js`) |
| `pets.weight_reference_value / _authority / weight_management_context` | target weight and context | Set through `PUT /api/pets/:id` |
| `users` | no unit preference | `locale`, `timezone` exist |
| `care_schedule_events.reason_code` | varchar(100), free text | Skip already passes `reason_code` from the body (`server/routes/healthEntries/occurrencesRouter.js:233`) |
| Latest migration | `086_pet_lifecycle_notifications` (ARCH E) | Next free number at time of writing: `087` (assign at landing, parallel-programmes §5.5) |

### 4.2 Server write paths for weights

| Path | File | Links to a weigh-in? |
|---|---|---|
| `POST /api/weight-entries` | `server/routes/weightEntries.js:112` | Never. Insert + cache refresh in `withTransaction` (ARCH E, #1503) |
| `PUT /api/weight-entries/:id` | `server/routes/weightEntries.js:157` | Keeps the link; **date not synced** to `completed_on`. Update + cache refresh in `withTransaction` (ARCH E) |
| `DELETE /api/weight-entries/:id` | `server/routes/weightEntries.js:205` | Linked → undoes the completion (`undoCompletionOfOccurrence`) |
| `POST /api/pets/:petId/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight` | `server/routes/healthEntries/completeWeightRouter.js` | Always (creates weight + completes in one `runCareCommand`; since ARCH E the cache refresh and establishment run inside that transaction and post-commit failures are logged with `console.warn`) |
| `POST /api/pets`, `PUT /api/pets/:id` | `server/routes/pets/coreRouter.js:227`, `:354` → `maybeCreateWeightEntryFromPetPayload` | Never. **Accepts `0` and negative weights** (only `NaN` is filtered): hardening finding F-13 never landed (`pet-care-weight-validation`, revoked) |
| Seeds | `server/db/seeds/scenarios/{health-care,care-occurrences,care-item-model-fixture}.js` | Some fixtures insert linked rows directly |

### 4.3 Known defects this plan fixes

| # | Defect | Where |
|---|---|---|
| G1 | A weight entered on the weight screen never completes a due weigh-in | No matching logic anywhere |
| G2 | Undo of a weigh-in leaves the weight linked to a pending occurrence; completing again with a different value returns 409 | `server/lib/care/occurrence/commands/undo.js:35` (`reverse()` never touches `weight_entries`; unchanged by #1503/#1504); `completeWeightRouter.js:126` |
| G3 | Weight date and `completed_on` drift apart | `weightEntries.js:157` (PUT) and `commands/completionDate.js` (neither updates the other) |
| G4 | Units: occurrence screen always sends `kg` and labels "Weight (kg)"; lb/kg is per device per pet; the Flutter model ignores `unit` | `flutter_app/lib/features/care_item/domain/completion_requirements.dart:30`, `app_en.arb:2884`, `weight_tracking/presentation/providers/weight_providers.dart` (`WeightUnitNotifier`), `weight_tracking/data/models/weight_entry_model.dart` |
| G5 | Flutter `WeightEntry` drops `health_occurrence_id` and `measurement_source`; deleting a linked weight silently reopens a weigh-in and doesn't refresh care screens | `weight_tracking/domain/entities/weight_entry.dart`, `core/providers/pet_weight_invalidation.dart` |
| G6 | Completing a weigh-in from the occurrence screen doesn't refresh weight data | `care_item/presentation/occurrence/*` (no weight invalidation) vs. legacy `health_tracking/presentation/widgets/weight_occurrence_care_actions.dart:40` |
| G7 | Two caches of the same weight list; the profile tile and PDF use the one the shared refresh doesn't clear | `weightEntriesProvider` vs `weightEntriesNotifierProvider` (`weight_providers.dart`) |
| G8 | Weight domain docs are stubs and don't mention weigh-ins | `docs/domains/weight_tracking/**` |
| ~~G9~~ | ~~Post-commit side effects swallow errors~~ | **Fixed by ARCH E (#1503)**: logged with `console.warn`; cache and establishment moved into the transaction. Keep that behaviour in the shared service |
| G10 | Pet create/update records `0` or negative weights | `server/lib/petWeightSync.js` `maybeCreateWeightEntryFromPetPayload` (hardening F-13) |

### 4.4 Flutter

| Piece | File | Notes |
|---|---|---|
| Weight screen | `flutter_app/lib/features/pet_profile/presentation/screens/pet_weight_tracking_screen.dart` + `screens/widgets/weight_tracking_section.dart`, `weight_chart.dart`, `add_weight_entry_sheet.dart` | In `pet_profile`, not `weight_tracking` |
| Weight data | `flutter_app/lib/features/weight_tracking/**` | entity, model, datasource, repository, providers |
| Profile tile | `pet_profile/presentation/widgets/pet_detail/pet_profile_weight_insight_section.dart` | Uses `weightEntriesProvider` |
| PDF | `pet_profile/presentation/controllers/download_report_controller.dart:59` | Uses `weightEntriesProvider` |
| Pet form | `pet_profile/presentation/screens/pet_form_screen.dart` (441 lines), `widgets/pet_form/pet_form_weight_section.dart` | Editable weight on edit |
| Occurrence screen (new Done flow) | `care_item/presentation/occurrence/occurrence_blocks.dart` (352 lines), `occurrence_screen.dart` | Inline weight field; Skip without reason |
| Care item view | `care_item/presentation/detail/care_item_detail_screen.dart` (route `petEventView`, `app_router.dart:270`) | Moved there by CARE F (#1504) |
| Legacy weigh-in completion | `health_tracking/presentation/widgets/weight_occurrence_care_actions.dart`, called from `occurrence_care_actions.dart:189`, `:214` and `pet_event_occurrence_actions.dart:37`; `pet_event_occurrence_actions.dart` is imported by three `care_item/presentation/detail/*` files | **Still present after CARE F.** Opens the old add-weight sheet. ARCH G3 (`health_tracking/presentation/widgets/**`) is pending |
| Care refresh hook | `care_item/application/care_item_providers.dart:45` `careDataChangedProvider`, overridden in `lib/main.dart:38` | Pattern reused in §6.1 |
| Pet providers | `pet_profile/presentation/providers/pet_providers.dart:141`, `:150` call `invalidateWeightEntryProviders` | ARCH G1 (`pet_profile/presentation/providers/**`) is pending |
| Import gate edges (baseline) | `pet_profile→weight_tracking`, `health_tracking→weight_tracking`, `weight_tracking→auth`; **no** `care_item→weight_tracking`, **no** `weight_tracking→care_item` | `scripts/feature-import-baseline.json` |

### 4.5 Tests and E2E today

- Jest: `server/test/weightEntries.test.js`, `server/test/healthEntries/completeWeight.test.js`, `server/test/healthEntries/weightOccurrenceCompletion.test.js`, `server/test/lib/petWeightSync.test.js`, `server/test/db/careWeightCompletion.integration.test.js`, `server/test/db/careOccurrences.completionDate.integration.test.js` (weigh-in case), and from ARCH E: `server/test/db/weightCompletionConcurrency.integration.test.js` and `server/test/architecture/transactionOwnership.test.js` (fails on `BEGIN` outside `withTransaction`).
- Flutter: `test/features/weight_tracking/**`, `test/features/pet_profile/presentation/screens/pet_weight_tracking_screen_test.dart`.
- BDD: `flutter_app/test/bdd/features/weight_tracking.feature` (11 scenarios).
- Playwright: `e2e/playwright/tests/weight.tracking.spec.ts`, page object `e2e/playwright/pages/weight-tracking.page.ts`.

---

## 5. Server specification

### 5.1 Module layout (created in W1, extended in W2–W3)

```
server/lib/care/observations/
  weightPrimitives.js            (exists — unchanged)
  weightUnits.js                 NEW: parseWeightInput({ weight, unit }) → { kg } | { error }, KG_PER_LB = 0.45359237
  weightObservationRepository.js NEW: all SQL on weight_entries (insert, update, delete, find by id, find by occurrence, list by pet with fulfils join)
  weightObservationService.js    NEW: recordWeight, updateWeight, deleteWeight (standalone and linked), all in withTransaction or runCareCommand
  weightFulfilment.js            NEW (W3): pure eligibility rule (D-WM-004) + candidate loader
  weightFulfilmentService.js     NEW (W3): fulfil-on-create, fulfil-existing, overview read
server/routes/weightEntries/      NEW folder replacing server/routes/weightEntries.js (W1)
  index.js                       mounts the routers below; default export weightEntriesRoutes(pool) (same name, so server/bin/server.js only changes its import path)
  readRouter.js                  GET /, GET /latest, (W3) GET /overview, GET /fulfilment-candidates
  writeRouter.js                 POST /, PUT /:id, DELETE /:id, (W3) POST /:id/fulfil
  wire.js                        weightEntryToMap (adds fulfils in W3)
```

Rules:

- Routes are thin: parse, authorise, call the service, map the result. No SQL in routes.
- Every transaction uses `withTransaction` (`server/lib/db/withTransaction.js`) or `runCareCommand` (`server/lib/care/occurrence/index.js:75`), never `BEGIN` by hand; `server/test/architecture/transactionOwnership.test.js` (ARCH E) enforces it. When a weigh-in is involved, use `runCareCommand` with `beforeCommand` for the weight write (same pattern as `completeWeightRouter.js` today), so the care item row lock covers both.
- **Build on ARCH E, don't redo it.** ARCH E (#1503) already runs `refreshPetWeightCache` and `maybePersistWeightEstablishment` on the transaction client and logs post-commit failures with `console.warn`. Move that code into the service as it is; the ARCH E tests (`completeWeight.test.js` fault injection, `weightCompletionConcurrency.integration.test.js`) must stay green unchanged.
- Audit and pet activity run **after commit**, with ARCH E's `console.warn` logging, and never change the response.
- `completeWeightRouter.js` keeps its route and response shape and becomes a thin wrapper around `weightObservationService.recordWeight({ …, fulfilOccurrenceId })` with the idempotency and 409 rules it has today.

### 5.2 Migration `*_weight_monitoring_unify` (W1)

File names: `db/migrations/<NNN>_weight_monitoring_unify.sql` and `<NNN>_weight_monitoring_unify_down.sql`; `NNN` is the next free number on `main` when the landing PR opens (092 at the time of writing (087–091 taken by ARCH F and PEOPLE server #1523); 085–091 taken by ARCH E/F and PEOPLE server). Register it in `db/schema/migration-manifest.json` and regenerate `db/schema/canonical.sql` with `bash scripts/db/regenerate-canonical.sh`.

Up (one transaction, `BEGIN; … COMMIT;` as in `084`):

1. **Guard:** `DO $$ BEGIN IF EXISTS (SELECT 1 FROM weight_entries WHERE unit IS NOT NULL AND lower(unit) NOT IN ('kg','lb','lbs')) THEN RAISE EXCEPTION 'weight_entries has units other than kg/lb; convert manually first'; END IF; END $$;`
2. `UPDATE weight_entries SET weight = weight * 0.45359237, unit = 'kg' WHERE lower(unit) IN ('lb','lbs');`
3. `UPDATE weight_entries SET unit = 'kg' WHERE unit IS NULL;`
4. `UPDATE weight_entries SET date = (COALESCE(measured_at, created_at) AT TIME ZONE 'UTC')::date WHERE date IS NULL;` then `UPDATE weight_entries SET date = CURRENT_DATE WHERE date IS NULL;` (both timestamps null, defensive).
5. `ALTER TABLE weight_entries ALTER COLUMN unit SET DEFAULT 'kg', ALTER COLUMN unit SET NOT NULL, ALTER COLUMN date SET NOT NULL;`
6. `ALTER TABLE weight_entries ADD CONSTRAINT weight_entries_unit_kg_check CHECK (unit = 'kg');`
7. `ALTER TABLE users ADD COLUMN weight_unit varchar(2) NOT NULL DEFAULT 'kg';` and `ALTER TABLE users ADD CONSTRAINT users_weight_unit_check CHECK (weight_unit IN ('kg','lb'));`

Down: drop both constraints, `ALTER COLUMN date DROP NOT NULL`, `ALTER COLUMN unit DROP NOT NULL`, `DROP COLUMN weight_unit`. Converted lb values are **not** converted back (state that in a comment; kg is correct data).

Test: `server/test/migrations/<NNN>_weight_monitoring_unify.test.js` following `081_health_entry_absence_resolutions.test.js`: up on fixture rows (lb row, `lbs` row, null unit, null date), assert conversions and constraints; down; up again (idempotent path); the guard raises for a `stone` row.

If the guard fires on UAT or production data: **halt** (§0.5) and report the row counts on the control issue. Don't widen the conversion.

### 5.3 Units and dates on the wire (W1)

- `weightUnits.parseWeightInput({ weight, unit })`:
  - `weight` required, finite, `> 0`; strings accepted (`"12.4"`, and `"12,4"` → 12.4).
  - `unit` absent/`null` → `kg`. `'kg'` or `'lb'` (case-insensitive) accepted. Anything else → `{ error: 'unit must be kg or lb' }` (400).
  - Returns `{ kg }`, with the lb value converted using `KG_PER_LB = 0.45359237`. No rounding on the server.
- Every weight response uses `unit: 'kg'` and the stored kg value. (Installed clients only ever sent kg, so they see no change.)
- **Date rule (new):** a weight's `date` must be `≤ today` in the pet's home calendar (`careAsOfForZone(loadPetHomeTimezone(...))`, see `server/lib/care/occurrence/careAsOf.js`). Later → 400 `{ error: 'date cannot be in the future', code: 'date_in_future' }`. Absent date → today (pet calendar), as today but with the pet's calendar instead of the server's.
- Applies to `POST /api/weight-entries`, `PUT /api/weight-entries/:id` and `complete-weight`.

### 5.4 User unit preference (W1)

- `server/routes/auth/profileRouter.js`: add `weight_unit` to `PROFILE_FIELDS` (line 22) with validation (`'kg' | 'lb'`, else 400 `weight_unit must be kg or lb`).
- `server/routes/auth/shared.js` `userRowToMap`: add `weight_unit: row.weight_unit || 'kg'`.
- `server/lib/gdprUserExport.js`: if it lists user columns explicitly, add `weight_unit`. If it selects `*`, nothing to do. (Read it and say which in the PR.)
- Signup/login responses use `userRowToMap`, so they carry the field automatically. Check that `auth.test.js` / `profile.test.js` snapshots are updated.

### 5.5 Linked weigh-in integrity (W2)

**Undo (D-WM-006).**

1. Every command that completes a weigh-in with a weight records it in the ledger payload: `extra.weight = { id: <weight id>, created: true|false }`. (`created: true` from complete-weight and fulfil-on-create; `false` from fulfil-existing in W3.) Add it in the service where `completeOccurrenceCommand` is called, by passing an `extra` addition. Don't change `complete.js` for non-weight families: the safest is for the weight service to wrap the command function and merge `weight` into `event.extra` before returning.
2. In `undo.js` `reverse()` (line 35), after restoring rows: if `payload.weight` exists and `created === true`, `DELETE FROM weight_entries WHERE id = $1 AND health_occurrence_id = $2` (the occurrence of the event). If `created === false`, `UPDATE weight_entries SET health_occurrence_id = NULL WHERE id = $1 AND health_occurrence_id = $2`. If `payload.weight` is absent and the event is a `completed` event, `UPDATE weight_entries SET health_occurrence_id = NULL WHERE health_occurrence_id = <event occurrence>` (legacy rows, unlink only). Then `refreshPetWeightCache(db, entry.pet_id)` when any row changed. All on `ctx.db` (inside the command transaction).
3. `undoCompletionOfOccurrence` (used by DELETE weight, `undo.js:114`) is unchanged: the weight is already deleted by `beforeCommand`, so the new code finds no row (both `WHERE` clauses include the occurrence id).

**One date (D-WM-007).**

1. `changeCompletionDateCommand` (`commands/completionDate.js`): after `updateCompletedOn`, `UPDATE weight_entries SET date = $1 WHERE health_occurrence_id = $2 RETURNING id, date` and record `extra.weight_date_before = <old date ISO>` when a row changed. Refresh the cache.
2. Undo of a `completion_date_changed` event: `reverse()` restores the occurrence row (existing code); add: when `payload.weight_date_before` is set, `UPDATE weight_entries SET date = $1 WHERE health_occurrence_id = $2`, then refresh the cache.
3. `PUT /api/weight-entries/:id` on a **linked** weight whose `date` changes: run `runCareCommand` on the weigh-in's care item with `beforeCommand` updating value/notes/source (not date), and the command `changeCompletionDateCommand(ctx, { occurrenceId, completedOn: newDate })` (which updates the weight's date through rule 1). Command errors (`completed_on_in_future`, `completed_on_before_start`, `occurrence_not_completed`) map to their status and body via `CareCommandError.toBody()`. Response: the updated weight map plus `undo_token` (additive).
4. `PUT` on a linked weight whose date doesn't change, or on a standalone weight: plain update in `withTransaction` (no care event).

**Delete.** Unchanged behaviour. The response gains `reopened_occurrence: { entry_id, occurrence_id } | null` (additive) so clients can say what happened.

**Skip reasons (D-WM-015).** In the skip route (`occurrencesRouter.js:232`), when the item's `care_family === 'weight_monitoring'` and `reason_code` is present, it must be one of the four codes, else 400 `{ error: 'invalid skip reason', code: 'invalid_skip_reason' }`. The note travels in the existing `notes` body field (the route already passes it to `skipOccurrenceCommand`, which stores it on the occurrence and as the ledger `reason_note`); it is optional, and for weigh-ins longer than 500 characters → 400 `{ code: 'skip_note_too_long' }`. Put the list in `server/lib/care/capabilities.js` (or `enums.js`) as `SKIP_REASON_CODES.weight_monitoring`, so later families can add theirs.

**Occurrence detail (additive).** `GET /api/health-entries/:id/occurrences/:occId` (`occurrencePatchRouter.js:85`; `linkedWeight()` at `:47`):

- `linked_weight` gains `id`, `date`, `measurement_source` (keep `value`, `unit`).
- New `skip_reason: { code, note } | null`, read from the latest non-undone `skipped` ledger event of that occurrence.

**Care item history (W3, requirement R2b).** `GET /api/health-entries/:id/history` rows for completed `weight_monitoring` occurrences gain additive `linked_weight: { value, unit, date } | null` (same shape as occurrence detail). Flutter history dialog (W9) shows the weight in the user's unit for those rows.

### 5.5b Observation undo/date hooks (W2, A1/A2)

The generic care engine **must not** import `weight_entries` SQL. `server/lib/care/observations/` implements `observationCompletionHooks` (undo + completion-date change) registered at startup; ledger payload uses `observation: { kind: 'numeric_weight', id, created }` (opaque to the engine). Add `server/test/architecture/careObservationBoundary.test.js`: `server/lib/care/occurrence/**` does not import `weightObservationRepository` or raw weight SQL paths.

### 5.6 Counting a weight as a weigh-in (W3)

**Pure rule** `weightFulfilment.js`:

```text
isEligible({ entry, occurrence, dateIso, todayIso, latestCompletedOn }) →
  entry.care_family === 'weight_monitoring'
  AND entry.status === 'active'                       (paused, closed → no)
  AND occurrence.status === 'pending'
  AND dateIso <= todayIso
  AND dateIso >= windowStart(entry, occurrence)       (D-WM-004)
  AND (entry.start_date == null OR dateIso >= entry.start_date)
  AND (latestCompletedOn == null OR dateIso >= latestCompletedOn)
windowStart = occurrence.scheduled_date − floor(nominalIntervalDays(entry, occurrence.scheduled_date) / 2) days
              (interval 0 → occurrence.scheduled_date)
```

`nominalIntervalDays` is in `server/lib/care/schedule/seriesDates.js:143`. Unit-test the rule as a table (§8.3).

**Loader** `findFulfilmentCandidates(db, { petId, dateIso, asOf })`: one query for the pet's active `weight_monitoring` items, their pending occurrences (ascending `scheduled_date, scheduled_time`), and each item's latest `completed_on`. Apply the rule; keep the earliest eligible occurrence per item. Return:

```json
{
  "date": "2026-10-04",
  "candidates": [
    {
      "entry_id": "…", "entry_name": "Monthly weigh-in",
      "occurrence_id": "…", "scheduled_date": "2026-10-03",
      "status": "overdue"
    }
  ],
  "default_occurrence_id": "…"   // set only when candidates.length === 1, else null
}
```

`status` comes from `occurrenceStatus` (`server/lib/care/schedule/occurrenceStatus.js`) with the pet's `asOf`.

**Endpoints** (all under `/api/weight-entries` and `/backend/api/weight-entries`):

| Method | Path | Auth | Body / query | Success | Errors |
|---|---|---|---|---|---|
| GET | `/fulfilment-candidates` | `WEIGHT_VIEW` on the pet | `pet_id`, `date` (default today) | 200 shape above (empty list when the user can't manage care for the pet) | 400 bad date; 403 |
| POST | `/` | `WEIGHT_EDIT`; plus `userCanManageHealthEntry` on the item when `fulfils_occurrence_id` is set | existing body + optional `fulfils_occurrence_id` | 201 weight map; when fulfilled, plus `fulfilment: { entry_id, occurrence, next_due_date, undo_token }` | 403; 409 `{ code: 'fulfilment_not_eligible' }` (nothing written); 409 `{ code: 'occurrence_not_open' }` from the command |
| POST | `/:id/fulfil` | `WEIGHT_EDIT` + `userCanManageHealthEntry` | `{ occurrence_id }` | 200 weight map + `fulfilment` | 404 weight; 409 `already_linked`; 409 `fulfilment_not_eligible` (uses the weight's own date) |
| GET | `/overview` | `WEIGHT_VIEW` | `pet_id` | 200 overview (below) | 403 |

On fulfil, **in one `runCareCommand`** on the item: `beforeCommand` inserts (or, for `/:id/fulfil`, links) the weight; re-check eligibility **inside** the lock (concurrency); then `completeOccurrenceCommand(ctx, { occurrenceId, completedOn: weight.date, notes: weight.notes })` with `extra.weight` (§5.5). The unique index makes a second concurrent link fail with `23505` → map to 409 `already_linked`.

**List additions (additive).** `GET /api/weight-entries` rows gain `fulfils: { entry_id, entry_name, occurrence_id, scheduled_date } | null` (LEFT JOIN occurrence + item).

**Overview** `GET /api/weight-entries/overview?pet_id=`:

```json
{
  "pet_id": "…",
  "as_of": { "date": "2026-10-04", "time": "09:12", "timezone": "Europe/Paris" },
  "reference": { "value": 12.0, "authority": "vet_target", "management_context": "none" } | null,
  "routines": [
    {
      "entry_id": "…", "name": "Monthly weigh-in", "status": "active",
      "frequency": "monthly", "frequency_interval": 1, "frequency_days": null,
      "next": { "occurrence_id": "…", "scheduled_date": "2026-10-03", "status": "overdue" } | null
    }
  ]
}
```

`routines` = the pet's `weight_monitoring` items with status `active` or `paused` (not closed), ordered by `next.scheduled_date` nulls last. Weights are **not** in the overview (they come from `GET /api/weight-entries`; one cache per data set, §6.2).

### 5.7 Pet create and update (W1)

Behaviour stays compatible for installed clients; only bad input is newly rejected. This is why it can land with the server child: the Flutter form (still editable until W5) keeps working exactly as today between landings A and B.

- `server/routes/pets/coreRouter.js`, `POST /api/pets` (`:227`) and `PUT /api/pets/:id` (`:354`): replace `maybeCreateWeightEntryFromPetPayload` with a call to `weightObservationService.recordWeightFromPetPayload(db, { petId, userId, weight, date })`, which:
  - does nothing when `weight` is absent, `null` or `''`;
  - rejects a non-numeric or non-positive value: the route returns 400 `{ error: 'weight must be a positive number', code: 'invalid_weight' }` **before** writing the pet (closes hardening F-13 / G10);
  - records a standalone weight (source `guardian`, unit kg, date from `weightEntryDate` or today in the pet's calendar, never fulfilling, D-WM-005) only when the value differs from the latest entry (today's rule); a `weightEntryDate` in the future → 400 `date_in_future` (same rule as §5.3);
  - refreshes `pets.weight` in the same transaction. If the pet write and the weight write aren't already in one transaction in `coreRouter.js`, wrap them with `withTransaction`.
- `pets.weight` is never written from the request body directly: it's always the cache from `refreshPetWeightCache` (today the `UPDATE` writes the body value and then refreshes; drop the body value from the `SET` list).
- Mark `weight`/`weightEntryDate` on `PUT` as **deprecated** in `api-reference.md` ("kept for installed clients; the app records weights through `/api/weight-entries`").
- Remove `maybeCreateWeightEntryFromPetPayload` and `createWeightEntryAndSyncPet` from `server/lib/petWeightSync.js` once no caller is left (grep `server/`, including seeds and tests).
- **Area check:** `coreRouter.js` is in PEOPLE `people-server-7f3b` s3's paths; see the child A entry gate (§10.1).

### 5.8 API documentation

Each phase updates `docs/architecture/api-reference.md` §Weight entries / §Auth / §Care occurrences for what it changed, and `docs/architecture/openapi/pet-care-critical.json` for paths already in it (occurrence detail: `linked_weight`, `skip_reason`). Run `node scripts/validate_openapi.js` and `server/test/openapi/petCareContract.test.js`.

---

## 6. Flutter specification

### 6.1 Cross-feature wiring (no new feature edges)

The import gate forbids `care_item → weight_tracking` and `weight_tracking → care_item`. Use **core contracts overridden at composition** (`lib/main.dart`, exempt from the gate), the same pattern as `careDataChangedProvider`:

| New file | Contents |
|---|---|
| `lib/core/weight/weight_unit.dart` | `enum WeightUnit { kg, lb }`; `const double kgPerLb = 0.45359237`; `double toDisplay(double kg, WeightUnit u)`; `double toKg(double value, WeightUnit u)`; `String unitLabel(WeightUnit u)` (`kg`/`lb`); `WeightUnit weightUnitFromWire(String? s)`; `String weightUnitToWire(WeightUnit u)`; `String formatWeight(double kg, WeightUnit u)` → one decimal + unit |
| `lib/core/weight/weight_unit_preference.dart` | `final weightUnitPreferenceProvider = Provider<WeightUnit>((ref) => WeightUnit.kg);` and `final setWeightUnitPreferenceProvider = Provider<Future<void> Function(WeightUnit)>((ref) => (_) async {});` |
| `lib/core/providers/pet_care_sync.dart` | `abstract class PetCareSync { Future<void> weightChanged(String petId); Future<void> careChanged(String petId); }`, a no-op implementation, and `final petCareSyncProvider = Provider<PetCareSync>((ref) => const NoopPetCareSync());` |
| `lib/core/care/care_item_observation_section.dart` | `typedef CareItemObservationSectionBuilder = Widget? Function(BuildContext context, {required String petId, required String entryId, required String observationKind});` and `final careItemObservationSectionProvider = Provider<CareItemObservationSectionBuilder>((ref) => (_, {required petId, required entryId, required observationKind}) => null);` (W9) |
| `lib/app_pet_care_sync.dart` (composition, next to `main.dart`) | `AppPetCareSync(Ref ref)`: `weightChanged` invalidates the weight families (`weightEntriesNotifierProvider(petId)`, `weightOverviewProvider(petId)`, `weightFulfilmentCandidatesProvider` family), `petListProvider`, `allPetsIncludingOrgProvider`; `careChanged` calls the same refresh as the `careDataChangedProvider` override (`healthEntriesNotifierProvider.notifier.refresh()`) and invalidates `careItemsControllerProvider` (family) |

`lib/main.dart` overrides (add them next to the existing `careDataChangedProvider` override at `lib/main.dart:38`):

| Provider | Override |
|---|---|
| `weightUnitPreferenceProvider` | `weightUnitFromWire(ref.watch(authProvider).user?.weightUnit)` |
| `setWeightUnitPreferenceProvider` | calls the auth notifier's profile update (`auth_providers.dart:189` `updateProfile`, extended with `weightUnit`) |
| `petCareSyncProvider` | `AppPetCareSync(ref)` |
| `careDataChangedProvider` (existing) | keep its current body **and** invalidate the whole weight families (`ref.invalidate(weightEntriesNotifierProvider)` without an argument invalidates every pet's instance; same for `weightOverviewProvider`). It has no pet id, so it can't target one pet. Cost is small: invalidation only refetches instances that a mounted widget is listening to (normally one pet); the others are rebuilt lazily on their next read. Care commands that know their pet (the occurrence screen, W8) call `petCareSyncProvider.weightChanged(petId)` instead. |
| `careItemObservationSectionProvider` (W9) | returns `WeightCareItemSection(petId:, entryId:)` when `observationKind == 'numeric_weight'`, else `null` |

Delete `lib/core/providers/pet_weight_invalidation.dart` once no caller is left (it's a baselined R3 violation; run `--update-baseline`). Its callers are `pet_profile/presentation/providers/pet_providers.dart:141` and `:150` (replace with `ref.read(petCareSyncProvider).weightChanged(pet.id)`) and the weight notifier itself; `pet_providers.dart` is in ARCH G1's paths (see the child B gate, §10.2).

Feature barrels: create `lib/features/weight_tracking/weight_tracking.dart` exporting the public API (entity, providers, `WeightHubScreen`, `showRecordWeightSheet`, `WeightCareItemSection`). Consumers outside the feature (`pet_profile`, router, `main.dart`) import the barrel, not `presentation/` or `data/` paths.

### 6.2 Weight data (W5)

- `WeightEntry` gains `healthOccurrenceId` (`String?`), `measurementSource` (`String`, default `guardian`), `fulfils` (`WeightFulfils?` with `entryId`, `entryName`, `occurrenceId`, `scheduledDate`). The model parses them (`health_occurrence_id`, `measurement_source`, `fulfils`) and **reads `unit`**: if a row ever says `lb`, convert to kg (defensive; the server only sends kg after W1).
- `WeightEntryModel.toJson` sends `unit: 'kg'` explicitly.
- **One list provider:** keep `weightEntriesNotifierProvider(petId)` as the only cache of the list. Delete `weightEntriesProvider` and `latestWeightProvider`. The profile tile and the PDF read `weightEntriesNotifierProvider(petId)` (`.future` for the PDF). Latest = first of the sorted list.
- `WeightUnitNotifier` and its `SharedPreferences` key are deleted. Every unit read uses `weightUnitPreferenceProvider`; the hub's kg/lb switch calls `setWeightUnitPreferenceProvider`.
- **Compatibility shim (W5 → removed in W8):** the CARE-owned legacy file `health_tracking/presentation/widgets/weight_occurrence_care_actions.dart` reads `weightUnitProvider(petId)` and passes a `WeightUnit` to the legacy sheet. Child B must not edit it. Keep `weight_providers.dart` re-exporting `WeightUnit` from `core/weight/weight_unit.dart`, and keep `weightUnitProvider` as a `@Deprecated` `Provider.family<WeightUnit, String>` returning `ref.watch(weightUnitPreferenceProvider)`. Keep the legacy sheet's `addEntry` path compiling (it now goes through `weightEntriesNotifierProvider`).
- `AuthUser` (`lib/features/auth/data/auth_service.dart:10`) gains `weightUnit` (`String`, default `'kg'`) parsed from `weight_unit`; `updateMe` accepts `weightUnit`.
- New in W6: `WeightOverview` (+ `WeightRoutine`, `WeightRoutineNext`, `WeightReference`) model and `weightOverviewProvider(petId)` (`FutureProvider.autoDispose.family`); `WeightFulfilmentCandidates` model and `weightFulfilmentCandidatesProvider((petId, date))`. Datasource methods for `GET /overview`, `GET /fulfilment-candidates`, `POST /` with `fulfils_occurrence_id`, `POST /:id/fulfil`, `PUT /:id`, undo through `POST /api/health-entries/:entryId/schedule/undo` with `{ undo_token }`.
- After every weight write (add, edit, delete, fulfil, undo): `ref.read(petCareSyncProvider).weightChanged(petId)` and `.careChanged(petId)`.

### 6.3 Weight screen (W6)

Move the screen into the feature: `lib/features/weight_tracking/presentation/screens/weight_hub_screen.dart` (`WeightHubScreen`), with widgets under `presentation/widgets/`. The router (`lib/core/router/app_router.dart:286`) imports it through the barrel. Delete `pet_profile/presentation/screens/pet_weight_tracking_screen.dart` and `screens/widgets/weight_tracking_section.dart` / `weight_chart.dart` (moved). **Keep** `pet_profile/.../add_weight_entry_sheet.dart` and `controllers/weight_tracking_controller.dart` untouched except imports: the legacy CARE-owned path still calls them until W8 (§10.3). Mark both `@Deprecated('Removed in weight-unify-care W8')`.

Layout (one scroll view, 16 px gutters, works at 360 px wide):

1. **Summary card** `Key('weight_hub_summary')`: latest weight in the user's unit (large); "Recorded {date}"; change since the previous weight ("+0.4 kg since 3 Sep", hidden with fewer than 2 weights); target line "Target {weight} · {authority label}" when `reference` is set. kg/lb `SegmentedButton` (keep the existing E2E-visible labels `kg` / `lb`) in the card's top-right; it writes the user preference.
2. **Chart** (≥ 2 weights), the existing `WeightChart` moved and extended: filled markers for weights with `fulfils`, outlined for others, dashed target line, legend row "● Weigh-in · ○ Other weight" (localised). Chart `Semantics` label stays `weightChartLabel(n)`.
3. **Weigh-in routines card** `Key('weight_hub_routines')`:
   - none: title "No weigh-in routine", body "A regular weigh-in helps spot changes early.", button "Set up a weigh-in routine" → care add with `family=weight_monitoring` preselected (§6.6, W9 / FW-20).
   - one or more: one row per routine: name; "Next weigh-in {date} · {status word}" (status words from the existing care status strings: Coming up / Due / Overdue); tap → `context.push('/pet/$petId/events/$entryId')`. Paused routines show "Paused".
4. **History**: rows newest first: weight (user unit), date, notes; a chip with the routine name when `fulfils` is set, else a source chip for `clinic`/`device`/`imported` (§7). Tap → Record weight sheet in edit mode. Trailing delete icon → confirm dialog (§6.5).
5. **Record weight** action: app-bar `IconButton` (keep `Key('weight_tracking_add_app_bar')`) and footer `FilledButton.tonalIcon` (keep `Key('weight_tracking_add_footer')`), both opening the sheet in create mode. Rename their label to "Record weight".
6. Empty state unchanged in structure (keep its semantics label `noWeightDataYet`), with the routines card shown under it.

Accessibility: every interactive control has a semantic label; chips are read as "Counts as {routine}" / "From the vet"; the switch in the sheet reads its full sentence.

### 6.4 Record weight sheet (W6)

`showRecordWeightSheet(BuildContext, WidgetRef, {required String petId, WeightEntry? editing})` in `weight_tracking/presentation/sheets/record_weight_sheet.dart` (split widgets so each file ≤ 300 lines).

Fields: **Date** (default today in the device calendar; ≤ today), **Weight ({unit})** (decimal keyboard; accepts `,`), **Notes (optional)**.

**Counts as** (create mode only):

- On open and on every date change, read `weightFulfilmentCandidatesProvider((petId, date))`. While it loads, show a one-line progress row "Checking for a due weigh-in…" and **keep Save disabled** (D-WM-003; the request starts when the sheet opens, so it normally finishes before the weight is typed). On error or after 8 seconds, show "Couldn't check for a due weigh-in." with a Retry text button, and enable Save; saving then records a standalone weight.
- 0 candidates → nothing.
- 1 → `SwitchListTile` `Key('record_weight_counts_as')`, title "Counts as {routine}", subtitle "{status word} · {scheduled date}", **on by default**. Changing the date resets it to on if the candidate is still the same occurrence, else re-evaluates.
- ≥ 2 → radio group `Key('record_weight_counts_as_choice')` with one option per candidate and "Don't count it as a weigh-in". **Nothing preselected**; Save is disabled until one is chosen, with helper text "Choose which weigh-in this counts as".
- On save: `POST /api/weight-entries` with `fulfils_occurrence_id` when chosen. On `409 fulfilment_not_eligible`, re-fetch candidates and show "That weigh-in can't take this weight any more. Check and save again." without closing the sheet.

**Edit mode:** same fields, prefilled. If the weight `fulfils` a weigh-in, show an info row "Counts as {routine} ({scheduled date}). Changing the date also changes when the weigh-in was done." Map server errors `completed_on_in_future` / `date_in_future` → "The date can't be in the future"; `completed_on_before_start` → "The date can't be before the routine started".

**After save** (snackbar, server-confirmed only):

- standalone: "Weight saved".
- fulfilled: "Saved · counted as {routine}" with **Undo** (calls schedule undo with the returned `undo_token`; success → "Weigh-in undone", both refresh hooks).

**Existing weight → "Count as weigh-in":** in edit mode, when the weight is standalone and the candidates endpoint (for the weight's own date) returns any, show a text button "Count as a weigh-in" that opens the same choice UI and calls `POST /:id/fulfil`.

### 6.5 Delete confirmation (W6)

- Standalone: "Delete this weight?" / "This can't be undone." / [Cancel] [Delete].
- Linked: "Delete this weight?" / "It counted as {routine} on {date}. Deleting it marks that weigh-in as not done." / [Cancel] [Delete].
- After delete of a linked weight (response `reopened_occurrence` set): snackbar "Weight deleted · {routine} is due again".

### 6.6 Care side (W8–W9)

- **Occurrence screen weight field** (`care_item/presentation/occurrence/occurrence_blocks.dart`): label "Weight ({unit})" from `weightUnitPreferenceProvider`; send `unit: weightUnitToWire(pref)` and the value as typed (the server converts). Replace `careWeightFieldLabel` with a parameterised `careWeightFieldLabelUnit(unit)`. `CompletionInputs.weightUnit` defaults from the preference.
- **Completed weigh-in view:** linked weight shown as `formatWeight` in the user's unit with its date, plus a "See all weights" link → `/pet/$petId/weight`.
- **Skip with a reason:** for `weight_monitoring`, the Skip button opens one bottom sheet (SH-1: one modal) titled "Skip this weigh-in?" with four `ChoiceChip`s (§7, none selected; optional), an optional note field, and [Cancel] [Skip]. Send `reason_code` and `notes`. Other families keep the direct skip.
- **Skipped weigh-in view:** "Skipped · {reason label}" and the note when present (from `skip_reason`).
- **After any command on a `weight_monitoring` item** (done, skip, undo, change date, completion date): `ref.read(petCareSyncProvider).weightChanged(petId)`.
- **Care item view weight section (W9):** in the care item view screen (route `petEventView`, `care_item/presentation/detail/care_item_detail_screen.dart` / `care_item_detail_body.dart`), insert `ref.watch(careItemObservationSectionProvider)(context, petId:, entryId:, observationKind:)` below the schedule section when the family's capabilities say `supportsObservations` (`CareFamilyCapabilityPolicy`, `features/pet_care/core/care_family_capabilities.dart`). `WeightCareItemSection` (in `weight_tracking`): title "Weight"; latest weight in the user's unit and date; sparkline of the last 8 weights (reuse `CareInsightTile`'s sparkline if reachable through a barrel, else a small `CustomPaint`); "See all weights" → `/pet/$petId/weight`.
- **Hub → care add (W9, FW-20):** routes from the weight hub "Set up a weigh-in routine" (and the empty-state button in §6.3) open care add with `family=weight_monitoring` preselected (query or `extra`; implementer picks one pattern and documents it in the child B PR).
- **Legacy path (W8):** replace `WeightOccurrenceCareActions.showWeightEntrySheetForOccurrence` call sites (`occurrence_care_actions.dart:189`, `:214`, `pet_event_occurrence_actions.dart:37`) with opening the occurrence screen (`/pet/$petId/events/$entryId/occurrences/$occurrenceId?focus=weight`). Keep `pet_event_occurrence_actions.dart` itself (three `care_item/presentation/detail/*` files import it); only its weight branch goes. Then delete `weight_occurrence_care_actions.dart`, the health_tracking `completeWeightOccurrence` chain (`health_repository*.dart`, `health_remote_datasource*.dart`, `health_remote_datasource_occurrence_methods.dart`, `health_weight_completion_remote.dart`), `pet_profile/.../add_weight_entry_sheet.dart` and `weight_tracking_controller.dart`, and their tests. All of these still exist at `4f3325d` (CARE F kept them). **If ARCH G3 has moved or deleted any of them by then, follow its new layout and say so in the PR.**

### 6.7 Pet form and profile (W5)

- Edit form: replace the editable weight field with a read-only row "Weight {latest} · recorded {date}" (or "No weight recorded yet") and a text button "Record weight" → `/pet/$petId/weight`. Stop sending `weight`/`weightEntryDate` on update.
- Create form: keep the optional field, relabelled "Weight today ({unit})", converted to kg before sending.
- Profile tile (`pet_profile_weight_insight_section.dart`) uses `weightEntriesNotifierProvider` and the user unit.

---

## 7. Copy (EN / FR)

Add to `flutter_app/lib/l10n/app_en.arb` and `app_fr.arb` (keys in `lowerCamelCase`, placeholders declared). Follow `docs/design/copy-tone.md` (calm, no blame).

**FR status:** written by the plan author, **pending owner review**. Not a gate: W6 posts the FR column on the child B control issue, and corrections ride the next phase (W7) or a follow-up copy PR.

| Key | EN | FR |
|---|---|---|
| `weightRecordAction` | Record weight | Enregistrer le poids |
| `weightRecordSheetTitle` | Record weight | Enregistrer le poids |
| `weightEditSheetTitle` | Edit weight | Modifier le poids |
| `weightFieldLabelUnit` | Weight ({unit}) | Poids ({unit}) |
| `weightTodayFieldLabelUnit` | Weight today ({unit}) | Poids aujourd'hui ({unit}) |
| `weightCountsAs` | Counts as {routine} | Compte comme {routine} |
| `weightCountsAsChoiceHelp` | Choose which weigh-in this counts as | Choisissez la pesée prévue concernée |
| `weightDontCount` | Don't count it as a weigh-in | Ne pas la compter comme pesée prévue |
| `weightCountAsWeighInAction` | Count as a weigh-in | Compter comme pesée prévue |
| `weightFulfilmentStale` | That weigh-in can't take this weight any more. Check and save again. | Cette pesée prévue ne peut plus recevoir ce poids. Vérifiez puis enregistrez à nouveau. |
| `weightCheckingWeighIn` | Checking for a due weigh-in… | Recherche d'une pesée prévue… |
| `weightCheckFailed` | Couldn't check for a due weigh-in. | Impossible de vérifier s'il y a une pesée prévue. |
| `weightCheckRetry` | Retry | Réessayer |
| `weightSaved` | Weight saved | Poids enregistré |
| `weightSavedCountedAs` | Saved · counted as {routine} | Enregistré · compté comme {routine} |
| `weightWeighInUndone` | Weigh-in undone | Pesée prévue annulée |
| `weightLinkedEditInfo` | Counts as {routine} ({date}). Changing the date also changes when the weigh-in was done. | Compte comme {routine} ({date}). Changer la date modifie aussi la date de la pesée prévue. |
| `weightDateInFuture` | The date can't be in the future | La date ne peut pas être dans le futur |
| `weightDateBeforeRoutineStart` | The date can't be before the routine started | La date ne peut pas être antérieure au début de la routine |
| `weightDeleteTitle` | Delete this weight? | Supprimer ce poids ? |
| `weightDeleteBody` | This can't be undone. | Cette action est définitive. |
| `weightDeleteLinkedBody` | It counted as {routine} on {date}. Deleting it marks that weigh-in as not done. | Il comptait comme {routine} le {date}. Le supprimer marque cette pesée prévue comme non faite. |
| `weightDeletedReopened` | Weight deleted · {routine} is due again | Poids supprimé · {routine} est de nouveau à faire |
| `weightSinceChange` | {change} since {date} | {change} depuis le {date} |
| `weightRecordedOn` | Recorded {date} | Relevé le {date} |
| `weightTargetLine` | Target {weight} · {authority} | Objectif {weight} · {authority} |
| `weightAuthorityVet` | set by the vet | fixé par le vétérinaire |
| `weightAuthorityGuardian` | your reference | votre référence |
| `weightAuthorityBaseline` | usual weight | poids habituel |
| `weightLegendWeighIn` | Weigh-in | Pesée prévue |
| `weightLegendOther` | Other weight | Autre pesée |
| `weightRoutinesTitle` | Weigh-in routine | Routine de pesée |
| `weightNoRoutineTitle` | No weigh-in routine | Aucune routine de pesée |
| `weightNoRoutineBody` | A regular weigh-in helps spot changes early. | Une pesée régulière aide à repérer les changements tôt. |
| `weightSetUpRoutine` | Set up a weigh-in routine | Créer une routine de pesée |
| `weightNextWeighIn` | Next weigh-in {date} · {status} | Prochaine pesée {date} · {status} |
| `weightRoutinePaused` | Paused | En pause |
| `weightSourceClinic` | From the vet | Chez le vétérinaire |
| `weightSourceDevice` | From a scale | Depuis une balance |
| `weightSourceImported` | Imported | Importé |
| `weightSeeAll` | See all weights | Voir tous les poids |
| `weightNoneRecordedYet` | No weight recorded yet | Aucun poids enregistré |
| `careWeightFieldLabelUnit` | Weight ({unit}) | Poids ({unit}) |
| `careSkipWeighInTitle` | Skip this weigh-in? | Ignorer cette pesée prévue ? |
| `careSkipReasonOptional` | Reason (optional) | Raison (facultatif) |
| `careSkipReasonCouldNotWeigh` | Couldn't weigh | Pesée impossible |
| `careSkipReasonPetUnsettled` | Pet too unsettled | Animal trop agité |
| `careSkipReasonVetWillWeigh` | Vet will weigh | Le vétérinaire pèsera |
| `careSkipReasonOther` | Other | Autre |
| `careSkippedWithReason` | Skipped · {reason} | Ignorée · {reason} |

`addWeightEntry` stays in the ARB files (E2E and the legacy sheet still use it until W8); new UI uses `weightRecordAction`. `careWeightFieldLabel` is removed in W8 once unused.

---

## 8. Test specification

Each ID is a test. Name the test with its ID.

### 8.1 Server — W1 (units, dates, shared service, profile)

| ID | Case | Expect |
|---|---|---|
| U-1 | `POST` `{ weight: 10, unit: 'lb' }` | 201; stored and returned `weight ≈ 4.5359237`, `unit: 'kg'` |
| U-2 | `POST` `unit: 'st'` | 400 `unit must be kg or lb`; no row |
| U-3 | `POST` date tomorrow (pet calendar) | 400 `date_in_future`; no row |
| U-4 | `PUT` with `unit: 'lb'` | stored in kg |
| U-5 | `complete-weight` with `unit: 'lb'` | weight stored in kg; occurrence completed |
| U-6 | `PATCH /api/auth/me { weight_unit: 'lb' }`, then `GET /me` | `weight_unit: 'lb'`; `'st'` → 400 |
| U-7 | Fault injected in `refreshPetWeightCache` during `POST` (and during `complete-weight`) | 500 (`publicError`), no weight row (rollback). ARCH E's existing fault-injection tests stay green unchanged; add the `POST` case only if missing |
| U-8 | Audit insert fails after commit | response 201 unchanged; `console.warn` called once (ARCH E behaviour, now through the service) |
| U-9 | Migration up/down/up on fixture rows (§5.2) | conversions, NOT NULLs and CHECKs as specified; guard raises on `stone` |
| U-10 | `complete-weight` replay with the same payload | 200, same weight (existing behaviour kept); different payload → 409 |
| U-11 | Concurrent identical `complete-weight` (real PG) | exactly one `weight_entries` row: ARCH E's `weightCompletionConcurrency.integration.test.js`, kept green unchanged |
| P-1 | `PUT /api/pets/:id` with a changed `weight` while a weigh-in is due | 200; one new standalone weight (kg, `health_occurrence_id` null); weigh-in still pending (D-WM-005) |
| P-2 | `PUT` / `POST /api/pets` with `weight` `0`, `-1` or `"abc"` | 400 `invalid_weight`; pet unchanged; no weight row (hardening F-13) |
| P-3 | `PUT` without `weight` | no weight row; `pets.weight` still equals the latest entry |
| P-4 | `POST /api/pets` with `weight: 4.2` | pet created; first weight recorded through the service |

### 8.2 Server — W2 (integrity)

| ID | Case | Expect |
|---|---|---|
| L-1 | complete-weight → undo with token | weight deleted; occurrence `pending`; `pets.weight` refreshed; complete again with another value → 201 |
| L-2 | Legacy completed event without `payload.weight` (insert via SQL in the test) → undo | weight kept, `health_occurrence_id` null; occurrence `pending` |
| L-3 | `PUT` linked weight with a new past date | `completed_on` = new date, `completion_timing` recomputed, `completion_date_changed` event, `undo_token` in response |
| L-4 | Undo of L-3 | both dates back to the original |
| L-5 | `PUT` linked weight date in the future / before start | 400 with the command's code; nothing changed |
| L-6 | `PATCH` occurrence `completed_on` (D-CSM-034 route) on a weigh-in | weight date follows; undo restores both |
| L-7 | `PUT` linked weight, value only | no care event; occurrence unchanged |
| L-8 | Skip weigh-in with `reason_code: 'could_not_weigh'`, note | 200; ledger has code and note; detail `skip_reason` returns both |
| L-9 | Skip weigh-in with `reason_code: 'refused'` | 400 `invalid_skip_reason`; occurrence still pending |
| L-10 | Skip a medication item with any `reason_code` | unchanged behaviour (200) |
| L-11 | Occurrence detail of a completed weigh-in | `linked_weight` has `value, unit, id, date, measurement_source` |
| L-12 | `DELETE` linked weight | `reopened_occurrence` set; standalone delete → `null` |

### 8.3 Server — W3 (counting)

Rule table (`server/test/care/observations/weightFulfilment.test.js`), monthly routine, weigh-in scheduled `2026-10-10` (`nominalIntervalDays` = 31 days from 10 Oct to 10 Nov, so half = 15 and the window starts `2026-09-25`), today `2026-10-12` unless stated:

| ID | Date | Other state | Eligible |
|---|---|---|---|
| F-1 | 2026-10-12 | — | yes |
| F-2 | 2026-09-25 | — | yes (window start 2026-09-25) |
| F-3 | 2026-09-24 | — | no |
| F-4 | 2026-10-13 | — | no (future) |
| F-5 | 2026-10-05 | latest `completed_on` 2026-10-06 | no |
| F-6 | 2026-10-05 | routine paused | no |
| F-7 | 2026-10-05 | routine closed | no |
| F-8 | 2026-10-05 | family `dental` | no |
| F-9 | 2026-10-10 | one-off item (interval 0), scheduled 2026-10-10 | yes; 2026-10-09 → no |
| F-10 | 2026-10-05 | `start_date` 2026-10-06 | no |

Endpoints:

| ID | Case | Expect |
|---|---|---|
| F-11 | Candidates: one routine due | one candidate, `default_occurrence_id` set |
| F-12 | Candidates: two routines eligible | two candidates, `default_occurrence_id: null` |
| F-13 | Candidates: fixed schedule with two stacked pending weigh-ins | only the earlier one |
| F-14 | Candidates for another user's pet without access | 403 |
| F-15 | `POST` with eligible `fulfils_occurrence_id` | 201; weight linked; occurrence completed on the weight's date; ledger `payload.weight = { id, created: true }`; `fulfilment.undo_token` present |
| F-16 | `POST` with ineligible occurrence | 409 `fulfilment_not_eligible`; no weight row |
| F-17 | `POST` with fulfil by a user with `WEIGHT_EDIT` but no care manage right | 403; no row |
| F-18 | `POST /:id/fulfil` on a standalone weight | 200; linked; `payload.weight.created: false`; undo → weight kept and unlinked, occurrence pending |
| F-19 | `POST /:id/fulfil` on a linked weight | 409 `already_linked` |
| F-20 | Two concurrent `POST` fulfilling the same occurrence (real PG) | one 201, one 409; one linked row |
| F-21 | `GET /` list | linked rows have `fulfils` with routine name; others `null` |
| F-22 | `GET /overview` | shape §5.6; closed routine absent; paused present with `status: 'paused'` |
| F-23 | Fulfil on create and `POST /:id/fulfil` | weight establishment evaluation runs in-transaction (same as complete-weight); progression advances |
| F-24 | `GET /:id/history` after completed weigh-in | row includes `linked_weight` with value/date |

### 8.4 Flutter

| ID | Phase | Test |
|---|---|---|
| FW-1 | W5 | `weight_unit.dart`: conversions round-trip (22.0 lb → kg → 22.0 lb at one decimal); `formatWeight` |
| FW-2 | W5 | `WeightEntryModel.fromJson` parses `health_occurrence_id`, `measurement_source`, `fulfils`; converts a `lb` row |
| FW-3 | W5 | `AuthUser` parses `weight_unit`; default `kg` |
| FW-4 | W5 | Profile tile and PDF read `weightEntriesNotifierProvider`; after `addEntry`, the tile shows the new latest (G7 regression) |
| FW-5 | W5 | Pet edit form shows read-only weight + "Record weight"; update payload has no `weight` (Flutter only; the server side is P-1…P-4 in W1) |
| FW-6 | W6 | Hub: summary, chart markers (filled vs outlined by `fulfils`), routines card (0 / 1 / 2 routines), history chips |
| FW-7 | W6 | Sheet: 0 candidates → no switch; 1 → switch on; 2 → radio, Save disabled until chosen |
| FW-8 | W6 | Sheet: date change re-fetches candidates |
| FW-9 | W6 | Sheet: 409 `fulfilment_not_eligible` keeps the sheet open with the message |
| FW-10 | W6 | Delete linked shows the linked copy; standalone shows the plain copy |
| FW-11 | W6 | Undo from the snackbar calls schedule undo with the token and both sync hooks |
| FW-12 | W6 | Unit switch calls `setWeightUnitPreferenceProvider` and the screen re-renders in lb |
| FW-18 | W6 | Sheet: Save disabled while the weigh-in check loads; enabled once it answers; on error, the note and Retry show and Save records a standalone weight |
| FW-13 | W8 | Occurrence screen label "Weight (lb)" when the preference is lb; request sends `unit: 'lb'` |
| FW-14 | W8 | Skip on a weigh-in opens the reason sheet; sends `reason_code`; other families skip directly |
| FW-15 | W8 | Skipped weigh-in shows the reason; completed shows the weight in the user unit + "See all weights" |
| FW-16 | W8 | A command on a weigh-in routine calls `petCareSyncProvider.weightChanged` |
| FW-17 | W9 | Care item view of a weigh-in routine renders the weight section; a medication item doesn't |
| FW-19 | W9 | Care item history dialog shows weight for completed weigh-in rows |
| FW-20 | W9 | Hub "Set up weigh-in routine" opens care add with `family=weight_monitoring` preselected |

Semantics contracts: any `Semantics(identifier: …)` used by a page object gets a contract widget test in the mirrored path (testing.mdc §Semantics contract).

### 8.5 BDD and Playwright

Gherkin in `flutter_app/test/bdd/features/weight_tracking.feature`; Playwright titles must equal the `Scenario:` lines exactly. Seed with API helpers and the test clock header `x-care-as-of` where dates matter (see `server/lib/care/occurrence/careAsOf.js`).

| Phase | Change | Scenario (exact title) | Spec |
|---|---|---|---|
| W4 | Keep unchanged | `Editing pet weight from profile creates a weight entry for today` and its API test still pass after A: the server behaviour is compatible (§5.7) | — |
| W4 | New @P1 | `A weight recorded with a weigh-in choice completes that weigh-in` (API-level: routine due today, `POST` with `fulfils_occurrence_id`, occurrence completed) | `weight.tracking.spec.ts` |
| W4 | New @P1 | `Undoing a weigh-in removes the weight it created` (API-level) | `weight.tracking.spec.ts` |
| W7 | New @P0 | `Recording a weight that counts as the due weigh-in` | `weight.hub.spec.ts` (new) |
| W7 | New @P1 | `Recording a weight without counting it as a weigh-in` | `weight.hub.spec.ts` |
| W7 | New @P1 | `Choosing which weigh-in a weight counts as` | `weight.hub.spec.ts` |
| W7 | New @P1 | `Undoing a weight that counted as a weigh-in` | `weight.hub.spec.ts` |
| W7 | New @P1 | `Deleting a weight that counted as a weigh-in asks for confirmation` | `weight.hub.spec.ts` |
| W7 | New @P1 | `Weight unit preference follows the user` | `weight.hub.spec.ts` |
| W7 | New @P2 | `Weight screen suggests a weigh-in routine when there is none` | `weight.hub.spec.ts` |
| W7 | Update | `Editing a weight entry` becomes UI-driven (tap row → sheet) | `weight.tracking.spec.ts` |
| W7 | **Replace** the P2 `Editing pet weight from profile creates a weight entry for today` (the edit form no longer allows it) | `Pet profile weight is read-only and links to the weight screen` (@P2, UI) | `weight.hub.spec.ts` |
| W7 | New @P2 (keeps the old API test) | `Profile updates from older apps still record the weight` — the existing API-level test (`editing pet weight via API creates a weight entry for today with no notes`) is re-titled to this scenario | `weight.tracking.spec.ts` |
| W10 | New @P1 | `Skipping a weigh-in with a reason` | `weight.care.spec.ts` (new) |
| W10 | New @P1 | `Completing a weigh-in in pounds` | `weight.care.spec.ts` |
| W10 | New @P2 | `Care item view shows the weight section` | `weight.care.spec.ts` |

New spec files: add them to the shard manifest only by **appending** (`e2e/scripts/shard-files.mjs` rules, parallel-programmes §5.6) and run `node e2e/scripts/check_bdd_coverage.js`. Update `e2e/playwright/pages/weight-tracking.page.ts` for the new labels (keep the old regexes as alternatives until W8 removes the legacy sheet).

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| ARCH G lands while A is in flight | A is server-only; develop in parallel; **landings** to `main` take turns (§5.1) |
| PEOPLE client-integration overlaps B/C paths | B/C gates: client-integration not `in_progress` (§10.2, §10.3) |
| ARCH G vs WEIGHT C on legacy weigh-in widgets | G3 skips `weight_occurrence_care_actions`; WEIGHT C W8 removes it (#1531 note in W0) |
| A weight counts for the wrong weigh-in | Server-only rule (D-WM-004) with a table test; nothing preselected when two match; Undo |
| A fast save skips the default "Counts as" | Save waits for the weigh-in check (D-WM-003, FW-18) |
| Migration finds unknown units | Guard raises; halt (§5.2) |
| Installed clients still send `weight` on pet `PUT` | Kept working (deprecated) through the shared service (§5.7); only invalid values are rejected |
| Users between landings B and C see "Weight (kg)" on the occurrence screen while their preference is lb | Accepted for one landing interval; the label is still correct (kg) |
| Import gate: `care_item` can't reach `weight_tracking` | Core contracts + composition (§6.1) |
| Files grow past 500 lines (`occurrence_blocks.dart` is 352, `pet_form_screen.dart` 441) | Put the skip-reason sheet and the weight field in new files under `care_item/presentation/occurrence/`; the read-only weight row in a new `pet_form` widget file |
| The programme spans several 48 h windows because of the gates | Each child gets its own window under the roadmap grant; renewals at child boundaries (§11) |

---

## 10. Phases, children and gates

| Step | plan_id | Branch / base | Phases | Gate |
|---|---|---|---|---|
| W0 — docs and slots | roadmap `weight-monitoring-unify-9b2e` (phase `W0`) | `cursor/weight-unify-w0-docs-9b2e` → **PR to `main`** | W0 | §10.0 |
| A — server | `weight-unify-server-9b2e` | integration `cursor/weight-unify-server-integration-9b2e` | W1–W4 | §10.1 |
| B — weight screen | `weight-unify-hub-9b2e` | integration `cursor/weight-unify-hub-integration-9b2e` | W5–W7 | §10.2 |
| C — care side | `weight-unify-care-9b2e` | integration `cursor/weight-unify-care-integration-9b2e` | W8–W10 | §10.3 |

**How to check "in progress" for another programme:** read its child snapshot on `origin/main` (`status` of the phase, `autonomy`, `approved_until`), its control issue (open, `busy` label, last session comment), and open PRs whose base is its integration branch or `main`. A phase is in progress when its status is `in_progress`/`pr_open`, or an open PR touches its paths. When unsure, treat it as in progress and halt with `**Needs you:**`.

### 10.0 W0 — canonical spec, programme slots, plan on `main` (roadmap phase)

**Gate:** roadmap approved (§11). No other programme's `main` PR is open (parallel-programmes §5.1); a docs-only PR still waits its turn.

**Scope (docs only; `exit_checklist: governance`):**

1. Create `docs/domains/weight_tracking/features/weight-monitoring-model.md`: decisions §3, model §5.1, rules D-WM-004/006/007/009, copy §7.
2. Rewrite `docs/domains/weight_tracking/README.md`, `features/specs.md`, `features/journeys.md` to point at it and describe the weigh-in link.
3. Amend `docs/domains/pet_care/features/care-progression.md` (§Observations: standalone weights may count through explicit fulfilment; undo/date rules) and `care-item-evolution.md` (Weight row, Completing care → Weight monitoring, Measurement block: unit preference, skip reasons).
4. Update `docs/agent-efficiency/parallel-programmes.md`:
   - §1: a WEIGHT row (plan, control issue, branches, scope, state).
   - §3 Area ownership: WEIGHT owns `server/routes/weightEntries/**`, `server/lib/care/observations/**`, `flutter_app/lib/features/weight_tracking/**`; and, **for the duration of its own children only**, `server/lib/care/occurrence/commands/undo.js` + `completionDate.js` and the skip/detail routes (A), `pet_profile` weight files + `pet_providers.dart` (B), the legacy weight path in `health_tracking/presentation/widgets/**` + the occurrence screen (C).
   - §4 Landing order (binding): **W0 → WEIGHT A** (may develop alongside ARCH G; `main` landings in queue) **→ ARCH G on `main` → WEIGHT B → WEIGHT C → PEOPLE `people-client-integration-7f3b`**. PEOPLE server is already on `main`. PEOPLE client-core may run in parallel anytime.
   - Refresh the stale programme states while there: CARE complete (#1504), ARCH E phases 1–4 landed (#1503).
5. Post a short note on PEOPLE [#1460](https://github.com/KanopeeKa/AgathaCheck/issues/1460), ARCH [#1446](https://github.com/KanopeeKa/AgathaCheck/issues/1446), and ARCH G control issue **#1531**: WEIGHT areas, slots, and G3 handoff (WEIGHT C owns legacy weigh-in widget removal).
6. Land this plan's files (`.agents/plans/weight-monitoring-unify-9b2e.*`, `weight-unify-*-9b2e.*`) on `main` in the same PR. From then on, every branch is created from `origin/main`.

**Exit:** `bash scripts/validate_docs.sh` reports no new errors (2 existed before WEIGHT at `4f3325d`); the four snapshots validate; PR merged on `main`.

### 10.1 Child A — `weight-unify-server-9b2e`

**Entry gate (all must hold before W1 code):**

1. W0 is merged on `main` (WEIGHT's row, areas and slots are on `main`, not only in a comment).
2. **PEOPLE server** has landed on `main` (#1523). Before W1, re-read on current `main`: `server/routes/auth/profileRouter.js`, `server/routes/pets/coreRouter.js`, `server/routes/healthEntries/occurrencePatchRouter.js`, `server/routes/healthEntries/shared.js`, `server/routes/healthEntries/crudRouter.js`.
3. No other programme's open PR touches WEIGHT A `allowed_paths` (ARCH G is Flutter-only — does not block A development).
4. At landing: no other programme's `main` PR is open (queue behind ARCH G landings is normal babysit wait, not owner approval).

| Phase | Scope | exit_checklist |
|---|---|---|
| **W1** | Migration (§5.2); `weightUnits.js`, repository and service (§5.1) built on ARCH E's transaction code; routes folder `server/routes/weightEntries/` replacing `weightEntries.js` (update the import in `server/bin/server.js`); units and date rule (§5.3) on POST/PUT/complete-weight; `complete-weight` wraps the service; user `weight_unit` (§5.4); **pet create/update through the service with validation (§5.7)**; seeds still pass (`server/test/seed.test.js`, `server/test/db/seeds/**`); api-reference. Tests U-1…U-11, P-1…P-4 | `single-backend-route` |
| **W2** | Integrity (§5.5, §5.5b): observation hooks, ledger payload, undo deletes/unlinks, date sync both ways (command + PUT), delete response, skip reason validation, occurrence detail; architecture boundary test; openapi + api-reference. Tests L-1…L-12 | `single-backend-route` |
| **W3** | Counting (§5.6): rule, loader, candidates/overview endpoints, history `linked_weight`, `POST` with `fulfils_occurrence_id`, `POST /:id/fulfil`, list `fulfils`; auth matrix (S1/S2); api-reference. Tests F-1…F-24 | `single-backend-route` |
| **W4** | E2E/BDD for A (§8.5 W4 rows): API-level scenarios in `weight_tracking.feature` / `weight.tracking.spec.ts`; run the weight shard and the care shards; BDD gate | `bdd-journey` |

**Exit:** all U/P/L/F tests green (Jest + real PG); ARCH E's weight tests and `transactionOwnership.test.js` green; migration applied on a fresh DB and on the UAT seed; `./scripts/pre-push.sh` green; pre-UAT green on the merge SHA; landing broadcast posted.

### 10.2 Child B — `weight-unify-hub-9b2e`

**Entry gate:** child A landed with pre-UAT green. **ARCH G child** (`active-codebase-batch-g-client-authority-e41f`) is **merged on `main`** with pre-UAT green. **`people-client-integration-7f3b` is not in progress** (no open PR / `in_progress` phase on i1/i2 paths per §10). Merge `main` into the hub integration branch; re-read `pet_profile` providers and health-store refresh APIs ARCH G introduced.

| Phase | Scope | exit_checklist |
|---|---|---|
| **W5** | Flutter foundations (§6.1, §6.2, §6.7): core weight unit + preference + `PetCareSync` + composition overrides; `AuthUser.weightUnit`; entity/model fields; one list provider (delete `weightEntriesProvider`, `latestWeightProvider`, `WeightUnitNotifier`; keep the deprecated shim); profile tile + PDF; pet form read-only on edit (the app stops sending `weight`); replace `pet_weight_invalidation.dart` callers and delete it; feature barrel; `--update-baseline`. Tests FW-1…FW-5. **Flutter only** (the server side landed in W1) | `flutter-screen-split` |
| **W6** | Weight screen + Record weight sheet (with the Save gating) + delete confirmation (§6.3–§6.5), copy (§7) EN+FR; move the screen into `weight_tracking`; data for overview/candidates/fulfil/edit/undo; post the FR column on the child B control issue for owner review. Tests FW-6…FW-12, FW-18 | `flutter-screen-split` |
| **W7** | E2E/BDD (§8.5 W7 rows): `weight.hub.spec.ts`, profile scenario replacement, page object, feature file, semantics contracts | `bdd-journey` |

**Exit:** FW-1…FW-12 and FW-18 green; `flutter analyze` clean; import gate green with a lower baseline; BDD gate green; weight + pet-profile shards green; pre-UAT green on the merge SHA.

### 10.3 Child C — `weight-unify-care-9b2e`

**Entry gate:** child B landed with pre-UAT green. **`people-client-integration-7f3b` is not in progress** on overlapping paths. Merge `main`; re-read §6.6 paths (`care_item/presentation/detail/**`, `health_tracking/presentation/widgets/**`). ARCH G3 must **not** migrate `weight_occurrence_care_actions` — WEIGHT C W8 owns removal (coordination note on ARCH G #1531 in W0).

| Phase | Scope | exit_checklist |
|---|---|---|
| **W8** | Occurrence screen unit, skip-with-reason sheet, completed/skipped views, `weightChanged` after weigh-in commands, legacy path redirect and deletions (§6.6). Tests FW-13…FW-16 | `flutter-screen-split` |
| **W9** | Observation slot + history weight rows + care-add `family` preselect (§6.6, D-WM-013). Tests FW-17, FW-19, FW-20 | `flutter-screen-split` |
| **W10** | E2E/BDD (§8.5 W10 rows), remove legacy regexes from the page object, close-out: docs status `active`, `complete-plan` on the roadmap, landing broadcast | `bdd-journey` |

**Exit:** FW-13…FW-17 green; legacy weight completion code gone; BDD gate green; care + weight shards green; pre-UAT green.

### 10.4 Landing broadcast (after each child)

```markdown
**Landed:** WEIGHT <A|B|C> @ <merge sha> (PR #<n>)
**Areas:** <§3 area names from parallel-programmes>
**Migrations:** <NNN_weight_monitoring_unify | none>
**Action for other programmes:** rebase at next phase start; run shards <n,…> if you touch weight entries, the occurrence screen or the pet form.
```

Post it on every open programme control issue (PEOPLE #1460, ARCH #1446, TEST #1449 if still open) and on the WEIGHT roadmap issue.

---

## 11. Bootstrap and approval (same pattern as `people-domain-refactor-7f3b`)

**Draft placeholders in the snapshots:** `control_issue: 999999`, `autonomy: halted`, and `approved_at` / `approved_until` recording the owner's product sign-off (2026-10-04), not an autonomy grant. `approved_by` says "DRAFT". All are replaced below. The validator only accepts `tests`, `docs`, `file-split`, `governance-allowlist` and `spawn-integration` as exception codes (not `backend-route`, despite the schema doc), so server paths are listed explicitly in `allowed_paths`.

### 11.1 Roadmap control issue and grant

```bash
node scripts/execute_plan_runtime.js init-control-issue weight-monitoring-unify-9b2e
# run the rendered `gh issue create`. The autonomous-approved label alone starts nothing:
# the gate refuses while the snapshot says autonomy "halted".
```

The owner approves with **one comment** on the roadmap issue. It is the standing grant for W0 and the three children, and restates what is pre-approved:

```text
approve-autonomous weight-monitoring-unify-9b2e
Pre-approved: migration *_weight_monitoring_unify (lb→kg conversion of existing rows, weight_entries.unit = 'kg'
and date NOT NULL, users.weight_unit); new validation (future-dated weights, non-positive pet weights, weigh-in
skip reasons); pet PUT weight kept as deprecated; WEIGHT slots in parallel-programmes as proposed in W0
(or: <owner's reordering>). Renewals at child boundaries.
```

The orchestrator then:

1. Stamps the roadmap snapshot: `approved_at`, `approved_until` (+48 h), `approved_by` (quote the comment and issue number), `control_issue`, `autonomy: active`; `--fix-hash`; validate.
2. Runs **W0** (§10.0) as the roadmap's own phase and gets its docs PR merged on `main`.
3. Bootstraps the next child whose entry gate is met:
   ```bash
   CHILD=$(node scripts/execute_plan_runtime.js roadmap-next-child weight-monitoring-unify-9b2e)
   # verify the child's entry gate on origin/main (§10.1–10.3); if not met → halt human_pause with next_action naming the missing landing
   git fetch origin main && git push origin origin/main:refs/heads/<child integration branch>
   node scripts/execute_plan_runtime.js init-control-issue "$CHILD"          # run the rendered gh command; labels execute-plan, plan:$CHILD
   # child snapshot: control_issue, approved_at, approved_until (+48h), approved_by ("standing grant — roadmap weight-monitoring-unify-9b2e #<n>"), autonomy active
   node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/$CHILD.snapshot.json
   node scripts/validate_execute_plan_snapshot.js .agents/plans/$CHILD.snapshot.json
   node scripts/execute_plan_runtime.js roadmap-set-child weight-monitoring-unify-9b2e --child "$CHILD" --status in_progress --write
   ```
   Then runs `/execute-plan $CHILD`. The child's own gate checks `plan:$CHILD` on the child's issue, so the roadmap issue and the child issues never share a `plan:` label.
4. Closes each child after its `main` merge is pre-UAT green: `complete-plan <child> --write`, then `roadmap-set-child … --status merged --pr-url … --merge-commit … --write`, and posts the landing broadcast (§10.4).

**Waiting and autonomy.** A child whose **programme gate** isn't met (e.g. ARCH G not on `main` before B): poll/subscribe on the roadmap control issue; continue other in-plan work only if allowed; do **not** ask the owner for permission. **Standing grant** covers all phases and children. When `approved_until` nears expiry, the orchestrator **re-stamps** `approved_at` / `approved_until` (+48h) on the **roadmap and active child** snapshots while `autonomous-approved` remains and scope stays within this plan — no new owner comment required.

**Sanity check:** `proceed-high-risk` — one migration (additive plus a unit conversion), care-engine edits (undo, completion date), shared files with PEOPLE server and ARCH G. Mitigated by the gates recorded on `main` in W0 and by per-child landings.

---

## 12. Out of scope

- Generalising "category owns its screens" to other care families (owner R8). Only the `numeric_weight` observation slot is added.
- Body condition score and other measurements (planned elsewhere; the slot makes them possible later).
- Automatic matching (Streaks-style) and device/import ingestion.
- Preselecting care families from surfaces other than the weight hub empty-state / "Set up weigh-in routine" entry (FW-20 scope only).
- Unlinking a weight from a weigh-in without deleting it, other than through Undo.
- Changes to Care Intelligence thresholds or establishment policy (they already read the linked weights; counting standalone weights through fulfilment feeds them).
- A user settings screen for the unit (the switch lives on the weight screen).

---

## 13. Sources

Analysis in the session of 2026-10-04 (current-state audit, comparison with Apple Health, Streaks, Medisafe, 11pets/PawPrints/DogLog, FHIR `Observation.basedOn`). Code references: §4. Related canonical specs: [care-item-evolution.md](../../docs/domains/pet_care/features/care-item-evolution.md), [care-progression.md](../../docs/domains/pet_care/features/care-progression.md), [care-schedule-management.md](../../docs/domains/pet_care/features/care-schedule-management.md), [calendar-dates.md](../../docs/architecture/calendar-dates.md), [parallel-programmes.md](../../docs/agent-efficiency/parallel-programmes.md).

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: W0
last_completed_phase: null
halt_reason: null
next_action: "bootstrap and gate child plan weight-unify-server-9b2e"
artifact_ref:
  branch: cursor/weight-unify-w0-docs-9b2e
  plan_path: .agents/plans/weight-monitoring-unify-9b2e.md
  plan_commit: 8cdc32ca88e98a03172578698a47dbde392cae68
  snapshot_path: .agents/plans/weight-monitoring-unify-9b2e.snapshot.json
  snapshot_commit: 8cdc32ca88e98a03172578698a47dbde392cae68
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1552"]
merge_commits: {}
debt_issue_refs: []
```
