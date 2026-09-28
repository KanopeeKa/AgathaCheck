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
| Vocabulary (EN/FR) | [features/vocabulary.md](features/vocabulary.md) |
| UI hub navigation (5-tab, desk module) | [changes/ui-hub-navigation.md](changes/ui-hub-navigation.md) |
| Backend delivery phases | [changes/delivery-plan.md](changes/delivery-plan.md) |
| Planned amendments to Away Planning | [changes/amends-away-planning.md](changes/amends-away-planning.md) |

## Implementation status (Guardian / Pet Care)

| Capability | Status | Notes |
|------------|--------|-------|
| Contacts API + basic list | Shipped | `people-care-team-a58d` p1 |
| Fifth nav tab `/pc/people` | Shipped | `people-ui-hub-a58d` |
| Today **People** desk module | Shipped | Professionals, carers, household rail |
| Hub list (search, filters, sections) | Shipped | `ListTile` rows — remodel replaces with cards |
| Person detail `/pc/people/:id` | Planned | `people-hub-remodel-a58d` p1–p2 |
| Person edit + danger zone | Planned | Revoke/remove **only** in Edit |
| Unified **Add person** + sharing | Planned | Reuses `features/sharing` |
| Households / guest access | Backend phases p3–p4 | See delivery plan |

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
