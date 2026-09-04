---
title: UAT demo personas
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-04
tags: [testing,e2e,playwright]
---
# UAT demo personas

Stable identities for **manual UAT and shared demo environments only**.

**Full dataset documentation:** [uat-demo-data.md](./uat-demo-data.md)

> Credential table below is generated from `server/db/seeds/demo-constants.js`.
> After changing users or passwords, run `node server/scripts/sync-demo-credentials-doc.js`.

## Credentials

<!-- DEMO_CREDENTIALS_TABLE:BEGIN -->
| User | Email | Password | Role |
|------|-------|----------|------|
| **Frederique** (main) | `frederique.prevost@gmail.com` | `PassTest` | Main test user — pet carer + super admin (Happy Paws Clinic & Rescue Hearts) |
| Bob | `bob@demo.agathatrack.test` | `PassTest` | Org admin at Happy Paws Clinic |
| Carol | `carol@demo.agathatrack.test` | `PassTest` | Pet carer with shared access to Buddy |
| Eve | `eve@demo.agathatrack.test` | `PassTest` | Foster parent at Rescue Hearts |
| Dave | `dave@demo.agathatrack.test` | `PassTest` | Dual-role user (personal pet + Rescue Hearts foster) |
| Grace | `grace@demo.agathatrack.test` | `PassTest` | Adoption prospect for Luna |
<!-- DEMO_CREDENTIALS_TABLE:END -->

All demo users share the same password for easy switching during manual testing. Password is intentionally weak and documented — acceptable only on isolated non-prod databases.

## Scenarios (`node server/scripts/seed.js`)

| Scenario | Contents |
|----------|----------|
| `guardian` | Frederique, Carol, Buddy, Whiskers (seed scenario key — wire value migrating to `pet_care`) |
| `org-clinic` | Happy Paws Clinic (discoverable, org UX v3 fields) |
| `org-v3-demo` | `org-clinic` + Rescue Hearts shell + org connection |
| `rescue-hearts` | Full charity dataset (fostering, adoption, pets) |
| `all` | Full rich demo dataset (all scenarios) |

## Reset commands (non-prod)

```bash
# Local: full database wipe + schema + seed
APP_ENV=development scripts/db/uat-reset.sh

# UAT server or local: truncate data + re-seed (keeps schema)
APP_ENV=uat scripts/db/uat-refresh-demo.sh
```

Remote UAT: GitHub Actions → **UAT reset demo data** (type `RESET` to confirm).

Refuses `APP_ENV=production`.

## Fixed UUIDs

See `DEMO_IDS` in `server/db/seeds/demo-constants.js`.
