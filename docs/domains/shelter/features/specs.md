---
title: Organization specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,organization,specs]
---

# Organization specs

## Custody data model

Authoritative reference for guardianship, care, shadows, org connections, and transfer **kinds** (not foster workflow UI):

[org-custody-model.md](org-custody-model.md)

## Member privacy (v3)

Per-org visibility enums, floors, and named grants:

[org-member-privacy.md](org-member-privacy.md)

## Roles and permissions

[org-roles-and-permissions.md](org-roles-and-permissions.md)

## Organisation branding (org experience)

Organisation mode uses the **teal** palette and assets — distinct from guardian plum:

| Concern | Location |
|---------|----------|
| Theme switch | `flutter_app/lib/core/theme/experience_colors.dart` |
| Org primary token | `AppColorTokens.organizationPrimary` in `app_color_tokens.dart` |
| Logo | `flutter_app/assets/logo-teal.png` / `.jpg` via `LogoAssets` |
| Email branding | `server/lib/email/branding.js` (mirror token hex) |

Generic re-skin checklist (all runtimes): [/docs/design/skin-change-guide.md](/docs/design/skin-change-guide.md). **Org-specific colours** are the `organizationPrimary` / teal family and logo-teal assets — do not conflate with guardian `guardianPrimary` plum.

## Pet activity (org sort)

Org pet list last-activity sorting uses the pet_profile product activity model — [/docs/domains/pet_profile/features/pet-activity-model.md](/docs/domains/pet_profile/features/pet-activity-model.md).

---

**Lessons:** [changes/lessons.md](../changes/lessons.md)
