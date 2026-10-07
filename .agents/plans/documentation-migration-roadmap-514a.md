---
title: Documentation migration roadmap
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-07
---

# Documentation migration roadmap (`documentation-migration-roadmap-514a`)

**Goal:** Run canonical-docs consolidation per `docs/domains/documentation/changes/documentation-migration-handover.md` on integration branch `cursor/documentation-migration-integration-514a`, then one `/babysit-uat` merge to `main`.

**Programme ref:** `docs/domains/documentation/changes/documentation-migration-handover.md`

**Standing grant:** User chat 2026-10-07 — execute full migration plan via `/execute-plan`.

## Child plans (ordered)

| plan_id | Scope |
|---------|--------|
| `documentation-migration-gate-warn-514a` | Phase A: `DOCS_GATE_MODE=warn` on integration |
| `documentation-migration-csm-514a` | Wave 1.1: consolidate `pet_care/care-schedule-management` |
| `documentation-migration-care-item-514a` | Wave 1.2: consolidate `pet_care/care-item` |
| `documentation-migration-integration-harden-514a` | Phase B: restore `block` + fix stragglers on integration |
| `documentation-migration-integration-main-514a` | Integration → `main` via babysit-uat |

## Orchestrator phase

Single phase `orchestrate` on branch `cursor/documentation-migration-roadmap-bootstrap-514a` — plan artifacts only.

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: orchestrate
last_completed_phase: null
halt_reason: null
next_action: child documentation-migration-csm-514a in progress after gate-warn merged (#1768)
artifact_ref:
  branch: cursor/documentation-migration-roadmap-bootstrap-514a
  plan_path: .agents/plans/documentation-migration-roadmap-514a.md
  plan_commit: pending
  snapshot_path: .agents/plans/documentation-migration-roadmap-514a.snapshot.json
  snapshot_commit: pending
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
