---
title: Fostering specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,fostering,specs]
---

# Fostering specs

## Placement lifecycle

[foster-placement-lifecycle.md](foster-placement-lifecycle.md)

## Contract pack (G0)

API and workflow contracts for foster platform foundation:

[g0-contract-pack.md](g0-contract-pack.md)

## Data migration

[migration-appendix.md](migration-appendix.md)

## Custody transfers

Transfer kinds and acceptor rules are defined in the organization custody model — [/docs/domains/shelter/features/org-custody-model.md](/docs/domains/shelter/features/org-custody-model.md). This domain owns the **workflows** that invoke those transfers.

## Node routes

`server/routes/fosterPlacements.js`, `custodyTransfers.js` — Jest: `fosterPlacements.test.js`, `custodyTransfers.test.js`
