---
name: babysit-plus
description: Autonomous PR operator — mandatory pre-PR critical self-review, triage review comments (must-fix / nits / ignore), apply fixes, track debt issues, CI retry loop, and squash merge when gates pass. Use during /execute-plan intermediate phases or when full autonomous PR hygiene is needed without pre-UAT. Policy lives in docs/agent-efficiency/autonomous-pr-policy.md.
---

# Babysit+

Autonomous PR operator. Extends lightweight `/babysit` with mandatory triage, debt-issue tracking, CI budgets, and merge gates.

**Canonical policy (do not restate here):** `docs/agent-efficiency/autonomous-pr-policy.md`  
**Phase exit profiles:** `docs/agent-efficiency/phase-exit-checklists.md`  
**Labels / dedupe:** `docs/agent-efficiency/github-labels.md`  
**Lightweight sibling:** `.cursor/commands/babysit.md` — use plain babysit when debt tracking and merge automation are not required.  
**Pre-UAT sibling:** `.cursor/skills/babysit-uat/SKILL.md` — final merge to `main` when pre-UAT E2E must pass.

During `/execute-plan`, use **/babysit-plus** for intermediate phase PRs and **/babysit-uat** for the **final** PR to `main` — never plain `/babysit` alone.

**Execute-plan override:** When `gate <plan_id>` exits `0`, do **not** halt or ask the human in chat for low-confidence triage — post `**Needs you:**` on the **control issue** only when merge safety is genuinely ambiguous; otherwise debt issue + continue. See autonomous-pr-policy §Execute-plan overrides and `.agents/memory/execute-plan-autonomy.md`.

---

## Inputs

| Input | Required | Notes |
|-------|----------|-------|
| PR URL or branch | yes | `gh pr view` / `ManagePullRequest` |
| `plan_id` | when in execute-plan | For debt-issue dedupe keys |
| Phase snapshot | when in execute-plan | `exit_checklist`, `allowed_paths` |
| `approved_until` | when in execute-plan | Halt if past expiry |

---

## Pre-PR critical review (mandatory)

Required for **all** agent PR work (not only babysit+). Canonical checklist: `docs/agent-efficiency/pr-review-cost-efficiency.md` · always-on rule: `.cursor/rules/pr-hygiene.mdc`.

**Before** creating or opening the PR (first push + `ManagePullRequest create_pr`), perform a **critical self-review** of the full diff against the requirement. Do not treat this as a quick skim — actively look for problems.

1. **Correctness & impact** — Re-read the requirement; trace happy paths, edge cases, error handling, and regressions. Confirm behavior matches intent; flag anything that could surprise callers or break downstream flows.
2. **Risks** — Security (auth, input validation, data exposure), data integrity, migrations, API contract drift, concurrency, and operational impact (logs, metrics, rollback).
3. **Design quality** — Against existing codebase patterns, assess **robustness**, **maintainability**, and **testability**. Prefer the smallest change that meets the requirement; avoid drive-by refactors.
4. **Better solution check** — If a clearer pattern, safer abstraction, or simpler approach would satisfy the requirement with equal or less scope, **adopt it now** — adjust code and tests before opening the PR. Do not defer with "we'll fix in review."
5. **Verification** — Run `./scripts/pre-push-changed.sh` after any adjustments from this review.
6. **UI-touching PRs** — If the diff includes `flutter_app/lib/**/presentation/**`, theme, or router files, complete the **`/ui-check`** checklist (`.cursor/skills/ui-check/SKILL.md` §Steps) before create/update PR. Escalate to `/ui-design-deep` when the skill says so.

Optional: `/review-bugbot` on the branch diff before push to dedupe a paid Bugbot PR review.

Only after this review passes: commit, push, and create/update the PR. Then continue with §Workflow from step 0 (Preflight).

## Model (babysit phase)

Use **`composer-2.5` only** for steps §0–7 (sync, poll, triage, fixes, CI, merge). If the session is on a thinking/high model, **switch to `composer-2.5`** or spawn a fresh cloud agent before babysit work. Implementation may use other models; babysitting may not.

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

### 0b. Ready for review + collect automatic reviews (mandatory)

Applies to **both** `/babysit` and `/babysit-plus`. **Copilot** is the primary automatic reviewer when enabled; **must be triaged when threads exist**. Policy: `docs/agent-efficiency/pr-review-cost-efficiency.md`.

1. Confirm session model is **`composer-2.5`** before this step (see §Model).
2. If `isDraft`: `gh pr ready <url>` (or equivalent).
3. **Collect review threads** (mandatory — do not hand-roll `gh api` calls):
   ```bash
   node scripts/babysit_pr_reviews.js collect --pr <url>
   ```
   The JSON `threads` array lists **every unresolved thread** from Copilot and humans. Triage **each** thread — never declare “no automated review” while `summary.copilotCount > 0` or `threads` is non-empty.
4. **Copilot unavailable / no threads:** Proceed when `collect` returns zero unresolved threads (or Copilot never posted). Comment `Copilot unavailable; babysit+ triage used CI + pre-push only.` only when Copilot was expected but never posted — do **not** halt.
5. **Autofix:** Off — babysit+ owns fixes; do not re-run adversarial review in agent turns (slim babysit).

Do **not** wait on Cursor Bugbot — it is disabled for this repo. The `wait` subcommand remains for optional manual use only.

### 1. Sync and conflicts

Same as `/babysit`: resolve merge conflicts preserving intent; escalate if intents conflict.

### 2. Triage (mandatory before fixes)

Run `node scripts/babysit_pr_reviews.js collect --pr <url>` and triage **every** entry in `threads` (Copilot, human — filter resolved threads via the script output).

Post a **triage comment** on the PR summarizing every active unresolved thread:

| Bucket | Action |
|--------|--------|
| **Must-fix** | Fix in this PR |
| **Nits** | Fix if local + low-risk; else debt issue |
| **Ignore** | No code; debt issue if valid concern deferred |

Rules: see autonomous-pr-policy §Review triage. **Never ignore** blocker / critical / high / must signals. Low confidence → debt issue + continue during active execute-plan (`gate` exit `0`); otherwise halt with `**Needs you:**` on the control issue — never ask in user chat.

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

### 7. Merge (always)

When all merge gates pass (autonomous-pr-policy §Merge gates), **always squash-merge** — babysit+ never stops at “merge-ready” without merging.

```bash
gh pr merge <url> --squash
gh pr view <url> --json state,mergedAt,mergeCommit
```

Verify merge commit is ancestor of `origin/<base_branch>` before execute-plan advances to the next phase.

**Babysit+ ends here.** Do not poll pre-UAT, promote, or deploy. For final merge to `main` when pre-UAT must pass, delegate to **/babysit-uat** instead.

### 8. Post-merge (out of scope for babysit+)

When the PR merges to **`main`**, **GitHub Actions** runs `pre-uat-e2e.yml` async. Babysit+ does **not** watch it.

| Layer | Owns |
|-------|------|
| **GitHub Actions** | Pre-UAT E2E, promote tag, deploy, prod-ready |
| **`/babysit-uat`** | Final merge to `main` + pre-UAT gate + remedial loop |
| **Human** | [uat-promote-manual.md](../../../docs/e2e/uat-promote-manual.md); ops localhost replay via `scripts/agent-uat-babysit.sh` |

**UAT prod-ready is not a phase gate** for execute-plan. E2E/deploy failure does **not** halt the orchestrator.

**Infra-only blockers** (e.g. `UAT_AUTO_MIGRATE` off with pending migrations) → §9 Escalation (true halt; human required). Do not weaken gates.

### 9. Escalation (always halt)

See autonomous-pr-policy §Escalation. Includes security/crypto, breaking API, prod migrations, CI gate changes, product/legal, drift, CI budget exhausted, issue tracking failed, **UAT prod-ready blocked by infra config** (e.g. pending live migrations with `UAT_AUTO_MIGRATE` off).

---

## Related skills

| Skill | When |
|-------|------|
| `/pre-push-verify` | Before every push; full suite before merge |
| `/spawn-sprint-agents` | Parallel agents inside a phase (when snapshot allows) |
| `/babysit-uat` | Final merge to `main` — babysit+ plus pre-UAT E2E gate |
| `/execute-plan` | Multi-phase orchestrator — babysit+ on phases; babysit-uat on final main merge |
