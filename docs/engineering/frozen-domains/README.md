---
title: Frozen domains
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-07
tags: [engineering, frozen-domains, pet-care]
---

# Frozen domains program

Shelter and Fostering are **frozen** — preserved in Git, not maintained, not in MVP. Pet Care and Subscription remain **active**.

| Doc | Purpose |
|-----|---------|
| [philosophy.md](philosophy.md) | Why and what “frozen” means |
| [mvp-pivot-decisions.md](mvp-pivot-decisions.md) | Locked D-MVP-* product decisions |
| [manifest.json](manifest.json) | Minimal machine-readable roots (boundary script + CI) |
| [rehydration-runbook.md](rehydration-runbook.md) | How to revisit frozen domains later |
| [ci-integration.md](ci-integration.md) | What active CI excludes |

**Execute-plan:** `.agents/plans/frozen-domains-freeze-ab54.md` · control issue [#1050](https://github.com/KanopeeKa/AgathaCheck/issues/1050)

**Governing sentence:** Shelter can rot without infecting Pet Care — without building archive-management infrastructure.

## Freeze complete (acceptance)

1. No Shelter/Fostering reachable in MVP UI.
2. No frozen HTTP endpoints in production/UAT.
3. Active code does not import frozen feature modules.
4. Frozen tests cannot fail active CI.
5. Frozen Dart unreachable from active import graph; excluded from analyze.
6. New Pet Care work has no Shelter/Fostering semantics obligation.
7. GDPR/delete/export for retained frozen data still works.

## Directional dependency

```
ACTIVE ──► SHARED
            ▲
            │
FROZEN ─────┘

ACTIVE ──X──► FROZEN
```

## Tags

| Tag | When |
|-----|------|
| `pre-frozen-domains-pivot-2026-09` | Before isolation/pivot (phase 1) |
| `frozen-domains-baseline-2026-09` | After technical freeze + product pivot (phase 5) |
