---
title: Care Through Change — Delivery Plan
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-09
tags: [pet_care, care_context, delivery]
---

# Care Through Change — Delivery Plan

**Canonical product behaviour:** [care-context.md](../features/care-context.md)  
**Execute-plan:** `.agents/plans/care-through-change-v1.md`

## Programme goal

Prove: *AgathaTrack can understand a declared change in real life and quietly help existing care continue through it — while being honest about what it knows and what it cannot yet know.*

## Shipping gates

1. Projection and coverage fixtures green before reassurance copy ships.
2. Zero projected items may only mean “nothing scheduled” when projection completeness is proven.
3. CC-1 … CC-4 as **separate atomic PRs** (integration branch batch, one final PR to `main`).

## Merge prerequisites

| PR | When |
|----|------|
| #1107 (dependabot batch) | **Done** — all branches rebase onto `main` @ `8e50b42b`+ |
| #1108 (copy-tone / True North docs) | Before **CC-4** user-facing copy and final integration→`main` |

## Implementation sequence

```text
CC-1  Planned absence persistence + canonical docs (no care claims)
CC-2  Server-authoritative care-period projection + certainty + corpus tests
CC-3  Coverage / reassurance policy + policy tests
CC-4  Flutter preview → optional save; per-pet presentation
      → STOP and evaluate
```

Integration branch: `cursor/care-through-change-v1-integration-6605`

## CC-1 — Planned absence fact

- Migration `060_planned_absences.sql`
- `server/routes/careContext/` CRUD (declarer-scoped)
- Overlap warning on save (non-blocking)
- Minimal Flutter: list/create/edit/cancel (no projection UI yet)
- Tests: auth, privacy, overlap, list filter

## CC-2 — Care-period projection

- `projectCareForPeriod` in care_planning layer
- Per-rhythm certainty boundary (`from_completion` default)
- `GET /api/pets/:petId/care-period-projection?starts_on&ends_on`
- 30-case fixture corpus (see care-context.md)
- **No Flutter reassurance copy**

## CC-3 — Coverage policy

- `CarePeriodCoveragePolicy` server evaluator
- Distinct projection completeness vs coverage states
- Policy version + reason codes
- Tests before any reassuring UI

## CC-4 — Care-for-dates UX

- Flow: dates → pets → **preview** → optional save
- Per-pet sections; no global reassurance
- Copy per merged `docs/design/copy-tone.md` (#1108)
- Pull-only; no dashboard slot / notifications

## Supersedes

Care Foundation roadmap appendix “Seasonal Care” remains deferred; environmental context is a future Care Context provider, not V1.
