---
title: Autonomous Pr Policy
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [agent-efficiency, policy]
---
# Autonomous PR policy (canonical)

Single source of truth for `/babysit`, `/babysit-plus`, and `/execute-plan`. Skills and commands **link here**; they do not restate full policy in different wording.

Whether an agent may merge is defined in [`AGENTS.md`](../../AGENTS.md) §Autonomy and merging; the babysit workflows below assume that gate is satisfied when the skill is active.

| Topic | Canonical location |
|-------|-------------------|
| Pre-PR self-review, review bots, Cursor model policy | [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) |
| One-outcome PRs + snag ladder | [atomic-pr-policy.md](./atomic-pr-policy.md) |
| Plan snapshot schema | [execute-plan-schema.md](./execute-plan-schema.md) |
| Phase exit profiles | [phase-exit-checklists.md](./phase-exit-checklists.md) |
| GitHub labels | [github-labels.md](./github-labels.md) |
| Lightweight PR loop | `.cursor/skills/babysit/SKILL.md` (cloud handoff: built-in `/autopilot`) |
| Babysit+ skill | `.cursor/skills/babysit-plus/SKILL.md` |
| Execute-plan skill | `.cursor/skills/execute-plan/SKILL.md` |
| Runtime CLI | [execute-plan-runtime.md](./execute-plan-runtime.md) |

---

## Layering

| Entry | Role |
|-------|------|
| `/babysit` | Lightweight: sync, conflicts, comments, CI, push (skill; optional cloud handoff via `/autopilot`) |
| `/babysit-plus` | Autonomous PR operator: triage, fixes, debt issues, CI budget, **always merge** |
| `/babysit-uat` | Babysit+ + pre-UAT E2E gate on final merge to `main` |
| `/execute-plan` | Multi-phase orchestrator; babysit+ on phases; babysit-uat on final main merge |

During `/execute-plan`, use **babysit-plus** for intermediate phase PRs and **babysit-uat** for the final PR to `main` — never plain babysit alone.

### Execute-plan (v2)

While a v2 worker or driver session is active, generic “stop and ask” rules are narrowed for in-scope
snapshot work; halt only on §Escalation or an unclear goal. Evidence goes to the control issue and PR
body, not routine user chat. See [execute-plan-v2.md](./plans/execute-plan-v2.md).

| Generic rule | During active v2 execute-plan |
|--------------|------------------------------|
| "Stop and ask human" (low confidence, minor policy conflict) | Proceed per snapshot; debt issue + continue; halt only on §Escalation or unclear goal |
| Multi-phase integration | Phase PRs target `integration_branch` from the v2 snapshot |
| `/execute-plan` without plan_id | Infer from conversation, branch, control issue, or single `busy` issue — skill §Resolve plan_id |

Skill: `.cursor/skills/execute-plan/SKILL.md` · **Instruction stack:** [execute-plan-instruction-stack.md](./execute-plan-instruction-stack.md)

#### Review threads on plan PRs

`tick` owns the review gate for plan PRs: any unresolved thread returns agent `triage-review` before the
driver arms or performs a merge (state-machine PR-ladder 5), PRs into `main` wait up to 15 min for Copilot
(PR-ladder 9), and the rulesets block merge while a thread is unresolved. The `triage-review` worker applies
§Review triage and §Debt issues to every listed thread, then replies on and resolves each one — an
unresolved thread relaunches the action. Copilot reviews only PRs into `main` (the release PR); phase PRs
into the integration branch carry human threads only.

---

## Babysit skill family

**Review conversations** = GitHub pull request **review threads** (`reviewThreads`). Rulesets on `main` and integration branches block merge while **any** review conversation is unresolved.

The **babysit skill family** is every agent entry that opens, updates, or merges a PR through a babysit workflow. **Procedure** (wait, triage every thread, reply and resolve each one, re-check after every push, `babysit_pr_reviews.js gate` before merge) is defined once in §Automatic reviews — skills link here; they do not duplicate those steps in different wording.

| Member | Resolve-all conversations |
|--------|---------------------------|
| `/babysit` | Yes — merge-ready = `gate` exit `0`; `/autopilot` handoff does not waive reply+resolve when you remain in session |
| `/babysit-plus` | Yes — §7 review gate; exit `2` → triage and resolve |
| `/babysit-uat` | Yes — babysit+ §0–7 on every merge, including remedial PRs |
| `/light-plan` light merge | Yes — `gate --pr` before `gh pr merge` on phase/sync PRs |
| `/dependabot-batch` | Yes — Phase 3 babysit+ (wait, reply+resolve, `gate`) + Phase 5 `/babysit-uat` |
| `/execute-plan` workers (`triage-review`) | Yes — reply and resolve every listed conversation; `tick` relaunches while any stay unresolved |
| `/execute-plan` driver | Yes — `tick` PR-ladder 5 blocks on GraphQL `unresolved_threads`; ladder 9 waits for Copilot on young PRs to **`main` only**; driver arms auto-merge when the ladder passes (does **not** invoke `babysit_pr_reviews.js`; workers + ruleset enforce resolve-all) |
| `.cursor/rules/pr-hygiene.mdc` | Points agents at §Babysit skill family and §Automatic reviews |
| Claude **steward** skill | Same pointers for Claude-driven PRs |

**Doc drift guard:** `node scripts/check_babysit_skill_family.js` (pre-push and CI governance — see `_reusable-test.yml`).

---

## Proactive base sync

Do **not** wait for CI to fail before rebasing when `main` (or the PR base branch) has moved.

| When | Command |
|------|---------|
| Start of babysit / babysit-plus | `./scripts/babysit_sync_base.sh --pr <url> --check` |
| Before every push | `--check`; `--push` only when behind (exit `1`) |
| Before entering CI wait loop | Same |
| After long automatic-review poll | Same |
| Immediately before merge (§7) | One authoritative `./scripts/babysit_sync_base.sh --pr <url> --push` after merge preflight `--claim` |

Script: `scripts/babysit_sync_base.sh` — fetches `origin/<base>`, rebases when behind, optional `--push` with `--force-with-lease`. Use `--pr <url>` so the rebase uses the PR's base, not always `main`. A head ref matching `cursor/*-integration-*` is not rebased and is not caught up to `main` because it is behind ([merge-policy](../../.cursor/rules/merge-policy.mdc)).

**Rebase-once-at-merge (babysit+):** During triage and CI fix loops (§0–§5), prefer `--check` only — rebase when behind, not on every poll. Defer the **single** authoritative rebase to immediately before merge (§Merge coordination).

---

## Merge coordination

Serialize merge attempts when multiple PRs reach the CI gate at the same time. Does not eliminate all rebases; reduces thundering-herd rebase + CI churn.

| When | Command |
|------|---------|
| Before merge (babysit+ §7) | `./scripts/babysit_merge_preflight.sh --pr <url> --claim` |
| Preflight exit `1` (behind base, action `rebase`) | `./scripts/babysit_sync_base.sh --pr <url> --push` once; re-run CI if required checks re-triggered; then `--claim` again. Action `recheck_mergeable` (integration head): fetch `mergeable` again; do not rebase. |
| Preflight exit `2` (wait) | Subscribe (`cursor-subscriptions` → `subscribe_github_pr` on lease holder or `subscribe_github_ci` on base) and wait for the lease holder; this is not a halt (merge coordination) — do **not** rebase yet |
| Preflight exit `4` (integration conflict) | One PR that merges the base into the integration head and resolves the conflict. Do not rebase. |
| After successful merge | `./scripts/babysit_merge_preflight.sh --pr <url> --release` (no-op if PR closed) |
| Stale lease (≥45 min, holder idle) | `--claim --force` |

Script: `scripts/babysit_merge_preflight.sh` — `merge-lease` label mutex + FIFO yield when base was updated within 10 minutes and a lower-numbered green PR exists on the same base. Env: `MERGE_PREFLIGHT_BASE_HOT_MINUTES`, `MERGE_PREFLIGHT_LEASE_STALE_MINUTES`.

## CI cost (Actions minutes)

Linux runner usage scales with **open PR count**, **pushes per PR**, and **jobs per `ci.yml` run**. Copilot review is a separate meter — see [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md).

| Practice | Why |
|----------|-----|
| **≤4 open `cursor/**` PRs** with full CI at once | Limits parallel matrix fan-out across branches |
| **Programme integration branch** (`cursor/*-integration-*`) | One CI-heavy line; single release PR to `main` |
| **Merge-lease (§Merge coordination)** | Reduces thundering-herd rebase + duplicate CI on the same base |
| **Babysit+ push batching** | `.cursor/skills/babysit-plus/SKILL.md` §5 — one push per logical fix batch |
| **`/babysit-plus` on phase PRs; `/babysit-uat` on release to `main` only** | Pre-UAT runs only after merge to `main` |

See [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) § GitHub Actions minutes.

**§0–§5 sync:** `./scripts/babysit_sync_base.sh --pr <url> --check` at preflight and before push; `--push` only when `--check` exits `1` (behind) and the head is not `cursor/*-integration-*`. **§7:** `--claim` → one `--push` rebase if needed (skip on an integration head) → review `gate` → `gh pr merge` → `--release`. A `MERGEABLE` integration release squash-merges while `BEHIND`.

---

## Pre-PR critical self-review (mandatory — all PR work)

Applies to **every** agent session and human-driven agent use **before** the first push that opens a PR and before any behavior-changing PR update. Not limited to `/babysit-plus`.

Checklist: [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Pre-PR critical self-review. Always-on rule: `.cursor/rules/pr-hygiene.mdc`.

Only after self-review passes: commit, push, create/update PR. Then continue with babysit workflow below.

---

## Automatic reviews (mandatory wait, triage and gate)

Applies to `/babysit`, `/babysit-plus` and `/babysit-uat`. Execute-plan v2 plan PRs: §Execute-plan (v2) review threads.

**Primary reviewer:** GitHub **Copilot** PR review (`copilot-pull-request-reviewer`) when enabled — **must be triaged when it posts review threads**. The `main` ruleset requests Copilot once when the PR opens (drafts included, not on later pushes); it posts 2–7 minutes later. Both the `main` and integration rulesets require every review thread to be **resolved** before merge.

**Model (Cursor):** [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Cloud Agent model policy.

`scripts/babysit_pr_reviews.js` (REST + review-thread GraphQL; works with the `repo`-scoped bot token):

| Command | Use | Exit |
|---------|-----|------|
| `wait --pr <url>` | Before triage — polls until no Copilot review is in progress (a PR younger than 3 min counts as awaiting the Copilot request) | `0` ready · `3` Copilot still pending at the timeout (default 15 min) — threads listed are triageable · `1` error |
| `gate --pr <url>` | Merge gate — `wait`, then require no unresolved threads (`mergeReady`) | `0` merge-ready · `2` unresolved threads → triage · `3` Copilot still pending at the timeout, nothing unresolved · `1` error |
| `collect --pr <url>` | One snapshot (no waiting) | `0` · `1` error |

Every review-thread page is read. A fetch or GraphQL error exits `1` and is never “no threads”: fix the error (identity, network) before continuing.

1. Mark PR **ready for review** before merge gates (`gh pr ready <url>` when draft).
2. **Wait, then triage** — `wait --pr <url>`; triage **every** unresolved thread in the JSON `threads` array (Copilot, human) per §Review triage. Never declare “no automated review” while Copilot is pending (`reviewers.copilot.state == "pending"`) or threads exist.
3. **Close every thread** — reply on the thread (fixed in `<sha>` / false positive because … / deferred to #issue) and resolve it. Unresolved threads block merge (ruleset) and the merge gate.
4. **After every push** — run `wait` again and triage any new threads before entering or continuing the CI wait loop (human or re-requested Copilot reviews arrive at any time).
5. **Before merge** — `gate --pr <url>` must exit `0` as the last step before `gh pr merge`, after any sync push (§Merge gates → Execution). Exit `2` → back to triage.
6. **Copilot unavailable** — `wait` / `gate` exit `3`: comment `Copilot review did not finish within 15 min; proceeding on triage + CI + pre-push.` once; triage the listed threads; `gate` exit `3` (nothing unresolved) then counts as passing. Copilot absent (never requested, no credits): proceed. See [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Copilot unavailable.
7. **Cursor Bugbot:** Retired — the script ignores it; never wait on it.
8. **Autofix:** Off by policy — babysit+ owns fixes (no duplicate Cloud Agent spend).

---

## Review triage

Run `node scripts/babysit_pr_reviews.js wait --pr <url>` and triage **every** unresolved thread in the output before applying fixes.

Post a **triage comment** on the PR before applying fixes. After acting on each thread, reply with the outcome and resolve it (§Automatic reviews step 3).

| Bucket | Signals | Action |
|--------|---------|--------|
| **Must-fix** | `request changes`, failing tests, bugs, security, migration risk, `blocker` / `critical` / `high` / `must` | Fix in this PR |
| **Nits** | `nit`, `minor`, `optional`, style-only in touched files | Fix if local + low-risk |
| **Ignore** | scope creep, future ideas, wrong reviewer read | Do not code; track in issue |

**Never ignore** blocker / critical / high / must signals.

**During active execute-plan** (`gate` exit `0`): prefer **debt issue + continue** unless must-fix vs merge-safety is genuinely ambiguous; halt with `**Needs you:**` on the **control issue** + short chat alert — not permission-seeking chat. **Otherwise:** low confidence → decide and record (PR comment or debt issue); ask only per `AGENTS.md` §When to ask.

**In-scope valid feedback stays in the PR.** Out-of-scope deferrals become issues (see §Debt issues). Aligns with `testing.mdc`.

### Nit heuristics

Apply when all true: same files as PR diff (or allowed exception), no API/behavior change, reviewer not wrong, matches repo rules.

Skip nit → debt issue when: auth/security paths, conflicts with conventions, needs product/architecture decision.

---

## Debt issues

Every **ignore** and every **skipped nit** must be tracked via **create or update** (never silent deferral).

### Dedupe key

```
sha256(plan_id + pr_number + file_path + normalized_concern)
```

`normalized_concern` = lowercase, collapsed whitespace, first 120 chars of reviewer text.

### Algorithm

1. Search: `label:review-follow-up label:tech-debt "<plan_id>"` + file path in body
2. Match on dedupe key → comment on existing issue
3. No match → `gh issue create` with labels `tech-debt`, `review-follow-up`, `plan:<id>`
4. Record issue # in `phase.debt_issue_refs`

### Batching

≥ **3** trivial nits, same reviewer, same PR, same file → **one** batched issue: `[tech-debt] Nits in <file> (PR #N)`.

**Never batch** blocker / critical / high / must items.

### Failure

If create and update both fail → `status: blocked`, `status_reason: issue_create_failed`.

---

## CI retry budget

Canonical rules for **red pushes on the PR head branch** before merge. Skills link here — do not restate numeric budgets elsewhere.

### Definitions

| Term | Meaning |
|------|---------|
| **Red push** | A push whose `CI` workflow run for the PR concludes **failure** (`cancelled` does not count). |
| **Streak** | Consecutive red pushes on one PR head branch; resets on the first green `CI` run. |
| **Same signature** | The same failing required **job name**, or for Playwright the same test id (`file:line › title`). |

### Limits

| Condition | Action |
|-----------|--------|
| Streak **2** with a Playwright failure | Before the next push, reproduce locally on `localhost:3000` (`./scripts/pre-push-changed.sh --e2e-specs …`, `--project=full` as CI). Record classification per `.cursor/agent-kernel/protocols/e2e.md` §1 in the PR. |
| Streak **3** on the **same signature**, or streak **5** on **any** signature | **Halt** pushing. One summary comment (failing tests, classification, hypotheses tried). Hand off: `/e2e-debug` for E2E; otherwise `**Needs you:**`. |
| `ci-loop` label on the PR (when `ci-loop-detector` is deployed) | `./scripts/pre-push-changed.sh` exits **4** unless `--ci-loop-override "<reason>"` (distinct from exit `3` on `babysit_pr_reviews.js`). |

Mechanical labelling (non-blocking workflow) is specified in `docs/agent-efficiency/plans/ci-pass-rate-improvement.md` §S2.

### Pre-UAT remedial (separate counter)

After merge to `main`, **pre-UAT remedial rounds** are capped by `/babysit-uat` (max **3** full `babysit-uat` loops per original feature PR). That budget does not share the PR-head red-push streak counter above.

Then halt. Never weaken CI gates to pass.

---

## Merge (always auto)

Babysit+ and execute-plan **always squash-merge** when merge gates pass. There is no `manual` or `labeled` mode.

### Halting before merge

Do **not** merge when: `do-not-merge` label, control issue `autonomous-revoked`, or PR is `draft` (when merge intended).

### Merge gates (before agent merge)

- CI green on PR
- Required approvals present
- Review gate: `node scripts/babysit_pr_reviews.js gate --pr <url>` exits `0` (no Copilot review in progress, every thread triaged and resolved; `3` after the Copilot-unavailable comment) — the last check before `gh pr merge`
- Not draft; no `do-not-merge`
- `./scripts/pre-push.sh` green locally
- BDD gate unchanged or intentionally updated
- File size gate respected
- Dual-backend parity when routes touched
- `approved_until` not past; not revoked
- **Documentation:** behaviour-changing PRs pass the docs gate (`## Docs`, canonical doc sync or `N/A — reason`) per `.cursor/skills/canonical-docs/SKILL.md` and babysit+ §Exit checklist

### Execution

Run merge coordination first (§Merge coordination):

```bash
./scripts/babysit_merge_preflight.sh --pr <url> --claim
# When preflight exit 1 (action rebase): babysit_sync_base.sh --pr <url> --push once, then --claim again.
# Integration head (`cursor/*-integration-*`): do not --push; MERGEABLE while BEHIND is OK. Exit 4 → merge base into release.
./scripts/babysit_sync_base.sh --pr <url> --push    # only when behind and head is not an integration release; skip if up to date
node scripts/babysit_pr_reviews.js gate --pr <url>  # must exit 0 — after the last push; 2 → release the lease, back to triage
gh pr merge <url> --squash
./scripts/babysit_merge_preflight.sh --pr <url> --release
gh pr view <url> --json state,mergedAt,mergeCommit
```

Verify merge commit is ancestor of `origin/<base_branch>` before next phase.

---

## Post-merge pre-UAT

| Skill | When |
|-------|------|
| **`/babysit-plus`** | Intermediate execute-plan merges (integration branch); ends at merge |
| **`/babysit-uat`** | **Final** PR to `main` — babysit+ merge + pre-UAT E2E gate on merge SHA |

**CI owns promotion** after pre-UAT green: `pre-uat-e2e.yml` → `promote-uat.yml` →
`deploy-uat.yml` → `prod-ready`. Neither babysit+ nor babysit-uat polls deploy.

After merge to `main`:

1. Record merge SHA.
2. **Babysit+** — done (intermediate phases).
3. **Babysit-uat** — watch `pre-uat-e2e.yml` for **that merge SHA**; remedial loop per `.cursor/skills/babysit-uat/SKILL.md`.
4. **Do not poll** `deploy-uat.yml` or prod-ready from the main session.
5. Applies only on **final merge to `main`**, not intermediate integration-branch merges.

See `docs/e2e/uat-deploy-tiers.md` · `docs/pipelines/ci-cd-gates.md` §3 · `docs/e2e/uat-promote-manual.md`.

**Infra-only blockers** (e.g. `UAT_AUTO_MIGRATE` unset with pending live migrations) → comment on PR/control issue and escalate; do not weaken gates.

---

## Issue hygiene (autonomous runs)

| When | Control issue | User chat (execute-plan) |
|------|---------------|--------------------------|
| Create issue and **start work immediately** | `node scripts/github_issue_workflow.js start-work --issue <n> --body "…"` (comment + `busy`) | — |
| Create debt issue for **later** | Comment on PR with issue # only | — |
| Progress / milestone | Comment on the issue | None — control issue only (gate `0`) |
| Pause or question for human | `**Needs you:**`; halt/pause when blocked on human | Short alert: issue link + unblock action (halt-class only) |
| Plan or task complete | Close with summary (`complete-plan --write` for control issues) | Brief completion note **only after** `complete-plan` |

**Project board status** (In Progress, Done, etc.) is **not** updated by Cloud Agents — GitHub does not grant Projects write on agent tokens. Use comments + `busy`; humans or GitHub Actions update the board when needed.

---

## Halt and resume

### Revoke = halt only

Does **not** close PRs, delete branches, or revert merged commits.

Does stop new commits, merge attempts, and new phases.

**Revoke:** add `autonomous-revoked` on control issue; optional `do-not-merge` on open PRs.

**Expiry:** past `approved_until` (default 48h from approval) → treat as `halted` / `revoked`. Re-approve after reviewing plan size and blockers.

### Graceful shutdown

1. Finish safe atomic step only
2. Do not merge if revoke detected pre-merge
3. Update live plan: `autonomy: halted`, `next_action`, `artifact_ref`, `pr_head_sha`
4. Comment on control issue + open PRs
5. Push plan artifact to phase branch
6. Stop agent

### Resume

1. Remove `autonomous-revoked`; comment `resume-plan <plan_id>`
2. `/execute-plan <plan_id> resume`
3. Revalidate: snapshot hash, not expired, not revoked
4. `gh pr view` → `headRefOid` == `phase.pr_head_sha` else `resume_mismatch` (human `accept-head` to override)
5. Continue from `next_action`; do not redo `merged` phases

Plan changes after approval → new snapshot + `approve-autonomous` again. v2: plans are immutable after approval; changing the plan's goal means a new plan. A fix outside the approved scope that the plan needs in order to land is not a scope change: land it as a plan-linked side PR (runbooks §7.5); time and budgets are renewed with `resume-autonomous`.

---

## Escalation (always stop)

- Security / crypto
- Breaking API without version bump
- Production data migrations
- CI workflow gate changes
- Product / legal decisions
- Drift (`status_reason: drift`)
- CI budget exhausted
- Issue tracking failed

(UAT prod-ready failure uses **pause** + sub-agent remedial + **auto-resume** — not escalation. True halt only for infra blockers per babysit-plus §9.)

---

## Approval

| Keyword | Action |
|---------|--------|
| `approve-autonomous <plan_id>` | Grant upfront autonomy; freeze snapshot; start phase 1 |
| `resume-plan <plan_id>` | Continue after halt |
| `accept-head` | On control issue — acknowledge PR force-push; update `pr_head_sha` |

`approved_until` = `approved_at + 48 hours` (mandatory).
