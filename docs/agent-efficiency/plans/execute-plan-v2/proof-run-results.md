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

**Control issue:** [#1975](https://github.com/KanopeeKa/AgathaCheck/issues/1975) (closed by the driver, 2026-11-01T21:22:15Z)  
**Init:** `8c825bd1` on `cursor/proof-build-label-7f3b-init` (branch deleted after this doc PR)  
**Driver fixes exercised:** [#1971](https://github.com/KanopeeKa/AgathaCheck/pull/1971) (observe after integration delete), [#1972](https://github.com/KanopeeKa/AgathaCheck/pull/1972) (epoch lock: no reset), [#1974](https://github.com/KanopeeKa/AgathaCheck/pull/1974) (`wait(hold)`), and [#1973](https://github.com/KanopeeKa/AgathaCheck/pull/1973) `wait(<reason>)` logging only. **#1973 merge fallback:** not exercised (auto-merge completed normally; scenario-only).

**Verdict (runbook §8):** **PASS** on the §8 pass/fail rules (driver closed #1975 with the four evidence links; no STOP; launches within budget; UAT curl prints `execute-plan-v2-proof-2`). **Drills: 1 passed, 2 not exercised.** The owner accepted this result and decided GO on 2026-11-01; drill 2 is tracked in [#1981](https://github.com/KanopeeKa/AgathaCheck/issues/1981).

### Owner drills (§8 steps 3–4)

| Drill | Exercised? | Notes |
|-------|------------|--------|
| **1 — injected phase-CI failure** | **Yes — PASS** | Hold on [#1976](https://github.com/KanopeeKa/AgathaCheck/pull/1976) **19:51:35Z**; PR ready **20:02:02Z** (worker); drill commit [`bcffee8`](https://github.com/KanopeeKa/AgathaCheck/commit/bcffee8) **20:03:34Z**; `ci-gate` red **~20:06:03Z**; hold removed **20:06:20Z**; `fix-ci` launch **20:06:43Z** (`bc-f6761640`); fix [`5d7393c`](https://github.com/KanopeeKa/AgathaCheck/commit/5d7393c); merged **20:12:11Z**. Driver run [41344745956](https://github.com/KanopeeKa/AgathaCheck/actions/runs/41344745956) logged **`driver:wait(hold)`**. |
| **2 — cancel phase-2 worker** | **No** | Phase-2 worker `bc-ae2eefc8-a42b-4b1e-9e62-390cab85c8a3` (launched **20:33:33Z**) is **hidden** from the owner Cursor dashboard (API-launched workers). Owner cancelled a **different** agent (no effect). [#1977](https://github.com/KanopeeKa/AgathaCheck/pull/1977) marked ready **20:40:16Z**, merged **20:40:47Z** without relaunch. Relaunch path covered only by scenario `p-draft-lease-stale-relaunch.json`. **Follow-up:** [#1981](https://github.com/KanopeeKa/AgathaCheck/issues/1981). |

**Expected launches (full drills):** phase 1 = **2**, phase 2 = **2**, release = **0**.  
**Observed launches:** phase 1 = **2**, phase 2 = **1**, release = **0**.

| Phase | Kind | Agent id | Launched |
|-------|------|----------|----------|
| 1 | implement | `bc-da40ebd6-cad3-4eab-bec8-c852dfdb8218` | 2026-11-01T19:50:46Z |
| 1 | fix-ci | `bc-f6761640-8954-4bf8-9ddf-155ee49bebf3` | 2026-11-01T20:06:43Z |
| 2 | implement | `bc-ae2eefc8-a42b-4b1e-9e62-390cab85c8a3` | 2026-11-01T20:33:33Z |

### Human actions (actual)

| Action | When | Effect |
|--------|------|--------|
| Approval (`approve-autonomous`) | 2026-11-01T19:50:17Z | Plan started (single approval; **no epoch reset**) |
| Drill 1 — hold + injected test break | 19:51:35Z – 20:06:20Z | Red `ci-gate` → `fix-ci` → merge #1976 |
| Drill 2 — dashboard cancel (wrong agent) | During phase 2 | No effect on lease; drill 2 not exercised |
| Drills 1–2 (expected) | Drill 1 only | See table above |

### Timeline and wall time

- **Approval:** 2026-11-01T19:50:17Z → **issue closed** 2026-11-01T21:22:15Z (**~1 h 32 min** wall time).
- **Phase 1:** [#1976](https://github.com/KanopeeKa/AgathaCheck/pull/1976) merged **20:12:11Z** (`5ea9389`).
- **Phase 2:** [#1977](https://github.com/KanopeeKa/AgathaCheck/pull/1977) merged **20:40:47Z** (`c189d2b`).
- **Release:** [#1978](https://github.com/KanopeeKa/AgathaCheck/pull/1978) merged **21:05:31Z** (`37ef096`); integration branch delete-on-merge; driver continued through UAT stage.
- **Pre-UAT E2E:** [41350180669](https://github.com/KanopeeKa/AgathaCheck/actions/runs/41350180669) (success **21:05:33Z** – **21:16:41Z**).
- **UAT tag:** `uat-261101-1978` → `37ef096`.
- **Deploy UAT:** [41351232460](https://github.com/KanopeeKa/AgathaCheck/actions/runs/41351232460) (success **21:17:19Z** – **21:21:28Z**; smoke + **Prod ready** green).

### Fix checks (WP9 driver patches)

| Check | Result |
|-------|--------|
| **(a)** Tracking after integration branch auto-deleted on release merge | **Pass** — release #1978 merged **21:05:31Z**; transitions `release:open → awaiting-preuat → … → complete` without losing PR/UAT state. |
| **(b)** `driver:merge` fallback | **Not fired** — no `driver:merge` in driver logs for this plan. |
| **(c)** No epoch reset on approval | **Pass** — single approval comment; launch budget accumulated (3 launches), not zeroed. |
| **(d)** `wait(hold)` observability | **Pass** — `driver:wait(hold)` on run [41344745956](https://github.com/KanopeeKa/AgathaCheck/actions/runs/41344745956). |

**Every `driver:wait(<reason>)` seen in driver logs:** `hold`, `agent-alive`, `checks`, `copilot`, `preuat`, `deploy`.

### Evidence

| Item | Value |
|------|--------|
| Pre-UAT E2E | https://github.com/KanopeeKa/AgathaCheck/actions/runs/41350180669 |
| UAT tag | `uat-261101-1978` → `37ef096b0071e94862b024e4c0250b2e13ee1305` |
| Deploy UAT | https://github.com/KanopeeKa/AgathaCheck/actions/runs/41351232460 (smoke + Prod ready) |
| `curl -s https://uat.agathatrack.com/backend/health \| jq -r .proof_label` | `execute-plan-v2-proof-2` (owner-confirmed 2026-11-01) |
| Cursor cost | Model Composer 2.5 fast. P1 implement (`bc-da40ebd6`) ~49.1K / 200K; P1 fix-ci (`bc-f6761640`) ~43.3K / 200K; P2 implement (`bc-ae2eefc8`) ~42.6K / 200K (total ~135.0K; 7f3a was ~82K for 2 workers). Dashboard figures are context-window use, not exact billing. Manual sessions not included (e.g. `bc-2170c664` ~58.2K / 200K). |
| Final driver state | `state: complete`, `stop: null` (status JSON on #1975, updated **21:21:39Z**) |
