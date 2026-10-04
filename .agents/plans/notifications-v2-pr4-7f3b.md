# notifications-v2-pr4-7f3b

**Goal:** Spec PR4 — inline actions (core); grouping + invite expiry (enhancement tier).

**base_branch:** `cursor/notifications-v2-integration-7f3b`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-pr4-7f3b` |
| **exit_checklist** | `single-backend-route`, `flutter-screen-split`, `bdd-journey` |

**allowed_paths:** `server/routes/**/notification*`, `server/lib/**notification*`, `flutter_app/lib/features/notifications/**`, `flutter_app/test/**`, `e2e/playwright/tests/*notification*`, `flutter_app/test/bdd/features/notifications_v2.feature`

**Scope:**

- **Core:** Needs your response; FR-IA-1 invites + admin pending; FR-AR-5/6; stale handling FR-IA-5
- **Enhancement (defer if slip):** §6.4.1 grouping read API; R4/R18 scheduled jobs

**Exit:** AC-IA-*, core AC-GR; PR merged to integration.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-pr4-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-pr4-7f3b
  plan_path: .agents/plans/notifications-v2-pr4-7f3b.md
  plan_commit: 63007efa9fa094eb1ad45f78c396f1360e58613a
  snapshot_path: .agents/plans/notifications-v2-pr4-7f3b.snapshot.json
  snapshot_commit: 63007efa9fa094eb1ad45f78c396f1360e58613a
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1585"]
merge_commits: {}
debt_issue_refs: []
```
