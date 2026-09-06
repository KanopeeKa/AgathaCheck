---
title: Pet Care terminology rename completion (F-22)
owner: Agent
audience: agent
status: active
---

# pet-care-terminology-rename

## Goal

Complete F-22 residual **Guardian → Pet Care** terminology: rename workspace-scoped `guardian_*` code identifiers and l10n keys, remove deprecated `AppExperience.guardian` / `guardianPrimary` call sites, and close the hardening discovery finding. Wire values (`pet_care`, `/pc/*`) and DB migration were delivered by `pet-care-domain-rename-b088` — this plan finishes internal naming drift.

**Custody carve-out:** keep `guardianship`, `individual_guardianship`, `pet_access.role = 'guardian'`, legal holder copy, seed scenario names.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T20:35:00Z |
| **approved_until** | 2026-09-08T20:35:00Z |
| **control_issue** | TBD |
| **autonomy** | active |

**Grant:** User chat 2026-09-06 — `approve-autonomous pet-care-terminology-rename`.

## Runtime

```yaml
autonomy: active
current_phase: 4
last_completed_phase: 3
halt_reason: null
next_action: "continue phase 4 on branch cursor/pet-care-terminology-cleanup-75cb"
artifact_ref:
  branch: cursor/pet-care-terminology-cleanup-75cb
  plan_path: .agents/plans/pet-care-terminology-rename.md
  plan_commit: c5e097d68df217211efcdbe92b9fcc5d003b6733
  snapshot_path: .agents/plans/pet-care-terminology-rename.snapshot.json
  snapshot_commit: c5e097d68df217211efcdbe92b9fcc5d003b6733
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1044"]
merge_commits: {}
debt_issue_refs: []
```

## Reference

- Prior plan: `pet-care-domain-rename-b088` (wire/API/DB — completed)
- Discovery: F-22 in `docs/domains/pet_care/changes/hardening-discovery.md`
- Naming contract: `docs/domains/pet_care/changes/domain-rename-plan.md`
