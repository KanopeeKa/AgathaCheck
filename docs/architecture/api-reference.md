---
title: API reference (docs index)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-15
tags: [api, reference]
---
# Agatha Track API — Endpoint Reference

> This top section is the authoritative, current endpoint list (generated from
> `server/routes/*.js`). The older notes further down predate several routes and
> may be incomplete or out of date; prefer this section.

**Mounting & prefixes.** Every router is mounted under **both** `/api/...` and
`/backend/api/...` on the same origin. The deployed Flutter web app calls
`/backend/api/...`; native/dev builds use `http://localhost:5000/api/...`.

**Auth.** Unless noted as *public*, endpoints require `Authorization: Bearer <JWT>`
(access token from signup/login). Organization routes enforce membership and role
checks (`super_admin`, `admin`, `foster`). See `docs/domains/fostering/changes/org-fostering-strategy.md`.

**OpenAPI (Pet Care subset).** Stable DTO contracts for auth session tokens and
critical pets/lifecycle endpoints live in
[`docs/architecture/openapi/pet-care-critical.json`](openapi/pet-care-critical.json).
Validate with `node scripts/validate_openapi.js`; Jest contract tests in
`server/test/openapi/petCareContract.test.js` assert live responses match the spec.

### Auth (`/api/auth`)
| Method | Path | Notes |
|---|---|---|
| POST | `/signup` | public; returns `{ user, access_token, refresh_token }` |
| POST | `/login` | public; optional body `timezone` (IANA) updates account on success |
| POST | `/refresh` | public; body `{ refresh_token }` |
| POST | `/logout` | no server-side revocation (stateless JWT) |
| GET | `/me` | current user (includes `pinned_organization_id`, nullable; `timezone` IANA string, default `UTC`) |
| PUT | `/me` | update profile (whitelisted fields incl. `pinned_organization_id`, `timezone`; must be active org member) |
| PATCH | `/me` | same as `PUT /me` (People phase 4 timezone) |
| POST | `/me/photo` | sets a photo URL |
| POST | `/change-password` | body `{ currentPassword, newPassword }` |
| POST | `/forgot-password` | public; the reset `code` is returned/logged **only outside production** |
| POST | `/reset-password` | public; body `{ email, code, new_password }` |
| DELETE | `/me` | body `{ password }`; deletes account |
| GET | `/me/export` | GDPR JSON export |

### Pets (`/api/pets`)
`GET /`, `GET /all`, `GET /:id` (UUID-validated), `POST /`, `PUT /:id`, `DELETE /:id`.

Pet responses include `homeTimezone` / `home_timezone` (IANA, default `UTC`). `POST /` defaults from `homeTimezone` body, else `X-Client-Timezone` header, else `UTC`. `PUT /:id` accepts `homeTimezone` to update.

`POST /:petId/tags` body `{ tag_id }` — assign current user's tag to an accessible pet.  
`DELETE /:petId/tags/:tagId` — unassign.

### Pet tags (`/api/pet-tags`)
Private per-user labels. `GET /` returns `[{ id, name, pet_ids, created_at, updated_at }]`.  
`POST /` body `{ name }`, `PATCH /:id` body `{ name }`, `DELETE /:id`.

### Vets (`/api/vets`)
`GET /`, `POST /`, `PUT /:id`, `DELETE /:id` — all scoped to the user.

### People (`/api/people`)

Personal directory contacts (phase 1). Storage: migrations `072_*`–`074_*`. Spec: [people-care-team.md](/docs/domains/people/features/people-care-team.md).

#### Contacts (`/api/people/contacts`)

| Method | Path | Authorization |
|---|---|---|
| GET | `/contacts` | authenticated — caller's personal directory; optional `?include_inactive=true` |
| POST | `/contacts` | authenticated — body `{ kind, name, phone?, email?, address?, website?, works_at_contact_id?, roles?, private_note? }`; `kind` ∈ {`person`,`organisation`}; `roles` ⊆ sitter, walker, vet, vet_nurse, groomer, trainer, behaviourist, boarding, emergency_contact, other |
| GET | `/contacts/:id` | authenticated — owner of directory only |
| PATCH | `/contacts/:id` | authenticated — partial update; `private_note` is per-caller only; **`kind` changes only when `kind` is sent** (rename alone does not re-infer kind) |
| DELETE | `/contacts/:id` | authenticated — blocked when `legacy_vet_id` is set (delete vet instead) or pet relationship exists (`409`) |

Response contact shape: `{ id, directory_id, kind, name, phone, email, address, website, works_at_contact_id, linked_user_id, inactive_at, legacy_vet_id, roles[], private_note, created_at, updated_at }`.

#### Pet contact relationships (`/api/pets/:petId/people-relationships`)

| Method | Path | Authorization |
|---|---|---|
| GET | `/api/pets/:petId/people-relationships` | `userCanManageProfile` (record owner or co-parent) |
| PUT | `/api/pets/:petId/people-relationships` | same — replaces all relationships; body `{ relationships: [{ contact_id, relationship_kind, is_primary?, active? }] }`; `relationship_kind` ∈ primary_vet, out_of_hours_vet, emergency_contact, care_provider, other; contact must be in caller's or pet owner's personal directory |

Vets API (`/api/vets`) dual-writes linked `people_contacts` rows via `legacy_vet_id` until clients migrate.

#### Planned — `people-domain-refactor-7f3b` (not implemented)

Additive changes, listed in [people-domain-refactor.md](/docs/domains/people/changes/people-domain-refactor.md) §3.6: `GET /api/people/roster`, enriched contact detail, `GET /api/people/contacts/:id/related`, `GET /api/people/contacts/by-legacy-vet/:vetId`, `GET /api/pets/:petId/people`, slot/add/remove relationship endpoints, usage-aware `DELETE` (`409 contact_in_use`), household removal preview and household email invites, `contact_id` on pet share invites, and a `code` field on People error bodies. `/api/vets` becomes a compat adapter over a one-way projection. Each entry moves to the tables above in the PR that ships it.

### Organizations (`/api/organizations`)
| Method | Path | Authorization |
|---|---|---|
| GET | `/` | member orgs only (joined query) |
| POST | `/` | any authenticated user (creator becomes `super_admin`) |
| GET | `/:id` | any active member (incl. foster — org contact) |
| PUT | `/:id` | `super_admin` only |
| DELETE | `/:id` | `super_admin` only |
| POST | `/:id/photo` | `super_admin` or `admin` |
| GET | `/:orgId/members` | `super_admin` or `admin` |
| POST | `/:id/invite` | `super_admin` or `admin`; body `{ email, role }`; role ∈ {`super_admin`,`admin`,`foster`}; admin cannot assign `super_admin` |
| PUT | `/:orgId/members/:userId/role` | `super_admin` or `admin`; same assignability rules as invite |
| DELETE | `/:orgId/members/:userId` | `super_admin` or `admin` |
| DELETE | `/:orgId/members/me` | self (leave org) |
| GET | `/:orgId/foster-parents` | `super_admin` or `admin`; member + external foster parents with active pet counts and `active_pets` |
| POST | `/:orgId/foster-parents` | `super_admin` or `admin`; body `{ display_name, email?, phone?, notes? }` — external contact without app account |
| PUT | `/:orgId/foster-parents/:id` | update external foster parent (same body fields) |
| DELETE | `/:orgId/foster-parents/:id` | remove external foster parent |
| POST | `/:orgId/pets` | `super_admin` or `admin`; create org pet; body `{ name, species, ... }` |
| POST | `/:orgId/pets/:petId/transfer` | `super_admin` or `admin`; transfer org pet to user by email; body `{ recipient_email, transfer_type?, notes? }` |
| GET | `/:orgId/pets/:petId/foster-history` | `super_admin` or `admin`; all foster placements for pet (PDF/admin) |
| GET | `/:orgId/placements` | `super_admin` or `admin`; all placements for org |
| GET | `/:orgId/pets/:petId/placement` | current active placement for pet (or `not_in_foster`) |
| POST | `/:orgId/pets/:petId/placements` | start foster (`pending`); body `{ foster_user_id, start_date?, notes? }` |
| POST | `/:orgId/pets/:petId/placements/direct-adopt` | skip foster period → `waiting_adoption_confirmation` (or `pending_adoption_conditions` if conditions set); body `{ foster_user_id, adoption_conditions?, notes? }` |
| POST | `/:orgId/placements/:id/start-adoption` | from `in_progress` → `waiting_adoption_confirmation` or `pending_adoption_conditions`; body `{ adoption_conditions? }` |
| POST | `/:orgId/placements/:id/complete-conditions` | `pending_adoption_conditions` → `waiting_adoption_confirmation` |
| POST | `/:orgId/placements/:id/cancel-adoption` | adoption step → `not_in_foster`; revokes foster `pet_access` |
| POST | `/:orgId/placements/:id/end` | end foster period → `not_in_foster`; revokes foster `pet_access` |
| GET | `/:orgId/pets`, `/:orgId/archived` | `super_admin` or `admin` (not foster) |
| GET | `/discover` | **public** — discoverable org tiles (`display_locality`, hero imagery) |
| GET | `/:id/public` | **public** (or member for opted-out orgs) — public-tier profile fields only |
| GET | `/:orgId/permissions/me` | active member — effective `view_*` and `manage_*` keys for viewer |
| GET | `/:orgId/people` | `view_admin_contacts` — admin contacts directory (redacted per viewer role) |
| GET | `/:orgId/people/:kind/:personId` | `view_admin_contacts` — member or external foster detail |
| PUT | `/:orgId/people/:kind/:personId/contact` | `super_admin` or `admin` — update contact card |
| GET | `/:orgId/connections` | `view_connections` — connected organisation tiles |
| GET | `/:orgId/pets/summary` | `view_org_pets` — profile preview list (12 pets, last-activity sort) |
| GET | `/:orgId/pets/:petId/redacted` | `view_org_pets` — associate-safe pet summary (Option B) |
| GET | `/:orgId/audit-events` | `manage_permissions` — permission audit log |
| GET | `/:orgId/permission-bundles` | `manage_permissions` — bundle preset catalog |
| POST | `/:orgId/members/:targetUserId/permissions/bundle` | `manage_permissions`; body `{ preset }` e.g. `pet_admin` |
| POST | `/:orgId/members/:targetUserId/permissions` | `manage_permissions` — grant individual override |
| DELETE | `/:orgId/members/:targetUserId/permissions/:permissionKey` | `manage_permissions` — revoke override |
| POST | `/:id/logo` | `super_admin` or `admin` — organisation logo upload |

### Foster placements (`/api/foster-placements`)
| Method | Path | Authorization |
|---|---|---|
| GET | `/pending` | authenticated foster parent; pending placement invites |
| GET | `/pending-adoptions` | foster parent; placements awaiting adoption confirmation |
| POST | `/:id/accept` | assigned foster parent; `pending` → `in_progress`, grants `pet_access` foster role |
| POST | `/:id/decline` | assigned foster parent; → `not_in_foster` |
| POST | `/:id/confirm-adoption` | assigned foster parent; `waiting_adoption_confirmation` → `adopted`; transfers ownership, writes `archived_pets` (`transfer_type: adoption`) |
| GET | `/invites/pending`, POST `/invites/:id/accept|decline` | invitee |

### Health entries (`/api/health-entries`)

CRUD: `GET /` (optional `?pet_id=`), `GET /export` (CSV), `GET /:id`, `POST /` (verifies pet ownership), `PUT /:id`, `DELETE /:id`, `GET|POST /:id/photos`, `DELETE /:entryId/photos/:photoId`. `POST /:id/photos` accepts one multipart `photo` document: JPG/JPEG, PNG, or PDF, up to 2 MB.

**Absence context (`GET /:id/absence-context`)** — Care Item evolution phase E

Returns upcoming active absences for the entry's pet with per-absence `affected`, derived `ui_state` (`nothing_due` \| `not_reviewed` \| `resolved` \| `needs_review`), optional `resolution`, `suggested_looked_after_by` (from `planned_absence_pets` carer), and enriched `planned_care` row when present. Requires manage-care access on the pet.

**Care Schedule Management (CSM)** — canonical behaviour: [care-schedule-management.md](../domains/pet_care/features/care-schedule-management.md). Calendar dates on the wire: `YYYY-MM-DD` ([calendar-dates.md](calendar-dates.md)).

#### Occurrence APIs (shipped — CSM-5–7)

| Method | Path | Notes |
|---|---|---|
| GET | `/:id/occurrences` | Query `status=open` (default) or `status=past`; optional `as_of` calendar day |
| POST | `/:id/occurrences/:occId/complete` | Body `{ completed_on?, notes?, skip_earlier_missed? }`; returns `{ occurrence, next_due_date }`; sets `completion_timing` |
| POST | `/:id/occurrences/:occId/skip` | Body `{ notes? }`; writes `care_schedule_events` ledger row |
| POST | `/:id/occurrences/skip-missed` | Body `{ as_of? }`; returns `{ skipped[], count }` |
| POST | `/:id/occurrences/:occId/undo` | Legacy per-occurrence reopen — superseded by `schedule/undo` (CSM-8) |

Weight monitoring rhythms: generic complete and `mark-taken` return `400` — use `POST /api/pets/:petId/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight` (see Care progression below).

#### Legacy / deprecated complete paths

| Method | Path | Notes |
|---|---|---|
| POST | `/:id/mark-taken` | **Deprecated** — completes oldest pending occurrence via `completeOccurrence`; **no `health_history` write**; when none is pending, first materialises the canonical open head (same as `occurrences/ensure-open`), else `400`; prefer occurrence complete |
| POST | `/:id/undo-complete` | **Legacy** — replaced by `POST /:id/schedule/undo` (CSM-8) |
| GET | `/:id/history` | Read-only legacy `health_history` rows (no new writes after CSM-7) |

**Removed (CSM-7):** `POST /:id/skip`, `POST /:id/unskip` — use occurrence skip APIs.

#### Schedule change APIs (shipped — CSM-8–13)

| Method | Path | Notes |
|---|---|---|
| POST | `/:id/pause` | Body `{ paused_from?, reason_note? }`; `status = paused`, `paused_since` cache, ledger `paused` event |
| POST | `/:id/resume` | Body `{ reason_note? }`; resume with **no catch-up** (D-CSM-005) |
| POST | `/:id/occurrences/:occId/reschedule` | Body `{ scheduled_date, reason_code?, reason_note? }`; validates move (400 on past/no-op/beyond next hop/before last closed); returns `{ occurrence, warnings[], next_due_date }`; syncs `next_due_date` cache (D-ACP-009) |
| POST | `/:id/occurrences/ensure-open` | **D-CSM-018** — Body optional `{ scheduled_date?, reason_code? }`; idempotently materialises pending row(s) for the **canonical open head** (or validates `scheduled_date` is that head); returns `{ occurrences[], created, next_due_date }`; 400 if a non-head date is requested while an earlier pending day exists |
| POST | `/:id/adjust-cadence` | Body `{ effective_from, frequency?, frequency_interval?, recurrence_anchor?, reason_note? }`; series-forward only |
| POST | `/:id/schedule/undo` | Timestamp-aware `undoLastAction` (CSM-8) |
| GET | `/:id/schedule-explain` | Read-only `explainGap` facts for CIM (CSM-13) |

**Create defaults (CSM-2):** when `recurrence_anchor` is omitted, server applies per-family default (`vaccination` / `parasite_prevention` → `from_due_date`; others → `from_completion`) — D-CSM-001.

**Classification (care-classification-taxonomy Phase B):** create/update accept `care_family` (required on create), optional `care_setting`, `care_planning`, `care_importance`. Responses include those fields plus `importance_overridden`, read-only `schedule_flexibility` `{ flexibility, max_shift_days }` (D-ACP-006). Legacy `type` is **server-derived** — clients must omit `type` on write (400 if sent). `unplanned` entries require `completed_on`, forbid `next_due_date`, use `frequency=once`, and set `remind_days_before=0`.

### Health issues (`/api/health-issues`)
`GET /` (optional `?pet_id=`), `GET /:id`, `POST /` (verifies pet ownership),
`PUT /:id`, `DELETE /:id`, `GET /:issueId/events`,
`DELETE /:issueId/events/:entryId` (events verify issue ownership).

### Weight entries (`/api/weight-entries`)
`GET /` (optional `?pet_id=`), `GET /latest?pet_id=`, `POST /` (verifies pet
ownership), `PUT /:id`, `DELETE /:id`.

Responses include optional `health_occurrence_id` when the observation completed a
care rhythm occurrence (CP-2). Deleting a linked weight entry re-opens the occurrence
to `pending` and refreshes the rhythm `next_due_date`.

D0 provenance: responses include `measurement_source` (`guardian`|`clinic`|`device`|`imported`).
POST/PUT accept optional `measurement_source`. Pet weight reference/context fields live on `PUT /api/pets/:id`
(`weight_reference_value`, `weight_reference_authority`, `weight_management_context`) — see [d0-provenance-contract.md](../domains/pet_care/changes/d0-provenance-contract.md).

### Notifications (`/api/notifications`)
`GET /`, `GET /unread-count`, `PUT|POST /:id/read`, `PUT|POST /read-all`,
`GET|PUT /preferences`, `POST /check-due`.

### Sharing (`/api/share`)
| Method | Path | Notes |
|---|---|---|
| POST | `/` | Owner or active foster parent creates a share link; body `{ pet_id, access_role? }` (`carer` default, or `co_parent`); returns `{ share_code, link_id }` |
| GET | `/:code` | Public preview of shared pet; includes `link_status` (`pending`, `active`, `revoked`) |
| POST | `/:code/accept` | Auth required; single-use — creates `pet_access` with link `access_role`, marks link `active` |
| DELETE | `/links/:linkId` | Owner deletes any share link; foster may delete only links they created |
| GET | `/hidden` | Hidden shared pets |
| PUT | `/:petId/hide` | Hide or unhide a shared pet (`{ hidden: true\|false }`) |
| POST | `/invites` | Email invite; body `{ invitee_email, pet_ids, role }` — up to 20 pets; returns `{ invite_id, code, included_pet_ids, excluded[], delivery }` |
| GET | `/invites/code/:code` | Public invite preview (no inviter email) |
| POST | `/invites/code/:code/accept` | Auth required; grants access per pet on invite |
| POST | `/invites/:id/decline` | Auth required; notifies inviter |
| DELETE | `/invites/:id` | Cancel pending invite |
| GET | `/access?pet_ids=` | Aggregate `{ pets: [{ pet_id, access[], pending_invites[] }] }` — omits inaccessible pets |

Pet access management on `/api/pets/:id/...` (owner unless noted):
- `GET /:id/share-links` — list share links with status and claimed user (owner: all links; foster: own links only)
- `GET /:id/invites` — pending email invites for the pet
- `GET /:id/access` — who has access: `{ access: [...], household_access: [...], access_events: [...] }` — direct `pet_access` rows plus household members when the pet is in a household; `access_events` capped at 100 per pet (owner or co-parent)
- `PUT /:id/access/:userId/role` — promote/demote between `carer` and `co_parent` (owner or co-parent)
- `DELETE /:id/access/:userId` — remove access and notify the user (owner or co-parent)
- `DELETE /:id/follow` — carer/co-parent stops following (self-remove access)
- `POST /:id/transfer` — transfer ownership to another user (owner only); body `{ recipient_email, confirmation_name }` (pet name must match, case-insensitive); former owner receives `carer` access automatically; writes `archived_pets` audit row (`transfer_type: user_to_user`)

Shared pets appear in `GET /api/pets/all` with `is_shared: true` and `access_role` (`carer` or `co_parent`). Fostered pets use `is_foster: true` (and `is_shared: false`). Shared and org-visible pets include `pet_parent_name` (display name of the pet parent); `primary_holder_name` is a deprecated alias.

Share links are **single-use**: once accepted, the same link cannot be used by another user (`410`).

### Households (`/api/households`) — People phase 3

| Method | Path | Notes |
|---|---|---|
| POST | `/` | Create household; body `{ name, pet_ids? }`; creator is organiser + `full_access` |
| GET | `/` | List households for caller `{ households: [...] }` |
| GET | `/:id` | Detail with `members` and `pets` (members only) |
| PATCH | `/:id` | Rename (organisers) |
| POST | `/:id/members` | Add member by `user_id`; body `{ access_tier?, is_organiser? }` |
| DELETE | `/:id/members/:userId` | Leave or remove; body optional `{ remove_all_access_to_my_pets: true }` |
| PUT | `/:id/pets` | Body `{ pet_ids: [] }` — record owner adds/removes their pets |

Household `full_access` grants `userCanManageProfile` + `userCanManageCare` (not share/transfer/delete). `can_log_care` grants care management only. Effective access is the highest of household, direct share, and **absence guest grants** (time-bound, evaluated in the absence's `timezone`).

`DELETE /api/auth/me` returns `409` with `code: household_pets_require_confirmation` when the user owns pets in a household with other members, unless `confirm_household_pets: true` is sent with the password.

### Care recommendations (`/api/pets/:id/care-recommendations`) — Phase C crisp rules

Server-authoritative Agatha suggestions (weight, dental, wellness rhythm families). Suggestions do not affect Care Status until accepted.

| Method | Path | Notes |
|---|---|---|
| GET | `/care-recommendations` | Sync pending recommendations for pet (`HEALTH_VIEW`) |
| POST | `/care-recommendations/:recommendationId/respond` | Body `{ action: accept\|adjust\|dismiss\|not_relevant, adjust?: { frequency, frequency_interval, care_setting?, care_importance? } }`; accept/adjust creates recurring `health_entry` with classification derived from `care_family` + taxonomy defaults (optional `care_setting` / `care_importance` in adjust); `type` is server-derived (`HEALTH_EDIT`) |

### Care progression (`/api/pets/:id/care-progression`) — CP-1+

| Method | Path | Notes |
|---|---|---|
| GET | `/care-progression` | Establishment + milestones read model (`HEALTH_VIEW`) |
| POST | `/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight` | CP-2: transactional weight observation + occurrence complete for `weight_monitoring` rhythms (`WEIGHT_EDIT`); body `{ weight, unit?, date?, measurement_source?, notes? }`; idempotent retry with same payload returns `200` |

Weight monitoring rhythms cannot use generic occurrence complete or mark-taken while pending — use `complete-weight`.

### Care-period projection (`/api/pets/:petId/care-period-projection`) — CC-2

| Method | Path | Notes |
|---|---|---|
| GET | `/care-period-projection?starts_on&ends_on` | Server-authoritative care scheduled in an inclusive calendar window (`HEALTH_VIEW` via `userCanManagePet`); max 12-month horizon; returns `projection_status` (`complete` \| `partially_indeterminate`), the unchanged raw per-occurrence `items[]` (per-item `source`: `materialised` \| `projected`), and `planned_care_items[]` — one server-sorted row per `health_entry_id` (D-AWD-002; **breaking change from the pre-AWD-2 shape**, which exposed `routine_items`/`dated_items`/`uncertainties` as three separate arrays — those are removed, not versioned alongside). Each `planned_care_items[]` row carries `kind` (`recurring_calendar` \| `recurring_chain` \| `single_once` \| `indeterminate_pending`, derived from `recurrence_anchor` + whether the entry has a materialised/projected occurrence in the window — never a separate `anchor_kind` field), `health_entry_id`, `name`, `type`, `care_family`, `frequency`, `frequency_interval`, distinct sorted `times_of_day[]`, and `next_due_date` (earliest pending date; non-null only for `kind: recurring_calendar` with `times_of_day.length <= 1`). `frequency: 'once'` entries are never grouped — each occurrence is its own row. Sort order: `kind` bucket (`recurring_calendar` → `recurring_chain` → `single_once` → `indeterminate_pending`), then `name` (locale-aware). Materialised `health_occurrences` win over simulated slots; `from_completion` rhythms do not guess dates beyond an unresolved hop. |

### Care-period coverage (`/api/pets/:petId/care-period-coverage`) — CC-3

| Method | Path | Notes |
|---|---|---|
| GET | `/care-period-coverage?starts_on&ends_on` | Same projection payload as CC-2 (`projection_status`, raw `items[]`, **`planned_care_items[]`** — see CC-2 for the unified-array wire shape and breaking change from `routine_items`/`dated_items`/`uncertainties`) plus `coverage` block (`policy_version`, `coverage_state`, `reason_codes`, `reassurance_available`). States: `nothing_scheduled` (complete + zero items only), `all_completed`, `no_unresolved_items`, `has_items_to_review`, `indeterminate` (when projection is partially indeterminate — no global reassurance). |

**`planned_care_items[]` row shape (D-AWD-002, finalised AWD-5):** each element includes at minimum `kind`, `health_entry_id`, `name`, `type`, `care_family`, `frequency`, `frequency_interval`, `times_of_day[]`, `next_due_date`, `certainty`. Grouped rows (`recurring_calendar`, `recurring_chain`, `indeterminate_pending`) also carry `occurrence_count`, `status_counts`, `first_scheduled_date`, `last_scheduled_date`; `indeterminate_pending` adds `reason`. `single_once` rows add `occurrence_id`, `scheduled_date`, `status` per occurrence. `next_due_date` is non-null only for `kind: recurring_calendar` when `times_of_day.length <= 1`. Sort order is server-side: `kind` bucket (`recurring_calendar` → `recurring_chain` → `single_once` → `indeterminate_pending`), then `name`. Pre-AWD-2 clients must migrate — the three legacy arrays are absent from responses.

**ACP additive fields on `planned_care_items[]` (D-ACP-001–002, nullable on older clients):**

| Field | Shape | Notes |
|-------|--------|-------|
| `open_occurrence` | `{ occurrence_id, scheduled_date, scheduled_time?, open_status }` | `open_status`: `overdue` \| `due_before_absence` \| `in_window` (D-ACP-004) |
| `in_window` | `{ first_date, last_date, count, date_basis }` | `date_basis`: `scheduled` \| `planned` \| `estimated` (D-ACP-002) |
| `is_paused` | `boolean` | When true, UI shows paused copy only (R-A9) |
| `schedule_flexibility` | `string` | `fixed` \| `earlier_only` \| `flexible` \| `carer_task` (D-ACP-006); drives away-plan **See options** |
| `max_shift_days` | `number` | Planner/reschedule tolerance when `schedule_flexibility` is set |

**D-ACP-011 away-plan list filter:** `planned_care_items[]` on `/care-period-coverage` (and PDF handover using the same payload) includes only rows with `in_window` set, or — when `today >= starts_on` — still-open `open_occurrence` with `scheduled_date < starts_on`. Pre-departure overdue is not listed; use `pre_absence_overdue_attention: { show, overdue_count }` per pet response instead. `projection_status` reflects **visible** rows only (no indeterminate caveat when hidden rows were the sole cause).

Raw `items[]` entries may include `window_relation: before_window` on materialised open occurrences surfaced before the window (D-ACP-001).

**Reschedule response (D-ACP-009):** `{ occurrence, warnings[], next_due_date }`. Each warning is a code-specific object (no shared `message`/`params` envelope):

| `code` | Fields |
|--------|--------|
| `earlier_only_later_move` | `{ code }` |
| `outside_flexibility` | `{ code, flexibility, max_shift_days, care_source? }` |
| `interval_changed` | `{ code, previous_gap_days, usual_gap_days }` |

`reason_code: away_planner` is accepted on reschedule when applying a Care Planner suggestion.

### Planned absences (`/api/planned-absences`) — CC-1

Declarer-scoped absence context (not visible to collaborators in V1): `GET /`, `POST /`, `GET /:id`, `PATCH /:id`, `POST /:id/cancel`.

**Timezone (D24)** — `users.timezone` is set at signup/login (optional body) or via `PATCH /api/auth/me`. Each absence stores `timezone` copied from the declarer's account at `POST` create (later account timezone changes do not alter existing absences). Access windows for guest grants use whole calendar days `starts_on`…`ends_on` inclusive in that absence timezone.

**Guest access (People phase 4)** — time-bound `can_log_care` via absence guest grants (evaluated at read time alongside household + direct share):

| Method | Path | Notes |
|---|---|---|
| POST | `/:id/carer-invites` | Body `{ contact_id, pet_ids? }`; record owner or household `full_access` on each pet; contact must be carer on absence pets |
| GET | `/carer-invites/code/:code` | Public preview for invite landing |
| POST | `/carer-invites/code/:code/accept` | Authenticated invitee; creates grants + links contact |
| POST | `/carer-invites/:inviteId/accept` | Same accept by id |
| DELETE | `/carer-invites/:inviteId` | Revoke pending invite |
| DELETE | `/guest-grants/:grantId` | Early revoke active grant |

`PATCH /:id` with active guest grants requires `confirm_guest_access_widen: true` when extending `ends_on` or adding pets (`409`, `code: guest_access_widen_required`). Cancelling an absence revokes active guest grants immediately.

**List (`GET /`)**

| Query | Values | Default |
|---|---|---|
| `scope` | `upcoming`, `past`, `all` | `upcoming` |

- `upcoming` — non-cancelled where `ends_on >= today`, ordered by `starts_on` ascending (wizard invalidate shape: top-level JSON array).
- `past` — non-cancelled where `ends_on < today`, ordered by `starts_on` descending.
- `all` — all non-cancelled absences; upcoming first (`starts_on` asc), then past (`starts_on` desc).

Each list item includes `overlap_warnings` **recomputed on read** (not persisted): non-blocking conflicts with other active absences (`status != cancelled` and `ends_on >= today`) for the same pet. Same shape as `POST`/`PATCH` overlap entries.

`POST` and `PATCH` also return non-blocking `overlap_warnings` when active absences overlap for the same pet.

**Carers (AW-4)** — each absence includes `pet_ids` and `pet_carers` (per-pet facts on `planned_absence_pets`):

| Field | Notes |
|---|---|
| `pet_carers[].carer_kind` | `shared_user`, `note_only`, or `null` (unset) — derived when writing via `contact_id` |
| `pet_carers[].carer_user_id` | Required on write for `shared_user`; must be a collaborator on that pet |
| `pet_carers[].carer_name` / `carer_note` | Snapshot / private note for `note_only`; enriched for `shared_user` reads |
| `pet_carers[].carer_state` | `unset` \| `set` \| `unavailable` (D18) |
| `pet_carers[].contact_id` | Contact in declarer's directory; primary write key on `PATCH` (People phase 2) |
| `pet_carers[].carer_removed` | Read-only alias: `true` when `carer_state` is `unavailable` |
| `pet_carers[].pet_note` | Any carer — free text about caring for this pet (feeding, meds, quirks); independent of carer identity (migration `071`, D-AWAY-014a) |

`PATCH /:id` accepts optional `pet_carers: [{ pet_id, contact_id?, carer_kind?, ..., pet_note }]`. Assigning via `contact_id` resolves to `shared_user` or `note_only` storage. Legacy `carer_kind` writes still accepted and upsert a matching contact. Carer writes bump `planned_absences.updated_at`. `shared_user` / linked contacts return `403` when the user is not a collaborator on that pet. Each `pet_carers` entry writes carer columns only when `contact_id` or `carer_kind` is a present key on that entry, and `pet_note` only when `pet_note` is a present key — an entry with only `pet_note` never touches the carer, and an entry with only carer keys never touches `pet_note`. Send `pet_note: null` to clear it explicitly.

**Readiness (`GET /:id/readiness`)** — AW-8

Server-authoritative two-fact readiness for hub, plan page, and dashboard tile (D-AWAY-002). Declarer-scoped; `404` when absence is not owned by caller.

```json
{
  "carer_coverage": {
    "state": "none_have_carers | some_have_carers | all_have_carers",
    "pets_with_carer": 0,
    "pets_total": 1,
    "unavailable_pet_ids": [],
    "copy_key": "awayPlanningCarerCoverageNoneHaveCarers"
  },
  "care_coverage": {
    "coverage_state": "nothing_scheduled | all_completed | …",
    "reason_codes": [],
    "reassurance_available": false,
    "copy_key": "careContextCoverageNothingScheduled"
  },
  "tile_copy": {
    "source": "carer_coverage | care_coverage",
    "copy_key": "awayPlanningTileCarerNone",
    "copy_params": {}
  }
}
```

Tile copy uses fixed actionability priority: carer gap first, else coverage sentence. See [away-planning-carer-model.md](/docs/domains/pet_care/features/away-planning-carer-model.md).

**Absence resolutions (`GET|PATCH /:id/resolutions`)** — Care Item evolution phase E (D-CIE-012/013)

Declarer-scoped; same auth as `GET /:id`. Stores per–care-item decisions for one absence (`health_entry_absence_resolutions`).

- **GET** — `{ resolutions: [{ id, health_entry_id, planned_absence_id, decision, looked_after_by, absence_note, dates_decided_for }] }`
- **PATCH** — upsert one or more rows: `{ resolutions: [{ health_entry_id, decision, looked_after_by?, absence_note? }] }` or a single object with `health_entry_id`. `decision` is `keep_date` \| `move_before` \| `move_after` \| `nothing_needed`. `looked_after_by` mirrors `pet_carers` carer shape (`shared_user` \| `note_only`). `dates_decided_for` is set server-side from the current in-window pending dates when saved.

Resolved affected items are excluded from away-plan `care_coverage.has_items_to_review` (readiness uses absence id when deriving coverage).

**Handover PDF (People phase 2)** — includes primary vet, out-of-hours vet, and emergency contacts from `GET /api/pets/:id/people-relationships` for pets on the plan.

**Planned (People phase 2)** — per-pet carer fact and coverage extension ([amends-away-planning.md](/docs/domains/people/changes/amends-away-planning.md)) — **shipped** on branch `cursor/people-p2-absence-a58d`:

| Field | Notes |
|---|---|
| `pet_carers[].carer_state` | `unset` \| `set` \| `unavailable` (replaces implicit unset/set; `unavailable` = carer no longer available, D18) |
| `pet_carers[].contact_id` | Contact in declarer's directory; unlinked contact behaves as `note_only` until phase 4 (D28) |
| `carer_coverage.unavailable_pet_ids` | Pet ids with `carer_state: unavailable`; counted as uncovered for `all_have_carers` |

**Care Planner (`GET /:id/care-plan`)** — ACP-6 (D-ACP-008)

Declarer-scoped; same auth as `GET /:id/readiness`. Stateless — computed on each read; not persisted. Does **not** affect readiness or care-period coverage.

```json
{
  "absence_id": "…",
  "today": "YYYY-MM-DD",
  "starts_on": "YYYY-MM-DD",
  "ends_on": "YYYY-MM-DD",
  "pets": [{
    "pet_id": "…",
    "suggestions": [{
      "health_entry_id": "…",
      "occurrence_id": "…",
      "from_date": "YYYY-MM-DD",
      "to_date": "YYYY-MM-DD",
      "direction": "earlier | later",
      "in_window_before": 1,
      "in_window_after": 0,
      "flexibility": "flexible | earlier_only | …",
      "rationale_code": "move_before_departure | move_after_return | overdue_do_before_departure"
    }],
    "carer_tasks": {
      "count": 2,
      "by_entry": [{ "health_entry_id": "…", "count": 1, "reason": "fixed | carer_task | no_valid_move" }]
    }
  }]
}
```

Accepting a suggestion: `POST /api/health-entries/:entryId/occurrences/:occId/reschedule` with `{ scheduled_date: <to_date>, reason_code: "away_planner" }`.

### Carer candidates (`GET /api/pets/:id/carer-candidates`) — AW-4

Scoped to `userCanManagePet` (same as absence declaration). Returns minimal collaborator list for assigning `shared_user` carers:

```json
[{ "user_id": "…", "display_name": "Sarah M." }]
```

No email, photo, or bio. Does not change `GET /api/pets/:id/access` (`userOwnsPet` guard unchanged).

### Review relevance (Phase D — internal only)

| Method | Path | Notes |
|---|---|---|
| GET | `/pets/:id/review-relevance/evaluate` | Internal evaluation harness output; `internal_only: true`; not a guardian safeguard (`HEALTH_VIEW`) |

### Pet family events (`/api/pets/:id/family-events`) — Node backend

Org placement/foster periods (legacy shape; see `docs/domains/fostering/changes/org-fostering-strategy.md` for
the planned `foster_placements` model):

| Method | Path | Notes |
|---|---|---|
| GET | `/family-events` | List events for pet (org pet required for writes) |
| POST | `/family-events` | Create; body includes `from_date`, optional `to_date`, `assigned_to_user_id` |
| PUT | `/family-events/:eventId` | Update |
| DELETE | `/family-events/:eventId` | Delete |
| POST | `/family-events/:eventId/mark-complete` | Set completed date |
| GET | `/family-events/:eventId/history` | History rows |

Calendar dates on the wire: `YYYY-MM-DD` (`docs/architecture/calendar-dates.md`).

### Not implemented (return `501 Not Implemented`)

These endpoints are placeholders. They return `501` with
`{ "error": "Not implemented" }`. **Do not call from primary UI flows.**

| Endpoint | Notes | Planned |
|---|---|---|
| `POST /api/organizations/join/:code` | Join-by-code retired; use email invite + accept | — |

Lifecycle stubs (acknowledge without full side effects):
`DELETE /api/pets/:id/data`, `POST /api/pets/:id/passed-away` (use `DELETE`/`PUT /api/pets/:id` for real changes).

**Roadmap:** `docs/domains/fostering/changes/org-fostering-strategy.md`

---

### Health Entries Endpoints

- **GET** `/backend/api/health-entries`
  - **Response:** `[]`
- **POST** `/backend/api/health-entries`
  - **Request Body:** `{ "pet_id": "pet-1", "type": "checkup", "date": "2026-03-26" }`
  - **Response:** `{ "created": true, "entry": { ... } }`

### Health Issues Endpoints

- **GET** `/backend/api/health-issues`
  - **Response:** `[]`
- **POST** `/backend/api/health-issues`
  - **Request Body:** `{ "pet_id": "pet-1", "description": "Fever", "date": "2026-03-26" }`
  - **Response:** `{ "created": true, "issue": { ... } }`

### Test Coverage

- See `server/test/healthEntries.test.js` for health-entries endpoint tests.
- See `server/test/healthIssues.test.js` for health-issues endpoint tests.
### Weight Entries Endpoints

- **POST** `/backend/api/weight-entries`
  - **Request Body:** `{ "pet_id": "pet-1", "weight": 4.5, "date": "2026-03-26" }`
  - **Response:** `{ "created": true, "entry": { ... } }`

- **GET** `/backend/api/weight-entries/latest`
  - **Response:** `{ "pet_id": "mock-pet", "weight": 5.2, "date": "2026-03-26" }`

### Auth Refresh Endpoint

- **POST** `/backend/api/auth/refresh`
  - **Request Body:** `{ "refresh_token": "<jwt-refresh-token>" }`
  - **Response:** `{ "access_token": "<jwt-access-token>" }`
  - **Error:** 400 if missing token, 401 if invalid/expired

### Test Coverage

- See `server/test/weightEntries.test.js` for weight-entries endpoint tests.
- See `server/test/auth_refresh.test.js` for auth refresh endpoint tests.

# API Documentation


## Project Structure (Backend)

The backend API is now modularized for maintainability:

- All `/api/pets` endpoints are implemented in `server/routes/pets.js`.
- All `/api/auth` endpoints are implemented in `server/routes/auth.js`.
- The main app setup and health/basic routes are in `server/bin/server.js`.

All endpoints are mounted under `/backend/api/`.

### Signup

**Endpoint:**
```
POST /backend/api/auth/signup
```

**JWT Token Generation:**
On successful signup, the backend generates and returns both an `access_token` and a `refresh_token` as JWTs (JSON Web Tokens). These tokens are signed using the backend's secret key and include the user's ID and email in their payload. The `access_token` is intended for authenticating API requests, while the `refresh_token` can be used to obtain new access tokens when the original expires.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "yourPassword",
  "first_name": "First",         // optional
  "last_name": "Last",           // optional
  "category": "pet_carer",    // optional, default: pet_carer
  "bio": "About me",             // optional
  "photo_url": "http://...",     // optional
  "locale": "en"                 // optional, default: en
}
```

**Success Response:**
- **Status:** 201 Created
- **Body:**
```json
{
  "user": {
    "id": "uuid-string",
    "email": "user@example.com",
    "first_name": "First",
    "last_name": "Last",
    "category": "pet_carer",
    "bio": "About me",
    "photo_url": "http://...",
    "locale": "en"
  },
  "access_token": "<jwt-access-token>",
  "refresh_token": "<jwt-refresh-token>"
}
```

**Error Responses:**
- **Missing email or password:**
  - Status: 400
  - Body: `{ "error": "Email and password are required." }`
- **Duplicate email:**
  - Status: 400
  - Body: `{ "error": "Email already exists." }`
- **Other server/database errors:**
  - Status: 500
  - Body: `{ "error": "Signup failed", "details": "..." }`

---

## Pet Endpoints: UUID Validation

### Single Pet Endpoints

Endpoints like `/api/pets/{id}` require `{id}` to be a valid UUID (e.g., `123e4567-e89b-12d3-a456-426614174000`).

- If `{id}` is not a valid UUID, the API returns:
  - **Status:** 400 Bad Request
  - **Body:** `{ "error": "Invalid pet ID" }`

This prevents errors when clients accidentally use reserved words (like `all`) or invalid IDs.

### All Pets Endpoint

- To fetch all pets, use `/api/pets/all` (or `/api/pets` for personal pets).
- Do **not** use `/api/pets/all` as a single-pet endpoint.


### Test Coverage

- Unit tests in `server/test/pets_list.test.js` and related files ensure UUID validation logic is enforced.
- CI will fail if invalid UUIDs are accepted for single-pet endpoints.

---

### Login

**Endpoint:**
```
POST /backend/api/auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "yourPassword"
}
```

**Success Response:**
- **Status:** 200 OK
- **Body:**
```json
{
  "user": {
    "id": "uuid-string",
    "email": "user@example.com",
    "first_name": "First",
    "last_name": "Last",
    "category": "pet_carer",
    "bio": "About me",
    "photo_url": "http://...",
    "locale": "en"
  },
  "access_token": "<jwt-access-token>",
  "refresh_token": "<jwt-refresh-token>"
}
```

**Error Responses:**
- **Missing email or password:**
  - Status: 400
  - Body: `{ "error": "Email and password are required." }`
- **Invalid credentials:**
  - Status: 401
  - Body: `{ "error": "Invalid email or password." }`
- **Other server/database errors:**
  - Status: 500
  - Body: `{ "error": "Login failed", "details": "..." }`


### Test Coverage

- Unit tests in `server/test/auth_login.test.js` ensure login returns the correct structure and errors for invalid input.

---

## Extended Pet Endpoints

### Transfer Pet to Organization

- **POST** `/api/pets/{id}/transfer-to-org`
- Transfers a personal pet to an organization where the caller is `super_admin` or `admin`.
- **Request body:** `{ "organization_id", "transfer_type"?, "notes"? }`
- **Response:** `{ "transferred": true, "pet_id", "organization_id", "transfer_type" }`
- **Errors:** 400 if pet already belongs to an org; 403 if caller is not an org admin; 404 if pet not found.

### Family Events (per-pet) — STUB

> **Status:** the per-pet family-events routes below are currently stubs that return empty arrays / no-op responses. Real family events live on **organization pets** (see the organization routes) and are implemented there. The `family_events` table exists in the canonical schema but is not written to by these endpoints.

- **GET** `/api/pets/{id}/family-events` — Returns `[]`.
- **POST** `/api/pets/{id}/family-events` — No-op stub.
- **PUT** `/api/pets/{id}/family-events/{eventId}` — No-op stub.
- **DELETE** `/api/pets/{id}/family-events/{eventId}` — No-op stub.

### Pet Access

Implemented in `server/routes/sharing/petAccessRoutes.js` (mounted on `/api/pets`).

- **GET** `/api/pets/{id}/access` — List collaborators (`carer`, `co_parent`).
- **PUT** `/api/pets/{id}/access/{userId}/role` — Body `{ role: "carer" | "co_parent" }`; returns `{ user_id, role }`.
- **DELETE** `/api/pets/{id}/access/{userId}` — Revoke access; returns `{ message: "Access removed" }`.
- **DELETE** `/api/pets/{id}/follow` — Self-revoke carer/co-parent access.

### Delete Pet Data

- **DELETE** `/api/pets/{id}/data` — Deletes pet-related rows (health, weight, timeline, shares, etc.) and purges health/pet upload files. Pet profile row remains until `DELETE /api/pets/{id}`.

### Mark Pet as Passed Away

- **POST** `/api/pets/{id}/passed-away` — Notification-only: creates in-app notifications for collaborators. Response: `{ notification_sent, pet_id, notified_count, delivery_status }` where `notification_sent` is true only when at least one notification row was written (`delivery_status`: `delivered` | `no_recipients`). Does **not** persist `passedAway`; use `PUT /api/pets/{id}` with `passed_away: true` for that.



### Notifications Endpoints

The notification system is fully implemented and persists to the `notifications` table (which keeps both `is_read` and a legacy `read` column for backward compatibility — UPDATEs touch both).

- **GET** `/backend/api/notifications` — Returns the authenticated user's notifications.
- **GET** `/backend/api/notifications/preferences` — Returns the user's notification preferences.
- **POST** `/backend/api/notifications/check-due` — Scans health entries for due/overdue items and creates notifications for the authenticated user.
- **PATCH** `/backend/api/notifications/{id}/read` — Marks a single notification as read.
- **POST** `/backend/api/notifications/mark-all-read` — Marks every unread notification for the user as read.

In-app notifications also support per-pet mute via the pet routes.

### Test Coverage

- See `server/test/pets.test.js` for pet endpoint tests (CRUD, auth guards, cross-user ownership, org-membership checks, and the extended stub endpoints) with mocked DB logic.
- See `server/test/notifications.test.js` for notifications endpoint tests.
