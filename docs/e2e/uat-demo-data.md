---
title: UAT demo data
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-29
tags: [e2e, uat, demo]
---
# UAT demo data

Rich synthetic dataset for **UAT and live demos**. Stable credentials, fixed UUIDs, and idempotent seeds.

**Never** run on production. Production deploy paths are guarded — see [DEPLOYMENT_DB.md](../../DEPLOYMENT_DB.md).

Credential reference (auto-synced from seed constants): [uat-demo-personas.md](./uat-demo-personas.md)

---

## Quick start

### Local / dev (full wipe — drops database, recreates schema, seeds data)

```bash
APP_ENV=development scripts/db/uat-reset.sh
```

Drops the database (all tables), bootstraps schema from canonical snapshot, then loads all demo scenarios.

### UAT server (data only — truncates all application tables, keeps schema)

```bash
APP_ENV=uat scripts/db/uat-refresh-demo.sh
```

Truncates every `public` table except `_migrations`, then re-seeds. Use when the schema is already up to date.

### GitHub Actions (remote UAT)

1. Open **Actions → UAT reset demo data**
2. Click **Run workflow**
3. Type `RESET` in the confirmation field

Requires `UAT_SSH_ENABLED=true` and UAT SSH secrets. Restarts Passenger after seeding.

---

## Credentials

See [uat-demo-personas.md](./uat-demo-personas.md) for the full table. Summary:

| Field | Value |
|-------|-------|
| **Main user** | `frederique.prevost@gmail.com` |
| **Shared password** | `PassTest` |

| User | Email | Role |
|------|-------|------|
| **Frederique** (main) | `frederique.prevost@gmail.com` | Pet carer + super admin (Happy Paws Clinic & Rescue Hearts) |
| Bob | `bob@demo.agathatrack.test` | Admin at Happy Paws Clinic |
| Carol | `carol@demo.agathatrack.test` | Pet carer with shared access to Buddy |
| Eve | `eve@demo.agathatrack.test` | Foster parent at Rescue Hearts |
| Dave | `dave@demo.agathatrack.test` | Dual-role user (personal pet + Rescue Hearts foster) |
| Grace | `grace@demo.agathatrack.test` | Adoption prospect for Luna |

Password is intentionally weak and documented — acceptable only on isolated non-prod databases.

To keep docs in sync after changing `server/db/seeds/demo-constants.js`:

```bash
node server/scripts/sync-demo-credentials-doc.js
```

---

## What the dataset covers

| Domain | Demo content |
|--------|----------------|
| **Owned pets** | Buddy (dog) and Whiskers (cat) — Frederique; Pip (dog) — Dave |
| **Org pets** | Clinic Cat (Happy Paws); Max, Luna, Rocky, Mittens (Rescue Hearts) |
| **Care occurrences** | Every care behaviour of the care occurrences programme — see [Care occurrences](#care-occurrences) below |
| **Health** | Vet visit record, active health issue |
| **Care scheduling (CSM)** | Multi-time weekly course and a daily After-it's-done item (away-planning inputs); established weekly weight check |
| **Away Planning** | Carer mix (all/some/none), five coverage-state windows, multi-time intersection, past/upcoming/cancelled absences, downloaded-then-edited handover timestamp |
| **Weight** | Weight history for Buddy and Whiskers |
| **Vets** | Dr. Sarah Mitchell linked to Buddy |
| **Timeline & family** | Buddy adoption milestone; Frederique holiday family event |
| **Fostering** | Active placement (Max ↔ Eve); foster-to-adopt (Rocky); completed (Mittens) |
| **Foster requests** | Sent request with Eve's "can help" response |
| **Adoption** | Rocky journey (pending conditions); Luna prospect + scheduled visit |
| **Custody** | Pending transfer of Luna to Grace |
| **Sharing** | Carol has shared access to Buddy; pending share link for Whiskers |
| **Notifications** | Overdue wellness review (urgent); foster request admin alert |
| **Org connections** | Happy Paws Clinic ↔ Rescue Hearts |
| **Permissions** | Bob has `manage_pets` override at Happy Paws |
| **Document templates** | Adoption milestones + foster intake checklist at Rescue Hearts |

Dates are **relative to seed time** (overdue entries, upcoming visits) so the app always looks realistic.

---

## Scenarios

Run individually with `node server/scripts/seed.js --scenario=<name>`:

| Scenario | Purpose |
|----------|---------|
| `guardian` | Frederique, Carol, personal pets |
| `org-clinic` | Happy Paws Clinic, Bob, Clinic Cat (discoverable, org UX v3) |
| `org-v3-demo` | Minimal org UX v3 subset: clinic + Rescue Hearts shell + connection |
| `rescue-hearts` | Rescue Hearts charity, Eve, Dave, Grace, org pets |
| `health-care` | Vets, health issues, weight, timeline, family events, Max's flea treatment |
| `care-occurrences` | Buddy's and Whiskers' care, built through the care commands (see below) |
| `care-schedule-fixture` | Multi-time weekly course and a daily After-it's-done item used by away planning |
| `away-planning` | Planned absences: carer mix, coverage states, lifecycle, multi-time overlap (after `care-schedule-fixture`) |
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
  truncate-data.js       # Truncate all public tables (keeps _migrations)
  scenarios/             # One module per scenario
server/scripts/seed.js   # CLI entry point
```

Idempotent `INSERT … ON CONFLICT DO UPDATE` — safe to re-run without truncate. Care items are recreated (delete by fixed id, then create through the care commands), so their occurrences are always consistent.

**Care is seeded through the app's commands only** (`server/db/seeds/helpers/care-commands.js`): create, record completions per occurrence, mark done, plan another date, postpone. Seeds never write `health_occurrences` with SQL — `scripts/check_occurrence_writes.js` enforces it. History in the app comes from completed occurrences (not `health_history`). Commands are replayed at past pet-home clocks (`Europe/Paris`), so time-dependent states come out right.

---

## Care occurrences

Seeded by `care-occurrences` relative to the seed day in the pet's timezone (`Europe/Paris`). Asserted row by row in `server/test/db/seeds/careOccurrencesSeed.test.js` (seed clock pinned with `SEED_CARE_CLOCK`). Every row uses its category's default schedule type unless it says "set explicitly".

| Pet | Care item | Setup | What UAT shows |
|-----|-----------|-------|----------------|
| Buddy | Apoquel (medication, Fixed schedule, 08:00 & 18:00) | Started 10 days ago; older doses recorded; yesterday 18:00 and today 08:00 not recorded | Today: "1 dose not recorded" + 08:00 Overdue (until 18:00) + 18:00 Due |
| Buddy | Heart tablet (medication, Fixed schedule, daily 09:00) | Remembered choice "Skip the next date" | Advanced settings → "If done after the due date" shows it |
| Buddy | NexGard (parasite prevention, monthly) | Due in 3 days | Due soon |
| Buddy | DHPP vaccine (yearly) | First dose done 20 days ago; booster planned in 10 days | Due soon: the booster (planned); after it, yearly from the booster |
| Buddy | Rabies vaccine (yearly) | Due in 200 days | Upcoming (collapsed) |
| Buddy | Wellness review (yearly) | Overdue by 5 days | Today → Overdue first; "Estimated next" moves with today |
| Buddy | Dental chew (dental, daily, no time) | Done yesterday → due today | "Anytime" group (or "Today's list") |
| Buddy | Grooming (every 6 weeks) | Paused 3 days ago | "Paused since …"; Resume asks the date |
| Buddy | Weekly weight check | Four weigh-ins recorded | Established marker (`care-item-model-fixture`) |
| Whiskers | Methimazole (medication, Fixed schedule, 08:00 & 20:00) | Last three days not recorded; one older dose auto-closed | Stack row "6 doses not recorded" → Review; History shows "Record as given" |
| Whiskers | Flea treatment (parasite prevention, monthly, 19:00) | Due today at 19:00 | Evening group |
| Whiskers | Nail trim (every 3 weeks) | Due tomorrow | Due soon |
| Whiskers | Cat vaccination (yearly) | Due in 90 days | Upcoming |
| Whiskers | Monthly weigh-in (weight monitoring, **Fixed schedule set explicitly**) | Anchored on the most recent 31st, that weigh-in recorded | Next dates clamp to month ends (30th / 31st); Advanced summary shows the non-default type |
| Whiskers | Vet visit | Recorded last week | History only, no open date |

Changes from the plan table (`.agents/plans/care-next-occurrence-c1a7.md` §6.4): the month-end weigh-in is on Whiskers (Buddy already has the established weekly weight check); Grooming is paused without an end date (for After-it's-done care, "Postpone until" moves the date rather than pausing); the trip with NexGard postponed after return and the booster kept with Carol is added with absences (child E).

### Resetting care data

The product is pre-launch with no users: data is wiped and reseeded, not migrated. The reset empties **every** application table, accounts included.

- **UAT:** after the deploy that carries migration 083, run **Actions → UAT reset demo data** (`scripts/db/uat-refresh-demo.sh` truncates application tables and reseeds).
- **Production (one-off, owner decision 2026-10-01):** emptied without demo data — steps in [Care tick runbook](../ops/care-tick.md#production-reset-one-off-2026-10).
- **Local:** `APP_ENV=development scripts/db/uat-reset.sh`.
- **Check:** `node server/scripts/care/repair_occurrences.js --dry-run` reports any invariant violation (expect 0 after seeding).
- **Then** install the care tick cron on that host ([runbook](../ops/care-tick.md#install-the-cron-o2switch-cpanel)).

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
