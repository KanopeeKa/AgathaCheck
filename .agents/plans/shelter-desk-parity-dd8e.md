---
title: Shelter desk parity (visual + compliance)
plan_id: shelter-desk-parity-dd8e
---

# Shelter desk parity — execute plan

## Goal

Bring the Shelter workspace to visual and interaction parity with the Care operations-desk **patterns** (section chrome, tile geometry, touch targets, workspace toggle compliance) while keeping the **Shelter teal palette** (`organizationLight` `#EAF5F5`, `organizationPrimary` `#1D7C84`) and locked IA (hub + profile nav rows — no Care-style primary nav). Completes outstanding v3 tile debt and D-v5-WORKSPACE-4 gaps on org deep routes.

**Non-goals:** Shelter bottom/rail primary nav (blocked by D-v4-2); Care plum palette; workspace-level operational previews on `/o/orgs`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-03 (/execute-plan shelter desk parity phases, teal palette) |
| **approved_until** | 2026-09-05T19:48:00Z |
| **base_branch** | `cursor/shelter-desk-parity-dd8e-integration-dd8e` |

## Phases

### Phase 0 — Shelter desk framing decisions

Docs: `docs/domains/shelter/changes/shelter-desk-framing-decisions.md` — D-desk-S1..S4; tokens note for teal canvas.

### Phase 1 — Workspace toggle on org deep shell

`OrgShellScaffold` exposes `ExperienceWorkspaceToggle` on every `/o/orgs/:id/*` route (D-v5-WORKSPACE-4).

### Phase 2 — Org pets grid touch targets

Remove compact transfer `TextButton`s under pet tiles; move admin actions to app bar overflow / pet detail.

### Phase 3 — Shelter hub compact teal chrome

`/o/orgs` compact app bar uses `organizationPrimary` + inverse foreground (mirror Care plum pattern, teal tokens).

### Phase 4 — Org membership pet-grid tiles

`OrgMembershipTile` replaces list-row `OrgCard` on hub (D-v3-TILE-1); solid teal hero fallback.

### Phase 5 — Hub section chrome on teal canvas

Eyebrow headers + subtitle on `organizationLight`; remove filled `primaryContainer` hero pattern.

### Phase 6 — Dead legacy cleanup

Remove `OrganizationDashboardScreen`, `OrgShellHomeContent`, `OrgHomeScreen` if unused.

### Phase 7 — Tests and navigation contract

Widget tests + `docs/e2e/navigation-contract.md` shelter hub notes.

## Runtime state

```yaml
autonomy: active
current_phase: 0
last_completed_phase: null
halt_reason: null
next_action: "continue phase 0 on branch cursor/shelter-desk-framing-decisions-dd8e"
artifact_ref:
  branch: cursor/shelter-desk-framing-decisions-dd8e
  plan_path: .agents/plans/shelter-desk-parity-dd8e.md
  plan_commit: 8f4dcaeb46b4223ea229053b9db08c817915f21c
  snapshot_path: .agents/plans/shelter-desk-parity-dd8e.snapshot.json
  snapshot_commit: 8f4dcaeb46b4223ea229053b9db08c817915f21c
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/943"]
merge_commits: {}
debt_issue_refs: []
```

| Phase | Status | Branch |
|-------|--------|--------|
| 0 | pending | cursor/shelter-desk-framing-decisions-dd8e |
| 1 | pending | cursor/shelter-org-shell-toggle-dd8e |
| 2 | pending | cursor/shelter-org-pets-touch-dd8e |
| 3 | pending | cursor/shelter-hub-teal-chrome-dd8e |
| 4 | pending | cursor/shelter-membership-tiles-dd8e |
| 5 | pending | cursor/shelter-hub-section-chrome-dd8e |
| 6 | pending | cursor/shelter-dead-code-cleanup-dd8e |
| 7 | pending | cursor/shelter-desk-tests-dd8e |
