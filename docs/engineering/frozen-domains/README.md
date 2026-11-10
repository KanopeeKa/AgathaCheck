---
title: Frozen domains removal record
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-10
tags: [engineering, frozen-domains, pet-care]
---

# Shelter and Fostering code removal (2026-11)

The frozen Shelter and Fostering **product code** was deleted from the active tree in programme `frozen-domains-removal-3f9c` (UI UX review Part 5, November 2026). The MVP ships **Pet Care only**. This folder is the engineering removal record; product rationale remains in [`mvp-pivot-decisions.md`](mvp-pivot-decisions.md).

## Recovery tag

Before the removal merged to `main`, owners tag `main` as **`pre-frozen-domains-removal-2026-11`** so the full removed tree is one `git checkout` away. The earlier freeze baseline tag **`frozen-domains-baseline-2026-09`** still marks the last commit where frozen code was complete under the September 2026 freeze programme.

## What was removed

| Area | Removed (summary) |
|------|-------------------|
| Flutter | `features/organization/`, `features/fostering_session/`, their tests, analyzer exclusions; unreachable active widgets; dead auth screens (`LoginScreen`, `SignupScreen`); single-valued `AppExperience` and workspace toggle |
| Server | Frozen HTTP mounts and gate; 14 unused frozen-only modules; frozen route files; frozen e-mail templates and seed scenarios; frozen Jest lane files that only served deleted code |
| E2E / BDD | Frozen Playwright specs and BDD features tied to deleted roots |
| Active UI copy | Help, Account, About, My details, notification settings matrix, and pending-actions messaging no longer describe shelter, organisation workspace, fostering, or Family Events |

**Not removed (by programme scope):** database schema and migrations (`023`, `028`, `042` unchanged); GDPR export and deletion paths; `POST /pets/:id/transfer-to-org`, `pinned_organization_id`, login/`/me` membership payloads; `rejectFrozen*` guards on active pet routes; redirect behaviour for legacy `/o/*`, `/organizations*`, `/archived-pets`, `/pending-actions`; `core/router/app_router.dart`.

## Server modules kept (and why)

Eight server modules from the original frozen inventory stay because active code or migrations still import them: `adoptionJourneys`, `custodyTransfers`, `fosterPlacements`, `fosterProfiles`, `fosterSessions`, `orgMemberPrivacy`, `orgPetViewAccess`, `petCustody`. They support retained data, export, and migration replay—not live Shelter/Fostering product UI.

## Boundary machinery (unchanged here)

`scripts/check_frozen_domain_boundaries.sh`, its fixture test, [`manifest.json`](manifest.json), frozen exclusions in pre-push scripts, and related CI steps remain until a separate owner PR retires them (protected paths in the removal programme). After code deletion the boundary check still passes with an empty frozen root set in manifest.

## Data decision (pending)

Pets and rows with `organization_id`, foster placements, and related notification kinds may still exist in production databases. **No schema drop** is part of this removal. Count of pets with non-null `organization_id` and confirmation that no producer emits foster/adoption/custody notification kinds are owner inputs recorded at programme approval. Retiring API fields and tables is a later data-protection track (review § 5.4).

## Related docs

| Doc | Role |
|-----|------|
| [`mvp-pivot-decisions.md`](mvp-pivot-decisions.md) | Locked D-MVP-* product decisions (why Pet Care-only MVP) |
| [`manifest.json`](manifest.json) | Machine-readable roots for the boundary script (unchanged by removal PRs) |
| [`docs/design/terminology.md`](../../design/terminology.md) | Active vocabulary; frozen-domain words are not active product language |
| Plan | `.agents/plans/frozen-domains-removal-3f9c.md` |
