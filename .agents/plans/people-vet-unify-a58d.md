# People–vet unification (`people-vet-unify-a58d`)

## Goal

Eliminate drift between legacy `vets` / `pets.vet_id` and People (`people_contacts`, `pet_contact_relationships`) so one professional identity appears in Vet team, pet assignment, and People hub — without duplicate rows or write paths.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | User chat 2026-09-29: full agreement phases 0–5 via `/execute-plan` |
| **control_issue** | (set in snapshot) |

## Phases

| id | Title |
|----|-------|
| p0-data-repair | Seed + reconcile/repair vets → contacts |
| p1-pet-write-sync | Pet save syncs contact + primary_vet |
| p2-flutter-read | Pet UI reads professionals from People |
| p3-contact-vet-sync | Contact ↔ vet field sync |
| p4-vet-ui-redirect | Vet routes → People; unified create |
| p5-cleanup | Tests, docs, seed gate |

## Runtime

```yaml
autonomy: active
current_phase: p1-pet-write-sync
last_completed_phase: p0-data-repair
halt_reason: null
next_action: "start phase p1-pet-write-sync: checkout cursor/people-vet-unify-p1-a58d"
artifact_ref:
  branch: cursor/people-vet-unify-integration-a58d
  plan_path: .agents/plans/people-vet-unify-a58d.md
  plan_commit: d665814204fd8048c324c0f92d93f52689820712
  snapshot_path: .agents/plans/people-vet-unify-a58d.snapshot.json
  snapshot_commit: d665814204fd8048c324c0f92d93f52689820712
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
