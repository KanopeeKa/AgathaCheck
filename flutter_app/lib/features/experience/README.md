---
title: Experience (Pet Care shell)
owner: Pet Care team
status: active
component_id: flutter.feature.experience
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Pet Care shell, drawer navigation, desk modules, and composed home surfaces (D5 composition layer). **Non-goals:** domain persistence owned by other features.

## Public entrypoint

`package:pet_profile_app/features/experience/experience.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `AppExperience` | domain entity | Branding and route context |
| `DrawerMenuItem`, `DrawerMenuGroup` | domain entities | Shell configuration |
| `ExperienceEligibility`, `PetCareOnboardingRules` | domain services | Gating helpers |
| `experienceProviders` | providers | Shell state |
| `ExperienceShellScaffold` | UI widget | Shared scaffold |
| Account, chooser, home, resolve, settings, onboarding screens | UI screens | Router destinations |
| `PetCareDueEventsScreen` | UI screen | Embedded in pet profile manage events |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| Other features via **public entrypoints only** | Direct `data/` imports (R2) |

## Side effects & freshness

Coordinates navigation; delegates data to feature providers.

## Permissions

Inherits authenticated session.

## Tests

`flutter_app/test/features/experience/`
