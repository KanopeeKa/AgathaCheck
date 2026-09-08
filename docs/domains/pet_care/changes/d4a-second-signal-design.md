---
title: D4a — Second signal family design
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-08
tags: [pet_care, care_intelligence, phase_d, d4a]
---

# D4a — Second signal family (design only)

**Status:** design-only — no implementation in Phase D.

## Candidate families (ranked)

| Rank | Signal | Structured data today | Notes |
|------|--------|----------------------|-------|
| 1 | **Activity / exercise** | Not reliable | Would need validated device or guardian cadence capture |
| 2 | **Appetite** | Not reliable | Subjective scales only; high false-positive risk |
| 3 | **BCS (body condition score)** | Not reliable | Clinic-entered occasionally; not longitudinal |

## Design principles for signal #2

- Must be **structured longitudinal** data with quality classifier parity to weight.
- Must have independent provenance concepts (not overloaded onto weight fields).
- Multi-signal safeguards require **both** families to pass quality + materiality gates.
- Guardian copy must name each evidence family explicitly (see [care-intelligence.md](../features/care-intelligence.md)).

## Recommendation

Defer implementation until weight-only Phase E path is evaluated (D5b/D7). Activity is the likely first second family if capture UX is validated in user research.
