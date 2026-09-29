# People domain refactor — execute-plan

**plan_id:** `people-domain-refactor-7f3b`
**title:** People domain refactor — one authoritative People context (server + Flutter) with a rich, calm UI
**author:** Claude Code session 2026-09-29 (drafted from the People review)
**created:** 2026-09-29
**base_branch:** `cursor/people-domain-refactor-integration-7f3b` (integration; one final PR → `main`)
**default_merge_mode:** `auto`
**artifact_branch_policy:** `phase-branch`
**phases:** 18 (ordinals used in commit prefixes: `phase(<n>/18): …`)

**Target model, gap analysis and UI spec (source of truth for every phase):** [docs/domains/people/changes/people-domain-refactor.md](../../docs/domains/people/changes/people-domain-refactor.md). Section numbers below (§3.3, §3.8 …) refer to that document. Bugs B1–B13 are listed in its §1.

---

## Goal

Refactor the People domain (UI label *Contacts*) into a clean bounded context:

- **Server:** one writer (`contactsRepo`) and one access policy (`access.js`). Pet relationships are the source of truth, and `vets` / `pets.vet_id` become write-only projections behind compat adapters. Read models serve the roster, contact detail, related care and "people around a pet".
- **Flutter:** a typed, layered People feature (domain → data → application → presentation) that other features reach only through the `people.dart` façade.
- **UI:** one set of person components and a single `PeoplePicker`, used across the app. The hub, detail, edit, add flow, pet section, Today desk and household screens are rebuilt to the §3.8 spec.

All 13 known bugs get regression tests. Legacy client code is deleted, and architecture tests guard the boundaries.

It is split into four waves so that each phase PR is one verifiable outcome and the app stays green on the integration branch between phases:

- **A:** server foundation (p0–p5).
- **B:** client core (p6–p8).
- **C:** surfaces (p9–p14).
- **D:** finish (p15–p17).

---

## Product and engineering locks (do not reopen during the run)

Workers implement these; they do not re-decide them. A conflict with them is a halt (`escalation`), not a judgement call.

1. Product decisions D1–D28 in [people-care-team.md](../../docs/domains/people/features/people-care-team.md) are unchanged. Wording comes from [vocabulary.md](../../docs/domains/people/features/vocabulary.md): EN nav/title **Contacts**, FR **Autour de vos animaux**, sections Trusted carers / Pet professionals, desk exception **Vet team**.
2. Engineering decisions R-01 … R-14 (target doc §6), in particular:
   - People is authoritative; `vets` / `pets.vet_id` are projections.
   - The server computes group, status, usages and access summaries.
   - Kind is explicit and never re-inferred.
   - Delete is usage-aware (`409 contact_in_use`).
   - Household UI lives in People.
   - One picker.
   - No new dependencies.
   - List–detail uses a ShellRoute with URL state.
   - API changes are additive only.
3. Destructive actions only in **Edit → danger zone**; every removal lists what remains (D16).
4. **Inactive** = neutral chip; **Needs review** = warning chip; errors never show raw backend text.
5. The People error `code` field is an **additive** field on the existing `{ error }` envelope. Shared `publicError` / validation conventions are not redefined.

## Pre-approved schema and behaviour changes (covered by the grant)

| Change | Phase | Notes |
|---|---|---|
| Migration `083_people_relationship_slots` (+ down) | p2 | `sort_order`; partial unique active-slot indexes for `primary_vet`, `out_of_hours_vet`; **idempotent dedupe** of duplicate active slot rows (keep most recently updated; log count) |
| Migration `084_people_household_notes` (+ down) | p4 | New table only |
| Migration `085_share_invite_contact_link` (+ down) | p5 | Nullable column + index |
| Migration `086_household_invites` (+ down) | p5 | New table (pattern of `planned_absence_carer_invites`) |
| PATCH contact no longer re-infers kind | p1 | B2 fix |
| PATCH rejects name/email change on a linked contact (`409 linked_identity_read_only`) | p1 | D9 / I11 |
| DELETE contact: `409 contact_in_use` + usages (was 400/409 free text); vet-linked unused contacts deletable | p1 | B3, B10 |
| Care item `provider_contact_id` validated (`400 validation_failed`) | p1 | B12 |
| Household member removal: transactional; last organiser must name a successor while members remain (`409 successor_required`) | p4 | Spec § Tiers and organisers |

**Any other migration, data change, breaking API change, CI workflow change or new dependency → halt with `status_reason: escalation`** and post `**Needs you:**` on the control issue.

---

## Bootstrap (before `approve-autonomous`)

The committed snapshot is a **draft**: `autonomy: "halted"`, `control_issue: 999999` (placeholder), `approved_by: DRAFT`. The gate refuses to run until the steps below are done.

```bash
# 1. Integration branch from main, carrying the plan artifacts + target doc
git fetch origin main
git checkout -b cursor/people-domain-refactor-integration-7f3b origin/main
git checkout origin/claude/exciting-bardeen-hy6yzp -- \
  .agents/plans/people-domain-refactor-7f3b.md \
  .agents/plans/people-domain-refactor-7f3b.snapshot.json \
  docs/domains/people/changes/people-domain-refactor.md
git commit -m "phase(1/18): docs: add people-domain-refactor plan and target model"
git push -u origin cursor/people-domain-refactor-integration-7f3b

# 2. Control issue
node scripts/execute_plan_runtime.js init-control-issue people-domain-refactor-7f3b
#    → run the rendered `gh issue create` (labels: execute-plan, plan:people-domain-refactor-7f3b,
#      autonomous-approved). The gate still refuses while the snapshot says autonomy "halted".

# 3. On human `approve-autonomous people-domain-refactor-7f3b` (comment on the control issue):
#    edit snapshot: control_issue=<N>, approved_at=<now UTC>, approved_until=<now+48h>,
#    approved_by="<human> via control issue #<N>", autonomy="active"
node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/people-domain-refactor-7f3b.snapshot.json
node scripts/validate_execute_plan_snapshot.js .agents/plans/people-domain-refactor-7f3b.snapshot.json
#    push the snapshot to the integration branch, then /execute-plan people-domain-refactor-7f3b
```

**Window:** expected 30–40h of agent time. If `approved_until` would pass mid-run, the orchestrator halts at a phase boundary with `next_action` recorded. The human re-approves: a refreshed window, no scope change, and a new hash via `--fix-hash`.

---

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_by** | *(pending)* — human via `approve-autonomous people-domain-refactor-7f3b` on the control issue |
| **approved_at** | *(pending)* |
| **approved_until** | `approved_at + 48h` |
| **control_issue** | *(pending — placeholder 999999 in draft snapshot)* |
| **content_hash** | from snapshot after `--fix-hash` |
| **autonomy** | `halted` (draft) → `active` on approval |

---

## Orchestrator notes (apply to every phase)

- **Worker brief:** `.cursor/agent-kernel/workers/phase-implementer.md`. Pass the phase **Outcome**, paths, `router_risk`, `protocols`, and the relevant target-doc sections.
- **Verification** after each logical batch: `./scripts/pre-push-changed.sh`. Server phases: `cd server && npx jest --env=node --forceExit`. Flutter phases:
  - `cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos`
  - `flutter test --concurrency=1 --exclude-tags=integration`
- **Gates:** `node scripts/check_file_size.js` must pass with **no new allowlist entries** (pages split into section widgets from the start; private widgets ≤80 lines). `node e2e/scripts/check_bdd_coverage.js --report-only` must not decrease.
- **Keep the integration branch green.** When a phase replaces a surface, it deletes the replaced code in the same phase unless another phase still depends on it; p15 removes the rest.
- **Architecture ratchets:**
  - `server/test/people/boundaries.test.js` (added p1, tightened p2, strict p15).
  - `flutter_app/test/features/people/architecture_test.dart` (added p6 with a temporary allowlist of current violators; shrinks in p8/p9/p14; empty in p15). A phase may only **remove** allowlist entries.
- **E2E hooks:** keep existing `Key`s used by Playwright (`people_*`, `pet_care_people_*`, `pet_care_dashboard_*`) working until p16 replaces the specs. New widgets use the stable keys documented in p7.
- **PR title:** `phase(<id>): <outcome>`. Body: outcome sentence, B-numbers fixed, target-doc sections implemented, tests added.

---

## Phases

### Phase 1 — `p0-hygiene` · Close stale People plans; docs truthful and linked

| Field | Value |
|-------|-------|
| **id** | `p0-hygiene` |
| **ordinal** | 1/18 |
| **branch** | `cursor/people-refactor-p0-hygiene-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R0 |
| **protocols** | `documentation` |

**Outcome:** No stale People plan is left active, and the People docs describe the real current state and point to the refactor target.

**allowed_paths:**

```
docs/domains/people/**
docs/architecture/index.md
docs/architecture/api-reference.md
docs/debt/refactoring-log.md
.agents/plans/people-vet-unify-a58d.md
.agents/plans/people-vet-unify-a58d.snapshot.json
.agents/plans/contacts-detail-parity-fcd9.md
.agents/plans/contacts-detail-parity-fcd9.snapshot.json
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
server/**
db/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:** `docs`

**Scope:**

- `people-vet-unify-a58d`: verify on `origin/main` that the p5-cleanup work landed (#1434, #1440). Then `set-phase … p5-cleanup --status merged` and `complete-plan people-vet-unify-a58d --write` (closes #1427). If any p5 deliverable is missing, open a debt issue that references this plan's p15, and still close.
- `contacts-detail-parity-fcd9`: its snapshot has no `control_issue`. Set it to the issue referenced by PR #1440; if there is none, create a closed `execute-plan` tracking issue and use that. Set `autonomy: completed`, re-hash, and add a short `.md` stub (outcome + PRs).
- `docs/domains/people/README.md`:
  - rewrite the implementation-status table to match reality (target doc §4 "Current" column);
  - add a "Refactor in progress" row linking the target doc and this plan;
  - fix the stale "Planned" and "ListTile" rows.
- `docs/domains/people/changes/delivery-plan.md`: add a `people-domain-refactor-7f3b` section (wave table from target doc §8).
- `docs/domains/people/changes/ui-hub-navigation.md`: add a note that desk and hub layout details are superseded by target doc §3.8, keeping only the navigation decisions.
- `docs/architecture/api-reference.md`: add a "Planned — people-domain-refactor-7f3b" subsection listing target doc §3.6 (marked planned).
- `docs/architecture/index.md`: People row links to the target doc.
- `docs/debt/refactoring-log.md`: sprint entry with the phase list and file ownership per phase.
- Target doc front-matter `status: proposed` → `accepted`.

**Exit criteria:**

- [ ] `bash scripts/validate_docs.sh` passes
- [ ] `node scripts/validate_execute_plan_snapshot.js` passes for both closed plans' snapshots
- [ ] #1427 closed with the complete-plan summary; `contacts-detail-parity-fcd9` shows `autonomy: completed`
- [ ] README status table matches target doc §4

---

### Phase 2 — `p1-server-core` · One writer, one access policy, typed errors

| Field | Value |
|-------|-------|
| **id** | `p1-server-core` |
| **ordinal** | 2/18 |
| **branch** | `cursor/people-refactor-p1-server-core-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `api-contract`, `validation`, `data-lifecycle`, `testing` |

**Outcome:** Every People write goes through one repository and every People visibility decision goes through one access module, with stable error codes. This fixes B2, B3, B6, B10 and B12.

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/lib/care/providerUsed.js
server/lib/care/schedule/completeOccurrence.js
server/lib/care/schedule/undoLastAction.js
server/routes/healthEntries/crudRouter.js
server/routes/healthEntries/shared.js
server/routes/healthEntries/occurrencePatchRouter.js
server/routes/careContext/plannedAbsencesRouter.js
server/test/people/**
server/test/healthEntries/**
server/test/healthEntries.test.js
server/test/careSchedule/**
server/test/careContext/**
server/test/lib/care/**
docs/architecture/api-reference.md
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
db/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/lib/households/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope** (target doc §3.3, §3.4, §3.5):

- `server/lib/people/index.js`: the façade. Other domains import only this.
- `errors.js`: `PeopleError(code, status, details)` → `{ error, code, details }`. Codes: `validation_failed`, `contact_not_found`, `forbidden`, `contact_in_use`, `linked_identity_read_only`.
- `constants.js`: add `ROLE_GROUP`. Move `inferContactKind` into `inference.js` with `contactGroup(roles, kind)`.
- `contactsRepo.js`, the **single writer** (create / update / setActive / delete / copy, plus roles and private notes, all in one transaction). Migrate every raw insert:
  - `contactMutations.js` (fold it in);
  - `vetSync.js` (contact rows only; the vets projection moves in p2);
  - `absenceCarer.js` (`ensureLinkedUserContact`, `ensureNoteOnlyContact`);
  - `contactCopyOnPetLeave.js`.
- PATCH never re-infers kind (**B2**). `active: boolean` stamps `inactive_at` server-side; a sent `inactive_at` is validated. Name/email change on a contact with `linked_user_id` → `409 linked_identity_read_only`.
- `access.js`: `visibleDirectoryIds` (personal only for now), `canViewContact`, `canEditContact`, `canAttachContactToPet` (caller's directory or pet owner's personal directory, plus `userCanManageProfile`), and a `careHandoverScope` stub. Use it in the contacts routes, `peopleRelationshipsRouter` authz helpers via the façade, and `absenceCarer`. Remove `assertPersonalDirectoryOwner` and the orphaned JSDoc in `vetSync.js`.
- `usages.js`: active relationships, absence carers on current or future absences, care-item providers, pending carer invites, works-at references.
- DELETE → `409 contact_in_use` with `details.usages` (**B10**). A vet-linked contact with no usages deletes, removing its `vets` row through the existing vet sync function (**B3**). Move the inline SQL out of the router.
- Care item create/update: validate `provider_contact_id` with `canAttachContactToPet` → `400 validation_failed` (**B12**).
- `snapshots.snapshotForAuthorisedWrite(contactId)`. Completion and occurrence patch take the provider snapshot from the attached contact without filtering by the completer's directory; a body override is validated with `canAttachContactToPet` (**B6**).
- `server/test/people/boundaries.test.js`: scan `server/**/*.js` (excluding migrations, `server/db/seeds/**`, `server/scripts/migrations/**`, tests). Fail on `INSERT INTO|UPDATE|DELETE FROM people_(contacts|contact_roles|contact_private_notes|directories)` outside `server/lib/people/`, and on imports of `lib/people/<file>` (other than `index.js`) from outside `lib/people`. Temporary allowlist: `vets` writes in `lib/people/vetSync.js` and `routes/vets.js` (removed in p2).
- `docs/architecture/api-reference.md`: People error codes, delete semantics, provider validation.

**Exit criteria:**

- [ ] Regression tests:
  - B2: rename keeps kind.
  - B3: an unused vet-linked contact deletes and its `vets` row is gone.
  - B10: a contact used as a care-item provider → `409` listing it.
  - B6: a co-parent completing an occurrence keeps the provider snapshot.
  - B12: a provider from another user's directory is rejected.
- [ ] Access-matrix tests: owner / co-parent / stranger × view / edit / attach
- [ ] `boundaries.test.js` passes; `grep -rn "INSERT INTO people_contacts" server --include=*.js` hits only `lib/people/contactsRepo.js`, seeds and migration scripts
- [ ] Jest green; no file over 500 lines; API reference updated

---

### Phase 3 — `p2-relationships` · Relationships authoritative; vets as projection

| Field | Value |
|-------|-------|
| **id** | `p2-relationships` |
| **ordinal** | 3/18 |
| **branch** | `cursor/people-refactor-p2-relationships-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R2 |
| **protocols** | `database-and-migrations`, `api-contract`, `authorization`, `data-lifecycle`, `testing` |

**Outcome:** Pet relationships are the only source of truth for a pet's vet and other contacts. `vets` and `pets.vet_id` are written only by a projection, behind unchanged compat endpoints. This fixes B11.

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/routes/pets/peopleRelationshipsRouter.js
server/routes/pets/coreRouter.js
server/routes/vets.js
server/scripts/reconcilePeopleVets.js
server/db/seeds/**
db/migrations/083_people_relationship_slots.sql
db/migrations/083_people_relationship_slots_down.sql
db/schema/**
server/test/people/**
server/test/vets.test.js
server/test/pets/**
server/test/migrations/083_people_relationship_slots.test.js
server/test/seed.test.js
server/test/openapi/**
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope** (target doc §3.3 I4–I6, §3.6, §5.1):

- Migration 083 exactly as pre-approved. Follow `database-and-migrations` protocol: down file, `db/schema/migration-manifest.json`, canonical schema. The migration test covers the duplicate-slot fixture and the down migration.
- `relationships.js`:
  - `listForPet`;
  - `setSlot(petId, kind, contactId|null)` (replace semantics for `primary_vet` / `out_of_hours_vet`);
  - `add` (emergency_contact / care_provider / other);
  - `remove`;
  - `reorder`.
  - Every mutation runs in a transaction and calls `vetProjection.projectPet(petId)`.
- `vetProjection.js`: `projectPet`, `projectContact`, `rebuildAll`. This is the only writer of `vets` rows and `pets.vet_id` (I5, I6). Absorb the two-way logic from `vetSync.js` and `petVetLink.js`.
- Compat adapters, with response shapes byte-compatible:
  - `routes/vets.js` → `contactsRepo` + projection.
  - `pets/coreRouter.js` `vet_id` writes → `relationships.setSlot('primary_vet', contactForLegacyVet)`.
  - Legacy `PUT /api/pets/:id/people-relationships` goes through the service and re-projects (**B11**).
- New endpoints:
  - `PUT /api/pets/:petId/people-relationships/slots/:kind`
  - `POST /api/pets/:petId/people-relationships`
  - `DELETE /api/pets/:petId/people-relationships/:relationshipId`
  - POST of a slot kind → `409 slot_conflict` (use PUT slots).
  - `POST /api/people/contacts` accepts optional `pet_links[]` (`{ pet_id, relationship_kind }`), applied in the same transaction via `relationships.js` and `canAttachContactToPet` (used by the p12 add flow).
- `reconcilePeopleVets.js` → calls `vetProjection.rebuildAll()` (People → vets direction). Seeds create professionals through the People service.
- Tighten `boundaries.test.js`: `vets` writes only in `vetProjection.js`; `vets` reads only in `routes/vets.js` and `vetProjection.js`.

**Exit criteria:**

- [ ] Invariant I5 test matrix: set, replace and clear the primary vet via (a) slots endpoint, (b) legacy pet PATCH `vet_id`, (c) `DELETE /api/vets/:id`, (d) legacy PUT-all. `pets.vet_id` always matches.
- [ ] Compat contract tests: `/api/vets` CRUD and pet GET `vet_id` response shapes unchanged
- [ ] Migration 083 applies on a DB with duplicate active slots and leaves one active; down migration passes
- [ ] OpenAPI and API reference updated; Jest green

---

### Phase 4 — `p3-read-models` · Roster, detail, related care, pet people

| Field | Value |
|-------|-------|
| **id** | `p3-read-models` |
| **ordinal** | 4/18 |
| **branch** | `cursor/people-refactor-p3-read-models-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `api-contract`, `date-time`, `testing` |

**Outcome:** The server returns everything the People UI needs as read models, so the client no longer derives groups, counts or linked pets.

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/routes/pets/petPeopleRouter.js
server/routes/pets/index.js
server/lib/households/petAccessGrants.js
server/lib/households/index.js
server/test/people/**
server/test/pets/**
server/test/households/**
server/test/openapi/**
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
db/**
e2e/**
.github/workflows/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope** (target doc §3.6 DTOs):

- `roster.js` + `GET /api/people/roster`:
  - households with members (display name, first name, tier, organiser, `is_you`, owns and shares pet ids) via exported household read functions (add `server/lib/households/index.js` exports; no behaviour change);
  - `contacts[]` as `ContactSummary` (group, status, pets with relationship kinds, `works_at`, `next_absence`, access summary for linked accounts from `petAccess`);
  - `pending_invites[]` (pending pet share invites and absence carer invites created by the viewer; the household source is added in p5).
- `detail.js`:
  - `GET /api/people/contacts/:id` enriched (`works_at`, `staff[]`, `usage_counts`, `linked_account`);
  - `GET /api/people/contacts/:id/related` (pets, care items where provider with next due date, absences as carer, past-visit count);
  - `GET /api/people/contacts/by-legacy-vet/:vetId` → `{ id }`.
- `GET /api/pets/:petId/people`: slots, household members, carers, professionals, emergency contacts. Scope-aware: Can log care members and absence guests get only the care handover scope (`access.careHandoverScope`); others → 403/404 per convention.
- `GET /api/people/contacts` adds `group`, `status` and `directory` (additive).
- Dates `YYYY-MM-DD`; bounded query count (no N+1).

**Exit criteria:**

- [ ] DTO shape tests for roster, detail, related and pet people (including empty cases)
- [ ] Scope tests: Can log care / guest see only handover-scope contacts; stranger denied
- [ ] Mock-pool test asserts roster query count doesn't grow with contact count
- [ ] OpenAPI and API reference updated; Jest green

---

### Phase 5 — `p4-households-api` · Household directory, notes, safe removal

| Field | Value |
|-------|-------|
| **id** | `p4-households-api` |
| **ordinal** | 5/18 |
| **branch** | `cursor/people-refactor-p4-households-api-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `database-and-migrations`, `data-lifecycle`, `api-contract`, `testing` |

**Outcome:** Household members see and manage their household's contacts and notes according to the access policy, and member removal is safe and previewable.

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/lib/households/**
server/routes/households/**
db/migrations/084_people_household_notes.sql
db/migrations/084_people_household_notes_down.sql
db/schema/**
server/test/people/**
server/test/households/**
server/test/migrations/084_people_household_notes.test.js
docs/architecture/api-reference.md
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope** (target doc §3.5; spec § Ownership and households, § People data):

- `access.js`: household directories. Full access and organisers get view / edit / create / attach; Can log care gets no directory view.
- `POST /api/people/contacts` accepts `household_id` (Full access only).
- Roster and contacts list include visible household-directory contacts.
- Migration 084. `household_note` read/write on contact detail and PATCH (household members only; never shown to the linked person, I10).
- `GET /api/households/:id/members/:userId/removal-preview`: access kept per pet and source (direct share, absence), D16.
- `removeHouseholdMember`: run in one transaction. Enforce "the last organiser names a successor" (`409 successor_required` when other members remain; accept `successor_user_id`). Keep "remove all access to my pets" for pet owners (not only organisers acting on their own pets, per spec).
- Contact copy on pet leave (D23) goes through `contactsRepo.copy`, with a test.

**Exit criteria:**

- [ ] Access matrix extended: Full access / Can log care / organiser × household contacts view / edit / create
- [ ] Household note visibility tests (member yes, non-member no, linked person no)
- [ ] Removal: transactional rollback test, successor rule, preview lists remaining direct shares
- [ ] Migration 084 test; Jest green; API reference updated

---

### Phase 6 — `p5-invites-api` · Household invites; invites link to contacts

| Field | Value |
|-------|-------|
| **id** | `p5-invites-api` |
| **ordinal** | 6/18 |
| **branch** | `cursor/people-refactor-p5-invites-api-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `database-and-migrations`, `api-contract`, `observability`, `testing` |

**Outcome:** Organisers can invite people to a household by email, and accepting a household or pet-share invite links the account to the People contact it was sent from.

**allowed_paths:**

```
server/lib/households/**
server/routes/households/**
server/routes/sharing/inviteRoutes.js
server/lib/people/**
server/lib/email/**
server/lib/emailTemplates.js
db/migrations/085_share_invite_contact_link.sql
db/migrations/085_share_invite_contact_link_down.sql
db/migrations/086_household_invites.sql
db/migrations/086_household_invites_down.sql
db/schema/**
server/test/households/**
server/test/sharing/**
server/test/people/**
server/test/email.test.js
server/test/migrations/085_share_invite_contact_link.test.js
server/test/migrations/086_household_invites.test.js
docs/architecture/api-reference.md
docs/domains/sharing/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Migrations 085 and 086 as pre-approved.
- Household invites service, modelled on `absenceCarerInviteService.js`:
  - `POST /api/households/:id/invites` (organisers only; email, tier, `is_organiser`, optional `contact_id`; 14-day expiry; rate-limited);
  - landing `GET /api/households/invites/code/:code`, plus `/accept` and `/decline` (accept adds membership via `householdService`; 18+ attestation per D14 is already captured at sign-up);
  - `DELETE /api/households/:id/invites/:inviteId` (revoke).
- Email template `householdInvitation` (EN/FR via `lib/email/i18n`). Landing URL: `/household-invite/<code>`.
- Pet share invite create accepts optional `contact_id` (caller must pass `canEditContact`). On accept, set `people_contacts.linked_user_id` when it is null. Never overwrite a different existing link: log and skip.
- The roster's `pending_invites` adds the `household` source.
- Structured log events for invite create, accept and revoke (no PII beyond ids).

**Exit criteria:**

- [ ] Household invite lifecycle tests: create, accept, decline, revoke, expire, non-organiser denied, duplicate member
- [ ] Contact link tests for share and household invites, including the "already linked to someone else" skip
- [ ] Email rendering test (EN/FR); migration 085/086 tests; Jest green; API reference updated

---

### Phase 7 — `p6-flutter-core` · Typed domain, repository, application layer, façade

| Field | Value |
|-------|-------|
| **id** | `p6-flutter-core` |
| **ordinal** | 7/18 |
| **branch** | `cursor/people-refactor-p6-flutter-core-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `api-contract`, `flutter-mobile`, `testing` |

**Outcome:** The Flutter People feature has a typed, layered core (domain, data, application) exposed through `people.dart`, and the detail refetch loop is gone (B1).

**allowed_paths:**

```
flutter_app/lib/features/people/people.dart
flutter_app/lib/features/people/domain/**
flutter_app/lib/features/people/data/**
flutter_app/lib/features/people/application/**
flutter_app/lib/features/people/presentation/labels/**
flutter_app/lib/features/people/presentation/providers/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.7):

- **Domain:**
  - enums `ContactKind`, `ContactRole` (with `group` from the wire value only), `ContactGroup`, `RelationshipKind`, `ContactStatus`;
  - entities `ContactSummary`, `ContactDetail`, sealed `Person` (contact / household member / pending invite), `Roster`, `PetRelationship`, `PetPeople`, `RelatedCare`, `ContactUsage`, `Household`, `HouseholdMember`, `HouseholdInvite`;
  - all immutable with hand-written `==`/`hashCode`;
  - pure services `roster_sections.dart`, `roster_search.dart` (name, localized role via injected labeler, organisation, email, phone digits, pet names), `desk_ranking.dart` (ui-hub-navigation rules).
- **Data:**
  - DTOs (the only place wire strings live);
  - `people_api.dart` on `authHttpClientProvider`, throwing `PeopleApiException(code, statusCode, usages)`;
  - `households_api.dart` (list, detail, create, rename, members, invites, removal preview, pets);
  - `PeopleRepository` / `HouseholdsRepository` interfaces in the domain, with implementations in data.
- **Application:**
  - `peopleRepositoryProvider`, `rosterProvider` (AsyncNotifier), `personSummaryProvider(id)` (select from roster), `personDetailProvider(id)` (`FutureProvider.autoDispose.family`, a single fetch that **never writes back** into other providers), `relatedCareProvider(id)`, `petPeopleProvider(petId)`, `householdsProvider`, `householdDetailProvider(id)`;
  - `people_commands.dart` (create, update, setActive, delete, linkPet, setSlot, removeRelationship, household commands), each invalidating exactly the affected providers.
- `presentation/labels/`: enum → l10n label extensions. Add ARB keys for every role, kind, group, relationship kind and status in EN and FR.
- Re-implement the legacy `peopleContactsProvider`, `peopleContactByIdProvider` and `peopleContactDetailProvider` as **deprecated adapters** over the repository, so the current screens and consumers keep working (no `mergeLocal`). Remove the loop (**B1**).
- `people.dart` exports domain entities, enums, labels and application providers/commands.
- `test/features/people/architecture_test.dart`:
  - files outside `features/people/` may import only `features/people/people.dart`;
  - `presentation/` never imports `data/`.
  - Temporary allowlist: the current violators (pet_profile vet provider/section, health_tracking provider field and info section, away plan carer dialog, experience desk module, core router).

**Exit criteria:**

- [ ] Unit tests: DTO round-trips (including unknown enum values), equality, sections, search, desk ranking
- [ ] Application tests with a fake repository: opening detail triggers exactly one fetch; commands invalidate roster, detail and petPeople as specified (**B1** regression)
- [ ] Architecture test passes with the documented allowlist; analyze and tests green

---

### Phase 8 — `p7-components` · Person components and the one PeoplePicker

| Field | Value |
|-------|-------|
| **id** | `p7-components` |
| **ordinal** | 8/18 |
| **branch** | `cursor/people-refactor-p7-components-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**Outcome:** One set of design-system person components and a single `PeoplePicker` exist, tested, ready for every surface.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/widgets/**
flutter_app/lib/features/people/presentation/picker/**
flutter_app/lib/features/people/domain/services/people_query.dart
flutter_app/lib/features/people/people.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
docs/e2e/navigation-contract.md
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 Shared components; [system.md](../../docs/design/system.md) §6.5, §6.8, §6.10):

- `PersonAvatar` (40/64, linked photo or stable monogram accent from id, organisation badge, semantics).
- `PersonCard`:
  - regular and compact variants;
  - role/tier line, pets line and context line;
  - status chip or chevron;
  - one semantic button;
  - minimum height 56.
- `PersonStatusChip` (neutral Inactive, warning Needs review, info Invited / Access until).
- `RoleChips` (display, and grouped selectable for forms).
- `ContactActionBar` (Call, Message, Email, Directions, overflow Website; hidden when there is no data; long-press copy with snackbar).
- `PersonSkeleton`.
- `PeopleQuery`: groups, roles, kinds, household members yes/no, `currentId` pinned even if inactive, `allowNone`, `allowTypedName`, pet scope.
- `PeoplePickerField` + `PeoplePickerSheet` (compact bottom sheet / 480px dialog; search; sections; "Add '{query}'" → `QuickAddPersonSheet` via commands; "Use '{query}' without saving" when `allowTypedName`).
- Stable keys: `people_card_<id>`, `people_picker_field_<purpose>`, `people_picker_option_<id>`, `people_picker_add`, `people_action_<call|message|email|directions>`. Document them in `docs/e2e/navigation-contract.md` § People.
- Export the components via `people.dart`.

**Exit criteria:**

- [ ] Widget tests: card variants and semantics label, chip variants (not colour-only), action bar hidden actions and copy, picker (search, inactive current pinned, inactive not offered, none, quick add returns the created person, typed-name option)
- [ ] Touch targets ≥ 48; text scales to 200% without overflow in card and picker tests
- [ ] Keys documented; analyze and tests green

---

### Phase 9 — `p8-consumers` · Pet profile, care, Away Planning and report use the façade

| Field | Value |
|-------|-------|
| **id** | `p8-consumers` |
| **ordinal** | 9/18 |
| **branch** | `cursor/people-refactor-p8-consumers-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `api-contract`, `accessibility`, `testing` |

**Outcome:** Every contact choice and display outside the People screens uses the façade and the `PeoplePicker`, backed by relationships. This fixes B7 and B8.

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/pet_form_vet_section.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/pet_detail_profile_card.dart
flutter_app/lib/features/pet_profile/presentation/providers/pet_vet_contacts_provider.dart
flutter_app/lib/features/pet_profile/presentation/controllers/**
flutter_app/lib/features/pet_profile/data/services/pet_report_service.dart
flutter_app/lib/features/pet_profile/data/services/pet_report_profile_section.dart
flutter_app/lib/features/health_tracking/presentation/widgets/care_provider_field.dart
flutter_app/lib/features/health_tracking/presentation/widgets/occurrence_add_details_sheet.dart
flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_form/health_entry_form_content.dart
flutter_app/lib/features/health_tracking/presentation/screens/care_item_detail/care_item_info_section.dart
flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_carer_edit_dialog.dart
flutter_app/lib/features/pet_care/context/presentation/controllers/away_plan_handover_controller.dart
flutter_app/lib/features/pet_care/context/presentation/away_plan_copy.dart
flutter_app/lib/features/pet_care/context/data/**
flutter_app/lib/features/pet_care/context/domain/repositories/care_context_repository.dart
flutter_app/lib/features/people/people.dart
flutter_app/lib/l10n/**
flutter_app/test/features/pet_profile/**
flutter_app/test/features/health_tracking/**
flutter_app/test/features/pet_care/**
flutter_app/test/features/people/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope:**

- Pet form and pet profile card: a **Primary vet** `PeoplePickerField` (query: professionals, vets first). Saving calls `setSlot(primary_vet)` after the pet save; the new client no longer writes `vet_id`. Delete `PetVetOption` / `petVetOptionsProvider`.
- Care provider field → `PeoplePickerField` (query: professionals and organisations; `allowTypedName` per D-CIE-016; inactive current pinned) (**B8**). The care item info section resolves the provider name via `contactSummary`/detail for contacts visible through the access policy (works for co-parents).
- Away plan carer dialog → picker (query: carers plus household members; current pinned). Empty state offers "Add a trusted carer" (quick add).
- PDF report and Away Planning handover read `petPeopleProvider` (primary vet with full coordinates, out-of-hours vet, emergency contacts) (**B7**). Remove `fetchPetPeopleRelationships` from `care_context` data/repository and the raw-map parsing in `away_plan_copy.dart`.
- Shrink the architecture-test allowlist (pet_profile, health_tracking and pet_care entries removed).

**Exit criteria:**

- [ ] B7 regression: the report vet block includes phone/email/address when present. B8 regression: an inactive contact is not offered and an unknown current id renders without assert.
- [ ] Widget tests for each migrated field (selection, clear, quick add, typed name for provider)
- [ ] No file in pet_profile, health_tracking or pet_care imports People internals (allowlist entries removed); analyze and tests green

---

### Phase 10 — `p9-hub` · Roster hub, search and filters, list–detail, Today desk

| Field | Value |
|-------|-------|
| **id** | `p9-hub` |
| **ordinal** | 10/18 |
| **branch** | `cursor/people-refactor-p9-hub-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**Outcome:** The Contacts hub shows the full roster (households with members, carers, professionals, invites, inactive), with full search, canonical filters and a working desktop list–detail, and the Today desk uses the same model. This fixes B4 and B5.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/hub/**
flutter_app/lib/features/people/presentation/desk/**
flutter_app/lib/features/people/presentation/routes/**
flutter_app/lib/features/people/presentation/screens/**
flutter_app/lib/features/people/domain/services/**
flutter_app/lib/features/people/people.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_people_desk_module.dart
flutter_app/lib/features/experience/presentation/widgets/pet_care_shell_home_content.dart
flutter_app/lib/core/router/experience_routes.dart
flutter_app/lib/core/router/vet_routes.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/experience/**
flutter_app/test/core/router/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 Hub, Today desk; R-08):

- `presentation/routes/people_routes.dart`: a feature-owned `ShellRoute` for `/pc/people` with builder `PeopleHubLayout`, plus child routes `:personId`, `:personId/edit`, `new`. For now `households` points at the existing screen, and p14 replaces it. `experience_routes.dart` includes it. `/account/people` and `/pc/vets*` redirects keep working (`?filter=professionals`).
- `PeopleHubLayout`:
  - compact shows the child;
  - ≥840px shows a 380–420px list plus the child, or a placeholder;
  - the experience shell wraps the whole layout (**B4**).
  - Selection uses `context.go` and keeps `q` and `filter` in the query.
- `RosterList`:
  - household sections (members, with tier/organiser and owns/shares lines), Trusted carers, Pet professionals, Pending invites, collapsed Inactive (n);
  - empty sections omitted;
  - skeleton, illustrated empty state (one action) and error with Retry.
- Search field (full search with match highlight). `CollectionFilterBar` dimensions: Group, Kind, Pet, Status. URL-synced.
- Add button: extended FAB on compact, header button on expanded → `/pc/people/new` (the legacy add screen stays until p12).
- Desk: `presentation/desk/people_desk_module.dart` on roster + `desk_ranking`. Vet team (vet slot or vet/vet nurse role), Trusted carers ranking, member rail → detail. All labels localized (**B5**). The experience home imports it via `people.dart`; delete the old desk module file.
- Delete `people_list_screen.dart` and `people_hub_screen.dart`. The detail and edit routes still point at the legacy screens (wrapped in the layout) until p10/p11.
- Shrink the architecture-test allowlist (experience, core router).

**Exit criteria:**

- [ ] Widget tests: sections (including members and invites), search over role/email/pet, filters and URL state, empty/loading/error states
- [ ] Widget test at 1280×800: selecting a person shows detail in the pane, the shell is outside the split, search text survives selection (**B4**)
- [ ] Desk tests: localized role line (**B5**), Vet team membership rule, ranking, member rail navigation
- [ ] Existing Playwright hooks still resolve (`pet_care_dashboard_all_people`, desk card keys) or are updated in `docs/e2e/navigation-contract.md`

---

### Phase 11 — `p10-detail` · Person detail with header, action bar and tabs

| Field | Value |
|-------|-------|
| **id** | `p10-detail` |
| **ordinal** | 11/18 |
| **branch** | `cursor/people-refactor-p10-detail-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**Outcome:** Person detail shows who someone is and how they relate to your pets and care: a header, the action bar, and Overview, Pets & access, Related care and Notes tabs, with member and invite variants.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/detail/**
flutter_app/lib/features/people/presentation/routes/**
flutter_app/lib/features/people/presentation/screens/people_detail_screen.dart
flutter_app/lib/features/people/presentation/widgets/people_contact_coordinates_section.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 Person detail):

- `PersonDetailPage`. It renders the header from `personSummaryProvider` immediately and the body from `personDetailProvider`.
  - **Header:** avatar 64, name, subtitle, works-at link, role chips, status chip, linked badge. Edit in the app bar; no destructive actions.
  - `ContactActionBar`.
- **Tabs**, each in its own file:
  - **Overview:** details rows with copy, **Next up** card, staff list for organisations, notes preview.
  - **Pets & access:** relationship chips per pet, access line, "Link to a pet" (pet picker → relationship kind → command).
  - **Related care:** care items as provider, absences as carer, past-visit count; shown for carers and professionals.
  - **Notes:** private and household notes with inline edit and explicit Save.
- **Variants:** household member (Pets & access and Notes); pending invite (single page).
- Route `:personId` → new page. Delete the legacy detail screen and coordinates section.

**Exit criteria:**

- [ ] Widget tests per tab and variant; "Link to a pet" command invalidates detail and petPeople
- [ ] Semantics: tabs reachable and labelled; action bar labelled; no raw error text on failure
- [ ] Analyze and tests green; each file ≤300 lines (≤500 hard)

---

### Phase 12 — `p11-edit` · Person edit with relationship editor and danger zone

| Field | Value |
|-------|-------|
| **id** | `p11-edit` |
| **ordinal** | 12/18 |
| **branch** | `cursor/people-refactor-p11-edit-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `flutter-mobile`, `data-lifecycle`, `testing` |

**Outcome:** Everything about a person can be edited in one calm form, and destructive actions live only in a danger zone that shows what each action affects. This fixes B13.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/edit/**
flutter_app/lib/features/people/application/person_form_controller.dart
flutter_app/lib/features/people/presentation/routes/**
flutter_app/lib/features/people/presentation/screens/people_edit_screen.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 Person edit):

- `PersonFormController` (shared with p12): field state, inline validation (email, phone, website), dirty tracking, submit, and error mapping by `PeopleApiException.code` (no string matching, no raw text) (**B13**).
- `PersonEditPage` with `AppFormSection` sections:
  - **Identity:** kind segmented control, grouped roles, read-only with explanation when linked.
  - **Works at:** organisation picker.
  - **Contact details.**
  - **Notes:** private, and household when applicable.
  - **Pets:** relationship editor, with a slot replace confirmation and emergency-contact reorder.
- Sticky `AppFormActionsBar` and discard dialog.
- **Danger zone:**
  - Mark inactive / Reactivate.
  - Remove contact → on `409`, a `UsagesDialog` listing usages with "Replace…" deep links and "Mark inactive instead".
  - Household member: Remove from household (uses the removal preview; two choices per spec).
  - Pending invite: Revoke.
- Route `:personId/edit` → new page. Delete the legacy edit screen.

**Exit criteria:**

- [ ] Widget tests: validation messages, roles/kind edit saves without changing kind unexpectedly, linked read-only, slot replace confirmation, reactivate, usages dialog on 409, removal preview shown before member removal
- [ ] Discard dialog on dirty back; no raw exception text anywhere in the edit flow
- [ ] Analyze and tests green

---

### Phase 13 — `p12-add` · Unified add flow with sharing and household-invite handoff

| Field | Value |
|-------|-------|
| **id** | `p12-add` |
| **ordinal** | 13/18 |
| **branch** | `cursor/people-refactor-p12-add-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `flutter-mobile`, `authorization`, `testing` |

**Outcome:** Anyone can be added in one short, guided flow that sets kind explicitly, links pets, and optionally hands off to sharing or a household invite already linked to the new contact. This fixes B9.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/add/**
flutter_app/lib/features/people/application/person_form_controller.dart
flutter_app/lib/features/people/presentation/routes/**
flutter_app/lib/features/people/presentation/screens/people_add_person_screen.dart
flutter_app/lib/features/people/presentation/utils/**
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
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 Add person; vocabulary § Adding someone):

- `AddPersonFlow` (compact full-screen with "Step n of 5"; expanded 560px dialog):
  1. **Who** — four tiles; sets kind and flow.
  2. **About them** — name and coordinates, with a live duplicate card from the roster ("Open existing"; never merges).
  3. **How do they help** — grouped roles, no default; works-at.
  4. **Which pets** — per-pet relationship kind.
  5. **App access** — household invite (create a household inline with the review step when there is none) or share pets / invite for an absence. Skipped for professionals and organisations.
- Review, then save through commands: contact create with `pet_links`, then the optional invite with `contact_id`.
- Sharing handoff: `SharePetRouteArgs` gains optional `prefillEmail` and `contactId`; the sharing data layer sends `contact_id`.
- Household invite handoff: `HouseholdsRepository.invite` with `contact_id`. *Someone at home* creates a household invite, not a contact (household members are accounts, D11).
- Picker "Add '{query}'" keeps using `QuickAddPersonSheet` (p7).
- Remove the `?pop=1` / `?roles=` contract, `people_add_person_screen.dart`, `people_contact_kind_inference.dart` and `people_contact_dedupe.dart` (**B9**).

**Exit criteria:**

- [ ] Widget tests for each tile path. Kind is set explicitly; roles required for carers and professionals; duplicate card opens the existing person; save errors shown with mapped messages (**B9**).
- [ ] Share handoff opens prefilled and sends `contact_id`; household invite path creates an invite with `contact_id`
- [ ] No client-side kind inference remains (`grep -rn inferPeopleContactKind flutter_app/lib` empty); analyze and tests green

---

### Phase 14 — `p13-pet-people` · People around {pet} and emergency card

| Field | Value |
|-------|-------|
| **id** | `p13-pet-people` |
| **ordinal** | 14/18 |
| **branch** | `cursor/people-refactor-p13-pet-people-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing` |

**Outcome:** Each pet profile shows the people around that pet: an emergency card with one-tap call and grouped household, carers and professionals, editable through slot pickers.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/pet/**
flutter_app/lib/features/people/people.dart
flutter_app/lib/features/pet_profile/presentation/screens/pet_detail_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/**
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/pet_profile/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 People around {pet}; vocabulary § Pet profile):

- `PetEmergencyCard`: primary vet, out-of-hours vet and emergency contacts with Call. **Manage** opens `SlotPickerRow`s. Empty slots are labels, not nudges.
- `PetPeopleSection` with groups At home, Trusted carers and Pet professionals. The owner is shown quietly.
- Mounted on the pet detail screen for viewers who can see it (scope-aware server data). Can log care sees the handover scope only, with no Manage.
- The vet row in `pet_detail_profile_card.dart` is replaced by the section (no duplication).

**Exit criteria:**

- [ ] Widget tests: owner vs Can log care rendering, set/clear out-of-hours vet, add/reorder emergency contacts, call action present only with a phone
- [ ] Analyze and tests green

---

### Phase 15 — `p14-households-ui` · Household management inside People

| Field | Value |
|-------|-------|
| **id** | `p14-households-ui` |
| **ordinal** | 15/18 |
| **branch** | `cursor/people-refactor-p14-households-ui-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |
| **router_risk** | R2 |
| **protocols** | `accessibility`, `authorization`, `flutter-mobile`, `testing` |

**Outcome:** Households are created and managed inside People: members, tiers, invites, pets, leave and remove with remaining-access previews. The Sharing feature no longer owns household UI.

**allowed_paths:**

```
flutter_app/lib/features/people/presentation/households/**
flutter_app/lib/features/people/presentation/routes/**
flutter_app/lib/features/people/people.dart
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
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope** (target doc §3.8 Households; spec § Creating and joining, § Leaving and removal):

- `HouseholdsPage` (`/pc/people/households`) and `HouseholdDetailPage` (`/pc/people/households/:id`):
  - rename (organisers);
  - members with tier chips;
  - **Invite member** (email, tier, organiser, 18+ confirmation copy per D14);
  - pending invites with Revoke;
  - pets in the household (record owner moves only their own pets);
  - Leave and Remove with the removal preview and successor picker (`409 successor_required`).
- Create household with the pet review step (your pets preselected, "These pets will be shared with household members").
- `/household-invite/:code` landing (accept / decline). Add to the public-path allowlist in `app_router.dart` like `/invite/` and `/absence-invite/`.
- `/pc/pets/households` → redirect to `/pc/people/households`.
- Delete the Sharing household UI and repository files listed in allowed_paths; the Sharing access/grant code (`household_pet_access`, who-has-access) stays.
- Shrink the architecture-test allowlist.

**Exit criteria:**

- [ ] Widget tests: create with review, invite, revoke, rename (organiser only), leave with successor, remove with preview choices, invite landing accept/decline
- [ ] Redirect test for `/pc/pets/households`; analyze and tests green

---

### Phase 16 — `p15-retire-legacy` · Delete legacy code; guards strict

| Field | Value |
|-------|-------|
| **id** | `p15-retire-legacy` |
| **ordinal** | 16/18 |
| **branch** | `cursor/people-refactor-p15-retire-legacy-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R1 |
| **protocols** | `testing`, `documentation` |

**Outcome:** No legacy People or vet client code remains, and both architecture tests run with empty allowlists.

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
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
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

**Scope:**

- Delete:
  - the Flutter `features/vet/**` feature entirely (screens, providers, use cases, repository, datasource, widgets, entity), after checking with grep that nothing imports it;
  - `PetCareMyVetsSection`;
  - the legacy People files (`PeopleContact`, `PeopleContactModel`, `PeopleRemoteDataSource`, `PersonRosterEntry`, `PeopleDirectoryCard`, deprecated providers, `people_legacy_vet_redirect_screen.dart`).
- Legacy vet deep links (`/pc/vets/:id`, `/pc/vets/edit/:id`, `/g/vets/*`, `/o/vets/*`, `/vets/*`) resolve through a small route-level resolver calling `GET /api/people/contacts/by-legacy-vet/:vetId`, or redirect to `/pc/people?filter=professionals` when unresolved.
- `grep -rn legacyVetId flutter_app/lib` returns nothing.
- Server: remove the superseded two-way functions in `vetSync.js` / `petVetLink.js` that p2 left as shims. Mark `/api/vets` **deprecated** in the API reference.
- Empty both architecture-test allowlists. Remove file-size allowlist entries for deleted files (`scripts/file-size-allowlist.json` via the `governance-allowlist` exception).
- Open a debt issue: "Sunset `vets` table and `pets.vet_id` behind a minimum-client-version gate", referencing R-01.

**Exit criteria:**

- [ ] `flutter_app/lib/features/vet/` no longer exists; `legacyVetId` absent from `flutter_app/lib`
- [ ] Both architecture tests pass with empty allowlists
- [ ] Legacy vet route tests pass (resolved and unresolved); analyze, Flutter tests and Jest green
- [ ] Sunset debt issue created and linked on the control issue

---

### Phase 17 — `p16-tests-e2e` · BDD and Playwright journeys

| Field | Value |
|-------|-------|
| **id** | `p16-tests-e2e` |
| **ordinal** | 17/18 |
| **branch** | `cursor/people-refactor-p16-tests-e2e-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |
| **router_risk** | R2 |
| **protocols** | `testing`, `release-verification`, `accessibility` |

**Outcome:** The People domain's user journeys are specified in Gherkin and covered by Playwright, with stable page objects.

**allowed_paths:**

```
flutter_app/test/bdd/features/people.feature
flutter_app/test/bdd/features/veterinarian_management.feature
flutter_app/test/bdd/features/away_planning.feature
flutter_app/test/bdd/features/sharing.feature
e2e/playwright/**
scripts/bdd-priority-tag-map.json
docs/e2e/**
flutter_app/lib/features/people/presentation/**
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `docs`

**Scope:** `flutter_app/lib/features/people/presentation/**` edits are limited to `Key` / semantics fixes needed by locators.

- `e2e/playwright/pages/people.page.ts` (roster, search, filters, card, detail tabs, edit, danger zone, add flow, picker). Retire `vet-list.page.ts` / `vet-form.page.ts` if unused. Serialize edits to `e2e/playwright/support/api.ts`.
- Scenarios (Gherkin `Scenario:` titles match `@bdd` headers exactly):
  1. Open Contacts from bottom navigation and see household, carers and professionals sections *(@smoke-ci)*
  2. Search by role and filter to professionals; `/pc/vets` lands on the professionals filter
  3. Desktop: select a person, the detail shows in the pane, and search is kept
  4. Add a pet professional as Buddy's primary vet; it appears on Buddy's emergency card
  5. Add a trusted carer and share Buddy with Can log care; a pending invite shows in the roster
  6. Edit a contact's roles and name; its kind is unchanged
  7. Removing a contact in use lists where it's used; mark it inactive; it isn't offered in pickers
  8. Pick a care provider and add a new one inline from the care item form
  9. Assign an absence carer with the picker
  10. Set Buddy's out-of-hours vet from People around Buddy
  11. Create a household, invite a member by email (accepted via API helper), then remove them with the remaining-access preview
  12. Today desk Vet team and Trusted carers cards open person detail *(@smoke-ci)*
- Update `people.feature` and the relevant existing features; update `scripts/bdd-priority-tag-map.json`.
- Locator hygiene per the testing rule: assert visibility, scope to the target row, use keys from `navigation-contract.md`.

**Exit criteria:**

- [ ] All 12 scenarios have Gherkin and Playwright specs; `node e2e/scripts/check_bdd_coverage.js --report-only` ≥ baseline (68% gate respected)
- [ ] Specs pass locally against `bin/start.js` single-origin (AGENTS.md); @smoke-ci subset green on the PR

---

### Phase 18 — `p17-ship-main` · Integration → main

| Field | Value |
|-------|-------|
| **id** | `p17-ship-main` |
| **ordinal** | 18/18 |
| **branch** | `cursor/people-refactor-p17-ship-main-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `release-verification`, `documentation` |

**Outcome:** The refactor lands on `main` with pre-UAT E2E green and the docs describe the shipped state.

**allowed_paths:**

```
docs/domains/people/**
docs/design/terminology.md
docs/architecture/index.md
docs/debt/refactoring-log.md
.agents/memory/MEMORY.md
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
```

**forbidden_paths:**

```
.github/workflows/**
```

**allowed_exceptions:** `docs`

**Scope:**

- Final docs PR into integration:
  - README status table "Shipped";
  - target doc `status: implemented`;
  - move shipped vocabulary rows into `terminology.md` per the vocabulary ship checklist (keep `vocabulary.md` for rows not yet shipped);
  - `MEMORY.md` entry (People façade and boundary tests);
  - refactoring-log completion.
- Rebase `cursor/people-domain-refactor-integration-7f3b` on `origin/main` and run `./scripts/pre-push.sh`.
- Open **one** PR integration → `main`. Run **/babysit-uat** until pre-UAT E2E is green for the merge SHA. On failure: `/e2e-debug` → `/babysit-uat` on the remedial PR in the same session.
- `complete-plan people-domain-refactor-7f3b --write`.

**Exit criteria:**

- [ ] Integration PR merged to `main`; pre-UAT E2E green on the merge commit
- [ ] `./scripts/pre-push.sh` green before the PR
- [ ] Control issue closed by `complete-plan` with the summary (phases, PRs, debt issues)

---

## Runtime state (agent-updated)

Do not edit manually during a run except on resume after halt.

```yaml
autonomy: halted            # draft — becomes active on approve-autonomous
current_phase: null
last_completed_phase: null
halt_reason: "draft — awaiting control issue + approve-autonomous"
next_action: "bootstrap per §Bootstrap, then /execute-plan people-domain-refactor-7f3b"
artifact_ref:
  branch: claude/exciting-bardeen-hy6yzp
  plan_path: .agents/plans/people-domain-refactor-7f3b.md
  plan_commit: null
  snapshot_path: .agents/plans/people-domain-refactor-7f3b.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

---

## Sanity check

**Expectation:** `proceed-high-risk`.

- Every phase has `allowed_paths`, `forbidden_paths`, `allowed_exceptions` and `exit_checklist`. Only valid exception codes are used (`tests`, `docs`, `file-split`, `governance-allowlist`).
- `allowed_paths` overlap only between **sequential** phases (for example `server/lib/people/**` in p1–p5, `features/people/**` in p6–p15). No phase is parallel (`spawn_allowed: false`), so there is no concurrent ownership conflict.
- Pessimistic estimate: 3 surfaces (server, Flutter, E2E) × 18 phases × CI factor 1.5 ≈ 30–40h of agent time. That exceeds a comfortable 24h session, so expect one `session_limit` checkpoint and possibly one window refresh (see §Bootstrap).
- Flagged risks:
  - four additive migrations, including one idempotent dedupe (083);
  - authorization changes in p1, p3, p4 and p5 (R3);
  - additive API changes only;
  - the E2E refresh in p16.

## Escalation watch

- A migration or data change not in §Pre-approved → halt (`escalation`)
- A breaking change to an existing response shape (`/api/vets`, pet `vet_id`, contacts list) → halt
- `.github/workflows/**`, a new package dependency, or any frozen-domain path → halt
- A product question not answered by D1–D28, R-01…R-14 or target doc §3.8 → `**Needs you:**` on the control issue, then continue with the rest of the phase if independent

## Revoke and resume

| Action | How |
|--------|-----|
| **Revoke** | Add `autonomous-revoked` on the control issue; optional `do-not-merge` on open PRs. Halt only; do not close PRs. |
| **Resume** | Remove the revoke label; comment `resume-plan people-domain-refactor-7f3b`; invoke `/execute-plan people-domain-refactor-7f3b resume` |

## Checklist before `approve-autonomous`

- [ ] Integration branch created with the plan artifacts and target doc (§Bootstrap step 1)
- [ ] Control issue created with labels `execute-plan`, `plan:people-domain-refactor-7f3b`
- [ ] Snapshot updated (control issue, approval window, `autonomy: active`), `--fix-hash`, validator passes
- [ ] Human has read target doc §3.3 (pre-approved migrations) and §6 (decisions)
