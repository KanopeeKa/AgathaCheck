# Refactoring debt & deferred decisions

Living tracker for modularization work, items parked for human review, and
architectural decisions deferred during the domain-by-domain refactor.

**Related:** `docs/technical-debt.md` (product/infra deferrals) · `docs/architecture/modularity.md` (rules)

**Last updated:** 2026-07-06

---

## How to use

| Put it here | Open a GitHub Issue when |
|---|---|
| Stub code kept pending review | Scope is clear and someone will implement |
| “For later” split not done this pass | Ready to schedule in a sprint |
| Dual-backend parity gaps | Dart server still needed in prod |

**Priority:** P1 critical · P2 high · P3 recommended · P4 for later

---

## Decisions log (2026-07-06)

| # | Topic | Decision | Recommendation |
|---|-------|----------|----------------|
| 1 | `health_entry_form_controller` | **Phase 2 done** (2026-07-06) | Name/dosage/notes in `StateNotifier` state; screen uses bound widgets, no `TextEditingController`s. Further slimming (frequency section extract) optional. |
| 2 | `family_events_controller.dart` | **Keep stub; do not wire** until product rules on legacy family events | See “Family events” section below. |
| 3 | Dart `organization_routes.dart` split | **Yes — done** | `server/lib/organizations/` mirrors Node layout (subset of routes). |
| 4 | `sharing_section.dart` split | **Yes — done** | `widgets/sharing/` with role-specific files + tests. |

---

## In progress (this refactor branch)

| Domain | Status | Notes |
|---|---|---|
| Infrastructure | Done | Debt doc, modularity rules, legacy cleanup |
| Organizations (Node) | Done | `routes/organizations/` + `test/organizations/` |
| Organizations (Dart) | Done | `lib/organizations/` (subset parity) |
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
| Root `lib/` legacy Flutter tree | P1 | Slated for removal from git; confirm no external tooling still points at repo root `pubspec.yaml`. |
| `attached_assets/` | P1 | Replit session dumps; remove from git after confirming team does not rely on them. |
| `npm run test:mocha` | P4 | Legacy runner; remove when team confirms no local scripts use it. |

---

## For later (recommended, not this overnight pass)

| Item | Priority | Effort | Notes |
|---|---|---|---|
| Split `pet_form_screen.dart` submit logic | P3 | Medium | **Done** — `PetFormController.submit()` |
| `organization_providers_test.dart` split | P3 | Small | **Done** — `presentation/providers/*_test.dart` + shared helpers |
| Executable Cucumber BDD | P4 | Medium | Gherkin exists; Playwright is executor today |
| `test_integration/` in CI | P3 | Small | Single flow test; wire or relocate under `test/features/.../integration` |
| Rename `pet_profile_app` package | P4 | Large | Cosmetic; defer until dedicated rename sprint |
| Dart `organization_routes.dart` foster/placements/people parity | P2 | Medium | Node has full routes; Dart has subset only |
| Node-only production backend | P4 | Strategic | Documented in technical-debt; Dart kept for Replit/AOT until decided |
| `dart analyze` on `server/` in CI | P3 | Trivial | Catches Dart route drift vs Node |

---

## Dual backend parity checklist

When changing org (or any) routes in Node, mirror in Dart **same PR** when possible:

- [ ] Route path + HTTP method
- [ ] Auth / role guards
- [ ] Request body validation
- [ ] Response JSON shape
- [ ] Status codes (incl. 501 stubs)
- [ ] Calendar date fields (`YYYY-MM-DD`)

Dart gaps already known (from `technical-debt.md`): audit logging, PostHog delete.

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-06 | Split `server/routes/auth.js` into `routes/auth/` modules. |
| 2026-07-06 | Split `server/routes/pets.js` into `routes/pets/` modules. |
| 2026-07-06 | Split `organization_remote_datasource.dart` into modular remote clients. |
| 2026-07-06 | Split `organization_providers_test.dart` by provider group. |
| 2026-07-06 | Sharing + Dart org splits done; decisions log for controller/family-events. |
| 2026-07-05 | Initial tracker for modularization refactor (`cursor/refactor-modular-domains-b4c2`). |
