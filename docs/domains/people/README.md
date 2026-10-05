---
title: People domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-05
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

**Shipped** on `main` (2026-10-05): `people-server-7f3b`, `people-client-core-7f3b`, and **`people-client-integration-7f3b`** (consumers, People around {pet}, legacy client removal, integration E2E). Follow-up debt: sunset `vets` table / `pets.vet_id` ([#1653](https://github.com/KanopeeKa/AgathaCheck/issues/1653)). Residual gaps vs the target doc: [changes/people-domain-refactor.md](changes/people-domain-refactor.md) (§4).

| Capability | Status | Notes |
|------------|--------|-------|
| Contacts API (personal + household directory) | Shipped | `people-server-7f3b` ([#1523](https://github.com/KanopeeKa/AgathaCheck/pull/1523)) |
| Pet relationships API | Shipped | Slots, vet projection; compat `/api/vets` and `pets.vet_id` on wire |
| Vets ↔ People | Shipped | Projection from relationships; legacy vet routes redirect to People |
| Fifth nav tab `/pc/people` (EN label **Contacts**) | Shipped | `people-ui-hub-a58d` |
| Today desk module | Shipped | Desk ranking + person cards; opens People detail (`people-client-core-7f3b` c3/c8) |
| Hub list | Shipped | Sections, search, filters, desktop list–detail (`c3`); E2E in `people-core.spec.ts` (`c8`) |
| Person detail `/pc/people/:id` | Shipped | Tabs, pets & access, relationships (`c4`) |
| Person edit + danger zone | Shipped | Roles, kind rules, usages, inactive (`c5`) |
| Add person | Shipped | Five-step flow + share handoff (`c6`) |
| Households | Shipped | People routes `/pc/people/households`; Sharing household UI removed (`c7`) |
| Absence guest access | Shipped | `people-care-team-a58d` p4 |
| Pet profile / care / away consumers (People façade) | Shipped | `people-client-integration-7f3b` i1 |
| People around {pet} + emergency card | Shipped | `people-client-integration-7f3b` i2 |
| Legacy vet client + directory adapters removed | Shipped | `people-client-integration-7f3b` i3 |
| Integration E2E (5 journeys) | Shipped | `people-integration.spec.ts` (`people-client-integration-7f3b` i4) |

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
| Today desk module | `flutter_app/lib/features/people/presentation/desk/people_desk_module.dart` |
| Pet profile — People around {pet} | `flutter_app/lib/features/people/presentation/pet/` |
| Sharing / invites | `flutter_app/lib/features/sharing/` |
| People API | `server/routes/people/` |
| Pet access roles | `server/lib/petAccess.js`, `server/routes/sharing/` |
| Absence carers | `server/routes/careContext/plannedAbsencesRouter.js` |

## Tests

| Layer | Location |
|-------|----------|
| Widget | `flutter_app/test/features/people/**` |
| BDD | `flutter_app/test/bdd/features/people.feature` |
| Playwright | `people-core.spec.ts`, `people-integration.spec.ts`, `veterinarian.spec.ts` (`people.page.ts`) |

Hub journeys: `people.feature` + `people-core.spec.ts` (**c8**). Cross-feature integration: five scenarios in `people-integration.spec.ts` (**i4**).
