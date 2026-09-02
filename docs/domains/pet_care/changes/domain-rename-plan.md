---
title: Pet Care domain rename plan
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-09-02
tags: [pet_care, migration, execute-plan]
---

# Pet Care domain rename — delivery reference

Execute-plan: `pet-care-domain-rename-b088` · Control issue #829.

## Goal

Full-stack rename of the Guardian workspace to **Pet Care**, including wire values, routes, API, DB, tests, and docs — without renaming the dashboard **My Pets** pet-rail section or custody **guardianship** legal terms.

## Naming layers

| Layer | Target | Do not confuse with |
|-------|--------|---------------------|
| Workspace domain | Pet Care / Suivi | My Pets section |
| Dashboard pet rail | My Pets / Mes animaux | Workspace label |
| Due-items block | Care Actions (eyebrow CARE ACTIONS / SOINS) | Notification kind `care`, Care team vets |
| Bottom nav | Actions / Soins | Workspace Pet Care |
| Custody legal | guardianship, individual_guardianship | Workspace |

## Wire migration map

| Current | Target |
|---------|--------|
| `AppExperience.guardian` | `AppExperience.petCare` |
| wire `'guardian'` | `'pet_care'` |
| `/g/*` routes | `/pc/*` |
| `users.category = 'pet_guardian'` | `pet_carer` |
| `NotificationScope.guardian` | `pet_care` |
| `guardian_name` (API) | `primary_holder_name` |
| `guardianPrimary` theme tokens | `petCarePrimary` |
| `drawerGuardian` l10n | Pet Care / Suivi |
| `myPets` l10n | **unchanged** — My Pets / Mes animaux |

## Custody carve-out

Keep in custody model and adoption/foster BDD: **guardianship**, **individual_guardianship**, care/guardian matrix columns. Rename only workspace-scoped identifiers and product copy that referred to the Guardian *experience*.

## Phases

1. Vocabulary & D38 (this doc + decisions)
2. DB & API migration
3. Flutter wire & `/pc/*` routes
4. l10n & UI copy
5. BDD & Playwright E2E
6. Documentation sweep
7. Integration → `main` with `/babysit-uat`

## E2E locator targets (post-migration)

| Concern | EN regex | FR regex |
|---------|----------|----------|
| Workspace switcher | `^Pet Care$` | `^Suivi$` |
| My Pets section | `My Pets` | `Mes animaux` |
| Bottom nav tab | `^Actions$` | `^Soins$` |
| Care Actions eyebrow | `CARE ACTIONS` | `SOINS` |

## Risks

- Deploy order: API/DB before Flutter wire
- Stored `last_app_section=guardian` prefs — dual-read on `fromWire`
- `pet_access.role=guardian` — audit before migration
- Do not rename `myPets` key or section semantics
