---
title: Pet detail UX and canonical back navigation
owner: Experience Program Team
audience: agent
status: active
last_updated: 2026-09-02
tags: [execute-plan, pet-profile, navigation, ux]
---

# Pet detail UX and canonical back navigation

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-detail-ux-c2ce` |
| **title** | Pet detail UX + canonical shell back navigation |
| **author** | cloud-agent |
| **created** | 2026-09-02 |
| **base_branch** | `cursor/pet-detail-ux-c2ce-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver pet-detail screen UX fixes (care preview parity, photo accent removal, overflow actions) and a canonical, documented `returnTo` back-navigation pattern enforced across guardian shell screens, with unit and E2E journey coverage and balanced Playwright shards.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-02T11:02:00Z |
| **approved_until** | 2026-09-04T11:02:00Z |
| **control_issue** | TBD |
| **autonomy** | `active` |

**Grant:** User chat 2026-09-02 — `/execute-plan` with standing grant for full scope.

## Phases

### Phase 1 — Canonical back navigation foundation

**Scope:**

- Generalize `returnTo` parsing/handling (reuse org profile pattern) for all shell screens
- Wire `ExperienceShellScaffold` to read `returnTo` from route query when `backPath` not set
- Update pet detail entry points to pass `returnTo` or use `push`
- Document pattern in `docs/design/system.md` and architecture index
- Unit/widget tests for back navigation matrix

**Exit criteria:**

- [ ] Shared `shell_return_navigation.dart` utility with tests
- [ ] Pet detail back returns to dashboard, all pets, vets, notifications origins
- [ ] Documentation updated

### Phase 2 — Pet detail UX (care, photo, overflow menu)

**Scope:**

- Remove left accent border on profile photo
- Replace legacy due/overdue block with dashboard care preview (`Care for {name}`)
- Remove divider after health issues nav
- `ScreenOverflowActions` widget; pet detail Share + Export in overflow menu

**Exit criteria:**

- [ ] Pet detail matches dashboard care look/feel (filtered, optimistic)
- [ ] Overflow menu pattern reusable from shell
- [ ] Widget tests updated

### Phase 3 — E2E journeys and shard rebalance

**Scope:**

- Playwright journeys for pet back navigation origins
- Rebalance `e2e/scripts/shard-files.mjs` for domain/speed
- BDD mapping if new scenarios added

**Exit criteria:**

- [ ] E2E covers dashboard → pet → back and all-pets → pet → back
- [ ] Shard manifest rebalanced with comment rationale
- [ ] `./scripts/pre-push.sh` green locally

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/back-navigation-canonical-c2ce"
artifact_ref:
  branch: cursor/back-navigation-canonical-c2ce
  plan_path: .agents/plans/pet-detail-ux-c2ce.md
  plan_commit: e63aa9d506f76cc37aaf1d1d2f78385d0580883f
  snapshot_path: .agents/plans/pet-detail-ux-c2ce.snapshot.json
  snapshot_commit: e63aa9d506f76cc37aaf1d1d2f78385d0580883f
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
