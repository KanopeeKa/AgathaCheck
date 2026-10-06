---
title: "ADR 0007: Pet list cache freshness (D2 / D18)"
owner: Mobile / Architecture
audience: both
status: accepted
last_updated: 2026-10-06
tags: [architecture, flutter, cache, adr]
adr: 0007
programme: active-codebase-batch-g-client-authority-e41f
---

# ADR 0007: Pet list cache freshness (D2 / D18)

## Status

**Accepted** — 2026-10-06 (Batch K phase 3). Implemented in Batch G phase 1.

## Context

The pet list used a hybrid error model: auth and hard failures threw, while transport errors could return cached pets without surfacing age (characterization baseline **D2**). Roadmap **D18** requires explicit freshness states and banners on every pet surface.

## Decision

### Persisted sync metadata

- Per-user `lastSyncedAt` is stored with the cached pet list (local persistence).
- On successful remote fetch, `fromRemoteThisCall` is true and freshness is **`fresh`**.

### Freshness states (D18)

`PetCacheFreshness` in `pet_cache_freshness.dart`:

| State | Rule | UX |
|-------|------|-----|
| `fresh` | Remote data in this fetch | No staleness banner |
| `stale` | Cache ≤ **7 days** (`petCacheStaleWindow`) | Info banner with sync time |
| `expired` | Cache > 7 days | Warning + retry |
| `unknown` | No timestamp (legacy cache) | Warning + retry |

Local-only / no-token paths never report `fresh` and never set `isStale: false`.

### Error hybrid (D2)

- **401 / 403 / 5xx / parse errors** — propagate (no silent cache).
- **Transport errors** when cache exists — return cached pets with appropriate freshness (`stale` / `expired` / `unknown`) and `isStale: true`.
- User switch must not show another user's cached pets (dedicated test).

### Non-goals

- Server-side cache headers for pet list (freshness is client repository concern).
- Hiding cached pets on transport failure — data stays visible with honest metadata.

## Consequences

- All pet list surfaces consume repository results with freshness metadata (`pet_providers.dart`, experience stale banners).
- Pet **detail** freshness migration tracked separately in baseline; list contract is normative.
- Changing the 7-day window requires product sign-off and test updates.

## References

- Roadmap D18: `.agents/plans/active-codebase-completion-e41f.md`
- Batch G: `.agents/plans/active-codebase-batch-g-client-authority-e41f.md`
- Component: [pet_profile README](../../../flutter_app/lib/features/pet_profile/README.md)
