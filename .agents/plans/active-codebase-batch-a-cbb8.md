---
title: Active codebase Batch A — Protect
owner: Agent
audience: agent
status: active
---

# active-codebase-batch-a-cbb8

## Goal

Execute **Batch A — Protect** from the accepted [active codebase architecture review](docs/architecture/reviews/active-codebase-review.md): publish the charter, add characterization baseline/tests (A1), gate frozen org-transfer routes (A2), and manifest-driven boundary checking (A3).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-22T14:40:00Z |
| **approved_until** | 2026-09-24T14:40:00Z |
| **control_issue** | TBD |
| **autonomy** | active |

Standing grant: user chat 2026-09-22 — agreed D1–D7 decisions; `/execute-plan` autonomous implementation.

## Programme reference

`docs/architecture/reviews/active-codebase-review.md` — Accepted decisions, delivery batches A→B→C.

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 4
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/active-codebase-batch-a-cbb8.md
  plan_commit: 2b2f690f07f65f2ea469a784c15128d9bb70b3a0
  snapshot_path: .agents/plans/active-codebase-batch-a-cbb8.snapshot.json
  snapshot_commit: 2b2f690f07f65f2ea469a784c15128d9bb70b3a0
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Publish architecture charter

Merge docs PR with accepted review, metrics script, and index link.

### Phase 2 — A1 characterization baseline

Command matrix artifact, baseline inventory, focused characterization tests for P1 failure paths (no behavior fixes).

### Phase 3 — A2 frozen route registration gate

Unregister `transfer-to-org` when frozen domains off; preserve individual `/:id/transfer` and permitted family-history reads.

### Phase 4 — A3 manifest-driven boundary checker

Rewrite `check_frozen_domain_boundaries.sh` to consume `manifest.json`; add fixture tests.
