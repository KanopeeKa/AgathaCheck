---
title: Care status model — delivery plan
owner: Product / Agent
audience: both
domain: pet_care
status: proposed
status_since: 2026-11-04
folds_into: docs/domains/pet_care/features/care-item-evolution.md
last_updated: 2026-11-04
related_prs: []
---

# Care status model — delivery plan

**Status:** Proposed — implementation plan for [care-status-model-spec.md](./care-status-model-spec.md) (CARE-STATUS-R-001 … R-023). **No code in this PR** — plan only.

**Base branch for delivery:** `claude/funny-albattani-v6t5k3` (spec branch) → integrate → `main` after product review.

**Escalation:** §3 includes a **production data migration** (autonomous-pr-policy §Escalation — human approval before merge).

---

## 1. Current-state inventory

### 1.1 Database (as implemented today)

| Area | Location | Notes |
|------|----------|-------|
| Occurrence row | `health_occurrences` | `status`: `pending` \| `completed` \| `skipped`; `close_reason`: `user` \| `not_recorded` \| `paused` \| `system` (migration `083_care_occurrence_model.js`) |
| Care item row | `health_entries` | `status`: `active` \| `paused` \| `completed` (Finished and Archived both `completed` on wire); `completed_on`, `completed_at`, `repeat_end_date`, pause fields |
| Schedule ledger | `care_schedule_events` | Includes `not_recorded_closed`, `schedule_changed`, etc. |
| No item closed reason | — | Spec needs `Ended` vs `Stopped by you` + closed instant — **not stored today** |

### 1.2 Server — writes (outcome / close_reason / lifecycle)

| Behaviour | File(s) |
|-----------|---------|
| User skip | `server/lib/care/occurrence/commands/skip.js` → `markSkipped(..., closeReason: 'user')` |
| User complete | `server/lib/care/occurrence/commands/complete.js`, `occurrenceRepository.markCompleted` |
| Stack auto-close (3-day window) | `server/lib/care/occurrence/syncOpenOccurrences.js` → `closeStackOutsideWindow` → `closeReason: 'not_recorded'` |
| Fixed: open status **Not recorded** (computed on read, row still `pending`) | `server/lib/care/schedule/occurrenceStatus.js` when next slot started |
| Pause: close open as skipped | `server/lib/care/occurrence/commands/postpone.js` → `closeReason: 'paused'` |
| Schedule edit: not-yet-started removed / started → not_recorded | `server/lib/care/occurrence/commands/lifecycle.js` → `reconcileScheduleEdit` (`deleteOpenOccurrences`, `markSkipped` system/not_recorded) |
| Repeat end: future open → system skip | `reconcileScheduleEdit` (`closeReason: 'system'`) |
| Archive / Close care | `lifecycle.js` → `closeSeriesCommand` → `closeAllOpen(..., 'system')`, `health_entries.status = 'completed'` |
| Restore | `lifecycle.js` → `reopenSeriesCommand` |
| Record earlier doses | `server/lib/care/occurrence/commands/stack.js` → `resolveStackCommand` |
| Record Not recorded as given | `stack.js` → `recordAsGivenCommand` (requires `skipped` + `not_recorded`) |
| Next-choice skip path | `server/lib/care/occurrence/commands/nextChoice.js` |
| TZ repair | `server/lib/care/repair/tzShiftRepair.js` (treats `not_recorded` / user skip) |
| Seeds / harness | `server/db/seeds/helpers/care-commands.js` |

### 1.3 Server — reads, wire, API

| Surface | File(s) |
|---------|---------|
| Open occurrence timing + open **not_recorded** | `occurrenceStatus.js`; wired via `openOccurrenceToWire` / `careItemReadAdditions` (`server/lib/care/occurrence/occurrenceDto.js`, `server/lib/care/item/wire.js`) |
| List read hides rows pending 3-day close | `readSync.js` → `filterOpenRowsForListRead`, `wouldAutoCloseAsNotRecorded` |
| GET occurrences (open) | `server/lib/health/occurrenceListService.js` — returns `status: 'pending'` + `occurrence_status` |
| GET occurrences (past) | `occurrenceListService.js` — `occurrenceToMap` only |
| GET history | `server/routes/healthEntries/completionRouter.js` — **no `close_reason` / outcome**; `historyToMap` in `shared.js` |
| PATCH occurrence detail wire | `occurrencePatchRouter.js` — maps `close_reason === 'not_recorded'` → wire `not_recorded` |
| Neighbours / leaf | `server/lib/health/occurrenceNeighbors.js` |
| Item list/detail wire | `server/lib/care/item/entryMap.js`, `wire.js` — `status` passthrough |
| CSV export | `server/lib/health/healthEntryCsv.js`, `shared.js` |
| Close / reopen routes | `completionRouter.js` — `POST /:id/close`, `POST /:id/reopen`; auth via `userCanManageHealthEntry` (**not owner-only**) |
| Resolve stack / record | `occurrenceCommandRouter.js` |
| OpenAPI contract tests | `server/test/openapi/petCareContract.test.js`, `server/test/db/careItemContract.integration.test.js` |
| Natural “Finished” | `syncOpenOccurrences.js` → `finishIfNothingLeft` sets `status = 'completed'` |

### 1.4 Server — adjacent domains (must align with Closed / outcomes)

| Domain | File(s) | Today |
|--------|---------|-------|
| Away planning | `server/lib/care/planner/planAbsenceCare.js` | Skips `entry.status === 'paused' \|\| 'closed'` — **`closed` not written to DB yet** |
| Care period coverage | `server/lib/care/carePeriodCoverage.js`, `server/test/careContext/*` | Uses `completed` on items |
| Care Intelligence | `server/lib/suggestions/suggestionGeneration.js`, `suggestionUpsert.js` | Reads `health_entries`; no explicit “closed care” suppress — verify dedupe on missing active care |
| Weight fulfilment | `server/lib/care/observations/weightObservationService.js`, `completeWeight` tests | Blocks complete on closed series via command guards |
| Reminders / notifications | Care tick + notification builders (grep `health_entries` in `server/lib/notifications`, cron care tick `server/lib/care/occurrence/careTick.js`) | Active/paused items only in tick query |
| Permissions | `server/lib/petAccess.js` — `userCanManageHealthEntry`, `userCanManageCare`; owner checks in `server/test/petCapabilityPolicy.test.js` (`pet.lifecycle.manage`) | Close uses manage-health, not owner-only |
| Dashboard / Actions counts | Server-backed open occurrences + Flutter grouping (`care_temporal_grouping_service.dart`, agenda providers) | Overdue/open stacks inflate counts |

### 1.5 Flutter — domain & application

| Area | File(s) |
|------|---------|
| API status enum | `flutter_app/lib/features/care_item/domain/care_occurrence.dart` — open includes `notRecorded`; closed: done/skipped |
| Live status / timing | `flutter_app/lib/features/care_item/domain/occurrence_status.dart` |
| Stack rules | `stack_rule.dart`, `care_agenda.dart`, `done_decision.dart`, `leading_occurrence.dart` |
| Stack UX + Record earlier doses | `care_item_needs_attention_section.dart`, `care_completion_service.dart`, `care_stack_feedback.dart` |
| Agenda row Review / stack count | `pet_care/presentation/widgets/care_agenda/care_agenda_row_tile.dart`; `health_entry.dart` `isStack` |
| Status pills / copy | `occurrence_display.dart`, `care_item_status_pill.dart`, `care_item_occurrence_status_pill.dart`, `health_tracking/.../health_entry_status.dart`, `care_event_status_line.dart` |
| Archive / Restore / Close event | `care_item_menu.dart`, `care_item_detail_screen.dart`, `health_repository` + `health_remote_datasource.dart`, `health_entries_store.dart`, `pet_event_close_confirm_dialog.dart`, `pet_event_lifecycle.dart` |
| Finished vs active chip | `care_item_context_strip.dart` — `completed` or `isHealthEntrySeriesClosed` |
| All care lists | `all_care_list.dart`, `all_care_inactive_section.dart` (“Other care”), `manage_events_filters.dart` |
| Occurrence leaf | `features/experience/presentation/care_item/occurrence/*`, `occurrence_review_flow` (if present) |
| l10n | `app_en.arb` / `app_fr.arb` — `closeEvent*`, `reopenEventAction`, `careItemMenuArchive/Restore`, `careStatusReviewAction`, stack strings, `allCareInactiveSection` |

### 1.6 Tests & E2E (baseline)

| Layer | Paths |
|-------|-------|
| Server Jest (unit) | `server/test/healthEntries.test.js`, `server/test/careSchedule/scheduleRules.test.js`, `server/test/careItem/scheduling.test.js`, `server/test/care/*`, `server/test/careContext/*`, `server/test/careSchedule/tzShiftRepair.plan.test.js` |
| Server DB integration | `server/test/db/careOccurrences.*.integration.test.js`, `migration083.integration.test.js`, `careOccurrencesSeed.test.js` |
| Flutter unit/widget | `flutter_app/test/features/care_item/**` (incl. `stack_rule_test.dart`, `not_recorded_care_ux_test.dart`, `care_agenda_test.dart`, detail/occurrence tests) |
| BDD features | `flutter_app/test/bdd/features/care_*.feature`, `health_tracking.feature` (stack scenario), `agatha_care_journey.feature`, `away_*.feature` |
| Playwright | `e2e/playwright/tests/care.*.spec.ts`, `away.*`, `agatha-care-journey.spec.ts`, `health.tracking.spec.ts`; helpers `e2e/playwright/support/care-api.ts`, `api.ts`; pages `care-item.page.ts`, `care-agenda.page.ts` |

---

## 2. Gap analysis (CARE-STATUS-R-001 … R-023)

| ID | Exists today | Gap / change |
|----|--------------|--------------|
| R-001 | Split `status` + `close_reason` | Single stored **outcome** column (or remapped `status`); retire `close_reason` on wire; optional audit `closed_by` |
| R-002 | `occurrenceStatus.js` + Flutter mirrors | Rename wire timing to **Upcoming** (today `coming_up`); show timing **only** when outcome is Open |
| R-003 | System writes `skipped` + `system`/`paused`/`not_recorded` | System must only write **Not recorded** or delete rows — never Skipped |
| R-004 | History maps all `skipped` → “Skipped” | History/agenda must expose **Not recorded** for system outcomes |
| R-005 | Open `not_recorded` + 3-day auto-close to stored skipped/not_recorded | **Store** Not recorded when next Fixed dose is due; remove open-stack timing; remove 3-day auto-close (`closeStackOutsideWindow`) |
| R-006 | `recordAsGiven` from History | Allow Done **or** Skip on stored Not recorded while item Active/Paused; block when Closed |
| R-007 | After-it's-done overdue stays open | **Preserve**; ensure pause/close paths apply R-008 |
| R-008 | Pause uses `paused` skip; close uses system skip all open | **Started** open → Not recorded; **not started** → **delete** (not skip) on pause/close/schedule change |
| R-009 | `active` / `paused` / `completed` | Introduce **Closed** item status (or `closed` + reason — see §3) |
| R-010 | No subtitle distinction | Persist **Ended** vs **Stopped by you** |
| R-011 | Reopen, Restore, edit on completed | Read-only Closed; remove reopen/restore; reject mutating commands |
| R-012 | Skip reason flows elsewhere | **No change** if already absent on skip API |
| R-013 | — | **Migration backfill** (production) |
| R-014 | Archive in menu, not bottom danger button | **Close care** CTA on Care details (Active/Paused only) |
| R-015 | `userCanManageHealthEntry` on `/close` | **Owner-only** server + hide button for non-owners |
| R-016 | `pet_event_close_confirm_dialog` (no “Record them first”) | New copy + count + **Record them first** navigation |
| R-017 | `closeSeriesCommand` | Set Closed · Stopped by you, `closed_at`, end schedule, stop reminders |
| R-018 | Closes all open as system skipped | Apply started/not-started rules; freeze Done/Skipped/Not recorded |
| R-019 | Close works on paused (API) | Same R-018; UI on Paused |
| R-020 | Completed items still partially editable | Remove from agenda/Actions; read-only details |
| R-021 | “Other care” groups inactive | **Closed care** link + list at bottom of All care |
| R-022 | Away planner skips `closed` in pure fn only | Drop Closed care from **not-started** away plans; keep in started/past |
| R-023 | `finishIfNothingLeft` → `completed` | Map to Closed · **Ended** + R-020/21 |

---

## 3. Data model and migration design

### 3.1 Care date outcome (stored)

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A — New `outcome` column** | `open` \| `done` \| `skipped` \| `not_recorded`; keep legacy `status` during rollout | Clear spec match; easy backfill audit | Two columns until deprecation |
| **B — Remap `health_occurrences.status`** | Replace enum: `open`, `done`, `skipped`, `not_recorded` | Single column | Breaking DB enum; heavy touch on all SQL |
| **C — Keep `status`+`close_reason` internally** | Wire-only “outcome” | Smaller SQL diff | Violates R-001 spirit; keeps bug class |

**Recommendation:** **Option A** — add `outcome` (NOT NULL after backfill) with check constraint; migrate writers to set `outcome` + transitional mirror of legacy columns for one release; then drop `close_reason` and collapse `status` to `open`/closed trinary or drop `status` in follow-up migration. Add optional `closed_by` (`user` \| `system`) for audit.

**Open rows:** `outcome = 'open'`; timing remains **computed** (not stored).

**Not recorded transition (R-005):** On sync/command when next Fixed slot is due, `UPDATE outcome = 'not_recorded', closed_by = 'system'` (no longer `pending` + computed not_recorded). Remove `closeStackOutsideWindow` and `wouldAutoCloseAsNotRecorded` 3-day logic.

### 3.2 Care item Closed (stored)

| Field | Recommendation |
|-------|----------------|
| `health_entries.status` | Add value **`closed`** (keep `completed` as deprecated alias one release, or migrate in same migration) |
| `care_closed_reason` | `ended` \| `stopped_by_user` (NULL unless closed) |
| `closed_at` | `timestamptz` — instant of close/natural end (display in pet home TZ) |
| Natural end | Set `care_closed_reason = 'ended'` in `finishIfNothingLeft` |

**Recommendation:** Single migration **`084_care_status_model.js`** (number TBD at implementation): add columns + backfill + constraints; **do not** assume UAT wipe in production.

### 3.3 Backfill rules (R-013)

| Legacy | Target |
|--------|--------|
| `completed` occurrence | `done` |
| `skipped` + `user` | `skipped` |
| `skipped` + `not_recorded` | `not_recorded` |
| `skipped` + `system` or `paused`, date **started** | `not_recorded` |
| `skipped` + `system` or `paused`, date **not started** | **DELETE row** |
| `pending` | `open` |
| Item natural finish (`completed`, no user close audit) | `closed` + `ended` |
| Item user archive (`health_entry.closed` activity or heuristic: open were system-closed at close) | `closed` + `stopped_by_user` |

**Heuristic gap:** Today Finished vs Archived share `status = 'completed'`. Backfill must use **`activity_log` / audit** (`health_entry.closed`) where available; remaining rows default to **`ended`** unless `repeat_end_date` was set by `closeSeriesCommand` (yesterday truncate) → **`stopped_by_user`**. Confirm in §10.

**Idempotence:** Migration SQL keyed by occurrence id; rerunnable `UPDATE … WHERE outcome IS NULL`.

### 3.4 Rollout order

1. **Deploy migration + server read/write** (dual-write legacy + new if needed).
2. **Ship Flutter/web** reading new wire fields (`outcome`, `care_closed_reason`, `closed_at`).
3. **Remove** `/reopen`, resolve-stack, deprecated wire (`close_reason`).
4. **Fold** canonical docs when behaviour stable on integration branch.

**Reversibility:** Forward-only migration; rollback = new migration restoring prior enum (only if no new outcomes written). Treat as **irreversible** once users close care under new rules.

> **Escalation:** Production data migration — require explicit human approval before merge to `main` (autonomous-pr-policy §Escalation; database-and-migrations.md §4).

---

## 4. API contract changes

| Change | Detail |
|--------|--------|
| Occurrence wire | Expose `outcome` (`open` \| `done` \| `skipped` \| `not_recorded`); for `open`, expose computed `timing` (`upcoming` \| `due` \| `overdue`) — rename from `occurrence_status` / split fields |
| Retire | `close_reason` on API; open-row `status: pending` pattern |
| History | Include `outcome` (and optional `closed_by`) on `GET /:id/history` and past occurrences list |
| Item wire | `status: closed`; `care_closed_reason`, `closed_at`; map legacy `completed` → `closed` + reason during compat window |
| Close care | `POST /:id/close` — rewrite semantics R-017/R-018; **403/404** unless pet owner |
| Retire | `POST /:id/reopen` — return **410** or remove route after min client version |
| Retire | `POST …/resolve-stack`; keep `POST …/record` only for Not recorded → Done (extend for Skip if spec confirmed) |
| Commands on Closed item | **409** `care_item_closed` on edit, pause, resume, occurrence mutations (except read) |
| Older clients | Additive fields first; keep sending legacy `status`/`occurrence_status` mirrors one release per `api-contract.md`; document min app version in OpenAPI |

---

## 5. Flutter changes

| Area | Action |
|------|--------|
| Domain | Replace open `notRecorded` timing with stored outcome model; `CareOccurrenceStatus` → outcome + optional timing |
| Delete | `stack_rule.dart` stack/Review paths, `resolveStack` in `care_completion_service.dart`, stack bulk UI, `care_stack_feedback.dart`, Record earlier doses sheets |
| Agenda | Remove stack row aggregation and **Review** trailing action; Not recorded rows leave Needs attention (history only) per R-005 |
| Care details | Bottom **Close care** danger button; remove Archive/Restore from menu; read-only when Closed |
| Dialog | Extend/replace `pet_event_close_confirm_dialog` — R-016 copy, **Record them first** |
| All care | Replace/refactor **Other care** → active list unchanged; add **Closed care** section + list screen |
| Chips | `care_item_context_strip` — **Closed** chip + subtitle (Ended / Stopped by you) |
| l10n | New `closeCare*` strings; retire/repurpose `closeEvent*`, Archive/Restore; align Upcoming vs Coming up if product wants EN copy change |
| Providers | `health_entries_store` — remove `reopenEvent`; gate edit/delete providers on Closed |
| Permissions | Hide Close care unless current user is pet owner (match server) |

---

## 6. Canonical doc impact

When the spec folds into canonical docs (after delivery, not with this plan PR):

| Source | Action |
|--------|--------|
| [care-item-evolution.md](../features/care-item-evolution.md) | Mark **Superseded**: D-CIE-002 (stored status wording), D-CIE-018 (lifecycle), D-CIE-024 (Not recorded as open), D-CIE-034, CARE-ITEM-R-008 (stack), CARE-ITEM-R-002 / D-CIH-013 (Finished/Archived chip), Restore/reopen flows, D-CIE-026 Review row |
| [care-schedule-management.md](../features/care-schedule-management.md) | Mark **Superseded**: D-CSM-023 stack/3-day window as specified; remove `resolveStack` / `recordAsGiven` table rows; amend INV/sync diagram for stored Not recorded |
| [care-status-model-spec.md](./care-status-model-spec.md) | Fold requirements + decisions into care-item-evolution; **delete** change doc per documentation standards |

**Timing:** Fold in the **final behaviour PR** to `main` (or integration), same PR as last E2E updates.

---

## 7. Test plan

### 7.1 Inventory — tests to update or delete

| Behaviour | Server | Flutter | BDD | Playwright |
|-----------|--------|---------|-----|------------|
| Stack / Review / Record earlier | `careOccurrences.fixed.integration.test.js`, `staleOpen` (resolve-stack), property tests | `stack_rule_test.dart`, `care_agenda_test.dart`, `not_recorded_care_ux_test.dart`, `needs_attention_section_test.dart`, `done_decision_test.dart` | `care_agenda.feature` (stack scenario), `health_tracking.feature` (multi-dose stack) | `care.agenda.spec.ts`, `care.schedules.spec.ts` (stack / history record) |
| 3-day not_recorded auto-close | `syncOpenOccurrences` via integration tests, `readSync` | Filter tests if any | — | `care.schedules` “older than three days…” |
| Archive / Restore / reopen | `healthEntries.test.js` close/reopen | `care_item_detail_screen_test.dart`, menu tests | — | `health.tracking.spec.ts` (if lifecycle) |
| History Skipped for system | — | `care_item_dates_section_test.dart` | — | — |
| Other care inactive | — | `all_care_*` widget tests | — | `care.agenda.spec.ts` |

### 7.2 Traceability (R-001 … R-023)

| ID | Test coverage (planned) | New/updated |
|----|-------------------------|-------------|
| R-001 | `test: server/test/db/migration084.integration.test.js#outcome column`; `test: flutter_app/test/features/care_item/data/care_item_wire_test.dart#outcome` | New |
| R-002 | `test: server/test/careSchedule/scheduleRules.test.js#timing`; `test: flutter_app/test/features/care_item/domain/occurrence_display_test.dart#upcoming` | Updated |
| R-003 | `test: server/test/db/careOccurrences.fixed.integration.test.js#system never skips` | Updated |
| R-004 | `test: server/test/healthEntries.test.js#history outcome`; `bdd: care_date_screen` History copy | Updated |
| R-005 | `test: server/test/db/careOccurrences.fixed.integration.test.js#NR at next dose`; delete 3-day tests | Updated |
| R-006 | `test: server/test/db/careOccurrences.fixed.integration.test.js#record NR done/skip`; `bdd: care_schedules` | Updated |
| R-007 | `test: server/test/db/careOccurrences.afterDone.integration.test.js#overdue stays open` | Updated |
| R-008 | `test: server/test/db/careOccurrences.*#pause/close removes future`; `test: careSchedule/postpone` | Updated |
| R-009 | `test: server/test/db/migration084.integration.test.js#item closed status` | New |
| R-010 | `test: flutter_app/test/features/care_item/presentation/detail/care_item_context_strip_test.dart#subtitle` | Updated |
| R-011 | `test: server/test/healthEntries.test.js#409 closed`; `test: care_item_detail_screen_test.dart#read-only` | New |
| R-012 | — (assert no skip reason field) | — |
| R-013 | `test: server/test/db/migration084.integration.test.js#backfill each rule`; idempotence case | New |
| R-014 | `test: care_item_detail_screen_test.dart#close button`; `bdd: care_item_lifecycle.feature` | New |
| R-015 | `test: server/test/healthEntries.test.js#close owner-only`; `bdd: sharing + close care` | New |
| R-016 | `test: care_item_detail_screen_test.dart#dialog record first`; `bdd: care_close.feature` | New |
| R-017 | `test: server/test/db/careOccurrences.*#close sets stopped_by_user` | Updated |
| R-018 | `test: server/test/db/careOccurrences.*#close dates matrix` (untimed today, multi-dose, TZ) | New |
| R-019 | `bdd: care_close.feature#paused close` | New |
| R-020 | `test: care_agenda_test.dart#closed excluded`; dashboard provider tests | Updated |
| R-021 | `bdd: care_close.feature#closed list`; widget test for All care footer | New |
| R-022 | `test: server/test/care/planner/planAbsenceCare.test.js#closed dropped`; `bdd: away_care` | Updated |
| R-023 | `test: syncOpenOccurrences finish → ended`; `bdd: care_close.feature#natural end` | New |

*(Add `@bdd` headers on Playwright tests when scenarios are added; run `node e2e/scripts/check_bdd_coverage.js` after.)*

### 7.3 Server (Jest) — detailed cases

- Outcome transitions on complete/skip/sync; Fixed **next dose** triggers stored Not recorded (not open status).
- Recording Not recorded → Done/Skip; Closed item rejected.
- Close care: owner vs carer; started vs not-started dates; untimed today; multi-dose day; `X-Care-As-Of` TZ cases.
- History lists outcome; no Skipped for system rows.
- Migration: one assertion per R-013 row; second run idempotent.
- Remove/adapt resolve-stack and 3-day window tests.

### 7.4 Flutter (unit/widget)

- Outcome + timing display; Closed chip subtitles.
- Close care visibility (owner, Active/Paused, hidden when Closed).
- Dialog variants; Record them first navigation.
- Read-only menus and date actions on Closed.
- Closed care list link/count.
- Deleted stack/Review widgets — remove or rewrite tests.

### 7.5 E2E (Playwright + BDD)

**New journeys (minimum):**

1. Close Active care with overdue + future dates → History shows Not recorded; agenda cleared; **Closed care** list.
2. **Record them first** from dialog → complete dates → then close.
3. Close **Paused** care.
4. **Non-owner** (shared carer) — no Close care button; API 403 if forced.
5. Open Closed care from list — read-only (no Edit).
6. Natural **Closed · Ended** (one-off done; recurring past end date).
7. Fixed dose → Not recorded → record from History later.
8. Away plan not started drops Closed care; started plan unchanged.
9. **care.a11y** — Close care button + dialog axe clean.

**Suggested new files:** `flutter_app/test/bdd/features/care_close.feature`, `e2e/playwright/tests/care.close.spec.ts` (and `@bdd` tags).

**BDD coverage (baseline on spec branch, 2026-11-04):**

| Metric | Before (this plan) | After (target when delivered) |
|--------|-------------------|-------------------------------|
| Gated scenarios | 184 | ~192 (+8 new care_close scenarios) |
| Mapped scenarios | 149 (81.0%) | ~157 (+8 mapped) |
| Pre-UAT shard specs | 34 files / 152 mapped tests | +1 spec file (`care.close.spec.ts`), ~+8 tests |
| Playwright `care*.spec.ts` `test()` count | **29** | **~37** (+8) |

Run `node e2e/scripts/check_bdd_coverage.js --report-only` on the delivery branch after E2E land; update this table in the fold PR.

**Pre-UAT gate:** New `care.close.spec.ts` scenarios tagged `@smoke-uat` (or shard with other `care.*` specs in pre-uat-e2e). Update existing `care.agenda`, `care.schedules`, `care.date`, `away.*`, `health.tracking` specs in the same PRs that change behaviour. **care.a11y** extended for close dialog (already in UAT tier).

---

## 8. PR slicing (ordered, atomic)

| # | Outcome (one sentence) | Scope | Depends | Tests (same PR) | Docs | Size |
|---|------------------------|-------|---------|-----------------|------|------|
| 1 | Add DB columns + R-013 backfill migration | `084_*`, migration integration tests | — | Jest migration084 | Migration runbook note in PR | **L** |
| 2 | Server reads/writes occurrence **outcome** (dual-write) | repository, wire, `occurrenceStatus` timing-only | 1 | Jest unit + fixed integration (partial) | — | **L** |
| 3 | Fixed Not recorded at **next dose**; remove 3-day stack close | `syncOpenOccurrences`, `readSync`, CSM tests | 2 | DB fixed/stale tests; delete resolve-stack server tests | CSM doc stub in PR body | **M** |
| 4 | Care item **Closed** fields + natural Ended | `finishIfNothingLeft`, `entryMap`, wire | 1 | Jest sync finish tests | — | **M** |
| 5 | **Close care** command R-017/R-018 + owner-only | `lifecycle.js`, `petAccess`, `completionRouter` | 2, 4 | Jest close matrix; owner denial | — | **L** |
| 6 | Pause/schedule **delete not-started** open dates | `postpone.js`, `reconcileScheduleEdit` | 2 | Jest pause/schedule | — | **M** |
| 7 | Retire reopen + resolve-stack; history **outcome** | routes, delete stack command, `historyToMap` | 5 | Jest healthEntries; contract tests | OpenAPI | **M** |
| 8 | Away + CIM + reminders + weight guards for Closed | planner, suggestions, tick, weight | 4, 5 | Jest away/suggestion | — | **M** |
| 9 | Flutter domain/wire **outcome** | `care_occurrence.dart`, datasources | 2 (API deployed) | Wire tests | — | **M** |
| 10 | Remove stack/Review UI; agenda/pills | agenda, needs attention, l10n | 9 | Flutter unit/widget; update `care.agenda` E2E | — | **L** |
| 11 | Close care UI + Closed list + read-only | detail screen, all_care, dialog | 5, 9 | Widget tests; **care.close** E2E | — | **L** |
| 12 | BDD feature `care_close` + update legacy specs | bdd + playwright care/away/health | 10, 11 | Full traceability row; BDD gate | — | **M** |
| 13 | Canonical docs fold + delete change spec | care-item-evolution, CSM, delete spec | 12 | `check_docs_canonical.js` | **Mode A sync** | **M** |

---

## 9. Risks and edge cases

| Risk | Mitigation |
|------|------------|
| **Timezones** | Pet home TZ for started/not-started on close; reuse `slotHasStarted`; extend integration tests with `X-Care-As-Of` |
| **Multi-dose days** | Close counts per occurrence row; Record them first routes to Needs attention |
| **Untimed dates today** | R-010/D-010 — started at day start → Not recorded on close |
| **After it's done** | No auto Not recorded; close still applies R-008 |
| **Paused care** | Open rows may exist hidden; close applies R-018 |
| **Shared pets** | Owner-only close; carers keep read-only Closed view |
| **In-flight away plans** | Server-side replan job when care closes; test R-022 |
| **Older app versions** | Dual-write + additive API; deprecate reopen with 410 after min version |
| **CIM suggestions** | Suppress/regenerate when item becomes Closed |
| **Weight fulfilment** | Ensure complete-weight blocked on Closed |
| **Backfill Archived vs Ended** | Audit-based; misclassification risk — see §10 |

---

## 10. Questions for product / engineering

| # | Question | Recommendation |
|---|----------|----------------|
| Q1 | R-013: Finished vs Archived both use `status=completed` today. Confirm backfill: **`health_entry.closed` audit → stopped_by_user**, else **`ended`**, with **`repeat_end_date = close−1`** from old Archive as secondary signal? | Adopt audit-first + repeat_end_date heuristic; log ambiguous rows count in migration |
| Q2 | R-006: Can users **Skip** a Not recorded date from History, or only **Done**? Spec says both; `record` endpoint today only completes. | Add `POST …/skip` for Not recorded rows (same guards as Done) |
| Q3 | R-016 **Record them first**: navigate to Care details Needs attention only, or open first started occurrence leaf? | Care details Needs attention (multi-date) — matches “those dates” plural |
| Q4 | Wire rename `coming_up` → `upcoming` — breaking for Flutter/web stored enums? | Add `upcoming` alias in API one release; Flutter maps both |
| Q5 | Item status string: new value `closed` vs keep `completed` externally? | **`closed`** in API with compat map `completed` → closed for one release |
| Q6 | Delete open rows on pause/close — confirm **no ledger event** per date (D-005)? | Delete rows; optional aggregate ledger on item pause/close only |
| Q7 | CIM: should Closed · Stopped by you suppress all suggestion types for that `health_entry_id`? | Yes — archive active suggestions tied to entry |
| Q8 | CSV export columns for outcome / Closed reason? | Add columns in same PR as history wire |

---

## Docs

This PR: delivery plan only (`status: proposed`). Canonical sync deferred to PR #13 in §8.
