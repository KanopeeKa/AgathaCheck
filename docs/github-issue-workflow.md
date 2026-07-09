# GitHub issue workflow

This document describes how issues are filed, triaged, and moved through delivery for Agatha Track.

## Issue forms

Issue intake uses GitHub Issue Forms in [`.github/ISSUE_TEMPLATE/`](../.github/ISSUE_TEMPLATE/). Blank issues are disabled; contributors must choose a form.

| Form | File | Purpose |
|------|------|---------|
| Bug | `bug.yml` | Report incorrect or broken behavior with reproduction steps and environment details. |
| Feature | `feature.yml` | Request a new capability or enhancement with problem statement and acceptance criteria. |
| Task | `task.yml` | Track internal engineering or maintenance work with scope and definition of done. |

New issues from these forms receive type labels (`bug`, `feature`, or `task`) and `needs-triage`.

**Legacy issues:** Issues created before these forms were introduced are not automatically normalized. They may need manual enrichment to match the fields expected by triage and future automation.

## Project status field

Use a single Project **Status** field with these values:

| Status | Meaning |
|--------|---------|
| **Backlog** | New or unreviewed issue. Default entry point. |
| **Human Reviewed** | A human has reviewed the issue and confirmed it is worth processing. |
| **Ready** | Passed the deterministic policy gate; eligible for implementation (including Cursor handoff). |
| **In Progress** | Work is actively underway. |
| **In Main** | Implementation merged to `main`. |
| **In UAT** | Change is deployed or being validated in UAT. |
| **Done** | Verified complete; issue can be closed. |

**Auto Check is not a status.** After an issue moves to **Human Reviewed**, an automated deterministic checker runs as a process step. It does not appear as a durable status value on the board.

## Labels

| Label | Meaning |
|-------|---------|
| `human-reviewed` | A maintainer has manually reviewed the issue. **Adding this label triggers the deterministic triage workflow.** |
| `question` | More information is needed at any point in the workflow. Add a comment explaining what is missing. |
| `busy` | A process or agent is currently working on this issue. Do not pick it up concurrently. Remove when work stops or ownership transfers. |
| `manual-only` | Never send this issue to autonomous implementation. Requires human execution only. |
| `agent-approved` | The issue passed the deterministic policy gate and is eligible for Cursor. |
| `blocked` | Agent run started but could not finish; issue stays **In Progress** and needs human input. |

## Workflow

```
Backlog → Human Reviewed → [Auto Check] → Ready → In Progress → In Main → In UAT → Done
                                    ↓
                              question label (loop back when answered)
```

1. **Backlog** — New issues enter here after filing via a form.
2. **Human Reviewed** — A maintainer reviews the issue: confirms clarity, priority, and that it belongs in the backlog. Move the status to **Human Reviewed** and add the `human-reviewed` label.
3. **Auto Check** (process, not a status) — The [triage workflow](../.github/workflows/triage-human-reviewed.yml) runs when `human-reviewed` is applied:
   - If the issue is complete and safe → move to **Ready** and apply `agent-approved`.
   - If more information is needed → add `question`, comment on what is missing, and move the issue to **Backlog** until resolved.
   - If the issue must not be automated → add `manual-only` and leave status in **Human Reviewed**.
4. **Ready** — Issue is approved for implementation. The [agent dispatch workflow](../.github/workflows/agent-dispatch.yml) picks it up automatically when `agent-approved` is present and status is **Ready**.
5. **In Progress** — Cursor agent dispatched (`busy` added). Stays here while the PR is open. If blocked, add `blocked` + `question` but keep **In Progress**.
6. **In Main** — After the agent PR merges to `main` ([merge handler](../.github/workflows/issue-agent-pr-merge.yml)).
7. **In UAT** — After UAT deploy succeeds for the linked `release/uat-YYMMDD-issue-<N>` branch ([UAT tracker](../.github/workflows/uat-deploy-tracker.yml)).
8. **Done** — Validation complete; close the issue.

Throughout the workflow, use `busy` to signal active work and `question` when blocked on missing information.

To re-run triage after updating an issue, remove `question` and `blocked` (if present) and re-add `human-reviewed`.

`busy` is removed when the agent PR merges to `main`.

## Cursor agent execution layer

GitHub remains the source of truth. Cursor Cloud Agents are workers that implement `agent-approved` issues.

### Components

| File | Purpose |
|------|---------|
| [`.github/workflows/agent-dispatch.yml`](../.github/workflows/agent-dispatch.yml) | Find eligible issues and launch Cursor agents |
| [`.github/workflows/agent-monitor.yml`](../.github/workflows/agent-monitor.yml) | Poll agent runs; comment; apply `blocked` / success handoff |
| [`.github/workflows/issue-agent-pr-merge.yml`](../.github/workflows/issue-agent-pr-merge.yml) | On merged `cursor/**` PR → **In Main**, push UAT branch |
| [`.github/workflows/uat-deploy-tracker.yml`](../.github/workflows/uat-deploy-tracker.yml) | On UAT deploy result → **In UAT** or escalate |
| [`.github/workflows/agent-pr-safety-gate.yml`](../.github/workflows/agent-pr-safety-gate.yml) | Fail PRs that touch forbidden paths |
| [`.github/scripts/agent-payload-lib.js`](../.github/scripts/agent-payload-lib.js) | Sanitized task payload + prompt |
| [`.github/scripts/agent-safety-lib.js`](../.github/scripts/agent-safety-lib.js) | Preflight + forbidden path rules |
| [`.github/scripts/launch-cursor-agent.js`](../.github/scripts/launch-cursor-agent.js) | Calls Cursor Cloud Agents API v1 |
| [`.github/scripts/monitor-cursor-agent.js`](../.github/scripts/monitor-cursor-agent.js) | Polls run status via Cursor API |
| [`.github/scripts/issue-agent-handlers.js`](../.github/scripts/issue-agent-handlers.js) | Merge + UAT status transitions |

### Eligibility

An issue is dispatched when **all** are true:

- Project status **Ready** (when project secrets configured; otherwise label-only fallback)
- Labels: `agent-approved`
- Labels **not** present: `busy`, `manual-only`, `question`, `blocked`
- Passes deterministic preflight (re-checks risky scope)
- No active `<!-- cursor-agent-run: ... -->` marker with status `running`

Dispatch is **single-threaded** (`concurrency: agent-dispatch`) — one issue at a time.

Triggers:

- `agent-approved` label added (immediate, after triage)
- Cron every 30 minutes (reconciliation)
- Manual `workflow_dispatch` (optional `issue_number`, `dry_run`)

### Sanitized task payload

Raw issue comments are **never** sent to Cursor. The dispatch script:

1. Parses issue form sections via `triage-lib.js` (`### Heading` markdown).
2. Builds a structured JSON payload (summary, objective, scope, acceptance, reproduction for bugs).
3. Renders a prompt with explicit allowed/forbidden paths and verification commands.

The agent must run `./scripts/pre-push-changed.sh` and open a PR with `Fixes #<n>` on success.

### Agent outcomes

| Outcome | Labels | Project status | Assignee |
|---------|--------|----------------|----------|
| Dispatched | +`busy` | **In Progress** | — |
| PR opened | keep `busy` | **In Progress** | — |
| Blocked / failed | +`blocked`, +`question`, −`busy` | **In Progress** | `KanopeeKa` |
| PR merged | −`busy` | **In Main** | — |
| UAT deploy OK | — | **In UAT** | — |
| UAT deploy fail | +`question` | unchanged | `KanopeeKa` |

To retry after a block: fix the issue, remove `blocked` and `question`, re-add `human-reviewed`.

### Safety boundaries

Encoded in the sanitized prompt **and** enforced in CI:

**Forbidden paths** (agent PR safety gate fails the PR):

- `.github/workflows/**`
- `db/migrations/**`
- `server/config/security.js`
- `infra/**`

**Forbidden actions** (documented in prompt):

- Push directly to `main`
- Bypass PRs
- Access or log secrets
- Modify auth, billing, permissions, or CI

Triage already blocks risky issues with `manual-only` before dispatch.

### Branch and PR conventions

- Agent branches: `cursor/issue-<n>-<slug>-7a9a` (Cursor may auto-generate `cursor/...`; prompt requests this pattern)
- PRs: against `main`, body must include `Fixes #<n>`
- UAT promotion branch: `release/uat-YYMMDD-issue-<n>` (pushed automatically on merge)

### Required secrets

| Secret | Purpose |
|--------|---------|
| `cursor_api_key` | Cursor User API Key (**github-actions-pawpet-automation** in Cursor dashboard) |
| `GH_PROJECTS_PAT` | Project GraphQL updates |
| `GH_PROJECT_ID` | GitHub Project v2 node ID |
| `GH_STATUS_FIELD_ID` | Status field node ID |

Optional:

| Variable / secret | Default |
|-------------------|---------|
| `CURSOR_AGENT_MODEL` | Cursor default model |
| `AGENT_ASSIGNEE` | `KanopeeKa` |

#### Cursor API key setup

This repository uses a **dedicated User API Key** (non-Enterprise plans do not expose separate service accounts):

1. Cursor dashboard → **API** → create key named `github-actions-pawpet-automation`.
2. GitHub → repo → **Settings → Secrets and variables → Actions** → repository secret `cursor_api_key`.
3. Verify repo access: `curl -H "Authorization: Bearer $KEY" https://api.cursor.com/v1/repositories`

#### Project IDs (user-owned repo)

```bash
GH_PROJECTS_PAT=ghp_... node .github/scripts/discover-project-ids.js --user KanopeeKa
```

For organization-owned repos, use `--org <login>` instead.

### Monitoring and debugging

- **Dispatch logs:** Actions → **Agent dispatch**
- **Run polling:** Actions → **Agent monitor** (every 10 minutes)
- **Issue comment marker:** `<!-- cursor-agent-run: {...} -->` stores `agentId`, `runId`, status
- **Cursor UI:** follow the agent URL posted in the dispatch comment
- **Dry run:** `workflow_dispatch` on **Agent dispatch** with `dry_run: true`

### UAT CD notes

Current UAT deploy (`deploy-uat.yml`) is FTP-based and does not automatically apply database migrations or restart the server. The merge handler pushes `release/uat-*` branches; the [UAT tracker](../.github/workflows/uat-deploy-tracker.yml) sets **In UAT** only when the full UAT workflow succeeds.

**Recommended CD improvements** (future):

1. Add SSH deploy step with `UAT_SSH_HOST`, `UAT_SSH_KEY`, `UAT_DATABASE_URL` secrets.
2. Run `node server/scripts/migrate.js up` when `db/migrations/` changes.
3. Restart Passenger/Node after backend deploy (consume `server/tmp/restart.txt` or explicit restart command).
4. Gate **In UAT** on `smoke` + `prod-ready` jobs, not frontend FTP alone.

**Production promotion** remains manual via `deploy-prod.yml` (`workflow_dispatch`) after UAT validation.

## Deterministic triage automation

The triage workflow is implemented in:

- [`.github/workflows/triage-human-reviewed.yml`](../.github/workflows/triage-human-reviewed.yml) — GitHub Actions entry point
- [`.github/scripts/triage-lib.js`](../.github/scripts/triage-lib.js) — rules-based validation logic
- [`.github/scripts/triage-human-reviewed.js`](../.github/scripts/triage-human-reviewed.js) — applies labels, comments, and Project status updates
- [`.github/scripts/discover-project-ids.js`](../.github/scripts/discover-project-ids.js) — helper to find Project and Status field IDs

### Trigger

The workflow runs on `issues: labeled` when the label name is exactly `human-reviewed`.

The workflow also ensures these labels exist if missing: `human-reviewed`, `question`, `busy`, `manual-only`, `agent-approved`.

### Validation rules

The checker is **deterministic and policy-based** — same inputs produce the same decision. No LLM is used.

#### All issue types

- Title/summary must be present and at least 10 characters.
- Body must be long enough to be actionable.
- Placeholder or injection-like text (for example `TBD`, `fix later`, prompt-injection patterns) is rejected.
- Issues without a `bug`, `feature`, or `task` label are flagged for missing type.

#### Bug (`bug` label)

Required sections (from the issue form):

- Current Behavior
- Expected Behavior
- Steps To Reproduce
- Environment

#### Feature (`feature` label)

Required sections:

- Problem to Solve
- Proposed Solution
- Acceptance Criteria

#### Task (`task` label)

Required sections:

- Objective
- Scope
- Definition of Done

#### Risky scope (`manual-only`)

The issue is flagged for manual handling if the title or body matches sensitive keywords such as authentication, billing, payments, secrets, credentials, API keys, infrastructure, Terraform, Pulumi, migrations, `.github/workflows`, GitHub Actions, CI/CD, permissions, roles, or access control.

The **Security or Sensitive Area** form field also flags the issue when the answer is not a plain `No`.

### Outcomes

| Result | Labels | Project status | Comment |
|--------|--------|----------------|---------|
| Pass | add `agent-approved`; remove `question`, `manual-only` | **Ready** | Approval summary |
| Missing info | add `question`; remove `agent-approved` | **Backlog** | Lists missing fields; asks author to update and re-add `human-reviewed` |
| Risky scope | add `manual-only`; remove `agent-approved` | **Human Reviewed** | Explains sensitive scope; do not send to Cursor |

### Required secrets

Configure these in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Purpose |
|--------|---------|
| `GH_PROJECTS_PAT` | Classic PAT with `repo` and `project` (or `read:project` + `project`) scopes for Project GraphQL updates |
| `GH_PROJECT_ID` | Node ID of the GitHub Project v2 board |
| `GH_STATUS_FIELD_ID` | Node ID of the Project **Status** single-select field |

`GITHUB_TOKEN` is used for issue labels and comments only. Project field updates require `GH_PROJECTS_PAT` because `GITHUB_TOKEN` does not have sufficient Project scope.

#### Create the PAT

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**.
2. Generate a token with at least `repo` and `project` scopes (or fine-grained equivalent with Project read/write on the organization).
3. Store it as repository secret `GH_PROJECTS_PAT`.

Use a machine/bot account PAT where possible rather than a personal developer token.

#### Find Project and Status field IDs

From a clone of this repository:

```bash
GH_PROJECTS_PAT=ghp_... node .github/scripts/discover-project-ids.js --user <github-login>
# or: --org <org-login>
```

The script prints `GH_PROJECT_ID`, `GH_STATUS_FIELD_ID`, and the option IDs for each status value.

**Repository ownership:** This repo is **user-owned**. Use `--user <login>` when discovering project IDs. Organization-owned repos can use `--org <login>`.

If secrets are not configured, triage and agent workflows still update labels and comments but skip Project status changes and log a warning.
