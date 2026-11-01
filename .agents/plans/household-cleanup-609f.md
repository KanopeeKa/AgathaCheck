# Household cleanup: lifecycle integrity, management and UI

## Goal
Make the household concept behave as `docs/domains/people/features/people-care-team.md` specifies,
fixing the gaps found in the 2026-11-02 review. Today a member who leaves keeps their pets shared
with the household; the last member cannot leave when household contacts are in use (foreign-key
`RESTRICT`, 500, rolled back after the "member left" notice went out) and otherwise contacts are
deleted and care providers and absence carers are silently nulled; account erasure leaves
households without an organiser or empty; transfer leaves a pet in a household its new owner cannot
leave; tiers and organisers cannot be changed after joining; the creation and join screens do not
match the spec; several writes are not transactional. Phases land on the integration branch in
dependency order (shared departure primitives first, then the callers, then UI, then E2E and docs);
one release PR goes to `main`, then Pre-UAT E2E and Deploy UAT.

Canonical doc updated by every behaviour phase (canonical-docs sync, decision-log rows):
`docs/domains/people/features/people-care-team.md`. Also maintained:
`docs/domains/people/changes/people-domain-refactor.md` (gap table),
`docs/engineering/privacy/erasure-data-map.md` (phase 4), `docs/architecture/api-reference.md` and
`docs/architecture/openapi/pet-care-critical.json` (route changes).

## Decisions encoded (approved with this plan)
- H1 Transfer: a pet in a household leaves it on transfer unless the new owner is already a member;
  household-directory contacts it uses are copied to the new owner (D23); neutral notice to the
  remaining members (D22) and a `pet_access_events` row.
- H2 Erasure of a sole organiser with other members: the longest-standing remaining member
  (`joined_at`, then `user_id`) becomes organiser on Full access. A user-facing successor prompt on
  `DELETE /me` is a follow-up outside this plan (that route is under `server/routes/auth/`).
- H3 "Remove all access to my pets": when an organiser removes someone else, it revokes that
  person's direct shares (`pet_access` `carer` / `co_parent`) and active absence guest grants on
  every pet the organiser owns. It does not apply to leaving yourself; your own pets always leave
  the household with you.
- H4 D23 copy scope: when a pet leaves a household, every reference from that pet's data to a
  household-directory contact is re-pointed to the owner's copy: pet relationships, care-item
  providers (`health_entries`, `health_occurrences`), absence carer rows (`planned_absence_pets`)
  and pending absence carer invites for absences that include the pet.
- H5 Closing a household (last member leaves, or erasure empties it) first runs the pet departure
  for every pet still in it, then deletes the household. It never fails on contact references and
  never nulls a provider or carer.

Out of this plan (each becomes a debt issue or its own plan when this one completes): Can log care
and carer-share narrowing to the care handover scope (D7; follow-up plan
`household-log-care-scope`), the per-pet transfer-or-delete choice on `DELETE /me` (D-lifecycle,
auth route), server-side recording of the 18-or-over confirmation (D14, needs a migration), the
two-sided transfer flow (R13), merging duplicate contacts.

## Phases

### Phase 1 — Pet departure and household close primitives
```json
{
  "allowed_paths": [
    "server/lib/households/departure/**",
    "server/lib/people/contactCopyOnPetLeave.js",
    "server/lib/people/contactsRepo.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "copyHouseholdContactsForPetLeave runs on a caller-supplied transaction client and re-points relationships, providers, absence carers and pending carer invites (H4)",
    "removePetFromHousehold and closeHousehold exported from server/lib/households/departure/ and return notices for after-commit emission",
    "server/test/db integration test: closing a household whose pets use household contacts succeeds with no nulled provider or carer",
    "canonical doc decision-log rows for H4 and H5",
    "pre-push-changed green"
  ]
}
```
Scope: make `copyHouseholdContactsForPetLeave` composable: when given a transaction client it uses
it (no nested `withTransaction`, which requires a pool); keep the pool call path working for the
current caller. Extend the re-point per H4 for the leaving pet only. Add
`server/lib/households/departure/` with `removePetFromHousehold(client, { householdId, petId,
ownerUserId, copyToUserId })` (copy contacts to `copyToUserId`, default the owner; delete the
`household_pets` row; record `pet_left_household`) and `closeHousehold(client, householdId)` (run
the departure for every pet still in the household, copying to each pet's owner, then delete the
household). Both return the D22 notice payloads; they never emit inside the transaction. Unit tests
with the mock pool; one real-database test under `server/test/db/` following the existing
`*.integration.test.js` pattern.
Out of scope: wiring the primitives into routes or services (phases 2 and 4), any schema change,
any Flutter file.

### Phase 2 — Household lifecycle on the server
```json
{
  "allowed_paths": [
    "server/lib/households/householdService.js",
    "server/lib/households/memberRemoval.js",
    "server/lib/households/householdInviteService.js",
    "server/lib/households/authz.js",
    "server/lib/households/constants.js",
    "server/lib/households/index.js",
    "server/lib/households/lifecycle/**",
    "server/routes/households/index.js",
    "server/routes/households/inviteRoutes.js",
    "server/routes/households/petRoutes.js",
    "server/lib/notifications/relationshipEmitters.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "leaving or being removed takes the member's own pets out of the household in the same transaction (G1)",
    "last member leaving closes the household via closeHousehold with no 500 (G2)",
    "member-left and pet-removed notices emitted only after commit",
    "remove_all_access_to_my_pets follows H3 and the removal preview lists pets leaving and grants revoked",
    "create, set-pets and invite accept are transactional; accept is a conditional update on pending; a pet already in another household returns 409 without moving",
    "record owner can take a pet out of a household without being a member (DELETE /api/households/:id/pets/:petId)",
    "POST /api/households/:id/members removed with its tests updated",
    "api-reference and canonical doc updated",
    "pre-push-changed green"
  ]
}
```
Scope: rewrite `removeHouseholdMember` as one transaction: successor promotion, membership delete,
the leaver's own pets leave through `removePetFromHousehold` (G1), H3 revocations when an organiser
removes someone else (the flag is ignored for self-leave), and `closeHousehold` when no member is
left; emit notices after commit. Extend the removal preview with `pets_leaving` (the target's own
pets in the household) and, for organiser removals, the grants H3 would revoke; keep
`remaining_access` correct after H3. Wrap `createHousehold` and `setHouseholdPets` in transactions;
`setHouseholdPets` uses `removePetFromHousehold` for removals and inserts with
`ON CONFLICT (pet_id) DO NOTHING`, returning 409 when the pet is in another household. Make
`acceptHouseholdInvite` transactional with `UPDATE … WHERE status = 'pending' AND expires_at > now()
RETURNING`, a membership conflict mapped to 409, and notifications after commit. Add the owner exit
route `DELETE /api/households/:id/pets/:petId` (record owner only, membership not required). Remove
the direct-add route `POST /:id/members` and `addHouseholdMember` (no client or E2E caller). Split
`householdService.js` into `server/lib/households/lifecycle/` modules if it would pass 500 lines.
Out of scope: changing a member's tier (phase 3), transfer and erasure (phase 4), Flutter.

### Phase 3 — Member tier and organiser management
```json
{
  "allowed_paths": [
    "server/lib/households/membership/**",
    "server/routes/households/memberRoutes.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["server/routes/households/index.js"],
  "exit_checklist": [
    "PATCH /api/households/:id/members/:userId changes access_tier and is_organiser; organisers only (D3)",
    "organiser always normalised to full_access (D13); demoting the last organiser returns 409 last_organiser",
    "route tests cover organiser, non-organiser, self-demotion with and without another organiser, unknown member",
    "api-reference, openapi and canonical doc updated",
    "pre-push-changed green"
  ]
}
```
Scope: add `PATCH /api/households/:id/members/:userId` with body `{ access_tier?, is_organiser? }`
in `server/routes/households/memberRoutes.js`, registered from `index.js` (companion), backed by
`server/lib/households/membership/`. Validate with the existing tier constants and
`normalizeMemberTier`; at least one organiser must remain; an organiser may demote themselves only
when another organiser exists. Effective access stays computed at read time; nothing else is stored.
Return the updated member DTO in the existing `mapMemberRow` shape.
Out of scope: notifications for tier changes, Flutter (phase 5), invite changes.

### Phase 4 — Transfer, account erasure and legacy repair
```json
{
  "allowed_paths": [
    "server/routes/pets/transferRouter.js",
    "server/lib/account/accountErasureService.js",
    "server/lib/households/accountDeletionGuard.js",
    "server/lib/households/erasure/**",
    "server/scripts/reconcileHouseholds.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "transfer applies H1 inside the transfer transaction; notices after commit",
    "acceptAccountErasure releases the user's households in its transaction: H2 promotion, own pets leave, empty households close (G3)",
    "server/scripts/reconcileHouseholds.js defaults to --dry-run and reports households without an organiser, empty households and pets whose owner is not a member; --apply repairs them with the departure primitives",
    "erasure-data-map and canonical doc updated",
    "pre-push-changed green"
  ]
}
```
Scope: in `transferRouter.js`, after the owner update inside the existing transaction, apply H1 with
`removePetFromHousehold(…, copyToUserId: newOwner)` when the new owner is not a member of the pet's
household. Add `server/lib/households/erasure/` with
`releaseHouseholdsForDepartingUser(client, userId)` and call it from `acceptAccountErasure` before
the user row is deleted: H2 promotion where the user is the sole organiser and others remain, the
user's own pets leave their households, and `closeHousehold` where the user was the last member.
Leave the `DELETE /me` 409 confirmation untouched. Add the repair script (dry-run default, no run
in this plan; the owner runs it on UAT and production after release). Unit tests for transfer and
erasure; extend `server/test/db/accountErasure.integration.test.js` for the household cases.
Out of scope: anything under `server/routes/auth/`, schema changes, the two-sided transfer flow.

### Phase 5 — Household screens match the spec
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/people/presentation/households/**",
    "flutter_app/lib/features/people/data/households_api.dart",
    "flutter_app/lib/features/people/data/dto/people_dtos.dart",
    "flutter_app/lib/features/people/application/**",
    "flutter_app/lib/features/people/domain/entities/household*.dart",
    "flutter_app/lib/features/people/domain/repositories/people_repository.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/who_has_access_section.dart",
    "flutter_app/lib/features/sharing/data/**",
    "flutter_app/lib/features/sharing/domain/**",
    "flutter_app/lib/l10n/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "create flow pre-selects all of the user's pets under the review heading (G4)",
    "after accepting an invite the user sees 'Share any of your pets with <household>?' with nothing pre-selected, then lands on the household (G5)",
    "organisers can change a member's tier and organiser flag on the household detail page; last-organiser 409 shown calmly",
    "removal and leave dialogs show pets leaving and remaining access from the new preview; 'Remove all access to my pets' offered only when removing someone else",
    "record owner can remove their pet from a household from the pet's Who has access section",
    "EN and FR strings per vocabulary.md; flutter analyze and household widget tests green",
    "pre-push-changed green"
  ]
}
```
Scope: client for the phase 2 and 3 API changes (`DELETE …/pets/:petId`, `PATCH …/members/:userId`,
new preview fields, removed direct add). G4 pre-selection in `household_create_flow.dart`. G5 step
after `acceptHouseholdInvite` in the invite landing flow, calling the existing set-pets API with
the user's own pets. Tier and organiser editing on `household_detail_page.dart` (organisers only).
Removal dialog per H3. Owner exit from the pet's Who has access household row. Copy follows
`docs/domains/people/features/vocabulary.md` (for example "Remove Buddy from « Famille Morgan »",
never "Quitter le foyer"). Split any file that would pass 500 lines.
Out of scope: Can log care gating in other pet screens, server changes, E2E specs (phase 6).

### Phase 6 — End-to-end journeys and docs closeout
```json
{
  "allowed_paths": [
    "e2e/playwright/pages/people.page.ts",
    "e2e/playwright/support/api.ts",
    "e2e/scripts/spec-domains.mjs",
    "docs/domains/people/**",
    "docs/engineering/privacy/**",
    "docs/architecture/api-reference.md"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "e2e/playwright/tests/households-lifecycle.spec.ts covers leave-with-pets, last-member close, organiser tier change and owner pet removal, tagged @people @P1",
    "spec registered in e2e/scripts/spec-domains.mjs under people",
    "people-care-team.md status, lifecycle table and Still open section match shipped behaviour; decision-log rows for H1-H5",
    "people-domain-refactor.md gap table: fixed rows folded out, remaining follow-ups listed with debt issue links",
    "BDD coverage report and docs gates green",
    "pre-push-changed green"
  ]
}
```
Scope: a new Playwright spec using API helpers in `api.ts` for setup (create household, invite and
accept, add pets) and the People page object for the journeys: a member leaves and their pet is no
longer listed in the household; the last member leaves and the household is gone; an organiser
changes a member to Can log care; a record owner removes their pet from a household. Register the
spec under the people domain. Close out the docs: canonical doc status and lifecycle rows, decision
log H1–H5, the change doc gap table, and debt issues for every item listed as out of this plan.
Out of scope: product code changes; if a journey exposes a product bug, fix it in the phase that
owns the file through a remedial step rather than here.

## Proof on UAT
Pre-UAT E2E runs `households-lifecycle.spec.ts` green on the release merge. Manually on
https://uat.agathatrack.com with two demo accounts: create a household with a pet, invite the
second account and accept (the share-your-pets step appears), have the second account share a pet
and then leave; the household detail no longer lists that pet and the leaver still sees it under
their own pets. Then remove the remaining members until one is left and leave: the household
disappears from Contacts → Households with no error.
