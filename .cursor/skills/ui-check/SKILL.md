---
name: ui-check
description: Quick UX and accessibility pass on Flutter UI changes before merge or polish. Use for single-screen edits, widget tweaks, or "does this look right?" — not full redesigns.
paths:
  - flutter_app/lib/**
---

# UI check (light)

## When to use

- Finishing a UI-touching PR
- User asks for a quick UX/a11y sanity check
- One screen or a few widgets changed

**Not for:** theme overhauls, new multi-step flows, or product-wide consistency — use `/ui-design-deep`.

## Escalate to `/ui-design-deep` when any apply

- Editing `app_theme.dart` or adding `tokens.md`
- Auth, landing, onboarding, or experience chooser
- New multi-step wizard or flow
- Changes spanning `/g/*` and `/o/*`
- User asks for redesign, refresh, or brand work
- Starting a phase from `docs/design/ui-rework-plan.md`

## Read first

- `.cursor/rules/design.mdc`
- `.cursor/rules/accessibility.mdc`
- Changed files only

## Steps

1. **Purpose** — Can a user answer in 5 seconds: what is this for, what next?
2. **Hierarchy** — Primary action obvious? Visual noise or competing accents?
3. **A11y spot-check** — labels on inputs, focus visible, touch ≥48dp, not color-only state, icon buttons have tooltips.
4. **Consistency** — Uses `Theme`/`colorScheme`? Matches neighboring screens?
5. **Copy** — Operational text direct; no cute tone in admin/health flows; strings in l10n.
6. **States** — If you touched a list/form/action, are empty/loading/error still reasonable?

## Output (keep short)

```markdown
### UI check — <area>
- **OK:** …
- **Fix now:** … (requirement / small snag)
- **Follow-up:** … (optional, separate PR if non-blocking)
```

Fix **Fix now** items in the same PR when ≤15 lines same file; else note as follow-up per atomic PR policy.

## Verify (if code changed)

```bash
./scripts/pre-push-changed.sh
```
