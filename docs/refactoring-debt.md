# Refactoring debt & deferred decisions

Living tracker for modularization work, items parked for human review, and
architectural decisions deferred during the domain-by-domain refactor.

**Related:** `docs/technical-debt.md` (product/infra deferrals) · `docs/architecture/modularity.md` (rules)

**Last updated:** 2026-07-22

---

## How to use

| Put it here | Open a GitHub Issue when |
|---|---|
| Stub code kept pending review | Scope is clear and someone will implement |
| “For later” split not done this pass | Ready to schedule in a sprint |
| Backend gaps | Node.js server is canonical (`single-backend.mdc`) |

**Priority:** P1 critical · P2 high · P3 recommended · P4 for later

---

## Decisions log (2026-07-06)

| # | Topic | Decision | Recommendation |
|---|-------|----------|----------------|
| 1 | `health_entry_form_controller` | **Phase 2 done** (2026-07-06) | Name/dosage/notes in `StateNotifier` state; screen uses bound widgets, no `TextEditingController`s. Further slimming (frequency section extract) optional. |
| 2 | `family_events_controller.dart` | **Keep stub; do not wire** until product rules on legacy family events | See “Family events” section below. |
| 3 | ~~Dart `organization_routes.dart` split~~ | **Removed** | Dart backend deleted 2026-07-21 (#240); Node `server/routes/organizations/` is canonical. |
| 4 | `sharing_section.dart` split | **Yes — done** | `widgets/sharing/` with role-specific files + tests. |

---

## Completed domains (modularization programme)

| Domain | Status | Notes |
|---|---|---|
| Infrastructure | Done | Debt doc, modularity rules, legacy cleanup |
| Organizations (Node) | Done | `routes/organizations/` + `test/organizations/` |
| Organization provider tests | Done | Split by provider group under `test/.../providers/` |
| Organization remote datasource | Done | `data/datasources/organization_remote/` |
| Pet routes (Node) | Done | `routes/pets/` modular routers |
| Auth routes (Node) | Done | `routes/auth/` session, profile, password |
| Pet profile — pet list | Done | `widgets/pet_list/` |
| Pet profile — sharing | Done | `widgets/sharing/` |
| Pet profile — pet form submit | Done | `PetFormController.submit()` |

---

## Parked for human review (do not delete without sign-off)

| Item | Priority | Notes |
|---|---|---|
| `family_events_controller.dart` | P4 | **Stub — not wired.** Legacy `family_events` table; placement data migrated to `foster_placements` (migration 016). Flutter still has `familyEventsProvider` + PDF section; pets API CRUD exists. **Recommendation:** delete stub; use foster placements for new UI — or revive only if product wants pre-migration family-event editing. |
| `health_entry_form_controller.dart` | P4 | Phase 2 done. Optional: extract frequency/recurrence widgets to slim screen further. |
| Root `lib/` legacy Flutter tree | P1 | **Removed** — root `pubspec.yaml` deleted Sprint 2 |
| Organisation pet timeline — remove event + ending notifications | P3 | Sprint 6.3 defer — no family-event delete UI; org notification cron not wired |
| `subscriptions.feature` E2E (11 scenarios) | P2 | Sprint 7.2 defer — RevenueCat likely replaced; see `docs/technical-debt.md` |
| `attached_assets/` | P1 | **Removed** — was already absent from git |
| `npm run test:mocha` | P4 | Legacy runner; remove when team confirms no local scripts use it. |

---

## For later (recommended, not this overnight pass)

| Item | Priority | Effort | Notes |
|---|---|---|---|
| Split `pet_form_screen.dart` submit logic | P3 | Medium | **Done** — `PetFormController.submit()` |
| `organization_providers_test.dart` split | P3 | Small | **Done** — `presentation/providers/*_test.dart` + shared helpers |
| Executable Cucumber BDD | P4 | Medium | Gherkin exists; Playwright is executor today |
| `test_integration/` in CI | P3 | **Done** | Legacy file removed; canonical flow under `test/features/.../integration/` |
| Rename `pet_profile_app` package | P4 | Large | Cosmetic; defer until dedicated rename sprint |

---

## Node route change checklist

When changing org (or any) routes, add Jest coverage in the same PR (`single-backend.mdc`).

- [ ] Route path + HTTP method
- [ ] Auth / role guards
- [ ] Request body validation
- [ ] Response JSON shape
- [ ] Status codes (incl. 501 stubs)
- [ ] Calendar date fields (`YYYY-MM-DD`)

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-22 | Removed Dart backend audit doc; Node-only route checklist; stale dual-backend debt rows closed (#240). |
| 2026-07-06 | Split `server/routes/auth.js` into `routes/auth/` modules. |
| 2026-07-06 | Split `server/routes/pets.js` into `routes/pets/` modules. |
| 2026-07-06 | Split `organization_remote_datasource.dart` into modular remote clients. |
| 2026-07-06 | Split `organization_providers_test.dart` by provider group. |
| 2026-07-06 | Sharing section split done; decisions log for controller/family-events. |
| 2026-07-05 | Initial tracker for modularization refactor (`cursor/refactor-modular-domains-b4c2`). |
