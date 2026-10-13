---
name: steward
description: Repo conventions for pull requests Claude Code opens or drives in AgathaCheck (pre-PR order, docs gate before every push, review triage pointers).
---

# Steward (Claude Code PR conventions)

Pointer-only. Do not copy procedures from the files linked here.

## Pre-PR order

`.cursor/rules/pr-hygiene.mdc` §Pre-PR critical self-review:
correctness → risks → design → better solution → **documentation sync**
(`/canonical-docs sync`) → verification (`./scripts/pre-push-changed.sh`).

## Before every push

On any PR Claude opened or drives, confirm the **Docs gate** in
`docs/agent-efficiency/phase-exit-checklists.md` (`default` profile) holds for
the current diff.

## Docs findings are blocking

On a behaviour-changing PR, a review comment or Copilot thread about a missing
or stale canonical doc update, or a missing `## Docs` section, is **blocking**
— even when the reviewer labels it nit, minor or optional. Fix it in the next
push; never defer it to a debt issue.

## Everything else

- Triage and debt conventions: `docs/agent-efficiency/autonomous-pr-policy.md`.
- Cursor-only mechanics do not apply to Claude Code (see `CLAUDE.md` §Claude Code mechanics).
- Merging: `AGENTS.md` §Autonomy and merging — when the user asked you to merge
  or babysit the PR, or execute-plan gate exits `0`; squash once merge gates pass
  (CI green, no open review thread).
