---
title: Help & about specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,help_about,specs]
domain: help_about
feature_id: help-about
---

# Help & about

Account help, FAQ, about, and legal surfaces (`help_faq.feature`).

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| **HA-1** | Help reachable from Account; FAQ accordion EN+FR. | delivered |
| **HA-2** | About shows app version and project information. | delivered |
| **HA-3** | Legal copy in assets aligned with FAQ where referenced. | delivered |

## User journeys

### Open Help from user menu

Guardians navigate to the Help page from the account/user menu.

### FAQ accordion

Help displays feature sections as expandable FAQ groups; multiple sections may be open; content available in EN and FR.

### About

About screens present app version and project information (`flutter_app/lib/features/about/`).

## Help / FAQ

- Route: help screen under `flutter_app/lib/features/help/` (accordion FAQ groups).
- Content: EN + FR strings in ARB (`faq*` keys); sections cover pets, health, sharing, subscription, org, etc.
- BDD: `help_faq.feature` — Sprint 6.4 target (+10 scenarios)

## About

- `flutter_app/lib/features/about/` — app version, project information.
- Linked from Account area (D27 global settings, not org-scoped).

## Legal surfaces

User-facing legal text also ships in `flutter_app/assets/legal/` (EN/FR) and `regulatory/` repo docs. Help FAQ must stay aligned when navigation chrome changes (see [changes/deferred.md](../changes/deferred.md)).

## Copy debt

FAQ strings may still reference legacy nav patterns (top-bar bell wording) — update after navigation shell migration completes.

## Localization

FAQ strings live in ARB. When editing enums tied to help copy, follow [.agents/memory/localization-enum-labels.md](/.agents/memory/localization-enum-labels.md).
