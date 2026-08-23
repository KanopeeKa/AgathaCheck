---
title: Organisation pet custody model
owner: Architecture Team
audience: both
status: active
last_updated: 2026-08-21
tags: [architecture,design,domain]
domain: shelter
feature_id: org-custody-model
---
# Organisation pet custody model

Authoritative reference for guardianship, care, shadows, org connections, and transfers.
Supersedes parts of `docs/domains/fostering/changes/org-fostering-strategy.md` glossary where they conflict.

## Glossary

| Term | Meaning |
|------|---------|
| **Guardianship** | Who is legally responsible for the pet. Org → `pets.organization_id`. Individual → `pets.user_id` when `organization_id` IS NULL. |
| **Care** | Who provides day-to-day care. `pets.care_holder_kind` + `care_holder_user_id` / `care_holder_org_id`. |
| **Live pet** | Canonical `pets` row and its mutable health/weight data. |
| **Shadow** | Frozen point-in-time snapshot in `archived_pets` when guardianship leaves an org. Never syncs after creation. |
| **Fostered** | Guardian = org, care = individual fosterer. Org admins see live pet in org inventory; fosterer shares live view. |
| **Shared** | Visibility via `pet_access` without care transfer. Collaborators may add health entries. |
| **Org connection** | Symmetric link between two orgs required before org→org transfer. |

## Care / guardianship matrix

| Situation | Guardian | Care |
|-----------|----------|------|
| Pet in org, not fostered | Org | Org |
| Fostered | Org | Pet guardian (fosterer) |
| Personal pet | Pet guardian | Pet guardian |
| Pet guardian + org care (e.g. cattery) | Pet guardian | Org (future) |

## Shadow rules

1. Created **only** when both guardianship and care leave the org (adoption, org→org transfer, direct adopt).
2. **Frozen at creation** — point-in-time JSON snapshot (`shadow_snapshot`), not live.
3. Linked to live pet via `archived_pets.pet_id`.
4. **Return:** shadow deleted; live pet `organization_id` restored; history while away stays on live pet.

## Org connections

- Request via one-time token (14-day expiry, revocable by sender).
- Accept → symmetric active connection; both orgs see basic admin info.
- Either party may disconnect → pending transfers between them cancelled.

## Transfers

| Kind | Initiator | Acceptor |
|------|-----------|----------|
| `individual_guardianship` | Org admin (direct adopt or post-foster) | Recipient user |
| `org_to_org` | Sending org admin | Receiving org admin |
| `return_to_org` | Current guardian (user or org) | Original org admin |

## Hide (home list only)

- **Fostered org pets:** org admins/super admins may hide from **personal home** list (`org_pet_home_hidden`). Org section always shows full inventory.
- **Fosterer hide:** `pet_access.hidden` only when `role = foster` and placement active.
- Auto-clear home hide when foster ends (`not_in_foster`).

## Flutter UI (Sprint 6.2)

| Surface | Location |
|---------|----------|
| Pending custody inbox | Home list `PendingCustodyTransfersSection` |
| Org connections | `OrganizationConnectionsSection` on org detail |
| Org→org transfer | `TransferPetToOrgScreen` |
| Connection accept | `/organizations/connect/:token` |
| Home hide (fostered) | Swipe on org-grouped pets in home list; unhide in `OrganizationHomeHiddenPetsSection` |
| Fosterer hide | Swipe on fostered pets section |
| Frozen shadow detail | `ArchivedPetDetailScreen` from archived list |

## API surface (Node canonical)

| Area | Routes |
|------|--------|
| Connections | `POST/GET .../organizations/:orgId/connection-requests`, `POST .../connection-requests/:token/accept`, `GET/DELETE .../connections` |
| Custody | `POST .../pets/:petId/custody-transfers`, `POST /api/custody-transfers/:id/accept|cancel` |
| Home hide | `PUT .../pets/:petId/home-hidden` |
