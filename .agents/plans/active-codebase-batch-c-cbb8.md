---
title: Active codebase Batch C — Client authority
owner: Agent
audience: agent
status: active
---

# active-codebase-batch-c-cbb8

## Goal

Execute **Batch C — Client authority** from the accepted [active codebase architecture review](docs/architecture/reviews/active-codebase-review.md): Package 7 explicit pet cache and D2 failure policy, then Package 8 canonical health-entry state with a single owner and migrated selectors.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-24T10:10:00Z |
| **approved_until** | 2026-09-26T10:10:00Z |
| **control_issue** | #1308 |
| **autonomy** | active |

Standing grant: user chat 2026-09-22/23 + `/execute-plan` Batch C (2026-09-24) — D1–D7 accepted; autonomous batches A→B→C.

## Programme reference

`docs/architecture/reviews/active-codebase-review.md` — Sprint C (Packages 7 → 8).

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/active-codebase-c1-pet-cache-cbb8"
artifact_ref:
  branch: cursor/active-codebase-c1-pet-cache-cbb8
  plan_path: .agents/plans/active-codebase-batch-c-cbb8.md
  plan_commit: f50a16b17a6e9cce204ab9806ec0a047adc32fd3
  snapshot_path: .agents/plans/active-codebase-batch-c-cbb8.snapshot.json
  snapshot_commit: f50a16b17a6e9cce204ab9806ec0a047adc32fd3
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — C1 D2 pet cache policy (Package 7)

Typed fetch result at the pet repository boundary; 401/403 fail loud; genuine network/transport errors may return stale cache with `isStale` metadata; migrate Pet Care home and All Pets surfaces to show offline/stale affordance; regression tests replace A06 characterization.

### Phase 2 — C2 canonical health store (Package 8)

Single canonical health-entry owner (`healthEntriesNotifierProvider`); remove independent `petHealthEntriesProvider` fetch path; session-generation guard on logout/user switch; document store in baseline; widget tests for selector convergence after mutations.
