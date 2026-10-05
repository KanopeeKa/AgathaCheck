# notifications-v2-pr6-7f3b

**Goal:** Spec PR6 — settings matrix (core); digest/email (enhancement).

**base_branch:** `cursor/notifications-v2-integration-7f3b`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-pr6-7f3b` |
| **exit_checklist** | `single-backend-route`, `flutter-screen-split`, `bdd-journey` |

**allowed_paths:** `flutter_app/lib/features/notifications/presentation/screens/notification_settings*`, `server/routes/**/notification*`, `server/lib/**notification*`, `server/test/**`, `flutter_app/test/**`, `flutter_app/test/bdd/features/notifications_v2.feature`

**Scope:** FR-SE-*, FR-MD-*, FR-DG-* (enhancement cut if slip); delete `@legacy` BDD scenarios per spec §12.

**Exit:** AC-SE-*, AC-DG-* (subset if enhancements cut); PR merged to integration.

**Debt (PR7):** Weekly digest job (FR-DG-1..5) and relationship push/email enforcement at emit time (AC-SE-3/4/9 delivery) deferred — matrix persistence and Agatha generation gate land in PR6.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-pr6-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-pr6-7f3b
  plan_path: .agents/plans/notifications-v2-pr6-7f3b.md
  plan_commit: 332770c9d35eaca17c5a754da92bd44d5a59b05c
  snapshot_path: .agents/plans/notifications-v2-pr6-7f3b.snapshot.json
  snapshot_commit: 332770c9d35eaca17c5a754da92bd44d5a59b05c
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
