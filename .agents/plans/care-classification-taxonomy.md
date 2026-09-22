---
title: Care classification taxonomy — execute plan
owner: Agent
audience: agent
status: active
last_updated: 2026-09-21
tags: [pet_care, care_item, taxonomy, execute-plan]
---

# care-classification-taxonomy

> **Specification:** [care-classification-taxonomy-spec.md](../../docs/domains/pet_care/changes/care-classification-taxonomy-spec.md) (v2)
> **Integration branch:** `cursor/care-classification-taxonomy-integration-8524` → single final PR to `main`

## Goal

Unify care entry classification on four axes (`care_family`, `care_setting`, `care_planning`, `care_importance`), hide legacy `type` from UI, derive `type` server-side, and replace dual-picker UX with one `CareClassificationSection` module. Deliver in eight atomic phases (A–H).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-21T14:25:00Z |
| **approved_until** | 2026-09-23T14:25:00Z |
| **approved_by** | User chat 2026-09-21 — `/execute-plan in full autonomy` (standing grant for full taxonomy roadmap A–H) |
| **control_issue** | TBD at bootstrap |
| **autonomy** | active |

## Phases

### Phase A — Taxonomy registry foundation

| Field | Value |
|-------|-------|
| **id** | `a` |
| **branch** | `cursor/care-taxonomy-registry-8524` |
| **exit_checklist** | default |

**Scope:** `shared/care_taxonomy.json`; Dart `care_taxonomy` module; Node `server/lib/care/taxonomy/`; contract tests Dart↔Node; retire E2E `inferCareFamilyFromType`.

**Exit criteria:**

- [ ] Single JSON source with family defaults, `filter_group`, `deriveLegacyType` table
- [ ] `rg inferCareFamilyFromType` zero matches in repo
- [ ] Contract tests pass

---

### Phase B — DB + API classification columns

| Field | Value |
|-------|-------|
| **id** | `b` |
| **branch** | `cursor/care-taxonomy-api-8524` |
| **exit_checklist** | single-backend-route |

**Scope:** Migration + backfill §5.4; API validation; server derives `type`; **reject client-sent `type` (400)**; update server + E2E tests.

**Exit criteria:**

- [ ] Columns `care_setting`, `care_planning`, `care_importance`, `importance_overridden`
- [ ] Backfill uses occurrences-first heuristic; ambiguous → `planned`
- [ ] POST/PUT reject `type` in body

---

### Phase C — CareClassificationSection + hide type

| Field | Value |
|-------|-------|
| **id** | `c` |
| **branch** | `cursor/care-classification-picker-8524` |
| **exit_checklist** | default |

**Scope:** `CareClassificationSection` widget; remove `HealthEntryType` dropdown; Flutter stops sending `type` on write.

**Exit criteria:**

- [ ] Form uses classification section only
- [ ] Flutter health entry writes omit `type`

---

### Phase D — Planned vs record form behaviour

| Field | Value |
|-------|-------|
| **id** | `d` |
| **branch** | `cursor/care-planning-modes-8524` |
| **exit_checklist** | default |

**Scope:** Planning toggle; collapse schedule for `unplanned`; `completed_on` required for record; pet-profile `?planning=unplanned` entry.

**Exit criteria:**

- [ ] Record flow validates per §5.3
- [ ] Planned flow unchanged except classification source

---

### Phase E — Health-issue prompts

| Field | Value |
|-------|-------|
| **id** | `e` |
| **branch** | `cursor/care-health-issue-prompts-8524` |
| **exit_checklist** | default |

**Scope:** Vet-setting unplanned save prompt; planned vet completion prompt + re-plan nudge (§10).

**Exit criteria:**

- [ ] Prompts dismissible; link/create health issue works

---

### Phase F — Family-based filters

| Field | Value |
|-------|-------|
| **id** | `f` |
| **branch** | `cursor/care-family-filters-8524` |
| **exit_checklist** | default |

**Scope:** Replace `ManageEventsTypeFilter` / dashboard type tabs with family + `filter_group` chips.

**Exit criteria:**

- [ ] No user-facing type filter chips

---

### Phase G — Unified routing / care list

| Field | Value |
|-------|-------|
| **id** | `g` |
| **branch** | `cursor/care-unified-routing-8524` |
| **exit_checklist** | default |

**Scope:** Single add path; deprecate `/health/add` vs `/other/add`; unify pet profile lists.

**Exit criteria:**

- [ ] One add route; `kHealthEventTypes` split removed from navigation

---

### Phase H — CIM template cleanup

| Field | Value |
|-------|-------|
| **id** | `h` |
| **branch** | `cursor/care-cim-taxonomy-8524` |
| **exit_checklist** | single-backend-route |

**Scope:** Drop `suggested_health_entry_type` from recommendations; templates use classification fields.

**Exit criteria:**

- [x] CIM accept uses `care_family` + optional setting/importance only

---

## Final merge

After phase H merged to integration → open PR `cursor/care-classification-taxonomy-integration-8524` → `main` → `/babysit-uat`.

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: h
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/care-classification-taxonomy.md
  plan_commit: bbc397e251181b14ba9b0a0f8cbec11c7807ae25
  snapshot_path: .agents/plans/care-classification-taxonomy.snapshot.json
  snapshot_commit: bbc397e251181b14ba9b0a0f8cbec11c7807ae25
open_prs: []
merge_commits: {"a":"5a770bbd82befe657c80cb142eb4eb1c2cdf0be9"}
debt_issue_refs: []
```
