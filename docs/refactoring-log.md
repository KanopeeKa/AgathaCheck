# Refactoring log (by sprint)

Tracks planned and completed refactor / quality work. See also `docs/refactoring-debt.md` and `docs/architecture/modularity.md`.

**Policy:** Multi-agent / sprint milestones use an **integration branch** → single PR to `main`. Single-agent domain PRs may go direct to `main`. Full E2E on UAT only. See `.cursor/rules/merge-policy.mdc` and `.cursor/rules/agent-coordination.mdc`.

---

## Sprint 1 — Governance & CI (2026-07-07)

**Goal:** Codify standards in Cursor + CI; security and a11y pipelines; no product refactors.

| # | Action | Status | PR / notes |
|---|--------|--------|------------|
| 1.1 | Cursor rules (modularity, testing, security, dual-backend, a11y, merge-policy) | Done | `.cursor/rules/` |
| 1.2 | `CONTRIBUTING.md` + PR template | Done | |
| 1.3 | `docs/quality/scorecard.md` | Done | |
| 1.4 | CI: `npm audit --audit-level=high` (server + e2e) | Done | `_reusable-test.yml` |
| 1.5 | CI: CodeQL JavaScript | Done | `codeql.yml` |
| 1.6 | Dependabot (server, e2e, flutter_app pub) | Done | `dependabot.yml` |
| 1.7 | CI: `dart analyze lib` on server | Done | |
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

## Sprint 6 — Org-operator BDD + help (planned)

**Integration branch:** `cursor/sprint-6-org-bdd-integration-13e3`

| # | Action | Status | Parallel agents | Owns |
|---|--------|--------|-----------------|------|
| 6.1 | Playwright: `organisation_pet_management.feature` (6) | Planned | 1 | `organisation.pet.management.spec.ts` + org pet pages |
| 6.2 | Playwright: org custody features (`org_foster_and_adoption`, `org_to_org_transfer`, `org_pet_return`, sharing/shadow) | Unblocked (API) | 1 | `adoption.spec.ts` — custody APIs + rewritten Gherkin on `cursor/org-custody-integration-13e3` |
| 6.3 | Playwright: `organisation_pet_timeline.feature` (subset 4/6) | Planned | 1 | `org.timeline.spec.ts` |
| 6.4 | Playwright: `help_faq.feature` (10) | Planned | 1 | `help.faq.spec.ts` |
| 6.5 | Realign `@smoke` + axe to P0 guardian paths | Planned | 1 | `e2e/playwright/tests/` smoke titles only |

**Parallelism:** 6.1 + 6.4 can run together (disjoint). 6.2 backend custody model landed in org-custody PR (migration 020, shadow snapshots, connections, pending transfers). 6.3 after 6.1 (shared org pet fixtures). Foundation agent extends `api.ts` once.

**Exit gate:** BDD ≥ **105/161 (65%)** + persona gate: ≥ **80% of @P1 guardian scenarios** (once tags land in 5.6).

---

## Sprint 7 — Compliance + subscriptions (planned)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 7.1 | Gherkin + Playwright: GDPR export + account delete (J13) | Planned | After 5.5 export payload complete |
| 7.2 | `subscriptions.feature` E2E (subset) | Planned | UAT RevenueCat sandbox required |
| 7.3 | Clear grandfather allowlist entries (all files <500) | Planned | After 5.4 splits |
| 7.4 | BDD gate ratchet to **105/161 (65%)** in CI | Planned | |

---

## Sprint 8 — Agent efficiency infrastructure (in progress)

**Goal:** Reduce agent token burn; encode recurring workflows as Skills; changed-files pre-push.  
**Plan:** `docs/agent-efficiency-plan.md`

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 8.1 | Master plan + architecture index | **Done** | `docs/agent-efficiency-plan.md`, `docs/architecture/index.md` |
| 8.2 | `scripts/pre-push.sh` + `pre-push-changed.sh` | **Done** | Single verify source of truth |
| 8.3 | Six Cursor Skills | **Done** | `.cursor/skills/` |
| 8.4 | Slim `agent-core.mdc`; scope path rules | **Done** | Less always-on duplication |
| 8.5 | `/babysit` + PR governance hints workflow | **Done** | Advisory only; CI unchanged |
| 8.6 | Prompt templates + slim AGENTS.md | **Done** | `docs/agent-efficiency/prompt-templates.md` |

**Exit:** Merged to `main`. Resume Sprint 6 functional work after merge.

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


| Date | Change |
|---|---|
| 2026-07-09 | Sprint 8: agent efficiency infra — Skills, pre-push scripts, scoped rules, babysit |
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
