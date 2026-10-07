---
name: Care item completion / occurrence semantics
description: Pointer — product rules live in the CSM canonical doc (2026-10-07 consolidate)
---

**Canonical doc:** `docs/domains/pet_care/features/care-schedule-management.md` (D-CSM-019 … D-CSM-035, requirements CARE-SCHEDULE-MANAGEMENT-R-001 … R-010).

**Agent lesson:** Only `server/lib/care/occurrence/**` may write `health_occurrences` (`scripts/check_occurrence_writes.js`). Test clock: `X-Care-As-Of` in development/test/ci only.
