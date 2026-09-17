---
title: Sharing specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-16
tags: [domain,sharing,specs]
domain: sharing
---

# Sharing specs

## Roles (`pet_access.role`)

| Wire value | User label | Capabilities |
|------------|------------|--------------|
| *(none)* | Pet Parent | Owner via `pets.user_id` — full control including transfer |
| `co_parent` | Co-parent | Profile, vet, care, sharing.manage — **no** transfer |
| `carer` | Carer | Care entries only — no profile/vet/sharing admin |
| `foster` | Foster | Foster placement axis — separate from share links |

Share links store target role in `pet_share_links.access_role` (`carer` or `co_parent`; default `carer`).

Away Planning `carer_kind: shared_user` is unchanged; assignable users must have `pet_access` in `PET_ACCESS_ROLES` (`carer`, `co_parent`).

## Permission enforcement

Server splits management checks in `server/lib/petAccess.js`:

- `userCanManageProfile` / `userCanSharePet` — owner + co-parent (+ foster for link-only share)
- `userCanManageCare` — owner + co-parent + carer + foster

**Migration note:** carers previously had latent profile/vet write via `userCanManagePet`; migration `065` tightens server enforcement to match UI.

## API

- `server/routes/sharing.js` — share links, hide, accept
- `server/routes/sharing/petAccessRoutes.js` — access list, role PUT, revoke, unfollow
- `server/lib/petSharing/permissions.js` — role normalization and sharing action matrix

Jest: `sharing.test.js`, `pets/extended.test.js`

## UI module

`flutter_app/lib/features/sharing/` — consolidated sharing panel, role labels, hide affordance for personal collaborators.

## Deferred

- `PetViewerRole.guardian` → `petParent` rename (viewer enum only)
- Audit logging extension for share routes — see [changes/deferred.md](../changes/deferred.md)
