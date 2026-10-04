---
title: Weight tracking specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [domain, weight_tracking]
domain: weight_tracking
feature_id: weight-specs
---

# Weight tracking — implementation specs

See [weight-monitoring-model.md](weight-monitoring-model.md) for rules. API shapes and phase delivery: `.agents/plans/weight-monitoring-unify-9b2e.md`.

## Server (target after WEIGHT A)

- Shared service: `server/lib/care/observations/weightObservationService.js`
- Fulfilment rule: `weightFulfilment.js` (CSM half-interval windows)
- Endpoints: list/latest, overview, fulfilment-candidates, fulfil, auth `weight_unit`
- Observation hooks: care engine does not SQL `weight_entries` directly (§5.5b)

## Flutter (target after WEIGHT B/C)

- Hub: `WeightHubScreen`, record sheet with counts-as UX
- User unit preference via profile API
- Care item observation slot (`numeric_weight`) and history weight rows (WEIGHT C)
