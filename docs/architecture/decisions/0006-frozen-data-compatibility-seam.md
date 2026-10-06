---
title: "ADR 0006: Frozen-data compatibility seam (Package 2)"
owner: Architecture / Backend
audience: both
status: accepted
last_updated: 2026-10-06
tags: [architecture, frozen-domains, adr]
adr: 0006
programme: active-codebase-batch-a-cbb8
---

# ADR 0006: Frozen-data compatibility seam (Package 2)

## Status

**Accepted** — 2026-10-06 (Batch K phase 3). Route gating: Batch A phase 2; boundary checker: Batch A phase 3.

## Context

Shelter and Fostering domains are **frozen** (not in active CI or MVP UX) but schema, historical rows, and installed clients may still carry organization/foster fields on pet DTOs. Package 2 must prevent active Pet Care from invoking frozen **commands** without breaking wire compatibility for retained data (review §Package 2, foster/org fields on DTOs).

## Decision

### Runtime gate

- `ENABLE_FROZEN_DOMAINS === 'true'` is the only switch that mounts frozen routers and allows shelter/foster APIs (`server/lib/frozenDomains.js`).
- Default everywhere: **off** — org-transfer routes return **404** (`rejectFrozenShelterApi`); pet writes with `organization_id` return **400** (`rejectFrozenOrganizationIdOnPetWrite`).

### Registration vs imports

- Frozen route **registration** is conditional in `server/bin/server.js`; static imports may still load modules — enforcement is at mount and handler gate, not “tree shaking”.
- `scripts/check_frozen_domain_boundaries.sh` consumes `docs/engineering/frozen-domains/manifest.json` to block active production code from importing frozen feature roots.

### Compatibility seam (retained data)

- Active Pet Care APIs may **read** historical org/foster-linked fields when present in the database, but must not expose new org/foster **commands** when the gate is off.
- Flutter `PetRepository` may still decode retained DTO keys (`organizationId`, `isFoster`, etc.) for installed clients; Pet Care UI must not surface frozen workflows unless the gate and product scope explicitly allow it.
- Individual user-to-user transfer and permitted family-history reads remain active regardless of the gate (Batch A characterization).

### Both prefixes

All gates and compatibility rules apply to `/api` and `/backend/api` equally.

## Consequences

- Removing foster/org columns from wire DTOs requires a versioned adapter and client evidence — not a silent cleanup PR.
- Expanding frozen surface requires manifest, checker, and ADR updates.
- Erasure and retention policies document lawful handling of frozen-linked rows (`docs/engineering/privacy/erasure-data-map.md`).

## References

- [Frozen domains manifest](../../engineering/frozen-domains/manifest.json)
- [Active codebase review — Package 2](../reviews/active-codebase-review.md)
- Component: [server/routes/pets/README.md](../../../server/routes/pets/README.md)
