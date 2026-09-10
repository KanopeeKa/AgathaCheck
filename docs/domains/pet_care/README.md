---
title: Pet Care domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-09
tags: [domain, pet_care, experience]
---

# Pet Care

The **Pet Care** workspace is the plum (`/pc/*`) operational experience for individual carers: owned pets, shared pets, due care actions, and vets. **MVP (2026-09):** fostering sessions and Shelter workspace are frozen — fostered animals are ordinary pets with no special UI. See [mvp-pivot-decisions.md](/docs/engineering/frozen-domains/mvp-pivot-decisions.md).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Care Intelligence

| Document | Role |
|----------|------|
| [care-intelligence.md](/docs/domains/pet_care/features/care-intelligence.md) | Canonical product behaviour |
| [care-foundation-roadmap.md](/docs/domains/pet_care/changes/care-foundation-roadmap.md) | Programme sequencing (v0.4) — Phases A–E |
| [phase-d-review-relevance-plan.md](/docs/domains/pet_care/changes/phase-d-review-relevance-plan.md) | Phase D research/delivery plan |

## Care Progression

| Document | Role |
|----------|------|
| [care-progression.md](/docs/domains/pet_care/features/care-progression.md) | Canonical product behaviour |
| [care-progression-delivery-plan.md](/docs/domains/pet_care/changes/care-progression-delivery-plan.md) | CP-0–CP-7 delivery plan (shipped) |
| [care-entitlements.md](/docs/domains/pet_care/features/care-entitlements.md) | Future tier principles (no runtime in V1) |

## Care Context (Care Through Change)

| Document | Role |
|----------|------|
| [care-context.md](/docs/domains/pet_care/features/care-context.md) | Canonical product behaviour |
| [care-through-change-delivery-plan.md](/docs/domains/pet_care/changes/care-through-change-delivery-plan.md) | CC-1–CC-4 delivery plan (active) |

## On this domain

| Section | Link |
|---------|------|
| **Care Foundation & Intelligence roadmap (v0.4)** | [changes/care-foundation-roadmap.md](changes/care-foundation-roadmap.md) |
| Domain rename plan | [changes/domain-rename-plan.md](changes/domain-rename-plan.md) |
| F-22 residual inventory | [changes/terminology-rename-inventory.md](changes/terminology-rename-inventory.md) |
| Pet profile decisions (D38) | [pet-profile-decisions.md](/docs/domains/pet_profile/features/pet-profile-decisions.md) |
| Navigation contract (E2E) | [navigation-contract.md](/docs/e2e/navigation-contract.md) |
| Program vocabulary | [program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) §2 |

## Product naming (locked)

| Surface | EN | FR |
|---------|----|----|
| Workspace (drawer, toggle, FTUE destination) | Pet Care | Suivi |
| Dashboard pet-rail section | My Pets | Mes animaux |
| Dashboard due-items eyebrow | CARE ACTIONS | SOINS |
| Link to full due list | All Actions | Tous les soins |
| Bottom nav tab | Actions | Soins |

Eyebrow labels use **ALL CAPS** in EN (`CARE ACTIONS`, `PETS` where used). FR eyebrows stay uppercase where already established (`SOINS`, `ANIMAUX`).

## Code map

Wire and routes use `pet_care` and `/pc/*`. Internal workspace identifiers use `pet_care_*` filenames, `PetCare*` classes, `petCare*` l10n keys, and shell semantics `drawer_pet_care` / `experience_workspace_menu_pet_care` — completed by execute-plan [`pet-care-terminology-rename`](../../.agents/plans/pet-care-terminology-rename.md) (PRs #1041–#1045) plus tier-1 shell semantics follow-up. Residual inventory and deferred drift: [terminology-rename-inventory.md](changes/terminology-rename-inventory.md).

**Not** Pet Care workspace terminology: custody **guardianship**, `individual_guardianship` transfer kinds, legal holder on a pet — see [org-custody-model.md](/docs/domains/shelter/features/org-custody-model.md).

## Related feature domains

Pet CRUD, timeline, and list behaviour remain documented under [pet_profile](/docs/domains/pet_profile/README.md). Health due-items under [health_tracking](/docs/domains/health_tracking/README.md). Shell navigation under [navigation](/docs/domains/navigation/README.md).

## Engineering hardening programme

Phase A discovery (findings table, milestones, follow-on plans):

- [changes/hardening-discovery.md](changes/hardening-discovery.md)
- Control issue: [#993](https://github.com/KanopeeKa/AgathaCheck/issues/993) (`pet-care-hardening-discovery`)
- Programme index: [pet-care-hardening](/docs/engineering/pet-care-hardening/README.md)
