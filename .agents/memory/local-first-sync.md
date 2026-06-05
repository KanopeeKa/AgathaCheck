---
name: Local-first cache & remote sync
description: Why local-first repositories must treat the server as source of truth, not replay local writes
---

# Server is the source of truth; never auto-replay local-only records

**Rule:** In repositories that cache to SharedPreferences and also talk to the
backend, a read (`getAllPets`-style) must return REMOTE data as authoritative and
prune local entries that are absent remotely. Never iterate "local rows missing on
the server" and re-`create` them on the server.

**Why:** That replay loop resurrected data the user had deleted directly in the DB
(and re-materialized pets whose original create had 500'd). Combined with a create
path that saved locally first and then *swallowed* the remote error, failed creates
became permanent phantom records that reappeared on every refresh.

**How to apply:**
- Writes are remote-authoritative: on create, roll back the optimistic local write
  and RETHROW if the server rejects it, so the UI surfaces the failure (don't
  silently keep a local-only copy). IDs here are client-generated UUIDs, so the
  rollback can delete by the same id.
- Reads prune local-only rows. The one thing worth preserving across the merge is
  inline local media (e.g. `data:`-URI photos) for records that DO still exist
  remotely — keep that branch, drop everything else.
- Accepted tradeoff: a pet created during a brief offline window is not retried/kept.
  Product decision = server authoritative; predictable beats resurrecting.
