---
name: babysit-plus
description: Autonomous PR operator — mandatory pre-PR critical self-review, triage review comments (must-fix / nits / ignore), apply fixes, track debt issues, CI retry loop, optional merge per frozen plan. Use during /execute-plan phases or when full autonomous PR hygiene is needed. Policy lives in docs/agent-efficiency/autonomous-pr-policy.md.
---

# Babysit+

Autonomous PR operator. Extends lightweight `/babysit` with mandatory triage, debt-issue tracking, CI budgets, and merge gates.

**Canonical policy (do not restate here):** `docs/agent-efficiency/autonomous-pr-policy.md`  
**Phase exit profiles:** `docs/agent-efficiency/phase-exit-checklists.md`  
**Labels / dedupe:** `docs/agent-efficiency/github-labels.md`  
**Lightweight sibling:** `.cursor/commands/babysit.md` — use plain babysit when debt tracking and merge automation are not required.

During `/execute-plan`, always use **/babysit-plus**, never plain babysit alone.

---

## Inputs

| Input | Required | Notes |
|-------|----------|-------|
| PR URL or branch | yes | `gh pr view` / `ManagePullRequest` |
| `merge_mode` | no | See §0 step 5 — explicit override; otherwise **`auto`** (standalone) or snapshot (execute-plan) |
| `plan_id` | when in execute-plan | For debt-issue dedupe keys |
| Phase snapshot | when in execute-plan | `merge_mode`, `exit_checklist`, `allowed_paths` |
| `approved_until` | when in execute-plan | Halt if past expiry |

---

## Pre-PR critical review (mandatory)

**Before** creating or opening the PR (first push + `ManagePullRequest create_pr`), perform a **critical self-review** of the full diff against the requirement. Do not treat this as a quick skim — actively look for problems.

1. **Correctness & impact** — Re-read the requirement; trace happy paths, edge cases, error handling, and regressions. Confirm behavior matches intent; flag anything that could surprise callers or break downstream flows.
2. **Risks** — Security (auth, input validation, data exposure), data integrity, migrations, API contract drift, concurrency, and operational impact (logs, metrics, rollback).
3. **Design quality** — Against existing codebase patterns, assess **robustness**, **maintainability**, and **testability**. Prefer the smallest change that meets the requirement; avoid drive-by refactors.
4. **Better solution check** — If a clearer pattern, safer abstraction, or simpler approach would satisfy the requirement with equal or less scope, **adopt it now** — adjust code and tests before opening the PR. Do not defer with "we'll fix in review."
5. **Verification** — Run `./scripts/pre-push-changed.sh` after any adjustments from this review.

Only after this review passes: commit, push, and create/update the PR. Then continue with §Workflow from step 0 (Preflight).

---

## Workflow

### 0. Preflight

1. **Proactive base sync** — rebase immediately when the base moved; do not wait for CI:
   ```bash
   ./scripts/babysit_sync_base.sh --pr <url> --push
   ```
   Re-run before every push, before the CI wait loop, and after long automatic-review polls. See autonomous-pr-policy §Proactive base sync.
2. If execute-plan: confirm control issue has `autonomous-approved`, not `autonomous-revoked`, and `approved_until` is in the future (`node scripts/execute_plan_runtime.js gate <plan_id> --labels ...`).
3. `gh pr view <url> --json state,isDraft,labels,headRefOid,baseRefName`
4. Stop if: `do-not-merge`, draft (when merge intended), revoked, or expired.
5. **Resolve effective `merge_mode`** (see autonomous-pr-policy §Merge modes):
   - **Execute-plan** (active phase snapshot): `phase.merge_mode` → else `default_merge_mode` from snapshot. Caller `merge_mode` input is ignored unless the run explicitly documents an override.
   - **Standalone** (no snapshot): caller `merge_mode` input if provided → else **`auto`**.

### 0b. Ready for review + wait for automatic reviews (mandatory)

Applies to **both** `/babysit` and `/babysit-plus`. Automatic reviewers run only after the PR is ready — not while draft.

1. If `isDraft`: `gh pr ready <url>` (or equivalent).
2. Poll until configured bot reviews land or the wait budget expires — **even when CI is already green** (reviews often arrive later).
   ```bash
   gh api repos/{owner}/{repo}/pulls/{n}/reviews
   gh api repos/{owner}/{repo}/pulls/{n}/comments
   gh api repos/{owner}/{repo}/issues/{n}/comments
   ```
   (`{n}` = PR number; PRs are issues in the GitHub API. Conversation comments catch bot feedback that never creates a formal review.)
3. Poll every **30–60s** for up to **15 minutes**. Track which bots have submitted (`copilot`, `bugbot`, etc.).
4. Do **not** triage, merge, or declare done while expected automatic reviews are still pending.
5. On timeout: comment on the PR listing pending reviewers and **halt** — do not skip review triage.
6. After each push that changes the diff, repeat this step when new automatic reviews are expected.

### 1. Sync and conflicts

Same as `/babysit`: resolve merge conflicts preserving intent; escalate if intents conflict.

### 2. Triage (mandatory before fixes)

Post a **triage comment** on the PR summarizing every active unresolved thread:

| Bucket | Action |
|--------|--------|
| **Must-fix** | Fix in this PR |
| **Nits** | Fix if local + low-risk; else debt issue |
| **Ignore** | No code; debt issue if valid concern deferred |

Rules: see autonomous-pr-policy §Review triage. **Never ignore** blocker / critical / high / must signals. Low confidence → halt and ask human.

Template:

```markdown
## Babysit+ triage

| Thread | Bucket | Action |
|--------|--------|--------|
| … | must-fix / nit / ignore | fix in PR / debt issue #… / no change |

Deferred items will be tracked per autonomous-pr-policy §Debt issues.
```

### 3. Apply fixes

- Must-fix items first.
- Nits in touched files when safe per policy heuristics.
- Run `./scripts/pre-push-changed.sh` after each logical batch.
- Never weaken CI gates to pass.

### 4. Debt issues

For every **ignore** and every **skipped nit**:

1. Compute dedupe key per policy (`plan_id + pr_number + file_path + normalized_concern`).
2. Search existing issues (`label:review-follow-up label:tech-debt`).
3. Comment on match or create with labels `tech-debt`, `review-follow-up`, `plan:<id>` when applicable.
4. Batch ≥3 trivial nits same file/reviewer/PR into one issue.
5. On failure → `status: blocked`, `status_reason: issue_create_failed` (execute-plan).

**When you start work on a debt issue** (same session or later), comment and add `busy`:

```bash
node scripts/github_issue_workflow.js start-work --issue <n> --body "Addressing deferred review item from PR #…"
```

Deferred debt issues that are not being worked yet need no label.

### 5. CI loop

| Failure type | Max iterations |
|--------------|----------------|
| Caused by this PR | 5 |
| Flaky / unrelated (after rebase on latest base) | 3 |

1. **Before watching CI:** `./scripts/babysit_sync_base.sh --pr <url> --push` — if the base moved while you were fixing or polling reviews, rebase now instead of waiting for a failure.
2. Push fixes; watch CI (`ManagePullRequest get_ci_status` or `gh pr checks`).
3. Rebase on latest base before counting unrelated failures (`babysit_sync_base.sh` or manual rebase).
4. Exhaust budget → halt; comment on PR + control issue.

### 6. Exit checklist

When execute-plan phase declares `exit_checklist`, run every applicable item in `docs/agent-efficiency/phase-exit-checklists.md` before merge step.

Always before merge attempt: `./scripts/pre-push.sh` green locally.

### 7. Merge (optional — per `merge_mode`)

Precedence and gates: autonomous-pr-policy §Merge modes + §Merge gates.

**Default:** standalone babysit-plus (no execute-plan snapshot) uses **`auto`** — merge when all gates pass unless the caller overrides `merge_mode`.

| `merge_mode` | Agent may merge when all gates pass? |
|--------------|--------------------------------------|
| `manual` | No — push only; human merges |
| `labeled` | Yes if `agent-merge-ok` label present |
| `auto` | Yes (default for ad-hoc babysit-plus) |

```bash
gh pr merge <url> --squash   # add --auto when using GitHub merge queue
gh pr view <url> --json state,mergedAt,mergeCommit
```

Verify merge commit is ancestor of `origin/<base_branch>` before execute-plan advances to next phase.

### 8. Post-merge UAT subagent (spawn and exit — main session never blocks)

When the PR merges to **`main`**, spawn a **UAT subagent** to own promotion through prod-ready. **The main agent must not block** on deploy polling — **spawn and continue immediately**.

**Trigger:** merge commit is on `origin/main` (spawn UAT babysit only on final merge to `main`, not integration-branch intermediate merges).

#### 8a. Main agent (after merge verified — spawn immediately)

1. Note merge SHA and PR number (`gh pr view <url> --json mergeCommit,number`).
2. Post PR comment: UAT babysit started for `<merge-sha>`.
3. **Spawn UAT subagent** (Task `generalPurpose` or dedicated session) with:
   ```bash
   ./scripts/agent-uat-babysit.sh \
     --merge <merge-sha> --pr <n> --pr-url <url> \
     --ref "plan:<plan_id> phase-<id>"
   ```
   Use `--ref "pr-<n>"` when not in execute-plan.
4. **Declare babysit-plus done for this PR** — advance to next phase or end session **without awaiting** the subagent.
5. **Do not spawn twice** for the same merge SHA if a lock is active (`/tmp/agatha-uat-babysit`).

**Forbidden in the main session:**

| Anti-pattern | Why |
|--------------|-----|
| Poll `gh run view` / `deploy-uat.yml` | Blocks next phase (~45–60 min) |
| `run_in_background: true` then `resume` / poll UAT subagent | Main session must not await UAT |
| `uat_queue_runtime.js enqueue` | Replaced by agent babysit (Jul 2026) |

**Allowed:** UAT subagent may block on E2E + deploy until green or retry cap — see [uat-agent-babysit.md](../../../docs/e2e/uat-agent-babysit.md).

#### 8b. Who owns UAT after spawn

| Layer | Owns |
|-------|------|
| **UAT subagent** | Full localhost E2E, promote dispatch, deploy wait, remedial PRs (retry cap) |
| GitHub Actions | `promote-uat.yml` → `deploy-uat.yml` → `prod-ready` |
| **Next merge agent** | Heals blocking E2E on `main` if prior subagent died or hit retry cap |
| **Human** | [uat-promote-manual.md](../../../docs/e2e/uat-promote-manual.md) |

**Failure path:** subagent comments on PR; execute-plan does **not** halt. Next merge agent or human promotes.

**Infra-only blockers** (e.g. `UAT_AUTO_MIGRATE` off with pending migrations) → §9 Escalation (true halt; human required). Do not weaken gates.

### 9. Escalation (always halt)

See autonomous-pr-policy §Escalation. Includes security/crypto, breaking API, prod migrations, CI gate changes, product/legal, drift, CI budget exhausted, issue tracking failed, **UAT prod-ready blocked by infra config** (e.g. pending live migrations with `UAT_AUTO_MIGRATE` off).

---

## Related skills

| Skill | When |
|-------|------|
| `/pre-push-verify` | Before every push; full suite before merge |
| `/spawn-sprint-agents` | Parallel agents inside a phase (when snapshot allows) |
| `/execute-plan` | Multi-phase orchestrator — delegates PR hygiene here (default merge mode `auto`) |
