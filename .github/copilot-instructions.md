# Copilot instructions (Agatha Track)

Shared rules for all agents: [`AGENTS.md`](../AGENTS.md) — operating rules, toolchain, commands, policy index. This
file adds only what Copilot needs; do not restate `AGENTS.md` here (`docs/agent-efficiency/agent-instructions.md`).

## Reviewing a PR

Output for every review: **verdict**, then each finding with comment, required or suggested fix (or possible
improvement), and priority.

Treat as **blocking**:

- A behaviour-changing PR without a canonical doc update or without a `## Docs` section in the body
  (`docs/domains/documentation/standards.md`).
- More than one independent outcome in one PR, or a snag deferred without a tracking issue
  (`docs/agent-efficiency/atomic-pr-policy.md`).
- Raw exception text in a production 5xx body, unvalidated uploads, missing rate limits on DB/filesystem routes
  (`.cursor/rules/security.mdc`).
- Hand-written files over 500 lines (`node scripts/check_file_size.js`); backend logic outside Node.js `server/`.
- Wire dates that are not calendar days `YYYY-MM-DD` (`docs/architecture/calendar-dates.md`).

Label everything else `nit` or `suggestion` so authors can triage by label.

## Coding agent

Follow `AGENTS.md`. Verify with `./scripts/pre-push-changed.sh` before each push; one validated push per logical fix.
