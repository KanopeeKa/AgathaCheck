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
`docs/engineering/privacy/erasure-data-map.md` (phase 5), `docs/architecture/api-reference.md` and
`docs/architecture/openapi/pet-care-critical.json` (every phase that changes a route or DTO).

## Decisions encoded (approved with this plan)
- H1 Transfer: a pet in a household leaves it on transfer unless the new owner is already a member;
  household-directory contacts it uses are copied to the new owner (D23); neutral notice to the
  remaining members (D22) and a `pet_access_events` row.
- H2 Erasure of a sole organiser with other members: the longest-standing remaining **Full access**
  member (`joined_at`, then `user_id`) becomes organiser; only when there is none does the
  longest-standing Can log care member become organiser (and therefore Full access, D13). The
  promoted member always gets a notification (D16). A user-facing successor prompt on `DELETE /me`
  is a follow-up outside this plan (that route is under `server/routes/auth/`).
- H3 "Remove all access to my pets": when an organiser removes someone else, it revokes that
  person's direct shares (`pet_access` `carer` / `co_parent`) and active absence guest grants on
  every pet the organiser owns. It does not apply to leaving yourself; your own pets always leave
  the household with you.
- H4 D23 copy scope: when a pet leaves a household, every reference from that pet's data to a
  household-directory contact is re-pointed to the owner's copy: pet relationships, care-item
  providers (`health_entries`, `health_occurrences`), absence carer rows (`planned_absence_pets`)
  and pending absence carer invites for absences that include the pet.
- H5 Closing a household is driven by the household directory's contacts, not by the pets still in
  the household: every remaining reference to a household contact (from any pet, in the household
  or not) is re-pointed to a copy in the referencing pet's owner's personal directory, then the
  household is deleted. It never fails on a `RESTRICT` reference and never nulls a provider or
  carer. D22 notices go only for pets that were still in the household.
- H6 Account erasure releases households **after** the user row is deleted, inside the same
  transaction, using the memberships captured before the delete. The user's own pets are already
  gone by then (`pets.user_id` cascades), so no contact is copied into the deleted user's
  directory and no "pet removed" notice is sent for a deleted pet.

Out of this plan (each becomes a debt issue or its own plan when this one completes): Can log care
and carer-share narrowing to the care handover scope (D7; follow-up plan
`household-log-care-scope`), the per-pet transfer-or-delete choice on `DELETE /me` (auth route),
server-side recording of the 18-or-over confirmation (D14, needs a migration), the two-sided
transfer flow (R13), merging duplicate contacts, and whether `absenceCarer.js` should pass `petId`
to `contactUsableForPet` (today household contacts cannot be absence carers).

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
    "closeHousehold re-points references from pets outside the household too (H5)",
    "server/test/db integration test: closing a household whose pets (one in the household, one that already left with a stale provider reference) use household contacts succeeds with no nulled provider, carer or relationship",
    "canonical doc decision-log rows for H4 and H5",
    "pre-push-changed green"
  ]
}
```
Scope: make `copyHouseholdContactsForPetLeave` composable: when given a transaction client it uses
it (no nested `withTransaction`, which requires a pool); keep the pool call path working for the
current caller. Extend the re-point per H4 for the leaving pet. Add
`server/lib/households/departure/` with `removePetFromHousehold(client, { householdId, petId,
ownerUserId, copyToUserId })` (copy contacts to `copyToUserId`, default the owner; delete the
`household_pets` row; record `pet_left_household`) and `closeHousehold(client, householdId)` per
H5: remove every pet still in the household (D22 notices for those), then, starting from the
household directory's contacts, re-point every remaining reference to the referencing pet owner's
copy, then delete the household. Both return notice payloads; they never emit inside the
transaction. Unit tests with the mock pool; one real-database test under `server/test/db/`
following the existing `*.integration.test.js` pattern.
Out of scope: wiring the primitives into routes or services (phases 2, 3 and 5), any schema change,
any Flutter file.

### Phase 2 — Leaving and closing a household
```json
{
  "allowed_paths": [
    "server/lib/households/lifecycle/**",
    "server/lib/households/memberRemoval.js",
    "server/lib/notifications/relationshipEmitters.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [
    "server/lib/households/householdService.js",
    "server/lib/households/index.js",
    "server/routes/households/index.js"
  ],
  "exit_checklist": [
    "leaving or being removed takes the member's own pets out of the household in the same transaction (G1)",
    "last member leaving closes the household via closeHousehold with no 500 (G2)",
    "member-left and pet-removed notices emitted only after commit",
    "remove_all_access_to_my_pets follows H3; the removal preview adds pets_leaving and the grants H3 would revoke, and remaining_access stays correct",
    "openapi removal-preview schema and api-reference updated; canonical doc updated",
    "pre-push-changed green"
  ]
}
```
Scope: move member removal into `server/lib/households/lifecycle/` (re-exported from
`householdService.js` so the route keeps its import) as one transaction: successor promotion,
membership delete, the leaver's own pets leave through `removePetFromHousehold` (G1), H3
revocations when an organiser removes someone else (the flag is ignored for self-leave), and
`closeHousehold` when no member is left; emit notices after commit. Extend the removal preview in
`memberRemoval.js` with `pets_leaving` (the target's own pets in the household) and, for organiser
removals, the grants H3 would revoke.
Out of scope: create, set-pets and invite flows (phase 3), tier changes (phase 4), transfer and
erasure (phase 5), Flutter.

### Phase 3 — Household write integrity
```json
{
  "allowed_paths": [
    "server/lib/households/householdService.js",
    "server/lib/households/householdInviteService.js",
    "server/lib/households/authz.js",
    "server/lib/households/constants.js",
    "server/lib/households/index.js",
    "server/lib/households/pets/**",
    "server/routes/households/index.js",
    "server/routes/households/inviteRoutes.js",
    "server/routes/households/petRoutes.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "create, set-pets and invite accept are transactional; notices after commit",
    "accept is a conditional update on pending and unexpired; a duplicate membership returns 409",
    "a pet already in another household returns 409 and is never moved (ON CONFLICT DO NOTHING)",
    "record owner can take a pet out of a household without being a member (DELETE /api/households/:id/pets/:petId)",
    "POST /api/households/:id/members and addHouseholdMember removed with their tests updated",
    "openapi and api-reference updated for the new and removed routes; canonical doc updated",
    "pre-push-changed green"
  ]
}
```
Scope: wrap `createHousehold` and `setHouseholdPets` in transactions; `setHouseholdPets` uses
`removePetFromHousehold` for removals and inserts with `ON CONFLICT (pet_id) DO NOTHING`, returning
409 when the pet is in another household. Make `acceptHouseholdInvite` transactional with
`UPDATE … WHERE status = 'pending' AND expires_at > now() RETURNING` and a membership conflict
mapped to 409. Add the owner exit route `DELETE /api/households/:id/pets/:petId` (record owner
only, membership not required) in `petRoutes.js` backed by `server/lib/households/pets/`. Remove
the direct-add route `POST /:id/members` and `addHouseholdMember` (no client, E2E or server
caller). Split files that would pass 500 lines.
Out of scope: member removal and the preview (phase 2), tier changes (phase 4), Flutter.

### Phase 4 — Member tier and organiser management
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
    "openapi, api-reference and canonical doc updated",
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
Out of scope: notifications for tier changes, Flutter (phase 6), invite changes.

### Phase 5 — Transfer, account erasure and legacy repair
```json
{
  "allowed_paths": [
    "server/routes/pets/transferRouter.js",
    "server/lib/account/accountErasureService.js",
    "server/lib/households/accountDeletionGuard.js",
    "server/lib/households/erasure/**",
    "server/lib/notificationKind.js",
    "server/scripts/reconcileHouseholds.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "transfer applies H1 inside the transfer transaction; notices after commit",
    "acceptAccountErasure applies H6: memberships captured before DELETE FROM users, households released after it in the same transaction (H2 promotion, empty households closed)",
    "H2 prefers Full access, falls back to Can log care, and notifies the promoted member after commit",
    "erasure integration test: a user whose own pet uses a household vet is erased; no contact is copied to the deleted user and no pet-removed notice is sent",
    "server/scripts/reconcileHouseholds.js defaults to --dry-run and reports households without an organiser, empty households, pets whose owner is not a member, and references to household contacts from pets outside that household; --apply repairs them with the departure primitives",
    "erasure-data-map and canonical doc updated",
    "pre-push-changed green"
  ]
}
```
Scope: in `transferRouter.js`, after the owner update inside the existing transaction, apply H1 with
`removePetFromHousehold(…, copyToUserId: newOwner)` when the new owner is not a member of the pet's
household. Add `server/lib/households/erasure/` with
`releaseHouseholdsForDepartingUser(client, { userId, memberships })` and wire it into
`acceptAccountErasure` per H6. Add a household promotion notification type in
`notificationKind.js`, rendered by the existing generic notification UI. Leave the `DELETE /me`
409 confirmation untouched. Add the repair script (dry-run default, never run in this plan; the
owner runs it on UAT and production after release). Unit tests for transfer and erasure; extend
`server/test/db/accountErasure.integration.test.js` for the household cases.
Out of scope: anything under `server/routes/auth/`, schema changes, the two-sided transfer flow.

### Phase 6 — Household screens match the spec
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
    "e2e/playwright/tests/people-core.spec.ts household invite and removal preview test updated if needed and green",
    "EN and FR strings per vocabulary.md; flutter analyze and household widget tests green",
    "pre-push-changed green"
  ]
}
```
Scope: client for the phase 2–4 API changes (`DELETE …/pets/:petId`, `PATCH …/members/:userId`,
new preview fields, removed direct add). G4 pre-selection in `household_create_flow.dart`. G5 step
after `acceptHouseholdInvite` in the invite landing flow, calling the existing set-pets API with
the user's own pets. Tier and organiser editing on `household_detail_page.dart` (organisers only).
Removal dialog per H3. Owner exit from the pet's Who has access household row. Copy follows
`docs/domains/people/features/vocabulary.md` (for example "Remove Buddy from « Famille Morgan »",
never "Quitter le foyer"). Keep the existing `people-core.spec.ts` removal-preview journey green.
Split any file that would pass 500 lines.
Out of scope: Can log care gating in other pet screens, server changes, new E2E specs (phase 7).

### Phase 7 — End-to-end journeys and docs closeout
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
    "e2e/playwright/tests/households-lifecycle.spec.ts covers leave-with-pets, last-member close with a household vet in use, organiser tier change and owner pet removal, tagged @people @P1",
    "spec registered in e2e/scripts/spec-domains.mjs under people",
    "people-care-team.md status, lifecycle table and Still open section match shipped behaviour; decision-log rows for H1-H6",
    "people-domain-refactor.md gap table: fixed rows folded out, remaining follow-ups listed with debt issue links",
    "BDD coverage report and docs gates green",
    "pre-push-changed green"
  ]
}
```
Scope: a new Playwright spec using API helpers in `api.ts` for setup (create household, invite and
accept, add pets, attach a household vet as primary vet and as a care-item provider) and the People
page object for the journeys: a member leaves and their pet is no longer listed in the household;
the last member leaves, the household is gone, and the pet still shows its vet with the provider
set; an organiser changes a member to Can log care; a record owner removes their pet from a
household. Register the spec under the people domain. Close out the docs: canonical doc status and
lifecycle rows, decision log H1–H6, the change doc gap table, and debt issues for every item listed
as out of this plan.
Out of scope: product code changes; if a journey exposes a product bug, fix it in the phase that
owns the file through a remedial step rather than here.

## Proof on UAT
Pre-UAT E2E runs `households-lifecycle.spec.ts` and `people-core.spec.ts` green on the release
merge. Manually on https://uat.agathatrack.com with two demo accounts: create a household with a
pet, invite the second account and accept (the share-your-pets step appears), have the second
account share a pet and then leave; the household detail no longer lists that pet and the leaver
still sees it under their own pets. Give the first account's pet a household-directory vet as
primary vet and as provider on a care item, then leave as the last member: the household disappears
from Contacts → Households with no error, the pet still shows the vet (now from the owner's
personal directory) and the care item's provider is not empty.
