---
title: Care Progression — Delivery Plan
owner: Product / Agent
audience: both
status: in-delivery
status_since: 2026-10-08
folds_into: docs/domains/pet_care/features/care-progression.md
last_updated: 2026-10-08
tags: [pet_care, care_progression, delivery]
---

# Care Progression — Delivery Plan

**Canonical product behaviour:** [care-progression.md](../features/care-progression.md) — requirements, acceptance criteria, and decision log live there.

**Execute-plan:** [.agents/plans/care-progression-v1.md](/.agents/plans/care-progression-v1.md) (CP-0 … CP-7 branch mapping).

**Predecessor programme:** [care-foundation-roadmap.md](./care-foundation-roadmap.md) (Phases A–E).

---

## Slice overview

```text
CP-0  Docs + naming + care_family write-path + data audit
CP-1  Shared care core/capabilities + server authority seams
CP-2  Weight occurrence ↔ observation transactional completion (+ FK)
CP-3  Weight establishment evaluator + persist transition
CP-4  Milestone persistence + idempotency + per-user presentation
CP-5  Care Rhythms Established marker
CP-6  Profile/dashboard presentation arbitration
CP-7  Timeline milestone integration

V1.1  medication_course_completed milestone
```

Durable rules folded into the canonical doc (2026-10-08). This file retains **time-bound** API and slice references for the active execute-plan.

---

## API summary (V1)

| Method | Path | Slice | Purpose |
|--------|------|-------|---------|
| `GET` | `/api/pets/:petId/care-progression` | CP-1+ | Establishment + milestones read model |
| `GET` | `/api/pets/:petId/care-progression/pending-moments` | CP-4 | Per-user presentation candidates |
| `POST` | `/api/pets/:petId/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight` | CP-2 | Transactional weight completion |
| `DELETE` | `/api/weight-entries/:id` | CP-2 | Linked weight delete re-opens occurrence |
| `POST` | `/api/pets/:petId/care-progression/re-evaluate` | CP-3 | Internal/dev re-evaluation (auth gated) |
| `POST` | `/api/pets/:petId/care-progression/moments/:bundleId/acknowledge-presented` | CP-4/6 | Per-user presentation acknowledgement |

Wire details: [api-reference.md](/docs/architecture/api-reference.md) §Care progression.

---

## CP-0 checkpoint (folded)

Pre-production signed off 2026-09-09: no live progression users; run `node scripts/care/audit_care_families.js` before establishment enablement. See **CARE-PROGRESSION-D-021** and **CARE-PROGRESSION-R-027** in the canonical doc.

---

## Explicit deferrals (not V1)

Seasonal milestones; progress rings; generic observation-store migration; paywall runtime; long-horizon family evaluation; progression consuming CIM review-relevance; `medication_course_completed` in initial ship (V1.1). Full list: canonical **CARE-PROGRESSION-R-028** … **R-031**.
