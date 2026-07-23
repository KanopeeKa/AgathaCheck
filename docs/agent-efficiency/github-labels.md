# GitHub labels — autonomous workflows

Labels for `/execute-plan`, `/babysit-plus`, and debt tracking. Create in repo settings if missing (document-only in Phase A).

---

## Plan control issue

| Label | Purpose |
|-------|---------|
| `execute-plan` | Marks plan control issues |
| `plan:<plan_id>` | e.g. `plan:foster-card-split` |
| `autonomous-approved` | Autonomy granted; agent may run |
| `autonomous-revoked` | Halt — remove `autonomous-approved` when revoking |
| `autonomous-resumed` | Optional — human acknowledged resume |

### Control issue title

```
[execute-plan] <plan_id>
```

### Control issue body (template)

```markdown
## Plan
- **ID:** <plan_id>
- **Snapshot:** `.agents/plans/<plan_id>.snapshot.json`
- **Content hash:** sha256:…
- **Approved until:** <ISO-8601 UTC> (48h default)

## Phases
| ID | Title | Merge mode | Status |
|----|-------|------------|--------|
| 1 | … | auto | pending |

## Revoke
Add label `autonomous-revoked` (halt only — does not close PRs).

## Resume
Remove revoke label; comment `resume-plan <plan_id>`.
```

---

## Pull request labels

| Label | Purpose |
|-------|---------|
| `agent-merge-ok` | Required for `labeled` merge mode |
| `do-not-merge` | Babysit+ and execute-plan skip merge |
| `snag` | Optional — trivial follow-up micro-PR (see [atomic-pr-policy.md](./atomic-pr-policy.md)) |

---

## Debt / review follow-up issues

| Label | Purpose |
|-------|---------|
| `tech-debt` | Deferred improvement |
| `review-follow-up` | Originated from PR review triage |
| `plan:<plan_id>` | Links to execute-plan run |

### Issue title format

```
[tech-debt] <short description> (plan:<plan_id> phase:<n>)
```

Batched nits:

```
[tech-debt] Nits in <file> (PR #<n>)
```

---

## Dedupe search

Before creating a debt issue:

```bash
gh issue list --label "review-follow-up" --label "tech-debt" --search "<plan_id> <file_path>" --state all --limit 20
```

Match on dedupe key (see [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Debt issues). Comment on existing issue if key matches.

---

## Comment keywords (control issue)

| Comment | Meaning |
|---------|---------|
| `approve-autonomous <plan_id>` | (Usually in agent chat) Grants autonomy |
| `resume-plan <plan_id>` | Human acknowledges resume |
| `accept-head` | Acknowledge PR force-push; agent may update `pr_head_sha` |

---

## Project status (control issue)

Per `docs/github-issue-workflow.md`. Debt issues created during babysit+ stay in **Backlog** until separately picked up (then `start-work`).

| Stage | Project status |
|-------|----------------|
| `init-control-issue` / `gh issue create` | **Backlog** |
| First work session after `gate` passes | **In Progress** (`set-project-status`) |
| `complete-plan --write` (all phases merged) | **Done** + issue closed |

**Agent CLI helpers:**

```bash
node scripts/execute_plan_runtime.js set-project-status <plan_id> --status "In Progress"
node scripts/github_issue_workflow.js start-work --issue <n> --body "…"
node scripts/github_issue_workflow.js comment --issue <n> --body "…"
```

Pause/halt/complete: prefer `--post-comment` on `pause`, `halt`, `resume-uat`, and `complete-plan`.
