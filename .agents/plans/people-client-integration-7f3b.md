# People client integration — execute-plan (`people-client-integration-7f3b`)

| Field | Value |
|-------|-------|
| **plan_id** | `people-client-integration-7f3b` |
| **parent** | roadmap [`people-domain-refactor-7f3b`](./people-domain-refactor-7f3b.md), child 4 of 4 |
| **title** | Consumers use the façade and picker, People around {pet}, legacy deleted, integration E2E, docs shipped |
| **base_branch** | `cursor/people-client-integration-integration-7f3b` (created from `origin/main` at bootstrap) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **phases** | 5 (commit prefix `phase(<n>/5): …`) |
| **entry gate** | On `origin/main`: `people-client-core-7f3b`, CARE E+F (absences on real occurrences, Care Item module, care E2E programme) and ARCH G (client authority, pet cache, pet detail migration). Landing slot 8 in [parallel-programmes §4](../../docs/agent-efficiency/parallel-programmes.md) |
| **source of truth** | [target doc](../../docs/domains/people/changes/people-domain-refactor.md) §3.7, §3.8 (People around {pet}, pickers), §5 |

## Goal

Finish the People refactor where it meets the rest of the app:

- every contact choice and display outside People goes through the façade and the one picker (pet profile, care, Away Planning, PDF report);
- each pet profile gets "People around {pet}" with the emergency card;
- the last legacy People and vet client code is deleted, and both architecture tests become strict;
- the integration journeys are covered and the docs describe the shipped state.

Fixes B7 and B8 for good.

## Rules for every phase (in addition to the roadmap locks)

- **Start of phase:** rebase on `origin/main`; run the full `./scripts/pre-push.sh` after any landing broadcast.
- **Areas released to this child:** care UI, absences and pet profile, now that CARE E+F and ARCH G have landed. Work **against CARE's Care Item module public API and ARCH G's controllers/store**, not around them. If a needed hook is missing, add it through that module's public API in the same PR, and note it in the PR body for the CARE/ARCH owners.
- **E2E stays green in every phase:** update the affected specs and page objects in the same PR. At phase start run `node e2e/scripts/shard-files.mjs --summary` and pass the shard indices for every spec you touch (health, People hub/desk, vets, etc. — lists change when TEST rebalance lands). Then `./scripts/pre-push-changed.sh --e2e-shards <indices>` against `bin/start.js`. Shared E2E files are append-only.
- `node scripts/check_feature_imports.js` green; the baseline may only shrink.

---

### Phase 1 — `i1-consumers` · Pet profile, care, Away Planning and report use the façade

| Field | Value |
|-------|-------|
| **id** | `i1-consumers` |
| **ordinal** | 1/5 |
| **branch** | `cursor/people-integration-i1-consumers-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `api-contract`, `accessibility`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/**
flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/pet_detail_profile_card.dart
flutter_app/lib/features/pet_profile/presentation/providers/pet_vet_contacts_provider.dart
flutter_app/lib/features/pet_profile/presentation/controllers/**
flutter_app/lib/features/pet_profile/data/services/pet_report_service.dart
flutter_app/lib/features/pet_profile/data/services/pet_report_profile_section.dart
flutter_app/lib/features/health_tracking/**
flutter_app/lib/features/pet_care/context/**
flutter_app/lib/features/people/**
flutter_app/lib/l10n/**
flutter_app/test/features/pet_profile/**
flutter_app/test/features/health_tracking/**
flutter_app/test/features/pet_care/**
flutter_app/test/features/people/**
e2e/playwright/pages/**
e2e/playwright/tests/health.tracking.spec.ts
e2e/playwright/tests/away.planning.spec.ts
e2e/playwright/tests/away.plan.detail.v2.spec.ts
e2e/playwright/tests/away.care.planning.spec.ts
e2e/playwright/tests/veterinarian.spec.ts
e2e/playwright/tests/pet.profiles.spec.ts
.agents/plans/people-client-integration-7f3b.md
.agents/plans/people-client-integration-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** Every contact choice and display outside the People screens uses the façade and the `PeoplePicker`, backed by relationships. This fixes B7 and B8.

**Scope:**

- **Pet form and pet profile card:** a Primary vet `PeoplePickerField`. Save calls `setSlot(primary_vet)`; the new client stops writing `vet_id`. Delete `PetVetOption` / `petVetOptionsProvider`.
- **Care provider** (inside CARE's Care Item form and occurrence sheets, through their public API) → `PeoplePickerField` with `allowTypedName` (D-CIE-016), inactive current pinned (**B8**). Provider names resolve through the façade, so they work for co-parents.
- **Away Planning carer choice** (CARE's absence UI) → picker with carers plus household members; the empty state offers quick add.
- **PDF report and handover** read `petPeopleProvider`: primary vet with full coordinates, out-of-hours vet, emergency contacts (**B7** for good). Remove `fetchPetPeopleRelationships` from `pet_care/context` data and the raw-map parsing in `away_plan_copy.dart`.
- Remove the pet_profile, health_tracking and pet_care entries from the People architecture-test allowlist.

**Exit criteria:**

- [ ] B7 regression (report vet coordinates) and B8 regression (inactive not offered; unknown current renders) kept green in their new locations
- [ ] Widget tests for each migrated field (selection, clear, quick add, typed name for provider)
- [ ] No file in pet_profile, health_tracking or pet_care imports People internals; `--e2e-shards` (from `shard-files.mjs --summary`) green

---

### Phase 2 — `i2-pet-people` · People around {pet} and emergency card

| Field | Value |
|-------|-------|
| **id** | `i2-pet-people` |
| **ordinal** | 2/5 |
| **branch** | `cursor/people-integration-i2-pet-people-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/features/pet_profile/presentation/screens/pet_detail_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/**
flutter_app/lib/features/experience/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/pet_profile/**
flutter_app/test/features/experience/**
e2e/playwright/pages/**
e2e/playwright/tests/pet.profiles.spec.ts
.agents/plans/people-client-integration-7f3b.md
.agents/plans/people-client-integration-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** Each pet profile shows the people around that pet: an emergency card with one-tap call and grouped household, carers and professionals, editable through slot pickers.

**Scope** (target doc §3.8 People around {pet}; vocabulary § Pet profile):

- `PetEmergencyCard`: primary vet, out-of-hours vet, emergency contacts with Call; Manage opens `SlotPickerRow`s; empty slots are labels.
- `PetPeopleSection` with At home / Trusted carers / Pet professionals; the owner shown quietly.
- Mount it wherever the pet detail composition lives on `main` at the time: in `pet_profile`, or in `experience` if ARCH has already moved pet-profile surfaces there (I2). Export it from `people.dart` either way. Can log care sees the handover scope only, without Manage.
- The vet row in `pet_detail_profile_card.dart` is replaced by the section.

**Exit criteria:**

- [ ] Widget tests: owner vs Can log care, set/clear out-of-hours vet, add/reorder emergency contacts, call only with a phone
- [ ] `--e2e-shards` (from `shard-files.mjs --summary`) green

---

### Phase 3 — `i3-retire-legacy` · Delete legacy code; guards strict

| Field | Value |
|-------|-------|
| **id** | `i3-retire-legacy` |
| **ordinal** | 3/5 |
| **branch** | `cursor/people-integration-i3-retire-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R1 |
| **protocols** | `testing`, `documentation` |

**allowed_paths:**

```
flutter_app/lib/features/vet/**
flutter_app/test/features/vet/**
flutter_app/lib/features/people/**
flutter_app/test/features/people/**
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_my_vets_section.dart
flutter_app/test/features/experience/**
flutter_app/lib/core/router/vet_routes.dart
flutter_app/lib/core/router/experience_routes.dart
flutter_app/test/core/router/**
server/lib/people/**
server/test/people/**
docs/architecture/api-reference.md
.agents/plans/people-client-integration-7f3b.md
.agents/plans/people-client-integration-7f3b.snapshot.json
```

**forbidden_paths:**

```
db/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `file-split`, `governance-allowlist`, `docs`

**Outcome:** No legacy People or vet client code remains, and both architecture tests run with empty allowlists.

**Scope:**

- Delete:
  - Flutter `features/vet/**` entirely (after checking with grep that nothing imports it);
  - `PetCareMyVetsSection`;
  - the legacy People files and deprecated adapters (`PeopleContact`, `PeopleContactModel`, `PeopleRemoteDataSource`, `PersonRosterEntry`, `PeopleDirectoryCard`, legacy providers, `people_legacy_vet_redirect_screen.dart`).
- Legacy vet deep links resolve through a small route resolver calling `GET /api/people/contacts/by-legacy-vet/:vetId`, falling back to `/pc/people?filter=professionals`.
- `grep -rn legacyVetId flutter_app/lib` is empty.
- Server: remove the two-way shims left in `vetSync.js` / `petVetLink.js`. Mark `/api/vets` **deprecated** in the API reference.
- Empty both architecture-test allowlists. Remove file-size allowlist entries for deleted files (`governance-allowlist`).
- Open the debt issue "Sunset `vets` table and `pets.vet_id` behind a minimum-client-version gate" (R-01).

**Exit criteria:**

- [ ] `features/vet/` gone; `legacyVetId` absent from `flutter_app/lib`; both architecture tests pass with empty allowlists
- [ ] Legacy vet route tests (resolved and unresolved) pass; analyze, Flutter tests and Jest green; sunset debt issue linked on the control issue

---

### Phase 4 — `i4-e2e-integration` · Integration journeys

| Field | Value |
|-------|-------|
| **id** | `i4-e2e-integration` |
| **ordinal** | 4/5 |
| **branch** | `cursor/people-integration-i4-e2e-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |
| **router_risk** | R2 |
| **protocols** | `testing`, `release-verification`, `accessibility` |

**allowed_paths:**

```
flutter_app/test/bdd/features/people.feature
flutter_app/test/bdd/features/away_planning.feature
flutter_app/test/bdd/features/health_tracking.feature
flutter_app/test/bdd/features/pet_profiles.feature
e2e/playwright/**
scripts/bdd-priority-tag-map.json
e2e/scripts/shard-files.mjs
docs/e2e/**
flutter_app/lib/features/people/**
.agents/plans/people-client-integration-7f3b.md
.agents/plans/people-client-integration-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `docs`

**Outcome:** The places where People meets pet profile, care and Away Planning are covered by journeys. Edits under `flutter_app/lib/features/people/**` are limited to keys and semantics.

**Scope:**

- Scenarios (Gherkin `Scenario:` titles match the `@bdd` headers exactly):
  1. Buddy's emergency card shows the primary vet set from Contacts, with a call action
  2. Set Buddy's out-of-hours vet from People around Buddy
  3. Pick a care provider and add a new one inline from the Care Item form
  4. Assign an absence carer with the picker; the handover lists emergency contacts and vets
  5. An inactive contact isn't offered in the care provider picker but stays visible on items already using it
- Extend `people.page.ts`; reuse CARE's care-item and absence page objects rather than duplicating them. Append to `support/api.ts` only.

**Exit criteria:**

- [ ] All 5 scenarios have Gherkin and Playwright specs; BDD coverage ≥ baseline; shard manifest valid
- [ ] Specs pass locally against `bin/start.js`

---

### Phase 5 — `i5-ship-main` · Integration → main; docs describe the shipped state

| Field | Value |
|-------|-------|
| **id** | `i5-ship-main` |
| **ordinal** | 5/5 |
| **branch** | `cursor/people-integration-i5-ship-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `release-verification`, `documentation` |

**allowed_paths:**

```
docs/domains/people/**
docs/design/terminology.md
docs/architecture/index.md
docs/debt/refactoring-log.md
docs/agent-efficiency/parallel-programmes.md
.agents/memory/MEMORY.md
.agents/plans/people-client-integration-7f3b.md
.agents/plans/people-client-integration-7f3b.snapshot.json
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
.github/workflows/**
server/**
```

**allowed_exceptions:** `docs`

**Outcome:** The People refactor is complete on `main` with pre-UAT green, and the docs describe the shipped state.

**Scope:**

- **Docs:**
  - People README status "Shipped";
  - target doc `status: implemented`;
  - move shipped vocabulary rows into `terminology.md` per the vocabulary ship checklist (keep `vocabulary.md` for rows not yet shipped);
  - `MEMORY.md` entry (People façade, boundary tests, relationships as source of truth);
  - refactoring-log completion.
- Rule 1 of parallel-programmes §5 (no other `main` PR open). Rebase; `./scripts/pre-push.sh`. Open **one** integration → `main` PR; the merge payload is the whole integration branch.
- `/babysit-uat` until pre-UAT is green (on failure: `/e2e-debug` → `/babysit-uat`).
- `complete-plan people-client-integration-7f3b --write`, roadmap `roadmap-set-child … merged`, then `complete-plan people-domain-refactor-7f3b --write`. Post the landing broadcast.

**Exit criteria:**

- [ ] Integration PR merged; pre-UAT green on the merge commit; roadmap closed; broadcast posted

---

## Runtime state (agent-updated)

```yaml
autonomy: halted            # draft — bootstrapped by the roadmap when the entry gate is met
current_phase: null
last_completed_phase: null
halt_reason: "draft — waiting for people-client-core-7f3b, CARE E+F and ARCH G on main"
next_action: "roadmap bootstraps at landing slot 8"
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
