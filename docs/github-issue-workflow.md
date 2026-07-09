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
4. **Ready** — Issue is approved for implementation. It may be handed to Cursor or picked up manually.
5. **In Progress** — When work starts, move here and add `busy`. Remove `busy` when work stops or ownership transfers.
6. **In Main** — After the change merges to `main`.
7. **In UAT** — While the change is validated in UAT.
8. **Done** — Validation complete; close the issue.

Throughout the workflow, use `busy` to signal active work and `question` when blocked on missing information.

To re-run triage after updating an issue, remove `question` (if present) and re-add `human-reviewed`.

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
GH_PROJECTS_PAT=ghp_... node .github/scripts/discover-project-ids.js <org-login>
```

The script prints `GH_PROJECT_ID`, `GH_STATUS_FIELD_ID`, and the option IDs for each status value.

**Organization assumption:** This automation expects an **organization-owned** repository with a GitHub Project v2 board. If the repository is user-owned, Project GraphQL access may be limited; move the repo to an organization or adjust the discovery script query.

If secrets are not configured, the workflow still runs label and comment updates but skips Project status changes and logs a warning.

### Cursor handoff (future)

Cursor agent handoff is **not implemented yet**. When added, only issues in **Ready** with `agent-approved` (and without `manual-only` or `busy`) should be eligible.

The handoff must use a **sanitized task payload** derived from approved fields, not the raw issue body.
