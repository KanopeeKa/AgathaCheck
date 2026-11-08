---
name: babysit-plus
description: Autonomous PR operator — mandatory pre-PR critical self-review, triage review comments (must-fix / nits / ignore), apply fixes, track debt issues, CI retry loop, and squash merge when gates pass. Use during /execute-plan intermediate phases or when full autonomous PR hygiene is needed without pre-UAT. Policy lives in docs/agent-efficiency/autonomous-pr-policy.md.
disable-model-invocation: true
---

# Babysit+

Autonomous PR operator. Extends lightweight `/babysit` with mandatory triage, debt-issue tracking, CI budgets, and merge gates.

**Resolve all review conversations** before merge (reply + resolve every thread; `gate --pr` exit `0` last) — autonomous-pr-policy §Babysit skill family.

**Canonical policy (do not restate here):** `docs/agent-efficiency/autonomous-pr-policy.md`  
**Phase exit profiles:** `docs/agent-efficiency/phase-exit-checklists.md`  
**Labels / dedupe:** `docs/agent-efficiency/github-labels.md`  
**Lightweight sibling:** `/babysit` (`.cursor/skills/babysit/SKILL.md`) or built-in `/autopilot` for cloud handoff — use when debt tracking and merge automation are not required.  
**Pre-UAT sibling:** `.cursor/skills/babysit-uat/SKILL.md` — final merge to `main` when pre-UAT E2E must pass.

During `/execute-plan`, use **/babysit-plus** for intermediate phase PRs and **/babysit-uat** for the **final** PR to `main` — never plain `/babysit` alone.

**Execute-plan v2:** After phase PR merge, return to the tick loop — not a routine babysit+ stop. See autonomous-pr-policy §Execute-plan (v2).

---

## Router (babysit+)

**Profile:** `full` when **implementing** a fix/feature. **`diff-scoped`** when PR already exists (triage/CI/merge only).

1. Read `.cursor/agent-kernel/ROUTER.md` with the matching profile.
2. Resolve risk + protocols; read only listed files under `.cursor/agent-kernel/protocols/`.
3. Map `verification[]` to `./scripts/pre-push-changed.sh`, Jest, flutter test, etc.
4. Escalate R2/R3 during work without asking user to restart — split via issues/phases if multiple outcomes.

**Bug workflow:** reproduce → root cause → regression test → fix → verify adjacent behaviour. No broad try/catch without proof.

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
5. **Documentation sync** — Run `/canonical-docs sync` (`.cursor/skills/canonical-docs/SKILL.md` Mode A). A behaviour-changing PR without a canonical doc update is not ready to open.
6. **Verification** — Run `./scripts/pre-push-changed.sh` after any adjustments from this review.
7. **UI-touching PRs** — If the diff includes `flutter_app/lib/**/presentation/**`, theme, or router files, complete **`.cursor/agent-kernel/protocols/accessibility.md` §Quick pass** before create/update PR. Escalate to `/ui-design-deep` when theme, landing/auth, or multi-screen work applies.

Only after this review passes: commit, push, and create/update the PR. Then continue with §Workflow from step 0 (Preflight).

## Model (babysit phase)

Use **`composer-2.5` only** for steps §0–7 (sync, poll, triage, fixes, CI, merge). If the session is on a thinking/high model, **switch to `composer-2.5`** or spawn a fresh cloud agent before babysit work. Implementation may use other models; babysitting may not. During an active execute-plan (any schema), never switch model or spawn a fresh agent for this step; v2 workers never merge — the driver arms auto-merge.

---

## Workflow

### 0. Preflight

1. **Base sync (check-first)** — detect staleness without rebasing on every poll:
   ```bash
   ./scripts/babysit_sync_base.sh --pr <url> --check
   ```
   When exit `1` (behind), rebase once: `./scripts/babysit_sync_base.sh --pr <url> --push`. Re-run `--check` before every push, before the CI wait loop, and after long automatic-review polls. See autonomous-pr-policy §Proactive base sync and §Merge coordination.
2. If execute-plan v2: confirm control issue approval via `tick` / driver status (not revoked; window valid).
3. `gh pr view <url> --json state,isDraft,labels,headRefOid,baseRefName`
4. **§Halt if:** `do-not-merge`, draft (when merge intended), revoked, or expired.

### 0b. Ready for review + wait for automatic reviews (mandatory)

Applies to `/babysit`, `/babysit-plus` and `/babysit-uat`. **Copilot** is the primary automatic reviewer when enabled; it posts 2–7 min after the PR opens and **must be triaged**. Policy: autonomous-pr-policy §Automatic reviews.

1. Confirm session model is **`composer-2.5`** before this step (see §Model). During an active execute-plan (any schema), never switch model or spawn a fresh agent for this step; v2 workers never merge — the driver arms auto-merge.
2. If `isDraft`: `gh pr ready <url>` (or equivalent).
3. **Wait for reviews, then collect** (mandatory — do not hand-roll `gh api` calls):
   ```bash
   node scripts/babysit_pr_reviews.js wait --pr <url>
   ```
   Returns once no Copilot review is in progress (a PR younger than 3 min counts as awaiting Copilot). The JSON `threads` array lists **every unresolved thread** from Copilot and humans. Never declare “no automated review” while `reviewers.copilot.state` is `pending` or `threads` is non-empty. A script error is never “no threads” — fix it and re-run.
4. **Copilot unavailable:** `wait` exits `3` (Copilot still pending after 15 min) → comment `Copilot review did not finish within 15 min; proceeding on triage + CI + pre-push.` once and continue — do **not** halt. Copilot absent (never requested) → proceed.
5. **Autofix:** Off — babysit+ owns fixes; do not re-run adversarial review in agent turns (slim babysit).

### 1. Sync and conflicts

Same as `/babysit`: resolve merge conflicts preserving intent; escalate if intents conflict.

### 2. Triage (mandatory before fixes)

Triage **every** entry in `threads` from the latest `wait` output (Copilot, human; resolved threads are already filtered out).

Post a **triage comment** on the PR summarizing every active unresolved thread:

| Bucket | Action |
|--------|--------|
| **Must-fix** | Fix in this PR |
| **Nits** | Fix if local + low-risk; else debt issue |
| **Ignore** | No code; debt issue if valid concern deferred |

Rules: see autonomous-pr-policy §Review triage. **Never ignore** blocker / critical / high / must signals. On a **behaviour-changing** PR, a missing or stale canonical doc update or missing `## Docs` in the PR body is **must-fix** (never a nit or debt issue). Low confidence → debt issue + continue during active execute-plan (`gate` exit `0`); otherwise halt with `**Needs you:**` on control issue + short chat alert.

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
- **Close every thread** once its fix is pushed or its debt issue exists: reply (`Fixed in <sha>` / `False positive: …` / `Deferred to #<n>`) and resolve it (GraphQL `resolveReviewThread`, or the GitHub UI). Rulesets block merge while any thread is unresolved.

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

Follow `autonomous-pr-policy.md` §**CI retry budget** (red-push streak, same signature, Playwright local repro on streak 2, halt at 3/5). Respect `ci-loop` via `./scripts/pre-push-changed.sh` (exit `4` when labelled).

**Push batching (Actions cost):** Accumulate fixes locally until `./scripts/pre-push-changed.sh` is green, then **one push** per logical batch — do not push after every single-file triage fix. Re-run pre-push after the batch, not after each file.

1. **Before watching CI:** `./scripts/babysit_sync_base.sh --pr <url> --check` — if behind, `--push` once instead of waiting for a failure.
2. Push fixes; watch CI (`ManagePullRequest get_ci_status` or `gh pr checks`).
3. **After every push**, `node scripts/babysit_pr_reviews.js wait --pr <url>` — new threads (human, re-requested Copilot) go back through §2–§4 in the same batch as CI fixes. CI green alone never ends the loop.
4. Rebase on latest base before counting unrelated failures (`--check` then `--push` when behind).
5. Exhaust policy streak budget → halt; comment on PR + control issue (`**Needs you:**` or `/e2e-debug` handoff).

### 6. Exit checklist

When execute-plan phase declares `exit_checklist`, run every applicable item in `docs/agent-efficiency/phase-exit-checklists.md` before merge step.

**Docs gate:** `## Docs` section present; canonical doc(s) updated or `N/A — reason`; any change doc this PR fully delivers deleted (deletion guard); `related_prs` includes this PR when docs changed; `bash scripts/validate_docs.sh` passes.

Always before merge attempt: `./scripts/pre-push.sh` green locally.

### 7. Merge (always)

When all merge gates pass (autonomous-pr-policy §Merge gates), **always squash-merge** — babysit+ never stops at “merge-ready” without merging.

**Merge coordination** (mandatory — see autonomous-pr-policy §Merge coordination):

```bash
./scripts/babysit_merge_preflight.sh --pr <url> --claim
```

| Exit | Action |
|------|--------|
| `0` | Proceed |
| `1` | `./scripts/babysit_sync_base.sh --pr <url> --push` once; re-run CI if checks re-triggered; `--claim` again |
| `2` | Another PR holds `merge-lease` or FIFO yield — subscribe and wait for the lease holder; this is not a halt (merge coordination); do not rebase yet |
| `3` | Halt (`do-not-merge` or error) |

Then sync, run the review gate, and merge:

```bash
./scripts/babysit_sync_base.sh --pr <url> --push    # skip when already up to date; a push → wait for CI green
node scripts/babysit_pr_reviews.js gate --pr <url>  # last check before merge — after any push
gh pr merge <url> --squash
./scripts/babysit_merge_preflight.sh --pr <url> --release
gh pr view <url> --json state,mergedAt,mergeCommit
```

**Review gate** exits (mandatory — the last step before `gh pr merge`):

| Exit | Action |
|------|--------|
| `0` | No Copilot review in progress; every thread resolved — merge |
| `2` | Unresolved threads → `--release`, back to §2 (triage, fix, reply + resolve, push, CI) |
| `3` | Copilot still pending after the timeout, nothing unresolved → §0b step 4 comment, then merge |
| `1` | Script error → fix and re-run; never merge on an error |

Verify merge commit is ancestor of `origin/<base_branch>` before execute-plan advances to the next phase.

### 7b. Roadmap child handoff (`plan_kind: roadmap`)

When babysit+ or babysit-uat merges a **child** plan PR (not the roadmap parent):

1. On the **child** plan: `node scripts/execute_plan_runtime.js complete-plan <child_plan_id> --write`
2. On the **roadmap parent**:
   ```bash
   node scripts/execute_plan_runtime.js roadmap-set-child <roadmap_id> \
     --child <child_plan_id> --status merged \
     --pr-url <url> --merge-commit <sha> --write
   ```
3. `roadmap-next-child <roadmap_id>` — bootstrap and gate the next pending child without permission prompts when the standing grant covers remaining scope
4. When `roadmap-status` reports `complete: true`, `complete-plan <roadmap_id> --write` on the parent

**During `/execute-plan` (v2):** Phase PR squash-merge is not session completion — continue the tick loop. See `docs/agent-efficiency/plans/execute-plan-v2.md`.

**Babysit+ scope ends here** (not the session) — no pre-UAT polling or deploy. Final merge to `main` when pre-UAT must pass → **/babysit-uat**.

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
| `/canonical-docs` | Mode A before PR open; Mode B consolidate on demand |
