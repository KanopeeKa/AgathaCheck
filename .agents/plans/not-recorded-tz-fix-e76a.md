---
title: Not recorded / TZ fix programme
owner: Agent
audience: agent
status: draft
last_updated: 2026-10-04
tags: [execute-plan, pet-care, care-occurrences]
---

# Plan — `not-recorded-tz-fix-e76a`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `not-recorded-tz-fix-e76a` |
| **title** | Calendar DATE host-TZ fix + data gates + care read/sync (#1558) + Flutter |
| **created** | 2026-10-04 |
| **base_branch** | `cursor/not-recorded-tz-fix-integration-e76a` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **spec** | `docs/domains/pet_care/changes/not-recorded-stale-open-bug-spec.md` (branch `claude/amazing-knuth-ufr7kv` until merged) |

## Goal

Eliminate the o2switch `Europe/Paris` node-pg `DATE` shift (§2.8 / §8), repair or reset corrupted data (§9), then land care read/command consistency and bulk partial success (#1558 fixes), then Flutter UX (§7 PR 3). **Do not deploy read-sync (#1558) to any host before §8 is live there.** UAT tick is suspended until §9 on UAT; **production has no care tick cron** (only UAT) — prod deploy still needs §8 before trusting any DATE field; enable prod tick only after §8 + prod DC-8 decision.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | User chat 2026-10-04 — full delegated authority for this programme |
| **control_issue** | #1569 |
| **Grant** | `approve-autonomous not-recorded-tz-fix-e76a` on #1569 (required for gate) |

## Deployment gates (hard)

1. **§8 merged to `main`** before merging phase 3 (#1558) to integration.
2. **UAT:** deploy §8 → **UAT reset demo data** (DC-1) → `repair_occurrences --dry-run` 0 violations → **re-enable UAT tick cron** → 24h log watch (`0/0` between midnights).
3. **Production:** confirm host `TZ` / `Intl` (DC-2) **before** reset or repair. No tick on prod today — skip cron suspend/re-enable until owner opts in; still run §8 deploy + DC-2 + reset/repair path.
4. **#1558 must not merge** without: `zoneClock` rename (TDZ fix), synced entry wire, shared close rule, **409** for bulk all-closed, AC-A6/A7 + Paris CI matrix green.

## Phases

### Phase 1 — §8 DATE parser + CI Paris matrix

**branch:** `cursor/pg-date-tz-fix-e76a`

**Scope:** TZ-1–TZ-9, AC-TZ1–TZ10; `pgTypes.js`; shared `createPool` or enforced import; `calendarDate.js` comment fix; DATE column audit table in PR body; TZ-3 guard test; tick `tz` field; startup probe TZ-7; INV-6 in repair; optional `scripts/check_pg_pool_bootstrap.js`.

**Exit:** Jest + care DB integration pass under `TZ=Europe/Paris`; second tick run `0/0` on §2.8 fixture; pre-push green.

### Phase 2 — §9 ops tooling + spec on main

**branch:** `cursor/tz-data-repair-ops-e76a`

**Scope:** `server/scripts/ops/sql_readonly.js`; `server/scripts/care/repair_tz_shift.js` (dry-run default); `docs/ops/care-tick.md`; merge spec from `claude/amazing-knuth-ufr7kv`; AC-DC1 on **fixture copy** (not live UAT).

**Exit:** DC-10 read-only helper rejects writes; repair refuses without TZ-7; docs state UAT reset vs prod repair.

**Human / Actions (tracked on control issue, not agent-blocked for phase merge):**

- UAT: run reset workflow after phase 1 deploy to UAT.
- Prod: DC-2 queries via `sql_readonly.js`; reset vs `--apply` per spec.

### Phase 3 — Care read/sync + bulk (#1558 remediated)

**branch:** `cursor/not-recorded-stale-open-e76a` (rebase on integration after phase 1)

**Scope:** FR-1, FR-6–FR-8, FR-10; fix `careItemsWire` TDZ (`zoneClock`); pass synced entry to `careItemWire`; `closeStackOutsideWindow` uses `wouldAutoCloseAsNotRecorded`; `nothing_to_update` → **409** + api-reference; NR + A6/A7 tests; both UTC and Paris.

**Exit:** #1558 superseded or updated PR green; **not deployed to UAT until phase 1 on UAT**.

### Phase 4 — Flutter care UX (§7 PR 3)

**branch:** `cursor/not-recorded-flutter-e76a`

**Scope:** FR-3–5, FR-7 client, FR-9; closed vs open Not recorded; record as given; confirm skip (Q1); unified errors; partial bulk snackbar; AC-I4/I5; Flutter `YYYY-MM-DD` contract test (AC from spec).

**Exit:** Widget tests + BDD scenario; analyze/test green.

### Phase 5 — Integration → main

**branch:** `cursor/not-recorded-tz-fix-integration-e76a`

**Scope:** Single PR integration → `main`; **/babysit-uat**; pre-UAT E2E.

**Exit:** Merged to `main`; pre-UAT green.

## Out of scope (debt issues)

- §2.7 absence-aware `nextSeriesSlotAfter` (AC-G4 not met by TZ fix alone).
- Unique index on all statuses for schedule slots (post-§9 optional).

## Runtime

```bash
node scripts/execute_plan_runtime.js gate not-recorded-tz-fix-e76a
node scripts/execute_plan_runtime.js current-phase not-recorded-tz-fix-e76a
```

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 5
last_completed_phase: 4
halt_reason: null
next_action: "continue phase 5 on branch cursor/not-recorded-tz-fix-integration-e76a"
artifact_ref:
  branch: cursor/not-recorded-tz-fix-integration-e76a
  plan_path: .agents/plans/not-recorded-tz-fix-e76a.md
  plan_commit: fa5f1a71b6182f5006f696c965c3a6f64527e9ba
  snapshot_path: .agents/plans/not-recorded-tz-fix-e76a.snapshot.json
  snapshot_commit: fa5f1a71b6182f5006f696c965c3a6f64527e9ba
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
