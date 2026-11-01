---
title: Execute-plan v2 proof run results
owner: Kanopee
audience: agent
status: active
last_updated: 2026-11-01
tags: [agent, execute-plan, proof]
---
# Execute-plan v2 proof run results

Record for runbook §8 (`runbooks-proof-retirement.md`). One section per plan id.

## `proof-build-label-7f3a`

**Control issue:** [#1966](https://github.com/KanopeeKa/AgathaCheck/issues/1966) (closed by owner after revoke)  
**Init:** `eae26605` on `cursor/proof-build-label-7f3a-init` (2026-10-28; branch deleted after init)  
**Final driver state:** `stopped`, reason **`expired`** (2026-10-31T14:05:16Z), label **`needs-owner`**. Owner then **revoked** the plan and **closed** #1966. The driver did **not** close the issue with the four evidence links.

**Verdict (runbook §8):** **FAIL** — STOP `expired`, extra human actions, drills not run, issue not closed by the driver. The **live shipping chain** still worked: phases → integration → release → Pre-UAT → tag → Deploy UAT (see evidence).

### Owner drills (§8 steps 3–4)

| Drill | Exercised? | Notes |
|-------|------------|--------|
| **1 — injected phase-CI failure** | **No** | [#1967](https://github.com/KanopeeKa/AgathaCheck/pull/1967) marked ready **2026-10-28T14:07:53Z**, merged **14:08:28Z** (~**35 seconds**). Window too short to inject by hand. |
| **2 — cancel phase-2 worker** | **No** | [#1968](https://github.com/KanopeeKa/AgathaCheck/pull/1968) draft PR **14:34:41Z**, ready **14:35:36Z** (~**55 seconds** draft window). Window too short to cancel by hand. |

**Expected launches:** phase 1 = **2**, phase 2 = **2**, release = **0** (`implement` + `fix-ci` / `implement` ×2 after cancel).  
**Observed launches:** phase 1 = **1**, phase 2 = **1**, release = **0**. Status table on #1966 showed **0** launches after the duplicate approval restarted the epoch (see human actions).

Drills were not run because the **procedure assumes longer ready/draft windows** than this run produced — a **gap in the runbook**, not owner error.

### Human actions (actual)

| Action | When | Effect |
|--------|------|--------|
| Approval (first `approve-autonomous`) | 2026-10-28T13:58:36Z | Plan started |
| Duplicate `approve-autonomous` | 2026-10-29T12:26:02Z | Approve workflow **rejected** it (integration branch already existed), but the driver treats the **latest valid** approve/resume comment as in force (`findControlComments` in `scripts/lib/execute_plan_approval.js`). That comment **restarted the plan clock and budgets**, which is why the status table showed **0** launches. |
| Manual “retrigger checks” commit on `-p2` | 2026-10-29T12:30:06Z (`2bce104`) | Extra human action; unblocked merge of #1968 after driver stall (see below) |
| Revoke + close | After expiry | Owner ended the programme; not in the runbook’s expected human-action set |
| Drills 1–2 | Not performed | Windows ~35s / ~55s |

### Timeline and wall time

- **Approval:** 2026-10-28T13:58:36Z → **Deploy UAT** complete **2026-10-29T13:23Z** (~**23.5 h** total).
- Of that, **~22 h** was the [#1968](https://github.com/KanopeeKa/AgathaCheck/pull/1968) stall: `ci-gate` green on head `6ea2d33` at **2026-10-28T14:37:41Z**; driver armed auto-merge **14:36:15Z**; every subsequent 30-minute pass logged only **`action driver:wait`** with **no reason** (observability gap); merge at **2026-10-29T12:33:48Z** only after commit `2bce104`.

### Root cause of STOP `expired` (driver never reached UAT stage)

[#1969](https://github.com/KanopeeKa/AgathaCheck/pull/1969) (release PR) merged to `main` at **2026-10-29T13:07:36Z** (`dddf7f9`). GitHub **delete-on-merge** removed `cursor/proof-build-label-7f3a-integration-7f3a` at **13:07:39Z**. That was possible because the **`deletion` rule had been dropped** from integration ruleset **25473354**, as runbook §7.2 says to do after WP8.

`execute_plan_observe.js` only resolves phase PRs and the release PR when **`integration.exists`** (`release: { pr: integration.exists ? … : null }`). With the branch gone it saw **no PRs** and logged **`release:open → phase:pending`** at **13:08:07Z**. It **never entered the UAT stage** and remained there until the approval window **expired**.

A lookup by head branch name (`GET /pulls?head=KanopeeKa:<branch>&state=all`) still returns #1969 and #1968 after deletion, so the fix is to **drop the `integration.exists` condition** (or equivalent). Runbook §7.2/§7.3 (“deleted branches do not matter”) need correcting.

### Evidence

| Item | Value |
|------|--------|
| Pre-UAT E2E | https://github.com/KanopeeKa/AgathaCheck/actions/runs/40879099352 (success, 2026-10-29 13:07–13:19Z, push on `dddf7f9`; **not** dispatched by the driver) |
| UAT tag | `uat-261029-1969` → `dddf7f9` |
| Deploy UAT | https://github.com/KanopeeKa/AgathaCheck/actions/runs/40880897299 (success 13:19–13:23Z; smoke and `Prod ready` green) |
| `curl -s https://uat.agathatrack.com/backend/health \| jq -r .proof_label` | `execute-plan-v2-proof` |
| Cursor cost | Model Composer 2.5 fast. P1 implement (`bc-8d41f63b`) ~47.4K / 200K tokens; P2 implement (`bc-29a98d66`) ~34.7K / 200K tokens (~82K total). Dashboard figures are context-window use, not exact billing. Manual sessions (init, retrigger, results doc) not included. |
| `wait` reasons | Driver log on #1968 stall: only **`action driver:wait`** (no reason in log); final stop **`expired`** |

### Drills not run — would they likely have failed?

**Summary:** Decision logic for `fix-ci` and cancel/relaunch is covered by scenario tests (32 fixtures + driver tests). This run does **not** disprove that logic. What failed in production was **procedure timing** (drill windows), **driver behaviour** (auto-merge armed + green checks but no merge for ~22 h; no timeout/fallback), **duplicate approval restarting epoch**, and **observe** after integration branch deletion.

#### Drill 1

- **Procedure:** ~35 s ready→merge on #1967 — not human-feasible; runbook should allow a **hold** or longer window before auto-merge.
- **If injected:** scope allows test-only break; `fix-ci` ladder is tested. **Same ~22 h auto-merge stall class** as #1968 could still block merge after a fix unless driver gains a fallback when checks are green.

#### Drill 2

- **Procedure:** ~55 s draft window on #1968 — not human-feasible.
- **If cancelled in time:** relaunch paths are scenario-tested; heartbeat up to 30 min is by design.

### Side note (outside WP9)

Deploy-prod run https://github.com/KanopeeKa/AgathaCheck/actions/runs/40881494315 failed only at **“Production post-deploy smoke”** (`main.dart.js returns 200 while PROD_PUBLIC_MODE=coming_soon`). The same failure has occurred on every deploy-prod run since at least **2026-10-27**. Track in a **separate issue** (not part of WP9 proof).

---

## `proof-build-label-7f3b`

**Blocked on driver fixes:** (a) find PRs by head branch name when the integration branch is gone; (b) fallback when auto-merge is armed and checks are green; (c) a rejected repeat `approve-autonomous` must **not** restart the clock and budgets; (d) a **hold** label so the owner can perform drills.

The plan must change something **new**: `proof_label` is already on `main` (e.g. value `execute-plan-v2-proof-2`).
