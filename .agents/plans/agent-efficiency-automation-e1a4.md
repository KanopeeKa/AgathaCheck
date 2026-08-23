# Agent efficiency automation + BDD easy wins

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `agent-efficiency-automation-e1a4` |
| **title** | Automate forgotten agent hygiene + close easy BDD/E2E gaps |
| **author** | Cloud agent |
| **created** | 2026-08-20 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Reduce manual Cursor hygiene (UI checks, review-bugbot, babysit model reminders) by embedding reminders in high-traffic skills and `pre-push-changed.sh`. Close zero-risk BDD drift and authentication validation E2E gaps. Leave the large BDD backlog (70+ scenarios) to a parallel spawn sprint in phase 3.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | _(pending — comment `approve-autonomous agent-efficiency-automation-e1a4` on control issue)_ |
| **approved_until** | `approved_at + 48h` |
| **control_issue** | _(run `node scripts/execute_plan_runtime.js init-control-issue agent-efficiency-automation-e1a4`)_ |
| **autonomy** | `halted` |

**Grant keyword:** `approve-autonomous agent-efficiency-automation-e1a4`

## Phases

### Phase 1 — Agent efficiency hooks

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/agent-efficiency-automation-e1a4` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
.cursor/commands/**
.cursor/skills/**
.agents/memory/MEMORY.md
scripts/check_ui_touch_reminder.sh
scripts/pre-push-changed.sh
docs/agent-efficiency/**
```

**Exit criteria:**

- [ ] `/review-bugbot` command exists
- [ ] `check_ui_touch_reminder.sh` wired into pre-push-changed
- [ ] `/ui-check` embedded in pre-push-verify, babysit+, split-flutter-screen, route-change, add-bdd skills
- [ ] Removed stale `uat-coordinator` skill; MEMORY lists babysit+/uat skills
- [ ] `./scripts/pre-push-changed.sh` green

### Phase 2 — BDD drift + auth validation E2E

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/agent-efficiency-automation-e1a4` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
e2e/playwright/tests/auth.login.spec.ts
e2e/playwright/tests/notifications.spec.ts
e2e/playwright/pages/landing.page.ts
flutter_app/web/index.html
flutter_app/lib/core/web/**
flutter_app/lib/features/auth/presentation/widgets/landing/**
scripts/bdd-priority-tag-map.json
```

**Exit criteria:**

- [ ] Notifications `@bdd` title matches Gherkin (no drift)
- [ ] Six auth login BDD scenarios mapped (validation, visibility, tab navigation)
- [ ] Native login shows localized required-field messages on web
- [ ] `node e2e/scripts/check_bdd_coverage.js` passes (≥ gate)
- [ ] `./scripts/pre-push-changed.sh` green

### Phase 3 — Parallel BDD backlog sprint

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/sprint-bdd-backlog-integration-e1a4` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `true` |

**spawn_config:** invoke `/spawn-sprint-agents` with integration branch `cursor/sprint-bdd-backlog-integration-e1a4`. Foundation agent merges `e2e/playwright/support/api.ts` helpers first; parallel agents own disjoint feature spec files per `docs/agent-efficiency/prompt-templates.md` §Parallel E2E agent.

**allowed_paths:**

```
e2e/**
flutter_app/test/bdd/**
docs/quality/bdd-journey-matrix.md
docs/debt/refactoring-log.md
```

**Exit criteria:**

- [ ] BDD mapped scenarios ≥ 85% (target; adjust if totals drift)
- [ ] `./scripts/pre-push.sh` green on integration → `main` PR

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 3
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/agent-efficiency-automation-e1a4.md
  plan_commit: 9bff48890e915ab660a9427523ce4ead6d289c7a
  snapshot_path: .agents/plans/agent-efficiency-automation-e1a4.snapshot.json
  snapshot_commit: 9bff48890e915ab660a9427523ce4ead6d289c7a
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Notes for operator

- **UI check automation:** agents cannot run `/ui-check` without you invoking it — we automate **reminders** in pre-push and skills instead.
- **Execute-plan automation:** after control issue + `approve-autonomous`, run `/execute-plan agent-efficiency-automation-e1a4` — no manual paste per phase.
- **Issue dispatch:** optional; you said manual paste is not your workflow — execute-plan + cloud agents is the primary path.
