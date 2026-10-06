---
name: steward
description: Repo conventions for pull requests Claude Code opens or drives in AgathaCheck (pre-PR order, docs gate before every push, review triage pointers).
---

# Steward (Claude Code PR conventions)

Pointer-only. Do not copy procedures from the files linked here.

## Pre-PR order

Same order as `.cursor/skills/babysit-plus/SKILL.md` §Pre-PR critical review:
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
- Cursor-only mechanics do not apply to Claude Code: the `composer-2.5` model,
  `ManagePullRequest`, merging, and merge-lease scripts. Claude Code never merges.
