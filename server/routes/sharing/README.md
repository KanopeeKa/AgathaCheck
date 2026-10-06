---
title: Sharing routes (Node.js)
owner: Backend team
status: active
component_id: server.routes.sharing
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

HTTP translation for share invites, invite accept/decline/revoke, share links, and pet access aggregation on `/api/share` and `/backend/api/share`. **Non-goals:** household invites (`households/`), org shelter sharing (frozen).

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/routes/sharing/` |
| Services | `server/services/sharing/shareInvite*Service.js`, `shareLinkService.js`, `shareAccessService.js` |
| Mount | `server/routes/sharing.js` shim |

## Owned data (primary)

`share_invites`, `pet_access`, share link tokens, in-app notification rows for invite events.

## Public API (selected)

| Endpoint | Inputs | Output | Errors | Transaction owner |
|----------|--------|--------|--------|-------------------|
| `POST /invites` | email, pet_ids, role | 201 invite + `delivery`; 200 replay (D22) | 400, 401 | `shareInviteCreateService` — `withTransaction` + advisory lock |
| `POST /invites/:id/accept` | invite id | access grants | 404, 409 | accept service transaction |
| `POST /invites/:id/decline`, `…/revoke` | invite id | status | 403 | respective services |
| `GET /invites/code/:code` | code | preview (no auth) | 404 | read-only |
| Pet access aggregates | pet id | collaborators list | 403 | read services |

In-app notifications for existing users are inserted **inside** the invite transaction (D11). Email delivery remains best-effort metadata.

## Side effects

- Notifications after commit for email channel only.
- Audit/logging for security-sensitive revoke/accept.

## Permissions

Inviter must own or co-parent share (`userCanSharePet`); accept requires matching invitee account/email.

## Tests

`server/test/sharing.test.js`, `server/test/sharing/invites/*.test.js`, `server/test/sharedPetAccess.test.js`.

## Module layout

| Module | Responsibility |
|--------|----------------|
| `inviteRoutes.js` | Invite CRUD flows |
| `petAccessRoutes.js` | Access listing and updates |
| `shareAccessAggregateRoutes.js` | Aggregated views |
| `index.js` | Registers route groups |

ADR: [0003](../../../docs/architecture/decisions/0003-transaction-ownership.md), [0004](../../../docs/architecture/decisions/0004-cleanup-jobs.md) (D11).
