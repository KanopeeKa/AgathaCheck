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
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/notifications-v2-integration-7f3b
  plan_path: .agents/plans/notifications-v2-integration-7f3b.md
  plan_commit: 1faa2589e00bcff43deb77b93c7f8601a4336d37
  snapshot_path: .agents/plans/notifications-v2-integration-7f3b.snapshot.json
  snapshot_commit: 1faa2589e00bcff43deb77b93c7f8601a4336d37
open_prs: []
merge_commits: {"1":"57f7152cace37d7e319700ddcac74fcaa5ae835b"}
debt_issue_refs: []
```
