# AgathaTrack experience split — implementation plan

**Branch:** `cursor/experience-split-17a0`  
**Status:** In progress (Phase 2 complete; Phase 3 next)  
**Last updated:** 2026-07-15

Product decisions are locked in planning conversations. This document is the **execution tracker** for agents and humans.

---

## Terminology (three layers)

| Layer | Examples |
|-------|----------|
| **Responsibilities** | Legal guardianship · Care responsibilities |
| **Pet role** | Pet guardian · Shared carer · Foster carer · Organisation (entity) |
| **Org permissions** | Super-admin · Admin · Viewer (foster portal = limited org access) |

See role table in planning notes; BDD scenarios tag `@pet-role` / `@org-permission` where relevant.

---

## Architecture layers

```
experience/          Shells, chooser, redirects, preferences (NEW)
pet_profile/         Shared pet record (context-aware actions later)
health_tracking/     Shared events
organization/        Org workflows (foster, adoption, transfer)
sharing/             Secondary carers, invites
```

**URL namespaces**

| Prefix | Experience |
|--------|------------|
| `/g/*` | Individual pet guardian |
| `/o/*` | Shelter / organisation |
| `/b/*` | Pet boarding (reserved, disabled) |
| `/app/choose` | Post-login experience chooser |

Legacy routes redirect for one release cycle.

---

## Navigation (locked)

Both shells use **top nav**:

```
☰ Settings drawer  |  Home  |  Events
```

- **Events:** calendar default, list toggle
- **Drawer:** Settings, Notifications, Upcoming events, Invite, About, Contact, experience switch
- **Dual-role users:** drawer shows Org view / Pet guardian view

---

## Experience chooser rules

| User | Chooser |
|------|---------|
| Guardian only (no org membership) | Skip → `/g/home` |
| Org only (member, no guardian context) | Skip → `/o/home` |
| Both | `/app/choose` with remember tick + info box |

**Remember my choice:** persisted; changeable in Settings → Default experience.

---

## Incremental phases

### Phase 1 — Foundation (done)

**Goal:** Chooser, shells, routes, preferences, drawer switch, BDD + tests.

| ID | Deliverable | BDD / tests |
|----|-------------|-------------|
| 1.1 | `AppExperience` enum + eligibility service | Unit tests |
| 1.2 | Preferences store (remember + default) | Unit tests |
| 1.3 | Experience chooser screen | Widget + BDD |
| 1.4 | Guardian shell `/g/*` + top nav + drawer | Widget + BDD |
| 1.5 | Org shell `/o/*` + top nav + drawer | Widget + BDD |
| 1.6 | Post-login redirect logic | Unit + router tests |
| 1.7 | Settings → Default experience | Widget + BDD |
| 1.8 | Legacy route redirects (`/` → resolved home) | E2E smoke update |
| 1.9 | Playwright page objects + `experience_navigation.feature` | E2E |

**Exit criteria:** Guardian-only login lands on `/g/home`; dual-user sees chooser; remember works; drawer switches shells.

### Phase 2 — Split home content (done)

| ID | Deliverable | Status |
|----|-------------|--------|
| 2.1 | Guardian home: due events + My Pets + Shared/Fostered sections (no org inventory) | Done |
| 2.2 | Group shared pets by sharer/org label (`guardian_name` API + grouping) | Done |
| 2.3 | Org home: per-org sections + org-only event filter | Done |
| 2.4 | Inline event actions on home due-event cards | Done |
| 2.5 | Remove org icon from old guardian chrome | Done (Phase 1 shell) |

**Exit criteria:** `/g/home` shows grouped guardian content; `/o/home` shows org inventory; `/g/events` and `/o/events` scope pets correctly.

### Phase 3 — Pet detail context (next)

| ID | Deliverable |
|----|-------------|
| 3.1 | `PetDetailActions` registry by experience + pet role |
| 3.2 | Responsibility labels on pet header |
| 3.3 | Foster role-filtered drawer |

### Phase 4 — Onboarding wizards

| ID | Deliverable |
|----|-------------|
| 4.1 | Guardian onboarding (pet + first reminder) |
| 4.2 | Org super-admin onboarding |
| 4.3 | Invited admin / foster flows |

### Phase 5 — Org operations (paperwork & permissions)

| ID | Deliverable |
|----|-------------|
| 5.1 | Configurable admin capabilities |
| 5.2 | Paperwork templates (foster / adoption) |
| 5.3 | Foster & adopter fitness checklists |
| 5.4 | Pet intake checklist + pending guardianship |
| 5.5 | Adopter / viewer pet-scoped journeys |

### Phase 6 — Notifications & polish

| ID | Deliverable |
|----|-------------|
| 6.1 | Snooze / Mark done from notification rows |
| 6.2 | Org connection accept = connected (no second confirm) |
| 6.3 | Failed adoption explicit UX |
| 6.4 | Deprecate legacy routes |

---

## User stories backlog (by phase)

### Phase 1 (implementing now)

- **E1a** Guardian-only user skips chooser → `/g/home`
- **E1b** Org-only user skips chooser → `/o/home`
- **E1c** Dual user sees both cards + boarding disabled
- **E2** Remember choice + info box under tick
- **E2a** Settings → Default experience
- **E5** Drawer Org view / Pet guardian view

### Phase 2+

See planning doc user story tables (G1–G5, O1–O9, F1–F10, A1–A7, etc.).

---

## BDD feature files

| Feature | Phase |
|---------|-------|
| `experience_navigation.feature` | 1 |
| `authentication.feature` (update post-login destination) | 1 |
| `pet_profiles.feature` (guardian home paths) | 2 |
| `organisation_management.feature` (org shell paths) | 2 |

---

## Test strategy

1. **TDD:** unit tests for eligibility + preferences before UI
2. **Widget tests:** chooser, shell, settings tile
3. **BDD:** Gherkin scenario titles must match Playwright `@bdd` headers exactly
4. **E2E:** update `pet-list.page.ts` for `/g/home`; add `experience.page.ts`
5. **Pre-push:** `./scripts/pre-push-changed.sh` each iteration; full before merge PR

---

## File ownership (this branch)

| Path | Agent |
|------|-------|
| `docs/experience-split-plan.md` | experience-split |
| `flutter_app/lib/features/experience/**` | experience-split |
| `flutter_app/lib/core/router/**` | experience-split |
| `flutter_app/test/bdd/features/experience_navigation.feature` | experience-split |
| `e2e/playwright/pages/experience.page.ts` | experience-split |
| `e2e/playwright/tests/experience.navigation.spec.ts` | experience-split |

---

## Progress log

| Date | Phase | Notes |
|------|-------|-------|
| 2026-07-15 | 1 | Branch created; plan doc; Phase 1 foundation implemented |
| 2026-07-15 | 2 | Guardian/org shell home widgets; `guardian_name` on `/pets/all`; scoped events dashboard; inline due-event actions; controller grouping tests |
