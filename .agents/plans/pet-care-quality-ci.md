---
title: Pet Care quality & CI foundations (F-17–F-20)
owner: Agent
audience: agent
status: active
---

# pet-care-quality-ci

## Goal

Raise Pet Care backend quality gates: weight-entry audit events (F-18), Jest coverage thresholds on policy modules (F-19), ESLint ratchet via pre-push governance (F-20), and PostgreSQL integration tests for pet access (F-17) without new GitHub workflow files (debt issue for CI job wiring).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T13:50:00Z |
| **approved_until** | 2026-09-08T13:50:00Z |
| **control_issue** | #1024 |
| **autonomy** | active |

Standing grant: Pet Care hardening roadmap (user chat 2026-09-05).

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-care-quality-ci-75cb"
artifact_ref:
  branch: cursor/pet-care-quality-ci-75cb
  plan_path: .agents/plans/pet-care-quality-ci.md
  plan_commit: e48706172c5bb9f6dc8ae0a08a405c55f55dfcce
  snapshot_path: .agents/plans/pet-care-quality-ci.snapshot.json
  snapshot_commit: e48706172c5bb9f6dc8ae0a08a405c55f55dfcce
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phase 1 — Weight audit + coverage thresholds + ESLint governance (F-18–F-20)

- Add `logAuditEventSafe` to weight entry mutations
- Jest `coverageThreshold` ratchet on `petAccess.js` / policy modules
- ESLint flat config for `server/` + `scripts/validate_eslint.js` in pre-push governance
- Debt issue: wire F-17 integration CI job + F-20 lint CI job (workflow escalation)

**Branch:** `cursor/pet-care-quality-ci-75cb`
