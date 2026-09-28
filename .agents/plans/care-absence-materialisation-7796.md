# Care absence materialisation — execute-plan

**plan_id:** `care-absence-materialisation-7796`  
**title:** Intent materialisation + absence occurrence review UX  
**created:** 2026-09-28  
**base_branch:** `cursor/care-absence-materialisation-integration-7796`  
**default_merge_mode:** `auto`  
**artifact_branch_policy:** `phase-branch`  
**programme_ref:** `docs/domains/pet_care/features/care-item-evolution.md`

## Goal

Add **intent-based materialisation** (D-CSM-018) so estimated in-window dates can become real occurrences for skip/reschedule; remodel absence UX to **Keep with {carer}** + **Review date** (occurrence sheet); auto-sync absence resolutions after schedule actions; E2E coverage.

**Standing grant (user chat 2026-09-28):** full `/execute-plan` on all phases until `complete-plan` or §Halt.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-28: execute-plan full agreement all phases |
| **control_issue** | #1390 |

## Runtime

```yaml
autonomy: active
current_phase: ensure-flutter
last_completed_phase: ensure-server
halt_reason: null
next_action: "continue phase ensure-flutter on branch cursor/care-absence-materialisation-ensure-flutter-7796"
artifact_ref:
  branch: cursor/care-absence-materialisation-integration-7796
  plan_path: .agents/plans/care-absence-materialisation-7796.md
  plan_commit: 2fb71dee902d5072c9aa2725024e19d845abb144
  snapshot_path: .agents/plans/care-absence-materialisation-7796.snapshot.json
  snapshot_commit: 2fb71dee902d5072c9aa2725024e19d845abb144
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

| id | title | branch |
|----|-------|--------|
| docs | D-CSM-018 spec remodel | `cursor/care-absence-materialisation-docs-7796` |
| ensure-server | ensureOpenOccurrence API | `cursor/care-absence-materialisation-ensure-server-7796` |
| ensure-flutter | Flutter ensure + review entry | `cursor/care-absence-materialisation-ensure-flutter-7796` |
| absence-ux | Absence strip, sheet, auto-resolution | `cursor/care-absence-materialisation-absence-ux-7796` |
| e2e | BDD + Playwright | `cursor/care-absence-materialisation-e2e-7796` |
| integration-main | Integration → main + pre-UAT | `cursor/care-absence-materialisation-integration-7796` |
