---
title: Weight tracking specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,weight_tracking,specs]
---

# Weight tracking specs

## Data model

- Weight entries belong to a pet; stored via server/routes/weightEntries.js.
- Weight is numeric (kg); date is a calendar day on the wire (see /docs/architecture/calendar-dates.md).
- Sort order for history: chronological by entry date.

## Profile integration

- Latest entry drives pet detail current weight and PDF report current weight.
- Editing pet weight on the profile form may create a same-day entry with no notes (see BDD P2 scenarios).

## API & tests

- Jest: server/test/weightEntries.test.js
- BDD: flutter_app/test/bdd/features/weight_tracking.feature
- E2E: e2e/playwright/tests/weight.tracking.spec.ts

---

**Lessons:** [changes/lessons.md](../changes/lessons.md)
