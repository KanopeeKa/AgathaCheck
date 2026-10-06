---
title: Care Item context header (execute-plan)
owner: Agent
audience: agent
status: active
---

# Care Item context header — execute-plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-item-context-header-4011` |
| **title** | Care Item context strip and app bar title |
| **created** | 2026-10-06 |
| **base_branch** | `cursor/care-item-context-header-4011-integration-4011` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Implement [care-item-context-header-spec.md](../../docs/domains/pet_care/changes/care-item-context-header-spec.md) (v2.2 on `main`): generic app bar title, context strip with `CareItemPetContextTile`, status chips (Finished/Paused), shell title on all route states, tests and E2E alignment. One integration PR to `main` after phases complete.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-06T16:05:00Z |
| **approved_until** | 2026-10-08T16:05:00Z |
| **control_issue** | #1691 |
| **autonomy** | `active` |

**Grant:** User chat 2026-10-06 — merge spec #1689, create plan, `/execute-plan` on integration branch without stopping between phases.

## Phases

### Phase 1 — Context strip and screen integration

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-item-context-strip-4011` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/care_item/**
flutter_app/lib/l10n/**
flutter_app/test/features/care_item/**
```

**forbidden_paths:** `server/**`

**Scope:**

- `careItemScreenTitle`, `careItemStatusFinished` EN/FR
- `CareItemPetContextTile`, `CareItemContextStrip`
- Wire `CareItemDetailScreen` / `CareItemDetailBody`; AC-1–AC-23 per spec

**Exit criteria:**

- [ ] All spec ACs covered by widget/screen tests
- [ ] `./scripts/pre-push-changed.sh` green

### Phase 2 — E2E semantics and doc pending cleanup

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-item-context-header-e2e-4011` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
e2e/playwright/pages/care-item.page.ts
e2e/playwright/tests/care.item*.spec.ts
docs/design/care-item-view-ui.md
docs/domains/pet_care/features/care-item-evolution.md
docs/domains/pet_care/changes/care-item-context-header-spec.md
```

**forbidden_paths:** `server/**`

**Scope:**

- Playwright audit per spec §9
- Remove "(pending implementation)" from canonical docs when behaviour ships

**Exit criteria:**

- [ ] Care item E2E paths stable
- [ ] Docs match shipped UI

## Integration → main

After phase 2 merged into integration: open PR integration → `main`, run **/babysit-uat**.

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 2
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/plan-runtime-care-item-4011
  plan_path: .agents/plans/care-item-context-header-4011.md
  plan_commit: 0b17269124bc40046914d24d93b7de634c598686
  snapshot_path: .agents/plans/care-item-context-header-4011.snapshot.json
  snapshot_commit: 0b17269124bc40046914d24d93b7de634c598686
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
