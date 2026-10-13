---
title: Execute-plan instruction stack (Cloud Agents)
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-13
tags: [agent-efficiency, execute-plan, cloud-agents]
---

# Execute-plan instruction stack (Cloud Agents)

**Purpose:** When gate exits `0`, platform and repo instructions still conflict. **Precedence:** [`AGENTS.md`](../../AGENTS.md) §Precedence and §Execute-plan (forbidden closers, no routine chat). **Loop:** [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Execute-plan overrides · Skill §Stop rules · [execute-plan-autonomy.md](../../.agents/memory/execute-plan-autonomy.md).

Plan-specific orchestrator contracts (e.g. programme docs) **add** constraints; they do not relax this stack.

---

## When this applies

| Condition | Stack applies |
|-----------|----------------|
| `gate` exit **`0`** | Yes — run-until-blocked |
| Gate **`2`**, revoked, no grant | No — generic agent rules |
| Plain PR | No — babysit+ only |

---

## Platform vs repo (gate exit `0`)

| Generic instruction | During active execute-plan |
|---------------------|----------------------------|
| Prove changes in **user reply** | PR body, control issue, `/opt/cursor/artifacts/` |
| End turn with summary / walkthrough | Deferred — evidence in PR + artifacts |
| `code-tour-author-handoff.md` | When product code changes; **not** a phase stop |
| “Update PR each turn” then summarize | Update PR in-loop; summary ≠ stop |
| Babysit+ “scope ends here” | Ends babysit+ only — orchestrator continues phase loop |
| Testing / diligence defaults | See AGENTS.md §Reporting and §Execute-plan |

**Rule of thumb:** “Report progress to the user” or “end with a summary” is wrong during gate `0` except `complete-plan` or §Halt / `**Needs you:**`.

---

## Common false stop signals

| False stop | Next step (same session when possible) |
|------------|----------------------------------------|
| Phase PR opened | Babysit+, CI wait (subscribe), merge |
| CI green | Merge, `set-phase merged`, control-issue telemetry |
| Babysit+ merge to integration | Checkout next `pending` phase; implement or spawn worker |
| Plan bootstrap commit only | Implementation + PR or active worker |
| User sent `/execute-plan` | Resume `next_action` via tools — not a milestone request |
| Cloud turn ended after a reply | Next `/execute-plan` resumes; prior chat ≠ programme end |

---

## Phase implementation (orchestrator vs worker)

| Orchestrator must | Forbidden |
|-------------------|-----------|
| Next phase: checkout, `set-phase in_progress`, implement or Task worker → PR + babysit+ | User-visible “PR-N started” then stop |
| Babysit+ through squash-merge before `merged` | Treat babysit+ end as session end |

Default spawn worker for R1+ multi-file scope. Worker brief: [phase-implementer.md](../../.cursor/agent-kernel/workers/phase-implementer.md).

---

## Babysit+ inside execute-plan

| Babysit+ completes | Orchestrator |
|--------------------|--------------|
| Phase PR squash-merged | Runtime update → **next phase** (no user chat) |
| Release PR to `main` | `/babysit-uat` → `complete-plan` |
| CI exhausted / `do-not-merge` | §Halt + blocker chat |

Triage comment when `plan_id` set: `execute-plan: merge → continue phase loop`.

---

## Cloud turn mechanics

1. User-visible messages **end the Cloud turn** — prefer long tool-only stretches.  
2. Valid user chat: blocker alerts only. Invalid: PR #, CI green, next-phase narration, soft offers.  
3. Forced turn end while waiting on CI: **subscribe** (`cursor-subscriptions`) + await; optional one-line park per agent entry file — no summary.  
4. Next `/execute-plan` resumes `next_action` ([plan-template.md](./plan-template.md) §Turn boundary).

**Residual risk:** Platform testing prompts may still bias toward chat proof; AGENTS.md §Execute-plan narrows them — behaviour is not fully enforceable from the repo alone.

---

## Claude Code

| Topic | Rule (gate `0`) |
|-------|-----------------|
| Authorisation | Standing grant: phase/release PRs, snapshot branches, subscribe, squash-merge when gates pass |
| GitHub | `mcp__github__*` / `gh`; pass labels to `gate --labels` |
| Phase workers | [phase-implementer.md](../../.cursor/agent-kernel/workers/phase-implementer.md); summary to orchestrator only |
| Waiting | Background watch; if turn must end: subscribe + `send_later`; one line: `Parked on CI for <PR>; resuming on event.` |
| Docs | Sync before push; end-of-turn docs report deferred to `complete-plan` or halt |
| N/A | `composer-2.5`, `ManagePullRequest`, `/opt/cursor/artifacts/` |

---

## Related

[execute-plan-schema.md](./execute-plan-schema.md) · [execute-plan-runtime.md](./execute-plan-runtime.md) · [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) · [cursor-agent-framework.md](../engineering/cursor-agent-framework.md)
