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

**Outcome:** one shared rulebook (`AGENTS.md`) plus agent deltas, gate I clean, runtime nudges for execute-plan. Model:
`docs/agent-efficiency/agent-instructions.md` (D-008).

## Prerequisites

Branch from **`origin/main` after PR #1869** (or later) so `AGENTS.md` §Operating rules and gate I exist.

## Why

Restated rules drifted; override docs did not stop wrongful execute-plan stops (bc-01a11e37: turn mechanics, CI-wait
chat, preflight-only turns).

## Delivery

| # | Owner | Scope | Status |
|---|-------|-------|--------|
| 1 | Claude Code | Architecture + `AGENTS.md` operating rules; slim agent entries; gate I (WARN) | Done (#1869) |
| 2 | Cursor | `.cursor/**` dedupe; execute-plan ≤300 lines; Bugbot retired; gate I → 0 in owned files | In progress |
| 3 | Cursor | Runtime: gate stdout next action; `expired` halt copy; tests | Planned (after 2) |
| 4 | Claude Code | Promote gate I BLOCK; stale plan audit in `docs/agent-efficiency/` | Planned — after 2–3 |
| 5 | Any | Product rules in memory → canonical docs on consolidate | Ongoing |

### Row 2 — Cursor dedupe (PR a)

- Run `node scripts/check_docs_canonical.js --instructions`; **0 findings** in owned paths (see task brief).
- Link don't restate: precedence, when-to-ask, closers, pre-push, docs duty, model → owner map in `agent-instructions.md`.
- `execute-plan-instruction-stack.md`: drop precedence rows now in `AGENTS.md`; keep platform-vs-repo, Cloud turns, Claude Code.
- `agent-core.mdc`: Cursor-only; always-loaded ≤2,400 words.
- Bugbot: delete `.cursor/BUGBOT.md`, `/review-bugbot`; Copilot-first in pr-review-cost-efficiency.md.
- Router: one line re-read `AGENTS.md` §Execute-plan (no override card).
- Word counts before/after in PR body.

### Row 3 — Cursor runtime (PR b)

- Gate exit `0` stdout ends with concrete `next_action` tool step; `/execute-plan` = resume (not permission).
- CI: subscribe/await, tool-only; skill ≤5 lines pointer.
- `approved_until` stays 48h; `expired` halt = re-approve + `resume-plan` only.
- Tests in `execute_plan_runtime.test.js`.
- **Acceptance note:** phase-merge silence is spot-checked on execute-plan runs; repo tests cover gate/halt strings only.
- **Residual risk:** platform testing prompts may still bias to chat proof — mitigated by AGENTS §Execute-plan, not fully repo-enforceable.

## Acceptance

- Gate I: 0 findings in owned files (row 2/3 scope).
- No owned file restates a rule whose home is elsewhere.
- `pre-push-changed.sh` green; `## Docs` on PRs; one outcome per PR.

On row 4 PR: fold into `standards.md` / architecture doc and delete this file.
