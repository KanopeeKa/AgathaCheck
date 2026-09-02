---
title: Copy tone and Shelter branding
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-02
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

## Shelter branding

Shelters may customize **logo, name, and photo** via
`organization_branding_section.dart` and related APIs. Technical
`organization` identifiers remain unchanged until a dedicated migration.

**Shelters must not override (system-locked):**

- Error, warning, success, and danger colors
- Focus indicators and focus visibility
- Minimum text contrast on surfaces
- Destructive-action styling (delete buttons, confirm dialogs)

**Accent:** org-specific tints may appear on avatars, chips, or headers only where the feature already supports it. If an org color fails WCAG AA contrast on its surface, fall back to `colorScheme` tokens.

**Rule:** one product — Shelter branding personalizes identity, not the interaction system.

## Pet Care workspace naming (D38)

Three labels must stay distinct in copy and l10n:

| Surface | EN | FR | ARB keys (target) |
|---------|----|----|-------------------|
| Workspace | Pet Care | Suivi | `drawerPetCare`, `experiencePetCareView`, … |
| Dashboard pet rail | My Pets | Mes animaux | `myPets` — **do not repurpose for workspace** |
| Due-items block | CARE ACTIONS (eyebrow) | SOINS | `careActionsEyebrow` or `careEyebrow` |
| Full due list link | All Actions | Tous les soins | `allActions` |
| Bottom nav | Actions | Soins | `actionsNavLabel` |

Custody **guardianship** in legal/org docs is not the Pet Care workspace. See [pet_care README](/docs/domains/pet_care/README.md).
