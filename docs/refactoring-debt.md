# Refactoring debt & deferred decisions

Living tracker for modularization work, items parked for human review, and
architectural decisions deferred during the domain-by-domain refactor.

**Related:** `docs/technical-debt.md` (product/infra deferrals) · `docs/architecture/modularity.md` (rules)

**Last updated:** 2026-07-05

---

## How to use

| Put it here | Open a GitHub Issue when |
|---|---|
| Stub code kept pending review | Scope is clear and someone will implement |
| “For later” split not done this pass | Ready to schedule in a sprint |
| Dual-backend parity gaps | Dart server still needed in prod |

**Priority:** P1 critical · P2 high · P3 recommended · P4 for later

---

## In progress (this refactor branch)

| Domain | Status | Notes |
|---|---|---|
| Infrastructure | In progress | Debt doc, modularity rules, legacy cleanup |
| Organizations (backend) | Done | Split `routes/organizations/` + `test/organizations/` |
| Pet profile (Flutter) | Done | Extracted `widgets/pet_list/` from `pet_list_screen` |
| Health tracking (Flutter) | Partial | Widget extraction done; controller wiring pending review |

---

## Parked for human review (do not delete without sign-off)

| Item | Priority | Notes |
|---|---|---|
| `family_events_controller.dart` | P4 | Stub; family-events API returns 501 / empty lists. **Keep** until product confirms removal vs implementation. |
| `health_entry_form_controller.dart` | P2 | Was a stub; refactor wires it incrementally. Review partial migration before deleting screen state. |
| Root `lib/` legacy Flutter tree | P1 | Slated for removal from git; confirm no external tooling still points at repo root `pubspec.yaml`. |
| `attached_assets/` | P1 | Replit session dumps; remove from git after confirming team does not rely on them. |
| `npm run test:mocha` | P4 | Legacy runner; remove when team confirms no local scripts use it. |

---

## For later (recommended, not this overnight pass)

| Item | Priority | Effort | Notes |
|---|---|---|---|
| Split `server/routes/pets.js` (~997 lines) | P2 | Medium | Sub-routers for weight hooks, passed-away, org transfer |
| Split `server/routes/auth.js` (~520 lines) | P3 | Small | Password-reset vs session routes |
| Split `organization_remote_datasource.dart` | P2 | Medium | Members, placements, foster parents |
| Split `sharing_section.dart` | P2 | Medium | Role-specific content widgets |
| Split `pet_form_screen.dart` submit logic | P3 | Medium | Move into `PetFormController` / notifier |
| `organization_providers_test.dart` split | P3 | Small | One file per provider group |
| Executable Cucumber BDD | P4 | Medium | Gherkin exists; Playwright is executor today |
| `test_integration/` in CI | P3 | Small | Single flow test; wire or relocate under `test/features/.../integration` |
| Rename `pet_profile_app` package | P4 | Large | Cosmetic; defer until dedicated rename sprint |
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
| 2026-07-05 | Initial tracker for modularization refactor (`cursor/refactor-modular-domains-b4c2`). |
