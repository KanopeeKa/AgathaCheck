# UAT demo personas

Stable identities for **manual UAT and shared demo environments only**.  
Never load via production deploy paths. Use `scripts/db/uat-reset.sh` on non-prod databases.

## Credentials

| User | Email | Password | Role |
|------|-------|----------|------|
| Alice | `alice@demo.agathatrack.test` | `UatDemoPass1!` | Guardian + org super admin |
| Bob | `bob@demo.agathatrack.test` | `UatDemoPass1!` | Org admin (Happy Paws Clinic) |

Password is intentionally weak and documented — acceptable only on isolated non-prod databases.

## Scenarios (`node server/scripts/seed.js`)

| Scenario | Contents |
|----------|----------|
| `guardian` | Alice + personal pet **Buddy** (dog) |
| `org-clinic` | Alice (super_admin), Bob (admin), **Happy Paws Clinic**, org pet **Clinic Cat** |
| `all` | Both scenarios |

## One-command reset (non-prod)

```bash
APP_ENV=development scripts/db/uat-reset.sh
```

Refuses `APP_ENV=production`.

## Fixed UUIDs

See `DEMO_IDS` in `server/scripts/seed.js` for stable primary keys used in idempotent upserts.
