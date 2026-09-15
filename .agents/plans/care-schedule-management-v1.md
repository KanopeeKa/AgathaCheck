---
title: Care Schedule Management V1
plan_id: care-schedule-management-v1
---

# Care Schedule Management V1

| Field | Value |
|-------|-------|
| **plan_id** | `care-schedule-management-v1` |
| **title** | Care Schedule Management (CSM-0 through CSM-18) |
| **base_branch** | `cursor/care-schedule-management-v1-integration-csm1` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Unify care timing under CSM: one primitive per action, `care_schedule_events` ledger, unified `advanceSeries`, per-family anchor defaults. No production data — clean cutover.

**Canonical docs:** `docs/domains/pet_care/changes/care-schedule-management-delivery-plan.md`

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-15T15:10:00Z |
| **approved_until** | 2026-09-17T15:10:00Z |
| **approved_by** | user chat 2026-09-15 — CSM verification confirmed; per-family anchor defaults; proceed CSM-0 onward; /execute-plan |
| **autonomy** | `active` |

## Phases

### Phase csm-0 — Decision log + plan bootstrap

| Field | Value |
|-------|-------|
| **branch** | `cursor/care-schedule-management-csm0-csm1` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
.agents/plans/care-schedule-management-v1.*
docs/domains/pet_care/changes/care-schedule-management-*
docs/domains/pet_care/features/care-schedule-management.md
docs/domains/pet_care/README.md
```

**Exit criteria:**

- [ ] Decision log D-CSM-001–008
- [ ] Delivery plan with CSM-SEED parallel seam
- [ ] Feature doc skeleton
- [ ] Snapshot validated

### Phase csm-seed — Rich demo seed data (parallel)

| Field | Value |
|-------|-------|
| **branch** | `cursor/care-schedule-management-csm-seed-csm1` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/db/seeds/**
server/scripts/seed.js
server/test/seed.test.js
docs/e2e/uat-demo-data.md
```

**Exit criteria:**

- [ ] Seed covers minimum scenario table in delivery plan
- [ ] `seed.test.js` asserts fixture presence
- [ ] `uat-demo-data.md` updated

### Phase csm-1 — Schema migration

| Field | Value |
|-------|-------|
| **branch** | `cursor/care-schedule-management-csm1-csm1` |

**allowed_paths:**

```
db/migrations/**
db/schema/canonical.sql
server/test/migrations/**
```

**Exit criteria:**

- [ ] `care_schedule_events` table
- [ ] Column additions on `health_entries` / `health_occurrences`
- [ ] Migration test green

(Subsequent phases csm-2 … csm-18 documented in delivery plan; snapshot carries full list.)
