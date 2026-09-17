---
title: Sharing specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-17
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

Email invites store target role in `pet_share_invites.role` (`carer` or `co_parent`).

Away Planning `carer_kind: shared_user` is unchanged; assignable users must have `pet_access` in `PET_ACCESS_ROLES` (`carer`, `co_parent`).

## Permission enforcement

Server splits management checks in `server/lib/petAccess.js`:

- `userCanManageProfile` / `userCanSharePet` — owner + co-parent (+ foster for link-only share)
- `userCanManageCare` — owner + co-parent + carer + foster

## API

### Share links (unchanged wire paths)

- `server/routes/sharing.js` — share links, hide, accept
- `server/routes/sharing/petAccessRoutes.js` — access list, role PUT, revoke, unfollow

### Email invites (PR1)

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/share/invites` | Body `{ invitee_email, pet_ids, role }` — atomic 403 if any pet fails `userCanSharePet` |
| GET | `/api/share/invites/code/:code` | Public preview (rate-limited) |
| POST | `/api/share/invites/code/:code/accept` | Auth required; idempotent; may upgrade `carer` → `co_parent` |
| POST | `/api/share/invites/:id/decline` | Auth required |
| DELETE | `/api/share/invites/:id` | Cancel (inviter or owner/co-parent on pets) |
| GET | `/api/pets/:id/invites` | Pending invites for one pet |
| GET | `/api/share/access?pet_ids=` | Aggregate access + pending invites (max 20 ids) |

Services: `server/services/sharing/shareInviteService.js`, `shareLinkService.js`, `shareAccessService.js`

Jest: `server/test/sharing/invites/`, `sharing.test.js`

## UI module

`flutter_app/lib/features/sharing/` — unified `SharePetScreen` (`/pet/:petId/share`, `/pc/pets/share`), `InviteLandingScreen` (`/invite/:code`), role labels, hide affordance.

Viewer matrix:

| Viewer | Screen |
|--------|--------|
| Owner / co-parent | Full invite, links, people, transfer (owner), hide (co-parent) |
| Carer | Stop following + hide |
| Foster | Link-only (no email invite) |

## Notifications

- `shareInviteReceived` (administrative) → `/invite/:code`
- `shareInviteAccepted` / `shareInviteDeclined` (care) → inviter

## Deferred

- `PetViewerRole.guardian` → `petParent` rename (viewer enum only)
- Audit logging extension for share routes — see [changes/deferred.md](../changes/deferred.md)
- PR2 (done): `shareLinkService.js` / `shareLinkQueries.js` + extended `shareAccessService` / `shareAccessQueries`; routes are thin HTTP layers. Link creation returns **403** (not 404) when `userCanSharePet` fails — aligned with access routes.
