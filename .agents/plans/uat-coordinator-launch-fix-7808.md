# UAT coordinator launch fix

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `uat-coordinator-launch-fix-7808` |
| **title** | Fix UAT coordinator agent launch (require side-effect) |
| **author** | cloud-agent |
| **created** | 2026-07-25 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Restore autonomous UAT coordinator dispatch after deploy failures. `launch-uat-coordinator.js` requires `launch-cursor-agent.js`, which unconditionally runs `main()` and crashes with `ISSUE_NUMBER` missing — coordinator agents have never launched.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-25T11:45:00Z |
| **approved_until** | 2026-07-27T11:45:00Z |
| **control_issue** | TBD |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous uat-coordinator-launch-fix-7808`

## Phases

### Phase 1 — Guard launch-cursor-agent main()

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/uat-coordinator-launch-guard-7808` |
| **merge_mode** | `auto` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.github/scripts/launch-cursor-agent.js
.github/scripts/launch-uat-coordinator.test.js
```

**forbidden_paths:**

```
flutter_app/**
server/**
```

**Scope:**

- Wrap `main()` in `if (require.main === module)` so `require('./launch-cursor-agent')` only exports `launchAgent`
- Add unit test: requiring module does not exit; `launchUatCoordinator` path can load

**Exit criteria:**

- [ ] `node --test .github/scripts/launch-uat-coordinator.test.js` passes
- [ ] `uat-coordinator-dispatch` can require launch chain without `ISSUE_NUMBER`

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/uat-coordinator-launch-guard-7808"
artifact_ref:
  branch: cursor/uat-coordinator-launch-guard-7808
  plan_path: .agents/plans/uat-coordinator-launch-fix-7808.md
  plan_commit: 016e469a9667ddae8685e6516a68ba90015c2b9f
  snapshot_path: .agents/plans/uat-coordinator-launch-fix-7808.snapshot.json
  snapshot_commit: 016e469a9667ddae8685e6516a68ba90015c2b9f
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/346"]
merge_commits: {}
debt_issue_refs: []
```
