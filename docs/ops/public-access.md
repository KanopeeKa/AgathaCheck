# Public access posture (canonical)

**Single source of truth** for pre-launch and launch public access on Agatha Track hosting.
Do **not** duplicate these truth tables into other docs — link here.

| Host | Intended posture |
|------|------------------|
| **`agathatrack.com` (prod)** | Static **coming-soon teaser** + API **`PUBLIC_ACCESS_MODE=coming_soon`** until launch |
| **`uat.agathatrack.com` (UAT)** | Full app; optional Apache **HTTP Basic Auth** (cPanel Directory Privacy) for CI/ops |

Related pointers only: [promotion-contract.md](../promotion-contract.md) · [uat-deploy-tiers.md](../e2e/uat-deploy-tiers.md) · [uat-waf-queue-lessons.md](../e2e/uat-waf-queue-lessons.md)

---

## Goals

1. **Prod teaser** — Public visitors see `public/coming-soon/` (logo + short copy), not Flutter. Signup/login APIs cannot create sessions behind the teaser.
2. **UAT Basic Auth** — When ops enables Directory Privacy, anonymous HTTP gets **401**; CI uses credentials for smoke and Playwright. Localhost / pre-UAT E2E stay unchanged until the flag is on.
3. **Clear failure kinds** — Smoke and E2E must not confuse Basic Auth 401 with WAF, or serve Flutter while `PROD_PUBLIC_MODE=coming_soon`.

---

## Truth tables

### Prod deploy × public mode

Repo/env: `PROD_DEPLOY_ENABLED`, `PROD_PUBLIC_MODE` (`coming_soon` | `app`).
Fail closed if deploy is enabled and `PROD_PUBLIC_MODE` is unset.

| `PROD_DEPLOY_ENABLED` | `PROD_PUBLIC_MODE` | Deploy web root | Prod smoke expects |
|-----------------------|--------------------|-----------------|--------------------|
| `false` / unset | any | No prod deploy | N/A |
| `true` | `coming_soon` | `public/coming-soon/` (no Flutter artifact required) | Teaser marker on `/`; **fail** if Flutter `main.dart.js` still 200 |
| `true` | `app` | Flutter web (promote path) | Existing landing / app smoke |

Backend may still deploy in both modes. Pair web teaser with API closed mode (below).

### API `PUBLIC_ACCESS_MODE`

Env: `PUBLIC_ACCESS_MODE=coming_soon|open` (default **`open`** for local, Jest, UAT).

| Mode | `/backend/health` (and health aliases) | Auth + other `/backend/api/*` (and `/api/*`) |
|------|----------------------------------------|-----------------------------------------------|
| `open` | 200 as today | Unchanged |
| `coming_soon` | **200 OK** | **403** JSON `{ error, code: "public_access_closed" }` (no raw exception text) |

Boot once (no secrets): `public_access_mode=…`.

**Implementation:** `server/config/publicAccess.js` + `server/middleware/publicAccessGate.js` (wired early in `server/bin/server.js`).

**Contract:** health stays green so deploy/smoke can prove the Node process is up while signup/login/forgot/reset are closed.

### UAT `UAT_BASIC_AUTH_ENABLED`

| Flag | Anonymous GET `/` or health | Authed smoke / Playwright |
|------|-----------------------------|---------------------------|
| `false` / unset (default) | Same as today (no Basic Auth expectation) | Unchanged |
| `true` | Expect **401** → smoke `failure_kind` / proof **`basic_auth`** when probing without credentials | Must send Basic Auth (secrets); Playwright `httpCredentials` when live UAT |

**Anonymous 401 proof (UAT, flag on):** first probe **without** credentials must observe HTTP **401**. That proves Directory Privacy is active — it is **not** a WAF challenge and not an app auth failure.

---

## Smoke failure kinds

Shared helpers: `scripts/ci/public-access-smoke-lib.sh`.

| Kind | Meaning |
|------|---------|
| `basic_auth` | HTTP **401** (expected anonymous proof when UAT Basic Auth is on; unexpected elsewhere) |
| `teaser_mismatch` | Expected teaser HTML (`data-site-mode="coming-soon"`) missing when mode is `coming_soon` |
| `flutter_served_in_teaser_mode` | Flutter asset (e.g. `main.dart.js`) still reachable while prod is in teaser mode |

Do not map 401 to WAF. Tiger Protect challenges are separate (HTML markers / browser warmup).

---

## Launch flip + rollback

### Launch (open the product)

1. Set `PROD_PUBLIC_MODE=app` and `PUBLIC_ACCESS_MODE=open` on prod.
2. Deploy Flutter web + backend (normal promote path).
3. Confirm `/` serves the app (no teaser marker); health 200; signup works in a controlled check.
4. Open debt / follow-up to **remove** the perishable teaser deploy path and `public/coming-soon/` once launch is stable.

### Rollback (re-close public)

1. Set `PROD_PUBLIC_MODE=coming_soon` and `PUBLIC_ACCESS_MODE=coming_soon`.
2. Redeploy teaser web root + backend.
3. Smoke: teaser marker present; Flutter assets must not be served; auth endpoints return `public_access_closed`.

---

## Ops checklist — cPanel Directory Privacy (UAT only)

Enable only on **`uat.agathatrack.com`**, never as a substitute for the prod teaser.

1. cPanel → **Directory Privacy** (Password Protect Directories) on the UAT docroot (and backend path if separate and should be covered).
2. Create the Basic Auth user; store username/password in GitHub Actions secrets used by UAT smoke / live E2E.
3. Set `UAT_BASIC_AUTH_ENABLED=true` in the UAT workflow env / vars.
4. Confirm anonymous curl → **401**; credentialed smoke → health + landing OK.
5. Confirm Playwright live UAT receives `httpCredentials` when the flag is on; fail closed if flag on and secrets missing.

**FTP note:** some FTP deploy clients **exclude `.htaccess`**. After enabling Directory Privacy, verify the protection file is present on the server; redeploy or re-save privacy settings if 401 disappears after a web sync.

---

## Upgrade path off shared Basic Auth

Shared HTTP Basic Auth is a coarse gate for UAT. Longer-term options (pick when ops capacity allows):

1. IP allowlists / VPN for human ops (if the host supports them without breaking CI).
2. App-level invite / staff-only auth on UAT (no shared password in CI secrets).
3. Separate preview hosts with short-lived signed URLs.

Until then: flag-gated Basic Auth + documented 401 contract keeps pre-UAT and localhost green when the flag is off.

---

## Teaser path is perishable

`public/coming-soon/` and the `PROD_PUBLIC_MODE=coming_soon` deploy branch exist for **pre-launch only**. After public launch:

- Remove teaser deploy wiring once `app` mode is permanent.
- Delete or archive the static teaser when no longer needed for rollback.
- Keep this doc’s launch/rollback section until removal is done; then trim obsolete rows.

---

## Live host helpers (E2E)

| Helper | Meaning |
|--------|---------|
| `isLiveUatTarget` | `uat.agathatrack.com` — WAF warmup, E2E bypass, Basic Auth, stealth |
| `isLiveProdTarget` | `agathatrack.com` / `www` — **not** UAT |
| `isLiveHostingTarget` | Any `*.agathatrack.com` — shared timeouts / “any live host” only |

See `.agents/memory/public-access-gate.md` for agent traps (401 ≠ WAF, FTP `.htaccess`, etc.).
