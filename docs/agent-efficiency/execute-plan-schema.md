# Execute-plan snapshot schema (canonical)

**Schema version:** 1  
**Status:** Phase A foundation — skills (`execute-plan`, `babysit-plus-plus`) must import from this document, not redefine policy in prose.

Companion docs:

- Human plan template: [plan-template.md](./plan-template.md)
- Exit checklist profiles: [phase-exit-checklists.md](./phase-exit-checklists.md)
- Cross-cutting PR autonomy policy: [autonomous-pr-policy.md](./autonomous-pr-policy.md)
- GitHub labels: [github-labels.md](./github-labels.md)

---

## Overview

An autonomous multi-phase run is driven by:

1. **Live plan** — `.agents/plans/<plan_id>.md` (human-readable, updated during run)
2. **Frozen snapshot** — `.agents/plans/<plan_id>.snapshot.json` (immutable after upfront approval)
3. **Control issue** — GitHub issue with autonomy labels (revoke / resume)

**Approval expiry:** `approved_until` is **mandatory**. Default: `approved_at + 48 hours`. Runs past expiry halt as `status: halted`, `status_reason: revoked`. If work routinely exceeds 48h, split the plan or re-approve after reviewing size, duplication, and blockers.

**Artifact location:** `artifact_branch_policy: phase-branch` (default). Plan files commit on the active phase branch; the control issue is the human index.

---

## Top-level snapshot fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | integer | yes | Currently `1` |
| `plan_id` | string | yes | Kebab-case identifier; matches filename |
| `approved_at` | ISO-8601 UTC | yes | Autonomy grant timestamp |
| `approved_by` | string | yes | User or agent principal |
| `approved_until` | ISO-8601 UTC | yes | **Mandatory.** Default `approved_at + 48h` |
| `content_hash` | string | yes | `sha256:` of canonical JSON (excluding this field) |
| `autonomy` | enum | yes | `active` \| `completed` \| `halted` \| `revoked` |
| `default_merge_mode` | enum | yes | `manual` \| `labeled` \| `auto` |
| `base_branch` | string | yes | Usually `main` or integration parent |
| `control_issue` | integer | yes | GitHub issue number |
| `artifact_branch_policy` | enum | yes | `phase-branch` (default) \| `main` |
| `phases` | array | yes | Ordered phase objects (see below) |

### `artifact_branch_policy`

| Value | Behavior |
|-------|----------|
| `phase-branch` | **Default.** `.agents/plans/<id>.*` commits on active phase branch. Control issue holds summary + `artifact_ref`. |
| `main` | After each phase merge, update plan on `main` via PR. Resume reads `origin/main`. |

### `artifact_ref` (on halt / resume)

Written to live plan markdown and control issue comment:

```yaml
artifact_ref:
  branch: cursor/example-phase-a-aec1
  plan_path: .agents/plans/example-plan.md
  plan_commit: abc1234
  snapshot_path: .agents/plans/example-plan.snapshot.json
  snapshot_commit: def5678
```

---

## Phase object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Phase id (e.g. `"1"`, `"2"`) |
| `title` | string | yes | Short description |
| `branch` | string | yes | Feature branch name |
| `allowed_paths` | string[] | yes | Glob patterns (repo-relative) |
| `forbidden_paths` | string[] | yes | Glob patterns — match → drift |
| `allowed_exceptions` | enum[] | yes | Closed list — see below |
| `spawn_allowed` | boolean | yes | If true, may invoke `/spawn-sprint-agents` |
| `spawn_config` | object \| null | if spawn | Integration branch, ownership map ref |
| `merge_mode` | enum | no | Overrides `default_merge_mode` |
| `merge_method` | enum | no | `squash` \| `merge` \| `rebase` — default `squash` |
| `exit_checklist` | string | yes | Profile name from phase-exit-checklists.md |
| `status` | enum | yes | See status model |
| `status_reason` | enum \| null | conditional | Required when `status` is `halted` or `blocked` |
| `status_detail` | string \| null | no | Human-readable detail |
| `pr_url` | string \| null | no | GitHub PR URL |
| `pr_head_sha` | string \| null | no | Updated on every push; revalidated on resume |
| `merge_commit` | string \| null | no | OID after merge |
| `debt_issue_refs` | integer[] | no | GitHub issue numbers for deferred work |
| `exception_files` | object[] | no | Audit trail for out-of-path files |

### `allowed_exceptions` (closed enum)

Every file **outside** `allowed_paths` must map to exactly one code at drift-check time:

| Code | Allows |
|------|--------|
| `tests` | Tests/fixtures for touched production code |
| `docs` | Docs required by exit checklist profile |
| `dual-backend-mirror` | Paired Node/Dart route files per dual-backend rules |
| `file-split` | New files from splitting an allowed-path file |
| `governance-allowlist` | e.g. `scripts/file-size-allowlist.json` when phase permits |
| `spawn-integration` | Files on integration branch per ownership map |

Unclassified out-of-path file → `status: blocked`, `status_reason: drift`.

### `spawn_config` (when `spawn_allowed: true`)

```json
{
  "integration_branch": "cursor/sprint-12-example-integration-aec1",
  "ownership_ref": "docs/refactoring-log.md#sprint-12-example"
}
```

---

## Status model

**`status`** (exactly one):

| Value | Meaning |
|-------|---------|
| `pending` | Not started |
| `in_progress` | Branch / PR work active |
| `merged` | Phase PR merged; `merge_commit` set |
| `halted` | Intentionally stopped (revoke, session limit, pause) |
| `blocked` | Cannot proceed without human intervention |

**`status_reason`** (required when `status` is `halted` or `blocked`):

| Value | `status` | Meaning |
|-------|----------|---------|
| `revoked` | `halted` | Control issue `autonomous-revoked` or past `approved_until` |
| `session_limit` | `halted` | Agent checkpoint before timeout |
| `human_pause` | `halted` | Explicit pause without revoke |
| `drift` | `blocked` | Path / scope violation |
| `ci_exhausted` | `blocked` | CI retry budget spent |
| `merge_failed` | `blocked` | Merge blocked or PR closed unmerged |
| `escalation` | `blocked` | Security / API / migration / product decision |
| `issue_create_failed` | `blocked` | Debt issue create/update failed |
| `resume_mismatch` | `blocked` | PR `headRefOid` ≠ recorded `pr_head_sha` |

---

## Drift detection algorithm (canonical)

Run at each commit and before babysit++ merge step.

```
FOR each file F in git diff(base..HEAD):
  IF F matches any phase.allowed_paths glob → continue
  IF F matches any phase.forbidden_paths glob → DRIFT(forbidden)
  IF F maps to exactly one phase.allowed_exceptions code → continue (score 0)
  ELSE → DRIFT(unclassified)

FOR each commit C on phase branch:
  IF C.message lacks /^phase\(\d+\/\d+\):/ → DRIFT(commit_convention)

IF work is not mapped to current phase.id → DRIFT(scope_creep)
```

**Hard stop:** any DRIFT → `status: blocked`, `status_reason: drift`, graceful halt.

**Commit message convention:**

```
phase(<id>/<total>): <type>: <description> [exception:<code>]
```

Example: `phase(2/3): test: FosterCard widget tests [exception:tests]`

**Optional audit:** append to `phase.exception_files`:

```json
{
  "path": "flutter_app/test/features/foster/foster_card_test.dart",
  "code": "tests",
  "phase_id": "2"
}
```

---

## Merge mode precedence

See [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Merge modes. Summary:

1. `do-not-merge` label → never merge
2. `autonomous-revoked` on control issue → never merge
3. PR is `draft` → never merge
4. Phase `merge_mode` from frozen snapshot
5. Else `default_merge_mode`
6. `agent-merge-ok` label required only when effective mode is `labeled`

Snapshot wins over PR labels when they disagree (e.g. `manual` + `agent-merge-ok` → do not merge).

---

## Merge completion detection

```bash
gh pr view <url> --json state,mergedAt,mergeCommit,baseRefName,headRefOid
```

Require `state == "MERGED"`, `mergedAt` set, `mergeCommit.oid` present.

Before next phase:

```bash
git fetch origin <base_branch>
git merge-base --is-ancestor <mergeCommit.oid> origin/<base_branch>
```

---

## Resume invariants

1. Read frozen snapshot from `artifact_ref.snapshot_commit`
2. Control issue must not have `autonomous-revoked`; `approved_until` must not be past
3. `gh pr view` → `headRefOid` must equal `phase.pr_head_sha` unless human commented `accept-head` on control issue
4. Same `content_hash` — plan changes require new approval + new snapshot
5. Continue from `next_action` in live plan; do not redo `merged` phases

---

## Validation

```bash
node scripts/validate_execute_plan_snapshot.js .agents/plans/_example.snapshot.json
node scripts/validate_execute_plan_snapshot.js --drift-test
```

---

## JSON Schema (draft)

Full machine schema: [execute-plan-snapshot.schema.json](./execute-plan-snapshot.schema.json)
