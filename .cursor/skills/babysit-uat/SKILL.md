---
name: babysit-uat
description: Babysit+ through merge, then gate on pre-UAT E2E on main with risk-ranked local shard replay and remedial PR loop. Use for final merge to main or when post-merge E2E drift must be caught before promotion.
---

# Babysit-UAT

**Babysit+ through merge**, then **pre-UAT E2E green** for that merge commit on `main`. Does **not** poll `promote-uat` or `deploy-uat` (current policy).

**Builds on:** `/babysit-plus` (§0–7) · **Canonical policy:** `docs/agent-efficiency/autonomous-pr-policy.md`  
**Shard risk:** `scripts/babysit_uat_shard_risk.mjs` (Option A — diff → shard overlap)  
**Manual ops sibling:** `scripts/agent-uat-babysit.sh` (full replay; ops only)

---

## When to use

| Caller | Skill |
|--------|-------|
| Standalone PR → `main` needing pre-UAT confidence | `/babysit-uat` |
| `/execute-plan` **intermediate** phase PR (integration parent) | `/babysit-plus` only |
| `/execute-plan` **final** PR → `main` | `/babysit-uat` |
| Narrow PR CI-only / docs | `/babysit-plus` (avoids pre-UAT queue pressure) |

---

## Inputs

| Input | Required | Notes |
|-------|----------|-------|
| PR URL or branch | yes | The PR you will merge (one patch — no shard-split PRs) |
| `plan_id` | when in execute-plan | Debt-issue dedupe |
| `round` | no | `1` (default) proactive risk run; `2+` wait for CI failure before local runs |
| `merge_sha` | after merge | From `gh pr view --json mergeCommit` — ties watch to **this** PR only |

---

## Model

**`composer-2.5` only** for babysit phases (sync, triage, CI, merge, UAT orchestration). Shard-fix **Task** subagents may use implementation models; orchestrator stays on `composer-2.5`.

---

## Phase 1 — Babysit+ (mandatory)

Run **all** of `/babysit-plus` §0–7:

1. Sync, triage, debt, CI loop, `pre-push.sh`
2. **Always squash-merge** when gates pass (no `manual` / `labeled` modes)
3. Record `merge_sha` from merged PR

**Stop babysit-plus scope here** — continue into Phase 2 in this skill only.

---

## Phase 2 — Shard risk sense-check

From the **merged PR file list** (not post-merge diff):

```bash
node scripts/babysit_uat_shard_risk.mjs --pr <n>
# or: git diff --name-only <base>...<merge_sha> | node scripts/babysit_uat_shard_risk.mjs
```

| `merge_action` | Round 1 behaviour | Round 2+ behaviour |
|----------------|-------------------|---------------------|
| `wait` (low/medium only) | Poll `pre-uat-e2e` for `merge_sha`; local runs **only** on CI failure | **Wait** for workflow failure first; then local on failed shards only |
| `act_now` (any **high** shard) | Bootstrap stack + run at-risk shards locally **in parallel with** CI poll | Wait for CI failure first (assume round-1 fix was complete) |

**Zero-risk shards:** never run locally unless CI reports them failed.

---

## Phase 3 — Kick into action

When CI fails **or** `merge_action == act_now` (round 1):

### 3a. Remedial PR (single patch)

```bash
git fetch origin main
git checkout -b cursor/preuat-fix-<short-sha>-8f3a origin/main
```

One remedial PR for all shard fixes — avoids stacked pre-UAT queue patches.

### 3b. Order shards

Use JSON from `babysit_uat_shard_risk.mjs` (already sorted high → low). On CI failure, prepend `failed_shards` from watch script.

### 3c. Local stack

```bash
./scripts/babysit_uat_bootstrap_stack.sh
```

### 3d. Main session — sequential shard runs

```bash
./scripts/babysit_uat_run_shard.sh <shard>
```

Highest risk first. **Do not** run zero-risk shards.

### 3e. On local shard failure → Task subagent

Spawn a **simple Task subagent** (`generalPurpose`) scoped to fix that shard's failing specs on the **same remedial PR branch**:

- Pass: shard index, spec list, Playwright trace/log excerpt, remedial branch name
- Subagent: implement fix, `pre-push-changed.sh`, push to remedial branch
- **Main session continues** the next at-risk shard while subagent works

When a subagent finishes, incorporate its push before the next shard if the same specs overlap.

### 3f. Exit remedial loop

Proceed when **every at-risk shard** is green locally **or** has a pushed fix on the remedial PR ready for babysit.

Open/update remedial PR → run **Phase 4** on that PR.

---

## Phase 4 — Babysit-UAT remedial (round 2+)

On the remedial PR:

1. Full **Phase 1** (babysit+ merge to `main`)
2. **Phase 2** with `round >= 2`: **only** `./scripts/babysit_uat_watch_preuat.sh <merge_sha>` until failure or success
3. On failure → Phase 3 for **failed shards only** (no proactive high-risk local runs)
4. Repeat until watch exits 0

**Success:** `pre-uat-e2e.yml` green for latest remedial `merge_sha`. **Stop** — do not poll promote/deploy.

---

## Watch pre-UAT (merge SHA scoped)

```bash
./scripts/babysit_uat_watch_preuat.sh <merge_sha> --json --timeout-min 90
```

Matches the workflow run triggered by **your** merge commit on `main`, not unrelated later pushes.

---

## CI retry budget

Inherits babysit+ §5 (5 PR-caused / 3 flaky). **Additional** pre-UAT remedial rounds: max **3** full babysit-uat loops per original PR; then halt with control-issue / PR comment.

---

## Escalation (halt)

Same as babysit+ §9. Plus: infra-only UAT blockers (`UAT_AUTO_MIGRATE`, WAF) — human ops per `docs/e2e/uat-promote-manual.md`.

---

## Related

| Skill | When |
|-------|------|
| `/babysit-plus` | Intermediate execute-plan merges; PRs that skip pre-UAT |
| `/execute-plan` | Final main merge delegates here |
| `/pre-push-verify` | Before every push |
