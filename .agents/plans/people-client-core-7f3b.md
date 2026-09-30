# People client core — execute-plan (`people-client-core-7f3b`)

| Field | Value |
|-------|-------|
| **plan_id** | `people-client-core-7f3b` |
| **parent** | roadmap [`people-domain-refactor-7f3b`](./people-domain-refactor-7f3b.md), child 3 of 4 |
| **title** | Typed People core and façade, components and picker, hub, detail, edit, add, household UI, with E2E |
| **base_branch** | `cursor/people-client-core-integration-7f3b` (created from `origin/main` at bootstrap) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **phases** | 9 (commit prefix `phase(<n>/9): …`) |
| **entry gate** | On `origin/main`: `people-server-7f3b` **and** CARE C+D (agenda, row, form; they touch the Today home content and the care form). Landing slot 5c in [parallel-programmes §4](../../docs/agent-efficiency/parallel-programmes.md); People-owned client files only |
| **source of truth** | [target doc](../../docs/domains/people/changes/people-domain-refactor.md) §3.7 (Flutter architecture) and §3.8 (UI/UX) |

## Goal

Rebuild the People feature on a typed, layered core and ship the People-owned screens to the §3.8 spec:

- `people.dart` façade and one set of person components;
- `PeoplePicker`;
- roster hub with working desktop list–detail and the Today desk;
- detail with tabs; edit with a danger zone; the five-step add flow;
- household management inside People.

Other features (pet profile, care, Away Planning, report) keep working through **deprecated adapters** until `people-client-integration-7f3b` migrates them. Fixes B1 for good (typed equality), and B4 and B5 in the new hub and desk.

## Rules for every phase (in addition to the roadmap locks)

- **Start of phase:** rebase on `origin/main`; run the full `./scripts/pre-push.sh` after any landing broadcast.
- **Areas released to this child:** People client (`flutter_app/lib/features/people/**`), the Today desk module and home content, People routes and households UI. **Not released:** care UI (`health_tracking/presentation/**`), absences (`pet_care/context/**`), and pet profile screens and sections. Don't edit those here.
- **E2E stays green in every phase:** each UI phase updates the existing specs and page objects it affects **in the same PR** and runs `./scripts/pre-push-changed.sh --e2e-shards 3,9` against `bin/start.js` (AGENTS.md single-origin). Shard 3 covers the People hub, desk, nav and Away Planning; shard 9 covers vets. Shared E2E files (`support/api.ts`, `shard-files.mjs`, tags) are append-only.
- **Feature-import gate (ARCH D):** `node scripts/check_feature_imports.js` green; the baseline may only shrink.
- Files ≤300 lines ideally, ≤500 hard; no private widget over 80 lines in a page file.

---

### Phase 1 — `c1-flutter-core` · Typed domain, repository, application layer, façade

| Field | Value |
|-------|-------|
| **id** | `c1-flutter-core` |
| **ordinal** | 1/9 |
| **branch** | `cursor/people-client-c1-core-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `api-contract`, `flutter-mobile`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** The Flutter People feature has a typed, layered core (domain, data, application) exposed through `people.dart`; legacy providers become thin deprecated adapters.

**Scope** (target doc §3.7):

- **Domain:**
  - enums `ContactKind`, `ContactRole` (`group` from the wire value), `ContactGroup`, `RelationshipKind`, `ContactStatus`;
  - immutable entities with hand-written `==`/`hashCode`: `ContactSummary`, `ContactDetail`, sealed `Person` (contact / household member / pending invite), `Roster`, `PetRelationship`, `PetPeople`, `RelatedCare`, `ContactUsage`, `Household`, `HouseholdMember`, `HouseholdInvite`;
  - pure services `roster_sections`, `roster_search`, `desk_ranking`.
- **Data:**
  - DTOs (the only place wire strings live);
  - `people_api.dart` and `households_api.dart` on `authHttpClientProvider`, following ARCH H's port/transport convention if published;
  - `PeopleApiException(code, statusCode, usages)`;
  - `PeopleRepository` / `HouseholdsRepository` interfaces in the domain, implementations in data.
- **Application:**
  - `rosterProvider`, `personSummaryProvider(id)`, `personDetailProvider(id)` (a single fetch that never writes back into other providers), `relatedCareProvider(id)`, `petPeopleProvider(petId)`, households providers;
  - `people_commands.dart` with targeted invalidation.
- `presentation/labels/` enum → l10n extensions; ARB keys EN/FR for every role, kind, group, relationship kind and status.
- Legacy `peopleContactsProvider` / `peopleContactByIdProvider` / `peopleContactDetailProvider` re-implemented as **deprecated adapters** over the repository, so pet profile, care, Away Planning and report keep working.
- `people.dart` exports domain, labels and application.
- `test/features/people/architecture_test.dart`:
  - outside `features/people/`, only `people.dart` may be imported;
  - `presentation/` never imports `data/`.
  - Temporary allowlist: the current external violators (pet_profile vet provider/section, health_tracking provider field and info section, away plan carer dialog, core router), emptied by `people-client-integration-7f3b`.

**Exit criteria:**

- [ ] Unit tests: DTO round-trips (unknown enum values included), equality, sections, search, desk ranking
- [ ] Application tests with a fake repository: one fetch per detail open (B1 regression kept from the hotfix); commands invalidate exactly roster, detail and petPeople
- [ ] Architecture test green with the documented allowlist; analyze and tests green

---

### Phase 2 — `c2-components` · Person components and the one PeoplePicker

| Field | Value |
|-------|-------|
| **id** | `c2-components` |
| **ordinal** | 2/9 |
| **branch** | `cursor/people-client-c2-components-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
docs/e2e/navigation-contract.md
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `file-split`, `docs`

**Outcome:** One tested set of design-system person components and a single `PeoplePicker`, ready for every surface.

**Scope** (target doc §3.8 Shared components; [system.md](../../docs/design/system.md) §6.5, §6.8, §6.10):

- `PersonAvatar`, `PersonCard` (regular and compact), `PersonStatusChip` (neutral Inactive, warning Needs review, info Invited / Access until), `RoleChips` (display and grouped-select), `ContactActionBar` (Call / Message / Email / Directions, overflow Website, hidden without data, long-press copy), `PersonSkeleton`.
- `PeopleQuery`: groups, roles, kinds, household members, `currentId` pinned even if inactive, `allowNone`, `allowTypedName`, pet scope.
- `PeoplePickerField` + `PeoplePickerSheet` (compact bottom sheet / 480px dialog, search, sections, "Add '{query}'" → `QuickAddPersonSheet`, "Use '{query}' without saving").
- Stable keys: `people_card_<id>`, `people_picker_field_<purpose>`, `people_picker_option_<id>`, `people_picker_add`, `people_action_<call|message|email|directions>`. Document them in `docs/e2e/navigation-contract.md` § People. Export via `people.dart`.

**Exit criteria:**

- [ ] Widget tests for every component and picker behaviour (inactive current pinned, inactive not offered, none, quick add returns the created person, typed-name option)
- [ ] Touch targets ≥48; 200% text scale without overflow; state never by colour alone
- [ ] Keys documented; analyze and tests green

---

### Phase 3 — `c3-hub` · Roster hub, search and filters, list–detail, Today desk

| Field | Value |
|-------|-------|
| **id** | `c3-hub` |
| **ordinal** | 3/9 |
| **branch** | `cursor/people-client-c3-hub-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_people_desk_module.dart
flutter_app/lib/features/experience/presentation/widgets/pet_care_shell_home_content.dart
flutter_app/lib/core/router/experience_routes.dart
flutter_app/lib/core/router/vet_routes.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/experience/**
flutter_app/test/core/router/**
e2e/playwright/pages/**
e2e/playwright/tests/people-hub.spec.ts
e2e/playwright/tests/guardian.dashboard.spec.ts
e2e/playwright/tests/guardian.navigation.spec.ts
e2e/playwright/tests/veterinarian.spec.ts
flutter_app/test/bdd/features/people.feature
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/health_tracking/**
flutter_app/lib/features/pet_care/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** The Contacts hub shows the full roster (households with members, carers, professionals, invites, inactive), with full search, canonical filters and a working desktop list–detail, and the Today desk uses the same model. This fixes B4 and B5 on the new code.

**Scope** (target doc §3.8 Hub, Today desk; R-08):

- `presentation/routes/people_routes.dart`: a feature-owned `ShellRoute` for `/pc/people` (builder `PeopleHubLayout`) with child routes `:personId`, `:personId/edit`, `new`, `households`. Included by `experience_routes.dart`. `/account/people` and `/pc/vets*` redirects keep working (`?filter=professionals`).
- `PeopleHubLayout`:
  - compact shows the child;
  - ≥840px shows a 380–420px list plus the child, or a placeholder;
  - the experience shell wraps the whole layout (B4);
  - selection via `context.go` keeping `q` and `filter`.
- `RosterList`:
  - household sections with members and tier/organiser lines, Trusted carers, Pet professionals, Pending invites, collapsed Inactive (n);
  - empty sections omitted;
  - skeleton, illustrated empty state and error with Retry.
- Full search with match highlight; `CollectionFilterBar` (Group, Kind, Pet, Status) synced to the URL.
- Desk module moves to `features/people/presentation/desk/`:
  - Vet team (vet slot or vet/vet nurse role), Trusted carers ranking, member rail → detail;
  - all labels localized (B5);
  - the experience home imports it via `people.dart`.
- Delete the old list and hub screens.
- Update affected Playwright specs and page objects in the same PR.

**Exit criteria:**

- [ ] Widget tests: sections (members, invites), search over role/email/pet, filters and URL state, empty/loading/error
- [ ] Widget test at 1280×800: detail in the pane, shell outside the split, search survives selection (B4)
- [ ] Desk tests: localized role line (B5), Vet team rule, ranking, member rail
- [ ] `./scripts/pre-push-changed.sh --e2e-shards 3,9` green with the updated specs

---

### Phase 4 — `c4-detail` · Person detail with header, action bar and tabs

| Field | Value |
|-------|-------|
| **id** | `c4-detail` |
| **ordinal** | 4/9 |
| **branch** | `cursor/people-client-c4-detail-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
e2e/playwright/pages/**
e2e/playwright/tests/people-hub.spec.ts
e2e/playwright/tests/veterinarian.spec.ts
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/health_tracking/**
flutter_app/lib/features/pet_care/**
flutter_app/lib/features/pet_profile/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** Person detail shows who someone is and how they relate to your pets and care: header, action bar and Overview / Pets & access / Related care / Notes tabs, with member and invite variants.

**Scope** (target doc §3.8 Person detail):

- `PersonDetailPage`: header from `personSummaryProvider` immediately, body from `personDetailProvider`. Edit in the app bar; no destructive actions.
- **Tabs**, one file each:
  - **Overview:** details with copy, Next up card, staff list, notes preview.
  - **Pets & access:** relationship chips, access line, "Link to a pet" → command.
  - **Related care:** for carers and professionals.
  - **Notes:** private and household, inline edit with explicit Save.
- **Variants:** household member; pending invite.
- Delete the legacy detail screen and coordinates section. Update the affected specs.

**Exit criteria:**

- [ ] Widget tests per tab and variant; "Link to a pet" invalidates detail and petPeople
- [ ] Tabs and action bar labelled for screen readers; no raw error text
- [ ] `--e2e-shards 3,9` green

---

### Phase 5 — `c5-edit` · Person edit with relationship editor and danger zone

| Field | Value |
|-------|-------|
| **id** | `c5-edit` |
| **ordinal** | 5/9 |
| **branch** | `cursor/people-client-c5-edit-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `flutter-mobile`, `data-lifecycle`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
e2e/playwright/pages/**
e2e/playwright/tests/people-hub.spec.ts
e2e/playwright/tests/veterinarian.spec.ts
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/health_tracking/**
flutter_app/lib/features/pet_care/**
flutter_app/lib/features/pet_profile/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** Everything about a person can be edited in one calm form, and destructive actions live only in a danger zone that shows what each action affects. B13 is fixed for good.

**Scope** (target doc §3.8 Person edit):

- `PersonFormController` (shared with `c6`): field state, inline validation, dirty tracking, submit, and error mapping by `PeopleApiException.code`.
- `PersonEditPage` with `AppFormSection` sections:
  - **Identity:** kind, grouped roles; read-only when linked.
  - **Works at:** organisation picker.
  - **Contact details.**
  - **Notes.**
  - **Pets:** relationship editor, slot replace confirmation, emergency-contact reorder.
- Sticky `AppFormActionsBar` and discard dialog.
- **Danger zone:**
  - Mark inactive / Reactivate.
  - Remove → `UsagesDialog` on 409, with "Replace…" links and "Mark inactive instead".
  - Household member: remove with removal preview and the two spec choices.
  - Invite: revoke.
- Delete the legacy edit screen. Update the affected specs (the vet edit/delete flows in `veterinarian.spec.ts`).

**Exit criteria:**

- [ ] Widget tests: validation, roles/kind edit, linked read-only, slot replace, reactivate, usages dialog, removal preview
- [ ] Discard dialog on dirty back; no raw exception text
- [ ] `--e2e-shards 3,9` green

---

### Phase 6 — `c6-add` · Unified add flow with sharing and household-invite handoff

| Field | Value |
|-------|-------|
| **id** | `c6-add` |
| **ordinal** | 6/9 |
| **branch** | `cursor/people-client-c6-add-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `flutter-mobile`, `authorization`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/features/sharing/presentation/providers/share_pet_providers.dart
flutter_app/lib/features/sharing/presentation/screens/share_pet_screen.dart
flutter_app/lib/features/sharing/presentation/widgets/share_invite_form.dart
flutter_app/lib/features/sharing/presentation/widgets/share_pet_owner_body.dart
flutter_app/lib/features/sharing/data/**
flutter_app/lib/features/sharing/domain/repositories/sharing_repository.dart
flutter_app/lib/core/router/experience_routes.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/sharing/**
e2e/playwright/pages/**
e2e/playwright/tests/people-hub.spec.ts
e2e/playwright/tests/veterinarian.spec.ts
e2e/playwright/tests/sharing.spec.ts
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/health_tracking/**
flutter_app/lib/features/pet_care/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** Anyone can be added in one short, guided flow that sets kind explicitly, links pets, and optionally hands off to sharing or a household invite already linked to the new contact. B9 is fixed for good.

**Scope** (target doc §3.8 Add person; vocabulary § Adding someone):

- `AddPersonFlow` (compact full-screen with "Step n of 5"; expanded 560px dialog):
  1. **Who** (four tiles).
  2. **About them** (live duplicate card, never merges).
  3. **How do they help** (grouped roles, no default).
  4. **Which pets** (per-pet relationship kind).
  5. **App access:** household invite (create a household inline with the review step), or share pets / invite for an absence; skipped for professionals and organisations.
- Review, then save: contact create with `pet_links`, then the optional invite with `contact_id`.
- `SharePetRouteArgs` gains `prefillEmail` / `contactId`; the sharing data layer sends `contact_id`. *Someone at home* creates a household invite, not a contact (D11).
- Remove the `?pop=1` / `?roles=` contract, the legacy add screen and client-side kind inference and dedupe utils. Update the affected specs (vet create in `veterinarian.spec.ts`).

**Exit criteria:**

- [ ] Widget tests for each tile path; kind explicit; roles required for carers and professionals; duplicate card opens existing; mapped save errors
- [ ] Share handoff prefilled and sends `contact_id`; household invite path sends `contact_id`
- [ ] `grep -rn inferPeopleContactKind flutter_app/lib` empty; `--e2e-shards 3,9` green

---

### Phase 7 — `c7-households-ui` · Household management inside People

| Field | Value |
|-------|-------|
| **id** | `c7-households-ui` |
| **ordinal** | 7/9 |
| **branch** | `cursor/people-client-c7-households-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `authorization`, `flutter-mobile`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/features/sharing/presentation/screens/households_screen.dart
flutter_app/lib/features/sharing/presentation/providers/household_providers.dart
flutter_app/lib/features/sharing/data/datasources/household_remote_datasource.dart
flutter_app/lib/features/sharing/data/repositories/household_repository_impl.dart
flutter_app/lib/features/sharing/domain/entities/household_summary.dart
flutter_app/lib/features/sharing/domain/repositories/household_repository.dart
flutter_app/lib/core/router/experience_routes.dart
flutter_app/lib/core/router/app_router.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/sharing/**
flutter_app/test/core/router/**
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `file-split`

**Outcome:** Households are created and managed inside People: members, tiers, invites, pets, leave and remove with remaining-access previews. The Sharing feature no longer owns household UI.

**Scope** (target doc §3.8 Households; spec § Creating and joining, § Leaving and removal):

- `HouseholdsPage` / `HouseholdDetailPage`:
  - rename (organisers);
  - members with tier chips;
  - **Invite member** (email, tier, organiser, 18+ copy per D14);
  - pending invites with Revoke;
  - pets in the household (record owner moves only their own pets);
  - Leave and Remove with removal preview and successor picker.
- Create household with the pet review step.
- `/household-invite/:code` landing (accept / decline), added to the public-path allowlist in `app_router.dart` next to `/invite/` and `/absence-invite/`. `/pc/pets/households` → `/pc/people/households`.
- Delete the Sharing household UI and repository files listed in the allowed paths. Sharing's grant code (`household_pet_access`, who-has-access) stays. Remove the matching architecture-test allowlist entries.

**Exit criteria:**

- [ ] Widget tests: create with review, invite, revoke, rename (organiser only), leave with successor, remove with preview choices, landing accept/decline
- [ ] Redirect test for `/pc/pets/households`; analyze and tests green

---

### Phase 8 — `c8-e2e-core` · BDD and Playwright journeys for the People screens

| Field | Value |
|-------|-------|
| **id** | `c8-e2e-core` |
| **ordinal** | 8/9 |
| **branch** | `cursor/people-client-c8-e2e-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |
| **router_risk** | R2 |
| **protocols** | `testing`, `release-verification`, `accessibility` |

**allowed_paths:**

```
flutter_app/test/bdd/features/people.feature
flutter_app/test/bdd/features/veterinarian_management.feature
flutter_app/test/bdd/features/sharing.feature
e2e/playwright/**
scripts/bdd-priority-tag-map.json
e2e/scripts/shard-files.mjs
docs/e2e/**
flutter_app/lib/features/people/**
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `docs`

**Outcome:** The People screens' journeys are specified in Gherkin and covered by Playwright, on one People page object. Edits under `flutter_app/lib/features/people/**` are limited to keys and semantics.

**Scope:**

- `e2e/playwright/pages/people.page.ts` covers roster, search, filters, card, detail tabs, edit, danger zone, add flow, picker and households. **Rewrite** the vet flows from `vet-list.page.ts` / `vet-form.page.ts` onto it and retire those two page objects. Serialize edits to `support/api.ts` and `e2e/scripts/shard-files.mjs` (append only: new spec files are added to an existing shard).
- Scenarios (Gherkin `Scenario:` titles match the `@bdd` headers exactly):
  1. Open Contacts from bottom navigation and see household, carers and professionals sections *(@smoke-ci)*
  2. Search by role and filter to professionals; `/pc/vets` lands on the professionals filter
  3. Desktop: select a person, the detail shows in the pane, and search is kept
  4. Add a pet professional as Buddy's primary vet; Buddy appears on their Pets & access tab
  5. Add a trusted carer and share Buddy with Can log care; a pending invite shows in the roster
  6. Edit a contact's roles and name; its kind is unchanged
  7. Removing a contact in use lists where it's used; mark it inactive; it shows as Inactive
  8. Create a household, invite a member by email (accepted via API helper), then remove them with the remaining-access preview
  9. Today desk Vet team and Trusted carers cards open person detail *(@smoke-ci)*
- Update `people.feature`, `veterinarian_management.feature` and `sharing.feature`; update `scripts/bdd-priority-tag-map.json`. Follow the locator hygiene in the testing rule.

**Exit criteria:**

- [ ] All 9 scenarios have Gherkin and Playwright specs; `node e2e/scripts/check_bdd_coverage.js` ≥ baseline; `node e2e/scripts/validate-shard-manifest.mjs` green
- [ ] Specs pass locally against `bin/start.js`; the `@smoke-ci` subset is green

---

### Phase 9 — `c9-ship-main` · Integration → main

| Field | Value |
|-------|-------|
| **id** | `c9-ship-main` |
| **ordinal** | 9/9 |
| **branch** | `cursor/people-client-c9-ship-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `release-verification`, `documentation` |

**allowed_paths:**

```
docs/domains/people/**
docs/agent-efficiency/parallel-programmes.md
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
```

**forbidden_paths:**

```
.github/workflows/**
server/**
```

**allowed_exceptions:** `docs`

**Outcome:** The People client core lands on `main` with pre-UAT green.

**Scope:**

- Rule 1 of [parallel-programmes §5](../../docs/agent-efficiency/parallel-programmes.md): no other programme `main` PR open.
- Rebase on `origin/main`; run `./scripts/pre-push.sh`.
- Update the People README status rows.
- Open **one** PR integration → `main`. The merge payload is the whole integration branch; this phase's own diff is docs only.
- Run `/babysit-uat` until pre-UAT is green (on failure: `/e2e-debug` → `/babysit-uat`).
- `complete-plan`, landing broadcast, roadmap `roadmap-set-child … merged`.

**Exit criteria:**

- [ ] Integration PR merged; pre-UAT green on the merge commit; broadcast posted

---

## Runtime state (agent-updated)

```yaml
autonomy: halted            # draft — bootstrapped by the roadmap when the entry gate is met
current_phase: null
last_completed_phase: null
halt_reason: "draft — waiting for people-server-7f3b and CARE C+D on main"
next_action: "roadmap bootstraps after landing slot 4 once CARE C+D has landed"
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
