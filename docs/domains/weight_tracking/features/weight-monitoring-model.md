---
title: Weight monitoring model
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [domain, weight_tracking, pet_care]
---

# Weight monitoring model

Canonical product and API model for **one weight record**, optional **link to a weigh-in occurrence**, and **one weight screen**. Full execute-plan contracts: `.agents/plans/weight-monitoring-unify-9b2e.md` (v1.2).

## Core rules

1. **`weight_entries` is the only store of weights.** A weigh-in is completed by linking one row via `weight_entries.health_occurrence_id` (unique when set). `pets.weight` is a cache of the latest entry.
2. **Counting is explicit.** The server suggests fulfilment candidates; the user chooses (default on when exactly one match). Never automatic on pet create, import, or device.
3. **Stored in kg; displayed in the user's `weight_unit`** (`users.weight_unit`, default `kg`).
4. **Undo and dates stay consistent.** Undo removes created weights or unlinks linked ones; weight `date` and occurrence `completed_on` move together.
5. **Skip with reason** for weigh-ins (`could_not_weigh`, `pet_unsettled`, `vet_will_weigh`, `other`).
6. **Pet PUT `weight` remains for installed clients** (deprecated): records a standalone weight through the shared service; rejects non-positive values.

## Save paths

| Path | Counts as weigh-in? |
|------|---------------------|
| `POST /api/weight-entries` (+ optional `fulfils_occurrence_id`) | Only when user selects fulfilment |
| `POST …/complete-weight` | Always (legacy route; thin wrapper over shared service) |
| `POST`/`PUT /api/pets` with `weight` | Never |
| Pet create optional weight | Never |

## Flutter boundaries

- Weight UI lives in `features/weight_tracking/` (hub screen, record sheet).
- Care ↔ weight coordination uses `core` providers (`PetCareSync`, `careItemObservationSectionProvider`) — no direct feature imports.

## Programme

Execute-plan **WEIGHT** (`weight-monitoring-unify-9b2e`): children server → hub → care. See [parallel-programmes.md](../../../agent-efficiency/parallel-programmes.md).
