---
title: D7 — Phase E handoff contract
owner: Product / Agent
audience: both
status: in-delivery
status_since: 2026-10-08
folds_into: docs/domains/pet_care/features/care-intelligence.md
plan: documentation-migration-514a
last_updated: 2026-10-08
---

# D7 — Phase E handoff contract

**Canonical behaviour:** [care-intelligence.md](../features/care-intelligence.md) — weight-only bar, copy template, and CARE-INTELLIGENCE-R-023.

## Decision (D5b — standing grant)

Proceed to Phase E with **weight-only safeguard** scope when:

- D5a harness reference vectors pass (`runEvaluationHarness` summary `all_pass`)
- D6.1 sample benchmark rubric validated (disagreement cases preserved)
- Structured weight context fields exist in production API (D0 migration 055)

## Persistence (Phase E implementation)

| Artifact | Phase E action |
|----------|----------------|
| `CareSafeguard` | New table + API — map in DATA_MAP before ship |
| `PhaseDEvidenceTrace` | Ephemeral default; persist only for safeguard audit if approved |
| Progressive context UI | Complete D3 capture widgets in pet profile weight flow |

## API entry point (internal today)

`GET /api/pets/:id/review-relevance/evaluate` — returns `internal_only: true` evaluation + trace. Phase E may promote to guardian-facing safeguard card when gates pass.
