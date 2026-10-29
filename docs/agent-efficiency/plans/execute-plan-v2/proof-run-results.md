---
title: Execute-plan v2 proof run results
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-29
tags: [agent, execute-plan, proof]
---
# Execute-plan v2 proof run results

Record for runbook §8 (`runbooks-proof-retirement.md`). One section per plan id.

## `proof-build-label-7f3a`

**Control issue:** [#1966](https://github.com/KanopeeKa/AgathaCheck/issues/1966)  
**Init:** `eae26605` on `cursor/proof-build-label-7f3a-init` (2026-10-28)  
**Status (2026-10-29):** in flight — `release:open` ([#1969](https://github.com/KanopeeKa/AgathaCheck/pull/1969)); issue not closed yet.

### Owner drills (§8 steps 3–4)

| Drill | Exercised? | Notes |
|-------|------------|--------|
| **1 — injected phase-CI failure** (break test on phase-1 PR when ready) | **No** | Phase 1 ([#1967](https://github.com/KanopeeKa/AgathaCheck/pull/1967)) merged with **0** failed CI attempts and **1** `implement` launch only. |
| **2 — cancel phase-2 worker** (draft PR + live lease) | **No** | Phase 2 ([#1968](https://github.com/KanopeeKa/AgathaCheck/pull/1968)) completed with **1** `implement` launch; no cancel/relaunch observed. |

**Expected launches if drills had run:** phase 1 = 2 (`implement` + `fix-ci`), phase 2 = 2 (`implement` ×2 after cancel).  
**Observed launches:** phase 1 = 1, phase 2 = 1 (see status JSON on #1966).

### Human actions (actual)

| Action | When |
|--------|------|
| Approval (first comment) | 2026-10-28 — valid; plan started |
| Duplicate approval | 2026-10-29 — correctly **rejected** (integration branch already existed) |
| Drills 1–2 | Not performed |
| Extra (non-runbook) | Empty commit on `cursor/proof-build-label-7f3a-p2` to unblock ruleset merge after ~24h stuck auto-merge (see risks below) |

### Evidence (fill when complete)

| Item | Value |
|------|--------|
| Pre-UAT run URL | _pending_ |
| Deploy UAT run URL | _pending_ |
| UAT tag | _pending_ |
| `curl -s https://uat.agathatrack.com/backend/health \| jq -r .proof_label` | _pending_ (expect `execute-plan-v2-proof`) |
| Cursor cost | _pending_ |
| `wait` reasons seen | _pending_ (collect from driver logs / tick JSON at close) |

### Drills not run — would they likely have failed?

**Summary:** No strong evidence the **decision logic** would have failed; there **is** live evidence that **merge/auto-merge** and **timing** are the fragile parts. Automated coverage for both drill paths is good (32 scenario fixtures + driver unit tests, all green locally).

#### Drill 1 (`fix-ci` after red `ci-gate`)

**Reasons to expect success**

- Scenario `p-ready-red-fix-ci.json` (PR-ladder 4) expects `fix-ci` with `launch: true` on red `ci-gate / CI passed`.
- Phase 1 scope allows `server/test/healthProofLabel.test.js` with `tests` exception — breaking only the test assertion matches the runbook and should keep `execute-plan-scope` green.
- Live run: phase-1 worker implemented, passed CI, merged — same worker path (`implement`, bot token handoff, scope check) would apply to `fix-ci` with `cursor_model_fix`.
- Budget headroom: `ci_per_phase: 3`, `launches_per_phase: 5` — one injected failure + one fix launch is within caps.

**Reasons to worry**

1. **Timing window:** Phase 1 went **ready → merged in ~9 minutes** (2026-10-28). If the owner push landed after auto-merge, the drill would be **missed** (operational), not a driver bug.
2. **Merge/ruleset flake (observed on phase 2):** PR #1968 sat **`mergeStateStatus: BLOCKED`** with green rollup checks; GitHub REST merge reported required check `execute-plan-scope` (later `ci-gate`) “expected” despite successful check runs on the head SHA. Auto-merge did not complete until a **new head** re-ran CI. The same class of issue could delay or block the **post–fix-ci** merge even if `fix-ci` succeeded.
3. **Launch accounting nuance:** Unit test documents that some `fix-ci` decisions record launch phase key `"release"` when `decision.phase` is null; phase-PR ladder sets `phase: "1"`, so this is unlikely on drill 1 but worth knowing for budget tables.

**Verdict:** Logic likely **OK**; **merge reliability** and **owner timing** are the main failure modes, not missing `fix-ci` wiring.

#### Drill 2 (cancel worker → relaunch on draft)

**Reasons to expect success**

- Scenarios `p-draft-lease-alive-wait.json` and `p-draft-lease-stale-relaunch.json` cover live lease vs stale lease (`last_tick` older than 20 minutes) on draft PRs.
- `getAgentRunStatus` treats `CANCELLED` as terminal (same set as `FINISHED` / `ERROR`); `leaseAlive` then returns not alive → driver can launch `implement` again (PR-ladder 2).
- Driver polls Cursor on every pass when `status.lease` is set (`execute_plan_driver_actions.js`); heartbeat cron `*/30 * * * *` matches runbook “within 30 min” worst case if no CI/issue events fire.
- Live run: phase-2 worker reached **ready** and merged without cancel — no contradiction.

**Reasons to worry**

1. **Operational timing:** Cancel must happen while PR is **draft** and the cancelled run matches **`lease.agent_id`** on the control issue. Cancel after **ready** misses the drill.
2. **Worst-case latency:** If cancel happens just after a driver pass and no further webhooks fire, relaunch may wait until the **scheduled heartbeat** (up to ~30 minutes). That is by design, not necessarily failure.
3. **Stale lease on later states:** Status JSON on #1966 still carried the phase-2 `lease` into `release:open` (with a recent `last_tick_at`). Driver re-polls Cursor each pass; terminal status should not block release driver actions, but a long-lived **RUNNING** mis-report from the API could cause **`wait(agent-alive)`** on a subsequent **agent** launch (edge case, not exercised).

**Verdict:** Relaunch logic is **well tested**; drill failure would most likely be **owner timing** or **slow wake** (heartbeat-bound), not absent code paths.

#### Other live-run signals (not drills, but affect confidence)

- **Duplicate approval** after integration moved: harmless reject; does not stop an already-approved plan.
- **Phase 2 merge stall:** Real production friction on integration ruleset + check rollup; remediated outside runbook (extra commit). Treat as **platform/merge** risk for any phase ending in auto-merge, including post–fix-ci.

---

## `proof-build-label-7f3b`

_Not started._ Reserved if a second proof run is needed to exercise drills 1–2 or to rerun after a STOP.
