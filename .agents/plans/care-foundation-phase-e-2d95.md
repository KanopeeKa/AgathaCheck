---
title: Care Foundation Phase E — Guardian Safeguards
owner: Product / Agent
audience: agent
status: active
last_updated: 2026-09-09
tags: [pet_care, care_intelligence, execute-plan]
---

# Care Foundation Phase E — Guardian Safeguards

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-foundation-phase-e-2d95` |
| **title** | Weight-only guardian safeguards (Phase E) |
| **author** | Cloud agent |
| **created** | 2026-09-09 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **canonical spec** | `docs/domains/pet_care/features/care-intelligence.md` |
| **roadmap** | `docs/domains/pet_care/changes/care-foundation-roadmap.md` §11 |
| **parent roadmap** | `care-programme-v1-2d95` |

## Goal

Ship production guardian safeguards for weight monitoring when evidence supports: server-authoritative evaluation, `care_safeguards` persistence, calm in-app card UX, dismiss semantics, and a minimal safeguard slot in `PetCarePresentationPolicy` (safeguard beats suggestion). Prerequisite for Care Progression CP-6 arbitration.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-09T10:10:00Z |
| **approved_until** | 2026-09-11T10:10:00Z |
| **approved_by** | user chat 2026-09-09 — standing grant Phase E + full Care Progression via `/execute-plan` (D5b implied) |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Phases

### Phase 1 — Phase E weight-only safeguards

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-foundation-phase-e-2d95` |
| **exit_checklist** | `single-backend-route` |

**Scope:**

- Migration: `care_safeguards` table (pet, type, status, evidence JSON, dismissed_at, policy_version)
- Server: `evaluateWeightSafeguard()` reusing Phase D quality + WeightChangeSpec; gate on `unexplained_material` + structured context in production
- API: `GET /api/pets/:petId/care-safeguards` (active), `POST .../care-safeguards/:id/dismiss`
- Trigger: evaluate on weight entry create/update and internal re-eval hook
- Flutter: calm info-blue safeguard card; `CimEvidenceView` (facts only); View changes + Dismiss actions
- `PetCarePresentationPolicy`: safeguard slot beats suggestion (profile + dashboard)
- l10n EN + FR; single-signal copy rule
- Tests: negative (poor data, explained change, diagnosis-free copy); positive golden vector
- DATA_MAP update for `care_safeguards`

**Exit criteria:**

- [ ] Weight-only safeguard surfaces when evaluation passes high bar
- [ ] No safeguard when data inadequate or change explained
- [ ] Dismiss persists; safeguard does not resurface without material change
- [ ] Safeguard beats suggestion in presentation policy tests
- [ ] Copy contains no diagnosis or emergency language

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/care-foundation-phase-e-2d95.md
  plan_commit: 394f77ea05e087a7565e5a92bc0a8396d5eeef5d
  snapshot_path: .agents/plans/care-foundation-phase-e-2d95.snapshot.json
  snapshot_commit: 394f77ea05e087a7565e5a92bc0a8396d5eeef5d
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
