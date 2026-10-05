# notifications-v2-integration-7f3b

**Goal:** Single PR `cursor/notifications-v2-integration-7f3b` → `main` with `/babysit-uat`.

**base_branch:** `main`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-integration-7f3b` |
| **exit_checklist** | `bdd-journey`, `governance` |

**allowed_paths:** `**` (integration merge only — no drive-by features)

**Scope:**

- [ ] Rebase integration on `main`; resolve conflicts
- [ ] `./scripts/pre-push.sh`
- [ ] Open PR integration → `main`
- [ ] `/babysit-uat` until pre-UAT green on merge SHA
- [ ] `complete-plan` on roadmap after merge

**Exit:** Integration merged to `main`; notifications v2 programme complete through PR7.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-integration-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-integration-7f3b
  plan_path: .agents/plans/notifications-v2-integration-7f3b.md
  plan_commit: 93308603b79487f1d205882c5539fb7ea68bcb4c
  snapshot_path: .agents/plans/notifications-v2-integration-7f3b.snapshot.json
  snapshot_commit: 93308603b79487f1d205882c5539fb7ea68bcb4c
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
