# E2E debug skill

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `e2e-debug-skill-6bba` |
| **title** | Add /e2e-debug skill and align babysit-uat / execute-plan |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Encode pre-UAT remedial workflow as `/e2e-debug`: diff since last green pre-UAT, union failed + at-risk shards, parallel shard workers on one remedial branch, hand off to `/babysit-uat`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-23T14:37:00Z |
| **approved_by** | user chat — go for it /execute-plan |
| **approved_until** | 2026-08-25T14:37:00Z |
| **control_issue** | (set after bootstrap) |
| **autonomy** | `active` |

## Phases

### Phase 1 — Skill + scripts + alignment

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/e2e-debug-skill-6bba` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.cursor/skills/e2e-debug/**
.cursor/skills/babysit-uat/SKILL.md
.cursor/skills/execute-plan/SKILL.md
.cursor/skills/pre-push-verify/SKILL.md
.cursor/rules/agent-core.mdc
.agents/memory/MEMORY.md
.agents/plans/e2e-debug-skill-6bba.*
scripts/e2e_debug_resolve.mjs
scripts/e2e_debug_resolve.test.mjs
scripts/babysit_uat_shard_risk.mjs
scripts/pre-push-changed.sh
```

**Exit criteria:**

- [ ] `node --test scripts/e2e_debug_resolve.test.mjs` passes
- [ ] Skill frontmatter validates
- [ ] babysit-uat delegates remedial to e2e-debug
- [ ] execute-plan references e2e-debug on pre-UAT failure

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: implement phase 1 on cursor/e2e-debug-skill-6bba
```
