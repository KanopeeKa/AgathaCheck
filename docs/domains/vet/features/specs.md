---
title: Veterinarian specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,vet,specs]
domain: vet
---

# Veterinarian specs

## Data model

- Vet records are user-scoped contacts (server/routes/vets.js).
- Required field: name. Optional: phone, email, address, notes.
- Pets link to a vet; list UI shows linked pet names on cards.

## Validation & edge cases

- Calendar dates on the wire use `YYYY-MM-DD` — same rules as weight/health entries ([/docs/architecture/calendar-dates.md](/docs/architecture/calendar-dates.md)).
- Empty list shows a no-vets prompt.
- Delete is destructive after confirmation; cancel preserves the record.
- Shared pet views may show linked vet in veterinarian section (sharing.feature).

## API & tests

- Jest: server/test/vets.test.js
- BDD: flutter_app/test/bdd/features/veterinarian_management.feature
- No dedicated Playwright spec today (BDD coverage via Flutter/integration paths).

---

**Plans:** [changes/plans.md](../changes/plans.md)
