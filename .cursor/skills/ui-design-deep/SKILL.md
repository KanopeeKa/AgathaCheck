---
name: ui-design-deep
description: In-depth UX, accessibility, and design-system review for new flows, landing/auth refresh, theme changes, or multi-screen consistency. Use when /ui-check is not enough.
paths:
  - flutter_app/lib/**
  - docs/design/**
---

# UI design deep

## When to use

- New or redesigned user flow (onboarding, wizard, dashboard)
- Theme / token / palette work
- Multi-screen visual or interaction consistency
- User explicitly requests design direction or UI refactor planning

**Not for:** routine widget fixes — use `/ui-check` or everyday `design.mdc` only.

## Read first

1. `docs/design/index.md` — tier and refactor phases
2. `docs/design/principles.md` — personality, palette target, layout
3. `docs/experience-split-plan.md` — if guardian/org/foster context matters
4. `flutter_app/lib/core/theme/app_theme.dart`
5. `.cursor/rules/design.mdc` + `accessibility.mdc`
6. Screens/widgets under review

## Steps

### 1. Scope

- Routes, `AppExperience`, and shared components affected
- Current vs target (do not assume sage/coral palette is live)

### 2. Audits (brief bullets each)

- **UX** — confusion, weak hierarchy, friction, missing states
- **A11y** — contrast, semantics, keyboard/focus, touch, forms, motion
- **Design** — token drift, spacing rhythm, off-brand tone

### 3. System first

Propose in order: **rule → component pattern → screen → flow → implementation**

Prefer theme/shared widget changes over one-off screen styling.

### 4. Phased rollout (refactors)

Follow `docs/design/index.md` phases. One atomic PR per phase unless user bundles explicitly.

### 5. Output

Use the 9-part structure from `docs/design/principles.md`. Mark items requirement / recommendation / preference.

Include an **acceptance checklist**:

- [ ] Theme tokens, not scattered colors
- [ ] Focus visible; touch ≥48dp
- [ ] l10n / enum labels
- [ ] Empty, loading, error considered
- [ ] Experience context (`/g/*` vs `/o/*`) respected
- [ ] `pre-push-changed.sh` or full pre-push as appropriate
- [ ] E2E/BDD if journey changed

## Verify (when implementing)

```bash
node scripts/check_file_size.js
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
./scripts/pre-push-changed.sh
```
