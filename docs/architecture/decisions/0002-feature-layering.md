---
title: Feature layering and dependency direction (Flutter)
owner: Architecture
audience: both
status: accepted
last_updated: 2026-10-05
tags: [architecture, flutter, modularity, active-codebase]
---

# ADR 0002 — Feature layering and dependency direction

## Context

At batch I2 base (`0577d1d6` on `main`, 2026-10-05), `node scripts/check_feature_imports.js --summary` reports **58** cross-feature import edges and **one** strongly connected component spanning ten features:

`care_intelligence ↔ care_item ↔ care_taxonomy ↔ health_tracking ↔ notifications ↔ people ↔ pet_care ↔ pet_profile ↔ sharing ↔ vet`

Rules R1–R7 are at zero; cycles remain because R4 only baselines edges, not topology. Package 9 (batch I2) makes acyclic layering permanent via ADR-directed cuts, composition moves (D21), and checker rules R5/R8 (phase 3).

## Decision

### Layer stack (bottom → top)

| Layer | Features | Role |
|------:|----------|------|
| L0 | `core` (under `lib/core`, not a feature barrel) | Shared primitives, routing infrastructure |
| L1 | `auth` | Session and identity ports |
| L2 | `care_taxonomy`, `care_item` | Care vocabulary and leaf agenda module (same tier; no `care_item` → feature imports except `core`) |
| L3 | `pet_profile` | Pet domain, list, form, and **non-composite** presentation only (D21) |
| L4 | `vet`, `people`, `pet_tags`, `sharing`, `notifications`, `weight_tracking`, `health_tracking` | Satellite domains around a pet |
| L5 | `care_intelligence`, `pet_care` | Care orchestration and schedules atop L4 |
| L6 | `experience` | Cross-feature composition, shells, and tab wiring |
| L7 (leaves) | `subscription`, `about`, `help` | Marketing and account leaves; may import `auth` only from L1 |

### Allowed import directions

A feature **A** may import feature **B** only when **all** of the following hold:

1. **Down-stack:** `layer(A) > layer(B)` (higher layer may depend on lower), **or** `A` is `experience` and `layer(B) < 6`.
2. **No up-stack:** `layer(A) < layer(B)` is forbidden (enforced as R8 in phase 3).
3. **Same-tier (L4 and L5):** no cross-import within the same layer except the explicit pairs below.
4. **L2 `care_item`:** imports only `core` and its own feature tree (existing R4 exceptions for `care_item` leaf reads remain until phase 3 inverts those call sites).
5. **L3 `pet_profile` (D21):** must **not** import `health_tracking`, `weight_tracking`, `pet_care`, `sharing`, `vet`, `notifications`, `care_intelligence`, or `people`. Composite pet surfaces that need those features move to `experience/…/pet_profile/` (phase 2).
6. **Leaves (L7):** may import `auth` only; no other feature imports.

**Explicit same-tier allowances (until removed in phase 3):**

- None at L4 or L5 — any `L4→L4` or `L5→L5` edge in the baseline is a cut-list item.

**Composition:**

- `experience` is the only feature that may aggregate widgets from multiple domains for one route.
- `core/router` and `lib/*.dart` may import feature entrypoints for registration (existing R3 exemption).

### D21 — Pet profile composition boundary

Multi-feature pet profile screens (detail tabs, care sections, health history, weight insights, report download, manage-events, org pets, etc.) **move to** `flutter_app/lib/features/experience/.../pet_profile/`. `pet_profile` retains list/form/domain and single-feature widgets only.

After phase 2, `pet_profile` has **no** dependency edges to L4/L5 features listed in criterion I2.2-1.

## Consequences

- Phase 2 executes D21 cuts (see cut list).
- Phase 3 removes remaining SCC edges and lands R5 (`feature-cycle`, no baseline) and R8 (`layer-order`, empty baseline).
- Server ownership direction (phase 4) mirrors the same “lower modules do not call higher product surfaces” rule.

## References

- Cut list: [`feature-layer-cut-list.md`](../../engineering/active-codebase-baseline/feature-layer-cut-list.md)
- Modularity gate: [`modularity.md`](../modularity.md)
- Programme: [`active-codebase-review.md`](../reviews/active-codebase-review.md)
