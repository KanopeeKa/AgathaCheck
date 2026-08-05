# Plan — Public access gate (prod teaser + UAT Basic Auth)

| Field | Value |
|-------|-------|
| **plan_id** | `public-access-gate-a35f` |
| **title** | Prod coming-soon + API closed mode; UAT Basic Auth CI |
| **author** | cloud-agent |
| **created** | 2026-08-05 |
| **base_branch** | `cursor/public-access-gate-integration-a35f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Ship a **pre-launch public posture** for Agatha Track:

1. **`agathatrack.com`** — static coming-soon teaser (logo + short bilingual-capable copy) instead of the Flutter app; Node API in **`PUBLIC_ACCESS_MODE=coming_soon`** so signup/login cannot create users behind the teaser.
2. **`uat.agathatrack.com`** — CI plumbing for Apache HTTP Basic Auth (anonymous 401 proof + authed smoke + Playwright `httpCredentials`), flag-gated so localhost / pre-UAT E2E stay unchanged until ops enables Directory Privacy.
3. **Canonical ops doc**, fixture-tested smoke scripts, and live-host helper split (`liveUat` vs `liveProd`) so CI cannot silently mis-classify 401 as WAF or apply UAT helpers to prod.

Teaser deploy path is **perishable** (documented removal after launch). Enabling cPanel Directory Privacy is **ops** (post-merge checklist); this plan ships code/docs/CI only.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-05T19:49:00Z |
| **approved_until** | 2026-08-07T19:49:00Z |
| **control_issue** | #611 |
| **content_hash** | (snapshot) |
| **autonomy** | `active` |

**Grant:** user chat 2026-08-05 — “go with your best recommendation… use /execute-plan… ensure e2e pre UAT is green”.

**Sanity check:** `proceed-high-risk` — touches deploy workflows and auth surface; human standing grant covers CI workflow edits for this feature (not gate weakening). Merge gates unchanged.

## Phases

### Phase 1 — Teaser site, canonical docs, hosting helpers

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/public-access-teaser-docs-a35f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
public/coming-soon/**
docs/ops/public-access.md
docs/refactoring-log.md
.agents/memory/public-access-gate.md
.agents/plans/public-access-gate-a35f.*
e2e/playwright/support/hosting.ts
e2e/playwright/support/hosting.test.ts
scripts/ci/public-access-smoke-lib.sh
scripts/ci/public-access-smoke-lib.test.js
```

**forbidden_paths:**

```
server/**
.github/workflows/**
flutter_app/**
```

**allowed_exceptions:** `tests`, `docs`, `governance-allowlist`

**Scope:**

- Static teaser under `public/coming-soon/` (logo, calm copy, `data-site-mode="coming-soon"`, `noindex`)
- Minimal copy source (EN primary; FR short paragraph OK) — not Flutter ARB
- Canonical `docs/ops/public-access.md` (truth table, launch flip, Basic Auth upgrade path, anonymous-401 contract)
- Split `isLiveHostingTarget` → `isLiveUat` / `isLiveProd` / shared helper; update call sites only within hosting.ts + test (call-site migrations that need other files → phase 4 or debt if out of path — prefer update all hosting.ts consumers via exception `tests` only if same PR needs compile; actually other files import hosting — need to allow e2e/playwright/support/** or update hosting.ts API to keep `isLiveHostingTarget` as deprecated wrapper)

**Exit criteria:**

- [x] Teaser `index.html` contains `data-site-mode="coming-soon"` and logo asset resolves
- [x] `docs/ops/public-access.md` is the single source of truth
- [x] Hosting helpers distinguish UAT vs prod; unit test covers both
- [x] Smoke lib has fixture-testable helpers (marker detection) with Node test

---

### Phase 2 — API `PUBLIC_ACCESS_MODE`

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/public-access-api-mode-a35f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
server/config/publicAccess.js
server/middleware/publicAccessGate.js
server/bin/server.js
server/test/publicAccess.test.js
.agents/plans/public-access-gate-a35f.*
docs/ops/public-access.md
```

**forbidden_paths:**

```
.github/workflows/**
flutter_app/**
public/**
```

**allowed_exceptions:** `tests`, `docs`, `backend-route`

**Scope:**

- Env `PUBLIC_ACCESS_MODE=coming_soon|open` (default `open` for local/test/UAT)
- Middleware: health OK; auth signup/login/forgot/reset and other `/backend/api/*` (and `/api/*`) return **403** `{ error, code: "public_access_closed" }` when `coming_soon`
- Boot log once: `public_access_mode=…` (no secrets)
- Jest coverage for both modes

**Exit criteria:**

- [x] Default mode does not break existing Jest / local E2E
- [x] `coming_soon` blocks signup; health still 200
- [x] No raw exception text in 403/5xx bodies

---

### Phase 3 — Prod deploy teaser path + smoke

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/public-access-prod-deploy-a35f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.github/workflows/deploy-prod.yml
scripts/prod-post-deploy-smoke.sh
scripts/ci/prod-post-deploy-smoke.test.js
scripts/ci/public-access-smoke-lib.sh
docs/ops/public-access.md
docs/promotion-contract.md
.agents/plans/public-access-gate-a35f.*
```

**forbidden_paths:**

```
server/**
flutter_app/**
```

**allowed_exceptions:** `tests`, `docs`, `governance-allowlist`

**Scope:**

- Repo/env var `PROD_PUBLIC_MODE=coming_soon|app` (fail if unset when deploy enabled)
- When `coming_soon`: deploy `public/coming-soon/` (no Flutter artifact required); keep backend deploy
- Prod smoke: teaser marker on `/`; fail if Flutter `main.dart.js` still 200; health if backend kept
- When `app`: existing promote + `/landing` (or Flutter) smoke
- Job summary prints both `PROD_DEPLOY_ENABLED` and `PROD_PUBLIC_MODE`
- Doc pointers from promotion-contract → public-access.md

**Exit criteria:**

- [x] Truth table documented and smoke script fixture-tested
- [x] No weakening of merge gates
- [x] Teaser path does not require UAT web artifact

---

### Phase 4 — UAT Basic Auth CI plumbing

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/public-access-uat-auth-a35f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
scripts/uat-post-deploy-smoke.sh
scripts/ci/uat-post-deploy-smoke.test.js
scripts/ci/public-access-smoke-lib.sh
scripts/ci/run-live-uat-gate.sh
.github/workflows/deploy-uat.yml
.github/workflows/uat-live-e2e.yml
e2e/playwright.config.ts
e2e/playwright/support/hosting.ts
e2e/playwright/support/**/*
docs/ops/public-access.md
docs/e2e/uat-deploy-tiers.md
docs/e2e/uat-waf-queue-lessons.md
.agents/memory/public-access-gate.md
.agents/plans/public-access-gate-a35f.*
```

**forbidden_paths:**

```
server/**
flutter_app/lib/**
```

**allowed_exceptions:** `tests`, `docs`, `governance-allowlist`

**Scope:**

- `UAT_BASIC_AUTH_ENABLED` + user/password secrets wiring (default **off**)
- Smoke: when enabled — anonymous probe expects **401** (`failure_kind=basic_auth`), then authed health + landing
- Playwright `httpCredentials` when live UAT + secrets present; fail closed if flag on and secrets missing
- Migrate remaining `isLiveHostingTarget` call sites to UAT-specific helpers where needed
- Docs: ops enable Directory Privacy checklist; 401 ≠ WAF

**Exit criteria:**

- [ ] Flag off → identical smoke behavior to today (pre-UAT / localhost green)
- [ ] Fixture tests cover 401 anonymous + authed success
- [ ] Live E2E workflow documents required secrets

---

## Runtime state

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 2
halt_reason: null
next_action: "continue phase 3 on branch cursor/public-access-prod-deploy-a35f"
artifact_ref:
  branch: cursor/public-access-prod-deploy-a35f
  plan_path: .agents/plans/public-access-gate-a35f.md
  plan_commit: a8dbcd63fa37ae9cd176d5553db97ca158ae0b41
  snapshot_path: .agents/plans/public-access-gate-a35f.snapshot.json
  snapshot_commit: a8dbcd63fa37ae9cd176d5553db97ca158ae0b41
open_prs: []
merge_commits: {"1":"08ef7e662e421aacac52e375acde3c188ddee565","2":"6449ed01bc08d07067a631abbeb371c4cff191d9"}
debt_issue_refs: []
```

## Post-plan ops (human; not a phase)

1. Set `PROD_PUBLIC_MODE=coming_soon` and `PUBLIC_ACCESS_MODE=coming_soon` on prod; deploy.
2. Enable cPanel Directory Privacy on UAT only; set GitHub UAT secrets + `UAT_BASIC_AUTH_ENABLED=true`.
3. After public launch: `PROD_PUBLIC_MODE=app`, `PUBLIC_ACCESS_MODE=open`; open debt to remove teaser deploy path.
