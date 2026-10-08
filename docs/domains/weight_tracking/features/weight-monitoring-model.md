---
title: Weight monitoring model
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain, weight_tracking, pet_care]
domain: weight_tracking
feature_id: weight-monitoring-model
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

## User journeys

### Record weight (hub)

Guardian opens **Weight tracking** for a pet → **Record weight** → enters value in preferred unit → when a weigh-in is due, chooses **Counts as** (default on for single match) → weight saved and optionally completes the occurrence.

### Record weight outside a routine

Same sheet; turn off counts-as or pick **Don't count** when multiple routines match → standalone weight still appears on chart and history.

### Complete weigh-in from care

Occurrence screen: enter weight in user unit, or skip with reason. Linked weight visible on occurrence and in care item history (after WEIGHT C).

### Read-only profile weight

Pet edit form shows latest weight + link to weight screen; weights are recorded on the hub or via deprecated API fields for legacy clients.

## Implementation reference

### Server (target after WEIGHT A)

- Shared service: `server/lib/care/observations/weightObservationService.js`
- Fulfilment rule: `weightFulfilment.js` (CSM half-interval windows)
- Endpoints: list/latest, overview, fulfilment-candidates, fulfil, auth `weight_unit`
- Observation hooks: care engine does not SQL `weight_entries` directly (§5.5b)

### Flutter (target after WEIGHT B/C)

- Hub: `WeightHubScreen`, record sheet with counts-as UX
- User unit preference via profile API
- Care item observation slot (`numeric_weight`) and history weight rows (WEIGHT C)

### Tests

- BDD: `weight_tracking.feature`
- Playwright: `weight.tracking.spec.ts`, `weight.hub.spec.ts` (WEIGHT B)
- Calendar wire format: [/docs/architecture/calendar-dates.md](/docs/architecture/calendar-dates.md)

## Deferred work

Open rows: [/docs/debt/debt.md](/docs/debt/debt.md) (filter **Domain = weight_tracking**).
