# UAT live E2E & deploy triage (agent memory)

**Full runbook:** `docs/e2e/uat-live-operations-runbook.md`  
**WAF + queue lessons (Jul 2026):** `docs/e2e/uat-waf-queue-lessons.md` ← **read for smoke WAF / promote skipped / coordinator**

## Read this when

- `deploy-uat.yml` fails or live `@smoke` is red
- Smoke fails on **Warm up UAT auth before live smoke** / `test:warmup-uat`
- `promote-uat` skipped (`head_entry_failed`, `promote_tag_skipped`)
- UAT coordinator never launches / dispatch "succeeds" but no agent
- UAT access logs show `401` / `429` / `500` on `/backend/api/*`
- Playwright timeout on `expectPetVisible` / due events on home

## Fast triage

| Symptom | Look here |
|---------|-----------|
| Deploy failed, smoke skipped | Deploy job → `UAT backend deploy via SSH`; check `ssh_invariant`, migration `FAIL` lines |
| `500` pets/all or custody | `_migrations` empty / pending; tables from `014`, `020` |
| `doit être le propriétaire` | DB user needs **OWNER**, not GRANT — app user must own `public` tables |
| `401` E2E API after login | `normalize-stored-token.ts`; token must be raw JWT |
| `429` signup smoke | `E2E_BYPASS_TOKEN` in workflow + UAT `E2E_BYPASS_ALLOWED` (signup only) |
| **All** `@smoke` timeout ~2.4 min on login | UAT Node missing `E2E=1` — login rate limit blocks CI runner IP | Set `E2E=1` on UAT Node app + restart |
| Pet visible timeout, API OK | Spec seeds **after** `loginAs` — fix: `createPet` before login or `refreshByRemount` |
| Due events not on home | `refreshByRemount()` after API seed (see `e2e-navigation-contract.md`) |
| **Health OK** but warmup fails with WAF HTML on signup | Health-only WAF clear — need auth probe in `passHostingWaf` (#351); see `uat-waf-queue-lessons.md` |
| Stuck `#/landing` 120s after signup | Signup API still WAF-blocked — do not add curl/Node retries |
| `promote-uat` skipped / no UAT tag | Failed queue head — `set-barrier` or wait for auto-barrier on enqueue (#344) |
| Coordinator dispatch OK, no agent | `infra_failed` → skip is expected; `failed` + no marker → launch guard (#346) |
| When to run `uat-queue-health.yml` | After deploy finishes; not mid-smoke; won't fix `infra_failed` alone |

## WAF rules (do not forget)

1. **Never** curl/Node `fetch` on live UAT auth — browser only (`passHostingWaf` + `warmup-uat`).
2. **Health passing ≠ auth passing** — both must be probed in-browser before `createTestUser`.
3. WAF smoke failures → ledger `infra_failed` (promotion continues), not `failed`.

## E2E seed rule (prevention)

```ts
await createPet(baseURL, testUser.accessToken, name);
const petList = await loginAs(page, testUser);
await petList.expectPetVisible(name);
```

Never depend on post-login API create + stale home list on live UAT.

## UAT env (must be set)

- `UAT_SSH_ENABLED=true`
- `UAT_AUTO_MIGRATE=true`
- UAT Node: **`E2E=1`** (disables auth + general API rate limits for CI — required for live `@smoke`; UAT-only)
- UAT Node: `E2E_BYPASS_ALLOWED=true` + `E2E_BYPASS_TOKEN` (matches GitHub secret; signup bypass only)
- Workflow smoke step passes `E2E_BYPASS_TOKEN` from GitHub secrets (`deploy-uat.yml`).

**Verified green (Jul 2026):** deploy run [29694789075](https://github.com/KanopeeKa/AgathaCheck/actions/runs/29694789075) after migrations + ownership + `E2E=1` + bypass token wiring.

## Key paths

- Migrations: `server/scripts/migrate.js`, `db/migrations/`, `_migrations` table
- Bypass: `server/config/e2eBypass.js`, `e2e/playwright/support/e2e-bypass.ts`
- WAF: `e2e/playwright/support/waf.ts`, `waf-markers.ts`
- SSH deploy: `scripts/ci/uat-ssh-backend-deploy.sh`
- Queue: `scripts/uat_queue_runtime.js`, coordination issue `UAT_COORDINATION_ISSUE`
- node_modules: `docs/uat-backend-node-modules-runbook.md`
