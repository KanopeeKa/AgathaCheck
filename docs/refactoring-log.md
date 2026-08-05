# Refactoring log (by sprint)

Tracks planned and completed refactor / quality work. See also `docs/refactoring-debt.md` and `docs/architecture/modularity.md`.

**Policy:** Multi-agent / sprint milestones use an **integration branch** → single PR to `main`. Single-agent domain PRs may go direct to `main`. Full E2E on UAT only. See `.cursor/rules/merge-policy.mdc` and `.cursor/rules/agent-coordination.mdc`.

---

## public-access-gate-a35f — Prod teaser + UAT Basic Auth (2026-08-05)

**Goal:** Pre-launch public posture — prod static coming-soon + API `PUBLIC_ACCESS_MODE=coming_soon`; UAT flag-gated HTTP Basic Auth CI; canonical ops doc; live-host helper split (`liveUat` vs `liveProd`).  
**Plan:** `.agents/plans/public-access-gate-a35f.md` · **Integration:** `cursor/public-access-gate-integration-a35f` · **Control issue:** #611  
**Canonical ops:** `docs/ops/public-access.md`

| Phase | Outcome | Branch | Status |
|-------|---------|--------|--------|
| 1 | Teaser site + docs + hosting helpers + smoke lib | `cursor/public-access-teaser-docs-a35f` | **In progress** |
| 2 | API `PUBLIC_ACCESS_MODE` middleware | `cursor/public-access-api-mode-a35f` | Pending |
| 3 | Prod deploy teaser path + smoke | `cursor/public-access-prod-deploy-a35f` | Pending |
| 4 | UAT Basic Auth CI plumbing | `cursor/public-access-uat-auth-a35f` | Pending |

---

## org-ux-polish-badd — Org dashboard UX polish (2026-08-05)

**Goal:** Fix UAT org image display (`/backend/uploads` routing), horizontal My Organisations rows, pet-style camera upload on branding, wrap grids for org pets and discover, British English locale.  
**Plan:** `.agents/plans/org-ux-polish-badd.md` · **Integration:** `cursor/org-ux-polish-integration-badd` · **Control issue:** #598

| Phase | Outcome | PR | Status |
|-------|---------|-----|--------|
| 1 | Upload URL fix + provider refresh | #599 | **Merged** |
| 2–5 | Cards, camera UX, grids, EN-GB | #600 | **Merged** |
| Integration → `main` | Pre-UAT E2E gate | TBD | **Pending** |

---

## ci-test-depth-abc9 — CI test depth & gate remediation (started 2026-08-03)

**Goal:** Close gap between BDD mapping metrics and real test execution; domain-scoped PR Flutter shards; Pre-UAT manifest hygiene; stale CI/CD doc truth.  
**Plan:** `.agents/plans/ci-test-depth-abc9.md` · **Integration branch:** `cursor/ci-test-depth-integration-abc9`  
**Control issue:** #558

| Phase | Outcome | Status |
|-------|---------|--------|
| F0 | Doc truth (UAT tiers, scorecard, coordinator superseded, pre-push skill) | **Done** |
| F1 | Quality metrics tooling (depth/execution scorecard) | **Done** |
| F2 | PR domain-scoped Flutter shards | **Done** |
| F3 | Pre-UAT shard manifest + rebalance (12 shards, 0 orphans) | **Done** |
| F4 | Org v2 test deepening | **Done** |
| F5 | General widening + scorecard update | **Done** |
| F6 | Integration → `main` | **In progress** |

---

## Sprint 1 — Governance & CI (2026-07-07)

**Goal:** Codify standards in Cursor + CI; security and a11y pipelines; no product refactors.

| # | Action | Status | PR / notes |
|---|--------|--------|------------|
| 1.1 | Cursor rules (modularity, testing, security, single-backend, a11y, merge-policy) | Done | `.cursor/rules/` |
| 1.2 | `CONTRIBUTING.md` + PR template | Done | |
| 1.3 | `docs/quality/scorecard.md` | Done | |
| 1.4 | CI: `npm audit --audit-level=high` (server + e2e) | Done | `_reusable-test.yml` |
| 1.5 | CI: CodeQL JavaScript | Done | `codeql.yml` |
| 1.6 | Dependabot (server, e2e, flutter_app pub) | Done | `dependabot.yml` |
| 1.7 | CI: `dart analyze lib` on server | ~~Done~~ Removed — Dart backend deleted 2026-07-21 | |
| 1.8 | CI: Node 22 alignment | Done | |
| 1.9 | CI: Flutter integration test blocking | Done | removed `continue-on-error` |
| 1.10 | CI: `dart format` check — **warn only** | Done | enforce in Sprint 2 |
| 1.11 | CI: coverage artifacts (report-only) | Done | |
| 1.12 | axe on UAT `@smoke` (critical + serious) | Done | `@axe-core/playwright` |
| 1.13 | Weekly non-blocking E2E cron on `main` | Done | `e2e.yml` |
| 1.14 | Extend `AGENTS.md` with merge/conflict policy | Done | |
| 1.15 | Fix npm audit highs (bcrypt 6, uuid 11, remove mocha) | Done | Unblocks CI audit gate |
| 1.16 | Fix blocking integration test (`petListProvider` override) | Done | |

**Sprint 1 exit criteria:** All items above merged; CI green on `main`.

---

## Sprint 2 — Legacy cleanup + first screen split (planned)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 2.1 | Remove root legacy `lib/` / `pubspec.yaml` if unused | **Done** | Root `pubspec.yaml` removed; orphaned root `analysis_options.yaml` removed in 2.7 |
| 2.2 | Remove `attached_assets/` from git | **Done** | Already absent from repo |
| 2.3 | Drop `npm run test:mocha` | **Done (Sprint 1)** | Removed with mocha/chai |
| 2.4 | Split `pet_form_screen.dart` (929 → <500) | **Done** | Extracted `widgets/pet_form/` incl. bio/insurance/chip + confirm dialogs |
| 2.5 | Split `health_entry_form_screen.dart` (756 → <500) | **Done** | Extracted `widgets/health_entry_form/` (425 lines) |
| 2.6 | Widget tests: `about`, `help`, `subscription` (smoke) | **Done** | Smoke tests added |
| 2.7 | **Enforce** `dart format` in CI (remove warn-only) | **Done** | CI blocks; repo formatted |
| 2.8 | Playwright: `sharing.feature` implementation | **Done** | `sharing.spec.ts` + `@smoke` anonymous preview |
| 2.9 | Coverage threshold (ratchet to 65% Flutter domain) | **Done** | CI gate via `check_domain_coverage.js` |

---

## Sprint 3 — Screen splits + backend test modularization (complete — all 8 items done)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 3.1 | Split `pet_detail_screen.dart` (710 → 114) | **Done** | `widgets/pet_detail/` + 4 widget tests |
| 3.2 | Split `health_dashboard_screen.dart` (729 → 232) | **Done** | `widgets/health_dashboard/` + org filter test |
| 3.3 | Split `my_details_screen.dart` (618 → 321) | **Done** | `widgets/my_details/` (profile editor + settings) |
| 3.4 | Split `server/lib/auth_routes.dart` → mirror `routes/auth/` | **Done** | PR #94; 14-line composer delegating to `routes/auth/`; was 769 lines |
| 3.5 | Split `server/test/auth.test.js` → `test/auth/` | **Done** | PR #92; split from 1012 lines into `test/auth/` modules |
| 3.6 | Split `server/test/pets.test.js` → `test/pets/` | **Done** | PR #93; split from 1072 lines into `test/pets/` modules |
| 3.7 | Playwright: `organisation_management.feature` | **Done** | `organisation.management.spec.ts` + org page objects |
| 3.8 | Expand `notifications` widget tests | **Done** | Screen + settings widget tests |

---

## Sprint 4 — Backend routes + BDD expansion (planned)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 4.1 | Split `server/routes/healthEntries.js` | **Done** | `routes/healthEntries/` (#101) |
| 4.2 | Playwright: `notifications.feature`, `weight_tracking.feature` | **Done** | #99 |
| 4.3 | BDD coverage target **50% of all scenarios (81/161)** | **Done** | #102; `e2e/scripts/check_bdd_coverage.js` |
| 4.4 | Resolve moderate `npm audit` findings (bcrypt 6.x, uuid) | **Done (Sprint 1)** | bcrypt ^6, uuid ^11 |

**Sprint 4 exit criteria:** All items merged (#99, #101, #102).

---

## Experience split — Phases 1–2 (2026-07-15)

**Branch:** `cursor/experience-split-17a0`  
**Plan:** `docs/experience-split-plan.md`

| # | Deliverable | Status |
|---|-------------|--------|
| XP-1 | Experience chooser + eligibility + remember choice | **Done** |
| XP-2 | Guardian shell `/g/*` + org shell `/o/*` + top nav drawer | **Done** |
| XP-3 | Guardian home excludes org inventory (`guardianShellPets`) | **Done** |
| XP-4 | BDD `experience_navigation.feature` + Playwright spec | **Done** (6/6 scenarios E2E) |
| XP-5 | Settings default experience | **Done** |
| XP-6 | Phase 2 home grouping + inline event actions + scoped events | **Done** |
| XP-7 | PR A+B tests: experience in `rest` shard; L1/L2 coverage; domain gate **72.4%** | **Done** (#184) |

## Experience split — Phase 3 (2026-07-15)

**Branch:** `cursor/experience-phase3-pet-detail-17a0`  
**Plan:** `docs/experience-split-plan.md`

| # | Deliverable | Status |
|---|-------------|--------|
| XP-8 | `PetDetailActions` + `PetViewerRole` registry | **Done** |
| XP-9 | Responsibility labels on pet detail header | **Done** |
| XP-10 | Foster portal drawer filter (hide invite + upcoming events) | **Done** |
| XP-11 | Experience-aware back nav on pet detail | **Done** |
| XP-12 | Review hardening: default-deny policy provider, edit/route guards, matrix tests, E2E shell nav | **Done** (#186, #187) |

## Experience split — E2a default experience settings (2026-07-16)

**Branch:** `cursor/experience-e2a-default-settings-17a0`

| # | Deliverable | Status |
|---|-------------|--------|
| XP-15 | BDD `Dual-role user sets default experience to organisation in settings` | **Done** |
| XP-16 | Playwright E2a + `resolvePostLoginPath` org-default L1 test | **Done** |

## Experience split — Phase 4.2 org super-admin onboarding (2026-07-16)

**Branch:** `cursor/org-onboarding-wizard-17a0`

| # | Deliverable | Status |
|---|-------------|--------|
| XP-20 | `/o/onboarding` wizard (org + inventory pet + reminder) + skip | **In progress** |
| XP-21 | Post-login redirect for org super-admins without inventory pets | **In progress** |
| XP-22 | BDD `org_onboarding.feature` + Playwright | **In progress** |

## Experience split — Phase 4.1 guardian onboarding (2026-07-16)

**Branch:** `cursor/guardian-onboarding-wizard-17a0`

| # | Deliverable | Status |
|---|-------------|--------|
| XP-17 | `/g/onboarding` wizard (pet + first reminder) + skip | **Done** (#192) |
| XP-18 | Post-login redirect for new guardians with no pets | **Done** (#192) |
| XP-19 | BDD `guardian_onboarding.feature` + Playwright | **Done** (#192) |

---

## Sprint 5 — Governance hardening + monolith splits (in progress)

**Integration branch:** `cursor/sprint-5-governance-integration-13e3` (create when parallel work starts)

| # | Action | Status | Parallel agent | Owns |
|---|--------|--------|----------------|------|
| 5.1 | Quality review doc + integration-branch policy + agent-coordination rule | **Done** | `docs/quality/review-2026-07-08.md`, `.cursor/rules/` |
| 5.2 | CI: `check_file_size.js` (500-line gate + grandfather ratchet) | **Done** | `scripts/check_file_size.js`, governance CI job |
| 5.3 | CI: `check_bdd_coverage.js` (81/161 gate, ratchet later) | **Done** | `_reusable-test.yml` |
| 5.4 | Split placements/foster monoliths (663 + 653 + 518 lines) | **Done** | Node `routes/organizations/placements/`; Dart `lib/organizations/placements/`; Flutter `pet_foster_placement/` |
| 5.4b | Clear remaining 5 grandfathered monoliths (org providers, Dart routes, landing, other-event form, health card) | **Done** | `org_provider_*.dart`; `routes_{pool,common,pet,vet}_*.dart`; `widgets/landing/`; `other_event_form/` handlers |
| 5.5 | GDPR `/me/export` completeness + Jest tests | **Done** | `server/lib/gdprUserExport.js` + Dart `gdpr_user_export.dart` |
| 5.6 | `@P0`/`@P1`/`@P2` tags on `.feature` files | **Done** | `scripts/bdd-priority-tag-map.json` + CI gate |

**5.4 agent order:** Foundation agent documents placement API shapes → Node split → Dart widget split (avoids `api.ts` / route conflicts).

---

## Sprint 6 — Org-operator BDD + help (complete)

**Integration branch:** `cursor/sprint-6-org-bdd-integration-feec`  
**Execution plan:** `docs/sprint-6-execution-plan.md`  
**Integration PR:** **Merged** #116 → `main`

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 6.1 | Playwright: `organisation_pet_management.feature` (6) | **Done** (#111) | |
| 6.A | Foundation: `api.ts` foster/custody/return helpers | **Done** (#114 base) | |
| 6.2 | Playwright: org custody (4 features, 12 scenarios) | **Done** (#115) | `adoption.spec.ts` |
| 6.3 | Playwright: `organisation_pet_timeline.feature` (4/6) | **Done** | `org.timeline.spec.ts`; 2 deferred |
| 6.4 | Playwright: `help_faq.feature` (10) | **Done** (#114) | `help.faq.spec.ts` |
| 6.5 | Realign `@smoke` + axe to P0 guardian paths | **Done** | Guardian P0 set |

**BDD mapped:** **113/165 (68.5%)** — exit gate **105** cleared.  
**Deferred:** timeline remove-event + notification scenarios → `docs/refactoring-debt.md` (if not already).

---

## Sprint 7 — Compliance + governance close-out (complete)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 7.1 | Gherkin + Playwright: GDPR export + account delete (J13) | **Done** | `gdpr_data_rights.feature`, `gdpr.data-rights.spec.ts` |
| 7.2 | `subscriptions.feature` E2E | **Deferred** | RevenueCat — see `docs/technical-debt.md`; pending EU billing solution review |
| 7.3 | Clear grandfather allowlist entries (all files <500) | **Done** | Verified Sprint 5.4b; allowlist empty, 0 grandfathered |
| 7.4 | BDD gate ratchet to **105/165 (65%)** in CI | **Done** | `check_bdd_coverage.js`, workflow, docs |

**BDD mapped:** **115/167** after 7.1 (+2 scenarios). Gate **105** enforced in CI.

**Refactoring programme:** Sprints 1–7 + agent-efficiency (8–11) complete for scoped modularization/BDD work. Remaining items → `docs/refactoring-debt.md` and `docs/technical-debt.md`.

---

## Sprint 8 — Agent efficiency infrastructure (complete)

**Goal:** Reduce agent token burn; encode recurring workflows as Skills; changed-files pre-push.  
**Plan:** `docs/agent-efficiency-plan.md` · **Merged:** #109

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 8.1 | Master plan + architecture index | **Done** | `docs/agent-efficiency-plan.md`, `docs/architecture/index.md` |
| 8.2 | `scripts/pre-push.sh` + `pre-push-changed.sh` | **Done** | Single verify source of truth |
| 8.3 | Six Cursor Skills | **Done** | `.cursor/skills/` |
| 8.4 | Slim `agent-core.mdc`; scope path rules | **Done** | Less always-on duplication |
| 8.5 | `/babysit` + PR governance hints workflow | **Done** | Advisory only; CI unchanged |
| 8.6 | Prompt templates + slim AGENTS.md | **Done** | `docs/agent-efficiency/prompt-templates.md` |

**Exit:** Merged to `main` (#109). Resume Sprint 6 functional work.

---

## Sprint 9 — Bugbot remediation + Dart foster parity audit (2026-07-10)

**Goal:** Investigate and fix still-valid Bugbot findings from merged PRs #2, #3, #99, #102; audit stale branch `cursor/dart-org-foster-parity-b4c2` for relevance vs supersession.

**Integration branch:** `cursor/sprint-9-bugbot-remediation-integration-2799` → single PR to `main` when exit criteria met.

### In-flight PRs — do not touch

| PR | Branch | Avoid paths |
|----|--------|-------------|
| #126 | `cursor/to-do-screen-pet-info-1fba` | `health_entry_card*`, `health_dashboard*`, `health_entry_model*`, `pet_providers.dart` |
| #128 | `cursor/agent-workflow-pause-uat-fixes-3842` | `.github/**`, `docs/github-issue-workflow.md`, `flutter_app/web/.htaccess` |
| #127 | `cursor/fix-deploy-uat-env-if-3842` | `.github/workflows/deploy-uat.yml` (superseded by #128) |

**Coordinator:** rebase integration on `origin/main` after #126/#128 merge; resolve conflicts before final PR.

### Ownership map (spawned agents)

| Phase | Agent | Branch | Owns | Bugbot source | Exit criteria |
|-------|-------|--------|------|---------------|---------------|
| 0 | `dart-foster-audit` | `cursor/sprint-9-dart-foster-audit-2799` | read-only branch compare (doc removed 2026-07-22) | stale `dart-org-foster-parity-b4c2` | Verdict: superseded by #64; Dart backend removed #240 |
| 1a | `flutter-token-migration` | `cursor/sprint-9-token-migration-2799` | `flutter_app/lib/features/auth/data/token_store.dart`, `flutter_app/test/features/auth/data/token_store_test.dart` | PR #3 High | Prefs→Secure migration on mobile upgrade; tests green |
| 1b | `flutter-photo-url` | `cursor/sprint-9-photo-url-fix-2799` | shared photo URL helper + `my_details_screen.dart`, org/sharing call sites using wrong `/backend` prefix for `/uploads` | PR #2 Medium | `/uploads` resolves to site root on web |
| 1c | `flutter-pet-sync` | `cursor/sprint-9-pet-sync-rollback-2799` | `pet_repository_impl.dart`, `pet_repository_impl_test.dart` | PR #2 Medium | Remote update/delete failure rolls back local state |
| 1d | `e2e-notifications` | `cursor/sprint-9-e2e-notifications-2799` | `e2e/playwright/pages/notifications.page.ts`, `notifications.spec.ts` | PR #99 Medium | Badge scoped to app-bar bell; `expectNoBadgeVisible` asserts absence |
| 1e | `e2e-vet-health` | `cursor/sprint-9-e2e-vet-health-2799` | `vet-list.page.ts`, `health.tracking.spec.ts`, vet detail helpers | PR #102 Low–Med | Vet menu targets named card; snooze/dosage/GET-vet assertions |

**Deferred (audit-dependent):** Dart org `501` stubs (`placements_routes.dart` etc.) — action only if `dart-foster-audit` recommends cherry-pick.

**Sprint 9 exit criteria:**

- All agent branches merged to integration; `./scripts/pre-push.sh` green on integration
- Audit doc published; valid Bugbot items fixed or documented false-positive
- No edits under in-flight PR paths until those PRs land on `main`

| # | Action | Status | PR / notes |
|---|--------|--------|------------|
| 9.0 | Dart foster parity branch audit | **Done** | Superseded by #64; Dart backend removed #240; stale branch safe to delete |
| 9.1 | Mobile token store migration | **Done** | Prefs→Secure one-time migration |
| 9.2 | Web upload photo URL resolution | **Done** | `resolveStaticAssetUrl` helper |
| 9.3 | Pet repo remote-failure rollback | **Done** | update/delete rollback on remote fail |
| 9.4 | E2E notification badge scoping | **Done** | Scoped badge assertions |
| 9.5 | E2E vet/health assertion hardening | **Done** | Named vet menu + snooze/dosage/GET status |

**Exit:** Merged to `main` (#129).

---

## Sprint 10 — Flutter 3.44 / Dart 3.12 toolchain upgrade (in progress)

**Goal:** Upgrade Flutter 3.32 → 3.44 (Dart 3.8 → 3.12); unblock blocked pub Dependabot PRs (#77–#81).  
**Execution plan:** `docs/sprint-10-flutter-344-execution-plan.md`  
**Integration branch:** `cursor/sprint-10-flutter-344-integration-4379` → single PR to `main`

| # | Action | Status | Agent / notes |
|---|--------|--------|---------------|
| 10.A | Foundation: CI pins, SDK constraints, docs | In progress | CI workflows + Dockerfile + SDK bump |
| 10.B | Pub batch: fl_chart, pdf, printing, mockito, flutter_lints | In progress | lockfiles + `build_runner` |
| 10.C | `fl_chart` 1.x migration (`weight_chart.dart`) | In progress | API fixes if needed |
| 10.D | `flutter_lints` 6 analyze cleanup | In progress | analyze fixes |
| 10.E | Full `./scripts/pre-push.sh`; rebase Dependabot #77–#81 | Pending | Coordinator |

**Out of scope:** Babel 8 (#73, #75) — close/ignore until separate decision.

**Sprint 10 exit criteria:** CI green on Flutter 3.44; blocked pub PRs merged or superseded; UAT deploy smoke passes.

---

## Sprint 11 — UI theme rework (planned)

**Goal:** Calm care-coordination visual system — sage palette, tokenized theme, phased screen alignment.  
**Execution plan:** `docs/design/ui-rework-plan.md` (phases 0–7)  
**Governance:** `docs/design/index.md`, `.cursor/rules/design.mdc`, skills `/ui-check`, `/ui-design-deep`  
**PR #267:** design governance + plan doc

| Phase | Outcome | Status |
|-------|---------|--------|
| 0 | `tokens.md` + `app_theme.dart` + `ExperienceColors` | In progress |
| 1 | Shared components + `AppTheme.org*` → tokens | Planned |
| 2 | Auth, landing, onboarding | Planned |
| 3 | Guardian shell, pet list/detail, notifications | Planned |
| 4 | Health, vet, weight forms | Planned |
| 5 | Organisation + foster portal | Planned |
| 6 | Sharing, help, about, paywall, stragglers | Planned |
| 7 | QA, a11y coverage, doc closeout | Planned |

**Sprint 11 exit criteria:** No purple-seed theme; zero undocumented `Color(0x` outside theme/charts; `./scripts/pre-push.sh` green; axe clean on primary journeys.

---

## Fostering platform (J1–J5 + G1)

**Goal:** Second-generation fostering & adoption per `docs/fostering-platform/`.  
**Coordination:** [`roadmap-delivery-plan.md`](fostering-platform/roadmap-delivery-plan.md)  
**Contract:** [`g0-contract-pack.md`](fostering-platform/g0-contract-pack.md) · [`migration-appendix.md`](fostering-platform/migration-appendix.md)

| Wave | execute-plan | Status |
|------|--------------|--------|
| Foundation | `fostering-platform-foundation-e877` | merged |
| J1 Ph2 approval | `fostering-platform-j1-phase2-e877` | merged |
| J1 Ph3 profiles + merge | `fostering-platform-j1-phase3-e877` | **active** |
| J1 Ph4 compliance | `fostering-platform-j1-phase4-e877` | pending |
| J2 requests | `fostering-platform-j2-e877` | pending (after J1 Ph3) |
| J3 sessions | `fostering-platform-j3-e877` | pending (after J1 Ph3) |
| J4 visits | `fostering-platform-j4-e877` | pending (after J3 Ph1) |
| J5 adoption | `fostering-platform-j5-e877` | pending (after J4) |
| G1 documents | `fostering-platform-g1-e877` | pending (after J3+J5 hooks) |

### Wave B ownership (J2 ∥ J3 — spawn after J1 Ph3)

| Agent | Branch | Owns | Avoid |
|-------|--------|------|-------|
| j2-backend | `cursor/j2-foster-requests-backend-e877` | foster_request migrations, `fosterRequestsRouter.js`, tests | `fosterPlacements*`, flutter |
| j3-schema | `cursor/j3-session-schema-e877` | session column migrations, `fosterPlacements.js`, placement tests | foster_requests, flutter |
| coordinator | `cursor/fostering-platform-j2-j3-e877-integration` | capacity glue, plan artifacts | — |

---

## Parallel-agent ownership matrix (reference)

Use this template when spawning agents on an integration branch:

| Phase | Agent | Branch suffix | Files / directories |
|-------|-------|---------------|---------------------|
| 0 Foundation | `foundation` | merge first | `e2e/playwright/support/api.ts`, shared fixtures |
| 1a | `e2e-health` | parallel | `health*.spec.ts`, `health-*.page.ts` |
| 1b | `e2e-auth-pet` | parallel | `auth.*.spec.ts`, `pet.profiles.spec.ts`, related pages |
| 1c | `e2e-org` | parallel | `organisation*.spec.ts`, `adoption*.spec.ts` |
| 2 | `node-<domain>` | parallel per domain | `server/routes/<domain>/` |
| 2 | `flutter-<screen>` | parallel per screen | one screen + `widgets/` subtree |

**Never parallelise:** same spec file, same page object, `api.ts`, CI workflows, `file-size-allowlist.json`.

---

## Experience program — Phase 3 (`experience-program-phase-3`)

**Integration branch:** `cursor/sprint-exp-org-presentation-integration-36bd`  
**Control issue:** #379 · **UI review:** `docs/experience-program/phase-3-ui-design-review.md`

| Agent | Branch | Owns | Avoid |
|-------|--------|------|-------|
| **foundation** | `cursor/exp-org-foundation-36bd` | `db/migrations/035_*`, `db/migrations/036_*`, `db/schema/canonical.sql`, `server/lib/orgPermissions.js`, `server/lib/orgRoles.js`, `server/routes/organizations/index.js` (permission helpers), `server/test/orgPermissions*.js`, Flutter `hasPermission` wiring in `flutter_app/lib/features/organization/domain/` | UI screens |
| **discover** | `cursor/exp-org-discover-36bd` | `server/routes/organizations/discover*`, `flutter_app/lib/features/organization/presentation/widgets/org_discovery_*`, `organization_list_screen.dart` (Discover section only), `e2e/playwright/tests/organisation.discovery.spec.ts`, BDD `organisation_discovery.feature` | `organization_detail_screen.dart`, migrations |
| **admin-contacts** | `cursor/exp-org-admin-contacts-36bd` | `flutter_app/lib/features/organization/presentation/screens/admin_contacts_screen.dart`, `widgets/admin_contacts/*`, BDD `admin_contacts.feature`, routes in `organization_routes.dart` (admin-contacts path only) | `organization_people_section.dart` (read-only reference), pets |
| **pet-tabs** | `cursor/exp-org-pet-tabs-36bd` | `organization_pets_screen.dart`, `widgets/org_pets/*`, BDD `pet_screen_filters.feature`, `e2e/playwright/tests/organisation.pet-filters.spec.ts` | other org screens |
| **coordinator** | `cursor/experience-org-presentation-36bd` | Org dashboard hub (3.4), Presentation screen (3.5), Legal slide-over (3.7), audit events (3.9), BDD extensions, plan artifacts | files owned by parallel agents until merged |

**Sequence:** foundation merges to integration first → discover / admin-contacts / pet-tabs in parallel → coordinator merges decomposition + remaining sprints → single PR integration → `main`.

---


| Date | Change |
|---|---|
| 2026-07-23 | UI navigation v2 execute-plan started (`ui-navigation-v2-14ee`, control #299): `docs/design/navigation-v2.md`; experience-split + tokens amended |
| 2026-07-23 | UI theme rework complete (`ui-theme-rework-4bed`): plum guardian / teal org tokens, phases 0–7 merged (#273–#294); `docs/design/tokens.md` |
| 2026-07-22 | Sprint 11 planned: UI theme rework — `docs/design/ui-rework-plan.md`; design governance PR #267 |
| 2026-07-19 | PR C (#220): due-events E2E restores home `DueEventsSection` assertion via `PetListPage.refreshByRemount()` after API seed (#216 events-screen proxy superseded). |
| 2026-07-19 | #219 merged: E2E shell-navigation fallback contract (`navigateWithShellFallback`). |
| 2026-07-19 | #218 merged: UAT pre-flight health probe before live smoke workers. |
| 2026-07-16 | #188 merged: E1b org-only user lands on organisation home |
| 2026-07-16 | #187 merged: E2E guardian shell nav hardening (chooser, strict-mode, shell fallbacks) |
| 2026-07-16 | #186 merged: Experience Phase 3 pet detail context |
| 2026-07-10 | Sprint 10 planned: Flutter 3.44 / Dart 3.12 upgrade; execution plan `docs/sprint-10-flutter-344-execution-plan.md` |
| 2026-07-10 | Sprint 9 merged #129: Bugbot remediation (token migration, photo URLs, pet sync rollback, E2E hardening); dart-foster audit |
| 2026-07-09 | Sprint 7: GDPR data-rights E2E; BDD gate 105/165; subscriptions E2E deferred (EU billing review) |
| 2026-07-09 | Sprint 6 complete (#116): 113/165 BDD; org custody + help FAQ |
| 2026-07-08 | Sprint 5.5–5.6: GDPR `/me/export` full payload; BDD priority tags (16 P0 / 111 P1 / 34 P2) |
| 2026-07-08 | Sprint 5.4b: cleared 5 remaining monoliths; empty `file-size-allowlist.json` |
| 2026-07-08 | Sprint 5–7 plan; integration-branch policy; parallel-agent ownership matrix |
| 2026-07-08 | Sprint 4.3 merged #102: 81/161 BDD scenarios; 79 Playwright tests |
| 2026-07-08 | Sprint 4.3: BDD journey matrix; 4.1–4.2 done; 50% all-scenario gate |
| 2026-07-08 | Sprint 3 complete (all 8 items): 3.4 auth_routes.dart split PR #94, 3.5 auth.test.js split PR #92, 3.6 pets.test.js split PR #93 |
| 2026-07-07 | Sprint 3.1–3.3: pet_detail, health_dashboard, my_details screen splits merged |
| 2026-07-07 | Sprint 2.9: Flutter domain coverage gate at 65% |
| 2026-07-07 | Sprint 2.8: Playwright sharing.feature E2E tests |
| 2026-07-07 | Sprint 2.5: health_entry_form_screen split (756 → 425 lines) |
| 2026-07-07 | Sprint 1 plan created; governance + CI implementation |

---

## Sprint — Organisation v2 (`organisation-v2-abc9`, 2026-08-02)

**Goal:** Profile composer IA, view permissions, activity log, discover tiles, BDD gate ratchet.  
**Integration branch:** `cursor/organisation-v2-integration-abc9` → single PR to `main` when complete.  
**Control issue:** #537 · **Plan:** `.agents/plans/organisation-v2-abc9.md`

| Agent / phase | Branch | Owns | Avoid |
|---------------|--------|------|-------|
| F0-F1 docs | `cursor/org-v2-f0-docs-abc9` | `docs/experience-program/**`, `docs/architecture/pet-activity-model.md` | product code |
| F0-F2 perms | `cursor/org-v2-f0-perms-abc9` | `server/lib/orgPermissions.js`, permissions routes, Flutter org permission providers | profile UI |
| Slice 1+ | per snapshot | see `organisation-v2-delivery-plan.md` | — |
| 8a–9 hardening | `cursor/org-v2-8-9-hardening-abc9` | BDD completion (admin contacts, permissions, customisations); gate **150/231**; docs + FR l10n | — |

---

## Sprint — Organisation UX v3 (`organisation-ux-v3-badd`, 2026-08-04)

**Goal:** Show-org visibility, last-section login, org chrome, dashboard/discover IA, profile nav-rows, Account per-org privacy, people tiles, upload P0, pre-UAT green.  
**Integration branch:** `cursor/organisation-ux-v3-integration-badd` → single PR to `main`.  
**Plan:** `docs/experience-program/organisation-ux-v3-delivery-plan.md` · `.agents/plans/organisation-ux-v3-badd.md`  
**Control issue:** #567

| Agent / phase | Branch | Owns | Avoid |
|---------------|--------|------|-------|
| 0 docs | `cursor/org-ux-v3-0-docs-badd` | `docs/experience-program/**`, architecture pointers, debt issues | product code |
| 1 upload | `cursor/org-ux-v3-1-upload-badd` | org image upload routes + Flutter branding upload + edit BDD | profile IA |
| 2 visibility | `cursor/org-ux-v3-2-visibility-badd` | experience prefs, drawer, login last-section, Account toggle | org profile widgets |
| 3 chrome | `cursor/org-ux-v3-3-chrome-badd` | org shell app bar / teal scaffold | discover API |
| 4 dashboard | `cursor/org-ux-v3-4-dashboard-badd` | list screen My Orgs tiles + Discover row | discover search API |
| 5 discover | `cursor/org-ux-v3-5-discover-badd` | discoverRouter `?q=` + Discover screen + browse-as | profile composer |
| 6 profile header | `cursor/org-ux-v3-6-profile-header-badd` | profile/edit header, menus, upload CTAs | privacy migration |
| 7 profile nav | `cursor/org-ux-v3-7-profile-nav-badd` | member nav rows + Administration entry | people tile grid |
| 8 privacy | `cursor/org-ux-v3-8-account-privacy-badd` | migrations + privacy APIs + Account org settings | tile chrome |
| 9 people tiles | `cursor/org-ux-v3-9-people-tiles-badd` | Admin/Foster tile grids + person profile | connections screen |
| 10 deep screens | `cursor/org-ux-v3-10-deep-screens-badd` | connections cleanup + pets entry polish | Account privacy |
| 11 harden | `cursor/org-ux-v3-11-hardening-badd` | l10n, seeds, BDD gate **180/266**, scorecard | — |
| 12 integrate | `cursor/organisation-ux-v3-integration-badd` | integration→main + pre-UAT fix loop | — |

**Optional spawn (after ownership confirmed disjoint):** Phase 5 discover-api vs discover-ui; Phase 9 after shared `OrgPersonTile` foundation micro-PR.

