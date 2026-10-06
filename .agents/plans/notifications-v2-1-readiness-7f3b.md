---
title: Notifications v2.1 readiness (Plans A–D)
owner: Agent
audience: both
status: active
last_updated: 2026-10-06
tags: [execute-plan, notifications]
---

# Notifications v2.1 readiness

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `notifications-v2-1-readiness-7f3b` |
| **title** | Notifications v2.1 — P0 remediation + household + suggestions + BDD |
| **created** | 2026-10-06 |
| **base_branch** | `cursor/notifications-v2-1-readiness-integration-7f3b` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Close the audit gaps blocking “done” on Notifications v2: Plan A (P0 inbox/care attention/settings/spec), Plan B (household relationship events), Plan C (suggestions wave 1), Plan D (real BDD + migration fixtures). All phase PRs merge to the integration branch; one final PR to `main` with pre-UAT.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | (snapshot) |
| **approved_until** | `approved_at + 48h` |
| **control_issue** | (snapshot) |
| **grant** | User chat 2026-10-06 — build plan + `/execute-plan` with integration branch and full autonomy through all phases |

## Phases

### Phase 1 — Plan A (P0 remediation)

**branch:** `cursor/notifications-v2-1-plan-a-7f3b`

- Actions tab badge: overdue + due today, muted pets excluded, shared logic with Care Actions list
- `needsResponse` decoupled from `is_read`; bell count includes unresolved needs-response when read
- Tab-scoped mark-all-read (Activity vs For you)
- Hide/disable push matrix toggles (transport not shipped); honest FAQ copy
- Legacy sign-in device bootstrap + one-time device-security intro
- Spec rev 2.4 with as-built vs intended (FR-CR-2)

### Phase 2 — Plan B (household & access events)

**branch:** `cursor/notifications-v2-1-plan-b-7f3b`

Emitters R5, R9–R12, R16; inbox copy; tests per emitter.

### Phase 3 — Plan C (suggestions wave 1)

**branch:** `cursor/notifications-v2-1-plan-c-7f3b`

Scheduler, S1/S2, limits/suppression, honest suggestion copy.

### Phase 4 — Plan D (BDD & fixtures)

**branch:** `cursor/notifications-v2-1-plan-d-7f3b`

Replace placeholder BDD rows; migration fixtures; Playwright pre-UAT coverage for v2 behaviour.

### Phase 5 — Integration → main

**branch:** `cursor/notifications-v2-1-readiness-integration-7f3b`

Single squash PR integration → `main`; `/babysit-uat`.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: babysit+ phase 1 PR
artifact_ref:
  branch: cursor/notifications-v2-1-plan-a-7f3b
  plan_path: .agents/plans/notifications-v2-1-readiness-7f3b.md
  plan_commit: pending
  snapshot_path: .agents/plans/notifications-v2-1-readiness-7f3b.snapshot.json
  snapshot_commit: pending
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
