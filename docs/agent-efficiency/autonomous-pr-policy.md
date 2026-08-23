---
title: Autonomous Pr Policy
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [agent-efficiency, policy]
---
# Autonomous PR policy (canonical)

Single source of truth for `/babysit`, `/babysit-plus`, and `/execute-plan`. Skills and commands **link here**; they do not restate full policy in different wording.

| Topic | Canonical location |
|-------|-------------------|
| Pre-PR self-review, Bugbot settings, model policy | [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) |
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
| User-chat follow-up questions | Bundle at end of turn; never break phase flow |
| `replit-agent-operating-policy` "stop and ask" | Does not apply except §Escalation |
| Cloud turn boundaries | Commit/push/PR update each turn, then **continue the phase loop** without asking |

Memory: `.agents/memory/execute-plan-autonomy.md` · Skill: `.cursor/skills/execute-plan/SKILL.md` §Autonomy contract

---

## Proactive base sync

Do **not** wait for CI to fail before rebasing when `main` (or the PR base branch) has moved.

| When | Command |
|------|---------|
| Start of babysit / babysit-plus | `./scripts/babysit_sync_base.sh --pr <url> --push` |
| Before every push | Same (or `--check` to detect only) |
| Before entering CI wait loop | Same |
| After long automatic-review poll | Same |

Script: `scripts/babysit_sync_base.sh` — fetches `origin/<base>`, rebases when behind, optional `--push` with `--force-with-lease`. Use `--pr <url>` so integration-branch PRs rebase onto their declared base, not always `main`.

---

## Pre-PR critical self-review (mandatory — all PR work)

Applies to **every** agent session and human-driven agent use **before** the first push that opens a PR and before any behavior-changing PR update. Not limited to `/babysit-plus`.

Checklist and optional `/review-bugbot` dedupe: [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Pre-PR critical self-review. Always-on rule: `.cursor/rules/pr-hygiene.mdc`.

Only after self-review passes: commit, push, create/update PR. Then continue with babysit workflow below.

---

## Automatic reviews (mandatory collect)

Applies to `/babysit` and `/babysit-plus`.

**Primary reviewer:** GitHub **Copilot** PR review (`copilot-pull-request-reviewer`) when enabled — **must be triaged when it posts review threads**.

**Model:** PR babysitting (collect, triage, fixes, CI, merge) uses **`composer-2.5` only** — see [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) §Cloud Agent model policy.

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

**Low confidence** → stop and ask human.

**Execute-plan override:** When gate is active and phase scope is frozen in the snapshot, low-confidence triage is uncommon. Prefer a **debt issue + continue** unless must-fix vs merge-safety is genuinely ambiguous. Halt with `**Needs you:**` on the control issue — not a user-chat question.

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

### Execution

```bash
gh pr merge <url> --squash
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

| When | Action |
|------|--------|
| Create issue and **start work immediately** | `node scripts/github_issue_workflow.js start-work --issue <n> --body "…"` (comment + `busy`) |
| Create debt issue for **later** | Comment on PR with issue # only |
| Progress / milestone | Comment on the issue |
| Pause or question for human | Comment with `**Needs you:**` + reason; halt/pause execute-plan when blocked |
| Plan or task complete | Close with summary comment (`complete-plan --write` for control issues) |

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

Plan changes after approval → new snapshot + `approve-autonomous` again.

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
