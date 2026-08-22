---
title: Help & about specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,help_about,specs]
---

# Help & about specs

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
