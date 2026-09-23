---
title: Active codebase Batch B — Backend integrity
owner: Agent
audience: agent
status: active
---

# active-codebase-batch-b-cbb8

## Goal

Execute **Batch B — Backend integrity** from the accepted [active codebase architecture review](docs/architecture/reviews/active-codebase-review.md): mandatory transaction runner (Package 3), repair `deleteAllPetData` (Package 3), stable committed command results for weight/share (Package 4), and D1 passed-away notification wire contract (Package 6).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-23T15:44:00Z |
| **approved_until** | 2026-09-25T15:44:00Z |
| **control_issue** | TBD |
| **autonomy** | active |

Standing grant: user chat 2026-09-22 + 2026-09-23 — D1–D7 accepted; `/execute-plan` autonomous through batches A→B→C.

## Programme reference

`docs/architecture/reviews/active-codebase-review.md` — Sprint B (Packages 3, 4, 6).

## Runtime

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 2
halt_reason: null
next_action: "continue phase 3 on branch cursor/active-codebase-b3-command-results-cbb8"
artifact_ref:
  branch: cursor/active-codebase-b3-command-results-cbb8
  plan_path: .agents/plans/active-codebase-batch-b-cbb8.md
  plan_commit: 7dbb46743b595fce27ae920b705c6184d7b9d259
  snapshot_path: .agents/plans/active-codebase-batch-b-cbb8.snapshot.json
  snapshot_commit: 7dbb46743b595fce27ae920b705c6184d7b9d259
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — B1 mandatory transaction runner

Introduce `withTransaction` in `server/lib/db` — acquire once, begin/commit/rollback/release once; preserve original error if rollback fails. Unit tests with mock client.

### Phase 2 — B2 deleteAllPetData single-client refactor

Refactor `deleteAllPetData` to use checked-out `PoolClient` for all DB steps. PostgreSQL integration test proves rollback; update characterization test to target contract.

### Phase 3 — B3 stable committed command results

Separate pre-commit failures from post-commit work in `completeWeightOccurrence` and `shareInviteService`; build authoritative result from transaction, not fallible post-commit reads.

### Phase 4 — B4 D1 passed-away notification DTO

Implement D1: `notification_sent` + delivery semantics; POST does not claim persistence; update api-reference and contract tests.
