# Notifications v2.1 closeout (UAT remediation)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `notifications-v2-1-closeout-7f3b` |
| **title** | Notifications v2.1 UAT closeout |
| **base_branch** | `cursor/notifications-v2-1-closeout-integration-7f3b` |
| **default_merge_mode** | `auto` |

## Goal

Close UAT gaps from #1715: fix P0 resolve/needs-response bell regression, wire S1/S2 generation, FR-FB-2/3 not-relevant, compulsory relationship emails, regression tests + spec housekeeping, merge to `main` with pre-UAT.

## Canonical docs

- `docs/domains/notifications/features/notifications-v2-spec.md`

## Phases

### Phase 1 — Resolve + actionability (P0)
### Phase 2 — Suggestion scheduler + not-relevant suppression
### Phase 3 — Compulsory relationship emails
### Phase 4 — Tests, e2e, spec housekeeping
### Phase 5 — Integration → main + pre-UAT

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 5
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/notifications-v2-1-closeout-7f3b.md
  plan_commit: d6a6219043209edad329a74a124d9874710a95ab
  snapshot_path: .agents/plans/notifications-v2-1-closeout-7f3b.snapshot.json
  snapshot_commit: d6a6219043209edad329a74a124d9874710a95ab
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
