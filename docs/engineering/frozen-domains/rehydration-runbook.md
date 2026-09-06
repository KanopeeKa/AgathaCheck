---
title: Frozen domains — rehydration runbook
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-07
tags: [engineering, frozen-domains]
---

# Rehydration runbook

Use when revisiting Shelter or Fostering after the freeze. Expect **substantial review or rewrite** — not flip-a-flag restoration.

## Before you start

1. Read [philosophy.md](philosophy.md) and [mvp-pivot-decisions.md](mvp-pivot-decisions.md).
2. Compare `pre-frozen-domains-pivot-2026-09` vs `frozen-domains-baseline-2026-09` tags.
3. Review `manifest.json` for frozen roots.

## Manual test signal (optional)

```bash
ENABLE_FROZEN_DOMAINS=true ./scripts/test-frozen-domains.sh
```

Expect failures; record baseline. No GitHub archived workflow is maintained.

## Re-enable order (suggested)

1. **Product decision** — Reverse or replace D-MVP-* with new locked IDs.
2. **Dependencies** — Remove or relax `scripts/check_frozen_domain_boundaries.sh`; restore active→frozen imports only where intentional.
3. **APIs** — Mount frozen routers in target environments.
4. **Router** — Re-register `/o/*` and fostering routes in Flutter.
5. **Tests** — Re-include frozen Jest roots and Flutter `org` shard in CI; fix or rewrite tests.
6. **BDD/E2E** — Re-include frozen feature patterns in coverage gate; rebuild smoke-ci.
7. **Analyze** — Remove `analyzer.exclude` for frozen `sourceRoots`.

## Do not assume

- Frozen tests pass without work.
- Frozen UI matches current design system.
- Pet Care capability policy unchanged — reconcile with `petCapabilityPolicy.js`.
- Schema unchanged — run migrations from baseline forward.

## Control issue

Track rehydration as a **new** execute-plan or epic — not an extension of `frozen-domains-freeze-ab54`.
