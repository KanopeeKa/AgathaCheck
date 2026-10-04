# Child F — Care Item module (`care-item-module-c1a7`)

Parent: `.agents/plans/care-next-occurrence-c1a7.md` §10, child F §795–804.

**Starts after child E merges to integration.** Same integration branch line; lands with E in one 5b PR to `main`.

## Phases

| id | Scope | exit_checklist |
|----|--------|----------------|
| F1 | Move files into `features/care_item/`; barrel | `flutter-screen-split` |
| F2 | Delete dead code + compat routes | `flutter-screen-split` + `single-backend-route` |
| F3 | `check_care_item_boundary.sh` in pre-push | `governance` |
| F4 | Server `lib/care/*` consolidation | `single-backend-route` |
| F5 | Architecture index entry | `governance` |
| F6 | Full E2E regression + BDD gate | `bdd-journey` |

## Runtime state

```yaml
autonomy: active
current_phase: F2
last_completed_phase: F1
halt_reason: null
next_action: "continue phase F2 on branch cursor/care-f2-compat-delete-50b4"
artifact_ref:
  branch: claude/eager-edison-mf34j6
  plan_path: .agents/plans/care-item-module-c1a7.md
  plan_commit: 038123763257877a51498f9f9fa16fd1ee435c54
  snapshot_path: .agents/plans/care-item-module-c1a7.snapshot.json
  snapshot_commit: 038123763257877a51498f9f9fa16fd1ee435c54
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
