# notifications-v2-pr3-7f3b

**Goal:** Spec PR3 — relationship emitters, §3.4 type map, `shareLinkFollowed`, ban `general`.

**base_branch:** `cursor/notifications-v2-integration-7f3b`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-pr3-7f3b` |
| **exit_checklist** | `single-backend-route`, `bdd-journey` |

**allowed_paths:** `server/services/sharing/**`, `server/lib/households/**`, `server/lib/petDataLifecycle.js`, `server/routes/pets/transferRouter.js`, `server/routes/organizations/**`, `server/routes/fosterPlacements.js`, `server/lib/notificationKind.js`, `server/lib/notificationHelper.js`, `server/test/**`, `flutter_app/lib/features/notifications/**` (navigation/copy only if needed)

**Scope:** R1–R12, R14–R17 emitters; explicit types; AC-AC-16 guard; privacy FR-PR-*; co-parent suggestion recipients unchanged until PR5.

**Exit:** AC-AC-*, AC-PR-*; PR merged to integration.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-pr3-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-pr3-7f3b
  plan_path: .agents/plans/notifications-v2-pr3-7f3b.md
  plan_commit: ca1de3e24241835415c3e8204b5c7d6f2acbb91b
  snapshot_path: .agents/plans/notifications-v2-pr3-7f3b.snapshot.json
  snapshot_commit: ca1de3e24241835415c3e8204b5c7d6f2acbb91b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
