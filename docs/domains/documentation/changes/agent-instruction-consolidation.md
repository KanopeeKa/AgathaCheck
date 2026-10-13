---
title: Agent instruction consolidation — delivery
owner: Documentation Team
audience: agent
status: in-delivery
status_since: 2026-10-13
plan: agent-instruction-consolidation (PR sequence below; no execute-plan snapshot)
folds_into: docs/domains/documentation/standards.md
last_updated: 2026-10-13
---

# Agent instruction consolidation — delivery

**Outcome:** every agent (Cursor, Claude Code, Copilot, Replit) loads one shared rulebook (`AGENTS.md`) plus its own
deltas, with no restated or contradicting rules, enforced by gate I. Model: `docs/agent-efficiency/agent-instructions.md`
(decision `DOCUMENTATION-STANDARDS-D-008`).

## Why

Restated rules drifted across layers (Bugbot "primary" vs "disabled", merge by user vs always-merge, "stop and ask" vs
run-until-blocked). Execute-plan runs kept stopping between phases although the contract said not to; adding override
docs (#1851, #1853, #1854) did not fix it. Claude Code loaded ~4,700 words of always-on rules including path-scoped
ones; Copilot's instruction files never applied (no `applyTo`, a glob-named file); Replit followed a stale policy copy
in memory.

## Delivery

| # | Owner | Scope | Status |
|---|-------|-------|--------|
| 1 | Claude Code | Architecture doc + standards rule 11/D-008; `AGENTS.md` operating rules (precedence, when to ask — critical only, autonomy/merge, reporting, execute-plan contract + forbidden closers); `CLAUDE.md` slimmed (1,531 words always-loaded) + `.claude/rules/` path pointers + `/execute-plan` pointer skill + steward merge rule; `.github/copilot-instructions.md` (broken path files removed); `replit.md` slimmed + Replit policy moved out of memory; gate I (WARN) | This PR |
| 2 | Cursor | `.cursor/**` dedupe (link, don't restate); execute-plan skill ≤300 lines; Bugbot retired (`.cursor/BUGBOT.md`, `/review-bugbot`, `pr-review-cost-efficiency.md`); `pr-hygiene.mdc` model-switch wording; gate I findings in owned files → 0 | Planned |
| 3 | Cursor | Runtime: `gate` output ends with the concrete next action; CI waits via subscriptions (tool-only); `expired` halt text = re-approve + `resume-plan` only. `approved_until` stays 48h | Planned |
| 4 | Claude Code | Promote gate I to BLOCK (wire into `pre-push-changed.sh` governance); audit `docs/agent-efficiency/` for stale plans (`uat-coordinator-plan.md`, `parallel-programmes.md`, `execute-plan-memory-1470.md`) | Planned — after 2 |
| 5 | Any | Product rules still in memory (`MEMORY.md` §Domain semantics, R-M4 backlog) move during per-capability `/canonical-docs consolidate` | Ongoing (existing backlog) |

## Acceptance

- `node scripts/check_docs_canonical.js --instructions` reports 0 findings (then promoted to BLOCK).
- No instruction file restates a rule whose home is elsewhere (owner map in the architecture doc).
- An execute-plan run with gate exit `0` produces no user-visible message between phase merges.

On the PR that delivers item 4, fold the remaining rows into `standards.md` / the architecture doc and delete this file.
