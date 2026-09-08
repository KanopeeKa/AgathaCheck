---
title: D7 — Phase E handoff contract
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-08
tags: [pet_care, care_intelligence, phase_d, phase_e]
---

# D7 — Phase E handoff contract

## Decision (D5b — standing grant)

Proceed to Phase E with **weight-only safeguard** scope when:

- D5a harness reference vectors pass (`runEvaluationHarness` summary `all_pass`)
- D6.1 sample benchmark rubric validated (disagreement cases preserved)
- Structured weight context fields exist in production API (D0 migration 055)

## Minimum evidence bar (weight-only)

| Criterion | Threshold |
|-----------|-----------|
| Quality classifier | `adequate: true` |
| WeightChangeSpec | `unexplained_material` + persistent trend |
| Suppression | No active `management_context`; no matching `vet_target` reference |
| Measurements | ≥3 over ≥14 days (see `QUALITY_THRESHOLDS`) |

## Guardian copy template (single-signal)

> "{petName}'s weight has been trending {direction} across several measurements. There isn't a known weight plan recorded, so it may be worth mentioning this to your vet."

**Forbidden:** plural "patterns/signals" unless a second family genuinely contributed.

## Persistence (Phase E implementation)

| Artifact | Phase E action |
|----------|----------------|
| `CareSafeguard` | New table + API — map in DATA_MAP before ship |
| `PhaseDEvidenceTrace` | Ephemeral default; persist only for safeguard audit if approved |
| Progressive context UI | Complete D3 capture widgets in pet profile weight flow |

## API entry point (internal today)

`GET /api/pets/:id/review-relevance/evaluate` — returns `internal_only: true` evaluation + trace. Phase E may promote to guardian-facing safeguard card when gates pass.

## Regulatory

Update [DATA_MAP.md](/regulatory/DATA_MAP.md) before persisting safeguards or traces beyond ephemeral evaluation.
