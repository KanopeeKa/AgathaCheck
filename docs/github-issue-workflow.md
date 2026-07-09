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
2. **Human Reviewed** — A maintainer reviews the issue: confirms clarity, priority, and that it belongs in the backlog. Move the status to **Human Reviewed**.
3. **Auto Check** (process, not a status) — A deterministic checker runs automatically after **Human Reviewed**:
   - If the issue is complete and safe → move to **Ready** and apply `agent-approved` when appropriate.
   - If more information is needed → add `question`, comment on what is missing, and keep or return the issue to **Backlog** until resolved.
   - If the issue must not be automated → add `manual-only`.
4. **Ready** — Issue is approved for implementation. It may be handed to Cursor or picked up manually.
5. **In Progress** — When work starts, move here and add `busy`. Remove `busy` when work stops or ownership transfers.
6. **In Main** — After the change merges to `main`.
7. **In UAT** — While the change is validated in UAT.
8. **Done** — Validation complete; close the issue.

Throughout the workflow, use `busy` to signal active work and `question` when blocked on missing information.

## Future automation handoff

GitHub Actions for the checker and Cursor handoff are **not implemented yet**. This section documents the intended design so future automation follows the same rules.

### Deterministic checker principles

The future checker must be **deterministic and policy-based** — same inputs produce the same decision. It should:

- Validate that required issue content is present.
- Validate issue type-specific fields (bug reproduction, feature acceptance criteria, task definition of done).
- Reject or flag risky scope such as auth, billing, secrets, infrastructure, migrations, or CI/workflow changes.
- Avoid passing raw, untrusted issue text directly into Cursor.
- Generate a **sanitized task payload** when automation is added, containing only approved fields and redacted content suitable for agent consumption.

### Cursor handoff

When automation is added, only issues in **Ready** with `agent-approved` (and without `manual-only` or `busy`) should be eligible for Cursor. The handoff should use the sanitized payload from the checker, not the raw issue body.
