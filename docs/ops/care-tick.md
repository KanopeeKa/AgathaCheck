---
title: Care tick — host cron runbook
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-29
tags: [ops, cron, care, occurrences]
---
# Care tick — host cron runbook

The care tick (D-CSM-031, [decision log](../domains/pet_care/changes/care-schedule-management-decisions.md#d-csm-031--care-tick-2026-09-29)) keeps Fixed-schedule care current: it stores doses as their days arrive, closes Not recorded doses once the dose after them is three days old, and resumes items whose "Postpone until" date has come. It never creates After-it's-done dates.

Every care command runs the same catch-up for its item first, so a late or missing tick never leaves wrong data behind — only later "Not recorded" closing, later automatic resume, and reminders that wait for the next read.

## Schedule it

On each backend host (UAT and production), add one cron entry for the deploy user:

```cron
*/15 * * * * cd "$HOME/<backend-dir>" && /usr/bin/env node scripts/care/care_tick.js >> logs/care_tick.log 2>&1
```

- It reads the same `.env` as the app (`DATABASE_URL` or `PG*`).
- It takes a PostgreSQL advisory lock, so overlapping runs exit at once (`skipped: true`).
- It handles one care item per transaction with `SELECT … FOR UPDATE SKIP LOCKED`, so it never waits on a person's action.
- Each run prints one JSON line: `{ at, skipped, processed, created, closed }`.

## Check it

```bash
tail -n 5 logs/care_tick.log
node scripts/care/repair_occurrences.js --dry-run   # expect "0 with violations"
```

If the dry run reports violations (for example after restoring a backup), run `node scripts/care/repair_occurrences.js --apply`, then the dry run again.

## Related

- [UAT demo data](../e2e/uat-demo-data.md#resetting-care-data) — resetting care data
- [Production backup and restore plan](./prod-backup-restore-plan.md)
