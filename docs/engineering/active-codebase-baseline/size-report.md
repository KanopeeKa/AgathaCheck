---
title: Server library size report (D7 report-only)
owner: Engineering
audience: both
status: active
last_updated: 2026-09-29
tags: [architecture, size, governance]
---

# Server library size report (D7, report-only)

Decision **D7** in the [architecture review](../../architecture/reviews/active-codebase-review.md) adds `server/lib` to size coverage **report-only first**, then a ratchet. From Batch D phase 3 on, `node scripts/check_file_size.js` scans `server/lib/**` and `server/services/**` and lists any file over 500 physical lines under **"Report-only (D7)"**. These entries never change the exit code. The blocking roots (`flutter_app/lib`, `server/routes`) are unchanged.

The ratchet lands in Batch J phase 2 (`active-codebase-batch-j-standards-e41f`). From then on, a new file over 500 lines in these roots fails, and existing offenders may not grow past their recorded size.

## Current report-only offenders (2026-09-29, `main` @ `adaff34`)

| File | Physical lines | Classification | Owner | Reason it is over the limit | Review date | Planned action |
|---|---:|---|---|---|---|---|
| `server/lib/orgPeople.js` | 538 | Frozen (Shelter family: org people directory) | Engineering | Frozen domain internals; the freeze contract forbids refactoring them | 2026-12-28 | Leave while frozen; re-assess if Shelter is unfrozen |
| `server/lib/orgPermissions.js` | 523 | Frozen (Shelter family: org role permissions) | Engineering | Frozen domain internals; the freeze contract forbids refactoring them | 2026-12-28 | Leave while frozen; re-assess if Shelter is unfrozen |
| `server/lib/care/schedule/projectSchedule.js` | 502 | Active (care schedule projection) | Engineering | Schedule projection grew with the care-item evolution work | 2026-12-28 | Split by responsibility in Batch K phase 1 (`active-codebase-batch-k-final-acceptance-e41f`), or ratchet at 502 in Batch J phase 2 |

Frozen classification follows `docs/engineering/frozen-domains/manifest.json` and the Shelter-family list in `docs/engineering/active-codebase-baseline/metrics-headline.md`.

## How to refresh

```sh
node scripts/check_file_size.js   # see the "Report-only (D7)" section
```

When the list changes, update this table in the same PR, including owner, reason, review date and action for any new entry.
