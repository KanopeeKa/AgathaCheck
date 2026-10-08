---
title: People domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain, people, households]
---

# People

Unified **People** directory (UI label **Contacts** / **Autour de vos animaux**), households, absence-scoped carers, and Guardian hub UX. Shipped on `main` (2026-10-05) via roadmap `people-domain-refactor-7f3b` (server, client core, client integration).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capabilities

| Capability | Document |
|------------|----------|
| Functional spec (decisions D1–D28) | [people-care-team.md](features/people-care-team.md) |
| Vocabulary (EN/FR) | [vocabulary.md](features/vocabulary.md) |

## Proposed / in-flight engineering

| Document | Role |
|----------|------|
| [people-domain-refactor.md](changes/people-domain-refactor.md) | **Proposed** target model, gap analysis, remaining UX/engineering scope (`people-domain-refactor-7f3b`) |

## Implementation status (summary)

| Capability | Status | Notes |
|------------|--------|-------|
| Contacts + pet relationships API | Shipped | `people-server-7f3b` ([#1523](https://github.com/KanopeeKa/AgathaCheck/pull/1523)) |
| Fifth nav tab `/pc/people` + Today desk | Shipped | `people-ui-hub-a58d`, `people-client-core-7f3b` |
| Hub list, detail, edit, unified add | Shipped | `people-hub-remodel-a58d`, `people-client-core-7f3b` |
| Households + sharing integration | Shipped | `people-client-core-7f3b` c7 |
| Cross-feature consumers + integration E2E | Shipped | `people-client-integration-7f3b` |
| Absence guest access + timezone (D24) | Shipped | `people-care-team-a58d` p4 |
| Vet table sunset | Debt | [#1653](https://github.com/KanopeeKa/AgathaCheck/issues/1653) |

Residual gaps: [people-domain-refactor.md](changes/people-domain-refactor.md) §4.

## Domains this touches

| Domain | What changes |
|--------|--------------|
| [Sharing](/docs/domains/sharing/README.md) | Household membership as access source; label changes (wire unchanged) |
| [Pet Care — Away Planning](/docs/domains/pet_care/features/away-planning-carer-model.md) | Carers from directory; People amendments to D-AWAY-002/003/005 |
| [Vets](/docs/domains/vet/README.md) | Vets migrate into contacts + relationships |
| [Notifications](/docs/domains/notifications/README.md) | D21, D25 reminder routing |
| [Auth](/docs/domains/auth/README.md) | Guarded deletion, GDPR export, timezone (D24), 18+ attestation (D14) |

## Code map

| Concern | Path |
|---------|------|
| People feature (Flutter) | `flutter_app/lib/features/people/` |
| Today desk module | `flutter_app/lib/features/people/presentation/desk/people_desk_module.dart` |
| Pet profile — People around {pet} | `flutter_app/lib/features/people/presentation/pet/` |
| People API | `server/routes/people/` |
| Pet access / sharing | `server/lib/petAccess.js`, `server/routes/sharing/` |
| Absence carers | `server/routes/careContext/plannedAbsencesRouter.js` |

## Tests

| Layer | Location |
|-------|----------|
| Widget | `flutter_app/test/features/people/**` |
| BDD | `flutter_app/test/bdd/features/people.feature` |
| Playwright | `people-core.spec.ts`, `people-integration.spec.ts`, `veterinarian.spec.ts` |
