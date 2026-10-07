---
title: Health tracking specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-07
tags: [domain,health_tracking,specs]
domain: health_tracking
---

# Health tracking specs

## Care scheduling and completion

**Canonical:** [Care Schedule Management](/docs/domains/pet_care/features/care-schedule-management.md) owns occurrence timing, commands, and history reads (D-CSM-019 … D-CSM-035).

**Care Item UX** (status words, agenda, completion flows): [care-item-evolution.md](/docs/domains/pet_care/features/care-item-evolution.md) (D-CIE-024 … D-CIE-034).

### Retired (pre-occurrence model)

| Topic | Status |
|-------|--------|
| Entry-level `mark-taken` advancing `nextDueDate` without occurrences | **Retired** — use occurrence `complete` APIs |
| `health_history` as authoritative complete/skip log | **Retired** (D-CSM-003, D-CSM-035) |
| `GET /:id/history` reading `health_history` only | **Retired** — closed occurrences (D-CSM-035) |
| Three-date model lesson in `.agents/memory/health-entry-completion.md` | **Retired** — rules moved to CSM canonical doc |

## Health issues

Managed via `server/routes/healthIssues.js` with separate CRUD from entries.

## Org family events alignment

Org family events use `from_date` = due, `to_date` = completed on; `family_event_history` stores the three-date audit trail (see fostering/organization domains).
