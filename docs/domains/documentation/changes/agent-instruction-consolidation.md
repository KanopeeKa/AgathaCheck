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
| 2 | Cursor | `.cursor/**` dedupe; execute-plan ≤300 lines; Bugbot retired; gate I → 0 in owned files | Done (#1870) |
| 3 | Cursor | Runtime: gate stdout next action; `expired` halt copy; tests | Done (#1872) |
| 4 | Claude Code | Promote gate I BLOCK; stale plan audit in `docs/agent-efficiency/` | Planned — after 2–3 |
| 5 | Any | Product rules in memory → canonical docs on consolidate | Ongoing |

### Row 2 — Cursor dedupe (PR a)

See #1870. Gate I 0 in owned paths; link don't restate per `agent-instructions.md` owner map.

### Row 3 — Cursor runtime (PR b)

- Gate exit `0`: JSON `next_action` / `agent_next_step` + stdout `NEXT:` line (concrete tool step).
- Gate `expired`: stdout `UNBLOCK:` with `approve-autonomous` + `resume-plan` only.
- `halt --reason expired` comment matches unblock copy.
- Tests in `execute_plan_runtime.test.js`.
- **Acceptance note:** phase-merge silence is spot-checked on execute-plan runs; repo tests cover gate/halt strings only.
- **Residual risk:** platform testing prompts may still bias to chat proof — not fully repo-enforceable.

## Acceptance

- `node scripts/check_docs_canonical.js --instructions` reports 0 findings (then promoted to BLOCK).
- No instruction file restates a rule whose home is elsewhere (owner map in the architecture doc).
- Execute-plan gate `0` + runtime tests; phase-merge chat silence validated by spot runs (not CI).

On row 4 PR: fold into `standards.md` / architecture doc and delete this file.
