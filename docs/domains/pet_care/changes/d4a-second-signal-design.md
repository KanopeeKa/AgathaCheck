---
title: D4a — Second signal family design
owner: Product / Agent
audience: both
status: in-delivery
status_since: 2026-10-08
folds_into: docs/domains/pet_care/features/care-intelligence.md
plan: documentation-migration-514a
last_updated: 2026-10-08
---

# D4a — Second signal family (design only)

**Status:** design-only — no implementation in Phase D.

**Canonical behaviour:** [care-intelligence.md](../features/care-intelligence.md) §Second signal family and CARE-INTELLIGENCE-R-013.

## Candidate families (ranked)

| Rank | Signal | Structured data today | Notes |
|------|--------|----------------------|-------|
| 1 | **Activity / exercise** | Not reliable | Would need validated device or guardian cadence capture |
| 2 | **Appetite** | Not reliable | Subjective scales only; high false-positive risk |
| 3 | **BCS (body condition score)** | Not reliable | Clinic-entered occasionally; not longitudinal |

## Recommendation

Defer implementation until weight-only Phase E path is evaluated (D5b/D7). Activity is the likely first second family if capture UX is validated in user research.
