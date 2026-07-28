# Manual UAT promote and deploy

Human fallback when agent UAT babysit is unavailable, hit retry cap, or subagent died before remedial work.

**Related:** [uat-agent-babysit.md](./uat-agent-babysit.md) · [promotion-contract.md](../promotion-contract.md)

---

## When to use

| Situation | Action |
|-----------|--------|
| Agent subagent died after merge | Manual promote below |
| E2E drift with no active merges | Run E2E locally (optional), then promote |
| Retry cap exhausted on PR | Human triage + remedial or manual promote |
| Emergency hotfix | Manual promote after your own verification |

---

## Option A — workflow_dispatch (recommended)

### 1. Confirm target commit

```bash
git fetch origin main
COMMIT=$(git rev-parse origin/main)
PR=$(gh pr list --state merged --base main --limit 1 --json number -q '.[0].number')
echo "main HEAD: $COMMIT  last merged PR: $PR"
```

### 2. (Optional) Full localhost E2E

```bash
git checkout "$COMMIT"
./e2e/scripts/run-local.sh
# Or all shards: for i in $(seq 1 11); do (cd e2e && npm run test:ci-shard -- $i) || exit 1; done
```

### 3. Promote (create tag)

```bash
./scripts/ci/trigger-promote-uat.sh --commit "$COMMIT" --pr "$PR"
```

Or via GitHub UI: **Actions → Promote UAT → Run workflow** with `commit_sha` and `pr_number`.

### 4. Deploy

`deploy-uat.yml` runs automatically via `workflow_run` after promote succeeds.

If needed manually: **Actions → Deploy UAT → Run workflow** with `deploy_ref` = `uat-YYMMDD-PR#`.

### 5. Verify

```bash
./scripts/ci/wait-uat-deploy.sh --tag "uat-$(date -u +%y%m%d)-${PR}"
# Or check Actions → Deploy UAT → Prod ready job
```

---

## Option B — local tag push

Requires a token with `contents: write` (PAT — `GITHUB_TOKEN` from Actions cannot chain tag workflows reliably).

```bash
COMMIT_SHA=<merge-sha>
PR_NUMBER=<n>
export PR_NUMBER COMMIT_SHA GITHUB_REPOSITORY GITHUB_TOKEN
bash scripts/ci/promote-uat-tag.sh
gh workflow run deploy-uat.yml -f deploy_ref="uat-$(date -u +%y%m%d)-${PR_NUMBER}"
```

---

## Tag format

`uat-YYMMDD-PR#` — see [promotion-contract.md](../promotion-contract.md).

Example: `uat-260727-481` for PR #481 merged on 2026-07-27.

---

## What was removed

- Blocking `pre-uat-e2e.yml` on every `main` push (now manual/advisory only)
- UAT coordinator dispatch and queue ledger promote hold
- `uat_queue_runtime.js enqueue` after merge (removed — CI Pre-UAT owns promotion)

Pre-UAT E2E remains available as **workflow_dispatch** for ops replay.
