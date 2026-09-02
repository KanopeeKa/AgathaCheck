---
title: UAT demo personas
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-02
tags: [testing,e2e,playwright]
---
# UAT demo personas

Stable identities for **manual UAT and shared demo environments only**.

**Full dataset documentation:** [uat-demo-data.md](./uat-demo-data.md)

## Credentials

| User | Email | Password | Role |
|------|-------|----------|------|
| Alice | `alice@demo.agathatrack.test` | `UatDemoPass1!` | Pet Care + org super admin |
| Bob | `bob@demo.agathatrack.test` | `UatDemoPass1!` | Org admin (Happy Paws Clinic) |
| Carol | `carol@demo.agathatrack.test` | `UatDemoPass1!` | Pet carer (shared access to Buddy) |
| Eve | `eve@demo.agathatrack.test` | `UatDemoPass1!` | Foster parent (Rescue Hearts) |
| Dave | `dave@demo.agathatrack.test` | `UatDemoPass1!` | Dual-role user |
| Grace | `grace@demo.agathatrack.test` | `UatDemoPass1!` | Adoption prospect |

Password is intentionally weak and documented — acceptable only on isolated non-prod databases.

## Scenarios (`node server/scripts/seed.js`)

| Scenario | Contents |
|----------|----------|
| `guardian` | Alice, Carol, Buddy, Whiskers (seed scenario key — wire value migrating to `pet_care`) |
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
