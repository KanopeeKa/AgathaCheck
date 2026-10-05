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
next_action: "babysit-uat PR #1617"
artifact_ref:
  branch: cursor/notifications-v2-integration-7f3b
  plan_path: .agents/plans/notifications-v2-integration-7f3b.md
  plan_commit: 243ce37d01337a149db7d5c7b6de1925672acaec
  snapshot_path: .agents/plans/notifications-v2-integration-7f3b.snapshot.json
  snapshot_commit: 243ce37d01337a149db7d5c7b6de1925672acaec
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1617"]
merge_commits: {}
debt_issue_refs: []
```
