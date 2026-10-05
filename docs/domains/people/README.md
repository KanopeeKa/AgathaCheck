---
title: People domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-28
tags: [domain, people, households]
---

# People

Unified **People** directory, households, absence-scoped carers, and Guardian hub UX. Backend phases ship via execute-plan `people-care-team-a58d`; **navigation and list hub** via `people-ui-hub-a58d`; **hub remodel** (cards, detail, edit, unified add, E2E) via `people-hub-remodel-a58d`.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## On this domain

| Section | Link |
|---------|------|
| Functional spec (decisions D1–D28) | [features/people-care-team.md](features/people-care-team.md) |
| **Refactor target, gaps and plan** | [changes/people-domain-refactor.md](changes/people-domain-refactor.md) |
| Vocabulary (EN/FR) | [features/vocabulary.md](features/vocabulary.md) |
| UI hub navigation (5-tab, desk module) | [changes/ui-hub-navigation.md](changes/ui-hub-navigation.md) |
| Backend delivery phases | [changes/delivery-plan.md](changes/delivery-plan.md) |
| Planned amendments to Away Planning | [changes/amends-away-planning.md](changes/amends-away-planning.md) |

## Implementation status (Guardian / Pet Care)

State at `main` before slot **4** landing (2026-10-04). Gaps and the target are in [changes/people-domain-refactor.md](changes/people-domain-refactor.md) (§4 gap analysis, §1 bugs B1–B13).

| Capability | Status | Notes |
|------------|--------|-------|
| Contacts API (personal + household directory) | **Landing slot 4** | `people-server-7f3b` on integration branch — writer, usages, roster/detail, household notes |
| Pet relationships API | **Landing slot 4** | Slots, vet projection, compat `/api/vets` and `pets.vet_id` unchanged on wire |
| Vets ↔ People | **Landing slot 4** | One-way projection from relationships (`vetProjection.js`); legacy vet endpoints retained |
| Fifth nav tab `/pc/people` (EN label **Contacts**) | Shipped | `people-ui-hub-a58d` |
| Today desk module | Shipped, partial | Raw role labels (B5), ranking rules not implemented, rail shows households not members → hotfix h2, client-core c3 |
| Hub list | Shipped, partial | Directory cards; name-only search; household sections are empty placeholders; desktop list–detail broken (B4) → client-core c3 |
| Person detail `/pc/people/:id` | Shipped, partial | One page, no tabs, linked pets for vets only → client-core c4 |
| Person edit + danger zone | Shipped, partial | Roles and kind not editable; no reactivate → client-core c5 |
| Add person | Shipped, partial | Single screen, 4 of 10 roles, no pet linking, generic invite hand-off → client-core c6 |
| Households | **Landing slot 4** (server) | Member removal preview, household notes, email invites (`household_invites`); UI still minimal → client-core c7 |
| Absence guest access | Shipped | `people-care-team-a58d` p4 |
| **Refactor** | Planned | Roadmap [`people-domain-refactor-7f3b`](/.agents/plans/people-domain-refactor-7f3b.md), landing order in [parallel-programmes.md](/docs/agent-efficiency/parallel-programmes.md). The hub remodel plan (`people-hub-remodel-a58d`) is closed; delivery of its remaining scope moves to the refactor |

## Domains this changes

| Domain | What changes |
|--------|--------------|
| [Sharing](/docs/domains/sharing/README.md) | Household membership becomes a new source of access. User-facing access labels change (wire values don't). Household Full access can't share long-term. The owner and co-parents still can (D26) |
| [Pet Care — Away Planning](/docs/domains/pet_care/features/away-planning-carer-model.md) | Carers are picked from the directory, replacing `note_only`. Access can be granted for an absence. D-AWAY-003 is amended |
| [Vets](/docs/domains/vet/README.md) | `vets` migrates into contacts (identity plus a primary-vet relationship) |
| [Notifications](/docs/domains/notifications/README.md) | Reminders go to the named person, or to the owner and Full access members (D21, D25). Adds an "all events" setting |
| [Auth](/docs/domains/auth/README.md) | Account deletion is guarded for pets other people rely on. GDPR export is extended. The account gets a timezone (D24) and an 18+ attestation (D14) |

## Code map

| Concern | Path |
|---------|------|
| People feature (Flutter) | `flutter_app/lib/features/people/` |
| Today desk module | `flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_people_desk_module.dart` |
| Card pattern reference | `flutter_app/lib/features/vet/presentation/widgets/vet_team_card.dart` |
| Sharing / invites | `flutter_app/lib/features/sharing/` |
| People API | `server/routes/people/` |
| Pet access roles | `server/lib/petAccess.js`, `server/routes/sharing/` |
| Absence carers | `server/routes/careContext/plannedAbsencesRouter.js` |

## Tests

| Layer | Location |
|-------|----------|
| Widget | `flutter_app/test/features/people/**` |
| BDD | `flutter_app/test/bdd/features/people.feature` |
| Playwright | `e2e/playwright/tests/guardian.navigation.spec.ts`, `guardian.dashboard.spec.ts`, vet redirect specs |

BDD and Playwright scenarios are expanded in `people-hub-remodel-a58d` phase **p4-tests-e2e**.
