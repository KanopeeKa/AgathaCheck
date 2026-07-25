# UAT live E2E & deploy operations runbook

Institutional knowledge from UAT `@smoke` / deploy hardening (July 2026). Use this to **triage failures fast** and **avoid reintroducing** the same classes of bug.

**Related:** [uat-backend-node-modules-runbook.md](../uat-backend-node-modules-runbook.md) · [e2e-navigation-contract.md](../e2e-navigation-contract.md) · [e2e/README.md](../../e2e/README.md) · **[uat-waf-queue-lessons.md](./uat-waf-queue-lessons.md)** (Jul 2026 incident chain)

---

## Failure layers (where to look first)

```
GitHub Actions deploy-uat.yml
  ├─ Build / FTP / cPanel restart
  ├─ SSH backend deploy (uat-ssh-backend-deploy.sh)
  │    ├─ Passenger .htaccess merge
  │    ├─ node_modules symlink invariant
  │    └─ migrate.js up (when UAT_AUTO_MIGRATE=true)
  ├─ UAT post-deploy smoke (HTTP)
  ├─ UAT live smoke E2E (@smoke on https://uat.agathatrack.com)
  └─ UAT full E2E localhost (10 shards — not live UAT)
```

| Layer | Typical symptoms | First log / file |
|-------|------------------|------------------|
| **Workflow / secrets** | Smoke skipped; `ssh_invariant=failed` | Deploy job summary; `deploy-uat.yml` |
| **Passenger / node_modules** | `/backend/health` HTML not JSON | `docs/uat-backend-node-modules-runbook.md` |
| **DB migrations** | API `500` on routes using new tables/columns | SSH step `=== Database migrations ===` |
| **DB ownership** | `doit être le propriétaire de la relation …` | Same SSH step; `migrate.js` output |
| **Auth / rate limit** | `401` on API seed; `429` on signup; **all** smoke timeout on login | UAT access logs; `server/config/rateLimit.js`; UAT Node `E2E=1` |
| **Token shape** | `401` after login; E2E “unexpected token shape” | `e2e/playwright/support/normalize-stored-token.ts` |
| **E2E test pattern** | Timeout on `expectPetVisible` with no API error | Spec order: seed **before** `loginAs` |
| **Flutter / WAF** | WAF challenge HTML; semantics timeout; stuck `#/landing` after signup | `e2e/playwright/support/waf.ts`, `waf-markers.ts`, [uat-waf-queue-lessons.md](./uat-waf-queue-lessons.md) |
| **UAT queue** | `promote-uat` skipped; `head_entry_failed`; coordinator never launches | `scripts/uat_queue_runtime.js`, [uat-waf-queue-lessons.md](./uat-waf-queue-lessons.md) |

---

## Symptom → cause → fix

### Deploy job failed (`Build and deploy to UAT`)

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `ssh_invariant=failed`, smoke **skipped** | SSH whitelist, secrets, or remote script exit ≠ 0 | Deploy job log around `UAT backend deploy via SSH` |
| `FAIL 001_….sql: doit être le propriétaire` | App DB user lacks **table ownership** (GRANT ≠ OWNER) | `ALTER TABLE … OWNER TO <app_user>` on `public` objects; see [DB ownership](#db-ownership-for-migrations) |
| `migrate_pending_count` > 0 after deploy | `UAT_AUTO_MIGRATE` not `true`, or migration failed mid-run | Set env var; fix ownership; re-run deploy |
| `node_modules_kind=not_verified` | `UAT_SSH_ENABLED` not `true` | GitHub → Environments → **UAT** → `UAT_SSH_ENABLED=true` |

### API errors on live UAT (access logs / browser network)

| HTTP | Route / context | Likely cause | Fix |
|------|-----------------|--------------|-----|
| **500** | `GET /backend/api/pets/all` | Missing tables/columns (`foster_placements`, `custody_transfers`, `care_holder_*`) | Apply pending migrations (`014`, `020`, …) |
| **500** | `GET /backend/api/custody-transfers/pending` | `custody_transfers` table missing | Migration `020_org_custody.sql` |
| **401** | `POST /backend/api/pets` (E2E seed) | Malformed Bearer token (JSON-wrapped JWT in localStorage) | `normalizeStoredToken()` in E2E + ensure app stores raw JWT |
| **429** | `POST /backend/api/auth/signup` | Auth rate limit; many smoke workers | Signup-only E2E bypass (see [E2E bypass](#e2e-auth-rate-limit-bypass-uat-only)) |
| **401** | After deploy, valid user | Wrong `JWT_SECRET` / stale session | Re-login; verify UAT `.env` |

### Live `@smoke` Playwright failures

| Failure | Likely cause | Fix |
|---------|--------------|-----|
| `expectPetVisible` timeout after `createPet` | Pet created **after** `loginAs` — home list already painted empty | **Seed via API before login** (`testUser.accessToken`); see [API seed ordering](#api-seed-ordering-critical-for-live-uat) |
| `expectDueEntryOnHome` timeout | Home `DueEventsSection` not refreshed after API seed | `PetListPage.refreshByRemount()` after login |
| Health dashboard entry timeout on UAT only | Live latency / WAF | `isLiveHostingTarget()` longer timeouts; `prepareLiveApiAccess` in fixture |
| **Warmup** `test:warmup-uat` fails — WAF HTML on signup, health OK | Health-only WAF clear; auth endpoint still blocked | `passHostingWaf` auth probe (#351); see [uat-waf-queue-lessons.md](./uat-waf-queue-lessons.md) |
| **Warmup** stuck `#/landing` 120s | Signup API WAF-blocked; UI cannot complete auth | Same as above — do not add curl/Node retries |
| Signup smoke `429` | Bypass token not in workflow env | `E2E_BYPASS_TOKEN` on smoke step in `deploy-uat.yml` |
| **All** `@smoke` tests timeout ~2.4 min | Login rate limit — UAT Node missing `E2E=1` | Set `E2E=1` on UAT Node app (cPanel) and restart |
| `globalSetup` health probe fail | UAT down, WAF, or bad TLS chain | `E2E_TLS_INSECURE=1`, `NODE_TLS_REJECT_UNAUTHORIZED=0` on CI |

---

## Prevention guidelines

### API seed ordering (critical for live UAT)

**Rule:** When a test creates data via `playwright/support/api.ts` and then asserts on the **home pet list**, seed **before** `loginAs`.

```ts
// ✅ Robust — matches pet.profiles, health.tracking, weight @smoke
const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
const petList = await loginAs(page, testUser);
await petList.expectPetVisible(pet.name);

// ❌ Fragile on live UAT — list rendered empty at login
const petList = await loginAs(page, testUser);
const pet = await createPet(baseURL, token, 'Bella');
await petList.expectPetVisible(pet.name); // timeout
```

**When post-login mutation is required:** use `petList.refreshByRemount()` (heavier; use only when testing refresh behaviour, e.g. due events on home).

**Do not** rely on `readAccessTokenFromPage` when `testUser.accessToken` exists — the `testUser` fixture already calls `prepareLiveApiAccess`.

### New routes that JOIN new tables

Before merging route code that references new tables:

1. Add SQL migration under `db/migrations/NNN_*.sql`.
2. Ensure Node runner records it in `_migrations` (`server/scripts/migrate.js`).
3. Document UAT env: `UAT_AUTO_MIGRATE=true` when SSH deploy is enabled.
4. Add Jest coverage with mock pool **and** consider integration failure mode (missing relation → 500).

**High-risk routes (org/foster/custody):** `server/routes/pets/coreRouter.js` (`/pets/all`), `server/routes/custodyTransfers.js`.

### Auth tokens in E2E

- Always normalize tokens read from `localStorage` via `normalizeStoredToken()` before API calls.
- Never log token previews in error messages (security).
- App wire format: raw JWT string, not JSON-encoded.

### UAT-only E2E bypass

- **Signup only** — login rate limits must still apply (`server/config/rateLimit.js` + `isSignupAuthRequest`).
- Gated by `E2E_BYPASS_ALLOWED=true` + `E2E_BYPASS_TOKEN` on **UAT Node app only** — never production.
- Playwright sends header via `api-fetch.ts` / `e2e-bypass.ts`.
- Workflow env passes `E2E_BYPASS_TOKEN` to the live smoke job (`deploy-uat.yml`).

### Flutter list screens + remote data

Local-first repositories may show cached state on first paint. Tests that only hit API after UI load can pass on localhost (fast refresh) and fail on UAT. Prefer seed-before-login or explicit remount helpers in page objects.

---

## UAT environment checklist

GitHub → **Settings → Environments → UAT**:

| Variable | Purpose |
|----------|---------|
| `UAT_SSH_ENABLED` | `true` — enforce node_modules symlink checks over SSH |
| `UAT_AUTO_MIGRATE` | `true` — run `node scripts/migrate.js up` on deploy |
| `E2E_BYPASS_ALLOWED` | `true` on UAT Node app `.env` (not GitHub var) |
| `E2E_BYPASS_TOKEN` | GitHub secret + UAT Node `.env` (must match) |

UAT Node app `.env` (cPanel):

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` or `PG*` | DB connection for app + migrate.js |
| `JWT_SECRET` | Must be stable across restarts |
| `E2E_BYPASS_ALLOWED` / `E2E_BYPASS_TOKEN` | Signup rate-limit bypass for smoke |
| **`E2E=1`** | **Required** — disables auth + general API rate limits for CI (live `@smoke` will hang without it; UAT-only) |

---

## DB ownership for migrations

`migrate.js` applies incremental files `001_*.sql` … `020_*.sql` and records them in `_migrations`.

| Error (French PG) | Meaning |
|-------------------|---------|
| `doit être le propriétaire de la relation <table>` | Connected user is not table **owner** |

`GRANT ALL` is **not** sufficient for `ALTER TABLE`. Transfer ownership to the app user (e.g. `bixo5840_agathatrack_uat`) or run migrations as the current owner.

**Verify:**

```sql
SELECT tablename, tableowner FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
SELECT name FROM _migrations ORDER BY applied_at;
```

**Expected after healthy deploy:** `N applied, 0 pending` in SSH logs; `_migrations` contains all `NNN_*.sql` files present in repo.

**Anti-pattern:** Manually applying SQL in phpPgAdmin without inserting `_migrations` rows — next `migrate.js up` retries from `001` and may conflict.

---

## E2E auth rate-limit bypass (UAT only)

| Piece | Location |
|-------|----------|
| Server gate | `server/config/e2eBypass.js` |
| Rate limit integration | `server/config/rateLimit.js` (`shouldSkipAuthRateLimit`) |
| Playwright header | `e2e/playwright/support/e2e-bypass.ts`, `api-fetch.ts` |
| Tests | `server/test/auth/e2e-bypass.test.js` |

Localhost CI: `E2E=1` disables auth + general API rate limits — bypass not needed.

**Live UAT:** `E2E=1` must be set on the UAT Node app (cPanel env vars). `shouldSkipRateLimit()` in `server/config/rateLimit.js` skips both `createAuthLimiter()` and `createApiLimiter()` when `E2E=1`. Without it, repeated login attempts from the GitHub Actions runner IP hit the auth rate limit and every `@smoke` test stalls on the login screen (~2.4 min timeout each). Signup bypass (`E2E_BYPASS_*`) alone is not sufficient — login still rate-limits. **Do not set `E2E=1` on production.**

---

## Key files map

| Concern | Path |
|---------|------|
| UAT deploy workflow | `.github/workflows/deploy-uat.yml` |
| SSH deploy script | `scripts/ci/uat-ssh-backend-deploy.sh` |
| Migration runner | `server/scripts/migrate.js` |
| Migration SQL | `db/migrations/` |
| Token normalization | `e2e/playwright/support/normalize-stored-token.ts` |
| Live WAF / API access | `e2e/playwright/support/waf.ts`, `e2e/playwright/support/waf-markers.ts` |
| WAF + queue lessons (Jul 2026) | `docs/e2e/uat-waf-queue-lessons.md` |
| Auth fixture | `e2e/playwright/fixtures/auth.fixture.ts` |
| Pet list remount helper | `e2e/playwright/pages/pet-list.page.ts` (`refreshByRemount`) |
| Pets `/all` route | `server/routes/pets/coreRouter.js` |
| Custody pending route | `server/routes/custodyTransfers.js` |
| Agent memory (short) | `.agents/memory/uat-live-e2e-triage.md` |

---

## Incident playbook (ordered)

1. **Deploy job** — green? If not, read SSH `Database migrations` section first.
2. **`curl -sk https://uat.agathatrack.com/backend/health`** — JSON `{"status":"OK"}`?
3. **Migrations** — deploy log: `0 pending`? If not, ownership + re-run.
4. **Live smoke artifact** — which spec failed? Map using [symptom table](#live-smoke-playwright-failures).
5. **UAT access logs** — correlate `401` / `429` / `500` with route and timestamp.
6. **Re-run** — `workflow_dispatch` on deploy-uat or re-run failed jobs only after root cause fixed.

**Do not** promote to prod when `prod-ready` is red or live smoke failed.

---

## Changelog (knowledge capture)

| Issue | Root cause | Fix / PR area |
|-------|------------|---------------|
| E2E `401` on `createPet` | JSON-wrapped JWT in localStorage | `normalizeStoredToken` (#222) |
| Signup `429` on UAT smoke | Auth rate limit, parallel workers | Signup-only bypass (#223, #224) |
| `500` on `/pets/all`, `/custody-transfers/pending` | 20 pending migrations on UAT | `UAT_AUTO_MIGRATE` + ownership |
| Weight `@smoke` timeout | API seed after login | Seed before login (#225) |
| Health `@smoke` passed after migrations | Was blocked by API 500s / separate UI timing | Migrations first; remount for home due events |
| All live `@smoke` timeout ~2.4 min | UAT Node missing `E2E=1` | Set `E2E=1` + restart; verified [run 29694789075](https://github.com/KanopeeKa/AgathaCheck/actions/runs/29694789075) |
| Warmup WAF: health OK, signup 503 | `passHostingWaf` cleared on health only | Auth signup browser probe before `sessionWafCleared` (#351) |
| `promote-uat` skipped after failed deploy | `failed` head blocked promote | Auto `setBarrier` on enqueue (#344); manual `set-barrier` + tag |
| Coordinator dispatch crashes instantly | `launch-cursor-agent` ran `main()` on `require()` | `require.main === module` guard (#346) |
| WAF smoke froze all merges | Ledger `failed` on infra-only deploy | `infra_failed` + gate classifiers (#331) |
