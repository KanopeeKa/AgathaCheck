---
name: babysit-uat
description: Babysit+ through merge, then gate on pre-UAT E2E on main. On failure delegates remedial work to /e2e-debug, then merges remedial PR and re-watches. Does not poll promote-uat or deploy-uat.
---

# Babysit-UAT

**Babysit+ through merge**, then **pre-UAT E2E green** for that merge commit on `main`. Does **not** poll `promote-uat` or `deploy-uat` (current policy).

**Builds on:** `/babysit-plus` (§0–7) · **Remedial:** `/e2e-debug` (§Phase 3) · **Canonical policy:** `docs/agent-efficiency/autonomous-pr-policy.md`  
**Shard risk:** `scripts/babysit_uat_shard_risk.mjs` · **Scope resolve:** `scripts/e2e_debug_resolve.mjs`  
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

**`composer-2.5` only** for babysit phases (sync, triage, CI, merge, UAT orchestration). **`/e2e-debug` subagents also use `composer-2.5` only.**

---

## Phase 1 — Babysit+ (mandatory)

Run **all** of `/babysit-plus` §0–7:

1. Sync, triage, debt, CI loop, `pre-push.sh`
2. **Always squash-merge** when gates pass (no `manual` / `labeled` modes)
3. Record `merge_sha` from merged PR

**Stop babysit-plus scope here** — continue into Phase 2 in this skill only.

---

## Phase 2 — Shard risk sense-check

From the **merged PR file list** (pre-merge proactive signal):

```bash
node scripts/babysit_uat_shard_risk.mjs --pr <n>
```

| `merge_action` | Round 1 behaviour | Round 2+ behaviour |
|----------------|-------------------|---------------------|
| `wait` (low/medium only) | Poll `pre-uat-e2e` for `merge_sha`; **no** local runs until failure | **Wait** for workflow failure first |
| `act_now` (any **high** shard) | Poll CI **in parallel** with **proactive `/e2e-debug --proactive`** on remedial branch | Wait for CI failure first |

**Zero-risk shards:** never run locally unless CI reports them failed.

---

## Phase 3 — Remedial (delegate to /e2e-debug)

When CI fails **or** `merge_action == act_now` (round 1 proactive):

Run **/e2e-debug** with:

| Parameter | Value |
|-----------|-------|
| `merge_sha` | failing merge (omit for proactive-only before first failure) |
| `failed_shards` | from `./scripts/babysit_uat_watch_preuat.sh <merge_sha> --json` when available |
| `round` | current remedial round |
| `plan_id` | when in execute-plan |

**Do not** duplicate remedial steps here — `/e2e-debug` owns triage, remedial branch, parallel shard workers, local validation, remedial PR.

**Exit Phase 3** when remedial PR is open/updated and ready → **Phase 4**.

---

## Phase 4 — Babysit-UAT remedial (round 2+)

On the **remedial PR** from `/e2e-debug`:

1. Full **Phase 1** (babysit+ merge remedial to `main`)
2. **Phase 2** with `round >= 2`: **only** `./scripts/babysit_uat_watch_preuat.sh <merge_sha>` until failure or success
3. On failure → **Phase 3** again (`/e2e-debug` with `round >= 2`, failed shards only)
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
| `/e2e-debug` | Pre-UAT remedial fix loop (Phase 3) |
| `/babysit-plus` | Intermediate execute-plan merges; PRs that skip pre-UAT |
| `/execute-plan` | Final main merge delegates here |
| `/pre-push-verify` | Before every push; `--e2e-shards` during remedial |
