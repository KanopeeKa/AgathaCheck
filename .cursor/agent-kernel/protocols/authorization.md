# Protocol: authorization

**When:** Pet access, roles, sharing, nested resources, health data visibility, org permissions, any “who can do what on whose data.”

**Policy helpers:** search `server/` for centralized capability/policy modules before adding inline checks.

---

## 1. Inspect

- Route handler AuthZ path end-to-end
- Nested resources (pet → health entry → attachment)
- Share/collaboration/foster grant tables and revocation
- Flutter UI gates (must not be the only enforcement)
- Existing Jest tests for the domain

## 2. Actors (select applicable)

| Actor | Use when |
|-------|----------|
| Anonymous | Public routes, share links |
| Owner | Pet/profile owner |
| Collaborator / shared carer | Sharing grants |
| Foster | Active fostering session |
| Org member / viewer / admin | `/o/*` operations |
| Unrelated authenticated user | Negative tests |
| Revoked / former user | Post-revocation denial |

Not every actor applies to every endpoint.

## 3. Invariants

- **Backend AuthZ is mandatory** — UI hiding is not security
- Possession of UUID, object key, or share URL is **not** authorization
- Use centralized policy/capability decisions
- Cross-pet and nested-object access must verify ownership/grant on **each** level
- No duplicated divergent role checks across handlers

## 4. Anti-patterns to search

- Direct `owner_id === req.user.id` without policy helper
- AuthZ only in Flutter provider
- Assuming share token scope includes unrelated pets/fields
- Missing check on update/delete of child resource

## 5. Tests (required for R2+)

- **Allowed** case per relevant actor
- **Denied** case: unrelated user, revoked collaborator, expired share (as applicable)
- Prefer integration/real-DB tests for AuthZ matrix when persistence involved (mock pool misses IDOR)

## 6. Verification

```bash
cd server && npx jest --env=node --forceExit test/<domain>/
```

Document actor matrix in PR or test file header when non-obvious.
