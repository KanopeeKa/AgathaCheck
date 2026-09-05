---
name: ui-check
description: >-
  INTERNAL (Tier 3) — superseded by Engineering Router + protocols/accessibility.md
  §Quick pass. Do not user-invoke; Tier 1 skills load accessibility protocol automatically.
paths:
  - flutter_app/lib/**
---

# UI check (internal — Tier 3)

> **Superseded by:** `.cursor/agent-kernel/protocols/accessibility.md` §Quick pass  
> **Framework:** `docs/engineering/cursor-agent-framework.md`

This skill remains for backward compatibility. **Do not invoke manually.**

When Flutter presentation changes, Tier 1 workflows (`/babysit-plus`, `/ui-design-deep`, etc.) run the Router and apply the **accessibility protocol quick pass** instead.

## Quick pass (canonical — copy in protocol)

1. Purpose clear in 5 seconds?
2. Primary action obvious?
3. Labels on inputs; focus visible; touch ≥48dp
4. Theme/`colorScheme` — no ad-hoc colors
5. Empty/loading/error still reasonable?
6. Auth/landing: role-neutral entry if touched

Escalate to `/ui-design-deep` for theme, landing/auth, multi-screen, or `/g/*` + `/o/*` span.

## Verify

```bash
./scripts/pre-push-changed.sh
```
