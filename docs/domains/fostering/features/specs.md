---
title: Fostering specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,fostering,specs]
domain: fostering
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

## Engineering rules

- Org-scoped routes must validate body-supplied org IDs against membership — see [.agents/memory/body-supplied-org-id-validation.md](/.agents/memory/body-supplied-org-id-validation.md) and [shelter org roles](/docs/domains/shelter/features/org-roles-and-permissions.md).
- Vocabulary, permissions, and audit catalog: [g0-contract-pack.md](g0-contract-pack.md).
- Foster onboarding delivery: [changes/j1-foster-onboarding.md](../changes/j1-foster-onboarding.md).
