---
title: Architecture index
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-06
tags: [architecture, index]
---
# Architecture index (agent quick-reference)

Thin map for agents — read this **before** broad codebase search.  
Full conventions: `docs/architecture/modularity.md`.  
**Accepted architecture review (2026-09-22):** [active-codebase-review.md](reviews/active-codebase-review.md) — integrity fixes, module contracts, and delivery batches A → B → C.  
**Architecture decisions (ADR):** [decisions/README.md](decisions/README.md) — [0001](decisions/0001-account-erasure-acceptance.md) erasure · [0002](decisions/0002-feature-layering.md) Flutter layering · [0003](decisions/0003-transaction-ownership.md) transactions · [0004](decisions/0004-cleanup-jobs.md) cleanup jobs · [0005](decisions/0005-canonical-health-state-care-schedule-controller.md) health store · [0006](decisions/0006-frozen-data-compatibility-seam.md) frozen seam · [0007](decisions/0007-pet-cache-freshness.md) pet cache.

**Contracts and baselines:** [api-reference.md](api-reference.md) · [OpenAPI pet-care subset](openapi/pet-care-critical.json) · [active codebase baseline](../engineering/active-codebase-baseline/README.md) · [component README template](reviews/active-codebase-review.md#appendix-c--governance-evidence-and-documentation-template) (Appendix C).

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
| Calendar dates | `docs/architecture/calendar-dates.md` | `YYYY-MM-DD` wire format |
| API reference | [api-reference.md](api-reference.md) | REST endpoints |
| OpenAPI (critical subset) | [openapi/pet-care-critical.json](openapi/pet-care-critical.json) | Contract tests + DTO stability |
| Active baseline | [active-codebase-baseline/README.md](../engineering/active-codebase-baseline/README.md) | Command matrix, metrics, gates |
| Design / UX | `docs/design/index.md` | Tiers, `system.md`, `/ui-design-deep`, Router `accessibility` protocol |
| Navigation shell & phased delivery | `docs/domains/navigation/` + `docs/domains/cross-domain/features/` | **Active** — supersedes `docs/archived/navigation-v2.md`; read [navigation-decisions.md](/docs/domains/navigation/features/navigation-decisions.md) first |

---

## Domain map

Product domains are documented under [/docs/domains/](/docs/domains/). Each row links to the domain README.

### Authentication & profile

| | Path |
|---|------|
| **Docs** | [/docs/domains/auth/README.md](/docs/domains/auth/README.md) |
| Flutter | `flutter_app/lib/features/auth/` |
| Node routes | `server/routes/auth/` |
| Jest | `server/test/auth/` |
| BDD | `authentication.feature` |
| E2E | `auth.login.spec.ts`, `auth.signup.spec.ts`, `auth.profile.spec.ts` |

### Pet profiles

| | Path |
|---|------|
| **Docs** | [/docs/domains/pet_profile/README.md](/docs/domains/pet_profile/README.md) |
| Flutter | `flutter_app/lib/features/pet_profile/` |
| Node routes | `server/routes/pets/` |
| Jest | `server/test/pets/` |
| BDD | `pet_profiles.feature` |
| E2E | `pet.profiles.spec.ts` |

### Pet Care (individual-carer workspace)

| | Path |
|---|------|
| **Docs** | [/docs/domains/pet_care/README.md](/docs/domains/pet_care/README.md) |
| Flutter shell | `flutter_app/lib/features/experience/` |
| Routes (target) | `/pc/home`, `/pc/pets`, `/pc/events`, `/pc/fostering` |
| Wire | `AppExperience.petCare`, `pet_care` |
| BDD | `guardian_dashboard.feature` (renaming in progress) |
| E2E | `guardian.*.spec.ts` (renaming in progress) |
| E2E contract | [navigation-contract.md](/docs/e2e/navigation-contract.md) § Pet Care |

### Health tracking

| | Path |
|---|------|
| **Docs** | [/docs/domains/health_tracking/README.md](/docs/domains/health_tracking/README.md) |
| Flutter | `flutter_app/lib/features/health_tracking/` |
| Node routes | `server/routes/healthEntries/`, `healthIssues.js` |
| Jest | `healthEntries.test.js`, `healthIssues.test.js` |
| BDD | `health_tracking.feature` |
| E2E | `health.tracking.spec.ts` |

**Semantics:** `.agents/memory/health-entry-completion.md` — completion from `next_due_date`. Occurrence commands, agenda, and the Care Item detail route live in the **Care Item** component below (not in `health_tracking/`).

### Care Item (component)

One health entry as a care series: open occurrences, agenda row, occurrence screen, detail view, and server-confirmed completion. Programme: [`care-next-occurrence-c1a7`](../../.agents/plans/care-next-occurrence-c1a7.md) child F.

| | Path |
|---|------|
| **Docs (product)** | [/docs/domains/pet_care/features/care-item-evolution.md](/docs/domains/pet_care/features/care-item-evolution.md) · [care-schedule-management.md](/docs/domains/pet_care/features/care-schedule-management.md) |
| **Docs (modularity)** | [care-item-cross-feature-imports.md](care-item-cross-feature-imports.md) — C1 defer (#1545) |
| **Docs (UI)** | [care-item-view-ui.md](/docs/design/care-item-view-ui.md) |
| Flutter (public API) | `flutter_app/lib/features/care_item/care_item.dart` — other features import **only** this barrel (`scripts/check_care_item_boundary.sh`, `scripts/check_feature_imports.js`) |
| Flutter tests | `flutter_app/test/features/care_item/` |
| Node libraries | `server/lib/care/` (`schedule/`, `occurrence/`, `absence/`, `awayPlan/`, …) |
| Node routes | `server/routes/healthEntries/` → `/api/health-entries` occurrence + schedule commands |
| Jest | `server/test/careSchedule/`, `server/test/healthEntries/`, `server/test/care/` |
| OpenAPI / contract | `docs/architecture/openapi/pet-care-critical.json` · `server/test/openapi/petCareContract.test.js` |
| BDD | `care_item_absence.feature` |
| E2E | `care.agenda.spec.ts`, `care.item.absence.spec.ts` · page object `e2e/playwright/pages/care-item.page.ts` |

### Weight tracking

| | Path |
|---|------|
| **Docs** | [/docs/domains/weight_tracking/README.md](/docs/domains/weight_tracking/README.md) · [weight-monitoring-model.md](/docs/domains/weight_tracking/features/weight-monitoring-model.md) |
| Flutter | `flutter_app/lib/features/weight_tracking/` |
| Node routes | `server/routes/weightEntries.js` |
| Jest | `weightEntries.test.js` |
| BDD | `weight_tracking.feature` |
| E2E | `weight.tracking.spec.ts` |

### Veterinarians

| | Path |
|---|------|
| **Docs** | [/docs/domains/vet/README.md](/docs/domains/vet/README.md) |
| Flutter | `flutter_app/lib/features/vet/` |
| Node routes | `server/routes/vets.js` |
| Jest | `vets.test.js` |
| BDD | `veterinarian_management.feature` |

### Sharing

| | Path |
|---|------|
| **Docs** | [/docs/domains/sharing/README.md](/docs/domains/sharing/README.md) |
| Flutter | `flutter_app/lib/features/sharing/` |
| Node routes | `server/routes/sharing.js` |
| Jest | `sharing.test.js`, `sharedPetAccess.test.js` |
| BDD | `sharing.feature` |
| E2E | `sharing.spec.ts` |

### People (Contacts)

| | Path |
|---|------|
| **Docs** | [/docs/domains/people/README.md](/docs/domains/people/README.md) |
| Spec | [/docs/domains/people/features/people-care-team.md](/docs/domains/people/features/people-care-team.md) (D1–D28) |
| Refactor target | [/docs/domains/people/changes/people-domain-refactor.md](/docs/domains/people/changes/people-domain-refactor.md) (roadmap `people-domain-refactor-7f3b`) |
| Flutter | `flutter_app/lib/features/people/` |
| Node | `server/routes/people/`, `server/lib/people/`, `server/routes/pets/peopleRelationshipsRouter.js`, `server/lib/households/` |
| Jest | `server/test/people/**`, `server/test/households/**` |
| BDD / E2E | `people.feature` · `people-hub.spec.ts`, `veterinarian.spec.ts` |

### Notifications

| | Path |
|---|------|
| **Docs** | [/docs/domains/notifications/README.md](/docs/domains/notifications/README.md) |
| Flutter | `flutter_app/lib/features/notifications/` |
| Node routes | `server/routes/notifications.js` |
| Jest | `notifications.test.js` |
| BDD | `notifications.feature` |
| E2E | `notifications.spec.ts` |

### Shelter (incl. foster, custody, adoption) — **FROZEN** (not MVP)

> **Status (2026-09):** Frozen with Fostering. Not maintained; not in CI. See [/docs/engineering/frozen-domains/](/docs/engineering/frozen-domains/).

| | Path |
|---|------|
| **Docs (org identity)** | [/docs/domains/shelter/README.md](/docs/domains/shelter/README.md) |
| **Docs (foster workflows)** | [/docs/domains/fostering/README.md](/docs/domains/fostering/README.md) · [session detail view](/docs/domains/fostering/features/session-detail-view.md) |
| Flutter | `flutter_app/lib/features/organization/` |
| Node routes | `server/routes/organizations/`, `fosterPlacements.js`, `custodyTransfers.js` |
| Jest | `server/test/organizations/`, `fosterPlacements.test.js`, `custodyTransfers.test.js`, `orgConnections.test.js` |
| Architecture | `docs/domains/shelter/features/org-custody-model.md`, `docs/domains/fostering/features/g0-contract-pack.md`, `docs/domains/shelter/changes/phase-3-organisation-presentation.md` (historical), **`docs/domains/shelter/changes/organisation-v2-delivery-plan.md`** (v2 profile composer), **`docs/domains/shelter/changes/organisation-ux-v3-delivery-plan.md`** (v3 UX — visibility, chrome, nav rows, privacy — **active**), **`docs/domains/shelter/features/org-member-privacy.md`** (v3 Account per-org privacy), **`docs/architecture/pet-activity-model.md`** |
| BDD | `organisation_profile.feature`, `organisation_discovery.feature`, `admin_contacts.feature`, `fostering_sessions.feature`, `fostering_session_detail.feature` (planned), `redacted_org_pet.feature`, `organisation_management.feature`, … |
| E2E | `organisation.profile.spec.ts`, `organisation.discovery.spec.ts`, `organisation.redacted-pet.spec.ts`, `organisation.pet-filters.spec.ts`, `organisation.management.spec.ts`, `organisation.pet.management.spec.ts`, `adoption.spec.ts` |

**Validation:** `.agents/memory/body-supplied-org-id-validation.md`

### Subscription

| | Path |
|---|------|
| **Docs** | [/docs/domains/subscription/README.md](/docs/domains/subscription/README.md) |
| Flutter | `flutter_app/lib/features/subscription/` |
| BDD | `subscriptions.feature` |
| E2E | — (UAT RevenueCat sandbox required) |

### Help & about

| | Path |
|---|------|
| **Docs** | [/docs/domains/help_about/README.md](/docs/domains/help_about/README.md) |
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

### Server component contracts (Node)

Appendix C READMEs — purpose, tables, endpoints, transaction owner, tests.

| Component | README |
|-----------|--------|
| Auth (session, profile) | [server/routes/auth/README.md](../../server/routes/auth/README.md) |
| Account (erasure service) | [server/lib/account/README.md](../../server/lib/account/README.md) |
| Pets | [server/routes/pets/README.md](../../server/routes/pets/README.md) |
| Health entries | [server/routes/healthEntries/README.md](../../server/routes/healthEntries/README.md) |
| Sharing | [server/routes/sharing/README.md](../../server/routes/sharing/README.md) |
| Care context (planned absences) | [server/routes/careContext/README.md](../../server/routes/careContext/README.md) |
| Cleanup jobs | [server/lib/jobs/README.md](../../server/lib/jobs/README.md) |

---

## Feature public APIs (Flutter)

Each active feature documents its entrypoint and public surface in `flutter_app/lib/features/<feature>/README.md`. Import **`features/<feature>/<feature>.dart`** from other features (enforced by `check_feature_imports.js` R6).

| Feature | Entrypoint | Component README |
|---------|------------|------------------|
| about | `about/about.dart` | [README](../../flutter_app/lib/features/about/README.md) |
| auth | `auth/auth.dart` | [README](../../flutter_app/lib/features/auth/README.md) |
| care_intelligence | `care_intelligence/care_intelligence.dart` | [README](../../flutter_app/lib/features/care_intelligence/README.md) |
| care_taxonomy | `care_taxonomy/care_taxonomy.dart` | [README](../../flutter_app/lib/features/care_taxonomy/README.md) |
| experience | `experience/experience.dart` | [README](../../flutter_app/lib/features/experience/README.md) |
| health_tracking | `health_tracking/health_tracking.dart` | [README](../../flutter_app/lib/features/health_tracking/README.md) |
| help | `help/help.dart` | [README](../../flutter_app/lib/features/help/README.md) |
| notifications | `notifications/notifications.dart` | [README](../../flutter_app/lib/features/notifications/README.md) |
| people | `people/people.dart` | [README](../../flutter_app/lib/features/people/README.md) |
| pet_care | `pet_care/pet_care.dart` | [README](../../flutter_app/lib/features/pet_care/README.md) |
| pet_profile | `pet_profile/pet_profile.dart` | [README](../../flutter_app/lib/features/pet_profile/README.md) |
| pet_tags | `pet_tags/pet_tags.dart` | [README](../../flutter_app/lib/features/pet_tags/README.md) |
| sharing | `sharing/sharing.dart` | [README](../../flutter_app/lib/features/sharing/README.md) |
| subscription | `subscription/subscription.dart` | [README](../../flutter_app/lib/features/subscription/README.md) |
| vet | `vet/vet.dart` | [README](../../flutter_app/lib/features/vet/README.md) |
| weight_tracking | `weight_tracking/weight_tracking.dart` | [README](../../flutter_app/lib/features/weight_tracking/README.md) |

---

## Agent workflow shortcuts

| Task | Start here |
|------|------------|
| **Default** | Five Tier 1 commands — see `docs/engineering/cursor-agent-framework.md` |
| Split a screen | `/split-flutter-screen` (Tier 2) |
| New API endpoint | `/babysit-plus` or `/execute-plan` — Router → `api-contract` protocol |
| BDD → Playwright | `/add-bdd-playwright-scenario` (Tier 2) |
| Parallel sprint | `/spawn-sprint-agents` (Tier 2) |
| Before push | `./scripts/pre-push-changed.sh` or `/pre-push-verify` |
| UI review / theme rework | `/ui-design-deep` · `docs/design/index.md` |
| Multi-phase autonomous work | `/execute-plan` |
| Security-sensitive change | Router → `.cursor/agent-kernel/protocols/security.md`, `.cursor/agent-kernel/protocols/authorization.md` |
