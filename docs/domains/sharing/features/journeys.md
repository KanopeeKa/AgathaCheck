---
title: Sharing journeys
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,sharing,journeys]
domain: sharing
---

# Sharing journeys

## Create share link

Pet owners generate a share link for collaborators to view (and optionally accept) pet access.

## View shared pet (anonymous)

Recipients open share URLs without logging in; health entries and vet info visibility per link policy.

## Accept or decline share

Share links: recipient opens `/shared/:code` and accepts into their pet list.

Email invites: existing members receive `shareInviteReceived` and land on `/invite/:code`; non-members receive email with signup link to the same landing. Accept grants `pet_access`; decline notifies the inviter.

## Hide shared pet

Swipe-to-hide removes shared pets from the home list without revoking access; unhide restores visibility.

## Expired or invalid links

Invalid or expired tokens show an appropriate error state.

---

**Specs:** [specs.md](specs.md) · BDD: `sharing.feature` · E2E: `sharing.spec.ts`
