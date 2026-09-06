---
title: Pet Care weight input validation (F-13)
owner: Agent
audience: agent
status: active
---

# pet-care-weight-validation

## Goal

Reject invalid weight values on create/update (F-13): missing, NaN, non-positive — no silent `parseFloat(missing) → 0`.

## Autonomy

Standing grant: Pet Care hardening roadmap (user chat 2026-09-05).

| Field | Value |
|-------|-------|
| **control_issue** | #1028 |
| **approved_until** | 2026-09-08T15:15:00Z |

## Runtime

```yaml
plan_id: pet-care-weight-validation
autonomy: active
current_phase: 1
next_action: implement on cursor/pet-care-weight-validation-75cb
```

## Phase 1 — Weight validation (F-13)

**Branch:** `cursor/pet-care-weight-validation-75cb`
