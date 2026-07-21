# Execute-plan: DB schema bootstrap phases 3–5

| Field | Value |
|-------|-------|
| **plan_id** | `db-schema-bootstrap-345` |
| **title** | DB schema bootstrap — fast install, UAT seeds, prod hardening |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Complete the database bootstrap initiative after Phase 1–2 (#249): fast canonical bootstrap (Phase 3), idempotent UAT/demo seeds (Phase 4), and production deploy hardening (Phase 5).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-21T22:25:00Z |
| **approved_by** | user (execute-plan request) |
| **approved_until** | 2026-07-23T22:25:00Z |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Runtime state

```yaml
autonomy: active
current_phase: "3"
last_completed_phase: "2"
next_action: "babysit+ phase 3 PR"
```

## Phases

### Phase 3 — Fast bootstrap switch

**branch:** `cursor/db-fast-bootstrap-b9c1`  
**status:** in_progress

Canonical snapshot + migration ledger bootstrap; archive v3; dual-path CI.

### Phase 4 — UAT/demo seed layer

**branch:** `cursor/db-uat-seeds-b9c1`

`server/scripts/seed.js` with `APP_ENV` guards; stable demo personas; `scripts/db/uat-reset.sh`.

### Phase 5 — Production hardening

**branch:** `cursor/db-prod-hardening-b9c1`

Non-prod guards on destructive scripts; prod deploy audit; `DEPLOYMENT_DB.md` checklist.
