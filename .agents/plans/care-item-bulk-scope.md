---
title: Care Item bulk scope UI
owner: Agent
audience: agent
status: active
last_updated: 2026-10-05
tags: [execute-plan, pet-care, care-item, flutter]
---

# Plan — `care-item-bulk-scope`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-item-bulk-scope` |
| **title** | Care Item bulk actions show scope and count |
| **created** | 2026-10-05 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **spec** | `docs/domains/pet_care/changes/care-item-bulk-scope-spec.md` |

## Goal

One atomic PR: Care Item bulk actions act on exactly the rows above them and show the count (FR-1–FR-26, §10 docs, §7.G tests). Flutter only; no server change.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | User chat 2026-10-05 — `/execute-plan` after handoff |
| **control_issue** | (see snapshot) |
| **Grant** | `approve-autonomous care-item-bulk-scope` on control issue |

## Phases

### Phase 1 — Scoped bulk UI

**branch:** `cursor/care-item-bulk-scope-0f49`

**Scope:** Domain partition; extract row/bulk/upcoming widgets; `CareMarkDoneButton` round + `CareSkipButton`; l10n; stack snackbar counts; app-bar Plan another date; bug spec + terminology §10; widget/unit/BDD/E2E page object updates.

**Exit:** Spec AC groups A–F covered by tests; pre-push-changed green; PR merged to `main` with babysit-uat.

## Follow-ups (debt, out of scope)

- `CareItemDatesSection` count labels (§11)
- Selection mode checkboxes (§11)

## Runtime

```bash
node scripts/execute_plan_runtime.js gate care-item-bulk-scope
node scripts/execute_plan_runtime.js current-phase care-item-bulk-scope
```

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "implement phase 1 on cursor/care-item-bulk-scope-0f49"
artifact_ref:
  branch: cursor/care-item-bulk-scope-0f49
  plan_path: .agents/plans/care-item-bulk-scope.md
  snapshot_path: .agents/plans/care-item-bulk-scope.snapshot.json
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
