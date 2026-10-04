# People server — execute-plan (`people-server-7f3b`)

| Field | Value |
|-------|-------|
| **plan_id** | `people-server-7f3b` |
| **parent** | roadmap [`people-domain-refactor-7f3b`](./people-domain-refactor-7f3b.md), child 2 of 4 |
| **title** | One writer, one access policy, relationships as source of truth, read models, household directory and invites |
| **base_branch** | `cursor/people-server-integration-7f3b` (created from `origin/main` at bootstrap) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **phases** | 7 (commit prefix `phase(<n>/7): …`) |
| **entry gate** | On `origin/main`: CARE A+B (`care-next-occurrence-c1a7` engine, migration `083_care_occurrence_model`) **and** ARCH E (`active-codebase-batch-e-backend-integrity-e41f`). Landing slot 4 in [parallel-programmes §4](../../docs/agent-efficiency/parallel-programmes.md) |
| **source of truth** | [target doc](../../docs/domains/people/changes/people-domain-refactor.md) §3.3–§3.6 (invariants, server architecture, access policy, API) |

## Goal

Make the server the single authority for People:

- **One writer** (`contactsRepo`) and **one access module** (`access.js`), with stable error codes.
- **Usage-aware delete.**
- **Pet relationships as the source of truth**, with `vets` / `pets.vet_id` written only by a projection behind unchanged compat endpoints.
- **Read models** for the roster, contact detail, related care and people around a pet.
- **Household-directory contacts and notes**, and safe member removal.
- **Household email invites**, with share and household invites that link to contacts.

Fixes B3, B6 (tests; implementation handed to CARE B), B10, B11 and B12.

## Rules for every phase (in addition to the roadmap locks)

- **Start of phase:** rebase on `origin/main`. If a landing broadcast arrived since the last phase, run the full `./scripts/pre-push.sh` before continuing.
- **Areas released to People** by the time this child starts (parallel-programmes §3):
  - People server;
  - the care engine for provider rules (after CARE B and ARCH E);
  - pets core for the `vet_id` adapter;
  - sharing invites (after ARCH E).

  **Not released:** absences (`server/routes/careContext/**`, owned by CARE until CARE E+F lands). Don't edit them here.
- New transaction code uses the shared helper landed by ARCH E; no hand-written `BEGIN`.
- **Contracts:** `docs/architecture/api-reference.md` and `docs/architecture/openapi/pet-care-critical.json` change in the same PR as the route, and `node scripts/validate_openapi.js` must be green.
- **Migrations:** referenced by name (`db/migrations/*_<name>.sql`). While on the integration branch, use the next free number on `origin/main`; renumber in `s7` if taken. Follow `.cursor/agent-kernel/protocols/database-and-migrations.md`, including `db/schema/migration-manifest.json` and the canonical schema.
- **R2+ phases:** integration review per `.cursor/agent-kernel/workers/integration-reviewer.md` before merge.

---

### Phase 1 — `s1-writer-access` · One writer, one access policy, typed errors

| Field | Value |
|-------|-------|
| **id** | `s1-writer-access` |
| **ordinal** | 1/7 |
| **branch** | `cursor/people-server-s1-writer-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `api-contract`, `validation`, `testing` |

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/test/people/**
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
server/test/openapi/**
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
db/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/routes/careContext/**
server/lib/households/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Outcome:** Every People write goes through one repository, every People visibility decision goes through one access module, and People routes return stable error codes. Behaviour is otherwise unchanged; the kind fix already shipped in `people-hotfixes-7f3b`.

**Scope** (target doc §3.4, §3.5):

- `server/lib/people/index.js` façade; `errors.js` (`PeopleError(code, status, details)` → `{ error, code, details }`).
- `constants.js` gains `ROLE_GROUP`; `inference.js` holds `inferContactKind` and `contactGroup`.
- `contactsRepo.js`, the single writer (create / update / setActive / delete / copy, plus roles and private notes, in one transaction via the shared helper). Migrate every raw insert and update:
  - `contactMutations.js` (fold it in);
  - `vetSync.js` (contact rows);
  - `absenceCarer.js` (`ensureLinkedUserContact`, `ensureNoteOnlyContact`), without changing absence routes;
  - `contactCopyOnPetLeave.js`.
- PATCH: `active: boolean` stamps `inactive_at` server-side, and a sent `inactive_at` is validated. Name/email change on a contact with `linked_user_id` → `409 linked_identity_read_only`.
- `access.js`: `visibleDirectoryIds` (personal for now), `canViewContact`, `canEditContact`, `canAttachContactToPet`, and a `careHandoverScope` stub. Used by the contacts routes, the relationships router helpers (via the façade) and `absenceCarer`. Remove `assertPersonalDirectoryOwner` and the orphaned JSDoc in `vetSync.js`.
- `server/test/people/boundaries.test.js` fails on:
  - `INSERT INTO | UPDATE | DELETE FROM people_(contacts|contact_roles|contact_private_notes|directories)` outside `server/lib/people/`;
  - imports of `lib/people/<file>` other than `index.js` from outside `lib/people`.

  Migrations, seeds and migration scripts are excluded. Temporary allowlist: `vets` writes in `lib/people/vetSync.js` and `routes/vets.js`, removed in `s3`.

**Exit criteria:**

- [ ] Access-matrix tests: owner / co-parent / stranger × view / edit / attach; linked-identity 409 test
- [ ] `boundaries.test.js` passes; `INSERT INTO people_contacts` appears only in `lib/people/contactsRepo.js` (seeds and migration scripts excepted)
- [ ] Compat: the existing contacts CRUD tests pass unchanged apart from the added `code` field
- [ ] Jest green; files ≤500 lines; API reference and OpenAPI updated

---

### Phase 2 — `s2-usages-provider` · Usage-aware delete and provider rules

| Field | Value |
|-------|-------|
| **id** | `s2-usages-provider` |
| **ordinal** | 2/7 |
| **branch** | `cursor/people-server-s2-usages-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `api-contract`, `data-lifecycle`, `testing` |

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/lib/care/occurrence/**
server/lib/care/providerUsed.js
server/routes/healthEntries/**
server/test/people/**
server/test/healthEntries/**
server/test/healthEntries.test.js
server/test/lib/care/**
server/test/careSchedule/**
server/test/db/**
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
server/test/openapi/**
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
db/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/routes/careContext/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Outcome:** A contact that is in use can't silently disappear, a vet-linked contact that isn't in use can be deleted, and care items can only reference contacts the user may attach. This fixes B3 and B10, B12, and pins B6.

**Scope:**

- `usages.js`: active relationships, absence carers on current or future absences, care-item providers (`health_entries.provider_contact_id`), pending carer invites, works-at references. History snapshots are not usages.
- DELETE → `409 contact_in_use` with `details.usages` (**B10**). An unused vet-linked contact deletes, removing its `vets` row through the vet sync function (**B3**; `s3` moves this into the projection). Move the router's inline SQL into `contactsRepo`.
- Care item create/update: validate `provider_contact_id` with `canAttachContactToPet` → `400 validation_failed` (**B12**). Apply it in CARE's command location (`server/lib/care/occurrence/**` or the health entries routes, whichever holds the write after CARE B).
- **B6:** confirm CARE B recorded the provider snapshot from the attached contact without a completer-directory filter (hand-off I12). Add the regression test: a co-parent completing an occurrence keeps the provider snapshot. Validate a completion body override with `canAttachContactToPet`. If CARE B did not implement I12, implement it here in CARE's command module, since the area is released by then.

**Exit criteria:**

- [ ] Regression tests:
  - B3: an unused vet-linked contact deletes and its `vets` row is gone.
  - B10: a contact used as a care-item provider → 409 listing it.
  - B12: a provider from another user's directory is rejected.
  - B6: a co-parent completion keeps the provider snapshot.
- [ ] CARE's occurrence write-path guard (`scripts/check_occurrence_writes.js`, if landed) still green
- [ ] Jest green (including `server/test/db` when touched); API reference and OpenAPI updated

---

### Phase 3 — `s3-relationships` · Relationships authoritative; vets as projection

| Field | Value |
|-------|-------|
| **id** | `s3-relationships` |
| **ordinal** | 3/7 |
| **branch** | `cursor/people-server-s3-relationships-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R2 |
| **protocols** | `database-and-migrations`, `api-contract`, `authorization`, `data-lifecycle`, `testing` |

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/routes/pets/peopleRelationshipsRouter.js
server/routes/pets/coreRouter.js
server/routes/vets.js
server/scripts/reconcilePeopleVets.js
server/db/seeds/**
db/migrations/*_people_relationship_slots.sql
db/migrations/*_people_relationship_slots_down.sql
db/schema/**
server/test/people/**
server/test/vets.test.js
server/test/pets/**
server/test/migrations/*_people_relationship_slots.test.js
server/test/seed.test.js
server/test/openapi/**
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/routes/careContext/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Outcome:** Pet relationships are the only source of truth for a pet's vet and other contacts. `vets` and `pets.vet_id` are written only by a projection, behind unchanged compat endpoints. This fixes B11.

**Scope** (target doc §3.3 I4–I6, §3.6, §5.1):

- Migration `*_people_relationship_slots` exactly as pre-approved: `sort_order`, partial unique active-slot indexes, and the idempotent dedupe that keeps the newest row and logs the count. Includes the down file, manifest and canonical schema.
- `relationships.js`:
  - `listForPet`;
  - `setSlot` (replace semantics for `primary_vet` / `out_of_hours_vet`);
  - `add` (emergency_contact / care_provider / other);
  - `remove`;
  - `reorder`.
  - Each mutation is transactional and calls `vetProjection.projectPet(petId)`.
- `vetProjection.js` (`projectPet`, `projectContact`, `rebuildAll`) is the **only** writer of `vets` rows and `pets.vet_id`. Absorb the two-way logic from `vetSync.js` and `petVetLink.js`.
- **Compat adapters**, with byte-compatible responses:
  - `routes/vets.js` → `contactsRepo` + projection;
  - `pets/coreRouter.js` `vet_id` writes → `relationships.setSlot('primary_vet', …)`;
  - legacy `PUT /api/pets/:id/people-relationships` goes through the service and re-projects (**B11**).
- **New endpoints:**
  - `PUT /api/pets/:petId/people-relationships/slots/:kind`
  - `POST /api/pets/:petId/people-relationships`; a POST of a slot kind → `409 slot_conflict`
  - `DELETE /api/pets/:petId/people-relationships/:relationshipId`
- `POST /api/people/contacts` accepts optional `pet_links[]` (`{ pet_id, relationship_kind }`) in the same transaction, checked with `canAttachContactToPet`.
- `reconcilePeopleVets.js` → `vetProjection.rebuildAll()` (People → vets). Seeds create professionals through the People service. Only the contact/professional calls change; CARE's reseed structure is untouched.
- Tighten `boundaries.test.js`: `vets` writes only in `vetProjection.js`; `vets` reads only in `routes/vets.js` and `vetProjection.js`.

**Exit criteria:**

- [ ] Invariant I5 matrix: set, replace and clear the primary vet via the slots endpoint, legacy pet PATCH `vet_id`, `DELETE /api/vets/:id` and legacy PUT-all. `pets.vet_id` always matches.
- [ ] **Seed check** (carried over from `people-vet-unify-a58d` p5): after seeding, every professional with the vet role has a contact, a projection row and a matching `pets.vet_id`
- [ ] Compat contract tests: `/api/vets` CRUD and pet GET `vet_id` shapes unchanged
- [ ] Migration applies on a DB with duplicate active slots and leaves one active; down migration passes
- [ ] OpenAPI and API reference updated; Jest green

---

### Phase 4 — `s4-read-models` · Roster, detail, related care, pet people

| Field | Value |
|-------|-------|
| **id** | `s4-read-models` |
| **ordinal** | 4/7 |
| **branch** | `cursor/people-server-s4-read-models-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `api-contract`, `date-time`, `testing` |

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
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
db/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/routes/careContext/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Outcome:** The server returns everything the People UI needs as read models, so the client no longer derives groups, counts or linked pets.

**Scope** (target doc §3.6 DTOs):

- `roster.js` + `GET /api/people/roster`:
  - households with members, via exported household read functions (no behaviour change);
  - `contacts[]` as `ContactSummary` (group, status, pets with relationship kinds, `works_at`, `next_absence`, access summary for linked accounts);
  - `pending_invites[]` (pet share and absence carer invites created by the viewer; the household source is added in `s6`).
- `detail.js`:
  - enriched `GET /api/people/contacts/:id`;
  - `GET /api/people/contacts/:id/related`;
  - `GET /api/people/contacts/by-legacy-vet/:vetId` → `{ id }`.
- `GET /api/pets/:petId/people`: slots, household members, carers, professionals, emergency contacts. Scope-aware: Can log care and absence guests get only the care handover scope.
- `GET /api/people/contacts` adds `group`, `status` and `directory` (additive).
- Dates `YYYY-MM-DD`; bounded query count (no N+1).

**Exit criteria:**

- [ ] DTO shape tests (including empty cases); scope tests (Can log care / guest handover scope only; stranger denied)
- [ ] Mock-pool test: the roster query count doesn't grow with contact count
- [ ] OpenAPI and API reference updated; Jest green

---

### Phase 5 — `s5-households-api` · Household directory, notes, safe removal

| Field | Value |
|-------|-------|
| **id** | `s5-households-api` |
| **ordinal** | 5/7 |
| **branch** | `cursor/people-server-s5-households-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `database-and-migrations`, `data-lifecycle`, `api-contract`, `testing` |

**allowed_paths:**

```
server/lib/people/**
server/routes/people/**
server/lib/households/**
server/routes/households/**
db/migrations/*_people_household_notes.sql
db/migrations/*_people_household_notes_down.sql
db/schema/**
server/test/people/**
server/test/households/**
server/test/migrations/*_people_household_notes.test.js
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/routes/careContext/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Outcome:** Household members see and manage their household's contacts and notes according to the access policy, and member removal is safe and previewable.

**Scope:**

- `access.js` household directories: Full access and organisers get view / edit / create / attach; Can log care gets no directory view.
- `POST /api/people/contacts` accepts `household_id` (Full access only). The roster and contacts list include visible household-directory contacts.
- Migration `*_people_household_notes`. `household_note` read/write on detail and PATCH (members only; never shown to the linked person, I10).
- `GET /api/households/:id/members/:userId/removal-preview` (access kept per pet and source, D16).
- `removeHouseholdMember`:
  - one transaction;
  - last organiser names a successor (`409 successor_required`, accepts `successor_user_id`);
  - "remove all access to my pets" available to pet owners.
- Contact copy on pet leave (D23) goes through `contactsRepo.copy`, with a test.
- Register the new personal-data table for ARCH F's inventory: a note in the API reference and a `data-lifecycle` protocol comment in the PR body.

**Exit criteria:**

- [ ] Access matrix extended: Full access / Can log care / organiser × household contacts
- [ ] Household note visibility tests (member yes, non-member no, linked person no)
- [ ] Removal tests: transactional rollback, successor rule, preview lists remaining direct shares
- [ ] Migration test; Jest green; API reference and OpenAPI updated

---

### Phase 6 — `s6-invites-api` · Household email invites; invites link to contacts

| Field | Value |
|-------|-------|
| **id** | `s6-invites-api` |
| **ordinal** | 6/7 |
| **branch** | `cursor/people-server-s6-invites-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R3 |
| **protocols** | `authorization`, `security`, `database-and-migrations`, `api-contract`, `observability`, `testing` |

**allowed_paths:**

```
server/lib/households/**
server/routes/households/**
server/routes/sharing/inviteRoutes.js
server/services/sharing/**
server/lib/people/**
server/lib/email/**
server/lib/emailTemplates.js
db/migrations/*_share_invite_contact_link.sql
db/migrations/*_share_invite_contact_link_down.sql
db/migrations/*_household_invites.sql
db/migrations/*_household_invites_down.sql
db/schema/**
server/test/households/**
server/test/sharing/**
server/test/people/**
server/test/email.test.js
server/test/migrations/*_share_invite_contact_link.test.js
server/test/migrations/*_household_invites.test.js
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
docs/domains/sharing/**
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
server/routes/organizations/**
server/routes/careContext/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Outcome:** Organisers can invite people to a household by email, and accepting a household or pet-share invite links the account to the People contact it was sent from.

**Scope:**

- Migrations `*_share_invite_contact_link` and `*_household_invites` as pre-approved.
- Household invites service, modelled on `absenceCarerInviteService.js`:
  - `POST /api/households/:id/invites` (organisers; email, tier, `is_organiser`, optional `contact_id`; 14-day expiry; rate-limited);
  - `GET /api/households/invites/code/:code`, plus `/accept` and `/decline` (accept adds membership via `householdService`; invitees without an account sign up first, as with pet share invites);
  - `DELETE /api/households/:id/invites/:inviteId`.
- Email template `householdInvitation` (EN/FR). Landing URL `/household-invite/<code>`.
- Pet share invite create accepts optional `contact_id` (caller must pass `canEditContact`), **on top of ARCH E's invite replay and concurrency semantics (D22)**. Accept sets `linked_user_id` when it is null and never overwrites a different link (log and skip).
- Roster `pending_invites` adds the `household` source. Structured log events for create, accept and revoke (ids only, no PII).

**Exit criteria:**

- [ ] Household invite lifecycle tests: create, accept, decline, revoke, expire, non-organiser denied, duplicate member
- [ ] Contact link tests for share and household invites, including the "already linked elsewhere" skip; ARCH E's replay tests still green
- [ ] Email rendering (EN/FR); migration tests; Jest green; API reference and OpenAPI updated

---

### Phase 7 — `s7-ship-main` · Integration → main

| Field | Value |
|-------|-------|
| **id** | `s7-ship-main` |
| **ordinal** | 7/7 |
| **branch** | `cursor/people-server-s7-ship-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R2 |
| **protocols** | `release-verification`, `documentation`, `database-and-migrations` |

**allowed_paths:**

```
docs/domains/people/**
docs/architecture/api-reference.md
docs/agent-efficiency/parallel-programmes.md
db/migrations/*_people_relationship_slots*.sql
db/migrations/*_people_household_notes*.sql
db/migrations/*_share_invite_contact_link*.sql
db/migrations/*_household_invites*.sql
db/schema/**
server/test/migrations/**
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
```

**forbidden_paths:**

```
.github/workflows/**
flutter_app/**
```

**allowed_exceptions:** `docs`, `tests`

**Outcome:** The People server lands on `main` in landing slot 4 with pre-UAT green.

**Scope:**

- Rule 1 of [parallel-programmes §5](../../docs/agent-efficiency/parallel-programmes.md): confirm no other programme's `main` PR is open.
- Rebase the integration branch on `origin/main`. **Renumber the four migrations** to the next free numbers if taken (file renames, manifest, canonical schema, migration tests only).
- Update the People README status rows and the target doc's delivery table.
- Run `./scripts/pre-push.sh`. Open **one** PR integration → `main`. The merge payload is the whole integration branch; this phase's own diff is only the docs and renumbering above.
- Run **/babysit-uat** until pre-UAT E2E is green on the merge SHA. On failure: `/e2e-debug` → `/babysit-uat` on the remedial PR in the same session.
- `complete-plan people-server-7f3b --write`. Post the landing broadcast (parallel-programmes §7) on every open programme control issue. Roadmap `roadmap-set-child … --status merged`.

**Exit criteria:**

- [ ] Integration PR merged; pre-UAT green on the merge commit; broadcast posted
- [ ] Installed-client note in the PR body: `/api/vets` and pet `vet_id` unchanged, new fields additive

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: s4-read-models
last_completed_phase: s3-relationships
halt_reason: null
next_action: "start phase s4-read-models on branch cursor/people-server-s4-read-models-7f3b"
artifact_ref:
  branch: cursor/people-server-integration-7f3b
  plan_path: .agents/plans/people-server-7f3b.md
  plan_commit: 3fc29bc9b05eee15f7ad780da7f166d494c5d8d9
  snapshot_path: .agents/plans/people-server-7f3b.snapshot.json
  snapshot_commit: 3fc29bc9b05eee15f7ad780da7f166d494c5d8d9
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
