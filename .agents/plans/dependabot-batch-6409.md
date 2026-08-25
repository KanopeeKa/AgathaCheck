# Dependabot batch — plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `dependabot-batch-6409` |
| **title** | Dependabot batch skill + Aug 2025 weekly deps |
| **created** | 2026-08-25 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Add `/dependabot-batch` skill and land this week's mergeable Dependabot bumps (#746 uuid, #747/#749 RevenueCat pair) in one batch PR with preventive E2E. Drop #748 (`intl` SDK conflict) and add dependabot ignore.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-25T09:00:00Z |
| **approved_until** | 2026-08-27T09:00:00Z |
| **approved_by** | user chat — create skill + apply batch via /execute-plan |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Phases

### Phase 1 — Skill + intl ignore

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/dependabot-batch-skill-6409` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.cursor/skills/dependabot-batch/**
.cursor/rules/agent-core.mdc
.github/dependabot.yml
.agents/plans/dependabot-batch-6409.*
```

**Scope:**

- Add `/dependabot-batch` skill
- Ignore `intl` in dependabot (SDK-pinned)
- Register skill in agent-core

**Exit criteria:**

- [ ] Skill validates (`check_skill_frontmatter.js`)
- [ ] `dependabot.yml` ignores `intl`
- [ ] PR merged to `main`

### Phase 2 — Weekly deps batch

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/deps-batch-2026-08-25-6409` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/pubspec.yaml
flutter_app/pubspec.lock
server/package.json
server/package-lock.json
```

**Scope:**

- Batch #746, #747, #749 into one branch
- Close #748 with comment (if not already)
- Preventive 13-shard E2E before merge
- `/babysit-uat` merge + pre-UAT green
- Close superseded Dependabot PRs

**Exit criteria:**

- [ ] Batch PR merged to `main`
- [ ] Pre-UAT E2E green for merge SHA
- [ ] #746, #747, #749 closed as superseded

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/deps-batch-2026-08-25-6409"
artifact_ref:
  branch: cursor/deps-batch-2026-08-25-6409
  plan_path: .agents/plans/dependabot-batch-6409.md
  plan_commit: feead2820227b686b1fe9a134eda1cdf479b9166
  snapshot_path: .agents/plans/dependabot-batch-6409.snapshot.json
  snapshot_commit: feead2820227b686b1fe9a134eda1cdf479b9166
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/752"]
merge_commits: {"1":"a8a916821523473aa9c17fc889f88324d7c50fce"}
debt_issue_refs: []
```
