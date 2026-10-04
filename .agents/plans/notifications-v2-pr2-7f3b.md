# notifications-v2-pr2-7f3b

**Goal:** Spec PR2 — two-tab inbox, calm badge, explainer, FAQ Appendix A in l10n.

**base_branch:** `cursor/notifications-v2-integration-7f3b`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-pr2-7f3b` |
| **exit_checklist** | `flutter-screen-split`, `bdd-journey` |

**allowed_paths:** `flutter_app/lib/features/notifications/presentation/**`, `flutter_app/test/features/notifications/**`, `flutter_app/lib/l10n/**`, `flutter_app/test/bdd/features/notifications_v2.feature`, `server/routes/**/notification*`, `server/test/notifications/**` (badge endpoint if new)

**Scope:** Shared tab widget for panel + screen; remove chips; §5.4 badge; explainer pref; AC-IN-*, AC-BG-*; split panel per spec size watch.

**Exit:** PR merged to integration; widget tests + BDD extended.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-pr2-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-pr2-7f3b
  plan_path: .agents/plans/notifications-v2-pr2-7f3b.md
  plan_commit: 71af0b42fd317c044dc0ab4810400a3352840af1
  snapshot_path: .agents/plans/notifications-v2-pr2-7f3b.snapshot.json
  snapshot_commit: 71af0b42fd317c044dc0ab4810400a3352840af1
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
