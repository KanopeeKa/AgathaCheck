---
title: Pet Care domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain, pet_care, experience]
---

# Pet Care

The **Pet Care** workspace is the plum (`/pc/*`) operational experience for individual carers: owned pets, shared pets, due care actions, and vets. **MVP (2026-09):** fostering sessions and Shelter workspace are frozen — fostered animals are ordinary pets with no special UI. See [mvp-pivot-decisions.md](/docs/engineering/frozen-domains/mvp-pivot-decisions.md).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capabilities

| Capability | Document |
|------------|----------|
| Care Item (series, detail, absence resolutions) | [care-item-evolution.md](features/care-item-evolution.md) |
| Care Schedule Management (CSM) | [care-schedule-management.md](features/care-schedule-management.md) |
| Care Context / Care Through Change | [care-context.md](features/care-context.md) |
| Away planning — carer model and handover | [away-planning-carer-model.md](features/away-planning-carer-model.md) |
| Care Progression | [care-progression.md](features/care-progression.md) |
| Care Intelligence | [care-intelligence.md](features/care-intelligence.md) |
| Care entitlements (future tiers) | [care-entitlements.md](features/care-entitlements.md) |

## Active delivery (`changes/`)

| Programme | Document | Notes |
|-----------|----------|-------|
| Care Item evolution | [care-item-evolution execute-plan](/.agents/plans/care-item-evolution.md) | Active delivery |
| Care Foundation roadmap (v0.4) | [care-foundation-roadmap.md](changes/care-foundation-roadmap.md) | Phases A–E sequencing |
| Care progression slices | [care-progression-delivery-plan.md](changes/care-progression-delivery-plan.md) | CP-0–CP-7; rules in canonical |
| Away planning (AW) | [away-planning-delivery-plan.md](changes/away-planning-delivery-plan.md) | AW-EMERGENCY–AW-10 |
| Away planning — People amendments | [amends-away-planning.md](/docs/domains/people/changes/amends-away-planning.md) | Planned D-AWAY-002/003/004/005 |
| Care Intelligence Phase D | [phase-d-review-relevance-plan.md](changes/phase-d-review-relevance-plan.md) | Research and delivery |
| Classification taxonomy | [care-classification-taxonomy-spec.md](changes/care-classification-taxonomy-spec.md) | Spec → fold when delivered |

## Frozen delivery history

| Topic | Document |
|-------|----------|
| Away Care Planning (ACP) | [away-care-planning-delivery-plan.md](changes/away-care-planning-delivery-plan.md) · [decisions](changes/away-care-planning-decisions.md) |
| Retired away decision pointer | [away-planning-decisions.md](changes/away-planning-decisions.md) → canonical care-context and carer model |
| Care Item model snapshot (2026-09-13) | [archive/care-item-model-delivery-plan-2026-09-13.md](changes/archive/care-item-model-delivery-plan-2026-09-13.md) |

## Product naming (locked)

Authoritative decision **D38** in [pet-profile-decisions.md](/docs/domains/pet_profile/features/pet-profile-decisions.md).

| Surface | EN | FR |
|---------|----|----|
| Workspace (drawer, toggle, FTUE destination) | Pet Care | Suivi |
| Dashboard pet-rail section | My Pets | Mes animaux |
| Dashboard due-items eyebrow | CARE ACTIONS | SOINS |
| Link to full due list | All Actions | Tous les soins |
| Bottom nav tab | Actions | Soins |

Eyebrow labels use **ALL CAPS** in EN (`CARE ACTIONS`, `PETS` where used). FR eyebrows stay uppercase where already established (`SOINS`, `ANIMAUX`).

### Naming layers (do not conflate)

| Layer | Target | Do not confuse with |
|-------|--------|---------------------|
| Workspace domain | Pet Care / Suivi | My Pets section |
| Dashboard pet rail | My Pets / Mes animaux | Workspace label |
| Due-items block | Care Actions (eyebrow CARE ACTIONS / SOINS) | Notification kind `care`, Care team vets |
| Bottom nav | Actions / Soins | Workspace Pet Care |
| Custody legal | guardianship, `individual_guardianship` | Workspace branding |

**Not** Pet Care workspace terminology: custody **guardianship**, `individual_guardianship` transfer kinds, legal holder on a pet — see [org-custody-model.md](/docs/domains/shelter/features/org-custody-model.md).

## Wire and code map

Delivered by execute-plans `pet-care-domain-rename-b088` (#829–#847) and [`pet-care-terminology-rename`](/.agents/plans/pet-care-terminology-rename.md) (#1041–#1045).

| Concern | Target |
|---------|--------|
| App experience | `AppExperience.petCare`, wire `'pet_care'` |
| Routes | `/pc/*` (legacy `/g/*` redirects until telemetry clears) |
| User category | `pet_carer` |
| Notifications scope | `NotificationScope.petCare` |
| API holder display | `primary_holder_name` (not `guardian_name`) |
| Theme tokens | `petCarePrimary` |
| Shell semantics | `drawer_pet_care`, `experience_workspace_menu_pet_care`, `DrawerMenuGroup.petCarePlum` |
| Flutter feature root | `flutter_app/lib/features/experience/` (`pet_care_*` paths) |
| Node routes | `server/routes/` Pet Care handlers under pet access policy |

Stored prefs: `fromWire('guardian')` dual-read remains for `last_app_section` migration.

### E2E locator targets

| Concern | EN regex | FR regex |
|---------|----------|----------|
| Workspace switcher | `^Pet Care$` | `^Suivi$` |
| My Pets section | `My Pets` | `Mes animaux` |
| Bottom nav tab | `^Actions$` | `^Soins$` |
| Care Actions eyebrow | `CARE ACTIONS` | `SOINS` |

Full navigation contract: [navigation-contract.md](/docs/e2e/navigation-contract.md).

### Deferred identifier drift (intentional)

Rename only when touching the owning feature — not bulk F-22 reopen.

| Tier | Item | Notes |
|------|------|-------|
| 2 | `PetListController.guardianShellPets()` | `pet_profile` — shell custody filter |
| 2 | `guardian_passed_away_section`, `guardian_embedded_pets_list` | `pet_profile` widgets |
| 3 | `guardian_dashboard.feature`, `guardian_onboarding.feature` | BDD filenames |
| 3 | `guardian.navigation.spec.ts` | Nav rail E2E |
| Permanent | `pet_access.role = 'guardian'`, `guardianship` enums | Custody / API contract |

### Permanent custody carve-out (never rename for workspace consistency)

| Item | Reason |
|------|--------|
| `pet_access.role = 'guardian'` | DB enum / collaborator role |
| `COLLABORATOR_ROLES` includes `'guardian'` | API contract |
| `guardianship`, `individual_guardianship` | Legal custody |
| `guardianIsOrg`, `guardianUserId` in `petCustody.js` | Holder semantics |

## Security and hardening

Phase A discovery (findings, actor matrix, follow-on plan map) lives in [changes/hardening-discovery.md](changes/hardening-discovery.md). Implementation programme (merged slices F-01–F-23): [pet-care-hardening](/docs/engineering/pet-care-hardening/README.md). Control issue [#993](https://github.com/KanopeeKa/AgathaCheck/issues/993).

| ID | Status | Summary |
|----|--------|---------|
| PET-CARE-R-001 | Live | Workspace rename wire/API/DB and F-22 internal identifiers delivered (see wire map above) |
| PET-CARE-R-002 | Live | P0 hardening slices (private files, share minimization, capability auth, session v2, data lifecycle) merged per engineering programme index |
| PET-CARE-R-003 | Planned | Residual gold-standard gaps and new findings — track in engineering programme and debt; discovery report remains the historical evidence table |

Care Intelligence live test with real health data still cites hardening prerequisites in [care-intelligence.md](features/care-intelligence.md).

## Cross-domain references

| Topic | Link |
|-------|------|
| Pet profile (CRUD, timeline) | [pet_profile](/docs/domains/pet_profile/README.md) |
| Health due-items and entries | [health_tracking](/docs/domains/health_tracking/README.md) |
| Shell navigation | [navigation](/docs/domains/navigation/README.md) |
| Program vocabulary | [program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) §2 |
| Navigation contract (E2E) | [navigation-contract.md](/docs/e2e/navigation-contract.md) |
