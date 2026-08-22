---
title: Database schema bootstrap plan
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [database, bootstrap]
---
# Database schema bootstrap — phased plan

**Status:** Phase 3 complete (fast bootstrap). Phases 4–5 tracked in execute-plan `db-schema-bootstrap-345`.  
**Principle:** Forward-only migrations are the production authority. The canonical schema is a **CI-verified snapshot** for fast bootstraps and drift detection — not a hand-edited alternate truth.

See also: [DEPLOYMENT_DB.md](../DEPLOYMENT_DB.md) (deploy commands), [calendar-dates.md](./calendar-dates.md) (wire format).

---

## Operating model

| Artifact | Path | Role | Production? |
|----------|------|------|-------------|
| **Incremental migrations** | `db/migrations/NNN_*.sql` | Authoritative upgrade path | **Yes** — `migrate.js up` only |
| **Migration manifest** | `db/schema/migration-manifest.json` | Ledger of incrementals; CI integrity | No (metadata) |
| **Canonical snapshot** | `db/schema/canonical.sql` | Generated end-state DDL; drift check | No (bootstrap only) |
| **Legacy baseline** | `db/migrations/v3__initial_uuid_schema.sql` | Historical fresh-install base | Retired in Phase 3 |
| **UAT/demo seeds** | `db/seeds/` (Phase 4) | Idempotent personas | **Never** |

### Data categories (Phase 4+)

| Type | Examples | Where |
|------|----------|-------|
| **Reference data** | Rows the app assumes exist on day one | Forward migration or controlled bootstrap |
| **Demo / UAT data** | Alice, Happy Paws Clinic, foster scenarios | `db/seeds/` only; non-prod |

---

## Phase 1 — Validation infrastructure (current)

**Outcome:** Prove the bootstrap path produces a schema that matches the committed canonical snapshot, without changing prod/UAT deploy behaviour.

### Deliverables

| Item | Purpose |
|------|---------|
| `db/schema/migration-manifest.json` | Authoritative list of `NNN_*.sql` files |
| `db/schema/canonical.sql` | Generated snapshot at migration 020 |
| `scripts/db/check-migration-manifest.js` | Manifest ↔ disk integrity |
| `scripts/db/normalize-schema-dump.js` | Stable `pg_dump` comparison |
| `scripts/db/check-schema-equivalence.sh` | Bootstrap path → dump → diff canonical |
| `scripts/db/regenerate-canonical.sh` | Regenerate snapshot after schema PRs |

### Developer workflow (schema change PR)

1. Add `db/migrations/021_feature.sql` (forward-only).
2. Append filename to `db/schema/migration-manifest.json`.
3. Run `scripts/db/regenerate-canonical.sh` and commit `canonical.sql`.
4. Run `scripts/db/check-schema-equivalence.sh` locally (Postgres required).
5. Production/UAT deploy unchanged: `node scripts/migrate.js up` only.

### Exit criteria

- [x] Manifest lists all incremental migrations on disk.
- [x] Canonical snapshot regenerated from v3 + 001–020 bootstrap path.
- [x] Equivalence check passes locally.
- [x] Manifest check in governance pre-push (lightweight, no Postgres).
- [x] Equivalence check in PR startup smoke (Postgres already provisioned).

### Non-goals (Phase 1)

- No bootstrap path switch (still `v3` + incrementals).
- No seed layer.
- No prod credential or deploy changes.

---

## Phase 2 — Blocking CI gate

**Outcome:** Schema drift cannot merge to `main`.

**Status:** Delivered alongside Phase 1 — `pr-startup-smoke` runs equivalence after bootstrap (already behind `ci-gate / CI passed`).

### Remaining work

1. ~~Add equivalence check to PR startup smoke~~ (done).
2. Document in [ci-cd-gates.md](./ci-cd-gates.md) (optional follow-up).
3. `pre-push-changed.sh`: schema-path changes run equivalence when Postgres is up (done).

### Exit criteria

- [x] PR with stale `canonical.sql` fails CI (via startup smoke).
- [x] PR with manifest/disk mismatch fails governance.
- [x] `ci-gate / CI passed` includes schema drift (via startup-smoke).

---

## Phase 3 — Fast bootstrap switch

**Outcome:** New environments apply one canonical file instead of v3 + 20 replay steps.

**Status:** Complete — `bootstrap-db.sh` applies `canonical.sql` + migration ledger; v3 archived.

### Delivered

1. `e2e/scripts/bootstrap-db.sh` — canonical snapshot + `seed-migration-ledger.js` on empty DB
2. `server/scripts/seed-migration-ledger.js` — pre-seeds `_migrations` from manifest
3. `scripts/db/check-bootstrap-paths-equivalence.sh` — legacy ≡ fast path (CI)
4. `db/migrations/v3__initial_uuid_schema.sql` → `archive/` (legacy regeneration + CI only)

### Exit criteria

- [x] Fast bootstrap path in E2E/CI
- [x] Dual-path equivalence CI gate
- [x] v3 archived; docs updated

---

## Phase 4 — UAT/demo seed layer

**Outcome:** Human testers get stable personas without API signup friction.

**Status:** Complete — idempotent seed script + `uat-reset.sh` with `APP_ENV` guards.

### Delivered

- `server/scripts/seed.js` — scenarios `guardian`, `org-clinic`, `all`
- `scripts/db/uat-reset.sh` — drop + bootstrap + seed (non-prod only)
- `scripts/db/guard-non-prod.js` — shared production refusal helper
- `docs/e2e/uat-demo-personas.md` — stable credentials and UUIDs

### Exit criteria

- [x] Documented one-command UAT refresh (`scripts/db/uat-reset.sh`)
- [x] `APP_ENV=production` refuses seed/reset
- [x] Jest coverage for guard + demo constants

---

## Phase 5 — Production hardening

**Outcome:** Prod can only run the narrow migration path; destructive ops impossible by design.

**Status:** Complete — deploy audit, `APP_ENV` guards on destructive scripts, production policy in `DEPLOYMENT_DB.md`.

### Delivered

1. `APP_ENV=production` guards on `regenerate-canonical`, `uat-reset`, `seed`, legacy bootstrap, and DB-reset equivalence checks
2. `scripts/ci/assert-prod-deploy-db-commands.sh` — deploy scripts must not reference bootstrap/seed
3. Production policy table in `DEPLOYMENT_DB.md` (credentials + expand-and-contract)

### Exit criteria

- [x] Prod deploy checklist documented
- [x] Separate migration DB role documented (recommended policy)
- [x] No seed/reset in prod deploy scripts (CI assertion)

---

## Command reference

| Command | Postgres? | When |
|---------|-----------|------|
| `node scripts/db/check-migration-manifest.js` | No | Every schema PR; governance |
| `scripts/db/check-schema-equivalence.sh` | Yes | After schema changes; CI Phase 2 |
| `scripts/db/regenerate-canonical.sh` | Yes | After new migration committed |
| `node scripts/migrate.js up` | Yes | **Prod/UAT deploy only** |
| `e2e/scripts/bootstrap-db.sh` | Yes | Dev/E2E — canonical snapshot + migration ledger |
| `scripts/db/bootstrap-legacy-db.sh` | Yes | Regenerate canonical + CI path equivalence only |

---

## Migration authoring rules (all phases)

1. **Forward-only** — no `down` in prod path; add a new migration to revert.
2. **No `gen_random_uuid()` in SQL** — generate UUIDs in Node (see `016` pattern).
3. **Reference vs demo** — prod-required rows in migrations; personas in seeds only.
4. **Expand-and-contract** for breaking changes: add → backfill → deploy code → drop (later migration).

---

## Related debt

| Item | Tracking |
|------|----------|
| v3 drift (inlines 001–007 only) | Resolved by canonical snapshot; v3 retired Phase 3 |
| Hand-merge policy in DEPLOYMENT_DB.md | Superseded by regenerate script |
| E2E API-only seeds | Phase 4 — promote stable personas to SQL |
