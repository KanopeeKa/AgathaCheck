---
title: Cursor engineering framework v2
owner: Documentation Team
audience: agent
status: completed
last_updated: 2026-09-05
tags: [agent, engineering, cursor]
---
# Plan: cursor-engineering-framework-v2

## Goal

Consolidate AgathaTrack Cursor agent infrastructure: Engineering Router, selective protocols, three-tier skill taxonomy, and Tier 1 skill integration — without replacing execute-plan runtime, PR hygiene, or CI machinery.

## Phases (single PR)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 | Inventory + compatibility map | done |
| 2 | ROUTER.md + router-scenarios.md | done |
| 3 | Protocol library (16 → canonical set) | done |
| 4 | Rules: agent-core, security, pet-care-architecture | done |
| 5 | Tier 1 skill Router preambles | done |
| 6 | phase-exit alignment + worker briefs | done |
| 7 | Tier 3 skill deprecation stubs | done |
| 8 | cursor-agent-framework.md | done |

## Router annotations (this plan)

```text
router_risk: R1 (governance)
protocols: [documentation, testing]
verification: [pre-push-changed.sh]
phase_fit: in-scope
```

## Next

Use this framework as orchestration layer for Pet Care hardening programme.
