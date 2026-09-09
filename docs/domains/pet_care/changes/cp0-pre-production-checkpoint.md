---
title: CP-0 Pre-production checkpoint
owner: Care Progression programme
audience: agent
status: active
last_updated: 2026-09-09
tags: [pet_care, care_progression, cp0]
---

# CP-0 Pre-production checkpoint

**Signed off:** 2026-09-09 (execute-plan `care-progression-v1`, phase `cp0`)

## Environment status

| Check | Result |
|-------|--------|
| Production live users with care progression data | **No** — pre-production |
| Destructive data reset required before CP-3 | **No** |
| Phase E safeguards on `main` | **Yes** (PR #1096) |

## CP-0 audit actions

1. Run `node scripts/care/audit_care_families.js` against dev/staging before CP-3 establishment enablement.
2. Recurring API writes require explicit `care_family` (Flutter write-path ships in CP-0).
3. Legacy rows may still have null `care_family`; read-path inference remains until cleanup.
4. DB `NOT NULL` on `care_family` deferred until audit shows zero ambiguous recurring rows.

## Cleanup plan (if audit finds issues)

- Backfill `care_family` from type inference for legacy recurring rows in dev/staging only.
- Re-run audit until recurring-without-family count trends to zero.
- Document any `other` family recurring rows for manual review before establishment.
