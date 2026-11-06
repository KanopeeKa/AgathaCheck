---
name: light-plan
description: Single-agent sequential plan — phase PRs merge-committed one by one into an integration branch, one release PR to main after a full self-review, then /babysit-uat. Use for 2–4 phases with an attentive owner; /execute-plan for long unattended programmes.
disable-model-invocation: true
---

# Light-plan

Minimal sequential programme — tracking issue only; no execute-plan runtime. Policy links: [`merge-policy.mdc`](../../rules/merge-policy.mdc) · [`pr-hygiene.mdc`](../../rules/pr-hygiene.mdc) · integration ruleset [runbooks §7.2](../../../docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md).

## When to use

| Workflow | When |
|----------|------|
| **`/light-plan`** | 2–4 sequential phases, owner around, ≤ ~2 days |
| **`/execute-plan`** | Many phases, multi-day unattended, scope/budget guarantees |
| **`/spawn-sprint-agents`** | Parallel agents on disjoint paths |

## Plan (tracking issue)

One GitHub issue: one-sentence goal, then `- [ ] P<n> — <outcome> — scope: <paths>`. Only state — resume with `continue light-plan #<issue>`. `node scripts/github_issue_workflow.js start-work --issue <n> --body "…"`. No `plan:` labels. **Do not** open the release PR early (draft CI re-runs on every integration merge).

## Branches

- Integration: `cursor/<slug>-integration-<4 lowercase alnum>` from `main` (CI + ruleset `cursor/*-integration-*`).
- Dev (reused): `cursor/<slug>-dev` from integration; optional agent suffix on dev only.

## Phase loop (sequential)

**Sync first:** if integration is behind `main`, PR `main` → integration and **light merge** below (merge, never rebase — ruleset `non_fast_forward`); unclear conflict → stop and ask. Merge integration into local dev.

Implement phase scope only (more files → update checklist or stop). Pre-PR self-review ([`pr-hygiene.mdc`](../../rules/pr-hygiene.mdc)) + `./scripts/pre-push-changed.sh`; PR dev → integration.

**Light merge (not `/babysit-plus`):** even if the integration ruleset is inactive, still require green CI and resolved threads.

1. `gh pr checks <url> --watch` — red → fix, one push per batch; same check red on **3 pushes** → stop (§7).
2. `node scripts/babysit_pr_reviews.js gate --pr <url>` — `0` merge; `2` fix or reply+resolve, re-run; `3` (Copilot pending, nothing unresolved) merge anyway; `1` fix script, never merge on error.
3. `gh pr merge <url> --merge`.

No merge lease, Copilot wait, triage comment, exit checklist or `./scripts/pre-push.sh` here. Deferred review → comment on tracking issue.

Remote dev deleted on merge: `git fetch origin <integration>`, merge into local dev, `git push -u origin cursor/<slug>-dev`. Tick checklist with PR link.

Self-review fixes (§5) use the same dev → integration light merge.

## Final self-review (before release PR)

Review whole `origin/main...<integration>` diff:

- Goal + checklist done; cross-phase seams (dead code, dup helpers, half renames, TODOs)
- Files outside any phase scope (justify or revert)
- `/canonical-docs sync`; `## Docs` ready; combined test coverage; sensitive paths (`.github/scripts/agent-safety-lib.js`)
- Tracking deferrals: fix now or note in release PR body
- `./scripts/pre-push.sh` (or pre-push-changed + what could not run)

Record under `## Self-review` on the release PR.

## Release

Open integration → `main` only now. Body: goal, phase links, `## Self-review`, `## Docs`, `Closes #<issue>`. Hand off **`/babysit-uat`** (full [`/babysit-plus`](../babysit-plus/SKILL.md): Copilot triage, debt rules, squash, Pre-UAT, [`/e2e-debug`](../e2e-debug/SKILL.md) remedial). Done when Pre-UAT green on release merge SHA.

## Stop and ask

[`AGENTS.md`](../../../AGENTS.md) §When to ask, plus: same check red on 3 pushes of one PR; scope creep; unresolvable main/integration conflict. One question + recommendation on the tracking issue.

## Not included

No snapshot, runtime, driver, approval, labels or budgets. Phase/sync PRs are not babysit+; full [`autonomous-pr-policy.md`](../../../docs/agent-efficiency/autonomous-pr-policy.md) on release only. Need guarantees → `/execute-plan`.
