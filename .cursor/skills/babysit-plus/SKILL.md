---
name: babysit-plus
description: Autonomous PR operator — triage review comments (must-fix / nits / ignore), apply fixes, track debt issues, CI retry loop, optional merge per frozen plan. Use during /execute-plan phases or when full autonomous PR hygiene is needed. Policy lives in docs/agent-efficiency/autonomous-pr-policy.md.
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

### 8. Post-merge UAT prod-ready (non-blocking sub-agent)

When the PR merges to `main`, UAT promotion starts (`promote-uat.yml` → `deploy-uat.yml`). **The main agent must not block** on this deploy poll — spawn a dedicated sub-agent immediately after merge verification.

**Trigger:** merge commit is on `origin/main` (or integration base) and UAT workflows are queued/running for that SHA.

#### 8a. Main agent (after merge verified — spawn immediately)

1. Note merge SHA (`gh pr view <url> --json mergeCommit`).
2. **Spawn UAT babysit sub-agent** (Task tool, `subagent_type: generalPurpose`, `run_in_background: true`):
   - **Inputs:** merge SHA, PR URL/number, `plan_id` + control issue URL when in execute-plan
   - **Prompt:** follow §8b below; on failure, pause main work at the next safe checkpoint (§8c)
3. Post a short PR/control-issue comment: UAT babysit sub-agent started for `<merge-sha>`; main work continues.
4. **Declare babysit-plus done for this PR** — main agent may advance (next execute-plan phase, next task, etc.) **without waiting** for prod-ready.
5. **Do not start another UAT sub-agent** for the same merge SHA unless the prior one exited after a remedial cycle.

#### 8b. UAT babysit sub-agent (owns poll + remedial loop until Prod ready)

1. Resolve tag + deploy run for the merge SHA:
   ```bash
   gh run list --workflow promote-uat.yml --limit 5
   gh run list --workflow deploy-uat.yml --limit 5
   gh run view <deploy-run-id>   # wait for Prod ready job
   ```
   Poll every **60–120s**. UAT full E2E can take **~45–60 min** (10 shards).
2. On **success:** comment on PR (+ control issue when `plan_id` set) that `prod-ready` is green; exit quietly — **do not interrupt** main work.
3. On **failure:** read `prod-ready` summary + failed shard logs (`scripts/ci/assert-uat-gates.sh` output); comment on PR + control issue with gate table; **pause main work** (not halt):
   - **Execute-plan:** checkpoint at next safe atomic step, then:
     ```bash
     node scripts/execute_plan_runtime.js pause <plan_id> \
       --reason uat_paused --detail "<gate summary>" --write --post-comment
     ```
   - **Standalone:** stop current work at checkpoint; comment the blocking issue with `**Needs you:**` when human input is required; sub-agent owns remedial flow below.
4. **Remedial loop (sub-agent owns end-to-end):** open remedial PR → babysit-plus §0–7 → merge → poll prod-ready for the new merge SHA (repeat §8b steps 1–3). Use the same CI retry budget as §5.
5. When remedial **prod-ready is green:** auto-resume main work (§8c) and exit quietly.

**Infra-only blockers** (e.g. `UAT_AUTO_MIGRATE` off with pending migrations) → §9 Escalation (true halt; human required). Do not weaken gates.

#### 8c. Pause and auto-resume (failure only)

- **Initial success (no failure):** no action required from main agent.
- **Pause:** main agent finishes the current safe atomic step, then **waits** — do not start new phases/commits until resumed. Snapshot `autonomy` stays `active`; only the in-progress phase is `halted` / `uat_paused`.
- **Auto-resume (sub-agent, after remedial prod-ready green):**
  ```bash
  node scripts/execute_plan_runtime.js resume-uat <plan_id> --write --post-comment
  ```
  Post the rendered resume comment on the control issue; **re-invoke main agent** (`/execute-plan <plan_id> resume` or continue the paused session) — **no human `resume-plan` comment required**.
- **True halt** only when auto-resume is impossible (§9 infra/legal/security). Use `halt` only if the run can restart without manual intervention; otherwise escalate.

Gate reference: `docs/ci-cd-gates.md` §3 · `scripts/ci/assert-uat-gates.sh`.

### 9. Escalation (always halt)

See autonomous-pr-policy §Escalation. Includes security/crypto, breaking API, prod migrations, CI gate changes, product/legal, drift, CI budget exhausted, issue tracking failed, **UAT prod-ready blocked by infra config** (e.g. pending live migrations with `UAT_AUTO_MIGRATE` off).

---

## Related skills

| Skill | When |
|-------|------|
| `/pre-push-verify` | Before every push; full suite before merge |
| `/spawn-sprint-agents` | Parallel agents inside a phase (when snapshot allows) |
| `/execute-plan` | Multi-phase orchestrator — delegates PR hygiene here (default merge mode `auto`) |
