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
  │    └─ Still fails after #351? → Host action: whitelist GitHub Actions egress in Tiger Protect
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

Helpers: `e2e/playwright/support/waf.ts`, `waf-markers.ts` (`authSignupProbeReachable`).

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
| `UAT auth signup is still blocked by hosting WAF at …/signup` | WAF HTML on auth after page cleared — wait or whitelist |
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
2. Wait for `deploy-uat` smoke → `test:warmup-uat`
3. If still WAF HTML on signup → **host whitelist**, not more client retries

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
7. **Expecting coordinator auto-fix for `infra_failed`** — escalate host/WAF config instead

---

## Key files (bookmark)

| Concern | Path |
|---------|------|
| WAF session + probes | `e2e/playwright/support/waf.ts`, `waf-markers.ts` |
| Auth warmup test | `e2e/playwright/tests/uat-auth-warmup.spec.ts` |
| createTestUser | `e2e/playwright/support/ui-auth.ts` |
| Node preflight deferral | `e2e/playwright/support/global-setup.ts` |
| Deploy smoke job | `.github/workflows/deploy-uat.yml` (`smoke`, `uat-e2e-smoke`) |
| Gate classification | `scripts/ci/assert-uat-gates.sh` |
| Queue library | `scripts/lib/uat_queue_lib.js` |
| Queue recovery | `scripts/ci/uat-queue-recovery.js` |
| Coordinator dispatch | `.github/scripts/uat-coordinator-dispatch.js` |
| Agent launch guard | `.github/scripts/launch-cursor-agent.js` |
| Coordinator plan | `docs/agent-efficiency/uat-coordinator-plan.md` |
