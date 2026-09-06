---
title: Pet Care terminology rename — residual inventory (F-22)
owner: Documentation Team
audience: agent
status: completed
last_updated: 2026-09-06
tags: [pet_care, migration, f-22]
---

# Terminology rename residual inventory (F-22)

Execute-plan: `pet-care-terminology-rename` · Prior delivery: `pet-care-domain-rename-b088` (#829–#847).

## Already delivered (b088 — do not redo)

| Layer | Status |
|-------|--------|
| `AppExperience.petCare`, wire `pet_care` | Done |
| Routes `/pc/*` + legacy `/g/*` redirects | Done |
| `users.category` → `pet_carer` | Done (migration) |
| `NotificationScope.petCare` | Done |
| API `primary_holder_name` | Done |
| BDD/E2E workspace locators Pet Care / Suivi | Done (phase 5) |
| Active docs vocabulary (phase 6) | Done |

## Residual drift (this plan)

Internal identifiers and copy keys still use **guardian** for the Pet Care **workspace** (not custody legal terms).

### Flutter `experience` feature (~30 files)

Paths under `flutter_app/lib/features/experience/**` named `guardian_*` or `screens/guardian/`:

- Presentation screens, widgets, config, domain services
- Widget test keys e.g. `guardian_dashboard_*` (update in phase 4)

**Target:** rename to `pet_care_*` / `screens/pet_care/`; update imports and router paths only where file paths change.

### l10n ARB keys

Workspace-scoped keys still prefixed `guardian*` / `experienceGuardian*` / `landingGuardian*` (EN strings often already say "Pet Care" but key names lag).

**Target (phase 3):** rename keys to `petCare*` / `experiencePetCare*` per naming contract; **exclude**:

- `pdfGuardian`, custody timeline strings with legal "guardian" semantics
- Share-invite templates using `{guardianName}` as variable name (rename variable in phase 3 only if copy changes)

### Deprecated compile-time aliases (phase 4)

| Alias | Replacement |
|-------|-------------|
| `AppExperience.guardian` | `AppExperience.petCare` |
| `AppColorTokens.guardianPrimary` | `petCarePrimary` |
| `experience_colors.guardianPrimary` getter | `petCarePrimary` |

Keep `fromWire('guardian')` dual-read for stored prefs.

### Intentionally unchanged (custody carve-out)

| Item | Reason |
|------|--------|
| `pet_access.role = 'guardian'` | DB enum / collaborator role |
| `COLLABORATOR_ROLES` includes `'guardian'` | API contract |
| `guardianship`, `individual_guardianship` | Legal custody |
| `guardianIsOrg`, `guardianUserId` in `petCustody.js` | Holder semantics, not workspace label |
| Seed scenario `guardian` | Dev fixture name |
| Legacy `/g/*` route redirects | Back-compat until telemetry shows zero use (optional later debt) |

## F-22 completion criteria

- [x] Zero `guardian_*` filenames under `flutter_app/lib/features/experience/` (dashboard assets renamed to `pet-care-empty-*.png` / `pet-care-foster-*.png` in debt PR)
- [x] Zero `AppExperience.guardian` references in `flutter_app/lib`
- [x] Workspace l10n keys use `petCare*` / `experiencePetCare*` naming (custody/legal keys exempt)
- [x] `docs/domains/pet_care/README.md` code map no longer says "migration in progress"
- [x] F-22 row in `hardening-discovery.md` marked addressed with link to this plan

## Phase map

| Phase | Outcome |
|-------|---------|
| 1 | This inventory + criteria (docs) |
| 2 | Experience layer file/class renames |
| 3 | l10n key migration |
| 4 | Alias cleanup + test keys |
| 5 | Discovery/programme doc closure |
| debt | Optional assets, onboarding keys, nav semantics, missed widget keys |
