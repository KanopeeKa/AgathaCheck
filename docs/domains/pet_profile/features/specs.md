---
title: Pet profile specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,pet_profile,specs]
domain: pet_profile
---

# Pet profile specs

## Pet activity model (org sort / preview)

Organisation v2 **last-activity sorting** for the 12-pet profile preview uses a product-layer model distinct from compliance audit (`audit_events`) and guardian timeline (`pet_timeline_entries`).

Full specification: [pet-activity-model.md](pet-activity-model.md) (relocated from `docs/architecture/`).

Summary:

| Artifact | Role |
|----------|------|
| `pet_activity_events` | Append-only event log |
| `pets.last_activity_at` | Denormalized column updated in same transaction |

Event types (v1): `health_log`, `foster_session`, `profile_edit`, `document_upload`. Writes go through `server/lib/petActivity.js` → `recordPetActivity()`.

## Pet CRUD validation

- Pets belong to a guardian account; foster pets appear via organisation custody (see organization / fostering domains).
- Calendar dates on the wire use `YYYY-MM-DD` ([/docs/architecture/calendar-dates.md](/docs/architecture/calendar-dates.md)).

## Sharing section on pet detail

Role-specific sharing UI lives under `flutter_app/lib/features/pet_profile/widgets/sharing/` — see sharing domain for share-link semantics.

## Guardian mobile completion

Due-events preview supports reversible mobile completion with transient cache during refresh — see [.agents/memory/guardian-mobile-completion.md](/.agents/memory/guardian-mobile-completion.md).

---

**Plans:** [changes/plans.md](../changes/plans.md)
