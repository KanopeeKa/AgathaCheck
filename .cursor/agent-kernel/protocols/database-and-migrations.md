# Protocol: database-and-migrations

**When:** Schema change, migration, backfill, constraints, indexes, persisted semantics.

**Scripts:** `cd server && node scripts/migrate.js up`

---

## 1. Inspect

- Current schema (`server/migrations/` or canonical SQL)
- Migration history — no duplicate numbering
- Deployed-data implications (existing rows)

## 2. Requirements

- Forward migration only in repo workflow
- Integrity constraints explicit
- Transactions for multi-step changes
- Indexes for new query patterns
- Backfill for existing data when semantics change
- **Never assume production can reset its database**

## 3. Tests

- Fresh schema path (migrate on empty DB)
- Upgrade path from previous schema state
- Failure/rollback consideration documented in PR

## 4. Escalation (halt)

Destructive migration, large production data rewrite → autonomous-pr-policy §Escalation.

## 5. Verification

```bash
cd server && node scripts/migrate.js up
cd server && npx jest --env=node --forceExit  # domain tests
```

Real-DB integration tests when AuthZ/persistence critical (Pet Care hardening target).
