---
title: Care status model — delivery plan
owner: Product / Agent
audience: both
domain: pet_care
status: proposed
status_since: 2026-11-04
folds_into: docs/domains/pet_care/features/care-item-evolution.md
last_updated: 2026-11-04
related_prs: [2065]
---

# Care status model — delivery plan

**Status:** Proposed — revised **2026-11-04** after product review on [#2065](https://github.com/KanopeeKa/AgathaCheck/pull/2065) against amended [care-status-model-spec.md](./care-status-model-spec.md) (`badfbcb` on `claude/funny-albattani-v6t5k3`).

**Spec coverage:** CARE-STATUS-R-001 … **R-028**, D-001 … **D-022**.

**Guiding principle (spec):** fewer types, fewer states, **no transitional layers** (R-026, D-020).

**Escalation:** Slice 1 includes a **production data migration** for care date outcomes (autonomous-pr-policy §Escalation). Owner must explicitly approve before that phase PR merges to integration, regardless of execute-plan approval.

---

## Autonomous delivery — recommendation

| Approach | Verdict |
|----------|---------|
| **Execute-plan v2** (`plan_id`: **`care-status-model`**) | **Recommended.** Six phases map 1:1 to R-028; integration branch `cursor/care-status-model-integration-*`; each worker tick delivers one vertical slice (server + Flutter + BDD + Playwright per R-027). Driver merges phase PRs; one release PR integration → `main`; `/babysit-uat` only on the release PR. |
| Six standalone PRs to `main` + `/babysit-plus` each | Works without control issue, but you lose scope guards, budget caps, and automated phase sequencing. More owner babysitting. |
| Single large PR | **Reject** — violates R-027 and atomic-PR policy. |

**Why execute-plan fits:** multi-slice programme, shared pet-care surface, first slice is escalated migration, spec already defines slice order (D-022).

**Prerequisites before `init`:**

1. Merge amended **spec** and this **delivery plan** to `main` (or agree integration base = spec branch until then).
2. Owner posts **`approve-autonomous care-status-model`** on the control issue after `node scripts/execute_plan_runtime.js init care-status-model`.
3. **Separate explicit approval** for Slice 1 production migration (comment on control issue or phase-1 PR) before driver merges phase 1.

**Execute-plan file:** add `.agents/plans/care-status-model.md` on branch `cursor/care-status-model-init` using the phase breakdown in §8 below (allowed_paths per phase — pet_care server, `flutter_app` care surfaces, `e2e/playwright/tests/care*.spec.ts`, matching BDD features). Proof on UAT: close an active care with overdue dates; see Closed care list; History shows Not recorded not Skipped for system rows.

**Not using** legacy `.agents/plans/care-status-consolidation.md` (2026-09 Child A — different goal: temporal grouping only).

---

## 1. Current-state inventory

*(Unchanged from first plan revision — still accurate on spec branch.)*

### 1.1 Database

| Area | Location | Notes |
|------|----------|-------|
| Occurrence row | `health_occurrences` | `status`: `pending` \| `completed` \| `skipped`; `close_reason`: `user` \| `not_recorded` \| `paused` \| `system` |
| Care item row | `health_entries` | `status`: `active` \| `paused` \| `completed`; Finished/Archived indistinguishable |
| Ledger | `care_schedule_events` | `not_recorded_closed`, etc. |

### 1.2 Server — writes

`skip.js`, `complete.js`, `syncOpenOccurrences.js` (`closeStackOutsideWindow`), `postpone.js` (`paused`), `lifecycle.js` (`reconcileScheduleEdit`, `closeSeriesCommand`, `reopenSeriesCommand`), `stack.js` (`resolveStackCommand`, `recordAsGivenCommand`), `occurrenceRepository.js`, `nextChoice.js`, `tzShiftRepair.js`.

### 1.3 Server — reads / API

`occurrenceStatus.js`, `readSync.js`, `occurrenceListService.js`, `completionRouter.js` (history without outcome), `occurrencePatchRouter.js`, `entryMap.js` / `wire.js`, CSV via `healthEntryCsv.js`, routes `/close`, `/reopen`, `/occurrences/resolve-stack`, `/occurrences/:id/record`.

### 1.4 Server — adjacent

`planAbsenceCare.js` (already skips `closed`), `carePeriodCoverage.js`, `suggestionGeneration.js`, weight fulfilment, `careTick.js`, `petAccess.js` (close not owner-only today).

### 1.5 Flutter

`care_occurrence.dart`, `stack_rule.dart`, `care_agenda.dart`, `care_item_needs_attention_section.dart`, `care_agenda_row_tile.dart`, `care_item_menu.dart` (Archive/Restore), `pet_event_close_confirm_dialog.dart`, `all_care_inactive_section.dart` (“Other care”), `care_item_context_strip.dart`, `occurrence_display.dart`, l10n `closeEvent*`, `careItemMenuArchive/Restore`, `careStatusReviewAction`.

### 1.6 Tests / E2E

Server: `server/test/db/careOccurrences.*`, `healthEntries.test.js`, `careSchedule/*`, `care/planner/planAbsenceCare.test.js`. Flutter: `flutter_app/test/features/care_item/**`. BDD: `care_*.feature`, `health_tracking.feature`, `away_*.feature`. Playwright: `care.*.spec.ts`, `away.*`, `health.tracking.spec.ts` (29 `test()` in `care*.spec.ts` at last count).

---

## 2. Gap analysis (R-001 … R-028)

| ID | Gap (short) |
|----|-------------|
| R-001 | Collapse to one stored outcome; **drop `close_reason`**; no `closed_by` |
| R-002 | Keep **Coming up** / `coming_up`; timing only on Open |
| R-003 | Stop system writing Skipped |
| R-004 | History + CSV say Not recorded, not Skipped, for system rows |
| R-005 | **Stored** Not recorded at next Fixed dose; **History only** (not Needs attention) |
| R-006 | Not recorded → **Done only** from History (existing `record` path) |
| R-007 | After-it's-done unchanged |
| R-008 | Pause/close/schedule: started → Not recorded; not started → **delete**, no ledger |
| R-009–R-011 | Item `closed`; read-only; no reopen |
| R-012 | Already satisfied |
| R-013 | In-place backfill; items: **audit-only** Stopped by you |
| R-014–R-019 | Close care UX + owner + R-018 |
| R-020 | Read-only includes **pencil**, **Edit schedule**, **Needs attention** removed |
| R-021 | **Closed care** list; rows **no dates** |
| R-022–R-023 | Away + natural Ended; record-only one-off → Closed · Ended at creation |
| R-024 | Empty **Other care** of finished/archived/recorded — all in Closed care |
| R-025 | Verify CIM; guard only if close re-triggers suggestion |
| R-026 | **No** dual-write, aliases, or deprecation window |
| R-027 | Every PR: server + app + E2E together |
| R-028 | **Six slices** (§8) |

---

## 3. Data model and migration design

### 3.1 Care date outcome (in-place — R-026, D-020)

**Recommendation:** One migration **`084_care_date_outcome.js`** (Slice 1) — **remap in place**, then **drop `close_reason`**:

| Stored | Implementation |
|--------|------------------|
| Open | `status = 'pending'` (or rename column values to `open` in same migration if enum is cheap — wire exposes outcome name either way) |
| Done | `status = 'completed'` |
| Skipped | `status = 'skipped'` and only user-initiated paths may set it |
| Not recorded | `status = 'not_recorded'` **new enum value** replacing `skipped` + `close_reason = 'not_recorded'` |

Backfill R-013 (occurrences): as spec table; delete rows for not-yet-started system/paused skips.

**Reject** prior plan options: separate `outcome` column kept alongside legacy, dual-write, `closed_by`, `coming_up` → `upcoming`.

Open-row timing stays **computed** (`occurrenceStatus.js`); remove open-row `not_recorded` timing once R-005 stores Not recorded (Slice 2).

### 3.2 Care item Closed (in-place — Slice 4)

Migration **`085_care_item_closed.js`** (or same phase as behaviour):

| Field | Value |
|-------|--------|
| `health_entries.status` | Add **`closed`**; migrate `completed` → `closed` |
| `care_closed_reason` | `ended` \| `stopped_by_user` |
| `closed_at` | timestamptz when closed / natural end |

Backfill R-013 (items): **`health_entry.closed` audit** → `stopped_by_user`; **all other** former `completed` → `ended` (D-021). Includes care recorded after the fact (D-019).

### 3.3 Rollout

No compatibility layer: deploy server + web build together. Migrations run forward only; rollback = new migration (escalation).

---

## 4. API contract changes

| Change | Notes |
|--------|-------|
| Occurrence wire | Expose single **outcome** (`open`, `done`, `skipped`, `not_recorded`); open rows + computed `occurrence_status` (`coming_up`, `due`, `overdue`) |
| History / past list | Include **outcome**; map legacy rows via migration only |
| Item wire | `status: closed`, `care_closed_reason`, `closed_at` |
| Retire | `/reopen`, `/occurrences/resolve-stack`; keep `/record` for Not recorded → Done |
| Close | Owner-only; semantics R-017/R-018 (Slice 5) |
| CSV | Wording only — “Not recorded” (R-004); **no new columns** |
| Closed item | 409 on mutating commands (Slice 4+) |

---

## 5. Flutter changes (by slice theme)

| Theme | Action |
|-------|--------|
| History / outcome | Pills and History rows show Not recorded; record Done from History |
| Stack removal | Delete stack/Review/Record earlier doses; agenda row no stack aggregation |
| Pause/schedule | UI unchanged mostly; behaviour from server R-008 |
| Closed item | Chip Closed · Ended/Stopped by you; read-only: hide pencil, ⋯ edit actions, Edit schedule, Needs attention |
| Close care | Bottom danger button, dialog + Record them first → Needs attention |
| Closed care list | Footer link + list; **no dates** on rows; remove finished/archived/recorded from Other care |
| l10n | Close **care** (not “event”); retire Archive/Restore |

---

## 6. Canonical doc impact

Fold in **Slice 6** only: merge spec requirements/decisions into `care-item-evolution.md` + supersede rows in `care-schedule-management.md`; delete `care-status-model-spec.md` and this delivery plan when fully delivered.

---

## 7. Test plan

### 7.1 BDD coverage baseline / target

| Metric | Before delivery | After (target) |
|--------|-----------------|----------------|
| Gated scenarios | 184 | ~192 (+8) |
| Mapped | 149 (81.0%) | ~157 |
| `care*.spec.ts` tests | 29 | ~37 (+8) |

Re-run `node e2e/scripts/check_bdd_coverage.js --report-only` after each slice.

### 7.2 Traceability by slice (requirements closed)

| Slice | Requirements | Primary tests |
|-------|--------------|---------------|
| 1 Truthful History | R-001, R-003, R-004, R-006, R-013 (occurrences), R-026 | Jest migration084 + history API; Flutter History/CSV widgets; BDD update `care_date_screen` / history; Playwright `care.date` |
| 2 Next-dose Not recorded | R-005, R-007, stack removal | DB fixed integration; delete stack tests; Flutter `stack_rule` removed; `care.agenda`, `care.schedules`, `health_tracking` BDD/E2E |
| 3 Pause / schedule | R-008 | Jest postpone + reconcileScheduleEdit; BDD `care_pause_resume`, `care_schedules` |
| 4 Item Closed | R-009–R-011, R-013 (items), R-020, R-023, R-024, D-019 | Jest finish + migration item backfill; Flutter read-only detail tests; partial E2E read-only |
| 5 Close care | R-014–R-019, R-022, R-025 | Jest close matrix + owner; new `care_close.feature` + `care.close.spec.ts`; `care.a11y`; away specs |
| 6 Closed care list | R-021, R-024, canonical fold | Widget All care footer; E2E list + natural Ended journeys; `check_docs_canonical.js` |

Full R-001 … R-028 row-level matrix: same as §2 plus slice column above.

### 7.3 Pre-UAT gate

New and updated journeys in **`care.close.spec.ts`** and touched `care.*` / `away.*` specs run in **pre-uat-e2e** shards (`@smoke-uat` / existing care shard assignment). Extend **`care.a11y.spec.ts`** for Close care button + dialog in Slice 5.

---

## 8. Delivery slices (R-028, D-022) — vertical PRs

Each slice = **one PR** to integration with **server + Flutter + BDD + Playwright** (R-027). Estimated size: **L** = large, **M** = medium.

### Slice 1 — Truthful History

**Outcome:** History and CSV show real outcomes; system rows say Not recorded; user can mark Not recorded as Done from History.

| Layer | Work |
|-------|------|
| Server | Migration 084 (occurrence backfill + `not_recorded` status + drop `close_reason`); history + past occurrence wire; stop system Skipped on write paths touched; CSV wording |
| Flutter | History pills, occurrence detail, wire parsing; record Done from History |
| E2E | Update `care.date` / history assertions; Jest migration + integration |

**Escalation:** production migration — **owner approval before merge.**

**Removes from plan drift:** dual-write, `closed_by`, compat aliases.

---

### Slice 2 — Not recorded at the next dose

**Outcome:** Fixed doses become stored Not recorded when the next dose is due; stack, Review, Record earlier doses gone; rows leave Needs attention and appear in History only.

| Layer | Work |
|-------|------|
| Server | Change sync/`occurrenceStatus` — remove 3-day `closeStackOutsideWindow`; persist Not recorded at next dose; remove `resolveStack` route/command |
| Flutter | Remove stack UI, Review action, `resolveStack`, `stack_rule` consumers, bulk stack bar |
| E2E | Rewrite `care.agenda` stack scenario; `care.schedules` stack/history specs; delete BDD stack lines |

**Requirements:** R-005, R-007, D-004, D-016 (keep Coming up).

---

### Slice 3 — Pause and schedule rule

**Outcome:** Pausing or schedule change removes not-yet-due open dates; started open dates become Not recorded; no ledger for deletes.

| Layer | Work |
|-------|------|
| Server | `postpone.js`, `reconcileScheduleEdit`, `deleteOpenOccurrences` — R-008 |
| Flutter | Minimal unless copy/snackbar |
| E2E | `care.item.pause_resume`, `care.schedules` reschedule/pause |

**Requirements:** R-008, D-005.

---

### Slice 4 — Care item Closed status

**Outcome:** Items become `closed` with Ended/Stopped by you; natural end and record-only one-offs; Care details read-only (pencil, menu, Edit schedule, Needs attention off); Other care no longer lists them.

| Layer | Work |
|-------|------|
| Server | Migration 085 item fields + audit backfill; `finishIfNothingLeft` → Closed Ended; command guards 409 |
| Flutter | Context strip, detail screen read-only mode, filters, inactive section |
| E2E | Read-only Closed detail smoke; one-off done → Ended |

**Requirements:** R-009–R-011, R-013 (items), R-020, R-023, R-024, D-019, D-021.

---

### Slice 5 — Close care

**Outcome:** Owner-only Close care button + dialog (Record them first → Needs attention); R-018 close semantics; reminders stop; away drop for not-started plans; CIM verify/guard.

| Layer | Work |
|-------|------|
| Server | Rewrite `closeSeriesCommand`; owner check; retire `/reopen`; away replan; CIM check (R-025) |
| Flutter | Bottom danger button, dialog, remove Archive/Restore; hide for non-owner |
| E2E | **New** `care_close.feature` + `care.close.spec.ts` (overdue+future close, Record them first, paused close, non-owner, a11y); update `away.*` |

**Requirements:** R-014–R-019, R-022, R-025, D-011–D-013.

---

### Slice 6 — Closed care list + docs

**Outcome:** Closed care link/count at bottom of All care; list rows Closed · Ended/Stopped by you **without dates**; canonical fold.

| Layer | Work |
|-------|------|
| Server | List/filter API if needed for closed items only |
| Flutter | `all_care_list` footer, new list route/screen |
| E2E | Closed list journeys; natural recurring end |
| Docs | `/canonical-docs sync`; delete change spec + this plan |

**Requirements:** R-021, R-024, R-028 (docs).

---

## 9. Risks and edge cases

Timezones, multi-dose days, untimed today (D-010), After-it's-done, paused open rows, shared pets (owner-only close), away in-flight, **audit gaps** for Stopped-by-you backfill (default Ended — acceptable per D-021).

---

## 10. Resolved product answers (2026-11-04)

Prior plan questions **closed in spec** — do not re-open in implementation:

| Topic | Resolution |
|-------|------------|
| Record-only entries | One-off Done → Closed · Ended; no Other care bucket (R-023, R-024, D-019) |
| Not recorded UX | History only, not Needs attention (R-005) |
| Not recorded action | Done only (R-006, D-017) |
| Timing label | Coming up / `coming_up` (R-002, D-016) |
| Closed list rows | No dates (R-021, D-018) |
| Read-only surface | Pencil, menu, Edit schedule, Needs attention (R-020) |
| Item backfill | Audit-only Stopped by you (R-013, D-021) |
| CSV | Wording only (R-004) |
| CIM | Verify then guard if needed (R-025) |
| Compat | None (R-026) |
| Record them first | Dialog closes → Needs attention (R-016) |

---

## Docs

This document: `status: proposed`. Canonical sync in Slice 6 only.
