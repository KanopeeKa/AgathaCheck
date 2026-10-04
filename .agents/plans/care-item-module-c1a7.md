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
current_phase: F5
last_completed_phase: F4
halt_reason: null
next_action: "continue phase F5 on branch cursor/care-f5-arch-index-50b4"
artifact_ref:
  branch: cursor/care-f5-arch-index-50b4
  plan_path: .agents/plans/care-item-module-c1a7.md
  plan_commit: 552bd7b8e6baaff9c5b79218d0868154492465e6
  snapshot_path: .agents/plans/care-item-module-c1a7.snapshot.json
  snapshot_commit: 552bd7b8e6baaff9c5b79218d0868154492465e6
open_prs: []
merge_commits:
  F2: fce0ce1e2146550fc085a00364693c9aa7c985f8
  F3: 83759d37b905ed8c22cbb28d56d978d4a33b7d53
  F4: 9850c118d5c7929056db1f779fbe0b5229e6942b
debt_issue_refs: []
```
