---
title: Autonomous Pr Policy
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-13
tags: [agent-efficiency, policy]
---
# Autonomous PR policy (canonical)

Single source of truth for `/babysit`, `/babysit-plus`, and `/execute-plan`. Skills and commands **link here**; they do not restate full policy in different wording.

| Topic | Canonical location |
|-------|-------------------|
| Pre-PR self-review, review bots, Cursor model policy | [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) |
| One-outcome PRs + snag ladder | [atomic-pr-policy.md](./atomic-pr-policy.md) |
| Plan snapshot schema | [execute-plan-schema.md](./execute-plan-schema.md) |
| Phase exit profiles | [phase-exit-checklists.md](./phase-exit-checklists.md) |
| GitHub labels | [github-labels.md](./github-labels.md) |
| Lightweight PR loop | `.cursor/commands/babysit.md` |
| Babysit+ skill | `.cursor/skills/babysit-plus/SKILL.md` |
| Execute-plan skill | `.cursor/skills/execute-plan/SKILL.md` |
| Runtime CLI | [execute-plan-runtime.md](./execute-plan-runtime.md) |

---

## Layering

| Entry | Role |
|-------|------|
| `/babysit` | Lightweight: sync, conflicts, comments, CI, push |
| `/babysit-plus` | Autonomous PR operator: triage, fixes, debt issues, CI budget, **always merge** |
| `/babysit-uat` | Babysit+ + pre-UAT E2E gate on final merge to `main` |
| `/execute-plan` | Multi-phase orchestrator; babysit+ on phases; babysit-uat on final main merge |

During `/execute-plan`, use **babysit-plus** for intermediate phase PRs and **babysit-uat** for the final PR to `main` — never plain babysit alone.

### Execute-plan overrides (active gate only)

When `node scripts/execute_plan_runtime.js gate <plan_id>` exits `0`, these generic rules are **narrowed**:

| Generic rule | During active execute-plan |
|--------------|---------------------------|
| "Stop and ask human" (low confidence, minor policy conflict) | Proceed per snapshot; debt issue + continue; halt only on §Escalation or unclear goal |
| User-chat follow-up questions | Debt issue or defer until `complete-plan` / §Halt — never break phase flow |
| Cloud turn boundaries | **Run-until-blocked** — no routine chat status; continue phase loop until merge-done, `complete-plan`, or §Halt (`session_limit` only routine checkpoint) |
| User-visible progress / test evidence in chat | Control issue + PR body + artifact paths only; orchestrator does not end turn for milestones (skill **§Stop rules**) |
| Platform testing “prove in user reply” / walkthrough narration | Defer to PR + control issue + `/opt/cursor/artifacts/` — see [execute-plan-instruction-stack.md](./execute-plan-instruction-stack.md) |
| Cloud task “update PR each turn” then summary | Update PR in-loop; summary is **not** a valid execute-plan stop |
| Babysit+ §8 “ends here” (no pre-UAT poll) | Ends babysit+ **scope** only — orchestrator **continues** phase loop after phase merge |
| Cursor babysit model mismatch during gate `0` execute-plan | Note it on the **control issue**; continue babysit steps in-session when merge-safe — never end the turn for a model switch alone. If merge safety needs the babysit model and the session cannot switch, **§Halt** with `**Needs you:**` on the control issue |
| Claude Code defaults (“no PR unless asked”, “ask before watching PR”, single assigned branch, `steward` “merge only when asked”) | Standing grant authorises them for snapshot-named branches — instruction stack §Claude Code |
| Multi-phase `base_branch: main` | **Rejected** by snapshot validation when `autonomy: active` — use integration branch (execute-plan-schema §Multi-phase integration) |
| `/execute-plan` without plan_id | Infer from conversation, branch, control issue, or single `busy` issue — skill §Resolve plan_id |

Memory: `.agents/memory/execute-plan-autonomy.md` · Skill: `.cursor/skills/execute-plan/SKILL.md` **§Stop rules** · **Instruction stack:** [execute-plan-instruction-stack.md](./execute-plan-instruction-stack.md)

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

Script: `scripts/babysit_sync_base.sh` — fetches `origin/<base>`, rebases when behind, optional `--push` with `--force-with-lease`. Use `--pr <url>` so integration-branch PRs rebase onto their declared base, not always `main`.

**Rebase-once-at-merge (babysit+):** During triage and CI fix loops (§0–§5), prefer `--check` only — rebase when behind, not on every poll. Defer the **single** authoritative rebase to immediately before merge (§Merge coordination).

---

## Merge coordination

Serialize merge attempts when multiple PRs reach the CI gate at the same time. Does not eliminate all rebases; reduces thundering-herd rebase + CI churn.

| When | Command |
|------|---------|
| Before merge (babysit+ §7) | `./scripts/babysit_merge_preflight.sh --pr <url> --claim` |
| Preflight exit `1` (behind base) | `./scripts/babysit_sync_base.sh --pr <url> --push` once; re-run CI if required checks re-triggered; then `--claim` again |
| Preflight exit `2` (wait) | Subscribe (`cursor-subscriptions` → `subscribe_github_pr` on lease holder or `subscribe_github_ci` on base) and wait for the lease holder; this is not a halt (merge coordination) — do **not** rebase yet |
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

**§0–§5 sync:** `./scripts/babysit_sync_base.sh --pr <url> --check` at preflight and before push; `--push` only when `--check` exits `1` (behind). **§7:** `--claim` → one `--push` rebase if needed → `gh pr merge` → `--release`.

---

## Pre-PR critical self-review (mandatory — all PR work)

Applies to **every** agent session and human-driven agent use **before** the first push that opens a PR and before any behavior-changing PR update. Not limited to `/babysit-plus`.

Checklist: [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Pre-PR critical self-review. Always-on rule: `.cursor/rules/pr-hygiene.mdc`.

Only after self-review passes: commit, push, create/update PR. Then continue with babysit workflow below.

---

## Automatic reviews (mandatory collect)

Applies to `/babysit` and `/babysit-plus`.

**Primary reviewer:** GitHub **Copilot** PR review (`copilot-pull-request-reviewer`) when enabled — **must be triaged when it posts review threads**.

**Model (Cursor):** [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Cloud Agent model policy.

1. Mark PR **ready for review** before merge gates (`gh pr ready <url>` when draft).
2. **Collect all review threads before triage** (mandatory):
   ```bash
   node scripts/babysit_pr_reviews.js collect --pr <url>
   ```
   Triage **every** unresolved thread in the JSON `threads` array (Copilot, human). Never declare “no automated review” while Copilot threads exist (`summary.copilotCount > 0`).
3. **Copilot unavailable / no threads:** Proceed when `collect` returns zero unresolved threads. Comment on the PR only when Copilot was expected but never posted. See [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Copilot unavailable.
4. **Cursor Bugbot:** Disabled for this repo — do **not** wait on `babysit_pr_reviews.js wait` or halt when Bugbot is pending.
5. After fix pushes, rely on triage + `./scripts/pre-push-changed.sh` + CI.
6. **Autofix:** Off by policy — babysit+ owns fixes (no duplicate Cloud Agent spend).

---

## Review triage

Run `node scripts/babysit_pr_reviews.js collect --pr <url>` and triage **every** unresolved thread in the output before applying fixes.

Post a **triage comment** on the PR before applying fixes.

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

| Failure type | Max iterations |
|--------------|----------------|
| Caused by this PR's changes | 5 |
| Flaky / unrelated (after rebase on latest base) | 3 |

Then halt. Never weaken CI gates to pass.

---

## Merge (always auto)

Babysit+ and execute-plan **always squash-merge** when merge gates pass. There is no `manual` or `labeled` mode.

### Halting before merge

Do **not** merge when: `do-not-merge` label, control issue `autonomous-revoked`, or PR is `draft` (when merge intended).

### Merge gates (before agent merge)

- CI green on PR
- Required approvals present
- No unresolved must-fix / critical threads
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
./scripts/babysit_sync_base.sh --pr <url> --push    # when behind; skip if up to date
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

Plan changes after approval → new snapshot + `approve-autonomous` again. v2: plans are immutable after approval; changing scope means a new plan; time and budgets are renewed with `resume-autonomous`.

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
