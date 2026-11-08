---
name: light-plan
description: Single-agent sequential plan — phase PRs merge-committed one by one into an integration branch, one release PR to main after a full self-review, then /babysit-uat. Use for 2–4 phases; runs phase to phase without owner check-ins. /execute-plan when you need scope/budget guarantees or a longer programme.
disable-model-invocation: true
---

# Light-plan

Minimal sequential programme — tracking issue only; no execute-plan runtime. Policy links: [`merge-policy.mdc`](../../rules/merge-policy.mdc) · [`pr-hygiene.mdc`](../../rules/pr-hygiene.mdc) · integration ruleset [runbooks §7.2](../../../docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md).

## Run to completion

- `/light-plan` delivers a release merged to `main` with Pre-UAT green, not a plan.
- Do not end the turn or ask the owner at a step boundary (setup done, phase merged, checklist tick, sync PR, waiting on CI — `gh pr checks --watch`; waiting on review — `node scripts/babysit_pr_reviews.js wait --pr <url>`).
- End the turn only for stops in §Stop and ask, blocked `./scripts/pre-push.sh` in §Final self-review, or Done (§Release).
- Put status on the tracking issue (checklist ticks with PR links). Never ask for acknowledgement.

## When to use

| Workflow | When |
|----------|------|
| **`/light-plan`** | 2–4 sequential phases, ≤ ~2 days, no owner check-ins between phases |
| **`/execute-plan`** | Many phases; snapshot, budgets, driver, and automatic relaunch when you need scope/budget guarantees |
| **`/spawn-sprint-agents`** | Parallel agents on disjoint paths |

## Plan (tracking issue)

One GitHub issue with a one-sentence goal and `- [ ] P<n> — <outcome> — scope: <paths>`. The issue is the programme's only state (no runtime). Run `node scripts/github_issue_workflow.js start-work --issue <n> --body "…"`. No `plan:` labels. **Do not** open the release PR early (draft CI re-runs on every integration merge). Then start P1 immediately.

## Branches

- Integration: `cursor/<slug>-integration-<4 lowercase alnum>` from `main` (CI + ruleset `cursor/*-integration-*`).
- Dev (reused): `cursor/<slug>-dev` from integration; optional agent suffix on dev only.

## Phase loop (sequential)

**Sync first:** if integration is behind `main`, PR `main` → integration and **light merge** below (merge, never rebase — ruleset `non_fast_forward`); unclear conflict → stop and ask. Merge integration into local dev.

Implement the current phase per its checklist scope (files needed for that outcome → add them to that phase's scope on the checklist, note why on the issue, continue; stop only if the goal itself would change). Pre-PR self-review ([`pr-hygiene.mdc`](../../rules/pr-hygiene.mdc)) + `./scripts/pre-push-changed.sh`; open PR dev → integration (ready for review, not draft).

**Light merge (not `/babysit-plus`):** even if the integration ruleset is inactive, still require green CI and **every review conversation resolved** (autonomous-pr-policy §Babysit skill family).

1. `gh pr checks <url> --watch` — red → fix, one push per batch; same check red on **3 pushes** → stop (**Stop and ask**).
2. `node scripts/babysit_pr_reviews.js gate --pr <url>` — `0` merge; `2` fix or reply+resolve, re-run; `3` → post once `Copilot review did not finish within 15 min; proceeding on triage + CI + pre-push.` then merge; `1` fix script, never merge on error.
3. If draft: `gh pr ready <url>`. `gh pr merge <url> --merge`.

No merge lease, Copilot wait, triage comment, exit checklist or `./scripts/pre-push.sh` here. Deferred review → comment on tracking issue.

Remote dev deleted on merge: `git fetch origin <integration>`, merge into local dev, `git push -u origin cursor/<slug>-dev`. Tick checklist with PR link. Then start the next phase, or §Final self-review after the last one, in the same turn.

Self-review fixes use the same dev → integration light merge.

## Final self-review (before release PR)

**Sync integration:** if behind `main`, light-merge a sync PR, then re-review `origin/main...<integration>`.

- Goal + checklist done; cross-phase seams (dead code, dup helpers, half renames, TODOs)
- Files outside any phase scope (justify or revert)
- `/canonical-docs sync`; `## Docs` ready; combined test coverage; sensitive paths (`.github/scripts/agent-safety-lib.js`)
- Tracking deferrals: fix now or note in release PR body
- `./scripts/pre-push.sh` green — if blocked, stop and record on tracking issue (release also runs full suite via `/babysit-uat`)

Record under `## Self-review` on the release PR.

## Release

Open integration → `main` only now. Body: goal, phase links, `## Self-review`, `## Docs`, `Closes #<issue>`. Run **`/babysit-uat`** in the same turn (full [`/babysit-plus`](../babysit-plus/SKILL.md): Copilot triage, debt rules, squash, Pre-UAT, [`/e2e-debug`](../e2e-debug/SKILL.md) remedial). Done when Pre-UAT green on release merge SHA.

## Recovery

If the run is cut off (platform limit, crash, or the owner stops it), a new session resumes with `continue light-plan #<issue>`. Read the checklist and branch heads first. The agent never ends a turn just to use this.

## Stop and ask

[`AGENTS.md`](../../../AGENTS.md) §When to ask, plus: same check red on 3 pushes of one PR; a change to the goal; unresolvable main/integration conflict. One question + recommendation on the tracking issue.

## Not included

No snapshot, runtime, driver, approval, labels or budgets. Phase/sync PRs are not babysit+; full [`autonomous-pr-policy.md`](../../../docs/agent-efficiency/autonomous-pr-policy.md) on release only. Need guarantees → `/execute-plan`.
