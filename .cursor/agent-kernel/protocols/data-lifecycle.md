# Protocol: data-lifecycle

**When:** Deletion, transfer, share revocation, account/pet purge, foster termination, retention.

---

## 1. Questions (answer in PR/plan)

| Asset | On delete/revoke |
|-------|------------------|
| DB rows | Removed, anonymized, or retained? |
| Physical files | Deleted? |
| Sessions/tokens | Revoked? |
| Share links | Invalidated? |
| Audit records | Kept for compliance? |

## 2. Invariants

- Deletion considers **both** metadata and blobs
- Share revocation must not leave active grants
- Account/pet deletion: integration-level verification for sensitive domains
- Privacy-sensitive flows need automated tests where feasible

## 3. Related protocols

- `private-files.md` for blob cleanup
- `database-and-migrations.md` for schema cascades
- `authorization.md` for post-revocation access denial

## 4. Tests

Integration tests for delete/revoke happy path + forbidden access after action.
