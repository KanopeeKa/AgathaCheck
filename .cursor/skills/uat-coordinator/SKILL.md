---
name: uat-coordinator
description: >-
  REMOVED (Jul 2026) — UAT coordinator dispatch and queue health workflows deleted.
  CI owns promotion (pre-uat-e2e → promote-uat → deploy-uat). Manual recovery only.
---

# UAT coordinator (removed)

**Removed:** `uat-coordinator-dispatch.yml`, `uat-queue-health.yml`, queue ledger promote hold.

**Current path:** [uat-deploy-tiers.md](../../../docs/e2e/uat-deploy-tiers.md) — merge to `main`
triggers Pre-UAT E2E; green at HEAD auto-promotes.

**Manual recovery:** [uat-promote-manual.md](../../../docs/e2e/uat-promote-manual.md) · ops localhost replay via `scripts/agent-uat-babysit.sh`.

Historical plan: `docs/agent-efficiency/uat-coordinator-plan.md` (archived).
