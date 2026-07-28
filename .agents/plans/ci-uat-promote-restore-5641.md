# Plan — CI-driven UAT promote restore

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ci-uat-promote-restore-5641` |
| **title** | Restore merge → Pre-UAT E2E → promote → deploy (HEAD throttle) |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |

## Goal

Every merge to `main` triggers async Pre-UAT E2E. Green E2E at current `origin/main` HEAD auto-promotes via `promote-uat.yml` → `deploy-uat`. Remove agent UAT subagent as default path. Delete deprecated coordinator/queue workflows.

Standing grant: user chat 2026-07-28 — CI owns promotion; babysit+ fixes E2E only.

## Phases

### Phase 1 — Workflow restore

- `pre-uat-e2e.yml`: `push: main` + `workflow_dispatch`
- `promote-uat.yml`: `workflow_run` on Pre-UAT success + manual dispatch; no queue hold job
- Delete `uat-coordinator-dispatch.yml`, `uat-queue-health.yml`

### Phase 2 — Docs and skills sync

- `uat-deploy-tiers`, `ci-cd-gates`, `promotion-contract`, `e2e/README`, `uat-agent-babysit` (manual fallback)
- Remove babysit+ §8 UAT subagent spawn; execute-plan post-merge spawn removed
- `agent-uat-babysit.sh` header → manual ops only

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/ci-uat-promote-restore-5641"
artifact_ref:
  branch: cursor/ci-uat-promote-restore-5641
  plan_path: .agents/plans/ci-uat-promote-restore-5641.md
  plan_commit: 077d2d8263370c818377c2eb94efe2a6deecdf1d
  snapshot_path: .agents/plans/ci-uat-promote-restore-5641.snapshot.json
  snapshot_commit: 077d2d8263370c818377c2eb94efe2a6deecdf1d
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
