---
title: Uat Coordinator Bootstrap
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [agent-efficiency, policy]
---
# UAT coordinator bootstrap (Phase 1b)

**Outcome:** The deploy queue ledger is live — merges enqueue entries and `health-check` passes.

Until bootstrap completes, `uat_queue_runtime.js enqueue` returns `skipped: true` and coordination is a no-op.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| `GH_TOKEN` / `GITHUB_TOKEN` | `issues:write` for issue + marker comment |
| Repo admin (one-time) | `actions:write` to set `UAT_COORDINATION_ISSUE` variable |
| `gh` CLI | Authenticated to the repo |

---

## Automated bootstrap

```bash
# Create/update issue, pin, post empty ledger marker, run health-check
node scripts/uat_coordinator_bootstrap.js --write --pin
```

Then set the repo variable (agent tokens often lack this permission):

```bash
gh variable set UAT_COORDINATION_ISSUE --body "<issue_number>" --repo KanopeeKa/AgathaCheck
```

Verify:

```bash
export UAT_COORDINATION_ISSUE=<issue_number>
node scripts/uat_queue_runtime.js health-check
node scripts/uat_queue_runtime.js status
```

---

## Verify merge enqueue

After the variable is set, the next merge to `main` should log in **Agent PR merge handler**:

```
UAT queue: enqueued PR #<n> merge <sha> on issue #<coordination>
```

To backfill a recent merge manually:

```bash
node scripts/uat_queue_runtime.js enqueue \
  --merge <merge_sha> --pr <pr_number> --ref "pr-<pr_number>" --write
```

---

## Smoke checklist

- [ ] Issue `[uat-coordinator] UAT deploy queue` exists, pinned, labels `uat-coordinator` + `governance`
- [ ] Marker comment `<!-- uat-queue-state:v1 -->` present on the issue
- [ ] `UAT_COORDINATION_ISSUE` repo Actions variable equals issue number
- [ ] `health-check` exits 0 locally and in CI (when wired)
- [ ] Merge handler enqueue log shows `enqueued`, not `skipped`

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `coordination issue not configured` | Set `UAT_COORDINATION_ISSUE` or pass `--issue` |
| `health-check` fails on marker | Run bootstrap with `--write` to create marker |
| Merge handler still `skipped` | Confirm repo variable visible in workflow logs (not empty) |
| `403` on `gh variable set` | Human operator with admin must set the variable |

---

## Next phases

After bootstrap: Phase 3 (coordinator dispatch + skill), Phase 3b (promote hold / deploy back-pressure). See [uat-coordinator-plan.md](./uat-coordinator-plan.md).
