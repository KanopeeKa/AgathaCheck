# UAT queue PR-keyed enqueue fallback

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `uat-queue-pr-fallback-2936` |
| **title** | PR-keyed UAT ledger enqueue when merge PR has no linked issue |
| **author** | cloud-agent |
| **created** | 2026-07-25 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Integration→main merge PRs (e.g. #361) often omit `Closes #n`, so merge-handler and deploy-sync skipped UAT ledger enqueue. Coordinator dispatch then saw `no_failed_head_entry` and infra WAF failures were never escalated on #313. This plan hardens enqueue/deploy-sync to key on PR number, backfills the missed `uat-260725-361` entry, and posts the infra escalation on the coordination issue.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-25T16:20:00Z |
| **approved_until** | 2026-07-27T16:20:00Z |
| **control_issue** | #363 |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous uat-queue-pr-fallback-2936` (standing grant from user chat 2026-07-25)

## Phases

### Phase 1 — PR-keyed enqueue fallback + #313 backfill

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/uat-queue-pr-fallback-2936` |
| **merge_mode** | `auto` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.github/scripts/issue-agent-handlers.js
.github/scripts/issue-agent-handlers.test.js
scripts/lib/uat_queue_apply.js
scripts/lib/uat_queue_lib.js
scripts/lib/uat_deploy_run_resolve.js
scripts/uat_deploy_run_resolve.test.js
scripts/uat_queue_apply.test.js
```

**Scope:**

- Merge handler: enqueue UAT ledger even when PR has no linked issues (`enqueuedBy: pr-<n>`)
- Deploy sync: backfill missing ledger entry from UAT tag + merge SHA before applying deploy result
- UAT result handler: post success/failure on coordination issue when no product issue linked
- Retroactive: backfill seq for PR #361 / `uat-260725-361` + infra escalation comment on #313

**Exit criteria:**

- [ ] Unit tests for enqueue fallback paths
- [ ] #313 ledger records PR #361 deploy as `infra_failed`
- [ ] Escalation comment posted on #313 for WAF blocker
- [ ] `./scripts/pre-push-changed.sh` green

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: implement phase 1 on cursor/uat-queue-pr-fallback-2936
```
