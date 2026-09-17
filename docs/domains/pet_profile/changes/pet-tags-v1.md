---
title: Pet tags v1
owner: Product
audience: engineering
status: active
last_updated: 2026-09-17
tags: [pet-profile, pet-care]
---

# Pet tags v1

Private per-user labels for organizing and filtering pets on `/pc/pets`. No sharing integration.

## Data model

- `pet_tags` — user-owned tag definitions
- `pet_tag_assignments` — many-to-many between tags and pets

Assignments are not cleaned up when `pet_access` is revoked (lazy ignore). CASCADE on user, pet, or tag delete.

## API

- `GET/POST/PATCH/DELETE /api/pet-tags`
- `POST/DELETE /api/pets/:petId/tags` (assign/unassign)

Client uses `GET /api/pet-tags` with `pet_ids[]` for filter, profile, and manage UI.

## UI

1. Account → Preferences → Pet tags (catalog CRUD)
2. Pet profile → My tags (assign/unassign existing tags)
3. `/pc/pets` → tag filter with Match any / Match all
