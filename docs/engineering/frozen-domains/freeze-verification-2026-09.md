---
title: Frozen domains freeze verification (2026-09)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-07
tags: [engineering, frozen-domains]
---

# Freeze verification — `frozen-domains-baseline-2026-09`

Verified at integration merge `7de3f488` (execute-plan `frozen-domains-freeze-ab54` phase 5).

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | No Shelter/Fostering reachable in MVP UI | Phase 3 pivot: 4-tab Pet Care nav, no workspace toggle, `/o/*` stubs redirect to `/pc/home` |
| 2 | No frozen HTTP endpoints in production/UAT | `ENABLE_FROZEN_DOMAINS` default `false`; org/foster routers unmounted in `server/bin/server.js` |
| 3 | Active code does not import frozen modules | `scripts/check_frozen_domain_boundaries.sh` in governance + pre-push |
| 4 | Frozen tests cannot fail active CI | No `flutter-test-org`; Jest `jest.config.active.cjs`; E2E frozen allowlist; BDD gate excludes frozen patterns |
| 5 | Frozen Dart excluded from analyze | `analysis_options.yaml` excludes `organization/` and `fostering_session/` |
| 6 | New Pet Care work has no Shelter/Fostering semantics obligation | D-MVP-* locked in `mvp-pivot-decisions.md`; foster UI removed |
| 7 | GDPR/delete/export for retained frozen data still works | Active Jest GDPR/auth suites; frozen org CRUD in `jest.config.frozen.cjs` manual only |

**Tag:** `frozen-domains-baseline-2026-09` on this integration line.

**Prior tag:** `pre-frozen-domains-pivot-2026-09` (phase 1 contract).
