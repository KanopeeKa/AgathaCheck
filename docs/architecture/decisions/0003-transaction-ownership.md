---
title: "ADR 0003: Server transaction ownership"
owner: Backend / Architecture
audience: both
status: accepted
last_updated: 2026-10-06
tags: [architecture, database, adr]
adr: 0003
programme: active-codebase-batch-e-backend-integrity-e41f
---

# ADR 0003: Server transaction ownership

## Status

**Accepted** — 2026-10-06 (Batch K phase 3). Implemented in Batch E and enforced by architecture tests.

## Context

Active codebase review Package 3 found ~20 hand-written `BEGIN` blocks, duplicate optional-transaction helpers, and a pool-query fallback that could commit work on a different connection than the one that began a transaction. Pet deletion, invites, and weight completion needed a single, testable contract for atomicity and post-commit side effects (D11).

## Decision

### Mandatory runner

All multi-statement atomic work in active server code uses `withTransaction(pool, async (client) => …)` from `server/lib/db/withTransaction.js`:

1. Acquire one `PoolClient` via `pool.connect()`.
2. `BEGIN` → run callback → `COMMIT` with a **COMMIT guard** (`commitResult.command === 'COMMIT'` or throw `TransactionAbortedError`).
3. On any error: `ROLLBACK` (preserve original error), always `release()` in `finally`.
4. **No pool fallback** — callbacks must use the supplied `client`; enqueue helpers (for example `enqueueCleanupJob`) reject a `Pool` instance.

Route modules translate HTTP; **services and lib own transactions** unless the operation is a single idempotent statement with no paired side effects.

### Ownership rules

| Concern | Owner |
|--------|--------|
| When a transaction is required | Application service or `server/lib/**` use case |
| HTTP status mapping | Route module |
| Post-commit async work (file purge kick, cleanup runner) | After `withTransaction` resolves successfully |
| Required in-transaction rows (invite notifications, passed-away ledger, erasure acceptance) | Same `withTransaction` callback (D11) |

### Enforcement

- `server/test/architecture/transactionOwnership.test.js` — no `BEGIN` / `withOptionalTransaction` in active production roots (manifest exclusions and documented deferrals only).
- `server/test/db/petLifecycle.integration.test.js` — rollback and client-release behaviour on real PostgreSQL.

### Deferrals

Care occurrence locking (`careItemLock.js`, `careTick.js`) may use dedicated primitives until migrated; listed in the architecture test allowlist. Tracked in [GitHub #1735](https://github.com/KanopeeKa/AgathaCheck/issues/1735).

## Consequences

- New routes must not call `pool.connect()` directly for business transactions.
- Characterization tests that mocked `BEGIN`/`COMMIT` were replaced or narrowed as services moved.
- Pool-only queries remain valid for read-only handlers and single-statement writes with no cross-row invariant.

## References

- [Modularity — backend layers](../modularity.md)
- Batch E plan: `.agents/plans/active-codebase-batch-e-backend-integrity-e41f.md`
- Component READMEs: `server/routes/pets/README.md`, `server/routes/sharing/README.md`
