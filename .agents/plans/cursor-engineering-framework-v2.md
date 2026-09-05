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

## Completion

| Field | Value |
|-------|-------|
| **PR** | [#988](https://github.com/KanopeeKa/AgathaCheck/pull/988) |
| **merge_commit** | `a443ff249dcf37813911a65d1218fa547f5fbd93` |
| **completed** | 2026-09-05 |
| **autonomy** | `completed` |

Copilot review (5 threads): canonical protocol paths under `.cursor/agent-kernel/protocols/` — fixed before merge.

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/cursor-engineering-framework-v2.md
  plan_commit: 6352a712627b0af76507a7a038b3c6e61bf6ddec
  snapshot_path: .agents/plans/cursor-engineering-framework-v2.snapshot.json
  snapshot_commit: 6352a712627b0af76507a7a038b3c6e61bf6ddec
open_prs: []
merge_commits: {"1":"a443ff249dcf37813911a65d1218fa547f5fbd93"}
debt_issue_refs: []
```

## Next

Use this framework as orchestration layer for Pet Care hardening programme. Start plans with `/execute-plan <plan_id>` — Router runs automatically.
