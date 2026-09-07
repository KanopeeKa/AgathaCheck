---
title: Care Foundation & Intelligence (Phases A–C)
owner: Product / Agent
audience: agent
status: active
last_updated: 2026-09-07
tags: [pet_care, care_intelligence, execute-plan]
---

# Care Foundation & Intelligence (Phases A–C)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-foundation-c7a1` |
| **title** | Care Foundation through Suggested by Agatha |
| **author** | Cloud agent |
| **created** | 2026-09-07 |
| **base_branch** | `cursor/care-foundation-c7a1-integration-dc3b` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **canonical spec** | `docs/domains/pet_care/changes/care-foundation-roadmap.md` v0.3 |

## Goal

Deliver Pet Care care organisation and quiet Agatha Suggestions in three autonomous phases: **Care Foundation** (status, family, source, icons, prompts), **Care Rhythms** (recurring care configuration), and **Suggested by Agatha** (three crisp-rule families). **Pause before Phase D** (pattern intelligence) until product owner supplies test dataset — out of scope for this plan.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-07T18:58:00Z |
| **approved_until** | 2026-09-09T18:58:00Z |
| **approved_by** | user chat 2026-09-07 — `/execute-plan` (Phases A–C autonomous; pause before D per roadmap v0.3) |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Phases

### Phase 1 — Care Foundation

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-foundation-phase-a-dc3b` |
| **exit_checklist** | `flutter-screen-split` |

**Scope:** `PetSpecies`, `CareFamily`, `CareSource`, `CareStatus`, `CareStatusService`, pet tile + profile status UI, profile prompt simplification, care-family icons, design docs. No recommendations.

**Exit criteria:**

- [ ] Three-state Care Status on pet tiles and pet profile
- [ ] Shelter teal removed from Pet Care urgency colours
- [ ] CareFamily/CareSource persisted with conservative backfill
- [ ] Unit + widget tests; design docs updated

### Phase 2 — Care Rhythms

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-foundation-phase-b-dc3b` |
| **exit_checklist** | `flutter-screen-split` |

**Scope:** Care Rhythms route/screen, profile nav row, edit/pause, Actions relationship copy.

**Exit criteria:**

- [ ] `/pet/:id/care-rhythms` lists recurring HealthEntry rows
- [ ] Cadence edit updates Actions schedule
- [ ] Actions vs Rhythms semantics in l10n + docs

### Phase 3 — Suggested by Agatha

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-foundation-phase-c-dc3b` |
| **exit_checklist** | `single-backend-route` |

**Scope:** Server recommendation engine (weight, dental, wellness families), persistence, API, Flutter suggestion UX. No fuzzy, safeguards, or LLM.

**Exit criteria:**

- [ ] Three families with negative-route tests
- [ ] Accept/adjust creates Care Rhythm; suggestions never in Actions pre-acceptance
- [ ] Presentation policy caps dashboard/profile cards

## Halt boundary

After Phase 3 merge: **halt for dataset** — do not bootstrap Phase D without product-owner test data (roadmap §10).

## Runtime

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 3 on branch cursor/care-foundation-phase-c-dc3b"
artifact_ref:
  branch: cursor/care-foundation-phase-c-dc3b
  plan_path: .agents/plans/care-foundation-c7a1.md
  plan_commit: bb449e395d1725579facf58ad57e4d8ce9516f7a
  snapshot_path: .agents/plans/care-foundation-c7a1.snapshot.json
  snapshot_commit: bb449e395d1725579facf58ad57e4d8ce9516f7a
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## next_action

Implement Phase 1 on `cursor/care-foundation-phase-a-dc3b`.
