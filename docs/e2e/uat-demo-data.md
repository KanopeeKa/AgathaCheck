---
title: UAT demo data
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-02
tags: [e2e, uat, demo]
---
# UAT demo data

Rich synthetic dataset for **UAT and live demos**. Stable credentials, fixed UUIDs, and idempotent seeds.

**Never** run on production. Production deploy paths are guarded — see [DEPLOYMENT_DB.md](../../DEPLOYMENT_DB.md).

---

## Quick start

### Local / dev (full wipe + schema)

```bash
APP_ENV=development scripts/db/uat-reset.sh
```

Drops the database, bootstraps schema from canonical snapshot, then loads all demo scenarios.

### UAT server (data only — keeps schema + migrations)

```bash
APP_ENV=uat scripts/db/uat-refresh-demo.sh
```

Truncates application tables and re-seeds. Use when the schema is already up to date.

### GitHub Actions (remote UAT)

1. Open **Actions → UAT reset demo data**
2. Click **Run workflow**
3. Type `RESET` in the confirmation field

Requires `UAT_SSH_ENABLED=true` and UAT SSH secrets. Restarts Passenger after seeding.

---

## Credentials

All demo users share the same password:

| Field | Value |
|-------|-------|
| Password | `UatDemoPass1!` |

| User | Email | Role |
|------|-------|------|
| Alice | `alice@demo.agathatrack.test` | Pet Care + super admin (Happy Paws Clinic & Rescue Hearts) |
| Bob | `bob@demo.agathatrack.test` | Admin at Happy Paws Clinic |
| Carol | `carol@demo.agathatrack.test` | Pet carer with shared access to Buddy |
| Eve | `eve@demo.agathatrack.test` | Foster parent at Rescue Hearts |
| Dave | `dave@demo.agathatrack.test` | Dual-role user (personal pet + Rescue Hearts foster) |
| Grace | `grace@demo.agathatrack.test` | Adoption prospect for Luna |

Password is intentionally weak and documented — acceptable only on isolated non-prod databases.

---

## What the dataset covers

| Domain | Demo content |
|--------|----------------|
| **Owned pets** | Buddy (dog) and Whiskers (cat) — Alice; Pip (dog) — Dave |
| **Org pets** | Clinic Cat (Happy Paws); Max, Luna, Rocky, Mittens (Rescue Hearts) |
| **Health** | Vaccinations, medications, overdue preventives, vet visits, active health issue |
| **Weight** | Weight history for Buddy and Whiskers |
| **Vets** | Dr. Sarah Mitchell linked to Buddy |
| **Timeline & family** | Buddy adoption milestone; Alice holiday family event |
| **Fostering** | Active placement (Max ↔ Eve); foster-to-adopt (Rocky); completed (Mittens) |
| **Foster requests** | Sent request with Eve's "can help" response |
| **Adoption** | Rocky journey (pending conditions); Luna prospect + scheduled visit |
| **Custody** | Pending transfer of Luna to Grace |
| **Sharing** | Carol has shared access to Buddy; pending share link for Whiskers |
| **Notifications** | Overdue flea treatment (urgent); foster request admin alert |
| **Org connections** | Happy Paws Clinic ↔ Rescue Hearts |
| **Permissions** | Bob has `manage_pets` override at Happy Paws |
| **Document templates** | Adoption milestones + foster intake checklist at Rescue Hearts |

Dates are **relative to seed time** (overdue entries, upcoming visits) so the app always looks realistic.

---

## Scenarios

Run individually with `node server/scripts/seed.js --scenario=<name>`:

| Scenario | Purpose |
|----------|---------|
| `guardian` | Alice, Carol, personal pets |
| `org-clinic` | Happy Paws Clinic, Bob, Clinic Cat (discoverable, org UX v3) |
| `org-v3-demo` | Minimal org UX v3 subset: clinic + Rescue Hearts shell + connection |
| `rescue-hearts` | Rescue Hearts charity, Eve, Dave, Grace, org pets |
| `health-care` | Vets, health entries, weight, timeline, family events |
| `fostering` | Foster profiles, placements, requests |
| `adoption` | Journeys, prospects, visits, custody transfers |
| `sharing-notifications` | Pet sharing, notifications, preferences |
| `connections` | Org-to-org connection |
| `all` | All of the above in dependency order (default) |

---

## Architecture

```
server/db/seeds/
  demo-constants.js      # Stable UUIDs and user definitions
  helpers.js             # Upsert helpers, relative calendar dates
  truncate-data.js       # Wipe application data (keeps _migrations)
  scenarios/             # One module per scenario
server/scripts/seed.js   # CLI entry point
```

Idempotent `INSERT … ON CONFLICT DO UPDATE` — safe to re-run without truncate.

---

## Review of prior state (before this work)

| Aspect | Before | After |
|--------|--------|-------|
| **Users** | 2 (Alice, Bob) | 6 personas across guardian, foster, dual-role, prospect |
| **Organisations** | 1 clinic | Clinic + charity rescue |
| **Pets** | 2 | 8 (personal + org-held, varied species) |
| **Health / weight** | None | Full entries including overdue + upcoming |
| **Fostering** | None | Active, foster-to-adopt, completed placements + requests |
| **Adoption** | None | Journey, prospect, scheduled visit, custody transfer |
| **Sharing / notifications** | None | Shared access, share link, overdue + admin alerts |
| **Org connections** | None | Cross-org link between clinic and rescue |
| **Reset on UAT** | Manual `uat-reset.sh` only (local drop DB) | + `uat-refresh-demo.sh` (truncate) + GitHub workflow |
| **E2E API seeds** | Separate random-email system | Unchanged — E2E still uses runtime API seeding; SQL personas are for manual UAT/demos |

The SQL demo layer and E2E API seeds remain **intentionally separate**: E2E creates ephemeral users per test; SQL personas give stable logins for human UAT and demos.

---

## Fixed UUIDs

See `DEMO_IDS` in `server/db/seeds/demo-constants.js`.

---

## Related

- [uat-demo-personas.md](./uat-demo-personas.md) — short credential reference (legacy alias)
- [db-schema-bootstrap-plan.md](../db-schema-bootstrap-plan.md) — seed layer design (Phase 4)
- [uat-deploy-tiers.md](./uat-deploy-tiers.md) — deploy pipeline (reset is **not** part of deploy)
