---
title: Away Planning — Delivery Plan
owner: Product / Agent
audience: both
status: in-delivery
status_since: 2026-10-07
folds_into: docs/domains/pet_care/features/away-planning-carer-model.md
plan: documentation-migration-carer-model-514a
last_updated: 2026-10-07
---

# Away Planning — Delivery Plan

**Status:** Shipped (V1 + AW-11). **Canonical behaviour:** [care-context.md](../features/care-context.md) (context, hub, plan presentation) and [away-planning-carer-model.md](../features/away-planning-carer-model.md) (carer schema, readiness carer fact, handover PDF).

This file keeps **historical phase sequencing** for agents tracing AW-* PRs. Do not treat phase tables as current product requirements.

## Carer and handover phases (shipped)

| Phase | Outcome |
|-------|---------|
| AW-EMERGENCY | Hang-on-error fix (`publicError`); D-AWAY-013 |
| AW-1 | Veterinary team terminology (D-AWAY-012) |
| AW-4 | Carer migration `063`, PATCH `pet_carers`, `carer-candidates` |
| AW-8 | Readiness derivation (carer + care facts) |
| AW-7 | Plan page Who's caring (no reschedule) |
| AW-9 | Full-plan handover PDF; `last_handover_downloaded_at` |
| AW-11 | `pet_note` + per-pet handover PDF ([away-planning-per-pet-handover-spec.md](./away-planning-per-pet-handover-spec.md)) |

Context and projection phases (AW-0, AW-2, AW-3, AW-5a/b, AW-6, AW-10) are documented against [care-context.md](../features/care-context.md) and [away-care-planning-delivery-plan.md](./away-care-planning-delivery-plan.md).

**Execute-plan archive:** `.agents/plans/away-planning-v1.md`

## Related

- [away-planning-decisions.md](./away-planning-decisions.md) — retired pointer
- [away-planning-per-pet-handover-spec.md](./away-planning-per-pet-handover-spec.md) — AW-11 detail
