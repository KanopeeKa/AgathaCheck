---
title: Care Foundation & Intelligence (Phases A–E)
owner: Product / Agent
audience: agent
status: active
last_updated: 2026-09-08
tags: [pet_care, care_intelligence, execute-plan]
---

# Care Foundation & Intelligence (Phases A–E)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-foundation-c7a1` |
| **title** | Care Foundation through Review Relevance |
| **author** | Cloud agent |
| **created** | 2026-09-07 |
| **base_branch** | `cursor/care-foundation-c7a1-integration-dc3b` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **canonical spec** | `docs/domains/pet_care/features/care-intelligence.md` |
| **delivery plan** | `docs/domains/pet_care/changes/phase-d-review-relevance-plan.md` |
| **roadmap** | `docs/domains/pet_care/changes/care-foundation-roadmap.md` v0.4 |

## Goal

Deliver Pet Care care organisation (Phases A–B), quiet Agatha Suggestions (Phase C), and weight-first **review-relevance** evaluation (Phase D) with human gates before production user-data research (D0.5) and Phase E scope lock (D5b). Phase E guardian safeguards follow D5b approval.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-07T18:58:00Z |
| **approved_until** | 2026-09-09T18:58:00Z |
| **approved_by** | user chat 2026-09-07 — Phases A–C autonomous only |
| **reapproval_required** | **yes** — 2026-09-08 replan supersedes A–C grant for Phase D scope |
| **control_issue** | [#1082](https://github.com/KanopeeKa/AgathaCheck/issues/1082) |
| **autonomy** | `halted` — awaiting re-approval after replan PR merges |

### Re-approval (mandatory before D0)

The 2026-09-07 autonomous grant covered **Phases A–C only** (including the obsolete “product-owner test dataset” pause before Phase D). That boundary is **superseded**.

After the Phase D documentation replan PR merges:

1. Product owner comments `approve-autonomous care-foundation-c7a1` on #1082 with refreshed approval window.
2. Agent updates `approved_at`, `approved_until`, and sets `autonomy: active`.
3. Resume at **Phase 5 — D0** (not before).

Do **not** mutate the snapshot scope without this re-approval step.

## Phases

### Phase 1 — Care Foundation ✅

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-foundation-phase-a-dc3b` |
| **status** | merged (#1083) |

### Phase 2 — Care Rhythms ✅

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-foundation-phase-b-dc3b` |
| **status** | merged (#1084) |

### Phase 3 — Suggested by Agatha ✅

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-foundation-phase-c-dc3b` |
| **status** | merged (#1085) |

### Phase 4 — Phase D documentation replan

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/phase-d-docs-replan-dc3b` |
| **exit_checklist** | `default` |

**Scope:** Feature doc, Phase D delivery plan, roadmap v0.4, README index, execute-plan reconciliation, schema halt reasons. **No runtime care-intelligence code.**

### Phase 5 — D0 Semantics & data contracts

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/care-foundation-phase-d0-dc3b` |
| **exit_checklist** | `single-backend-route` |
| **gate** | D0.5 → `halted` / `governance_approval_required` |

**Scope:** Provenance model (`measurementSource`, `referenceAuthority`, `managementContext`), WeightChangeSpec contract, trace types, D6.0 benchmark schema.

### Phase 6 — D1–D7 Review relevance execution

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/care-foundation-phase-d-exec-dc3b` |
| **exit_checklist** | `single-backend-route` |
| **gate** | D5b → `halted` / `model_selection_approval_required` |

**Scope:** Per [phase-d-review-relevance-plan.md](../../docs/domains/pet_care/changes/phase-d-review-relevance-plan.md). Parallel context micro-PRs allowed.

## Halt boundaries

| Gate | `status_reason` | Trigger |
|------|-----------------|---------|
| Replan re-approval | `governance_approval_required` | After phase 4 merge, before phase 5 |
| D0.5 | `governance_approval_required` | Before prod user-data research |
| D5b | `model_selection_approval_required` | Before Phase E handoff |

## Runtime

```yaml
autonomy: halted
current_phase: 4
last_completed_phase: 3
halt_reason: governance_approval_required
halt_detail: "Phase D replan PR in progress; A–C grant superseded — re-approve before D0"
next_action: "Complete phase 4 docs replan PR; then request re-approval on #1082 before phase 5"
artifact_ref:
  branch: cursor/care-foundation-c7a1-integration-dc3b
  plan_path: .agents/plans/care-foundation-c7a1.md
  snapshot_path: .agents/plans/care-foundation-c7a1.snapshot.json
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## next_action

Land phase 4 (docs replan). Post re-approval request on #1082. Do not start D0 until re-approved.
