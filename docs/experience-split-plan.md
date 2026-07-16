# AgathaTrack experience split — implementation plan

**Branch:** `cursor/guardian-onboarding-wizard-17a0`  
**Status:** Phase 4.1 in progress — guardian onboarding wizard (pet + first reminder)  
**Last updated:** 2026-07-16 (post-#191 merge; Phase 4.1 in this PR)

Product decisions are locked in planning conversations. This document is the **execution tracker** for agents and humans.

**Locked decisions (2026-07-15):** see [Test governance](#test-governance-for-experience-split) and [Decisions](#decisions-locked).

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

### Phase 3 — Pet detail context (done)

| ID | Deliverable | Status |
|----|-------------|--------|
| 3.1 | `PetDetailActions` registry by experience + pet role | **Done** (#186) |
| 3.2 | Responsibility labels on pet header | **Done** (#186) |
| 3.3 | Foster role-filtered drawer | **Done** (#186) |

**Also in Phase 3 PR:** experience-aware back navigation on pet detail (`backPath` from `experienceHomePathProvider`). E2E shell nav hardening in #187.

### Phase 4 — Onboarding wizards

| ID | Deliverable | Status |
|----|-------------|--------|
| 4.1 | Guardian onboarding (pet + first reminder) | **In progress** (#TBD) |
| 4.2 | Org super-admin onboarding | Planned |
| 4.3 | Invited admin / foster flows | Planned |

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

### Phase 1 (done — see traceability matrix)

- **E1a** Guardian-only user skips chooser → `/g/home`
- **E1b** Org-only user skips chooser → `/o/home`
- **E1c** Dual user sees both cards + boarding disabled
- **E2** Remember choice + info box under tick
- **E2a** Settings → Default experience
- **E5** Drawer Org view / Pet guardian view

### Phase 2 (done — home content)

- **G-H1** Guardian home: due events + My Pets + grouped shared/fostered (no org inventory)
- **G-H2** Shared pets grouped by sharer/org label
- **O-H1** Org home: per-org sections + org-scoped due events
- **G-H3** Inline event actions on home due-event cards
- **G-H4** Scoped events dashboard (`/g/events`, `/o/events`)

### Phase 3 (pet detail context)

| Story | L1 | L2 | Status |
|-------|----|----|--------|
| **G1** | `pet_detail_actions_test.dart` (guardian owner) | `pet_detail_profile_card_test.dart` | **Done** |
| **G2** | `pet_detail_actions_test.dart` (shared carer) | profile card label + no edit | **Done** |
| **G3** | `pet_detail_actions_test.dart` (foster carer) | profile card foster label | **Done** |
| **G4** | `pet_detail_actions_test.dart` (org admin) | foster placement gate | **Done** |
| **G5** | `isFosterPortalUserProvider` | `experience_shell_scaffold_test.dart` | **Done** |

### Phase 3+ (remaining)

---

## Test governance for experience split

Coverage percentage is **necessary but insufficient**. All experience-split work must climb a **quality ladder** and satisfy **multi-dimensional CI gates** before non-draft merge.

### Quality ladder (L1–L4)

| Level | What | Examples (experience split) |
|-------|------|-----------------------------|
| **L1 — Contract** | Domain entities/services: pure logic, no UI | `AppExperience` wire/paths; `ExperienceEligibility` + negative cases; `resolvePostLoginPath`; `ExperiencePreferencesStore` |
| **L2 — Widget behaviour** | Screens/sections with provider overrides | Chooser card visibility; drawer org/guardian switch; guardian/org home sections; `DueEventRow` inline actions |
| **L3 — Integration** | Full app router + fakes, post-login flows | `pet_profile_flow_test` on `/g/home`; resolve → shell navigation; add-pet FAB in shell |
| **L4 — E2E / BDD** | Persona journeys, Playwright + Gherkin | `experience_navigation.feature` (6 scenarios); auth post-login destination |

**Rule:** A phase deliverable is not “tested” until it has at least **L1 + one of L2/L3**, and any user-facing journey also has **L4** when a BDD scenario exists.

### Traceability matrix (Phase 1–2)

Gaps drive PR B/C work. Status: **Done** · **Partial** · **Gap**.

| Story | BDD scenario | L1 unit | L2 widget | L3 integration | L4 Playwright | Status |
|-------|--------------|---------|-----------|----------------|---------------|--------|
| **E1a** | Guardian-only user lands on guardian home after login | `experience_eligibility_test.dart`, `app_experience_test.dart`, `resolve_post_login_path_test.dart` | `experience_chooser_screen_test.dart` | `pet_profile_flow_test.dart` | `experience.navigation.spec.ts` | **Done** |
| **E1b** | Organisation-only user lands on organisation home after login | `experience_eligibility_test.dart` (org-only), `resolve_post_login_path_test.dart` | — | — | `experience.navigation.spec.ts` | **Done** |
| **E1c** | Dual-role user sees experience chooser after login | `experience_eligibility_test.dart`, `resolve_post_login_path_test.dart` | `experience_chooser_screen_test.dart` | — | `experience.navigation.spec.ts` | **Done** |
| **E2** | Dual-role user remembers guardian choice | `experience_preferences_store_test.dart` | `experience_chooser_screen_test.dart` (hint) | — | `experience.navigation.spec.ts` | **Done** |
| **E2** | Remembered guardian choice skips chooser on next login | `experience_preferences_store_test.dart`, `resolve_post_login_path_test.dart` | — | — | `experience.navigation.spec.ts` | **Done** |
| **E2a** | Dual-role user sets default experience to organisation in settings | `experience_preferences_store_test.dart` | `experience_settings_section_test.dart` | — | `experience.navigation.spec.ts` | **Done** |
| **E5** | User switches to organisation view from guardian drawer | — | `experience_shell_scaffold_test.dart` (drawer) | — | `experience.navigation.spec.ts` | **Done** |
| **E1c** | Guardian chooser hides organisation option for guardian-only users | `experience_eligibility_test.dart` | `experience_chooser_screen_test.dart` | — | `experience.navigation.spec.ts` | **Done** |
| **G-H1** | *(pet_profiles.feature — future)* | `pet_list_controller_guardian_shell_test.dart` | — | `pet_profile_flow_test.dart` | — | **Partial** — L2 home sections |
| **G-H2** | *(grouping)* | `pet_list_controller_guardian_shell_test.dart` | — | — | — | **Partial** — L2/L4 |
| **O-H1** | *(organisation_management.feature — future)* | `pet_list_controller_guardian_shell_test.dart` (`orgShellPets`) | — | — | — | **Partial** — L2 org home |
| **G-H3** | *(health_tracking due events)* | — | `due_event_row_test.dart` | — | — | **Done** |
| **G-H4** | *(scoped events)* | `health_events_scope` (enum) | — | — | — | **Gap** — L2 health dashboard embedded |

*New stories must add a row before implementation merges.*

### CI gates (multi-dimensional)

| Gate | When | Requirement |
|------|------|-------------|
| **Domain coverage** | Every PR (merged lcov) | ≥ **65%** (PR A landed in #184); ratchet → **70%** after CI confirms headroom; **75%** after Tier C entity debt |
| **Per-file floor** | Long-term | No **logic-bearing** domain file &lt; **60%** (getters, parsing, eligibility, `fromJson` with branches) |
| **BDD priority map** | Every PR | All scenarios in `bdd-priority-tag-map.json` with `@P0`/`@P1`/`@P2` |
| **BDD coverage** | Every PR | ≥ 105 mapped scenarios (`check_bdd_coverage.js`) |
| **Changed-files test** | PR touches `lib/features/experience/**` | Same PR must add/update tests under `test/features/experience/**` (or linked controller/API tests) |
| **Critical journey** | Experience-split PRs before non-draft merge | All **P0** + applicable **P1** `experience_navigation.feature` scenarios green in CI |
| **Phase regression** | PR touches split-related code | Fast subset below must pass |

Pure data-only structs (fields + `const` constructor, no getters/parsing) are excluded from the per-file floor unless they gain logic.

### Coverage ratchet milestones

| Milestone | Target | Trigger |
|-----------|--------|---------|
| **Now (unblock)** | 65% overall domain | PR A: shard + experience L1 tests (**done in #184**) |
| **Same sprint** | **70%** overall domain | After #184 CI green; bump `DOMAIN_COVERAGE_THRESHOLD` |
| **After entity debt** | **75%** overall domain | PR C: org/sharing/notification entity tests |
| **Per-file floor** | ≥ 60% on logic-bearing domain files | Enforced in review; optional script later |

### L1 negative / mutation-style assertions

Core rules must include **failure paths**, not only happy paths:

| Rule | Negative assertion |
|------|-------------------|
| Saved default | Invalid / stale `savedDefault` → chooser (`resolveAutoExperience` → null) |
| Org-only user | Cannot auto-land guardian (`canUseGuardian` false → org home) |
| Guardian-only | Organisation card not in `availableExperiences` / chooser |
| Dual-role + no default | `showChooser` true; `resolvePostLoginPath` → `/app/choose` |
| Active experience override | Invalid `activeExperience` ignored; falls through to auto/chooser |
| `AppExperienceWire.fromWire` | Unknown wire → `null` |

File: expand `experience_eligibility_test.dart` + new `app_experience_test.dart` + `resolve_post_login_path_test.dart`.

### Flake prevention (shell architecture)

Encoded guidelines for all experience tests:

1. **Prefer keys** over broad finds: `Key('add_pet_button')`, `experience_nav_home`, `drawer_org_view` — not `find.byType(Scaffold).single`.
2. **Use helpers** in `test/helpers/test_helpers.dart`: `pumpGuardianHome()`, `l10nFromTester()` — anchor l10n from a shell widget, not an ambiguous root.
3. **Override eligibility** in integration tests: `experienceEligibilityProvider` → guardian-only or dual as needed.
4. **Avoid** `pumpAndSettle` on shells with `CircularProgressIndicator` unless bounded; use `pumpApp` / keyed waits.
5. **Provider overrides** in widget tests — do not spin full GoRouter unless testing routing.

### Phase regression suite (fast PR gate)

When any of `lib/features/experience/**`, `experience_routes.dart`, `experience_navigation.feature`, or Phase 2 home widgets change, CI must run at minimum:

**Flutter (L1 + L3)**

- `test/features/experience/` (all files)
- `test/features/pet_profile/presentation/controllers/pet_list_controller_guardian_shell_test.dart`
- `test/features/pet_profile/presentation/integration/pet_profile_flow_test.dart` (integration job)

**Playwright (L4 — P0/P1 subset)**

| Priority | Scenario |
|----------|----------|
| P0 | Guardian-only user lands on guardian home after login |
| P1 | Dual-role user sees experience chooser after login |
| P1 | Dual-role user remembers guardian choice |
| P1 | Remembered guardian choice skips chooser on next login |
| P1 | User switches to organisation view from guardian drawer |

Full 6-scenario `experience.navigation.spec.ts` + nightly E2E shards for broader regression.

### Implementation sequencing (PRs)

| PR | Scope | Quality levels | Unblocks |
|----|--------|----------------|----------|
| **PR A** | Tier A: add `test/features/experience` to **`rest` CI shard**; `app_experience_test`; expand eligibility negatives; `resolvePostLoginPath` L1 | L1 | Domain coverage ≥ 65% → 70% ratchet |
| **PR B** | Tier B: shell/chooser/home widget tests; `due_event_row_test`; settings section | L2 (+ L1 gaps) | Behaviour hardening |
| **PR C** | Tier C: org/sharing entity domain debt (archived_pet, pet_access, organization, etc.) | L1 | Headroom → 75% ratchet |

**Do not** add a dedicated `experience` CI shard unless `rest` shard runtime becomes a bottleneck.

---

## Decisions (locked)

| # | Decision | Choice |
|---|----------|--------|
| 1 | **CI shard placement** | Include `test/features/experience` in **`rest` shard** now; revisit dedicated shard only if runtime bottlenecks |
| 2 | **Scope sequencing** | **PR A** → **PR B** → **PR C** (as table above) |
| 3 | **Coverage ratchet** | Gate bumped to **70%** in #184 (measured **72.4%**); **75%** after PR C |
| 4 | **Merge readiness** | Experience-split PRs require all **P0** + applicable **P1** `experience_navigation` scenarios green before **non-draft** merge |

---

## BDD feature files

| Feature | Phase |
|---------|-------|
| `experience_navigation.feature` | 1 |
| `authentication.feature` (update post-login destination) | 1 |
| `pet_profiles.feature` (guardian home paths) | 2 |
| `organisation_management.feature` (org shell paths) | 2 |

---

## Test strategy (summary)

1. **Quality ladder:** L1 contract → L2 widget → L3 integration → L4 BDD (see [Test governance](#test-governance-for-experience-split)).
2. **TDD:** L1 before UI for eligibility, preferences, route resolution.
3. **Traceability:** Every story row in the matrix must be updated in the same PR that closes the story.
4. **BDD:** Gherkin `Scenario:` titles must match Playwright `@bdd` headers exactly.
5. **Pre-push:** `./scripts/pre-push-changed.sh` during iteration; `./scripts/pre-push.sh` before merge to `main`.
6. **Domain coverage:** `flutter_app/scripts/merge_flutter_coverage.sh` after all four shards; gate per ratchet table.

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
| 2026-07-15 | Test | Test governance locked: quality ladder L1–L4, traceability matrix, CI gates, PR A/B/C sequencing, ratchet 65→70→75 |
| 2026-07-15 | Test | PR A+B implemented: experience in `rest` shard; L1 (`app_experience`, eligibility negatives, `resolvePostLoginPath`); L2 (shell, settings, `due_event_row`); entity headroom (`archived_pet`, `pet_access`) |
| 2026-07-15 | — | **#184 merged** to `main` (Phases 1–2 + test coverage) |
| 2026-07-15 | 3 | Phase 3: `PetDetailActions` registry, responsibility labels, foster portal drawer filter, experience-aware pet detail back nav |
| 2026-07-16 | — | **#186/#187 merged** — Phase 3 + E2E shell hardening |
| 2026-07-16 | E1b | Org-only post-login landing: BDD scenario + Playwright |
| 2026-07-16 | E2a | Settings default experience: BDD scenario + Playwright |
