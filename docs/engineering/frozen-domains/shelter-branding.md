---
title: Shelter org branding (frozen domain)
owner: Documentation Team
audience: both
status: frozen
last_updated: 2026-09-09
tags: [engineering, frozen-domains, shelter, branding]
---

# Shelter org branding (frozen domain)

**Status:** Frozen — preserved for rehydration, not part of active Pet Care brand or tone.

Active product voice, terminology, and copy rules live in:

- [`docs/design/true-north.md`](../../design/true-north.md)
- [`docs/design/copy-tone.md`](../../design/copy-tone.md)
- [`docs/design/terminology.md`](../../design/terminology.md)

## Scope (when Shelter is rehydrated)

Shelters may customize **logo, name, and photo** via
`organization_branding_section.dart` and related APIs. Technical
`organization` identifiers remain unchanged until a dedicated migration.

## System-locked (must not override)

- Error, warning, success, and danger colors
- Focus indicators and focus visibility
- Minimum text contrast on surfaces
- Destructive-action styling (delete buttons, confirm dialogs)

## Accent

Org-specific tints may appear on avatars, chips, or headers only where the feature already supports it. If an org color fails WCAG AA contrast on its surface, fall back to `colorScheme` tokens.

## Rule

One product — Shelter branding personalizes identity, not the interaction system.

## Rehydration

See [`rehydration-runbook.md`](./rehydration-runbook.md) before reactivating Shelter UI or branding flows.
