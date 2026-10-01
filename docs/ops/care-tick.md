---
title: Care tick — host cron runbook
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-01
tags: [ops, cron, care, occurrences]
---
# Care tick — host cron runbook

The care tick (D-CSM-031, [decision log](../domains/pet_care/changes/care-schedule-management-decisions.md#d-csm-031--care-tick-2026-09-29)) keeps Fixed-schedule care current: it stores doses as their days arrive, closes Not recorded doses once the dose after them is three days old, and resumes items whose "Postpone until" date has come. It never creates After-it's-done dates.

Every care command runs the same catch-up for its item first, so a late or missing tick never leaves wrong data behind — only later "Not recorded" closing, later automatic resume, and reminders that wait for the next read.

## When to install it

Install the cron on a host **only after** that host runs a backend that contains migration `083_care_occurrence_model` (the script and its columns arrive together), and **after** the host's data reset (care-next-occurrence-c1a7 §6.3). Order per host:

1. The deploy that carries migration 083 succeeds (UAT: **Deploy UAT** after Pre-UAT E2E and promote; production: **Deploy production**).
2. UAT only: wait for the **UAT live E2E** run that follows the deploy to finish.
3. Reset the data (UAT: [below](#uat-reset); production: [below](#production-reset-one-off-2026-10)).
4. Install the cron ([below](#install-the-cron-o2switch-cpanel)).
5. Check it ([below](#check-it)).

## UAT reset

GitHub → **Actions → UAT reset demo data → Run workflow**, type `RESET`. It truncates every application table on UAT (all accounts included) and reloads the demo dataset (`scripts/db/uat-refresh-demo.sh`). Announce it on the open programme control issues first.

## Production reset (one-off, 2026-10)

Owner decision 2026-10-01: production has no users and is emptied once, **without** demo data. `uat-refresh-demo.sh` refuses production by design, so run these steps over SSH yourself:

```bash
cd ~/agathatrack.com/backend
NODE="$(dirname "$(readlink -f node_modules)")/bin/node"   # the cPanel nodevenv node
set -a; source .env; set +a

# 1. Backup first (keep it until launch)
mkdir -p ~/backups && pg_dump -Fc ${DATABASE_URL:+-d "$DATABASE_URL"} -f ~/backups/prod-before-reset-$(date +%Y%m%d-%H%M).dump

# 2. Confirm there is nobody to lose (expect only your own test accounts)
psql ${DATABASE_URL:+"$DATABASE_URL"} -c "SELECT count(*) AS users, max(created_at) AS newest FROM users;"

# 3. Empty every application table, keep the schema and _migrations.
#    One-off override of the non-production guard, for this reset only.
APP_ENV=development "$NODE" db/seeds/truncate-data.js

# 4. Check
psql ${DATABASE_URL:+"$DATABASE_URL"} -c "SELECT count(*) AS users FROM users;"   # 0
"$NODE" scripts/care/repair_occurrences.js --dry-run          # checked 0 care items; 0 with violations
```

Migrations insert no reference rows, so an empty database is valid. Then sign up again in the app.

If `pg_dump` or `psql` is missing on the host, take the backup from cPanel → **Databases → phpPgAdmin → Export** and run the count there; the truncate step needs only node.

## Install the cron (o2switch cPanel)

Same steps on each host; only the folder differs.

| Host | Backend folder | Log file |
|---|---|---|
| UAT | `~/uat.agathatrack.com/backend` | `~/logs/care_tick_uat.log` |
| Production | `~/agathatrack.com/backend` | `~/logs/care_tick_prod.log` |

1. Over SSH, find the node binary the app uses (cPanel's nodevenv) and create the log folder:

   ```bash
   readlink -f ~/uat.agathatrack.com/backend/node_modules
   # → /home/<user>/nodevenv/uat.agathatrack.com/backend/<version>/lib/node_modules
   ls ~/nodevenv/uat.agathatrack.com/backend/          # note <version>, e.g. 22
   mkdir -p ~/logs
   ```

   Logs live outside the deployed folder so a deploy never removes them.

2. Run the tick once by hand; it must print one JSON line:

   ```bash
   cd ~/uat.agathatrack.com/backend && ~/nodevenv/uat.agathatrack.com/backend/22/bin/node scripts/care/care_tick.js
   # {"at":"…","skipped":false,"processed":…,"created":…,"closed":…}
   ```

3. cPanel → **Advanced → Cron Jobs → Add New Cron Job**: Common settings **Once Per Fifteen Minutes** (`*/15 * * * *`), Command:

   ```bash
   cd $HOME/uat.agathatrack.com/backend && $HOME/nodevenv/uat.agathatrack.com/backend/22/bin/node scripts/care/care_tick.js >> $HOME/logs/care_tick_uat.log 2>&1
   ```

   For production, replace `uat.agathatrack.com` with `agathatrack.com` and the log name with `care_tick_prod.log`. All output goes to the log, so cPanel sends no e-mails.

How it behaves:

- It reads the backend `.env` (`DATABASE_URL` or `PG*`), like `migrate.js` over SSH.
- It takes a PostgreSQL advisory lock, so overlapping runs exit at once (`skipped: true`).
- It handles one care item per transaction with `SELECT … FOR UPDATE SKIP LOCKED`, so it never waits on a person's action.
- If the Node.js version changes in cPanel (Setup Node.js App), update `<version>` in the cron command.

## Check it

```bash
tail -n 5 ~/logs/care_tick_uat.log        # a new line every 15 minutes, "skipped": false
cd ~/uat.agathatrack.com/backend && ~/nodevenv/uat.agathatrack.com/backend/22/bin/node scripts/care/repair_occurrences.js --dry-run
# checked N care items; 0 with violations (dry run)
```

If the dry run reports violations (for example after restoring a backup), run it again with `--apply`, then the dry run again. A line with `care tick failed` in the log means the tick could not reach the database: check `.env`, then run step 2 by hand.

When `docs/ops/prod-backup-restore-plan.md` Step 3 (cron-as-code) lands, move these lines into its managed `# BEGIN agatha` / `# END agatha` block and delete the manual entries.

## Related

- [UAT demo data](../e2e/uat-demo-data.md#resetting-care-data) — resetting care data
- [Production backup and restore plan](./prod-backup-restore-plan.md)
