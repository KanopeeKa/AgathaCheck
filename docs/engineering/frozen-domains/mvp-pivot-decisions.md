---
title: MVP pivot decisions (frozen domains)
owner: Documentation Team
audience: both
status: locked
last_updated: 2026-09-07
tags: [engineering, frozen-domains, decisions]
---

# MVP pivot decisions (D-MVP)

Locked by execute-plan `frozen-domains-freeze-ab54`. Supersedes active Shelter/Fostering navigation decisions where noted — historical rows remain in domain docs for context.

| ID | Decision | Supersedes (examples) |
|----|----------|------------------------|
| **D-MVP-1** | Shelter workspace (`/o/*`) not in MVP. Workspace toggle and drawer Shelter entry **removed**. | D5, D-shell-4, D-v5-WORKSPACE-1/4 |
| **D-MVP-2** | Fostering sessions removed from Pet Care. Fostered pets **indistinguishable** from owned pets in UI. | D-v4-1 (Fostering tab), D-v5-WORKSPACE-5 |
| **D-MVP-3** | Pet Care primary nav: **four** destinations — Today, Pets, Care, Account. | Five-tab Pet Care nav |
| **D-MVP-4** | Shelter + Fostering **frozen**. Subscription **active**. | — |
| **D-MVP-5** | Frozen source stays in Git; frozen tests excluded from blocking CI. | — |
| **D-MVP-6** | **Semantics:** Pet Care client does not expose or send foster/org linkage on new writes. Schema may retain dormant fields. API must **reject or document** unsupported dormant fields — no silent ignore. | — |
| **D-MVP-7** | Frozen HTTP routers not mounted unless `ENABLE_FROZEN_DOMAINS=true`. **Default false everywhere** (local, UAT, prod). | Optional 404 flag proposals |
| **D-MVP-8** | Active code must not import frozen Dart/JS modules — CI boundary script. | Shelter regression on Pet Care PRs |
| **D-MVP-9** | GDPR/deletion/export for org/foster tables remains active. | — |
| **D-MVP-10** | No archived GitHub workflow; optional `scripts/test-frozen-domains.sh` manual only. | Monthly archived CI |

## UI vs API vs schema (D-MVP-6 detail)

| Layer | MVP stance |
|-------|------------|
| **UI** | No foster/Shelter semantics in presentation. |
| **Client writes** | Do not send `organization_id` or foster linkage on new Pet Care pet creates/updates. |
| **Schema** | May retain columns/tables; no drop migrations in freeze program. |
| **Public API** | Reject unsupported dormant fields with clear 400, or document as frozen/unsupported. |

## Route namespace note

Not all `/o/*` paths are intrinsically Shelter-only (e.g. legacy `/o/vets`). **Product rule:** organisation workspace disappears. Any Pet Care capability still under `/o/*` must move to `/pc/*` during isolation (phase 2), not be accidentally frozen.

## Hybrid assets (split in place — no `_frozen/` moves)

Wholly frozen BDD features: excluded from active gate by `manifest.json` `bddFeaturePatterns`.

Hybrid assets require scenario splits or active-file trims:

- `experience_navigation.feature` / `.spec.ts`
- `guardian_dashboard.feature` / `guardian.dashboard.spec.ts`
- `guardian.navigation.spec.ts`
- `guardian_onboarding.feature`
- `pet_timeline.feature` / `pet.timeline.spec.ts`
- `account_area.feature` / `account.area.spec.ts`
- `notifications.feature` / `notifications.spec.ts`
- `pet_profiles.feature` (foster distinction scenarios)

Server tests: freeze by **behaviour** (org CRUD, placements, adoption). Split files that mix pet MVP + org admin. Keep GDPR/auth deletion tests **active**.
