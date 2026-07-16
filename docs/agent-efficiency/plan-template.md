# Plan template — execute-plan

Copy to `.agents/plans/<plan_id>.md` and fill in. Pair with `<plan_id>.snapshot.json` at approval time (see [execute-plan-schema.md](./execute-plan-schema.md)).

**Sizing:** Medium features only. If sanity check warns `proceed-high-risk` or work exceeds **48h** `approved_until`, split the plan or re-approve after reviewing scope, duplication, and blockers.

---

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `my-feature-plan` |
| **title** | Short human title |
| **author** | |
| **created** | YYYY-MM-DD |
| **base_branch** | `main` |
| **default_merge_mode** | `manual` \| `labeled` \| `auto` |
| **artifact_branch_policy** | `phase-branch` (default) |

---

## Goal

One paragraph: what this plan achieves and why it is split into phases.

---

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | |
| **approved_until** | `approved_at + 48h` (mandatory) |
| **control_issue** | # |
| **content_hash** | `sha256:…` from snapshot |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous <plan_id>`

---

## Phases

Repeat for each phase. IDs must match snapshot JSON.

### Phase 1 — `<title>`

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/<descriptive-name>-aec1` |
| **merge_mode** | (optional override) |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` \| see [phase-exit-checklists.md](./phase-exit-checklists.md) |

**allowed_paths:**

```
flutter_app/lib/features/example/**
flutter_app/test/features/example/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:**

- Bullet list of concrete deliverables

**Exit criteria:**

- [ ] Measurable outcome 1
- [ ] Measurable outcome 2

---

### Phase 2 — `<title>`

(duplicate phase section)

---

## Spawn phase (optional)

If a phase uses parallel agents:

| Field | Value |
|-------|-------|
| **spawn_allowed** | `true` |
| **integration_branch** | `cursor/sprint-N-topic-integration-aec1` |
| **ownership_ref** | `docs/refactoring-log.md#sprint-N` |

Publish ownership map **before** spawning. See `/spawn-sprint-agents`.

---

## Runtime state (agent-updated)

Do not edit manually during a run except on resume after halt.

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: null
artifact_ref:
  branch: null
  plan_path: .agents/plans/<plan_id>.md
  plan_commit: null
  snapshot_path: .agents/plans/<plan_id>.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

---

## Sanity check expectations

Agent evaluates before autonomy grant:

- Every phase has `allowed_paths`, `forbidden_paths`, `allowed_exceptions`, `exit_checklist`
- No overlapping `allowed_paths` across non-spawn phases
- Pessimistic scope estimate (domains × phases × CI factor)
- Migrations / auth / API breaks flagged

Output: `proceed` | `proceed-high-risk` | `reject`

---

## Revoke and resume

| Action | How |
|--------|-----|
| **Revoke** | Add `autonomous-revoked` on control issue; optional `do-not-merge` on open PRs. **Halt only** — do not close PRs. |
| **Resume** | Remove revoke label; comment `resume-plan <plan_id>`; invoke `/execute-plan <plan_id> resume` |

See [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Halt and resume.

---

## Checklist before `approve-autonomous`

- [ ] Snapshot JSON validates: `node scripts/validate_execute_plan_snapshot.js .agents/plans/<plan_id>.snapshot.json`
- [ ] Control issue created with labels `execute-plan`, `plan:<id>`, `autonomous-approved`
- [ ] Each phase merge_mode declared (or `default_merge_mode` set)
- [ ] Plan fits medium feature scope (< 48h expected)
