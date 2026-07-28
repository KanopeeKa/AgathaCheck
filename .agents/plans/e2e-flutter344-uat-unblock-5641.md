# Plan — E2E Flutter 3.44 UAT unblock

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `e2e-flutter344-uat-unblock-5641` |
| **title** | Restore 11-shard localhost E2E after Flutter 3.44 semantics drift |
| **author** | cloud-agent |
| **created** | 2026-07-28 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

PR #497 upgraded Flutter to 3.44; seven Playwright shards fail because semantics roles changed (button → checkbox/tab, group labels merged). Fix page-object fallbacks so the full 11-shard gate passes locally, then unblock UAT promote via agent babysit.

Standing grant: user chat "go ahead with the plan and sequenced suggestions /execute-plan" (2026-07-28).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-28T12:40:00Z |
| **approved_until** | 2026-07-30T12:40:00Z |
| **control_issue** | TBD |
| **content_hash** | TBD |
| **autonomy** | `active` |

## Phases

### Phase 1 — E2E semantics fallbacks

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/e2e-flutter344-uat-unblock-5641` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
e2e/playwright/**
docs/e2e-navigation-contract.md
.agents/plans/e2e-flutter344-uat-unblock-5641.*
```

**Scope:**

- `semanticsByName` / `dashboardSectionGroup` checkbox+tab fallbacks
- MyDetails, OrganizationDetail, PetDetail, Notifications page objects
- Navigation contract doc for Flutter 3.44

**Exit criteria:**

- [ ] All 11 localhost E2E shards green on branch
- [ ] `./scripts/pre-push-changed.sh` passes

### Phase 2 — Babysit hygiene

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/e2e-babysit-retry-hygiene-5641` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
scripts/agent-uat-babysit.sh
docs/e2e/uat-agent-babysit.md
.agents/plans/e2e-flutter344-uat-unblock-5641.*
```

**Scope:**

- Default `UAT_BABYSIT_MAX_ATTEMPTS=1` until remedial-PR loop exists
- Document retry behaviour

**Exit criteria:**

- [ ] Babysit script merged; UAT subagent spawned post phase-1 merge

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/e2e-flutter344-uat-unblock-5641"
artifact_ref:
  branch: cursor/e2e-flutter344-uat-unblock-5641
  plan_path: .agents/plans/e2e-flutter344-uat-unblock-5641.md
  plan_commit: 77f88ef7947089554ac96f5d2a77b2e0269604b1
  snapshot_path: .agents/plans/e2e-flutter344-uat-unblock-5641.snapshot.json
  snapshot_commit: 77f88ef7947089554ac96f5d2a77b2e0269604b1
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
