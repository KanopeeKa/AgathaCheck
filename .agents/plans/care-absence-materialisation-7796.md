---
title: Care absence materialisation and occurrence review
owner: Agent
audience: both
status: active
---

# Care absence materialisation and occurrence review

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-absence-materialisation-7796` |
| **title** | Intent materialisation + absence occurrence review UX |
| **created** | 2026-09-28 |
| **base_branch** | `cursor/care-absence-materialisation-integration-7796` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Remove the estimated-date reschedule dead-end by adding **intent-based materialisation** (D-CSM-018), then deliver **occurrence-centric absence UX**: Keep with carer, Review date → skip/reschedule, auto-sync absence resolutions, proactive ensure for affected items, and E2E coverage.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-28T17:08:00Z |
| **approved_until** | 2026-09-30T17:08:00Z |
| **approved_by** | user chat 2026-09-28: execute-plan full agreement all phases |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Phases

See `care-absence-materialisation-7796.snapshot.json`.

## Runtime

```bash
node scripts/execute_plan_runtime.js gate care-absence-materialisation-7796
node scripts/execute_plan_runtime.js current-phase care-absence-materialisation-7796
```
