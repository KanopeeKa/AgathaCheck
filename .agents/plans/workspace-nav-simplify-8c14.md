---
title: Workspace navigation simplify
owner: Agent
audience: agent
status: active
---

# Workspace navigation simplify

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `workspace-nav-simplify-8c14` |
| **title** | Simplify workspace navigation — always Shelter, single login landing |
| **author** | cloud agent |
| **created** | 2026-09-03 |
| **base_branch** | `cursor/workspace-nav-simplify-8c14-integration-8c14` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Fix UAT navigation confusion for dual-role users: always show Shelter workspace, canonical `/o/orgs` root, everyone lands on `/pc/home` after login, global workspace switcher, warm fostering copy with new illustrations. Supersedes D-v3-VIS-1 org-section visibility toggle.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-03T10:50:00Z |
| **approved_until** | 2026-09-05T10:50:00Z |
| **control_issue** | #897 |
| **autonomy** | `active` |

**Grant:** user chat 2026-09-03 — Option A landing, `/execute-plan` with `/ui-design-deep`, full phased roadmap.

## Runtime state

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: implement phase 1
artifact_ref:
  branch: cursor/workspace-nav-always-shelter-8c14
  plan_path: .agents/plans/workspace-nav-simplify-8c14.md
  plan_commit: null
  snapshot_path: .agents/plans/workspace-nav-simplify-8c14.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Always-visible Shelter

Remove Account "Show shelters section" toggle, `OrganisationSectionVisibility` gating, and membership sync. Drawer, rail, sidebar, and shell always expose Shelter.

### Phase 2 — Route canon and fostering copy

Redirect `/o/home` → `/o/orgs`; org `homePath()` → `/o/orgs`. Move PR894 illustrations; update Care dashboard fostering section copy for no-shelter vs linked-shelter states.

### Phase 3 — Single login landing

`resolvePostLoginPath` always returns `/pc/home` (with onboarding rules); remove `last_app_section` restore; fix resolve double-navigation race.

### Phase 4 — Global workspace switcher

Show workspace toggle on every authenticated experience screen (compact app bar + leading-nav chrome), with back arrow on non-root routes.

### Phase 5 — Docs and E2E

Record D-v5-WORKSPACE-* decisions; supersede D-v3-VIS-1; update BDD/Playwright navigation contract. Final integration → `main` PR.

## Runtime state

| Phase | Status | PR |
|-------|--------|-----|
| 1 | pending | |
| 2 | pending | |
| 3 | pending | |
| 4 | pending | |
| 5 | pending | |
