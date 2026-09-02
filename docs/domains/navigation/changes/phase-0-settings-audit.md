---
title: Phase 0 — Settings content audit (Q3)
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 0 — Settings content audit (Q3)

**Status:** Sprint 0.1 deliverable · resolves program-contract Q3  
**Parent:** [`phase-0-foundation.md`](phase-0-foundation.md)

Maps every settings row today to its **Phase 1+ destination** per decisions D25–D27.

## Destination buckets

| Bucket | Meaning |
|--------|---------|
| **Account** | Global personal preferences — lives on `/account` after Phase 1 |
| **Org edit** | Super-admin org customisation — org edit / Phase 5 customisations |
| **Self-card** | Per-org membership prefs on Admin Contacts self-card (Phase 3/4) |

## `/g/settings` and `/o/settings` — `ExperienceSettingsScreen`

| Row / section | Current location | Destination | Notes |
|---------------|------------------|-------------|-------|
| Default experience (Pet Care / Shelter radio) | `ExperienceSettingsSection` | **Account** | Cross-org personal preference (D25) |
| My Details → `/my-details` | `ListTile` on settings screen | **Account** | Profile entry; screen content audited below |

## `/my-details` — `MyDetailsScreen`

| Row / section | Widget | Destination | Notes |
|---------------|--------|-------------|-------|
| Profile header + editor | `ProfileHeaderCard` / `ProfileEditorSheet` | **Account** | Name, photo, bio |
| Default experience (duplicate) | `ExperienceSettingsSection` | **Account** | Same as above — consolidate to Account only in Phase 1 |
| Subscription / premium | `ProfileSettingsSection` | **Account** | Personal billing |
| My organisations list | `ProfileSettingsSection` | **Account** | Navigation hub; not org customisation |
| Language | `ProfileSettingsSection` | **Account** | Global locale |
| Change password | `ChangePasswordForm` | **Account** | |
| Export data / delete account | `AccountActionsSection` | **Account** | |

## Not on settings screens today (Phase 3+ targets)

| Concern | Destination | Phase |
|---------|-------------|-------|
| Org branding, discoverability, legal identifiers | **Org edit** | 3 |
| Document template admin | **Org edit** | 5 (`manage_document_templates`) |
| Admin contact visibility / message channel | **Self-card** | 3 |
| Foster self-management prefs | **Self-card** | 4 |

## Phase 1 routing actions

1. Retire `/g/settings` and `/o/settings` routes; move Account bucket rows to `/account`.
2. Remove duplicate `ExperienceSettingsSection` from one entry point (keep single Account copy).
3. Do **not** move org-scoped rows onto Account — they land on org edit or self-card in later phases.

## Open items

None — audit complete for Phase 0 exit.
