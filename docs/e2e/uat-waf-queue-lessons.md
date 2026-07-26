# UAT WAF, smoke, and queue — lessons learned (Jul 2026)

Institutional knowledge from the Jul 24–25 deploy/smoke/coordinator incident chain. Use this **before** debugging the same symptoms again.

**Related:** [uat-live-operations-runbook.md](./uat-live-operations-runbook.md) · [uat-coordinator-plan.md](../agent-efficiency/uat-coordinator-plan.md) · `.agents/memory/uat-live-e2e-triage.md`

---

## TL;DR decision tree

```
deploy-uat smoke failed on "Warm up UAT auth before live smoke"
  ├─ Log shows Tiger Protect HTML (503, o2s-browser-check) on signup
  │    ├─ /backend/health passed? → YES: health-only WAF clear is insufficient (#351)
  │    ├─ Fix in code: passHostingWaf must probe POST /backend/api/auth/signup (JSON 400 = OK)
  │    └─ Still fails after #351? → Retry later; avoid duplicate browser warmups in same deploy
  ├─ Stuck on #/landing 120s after UI signup
  │    └─ Same root cause — Flutter signup API still WAF-blocked; do not add curl/Node retries
  ├─ promote-uat skipped (promote_tag_skipped / head_entry_failed)
  │    └─ See [Queue stuck](#queue-stuck-promote-or-deploy-skipped) below
  └─ uat-coordinator-dispatch succeeded but no agent launched
       ├─ infra_failed head? → Expected skip (infra_only_failure_no_hold)
       └─ failed head + no <!-- uat-coordinator-run -->? → Check launch-cursor-agent require guard (#346)
```

---

## WAF / smoke lessons

### 1. Curl and Node `fetch` cannot solve o2switch JS challenges

Tiger Protect (`o2s-browser-check`) requires a **real browser with JS**. No User-Agent trick, retry loop, or header change fixes curl/Node on auth endpoints.

| Approach | Works on live UAT auth? |
|----------|------------------------|
| `curl` / `scripts/ci/warmup-uat-auth.sh` | **No** — deprecated for deploy smoke (#332) |
| Node `fetch` in `global-setup.ts` on `/backend/health` | Sometimes — defer on WAF body, do not fail deploy (#343) |
| Node `fetch` on `/backend/api/auth/signup` | **No** — removed from `createTestUser` fallback (#351) |
| Headed Chromium + `passHostingWaf` + in-browser `fetch` | **Yes** — canonical path |

**Do not reintroduce:** curl auth warmup in `deploy-uat.yml`; direct Node signup fallback in `createTestUser`.

### 2. `/backend/health` passing does not mean auth is reachable

Tiger Protect scrutinizes **signup/login** more than health. A green health probe + cleared page shell can still leave signup returning WAF HTML.

**Fix (#351):** `passHostingWaf` loops until **both** probes succeed in-browser:

1. `GET /backend/health` → JSON `{"status":"OK"}`
2. `POST /backend/api/auth/signup` with `{}` → JSON **4xx** validation error (not WAF HTML)

Helpers: `e2e/playwright/support/waf.ts`, `e2e/playwright/support/waf-markers.ts` (`authSignupProbeReachable`).

**Anti-pattern:** Marking `sessionWafCleared = true` when only health returns OK — causes `createTestUser` to hammer a still-blocked signup API, then UI signup stalls on `#/landing`.

### 3. Browser warmup architecture (keep this stack)

| Piece | Role |
|-------|------|
| `uat-post-deploy-smoke.sh` | curl health + landing priming (OK for health only) |
| `uat-auth-warmup.spec.ts` (`warmup-uat` project) | Real browser auth gate before `@smoke-uat` (#332) |
| `passHostingWaf` | Page challenge + health + **auth** probes (#315, #351) |
| `stealth.ts` | Hide `navigator.webdriver` on live UAT |
| `prepareLiveApiAccess` | WAF warmup then route `api-fetch.ts` through browser |
| `E2E_SKIP_NODE_UAT_PREFLIGHT=1` | Skip Node health preflight in smoke when browser warmup follows (#343) |

Playwright live UAT runs **headed** when `E2E_TLS_INSECURE=1` (`playwright.config.ts`).

### 4. WAF marker detection must include French

Pass the full `WAF_MARKERS` array into `page.evaluate` probes (#315). Missing `Test de sécurité` caused `'down'` instead of `'waf'` → premature throw instead of retry.

Markers live in `e2e/playwright/support/waf-markers.ts`.

### 5. Error messages must distinguish probe failures

When debugging CI logs:

| Thrown message | Meaning |
|----------------|---------|
| `UAT backend is not healthy at …/backend/health` | Health probe failed (Passenger, SPA rewrite, etc.) |
| `UAT auth signup is still blocked by hosting WAF at …/signup` | WAF HTML on auth after page cleared — workflow retries after cooldown; check cookie persistence (#17) |
| `UAT auth signup is not reachable at …/signup` | Non-WAF HTML/5xx on auth — app/route problem |
| `Post-login route not ready (url=…#/landing)` | Signup never completed — often downstream WAF on auth API |

### 6. `createTestUser` flow on live UAT

1. `prepareLiveApiAccess` → `passHostingWaf` (must finish auth probe)
2. Browser-fetch signup (up to 3 attempts)
3. UI signup fallback only if API never created a user

Do **not** add Node-fetch between steps 2 and 3 — it always fails on WAF and wastes ~15s.

---

## UAT queue & coordinator lessons

### 7. `infra_failed` vs `failed` — promotion must not freeze on WAF alone

| Entry state | `queueHeadHold` blocks? | Coordinator auto-launch? |
|-------------|-------------------------|---------------------------|
| `failed` / `remedial` | **Yes** | Yes (if dispatch runs) |
| `infra_failed` | **No** | **No** (`infra_only_failure_no_hold`) |

WAF-only smoke failures should be `infra_failed` (#331) so later merges keep promoting.

**Do not** mark pure WAF smoke failures as `failed` — that froze all of `main` until manual recovery.

### 8. Failed head blocks promote even when `promote_hold` is clear

`queueHeadHold` reacts to head `failed`/`remedial` **independently** of `promote_hold`.

**Symptom:** `promote-uat` skips with `head_entry_failed`; deploy never tagged (`promote_tag_skipped`).

**Fixes:**

- **#344:** `enqueueEntry` auto-`setBarrier` when a newer merge follows a `failed` head (not `remedial`)
- **Manual recovery:** `set-barrier --sha <good-merge>` + push `uat-YYMMDD-PR` tag if promote was already skipped

### 9. Coordinator dispatch crashed on `require()` — fix launch guard (#346)

`launch-uat-coordinator.js` requires `launch-cursor-agent.js`, which called `main()` unconditionally → `ISSUE_NUMBER required` before any Cursor API call.

**Fix:** `if (require.main === module) { main()… }` in `launch-cursor-agent.js`.

**Verify:** `uat-coordinator-dispatch.yml` log should show payload JSON, not immediate `ISSUE_NUMBER` throw. Issue #313 should get `<!-- uat-coordinator-run:` only on **code** `failed` heads.

### 10. When to run `uat-queue-health.yml`

| Run when | Do not run when |
|----------|-----------------|
| Deploy run reached terminal state (pass/fail) | Full `deploy-uat` still in progress |
| Stale watcher lease suspected | — |
| First-ever baseline (weekly cron never fired) | — |
| `failed`/`remedial` head + no coordinator marker | `infra_failed` head only — health job **will not** re-dispatch |

`DISPATCH_RECOVERY=true` (default) only dispatches for `failed`/`remedial` heads (`uat-queue-recovery.js`).

### 11. Coordinator watcher lease orphans

Acquiring a 90-minute lease **before** a successful agent launch blocked all promotion (#342 / coordinator plan §7).

**Guards:** defer ledger commit until launch succeeds; `releaseWatcherIfHolderRunFinished`; `uat-queue-health` stale lease recovery.

### 12. Duplicate browser warmups in one deploy (added Jul 26)

**Problem:** `deploy-uat.yml` ran `test:warmup-uat` in **post-deploy smoke** and again in **live smoke E2E** — separate jobs, separate Playwright processes, same GitHub Actions IP. Post-deploy warmup passed in ~5s; live smoke warmup failed after ~2min with WAF HTML on signup. Tiger Protect rate-limits repeated auth probes from one IP.

**Fix:** HTTP health only in post-deploy smoke; single `test:live-uat-gate` (`warmup-uat` + `uat-smoke` projects) in one Playwright process for live smoke.

**Do not reintroduce:** warmup in both smoke jobs; separate `npm run test:warmup-uat` then `test:smoke-uat` in the same job.

### 13. Catch-up promote tags must trigger deploy (added Jul 26)

**Problem:** `uat-promote-catchup.yml` creates `uat-*` tags after the 90-minute cadence elapses, but `deploy-uat.yml` only listened to `workflow_run` from **Promote UAT (tag on merge to main)** — not **UAT promote catch-up**. Tags from catch-up never deployed (e.g. `uat-260726-386` at 09:53, no deploy run).

**Fix:** Add `UAT promote catch-up` to `deploy-uat.yml` `workflow_run.workflows` (GITHUB_TOKEN tag push still does not fire `on: push: tags`).

### 14. Playwright warmup failures must set `SMOKE_FAILURE_KIND=waf`

**Problem:** `uat-post-deploy-smoke.sh` (curl health) sets `failure_kind` on the smoke job output. When health passes but **`test:warmup-uat`** fails (auth signup still WAF-blocked after page challenge — the #351 scenario), `SMOKE_FAILURE_KIND` stayed empty. `assert-uat-gates.sh` then classified the run as **`code`**, not `infra_only` — freezing promotion and misrouting the coordinator (uat-coordinator-plan §6 residual risk).

**Symptom:** Log shows `UAT auth signup is still blocked by hosting WAF` in warmup, but notify handler logs `GATE_FAILURE_CLASS: code`.

**Fix:** `scripts/ci/classify-uat-smoke-failure.sh` runs after health + warmup; when health succeeded and warmup failed → `failure_kind=waf` (health OK implies auth/WAF path, not Passenger crash).

**Do not:** Treat warmup-only WAF failures as code regressions; do not add curl/Node auth retries.

### 15. Per-test `resetHostingWafSession()` re-probes signup (added Jul 26)

**Problem:** After #387 (single Playwright run), deploy [30203441553](https://github.com/KanopeeKa/AgathaCheck/actions/runs/30203441553) passed the a11y smoke test then failed on the **second** `@smoke-uat` test. `testUser` and `loginAs` each called `resetHostingWafSession()` → full `passHostingWaf` with auth signup probe again → WAF after ~2.3m.

**Fix:** Reuse in-process `sessionWafCleared` across `@smoke-uat` tests; `loginAs` clears browser cookies but does not reset the WAF session flag. Anonymous sharing tests use `prepareLiveApiAccess` after cookie clear without reset.

**Do not reintroduce:** `resetHostingWafSession()` in `testUser` / `loginAs` fixtures for live UAT smoke.

### 16. Catch-up skip must not fall through to tag slow-scan (added Jul 26)

**Problem:** Deploy [30207687290](https://github.com/KanopeeKa/AgathaCheck/actions/runs/30207687290) was **cancelled** on `Resolve trigger context` after 5 minutes. Catch-up promote [30207665212](https://github.com/KanopeeKa/AgathaCheck/actions/runs/30207665212) skipped **Create UAT tag (catch-up)** (cadence still active — 66 min wait). `resolve-uat-deploy-trigger.sh` only recognized skipped job name `Create UAT tag`, not the catch-up variant → fell through to `slow_scan()` over 137 tags → hit `resolve-trigger` `timeout-minutes: 5`.

**Fix:** Treat any job whose name starts with `Create UAT tag` as the promote-tag step (merge promote + catch-up).

**Do not:** Rely on full tag scan when promote/catch-up skipped tag creation — skip deploy immediately with `promote_tag_skipped`.

### 17. WAF cookies must persist across Playwright test contexts (added Jul 26)

**Problem:** Deploy [30210675285](https://github.com/KanopeeKa/AgathaCheck/actions/runs/30210675285) — `warmup-uat` passed but the first `uat-smoke` test failed with WAF on signup after 2.2m. #390 reused `sessionWafCleared` in Node memory, but each Playwright test gets a **fresh browser context** without Tiger Protect cookies. `passHostingWaf` returned early → new context re-ran full warmup and hit rate limits.

**Fix:**

1. `persistWafStorageState` after warmup saves cookies to `playwright/.uat-waf-storage.json`
2. `uat-smoke` project loads that `storageState` and `depends: ['warmup-uat']`
3. `passHostingWaf` verifies in-browser probes before trusting `sessionWafCleared`
4. `scripts/ci/run-live-uat-gate.sh` retries once after 180s on WAF classification

**Do not:** Ask operators to whitelist GitHub Actions egress IPs — not available. SSH whitelist (`o2switch-ssh-whitelist.sh`) is port 22 only and unrelated to HTTP WAF.

---

## Operator recovery cheat sheet

### Queue stuck (promote or deploy skipped)

```bash
# Inspect ledger on coordination issue (default #313)
node scripts/uat_queue_runtime.js reconcile --issue 313
node scripts/uat_queue_runtime.js health-check

# If head is failed and blocking:
node scripts/uat_queue_runtime.js set-barrier --sha <merge-on-main> --write --issue 313

# Manual tag if promote already skipped (repo admin)
git tag uat-YYMMDD-<pr> <merge-sha>
git push origin uat-YYMMDD-<pr>
```

### After merging a WAF fix

1. Merge lands → `enqueue` runs (or `node scripts/uat_queue_runtime.js enqueue --merge … --pr … --write`)
2. Wait for `deploy-uat` → `run-live-uat-gate.sh` (warmup + smoke, auto-retry on WAF)
3. If still WAF after retry → lower Tiger Protect sensitivity in cPanel or wait for rate-limit cooldown — **not** CI IP whitelist

---

## PR / fix map (Jul 24–25 chain)

| PR | Outcome |
|----|---------|
| #331 | `infra_failed` — WAF does not freeze promotion |
| #332 | Browser `warmup-uat` replaces curl auth warmup |
| #343 | WAF preflight deferral in `global-setup`; `/o/orgs` nav fixes |
| #344 | Auto `setBarrier` when enqueue follows failed head |
| #346 | `require.main` guard — coordinator dispatch no longer crashes |
| #351 | Auth signup probe in `passHostingWaf`; remove Node fetch fallback |

---

## Anti-patterns (do not repeat)

1. **Health-only WAF clearance** then immediate signup API calls
2. **Curl or Node retries** on `/backend/api/auth/signup` in CI
3. **`failed` ledger state** for pure WAF/infra smoke failures
4. **`main()` at module load** in scripts that are both CLI and `require()` libraries
5. **Polling UAT prod-ready** in agent sessions — enqueue and continue (`babysit-plus` §8)
6. **Running `uat-queue-health` mid-deploy** — race with in-flight smoke
7. **Expecting coordinator auto-fix for `infra_failed`** — apply workflow/code mitigations; never request CI IP whitelist

---

## Key files (bookmark)

| Concern | Path |
|---------|------|
| WAF session + probes | `e2e/playwright/support/waf.ts`, `e2e/playwright/support/waf-markers.ts` |
| Auth warmup test | `e2e/playwright/tests/uat-auth-warmup.spec.ts` |
| createTestUser | `e2e/playwright/support/ui-auth.ts` |
| Node preflight deferral | `e2e/playwright/support/global-setup.ts` |
| Deploy smoke job | `.github/workflows/deploy-uat.yml` (`smoke`, `uat-e2e-smoke`) |
| Live gate + WAF retry | `scripts/ci/run-live-uat-gate.sh` |
| Gate classification | `scripts/ci/assert-uat-gates.sh`, `scripts/ci/classify-uat-smoke-failure.sh` |
| Queue library | `scripts/lib/uat_queue_lib.js` |
| Queue recovery | `scripts/ci/uat-queue-recovery.js` |
| Coordinator dispatch | `.github/scripts/uat-coordinator-dispatch.js` |
| Agent launch guard | `.github/scripts/launch-cursor-agent.js` |
| Coordinator plan | `docs/agent-efficiency/uat-coordinator-plan.md` |
