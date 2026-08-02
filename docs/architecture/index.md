# Architecture index (agent quick-reference)

Thin map for agents — read this **before** broad codebase search.  
Full conventions: `docs/architecture/modularity.md`.

---

## Stack

| Layer | Path | Notes |
|-------|------|-------|
| Flutter UI | `flutter_app/lib/features/<feature>/` | Riverpod, go_router |
| Flutter tests | `flutter_app/test/features/<feature>/` | Mirror `lib/` structure |
| Node API (canonical) | `server/routes/<domain>/` | Express, Jest |
| Node tests | `server/test/<domain>/` | supertest + mock pool |
| BDD specs | `flutter_app/test/bdd/features/*.feature` | Gherkin, not executed directly |
| Playwright E2E | `e2e/playwright/tests/*.spec.ts` | `@bdd` header links scenarios |
| Page objects | `e2e/playwright/pages/` | Reusable UI vocabulary |
| E2E API helpers | `e2e/playwright/support/api.ts` | **Serialize edits** across agents |
| Governance scripts | `scripts/` | file size, BDD gate, priority tags |
| Calendar dates | `docs/calendar-dates.md` | `YYYY-MM-DD` wire format |
| Design / UX | `docs/design/index.md` | Tiers, `ui-rework-plan.md`, `/ui-check`, `/ui-design-deep` |
| Experience program (nav reversal, Guardian/Org rework) | `docs/experience-program/` | **Active** — supersedes `docs/design/navigation-v2.md`; read `decisions-log.md` first |

---

## Domain map

### Authentication & profile

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/auth/` |
| Node routes | `server/routes/auth/` |
| Jest | `server/test/auth/` |
| BDD | `authentication.feature` |
| E2E | `auth.login.spec.ts`, `auth.signup.spec.ts`, `auth.profile.spec.ts` |

### Pet profiles

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/pet_profile/` |
| Node routes | `server/routes/pets/` |
| Jest | `server/test/pets/` |
| BDD | `pet_profiles.feature` |
| E2E | `pet.profiles.spec.ts` |

### Health tracking

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/health_tracking/` |
| Node routes | `server/routes/healthEntries/`, `healthIssues.js` |
| Jest | `healthEntries.test.js`, `healthIssues.test.js` |
| BDD | `health_tracking.feature` |
| E2E | `health.tracking.spec.ts` |

**Semantics:** `.agents/memory/health-entry-completion.md` — completion from `next_due_date`.

### Weight tracking

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/weight_tracking/` |
| Node routes | `server/routes/weightEntries.js` |
| Jest | `weightEntries.test.js` |
| BDD | `weight_tracking.feature` |
| E2E | `weight.tracking.spec.ts` |

### Veterinarians

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/vet/` |
| Node routes | `server/routes/vets.js` |
| Jest | `vets.test.js` |
| BDD | `veterinarian_management.feature` |

### Sharing

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/sharing/` |
| Node routes | `server/routes/sharing.js` |
| Jest | `sharing.test.js`, `sharedPetAccess.test.js` |
| BDD | `sharing.feature` |
| E2E | `sharing.spec.ts` |

### Notifications

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/notifications/` |
| Node routes | `server/routes/notifications.js` |
| Jest | `notifications.test.js` |
| BDD | `notifications.feature` |
| E2E | `notifications.spec.ts` |

### Organization (incl. foster, custody, adoption)

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/organization/` |
| Node routes | `server/routes/organizations/`, `fosterPlacements.js`, `custodyTransfers.js` |
| Jest | `server/test/organizations/`, `fosterPlacements.test.js`, `custodyTransfers.test.js`, `orgConnections.test.js` |
| Architecture | `docs/architecture/org-custody-model.md`, `docs/fostering-platform/g0-contract-pack.md`, `docs/experience-program/phase-3-organisation-presentation.md` (presentation/access-control rework, active), **`docs/experience-program/organisation-v2-delivery-plan.md`** (v2 profile composer — active), **`docs/architecture/pet-activity-model.md`** |
| BDD | `organisation_management.feature`, `organisation_pet_management.feature`, `pet_ownership_and_adoption.feature`, … |
| E2E | `organisation.management.spec.ts`, `adoption.spec.ts` |

**Validation:** `.agents/memory/body-supplied-org-id-validation.md`

### Subscription

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/subscription/` |
| BDD | `subscriptions.feature` |
| E2E | — (UAT RevenueCat sandbox required) |

### Help & about

| | Path |
|---|------|
| Flutter | `flutter_app/lib/features/help/`, `about/` |
| BDD | `help_faq.feature` |

### Cross-cutting Flutter core

| Concern | Path |
|---------|------|
| Router | `flutter_app/lib/core/router/` |
| API base URL | `flutter_app/lib/core/providers/api_base_url_provider.dart` |
| Auth HTTP (refresh) | `authHttpClientProvider` — see `.agents/memory/auth-token-refresh.md` |
| Calendar dates | `flutter_app/lib/core/utils/calendar_date.dart` |
| l10n | `flutter_app/lib/l10n/` — enum `.label` getters too (memory: localization-enum-labels) |

### Cross-cutting server

| Concern | Path |
|---------|------|
| Security / errors | `server/config/security.js` |
| Rate limits | `server/config/rateLimit.js` |
| Uploads | `server/lib/safeUpload.js` |
| GDPR export | `server/lib/gdprUserExport.js` |
| Calendar dates | `server/lib/calendarDate.js` |

---

## Agent workflow shortcuts

| Task | Start here |
|------|------------|
| Split a screen | `/split-flutter-screen` skill |
| New API endpoint | `/single-backend-route-change` skill |
| BDD → Playwright | `/add-bdd-playwright-scenario` skill |
| Parallel sprint | `/spawn-sprint-agents` skill |
| Before push | `/pre-push-verify` skill or `./scripts/pre-push-changed.sh` |
| UI review / theme rework | `docs/design/index.md` · `/ui-check` · `/ui-design-deep` · `docs/design/ui-rework-plan.md` |
| Security audit | `/security-error-audit` skill |
| UAT deploy / live smoke red | `docs/e2e/uat-live-operations-runbook.md` · `docs/e2e/uat-waf-queue-lessons.md` · `.agents/memory/uat-live-e2e-triage.md` |
