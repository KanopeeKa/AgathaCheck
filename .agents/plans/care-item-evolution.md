# Care Item evolution — execute-plan

**plan_id:** `care-item-evolution`  
**title:** Canonical Care Item spec, doc consolidation, and phased product delivery  
**created:** 2026-09-27  
**base_branch:** `cursor/care-item-evolution-integration-7796`  
**default_merge_mode:** `auto`  
**artifact_branch_policy:** `phase-branch`  
**programme_ref:** `docs/domains/pet_care/features/care-item-evolution.md`

## Goal

Make [care-item-evolution.md](../../docs/domains/pet_care/features/care-item-evolution.md) the **only canonical Care Item product spec**; archive superseded delivery plans; implement the spec in phases A0→F aligned with the document (People track runs separately via `people-care-team-a58d`).

**Standing grant (user chat 2026-09-27):** full autonomous `/execute-plan` through this programme — doc tidying, branches, PRs, babysit+, merge — until `complete-plan` or §Halt.

**Supersedes:** `.agents/plans/pet-care-item-model.md` and all halted child plans there.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-27: execute-plan full autonomous through care-item-evolution programme |
| **control_issue** | #1346 |

## Runtime

```yaml
autonomy: active
current_phase: e-absence
last_completed_phase: d-providers
halt_reason: null
next_action: "start phase e-absence: checkout cursor/care-item-evolution-e-absence-7796"
artifact_ref:
  branch: cursor/care-item-evolution-integration-7796
  plan_path: .agents/plans/care-item-evolution.md
  plan_commit: 75ee0ce6b0c75aa32a4ac6031cb4d4b27168ef9b
  snapshot_path: .agents/plans/care-item-evolution.snapshot.json
  snapshot_commit: 75ee0ce6b0c75aa32a4ac6031cb4d4b27168ef9b
open_prs: []
merge_commits: {"docs":"d977ebdecbe7f881a3e552122f055f265e9af755"}
debt_issue_refs: []
```

## Phases (summary)

| id | title | branch | Depends |
|----|-------|--------|---------|
| docs | Canonical spec + archive old delivery plan | `cursor/care-item-evolution-docs-7796` | — (PR → `main`) |
| a0-rules | Overdue vocabulary + multi-dose list subtitles | `cursor/care-item-evolution-a0-rules-7796` | docs |
| a1-timezone | Pet home timezone | `cursor/care-item-evolution-a1-timezone-7796` | a0-rules |
| b-view | Care Item view + Edit + Pause UI | `cursor/care-item-evolution-b-view-7796` | a0-rules |
| c-completion | Overdue completion date + Add details | `cursor/care-item-evolution-c-completion-7796` | b-view |
| d-providers | Provider + performed-by (needs People P1) | `cursor/care-item-evolution-d-providers-7796` | c-completion, People P1 |
| e-absence | Absence resolutions + away join | `cursor/care-item-evolution-e-absence-7796` | b-view |
| f-categories | Category blocks rollout | `cursor/care-item-evolution-f-categories-7796` | c-completion |
| integration-main | Integration → main | `cursor/care-item-evolution-integration-7796` | all impl phases |

Reminders track (spec §R) is **out of scope** for this plan.

### Phase docs — Canonical documentation

**Scope:** Spec authority header; review fixes (D-CIE-003 Agreed, phasing A0/A1); supersede `care-item-model-delivery-plan`; archive 2026-09-13 delivery text; D-AWAY-003 amendment; README + taxonomy links; halt `pet-care-item-model` roadmap.

**Exit criteria:**

- [ ] `bash scripts/validate_docs.sh` green
- [ ] PR merged to `main`

### Phase a0-rules — Overdue everywhere (preserve timed predicate)

**Scope:** Retire user-facing "Missed"; unify Overdue; worst-slot subtitles on profile / All Actions / All care; agreement tests updated. **Do not** change `isOccurrenceMissed` semantics.

**Exit criteria:**

- [ ] Flutter + server tests for grouping/subtitles
- [ ] BDD selectors updated where titles change

### Phase a1-timezone — Pet home timezone

**Scope:** Schema + API + server/client open-occurrence missed in pet home TZ (D-CIE-005, D-CIE-023).

**Exit criteria:**

- [ ] Documented pet TZ field; server `listOpenOccurrences` uses pet TZ
- [ ] Client grouping uses pet TZ from API

### Phase b-view — Care Item view and Edit

**Scope:** Needs attention layout, History, Schedule copy fix, menus (D-CIE-017), lifecycle Pause UI, web two-column layout, access tiers table.

**Exit criteria:**

- [ ] Care Item detail matches spec order; widget tests
- [ ] Pause/resume UI wired to existing API

### Phase c-completion — Completing care

**Scope:** One-tap mark done for Due/Coming up; overdue "When was this done?"; Add details sheet; occurrence documents (API + UI).

**Exit criteria:**

- [ ] Jest + Flutter tests for completion paths
- [ ] No regression on after-completion schedule advance

### Phase d-providers — Providers and people on occurrences

**Scope:** Default provider, typed name interim, provider used, performed by snapshots (D-CIE-016, D-CIE-020). **Gate:** People P1 merged to `main`.

**Exit criteria:**

- [ ] Provider picker + migration for typed names
- [ ] Occurrence completion stores provider used

### Phase e-absence — Absence resolutions

**Scope:** Resolution storage, derived states, Care Item Absence section, away-plan alignment, handover PDF extension (Phase E in spec).

**Exit criteria:**

- [ ] Away plan + care item use same affected-item calculation
- [ ] Migration + API for resolutions

### Phase f-categories — Category blocks

**Scope:** Shared blocks on item/occurrence per spec table; dosage → product block migration path.

**Exit criteria:**

- [ ] Medication + weight + vaccination blocks shipped first (spec delivery order)

### Phase integration-main — Ship to main

**Scope:** Single PR integration → `main`; `./scripts/pre-push.sh`; `/babysit-uat`.

**Exit criteria:**

- [ ] Pre-UAT green on merge SHA
