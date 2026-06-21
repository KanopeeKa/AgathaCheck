---
name: Body-supplied organization_id must be membership-validated
description: Pet create/update accept organization_id from the request body; both backends must verify the caller belongs to that org before persisting.
---

# Body-supplied `organization_id` must be membership-validated

Pet create (`POST /api/pets`) and update (`PUT /api/pets/:id`) read `organization_id`
from the request body. Before persisting, both backends verify the authenticated
user is a member of that org (`SELECT 1 FROM organization_users WHERE organization_id
= ? AND user_id = ?`); a non-member gets `403 { error: 'Not a member of this
organization' }`. Omitting `organization_id` (null/empty string) skips the check —
that is intentional (personal pets).

**Why:** without the check, any authenticated user could attach a pet to an org they
don't belong to (a cross-entity IDOR). JWT auth + `user_id`-scoped queries already
prevent reading/editing *other users'* pets, but said nothing about which org a new
pet may be assigned to.

**How to apply:** any time a body-supplied foreign key grants cross-entity access
(org, shared-pet, etc.), validate the relationship server-side in BOTH the Node
(`server/routes/`) and Dart (`server/lib/`) backends — they are kept in route-for-route
parity. Match the truthy/empty-string guard semantics on both sides (Node: `if (orgId
&& ...)`; Dart: `if (orgId != null && orgId.toString().isNotEmpty && ...)`).
In Jest, the mock pool intercepts the membership query via `sql.includes('organization_users')`
— return `{ rows: [{ '?column?': 1 }] }` for member, `{ rows: [] }` for non-member.
