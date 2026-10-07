---
title: Server library size report (D7 blocking ratchet)
owner: Engineering
audience: both
status: active
last_updated: 2026-10-06
tags: [architecture, size, governance]
---

# Server library size report (D7 blocking ratchet)

Decision **D7** in the [architecture review](../../architecture/reviews/active-codebase-review.md) adds `server/lib` and `server/services` to the **blocking** size gate (Batch J phase 2). `node scripts/check_file_size.js` fails when:

- a new hand-written file in those roots exceeds **500** physical lines without an allowlist entry, or
- an allowlisted file grows beyond its recorded `maxLines`.

Allowlist entries in `scripts/file-size-allowlist.json` require `owner`, `reason`, and `review_date`. The check emits a **warning** when `review_date` is in the past.

Blocking roots remain `flutter_app/lib` and `server/routes` with the same 500-line policy.

## Flutter classification summary (2026-10-06)

Physical and heuristic line totals by path classification (from `check_file_size.js` output):

| Classification | Files | Physical lines | Heuristic lines |
|---|---:|---:|---:|
| screens | 109 | 17,354 | 16,054 |
| widgets | 419 | 46,873 | 42,842 |
| controllers/providers | 65 | 5,155 | 4,461 |
| data | 120 | 16,035 | 14,586 |
| other | 415 | 35,737 | 31,308 |

Heuristic counts match `scripts/architecture/architecture-metrics.py` (non-blank, non-comment approximation).

## Allowlisted server offenders (2026-10-06)

| File | Physical lines | Classification | Owner | Reason | Review date | Planned action |
|---|---:|---|---|---|---|---|
| `server/lib/care/observations/weightObservationService.js` | 551 | Active (weight observations) | Engineering | Weight observation service consolidated fulfilment paths | 2026-12-28 | Split by responsibility in Batch K |
| `server/lib/orgPeople.js` | 538 | Frozen (Shelter family) | Engineering | Frozen domain internals; freeze contract forbids refactoring | 2026-12-28 | Leave while frozen |
| `server/lib/orgPermissions.js` | 523 | Frozen (Shelter family) | Engineering | Frozen domain internals; freeze contract forbids refactoring | 2026-12-28 | Leave while frozen |
| `server/lib/care/occurrence/occurrenceRepository.js` | 501 | Active (occurrence persistence) | Engineering | Occurrence persistence grew with care command stack | 2026-12-28 | Split in Batch K phase 1 |

Frozen classification follows `docs/engineering/frozen-domains/manifest.json` and the Shelter-family basename list in `metrics-headline.md`.

## How to refresh

```sh
node scripts/check_file_size.js
```

Update this document when allowlist entries or Flutter classification totals change materially.
