---
title: Care item cross-feature imports (C1 decision)
owner: Architecture
audience: agent
status: active
last_updated: 2026-10-04
tags: [architecture, pet-care, modularity]
---

# Care item cross-feature imports (gap-close C1)

## Decision (2026-10-04)

**Option 3 — defer structural split; ratchet-only until ARCH-G.**

`care_item` detail UI intentionally composes `health_tracking` presentation/providers and `pet_care` care-surface widgets. Violations are **baselined** in `scripts/feature-import-baseline.json` (R2/R3 edges). New edges remain blocked by `node scripts/check_feature_imports.js`.

## Rationale

- B1/B2 need stable Care Item view surfaces without a multi-PR shell extraction in the gap-close window.
- Splitting detail sections into a composition layer is tracked as **#1545** (DEBT-ARCH-CYCLE) for a dedicated sprint.
- Re-baseline-only (option 2) adds no product value beyond the existing gate.

## B-stream guardrails

- B1/B2 must not add **new** cross-feature import edges; use existing providers/widgets or extend `care_item` internals.
- Before merging B1, run `node scripts/check_feature_imports.js` (also in CI governance).

## References

- Plan: `care-requirements-gap-close-c1a7` phase C1
- Control issue: #1526
- Debt: #1545
