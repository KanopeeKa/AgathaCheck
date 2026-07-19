# UAT live E2E & deploy triage (agent memory)

**Full runbook:** `docs/e2e/uat-live-operations-runbook.md`

## Read this when

- `deploy-uat.yml` fails or live `@smoke` is red
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
- UAT Node: **`E2E=1`** (disables auth rate limits for CI — required for live `@smoke`)
- UAT Node: `E2E_BYPASS_ALLOWED=true` + `E2E_BYPASS_TOKEN` (matches GitHub secret; signup bypass only)
- Workflow smoke step needs `E2E_BYPASS_TOKEN` (human PR — `cursor/*` cannot edit workflows)

**Verified green (Jul 2026):** deploy run [29694789075](https://github.com/KanopeeKa/AgathaCheck/actions/runs/29694789075) after migrations + ownership + `E2E=1` + bypass token wiring.

## Key paths

- Migrations: `server/scripts/migrate.js`, `db/migrations/`, `_migrations` table
- Bypass: `server/config/e2eBypass.js`, `e2e/playwright/support/e2e-bypass.ts`
- SSH deploy: `scripts/ci/uat-ssh-backend-deploy.sh`
- node_modules: `docs/uat-backend-node-modules-runbook.md`
