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

**If "phantom pets" reappear after the fix, suspect a STALE DEPLOYED BUILD, not a
code regression.** The no-re-push fix lives in the Flutter client bundle, so an old
UAT/prod artifact still resurrects. Symptom chain: deployed build's pet read 401s →
falls back to local cache (shows pets not in DB) → old build re-pushes them via the
create upsert (`POST /api/pets` is `ON CONFLICT (id) DO UPDATE` in both Node and Dart).
`PUT /api/pets/:id` is a plain UPDATE (can't resurrect). Resolution = rebuild+redeploy,
then a ONE-TIME manual delete of the already-resurrected DB rows (a fresh read only
prunes the local cache, never deletes server rows).

**Flutter web service worker hides fresh deploys — a normal refresh keeps the OLD
bundle.** `main.dart.js` is NOT content-hashed (filename is constant) and the registered
`flutter_service_worker.js` caches it, so users run stale JS (e.g. a POST still missing
its `Authorization` header) until a HARD reload / SW unregister. Don't trust a plain
refresh when verifying a frontend fix on cPanel/o2switch. To confirm what's actually
live: compare deployed asset `Last-Modified` and `md5sum main.dart.js` against the local
`flutter_app/build/web/main.dart.js` (identical md5 = same build = fix is deployed; the
remaining 401 is purely browser cache). The UAT deploy workflow itself builds fresh and
FTPs `build/web/` correctly — it is not the culprit.
