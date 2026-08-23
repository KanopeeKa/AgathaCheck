---
title: Sharing specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,sharing,specs]
---

# Sharing specs

## Roles

- `pet_access.role = shared` — collaborator via share link (distinct from foster role).
- Share acceptance may target personal guardian list or organisation inventory.

## API

`server/routes/sharing.js` — Jest: `sharing.test.js`, `sharedPetAccess.test.js`

## Widget modularization

Sharing UI split under `flutter_app/lib/features/pet_profile/widgets/sharing/` — see [/docs/debt/refactoring-debt.md](/docs/debt/refactoring-debt.md).

## Deferred

Audit logging extension for share routes — see [changes/deferred.md](../changes/deferred.md).
