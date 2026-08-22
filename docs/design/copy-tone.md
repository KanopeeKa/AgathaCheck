---
title: Copy tone and org branding
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-21
tags: [design,ui,ux]
---
# Copy tone and org branding

Everyday UI work: follow the bullets in `design.mdc`. Use this file for `/ui-design-deep` or copy/branding tasks.

## Tone

| Context | Do | Don't |
|---------|-----|-------|
| **Operational** (forms, deletes, errors, schedules) | Direct, specific, calm | Puns, emoji, pet jokes, vague startup-speak |
| **Supportive** (onboarding, empty states, confirmations) | Warm, brief, reassuring | Cute, childish, emotionally manipulative |
| **Status** (overdue, success) | Plain labels | Anthropomorphic panic (“Uh-oh!”) |

### Examples (from `app_en.arb`)

| Key | Good (keep this register) | Bad (do not introduce) |
|-----|---------------------------|-------------------------|
| `deleteEntryConfirm` | “Are you sure you want to delete this entry?” | “Oops! Say goodbye to this entry 🐾” |
| `noPetsYet` | “No pets yet” | “Your fur family is waiting to be discovered!” |
| `overdue` | “Overdue” | “Uh-oh, someone's behind!” |
| `appTagline` | Calm, purpose-led (see ARB) | Exclamation-heavy marketing hype |

All user-facing strings belong in ARB/l10n. Localize enum `.label` when touched — `.agents/memory/localization-enum-labels.md`.

## AgathaTrack landing/auth copy

- Use **AgathaTrack** as the current product name. **AgathaCheck** is legacy
  wording and must not be introduced in new UI or design work.
- The landing page speaks to a shared care desk: calm, practical, and
  reassuring without being cute.
- Shelter/foster-team language may establish the product context, for example:
  “For shelters and foster teams, every handover and next step stays close at
  hand.”
- Keep the login path universal. Do not ask users to choose “pet guardian,”
  “shelter,” or “organisation” before signing in. That context belongs inside
  the authenticated experience.
- Prefer short supporting copy over feature lists or role-based marketing
  gates. The form should make the next action obvious: sign in or create an
  account.

## Org branding

Orgs may customize **logo, name, and photo** via `organization_branding_section.dart` and related APIs.

**Orgs must not override (system-locked):**

- Error, warning, success, and danger colors
- Focus indicators and focus visibility
- Minimum text contrast on surfaces
- Destructive-action styling (delete buttons, confirm dialogs)

**Accent:** org-specific tints may appear on avatars, chips, or headers only where the feature already supports it. If an org color fails WCAG AA contrast on its surface, fall back to `colorScheme` tokens.

**Rule:** one product — org branding personalizes identity, not the interaction system.
