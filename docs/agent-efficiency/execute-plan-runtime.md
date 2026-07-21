# Execute-plan runtime (Phase C)

Control issue + plan artifact runtime for `/execute-plan` and `/babysit-plus`. The [execute-plan skill](../../.cursor/skills/execute-plan/SKILL.md) orchestrates these commands; agents call them directly during autonomous runs.

**Canonical policy:** [autonomous-pr-policy.md](./autonomous-pr-policy.md)  
**Snapshot schema:** [execute-plan-schema.md](./execute-plan-schema.md)  
**Labels:** [github-labels.md](./github-labels.md)

---

## Library

Shared logic lives in `scripts/lib/execute_plan_lib.js` (validation, drift classification, gate checks, runtime YAML sync). The validator re-exports this library:

```bash
node scripts/validate_execute_plan_snapshot.js .agents/plans/<plan_id>.snapshot.json
node scripts/validate_execute_plan_snapshot.js --drift-test
```

---

## CLI — `scripts/execute_plan_runtime.js`

### Autonomy gate (preflight)

Confirms snapshot `autonomy: active`, `approved_until` in the future, and control issue labels (`autonomous-approved`, not `autonomous-revoked`).

```bash
node scripts/execute_plan_runtime.js gate example-plan \
  --labels execute-plan,plan:example-plan,autonomous-approved
```

Exit `0` = proceed; exit `2` = halt (JSON reason on stdout).

### Resume check

Validates gate + PR `headRefOid` against recorded `pr_head_sha` (override with human `accept-head` on control issue).

```bash
node scripts/execute_plan_runtime.js resume-check example-plan \
  --phase 1 --pr-head <sha> --labels autonomous-approved
```

### Control issue bootstrap

Renders title, body, labels, and suggested `gh issue create` command:

```bash
node scripts/execute_plan_runtime.js init-control-issue <plan_id>
node scripts/execute_plan_runtime.js render-control-issue <plan_id>
node scripts/execute_plan_runtime.js render-control-issue <plan_id> --title
```

After creating the issue, set `control_issue` in the snapshot JSON and re-run validation.

### Halt (graceful shutdown)

Updates snapshot + live plan runtime block; prints markdown comment for control issue (agent posts via `gh`).

```bash
node scripts/execute_plan_runtime.js halt <plan_id> \
  --reason session_limit --detail "checkpoint" --write
```

`--autonomy` defaults to `halted`; use `revoked` when `autonomous-revoked` label applied.

### Pause (UAT remedial — keeps autonomy active)

Pauses the in-progress phase without setting snapshot `autonomy` to `halted`. Used by the UAT babysit sub-agent when prod-ready fails.

```bash
node scripts/execute_plan_runtime.js pause <plan_id> \
  --reason uat_paused --detail "prod-ready: smoke shard 3 failed" --write
```

### Resume UAT (auto-resume — no human `resume-plan`)

Clears `uat_paused` on the halted phase and restores `in_progress`. Sub-agent calls this when remedial prod-ready is green.

```bash
node scripts/execute_plan_runtime.js resume-uat <plan_id> --write
```

Prints JSON (`next_action`, phase) plus a resume comment for the control issue. Main agent continues via `/execute-plan <plan_id> resume` without manual intervention.

### Phase status + artifact sync

```bash
node scripts/execute_plan_runtime.js set-phase <plan_id> \
  --phase 1 --status in_progress --pr-url <url> --pr-head <sha> --write

node scripts/execute_plan_runtime.js sync-runtime <plan_id> --write
node scripts/execute_plan_runtime.js current-phase <plan_id>
```

`sync-runtime` writes the `## Runtime state` YAML block in `.agents/plans/<plan_id>.md` including `artifact_ref` (branch + commit SHAs from current git context).

---

## Agent workflow (summary)

1. Human approves → freeze snapshot → `init-control-issue` → create GitHub issue → set `control_issue` number
2. Each session: `gate` → `current-phase` → work on phase branch
3. On push: `set-phase` + `sync-runtime --write`
4. On revoke/expiry/escalation: `halt --write` + add `autonomous-revoked` label (halt only — do not close PRs)
5. Resume: remove revoke label → `resume-check` → continue from `next_action`

Full halt/resume semantics: [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Halt and resume.

---

## Tests

```bash
node --test scripts/execute_plan_runtime.test.js
```

Wired into `./scripts/pre-push-changed.sh` and `./scripts/pre-push.sh` governance gates.
