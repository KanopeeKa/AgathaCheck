---
title: Pet Care engineering hardening programme
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-09-05
tags: [pet_care, security, engineering]
---

# Pet Care engineering hardening

Gold-standard security and mobile-readiness programme for the Pet Care domain.

| Doc | Role |
|-----|------|
| [hardening-discovery.md](../../domains/pet_care/changes/hardening-discovery.md) | Phase A inventory, findings table, recommended plan slices |
| [../domains/pet_care/README.md](../../domains/pet_care/README.md) | Product domain map |
| [../cursor-agent-framework.md](../cursor-agent-framework.md) | Agent orchestration (Router, execute-plan) |

## Programme plans (execute-plan)

| plan_id | Phase | Status |
|---------|-------|--------|
| `pet-care-hardening-discovery` | A — discovery only | merged (#994) |
| `pet-care-p0-private-files` | P0 — F-01 private health files | merged (#998) |
| `pet-care-p0-share-minimization` | P0 — F-03/F-04 share preview + expiry | merged (#1001) |
| `pet-care-auth-platform` | B — shared foundations (F-08) | merged (#1006) |
| `pet-care-capability-auth-rollout` | F-02 capability rollout | merged (#1009) |
| `pet-care-session-v2` | F-05–F-07 session v2 (refresh + web cookies) | merged (#1013, #1014) |

See discovery report §Recommended follow-on plans for the full slice list.
