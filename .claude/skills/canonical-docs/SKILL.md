---
name: canonical-docs
description: Keep canonical feature docs current. Use when a change alters product behaviour, when a spec, decision or behaviour change is written or agreed, when delivery of a docs/domains/*/changes/ doc finishes, or when the user asks to consolidate docs (`/canonical-docs sync` or `/canonical-docs consolidate <domain>/<capability>`).
---

# Canonical docs (Claude Code wrapper)

Read and follow `.cursor/skills/canonical-docs/SKILL.md`:

- **Mode A `sync`** — every behaviour-changing commit/push, before `./scripts/pre-push-changed.sh`.
- **Mode B `consolidate <domain>/<capability>`** — only when asked; one capability per PR.

Policy: `docs/domains/documentation/standards.md`.

This file is a pointer only. Do not copy the procedure here.

## Claude Code adaptations

- Cursor mechanics named in the procedure (`ManagePullRequest`, babysit-plus,
  merge) map to Claude Code's own PR flow; the steps and their order do not change.
- **Subagents:** when delegating, the brief names the canonical doc(s) and
  requires "run canonical-docs sync before handing back".
