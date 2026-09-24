---
title: Away Care Planning
plan_id: away-care-planning
---

# Away Care Planning

| Field | Value |
|-------|-------|
| **plan_id** | `away-care-planning` |
| **title** | Away Care Planning (ACP-DOC-0 through ACP-8) |
| **base_branch** | `cursor/away-care-planning-integration-43b3` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Fix away-plan display honesty (overdue/open occurrences visible with real dates), add reschedule UI from care items, and ship a deterministic Care Planner that suggests date moves to reduce carer load — without CIM inference or automatic writes.

**Canonical docs:** `docs/domains/pet_care/changes/away-care-planning-delivery-plan.md`
**Frozen decisions:** `docs/domains/pet_care/changes/away-care-planning-decisions.md` (D-ACP-001–010, frozen ACP-DOC-0)

## Autonomy

**APPROVED — full continuous execution.** User chat 2026-09-23: agreed Cursor review resolutions, legacy removal, and `/execute-plan` with **no validation pause between phases**.

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-23T23:35:00Z |
| **approved_until** | 2026-09-25T23:35:00Z |
| **approved_by** | User chat 2026-09-23 — Cursor review accepted; execute-plan full autonomy; no phase validation gates |
| **autonomy** | `active` |
| **control_issue** | [#1304](https://github.com/KanopeeKa/AgathaCheck/issues/1304) |

## Phases

**Merged phases:** ACP-1 = old ACP-1+2; ACP-6 = old ACP-6+7. Final PR: integration → `main` after ACP-8.

### Phase acp-doc-0 — Freeze + bootstrap

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-doc0-43b3` |

**Exit criteria:**

- [ ] D-ACP-001–010 frozen; delivery plan §9 resolutions recorded
- [ ] Execute-plan snapshot validated; control issue opened
- [ ] Integration branch pushed

### Phase acp-1 — Server projection + row contract

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-acp1-43b3` |

**Exit criteria:**

- [ ] Open occurrences surfaced (both anchors); corpus updated with pending-row cases
- [ ] Additive wire fields: `open_occurrence`, `in_window`, `is_paused`
- [ ] `estimateOccurrences` table tests; coverage side effect documented/tested
- [ ] `api-reference.md` updated

### Phase acp-3 — Flutter away-plan rows + PDF

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-acp3-43b3` |

**Exit criteria:**

- [ ] New copy lines; legacy `~` and duplicate next-due line removed (R-A2.1)
- [ ] Footnote R-A6; suppress chain explainer R-A6.1
- [ ] Widget tests; one Playwright overdue-row scenario

### Phase acp-4 — Flexibility + reschedule hardening

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-acp4-43b3` |

**Exit criteria:**

- [ ] `resolveScheduleFlexibility` table tests (narrow `fixed` rule)
- [ ] Reschedule validation + `syncNextDueDateFromOccurrences`; router split
- [ ] CSM-10 test expectation updated

### Phase acp-5 — Change date UI

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-acp5-43b3` |

**Exit criteria:**

- [ ] Reschedule sheet + datasource; gap/preview; server warnings win on confirm
- [ ] "Plan this" from away-plan row; undo snackbar

### Phase acp-6 — Care Planner (server + UI)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-acp6-43b3` |

**Exit criteria:**

- [ ] `server/lib/care/planner/**` + GET care-plan route; BR tests; import boundary
- [ ] Suggestions block above Planned care; Accept/Not now

### Phase acp-8 — Docs + remaining journeys

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-care-planning-acp8-43b3` |

**Exit criteria:**

- [ ] Feature docs updated; BDD + Playwright (3 remaining scenarios)
- [ ] `.agents/memory/MEMORY.md` one-liner on D-ACP-001
- [ ] Integration → `main` PR via babysit-uat

## Runtime state

```yaml
autonomy: active
current_phase: acp-3
last_completed_phase: acp-1
halt_reason: null
next_action: "continue phase acp-3 on branch cursor/away-care-planning-acp3-43b3"
artifact_ref:
  branch: cursor/away-care-planning-integration-43b3
  plan_path: .agents/plans/away-care-planning.md
  plan_commit: 881e5b80df0425797f002bb827cc783cef706583
  snapshot_path: .agents/plans/away-care-planning.snapshot.json
  snapshot_commit: 881e5b80df0425797f002bb827cc783cef706583
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
