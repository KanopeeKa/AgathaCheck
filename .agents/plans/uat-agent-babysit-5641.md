# UAT agent babysit simplification

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `uat-agent-babysit-5641` |
| **title** | Replace UAT coordinator with per-merge agent babysit |
| **author** | cloud-agent |
| **created** | 2026-07-27 |
| **base_branch** | `cursor/uat-agent-babysit-integration-5641` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Remove the blocking Pre-UAT CI gate, UAT coordinator, and queue ledger from the promotion path. After merge to `main`, the merge agent spawns a UAT subagent that runs full localhost E2E, tags, triggers deploy, and owns remedial fixes until UAT HTTP smoke is green (retry cap). Humans retain manual tag + `deploy-uat` dispatch as fallback.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-27T22:55:00Z |
| **approved_until** | 2026-07-29T22:55:00Z |
| **control_issue** | TBD |
| **autonomy** | `active` |

**Grant:** user chat — "go ahead implement as a plan then /execute-plan"

## Phases

### Phase 1 — Docs + babysit contract

**id:** `1` · **branch:** `cursor/uat-agent-babysit-docs-5641`

- `docs/e2e/uat-agent-babysit.md` — subagent contract, retry cap, PR comments
- `docs/e2e/uat-promote-manual.md` — human E2E optional, manual tag, workflow_dispatch
- Update `docs/e2e/uat-deploy-tiers.md` pipeline overview

### Phase 2 — Agent babysit script

**id:** `2` · **branch:** `cursor/uat-agent-babysit-script-5641`

- `scripts/agent-uat-babysit.sh` — E2E → promote dispatch → deploy wait
- `scripts/ci/trigger-promote-uat.sh` — `gh workflow run` helper

### Phase 3 — Workflow cutover

**id:** `3` · **branch:** `cursor/uat-agent-babysit-workflows-5641`

- `pre-uat-e2e.yml` — remove `push: main` (keep `workflow_dispatch` for ops)
- `promote-uat.yml` — `workflow_dispatch` with `commit_sha` + `pr_number`; drop ledger hold
- Disable `uat-coordinator-dispatch.yml`, `uat-queue-health.yml`

### Phase 4 — Skills and policy sync

**id:** `4` · **branch:** `cursor/uat-agent-babysit-skills-5641`

- `babysit-plus` §8 — spawn UAT subagent (fire-and-forget)
- `execute-plan` — remove barrier-check / enqueue; UAT subagent spawn after merge
- `autonomous-pr-policy`, `ci-cd-gates`, `promotion-contract`, `e2e/README.md`
- Mark `uat-coordinator` skill deprecated

## Runtime state

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
```
