---
title: Issue pipeline automation — proposal
owner: Documentation Team
audience: both
status: proposed
status_since: 2026-11-14
last_updated: 2026-11-14
tags: [agent-efficiency, github-issues, automation, security]
folds_into: [docs/agent-efficiency/github-issue-workflow.md, docs/agent-efficiency/github-labels.md, .cursor/skills/light-plan/SKILL.md, docs/agent-efficiency/plans/execute-plan-v2/contracts.md]
---

# Issue pipeline automation — proposal

This proposal automates the issue flow end to end: Backlog → To do → In Analysis → Ready → In Progress → In Main → In UAT → In Prod. Claude and Cursor review each issue in alternating rounds until they agree. The pipeline then picks a delivery method, implements under a work-in-progress limit, and tracks the release in GitHub Actions.

The proposal is based on the manual Agent1/Agent2 review rounds run on 2026-11-13 (issues #311, #1672, #1770, #2116, #2139, #2175) and on the automation already in the repo. It is analysis only; nothing here is built yet.

**Owner decisions (2026-11-13):**

| # | Question | Decision |
|---|---|---|
| 1 | Who approves execute-plan programmes started by the pipeline? | **(b) Coded auto-approve policy** in the approve workflow, run as the bot, under strict conditions (§8). Never an agent posting the approval line with the owner token. |
| 2 | Lifecycle of light-plan issues | **Hybrid:** the agent session stops at Pre-UAT green; Actions move the issue through In Main → In UAT → In Prod and close it (§9). |
| 3 | Move repo and Project to a GitHub organisation? | **Not now** — stay user-owned; labels are the source of truth for status (§2). |

## 1. What already exists

About half of the planned pipeline is already in the repo. The new design should extend these pieces rather than duplicate them.

| Piece | File | What it does today |
|---|---|---|
| Deterministic triage | `.github/workflows/triage-human-reviewed.yml`, `.github/scripts/triage-lib.js` | On `human-reviewed`: checks the issue form sections, flags risky keywords as `manual-only`, otherwise adds `agent-approved` and sets **Ready** |
| Agent dispatch | `.github/workflows/agent-dispatch.yml` | Launches one Cursor agent at a time (`concurrency: agent-dispatch`) for Ready + `agent-approved` + `human-reviewed` issues |
| Sanitised payload | `.github/scripts/agent-payload-lib.js` | Builds the agent prompt from issue form sections only; **raw comments are never sent** |
| Agent monitor | `.github/workflows/agent-monitor.yml` | Polls Cursor runs through the run marker `<!-- cursor-agent-run: … -->` (manual dispatch only) |
| Merge → In Main | `.github/workflows/issue-agent-pr-merge.yml`, `.github/scripts/issue-agent-handlers.js` | On a merged `cursor/**` PR with `Refs #n`: removes `busy`, reopens, sets **In Main**, records the expected `uat-YYMMDD-PR#` tag. Skips plan control issues. |
| UAT tag and deploy | `promote-uat.yml`, `deploy-uat.yml` (`agent-uat-notify`) | Tags the merge, deploys, sets **In UAT** when every gate passes |
| Prod deploy | `deploy-prod.yml` | Deploys after Prod ready; **no issue notify** |
| Execute-plan v2 | `execute-plan-approve.yml`, `execute-plan-driver.yml` (30-minute cron) | Owner approval, then a driver that runs `tick` and launches workers; kill switch `EXECUTE_PLAN_DRIVER` |
| Forbidden paths | `.github/scripts/agent-safety-lib.js`, `agent-pr-safety-gate.yml` | Fails agent PRs touching `db/migrations/**`, `server/config/security.js`, `infra/**`, `/auth/`, `/billing/`, `/secrets?/` |

## 2. Access and identities

### 2.1 Labels are the source of truth for status

Agents never write to the GitHub Project.

- One status label per state, exactly one per issue: `status:backlog`, `status:todo`, `status:analysis`, `status:planned`, `status:ready`, `status:in-progress`, `status:in-main`, `status:in-uat`, `status:done`.
- A **Project sync** workflow runs on `issues: labeled` and sets the Project **Status** field. It is the only job holding `GH_PROJECTS_PAT`, in the `automation` environment.
- A reverse sync (board move → label) is optional, needed only if humans keep moving cards by hand.

What this solves:

- Claude no longer needs Projects access; its current gap ("sees labels, not status") disappears.
- No agent token needs the `project` scope.
- The `project_secrets_missing` failures from `github_issue_workflow.js set-status` stop mattering for agents.

### 2.2 Identities

| Actor | Identity | Token |
|---|---|---|
| Cursor agents | `pawpet-bot` (existing) | Classic PAT, `repo` only. Pushes and PRs go through the Cursor GitHub App. |
| Claude agents | **New machine user `pawpet-claude`** | Classic PAT, `repo` only; collaborator on AgathaCheck **only**, because a classic PAT reaches every repo the account can access. When Claude runs in Actions (`claude-code-action`), the workflow `GITHUB_TOKEN` with `issues: write` and `pull-requests: write` may be enough. |
| Deterministic workflows | `GITHUB_TOKEN` | Plus `GH_PROJECTS_PAT` in the Project sync job only |
| Owner | `OWNER_GH_TOKEN` | Humans only. No autonomous lane holds it. |

A separate Claude login gives:

- an audit trail of which agent did what;
- separate revocation and rate limits;
- **enforced review independence:** the dispatcher can require that a review comment's author differs from the previous round's author.

### 2.3 Least privilege per lane

| Lane | Contents | Issues | Pull requests |
|---|---|---|---|
| Intake, review, delivery | read | write | none |
| Implement, monitor | write | write | write |
| Release tracking | none (Actions only) | write | read |

Enforce this through the token and launch settings, not prompt instructions.

### 2.4 Token hygiene

- Every PAT has an expiry of about 90 days and a rotation reminder.
- `OWNER_GH_TOKEN` is a dashboard secret today, so it reaches every Cloud VM. Narrow it to the runs that need it, or keep owner-only actions inside Actions environments with required reviewers.
- No agent token gets the `workflow` scope (as today). Changes to workflows and to the safety library go through owner review (`agent-pr-safety-gate`, `guard-rail-change-alert`).

## 3. Architecture: one dispatcher with lanes

Use one general dispatcher, the pattern `scripts/execute_plan_runtime.js tick` already proves.

- **Dispatcher:** a plain Node script in Actions. It reads labels, the state marker (§4), PRs, CI runs and agent runs, then decides **one next action per issue**. It launches a narrow worker (Cursor API or Claude) for that one issue and step.
- **Workers** never filter "all issues in status X". They do one step and end. This removes most prompt drift and double processing.
- **Lanes**, each with its own concurrency group and per-tick cap:

| Lane | Agent | Cap per tick |
|---|---|---|
| Intake | Claude | 2 |
| Review | Cursor and Claude, alternating | 2 per agent |
| Delivery | Cursor | 1 |
| Implement | Cursor (Composer 2.5) | Work-in-progress limit (§6) |
| Monitor | Cursor | 2 |
| Release tracking | No agent (Actions) | — |

- **Per-issue lock:** reuse the `busy` label plus a run marker holding the agent ID and start time. Reclaim a stale lock after a set time (for example 3 hours for analysis lanes).
- **Kill switch and dry run:** a repo variable (for example `ISSUE_PIPELINE`) with `off` (default) / `dry-run` / `on`, checked first, like `EXECUTE_PLAN_DRIVER`.
- **Consolidation:** fold `triage-human-reviewed.yml`, `agent-dispatch.yml` and `agent-monitor.yml` into the dispatcher, or retire them. Otherwise two dispatchers compete for the same Ready issues.

## 4. State marker instead of title counters

The proposed `[x]` and `[x][y]` title counters break existing automation. `isPlanControlIssue` in `.github/scripts/issue-agent-handlers.js` matches `/^(?:\[)?(?:light-plan|execute-plan)\b/i`; a title like `[0] light-plan: …` no longer matches, so the merge handler treats a programme issue as a product ticket. Titles are also edited by humans and fire `edited` events.

Use one hidden marker, written only by the bot identities, at the end of the issue body:

```
<!-- agent-state: {"round":3,"stuck":0,"last_reviewer":"cursor","verdict":"red","body_sha":"…","delivery":"PR","owner_reason":null} -->
```

| Field | Meaning |
|---|---|
| `round` | Review rounds so far (replaces the first title counter) |
| `stuck` | Monitor relaunches while In Progress (replaces the second title counter) |
| `last_reviewer` | `claude` or `cursor`; the next reviewer is the other one |
| `verdict` | Latest verdict |
| `body_sha` | Hash of the agreed body text at the last verdict; used for the convergence rule (§5.3) |
| `delivery` | `PR`, `light-plan` or `execute-plan` once chosen |
| `owner_reason` | Why `needs-owner` was set (§7) |

Optionally mirror `round` in a numeric Project field for a board view.

## 5. Workflows by status

### 5.1 Backlog → To do

- Adding `todo` (or `status:todo`) moves the issue to **To do**. With labels as status, `status:todo` *is* the move, so no separate "remove `todo`" step is needed.
- It can still be done by hand on the board if the reverse sync exists.

### 5.2 To do — intake (Claude)

For one issue:

1. **Information check.** Read the body and comments from allowed authors only (§10.1). If the information is not enough, add `question` with one comment saying what is missing, and stop. Reuse `question` rather than adding `missing-info`; the existing triage flow already uses it.
   - **Re-entry:** when the author updates the issue (or an allowed author comments), the dispatcher removes `question` and re-queues intake.
2. **Analysis.** Review the context and requirement, adjust the description, and write the plan. The spec and plan cover tests, documentation (canonical doc), logging, monitoring, security, database and migrations. If a screen is touched, apply the `ui-design-deep` skill guidelines.
3. **Handoff.** Post a detailed review comment for the second agent, write the marker (`round: 0`, `last_reviewer: "claude"`), and move to **In Analysis**.

### 5.3 In Analysis — one alternating peer-review step

The proposed "Analysis 1/2/3" workflows are one step mirrored. Replace them with one peer-review step where the reviewer is whichever agent did not write last.

For one issue:

1. If `round` exceeds the limit (**4** recommended; 5 costs many tokens), set `needs-owner` with reason `no-convergence` and stop.
2. Review the previous comment and plan. Fold minor points into the issue body; address every question raised.
3. Post a clear comment with the verdict and the updated plan.
4. Set the single verdict label `review:green` or `review:red` (replacing the previous one), update the marker, and increment `round`.

**Convergence rule:** move to **Planned** only when the reviewer says Green **and** made no substantive body change in that round (`body_sha` unchanged), or after two consecutive Greens. Otherwise the turn passes to the other agent.

Why:

- In the proposed flow, Cursor folds Claude's points into the body *and* goes Green → Ready in the same step, so Claude never sees the edited text.
- "Analysis 2" filters on Cursor:Green issues still In Analysis, but Cursor:Green already moved them to Ready, so that path is empty.
- Keeping both `Claude:*` and `Cursor:*` labels side by side produces contradictory pairs (for example `Claude:Red` + `Cursor:Green`) the dispatcher must interpret. One verdict label plus the marker is unambiguous; history lives in comments.

### 5.4 Planned — delivery method (Cursor)

"Analysis converged" and "delivery method chosen" are separate states. Without that split, Implement can pick up an issue before Delivery has run.

For one issue:

1. Choose `PR`, `light-plan` or `execute-plan`:
   - **PR:** one verifiable outcome, one reviewable diff.
   - **light-plan:** 2–4 sequential phases, no owner check-ins between phases.
   - **execute-plan:** more phases, or when scope and budget guarantees are needed.
2. Rewrite the existing issue to the template for that method. Do not create a new issue (execute-plan exception in §8).
   - **PR:** issue form sections (Summary, Objective, Scope, Out of Scope, Definition of Done, Priority, Affected Area, Security or Sensitive Area), branch name, `Refs #n`.
   - **light-plan:** title `light-plan: …`, one-sentence goal, integration and dev branches, `- [ ] P<n> — <outcome> — scope: <paths>` checklist.
   - **execute-plan:** plan file per `docs/agent-efficiency/plan-template.md` (§8).
3. Write a machine-readable **planned paths** block:

   ````
   ```json agent-paths
   { "paths": ["e2e/playwright/pages/**", "flutter_app/lib/l10n/**"] }
   ```
   ````

4. The **dispatcher** (not the agent) checks those paths against `isForbiddenPath` plus `.github/**` and `.cursor/agent-kernel/**`. A match sets `needs-owner` with reason `sensitive-paths`. Otherwise it adds the delivery label and moves to **Ready**.

`triage-lib.js` flags risk from **keywords in the body** ("migration", "roles", "permissions"). That over-flags: #2116 mentions migrations but touches no file under `db/migrations/`. Decide sensitivity from planned paths, and keep the keyword check only as a hint.

### 5.5 Ready — implement (Cursor, Composer 2.5)

Filter: **Ready** + delivery label + no `needs-owner` + a free work-in-progress slot (§6).

| Label | Action |
|---|---|
| `PR` | Implement on the named branch, open the PR with `Refs #n`, then drive it with `/babysit-plus` |
| `light-plan` | Start `/light-plan` on the issue |
| `execute-plan` | Run `init` from the plan file; the approve workflow applies the auto-approve policy (§8) |

Set **In Progress** and `busy` at launch, and record the agent ID in the run marker. If the launch fails, set `needs-owner` with reason `launch-failed`.

### 5.6 In Progress — monitor (Cursor)

Filter: **In Progress** without `needs-owner`. If `stuck` exceeds the limit (for example 3), set `needs-owner` with reason `stuck`.

| Label | Action |
|---|---|
| `PR` | PR merged → nothing to do (Actions moves the issue to In Main). Otherwise, if the recorded agent run has ended without merging, relaunch `/babysit-plus` and increment `stuck`. |
| `light-plan` | If the session has ended before Pre-UAT green, relaunch with `continue light-plan #n` and increment `stuck`. Do **not** start `/babysit-plus` on the release PR; light-plan drives it through `/babysit-uat`. |
| `execute-plan` | Report only. Humans and agents must not run `/babysit-*` on plan PRs or push to plan branches outside a worker `tick` (execute-plan skill). A stopped plan needs `resume-autonomous`, which is owner-only, so a stop sets `needs-owner` with reason `plan-stopped`. |

"Is babysit watching?" is not observable today. The run marker makes it observable: the dispatcher checks the recorded agent's status through the Cursor API (what `agent-monitor` was built for) and relaunches only when the run ended without the expected outcome.

### 5.7 In Main → In UAT → In Prod (Actions only)

No agent is needed.

- **In Main:** `issue-agent-pr-merge.yml` already handles merged PRs with `Refs #n` and records the expected `uat-YYMMDD-PR#` tag.
- **In UAT:** `deploy-uat.yml` `agent-uat-notify` already sets it when every UAT gate passes.
- **In Prod (new):** add a notify job to `deploy-prod.yml`, mirroring `agent-uat-notify`. It adds `in-prod`, sets **Done**, tidies labels (`busy`, lane labels) and closes the issue.

The link between deploy and issue is the PR number in the UAT tag plus `Refs #n` in the PR body, so no extra note on the issue is needed.

## 6. Work-in-progress limit

Enforce it in the dispatcher, not in prompts.

| Delivery | Slots |
|---|---|
| `PR` | 1 |
| `light-plan` | 2 (one session holds for hours, through Pre-UAT) |
| `execute-plan` | 2 |

- **Capacity: 2.** In practice, either one programme or up to two single PRs.
- **What holds a slot:** issues In Progress, or with `busy`, or with an open PR or programme. In Progress issues stuck with `needs-owner` still hold their slot, so stuck work does not silently free capacity.
- **Order:** priority label, then age.
- **Release:** a slot frees when the issue leaves In Progress and `busy` is removed. The merge event re-runs the dispatcher, so the next issue starts without waiting for the heartbeat.

## 7. `needs-owner` with a reason

`needs-owner` today would mean "sensitive paths", "no convergence", "stuck", "launch failed" and "approval needed". On an execute-plan control issue the driver also treats `needs-owner` as a **STOP** (`scripts/lib/execute_plan_control.js`).

- Keep `needs-owner` as the single "human please look" label, and record `owner_reason` in the marker: `sensitive-paths`, `no-convergence`, `stuck`, `launch-failed`, `plan-stopped`, `approve`.
- Never set `needs-owner` on an execute-plan **control** issue for a pipeline reason; set it on the product issue.
- Agents never remove `needs-owner` (run-as-me rule 6); the owner removes it in the web interface.

## 8. Execute-plan: product issue, control issue and auto-approve (decision 1b)

### 8.1 Two issues

`init` always creates a new control issue, which conflicts with "rewrite the existing issue".

- The **product issue** (the one in the pipeline) stays in the pipeline and links to the control issue.
- The **control issue** belongs to the driver, which closes it when the programme finishes.
- The plan snapshot records `source_issue`, and the driver writes `Refs #<source_issue>` in the release PR body, so the product issue follows In Main → In UAT → In Prod (§5.7).

### 8.2 Coded auto-approve policy

The approve workflow (`.github/scripts/execute-plan-approve.js`, trusted `main` code) approves on its own, as the bot, only when **all** of these hold:

- **Paths:** no phase `allowed_paths` or `companions` match `isForbiddenPath`, `.github/**` or `.cursor/agent-kernel/**`, and there is no `approved_sensitive_paths` field.
- **Window and size:** approval window of 7 days or less, default budgets, at most 6 phases.
- **Provenance:** the plan file was committed by the bot on the `-init` branch, and that branch contains only the two plan files (the existing `init` guard).
- **Review:** the product issue's marker shows convergence (both agents Green) and the issue has no `needs-owner`.
- **Concurrency:** at most one auto-approved plan active at a time, and only while `EXECUTE_PLAN_DRIVER` is `on`.

It then posts an `auto-approved by policy` acknowledgement with the hash, for audit. A plan that fails any condition gets `needs-owner` with reason `approve` on the product issue. `revoke-autonomous` and `resume-autonomous` stay owner-only.

**Never:** an agent posting `approve-autonomous` with `OWNER_GH_TOKEN`. The approval line is the owner's sign-off on the frozen plan hash; letting an agent that reads issue text approve its own plan opens a prompt-injection route to autonomous merges.

**Escalation:** this changes approval behaviour and the execute-plan v2 contracts. The implementing PR needs owner review and decision-log rows in `execute-plan-v2.md` and `execute-plan-v2/contracts.md`.

## 9. Light-plan lifecycle (decision 2)

| Option | What happens | Downside |
|---|---|---|
| A. Keep today's rule | Issue closes at Pre-UAT green | Two lifecycles on one board; UAT and Prod tracking can't see programmes; "done" may not be live |
| B. Full lifecycle in the agent | Session waits for UAT and Prod | Sessions open for hours or days; costs money and holds a slot |
| **C. Hybrid (chosen)** | Agent stops at Pre-UAT green; Actions move the issue to In UAT and In Prod, then close it | A few rule changes (below) |

Why C:

- One lifecycle for all three delivery methods, so release tracking has one rule.
- No agent waits on deploys; UAT and Prod tracking cost no agent time.
- A closed issue really is in production.
- Slots free when the light-plan removes `busy` after Pre-UAT green, not at production.

Changes required:

1. **Light-plan skill:** the release PR uses `Refs #n` instead of `Closes #n`. The final step posts the merge SHA and Pre-UAT run link and removes `busy`, but does not close the issue. `/e2e-debug` remedial work after merge stays in the session.
2. **`issue-agent-handlers.js`:** stop excluding `light-plan:` issues from In Main; exclude only execute-plan control issues.
3. **`deploy-prod.yml`:** the prod notify job from §5.7.
4. **Docs:** `github-issue-workflow.md` §plan control issue and its decision log.

`promote-uat` already tags `uat-YYMMDD-<PR#>` with the release PR number, so `Refs #n` on the release PR is all the notify jobs need.

## 10. Security

### 10.1 Prompt injection from issues and comments

`agent-payload-lib.js` deliberately never sends raw comments to agents. The review loop depends on comments, so reverse that carefully:

- pass only comments from an allowlist (`KanopeeKa`, `pawpet-bot`, `pawpet-claude`);
- wrap them as quoted data in the prompt, never as instructions;
- ignore or summarise text from other users;
- treat the state marker as valid only when written by a bot identity (check the last editor of the body, or keep the marker in a bot-authored comment).

### 10.2 Other controls

- **Owner token:** out of every autonomous lane (§2.4, §8.2).
- **Workflow changes:** no `workflow` scope on agent tokens; owner review on `.github/**` and the safety library.
- **Budgets:** a daily ceiling on agent launches per agent, the existing CI retry budget (`autonomous-pr-policy.md` §CI retry budget), and the kill switch.
- **Review independence:** the dispatcher rejects a verdict whose comment author equals the previous round's author.

## 11. Tick frequency

Event-driven first, with a heartbeat as the safety net.

- **Events:** `issues: labeled/edited`, `issue_comment` from allowed authors, `pull_request_target: closed`, `workflow_run` for CI, Pre-UAT and deploys.
- **Heartbeat:** every 30 minutes, matching the execute-plan driver. GitHub cron is best-effort and often delayed, so do not go below about 15 minutes.
- **Optional cost saver:** run intake and review as a nightly batch; keep implement and monitor event-driven.

## 12. End-to-end flow

```
Backlog ──todo──▶ To do ──[Claude intake]──▶ In Analysis
   ▲                 │ not enough info → question (author updates → back)
   │                 ▼
   │     peer review alternates Cursor ⇄ Claude, round++ in marker
   │     converged (Green, no body change) → Planned
   │     round > 4 → needs-owner (no-convergence)
   │
Planned ──[Cursor delivery: PR | light-plan | execute-plan + paths block]──▶ Ready
   │     sensitive paths → needs-owner (sensitive-paths)
   │     execute-plan → init → auto-approve policy, else needs-owner (approve)
   ▼
Ready ──[implement, work-in-progress limit]──▶ In Progress (busy + run marker)
In Progress ──[monitor: relaunch ended runs; plans → report / needs-owner]──
merge (Actions) ▶ In Main ▶ deploy-uat notify ▶ In UAT ▶ deploy-prod notify (new) ▶ in-prod + Done + close
```

## 13. Delivery order (stacked PRs)

Each step is one PR with its own verifiable outcome.

1. **Labels as status:** create the `status:*` labels and the Project sync workflow (`GH_PROJECTS_PAT` in `automation` only). Backfill labels from the current board.
2. **Dispatcher skeleton:** kill switch, dry-run mode, state marker read/write, per-issue lock. Dry run only.
3. **Intake and review lanes:** Claude intake (with the `pawpet-claude` identity), alternating peer review, convergence rule, round limit.
4. **Delivery lane:** templates, planned-paths block, sensitive-path check in the dispatcher.
5. **Implement and monitor lanes:** work-in-progress limit, run markers, relaunch rules. Retire or fold `agent-dispatch.yml`, `agent-monitor.yml` and `triage-human-reviewed.yml`.
6. **Release tracking:** prod notify job in `deploy-prod.yml`; light-plan lifecycle change (§9).
7. **Execute-plan auto-approve and `source_issue`** (§8) — needs owner review.

## Open points

- Allowed comment authors beyond the three identities (other collaborators?).
- Exact round and `stuck` limits after the first weeks of data.
- Whether intake and review run as a nightly batch or on events.

## Decision log

| ID | Decision | Rationale | Status | Date |
|---|---|---|---|---|
| ISSUE-PIPELINE-D-001 | Execute-plan programmes started by the pipeline use a coded auto-approve policy in the approve workflow, run as the bot | Keeps approval in trusted code with hard conditions; no agent holds the owner token | Proposed | 2026-11-13 |
| ISSUE-PIPELINE-D-002 | Light-plan issues follow In Main → In UAT → In Prod through Actions; the agent session stops at Pre-UAT green | One lifecycle for all delivery methods; no agent waits on deploys | Proposed | 2026-11-13 |
| ISSUE-PIPELINE-D-003 | Stay user-owned; status labels are the source of truth and one Actions job syncs the Project | Removes Projects access from agent tokens; Claude needs only issue access | Proposed | 2026-11-13 |
| ISSUE-PIPELINE-D-004 | Review state lives in a bot-written body marker, not title counters | Title prefixes break `isPlanControlIssue` and are edited by humans | Proposed | 2026-11-14 |
