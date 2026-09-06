---
title: API reference (docs index)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
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
| POST | `/login` | public |
| POST | `/refresh` | public; body `{ refresh_token }` |
| POST | `/logout` | no server-side revocation (stateless JWT) |
| GET | `/me` | current user (includes `pinned_organization_id`, nullable) |
| PUT | `/me` | update profile (whitelisted fields incl. `pinned_organization_id`; must be active org member) |
| POST | `/me/photo` | sets a photo URL |
| POST | `/change-password` | body `{ currentPassword, newPassword }` |
| POST | `/forgot-password` | public; the reset `code` is returned/logged **only outside production** |
| POST | `/reset-password` | public; body `{ email, code, new_password }` |
| DELETE | `/me` | body `{ password }`; deletes account |
| GET | `/me/export` | GDPR JSON export |

### Pets (`/api/pets`)
`GET /`, `GET /all`, `GET /:id` (UUID-validated), `POST /`, `PUT /:id`, `DELETE /:id`.

### Vets (`/api/vets`)
`GET /`, `POST /`, `PUT /:id`, `DELETE /:id` — all scoped to the user.

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
`GET /` (optional `?pet_id=`), `GET /export` (CSV), `GET /:id`, `POST /` (verifies
pet ownership), `PUT /:id`, `DELETE /:id`, `POST /:id/mark-taken`,
`POST /:id/undo-complete`, `GET /:id/history`, `GET|POST /:id/photos`,
`DELETE /:entryId/photos/:photoId`. Nested history/photos verify entry ownership.
`POST /:id/photos` accepts one multipart `photo` document: JPG/JPEG, PNG, or PDF,
up to 2 MB.

### Health issues (`/api/health-issues`)
`GET /` (optional `?pet_id=`), `GET /:id`, `POST /` (verifies pet ownership),
`PUT /:id`, `DELETE /:id`, `GET /:issueId/events`,
`DELETE /:issueId/events/:entryId` (events verify issue ownership).

### Weight entries (`/api/weight-entries`)
`GET /` (optional `?pet_id=`), `GET /latest?pet_id=`, `POST /` (verifies pet
ownership), `PUT /:id`, `DELETE /:id`.

### Notifications (`/api/notifications`)
`GET /`, `GET /unread-count`, `PUT|POST /:id/read`, `PUT|POST /read-all`,
`GET|PUT /preferences`, `POST /check-due`.

### Sharing (`/api/share`)
| Method | Path | Notes |
|---|---|---|
| POST | `/` | Owner or active foster parent creates a share link; body `{ pet_id }`; returns `{ share_code, link_id }` |
| GET | `/:code` | Public preview of shared pet; includes `link_status` (`pending`, `active`, `revoked`) |
| POST | `/:code/accept` | Auth required; single-use — creates `shared` access immediately, marks link `active` |
| DELETE | `/links/:linkId` | Owner deletes any share link; foster may delete only links they created |
| GET | `/pending` | Deprecated — always returns `[]` (one-step flow) |
| POST | `/pending/:petId/accept` | Deprecated — returns `410` |
| POST | `/pending/:petId/decline` | Deprecated — returns `410` |
| GET | `/hidden` | Hidden shared pets |
| PUT | `/:petId/hide` | Hide or unhide a shared pet (`{ hidden: true\|false }`) |

Pet access management on `/api/pets/:id/...` (owner unless noted):
- `GET /:id/share-links` — list share links with status and claimed user (owner: all links; foster: own links only)
- `GET /:id/access` — list users the pet is shared with (owner only)
- `DELETE /:id/access/:userId` — remove access and notify the user (owner only)
- `DELETE /:id/follow` — shared user stops following (self-remove access)
- `POST /:id/transfer` — transfer ownership to another user (owner only); body `{ recipient_email, confirmation_name }` (pet name must match, case-insensitive); former owner receives `shared` access automatically; writes `archived_pets` audit row (`transfer_type: user_to_user`)

Shared pets appear in `GET /api/pets/all` with `is_shared: true`. Fostered pets use `is_foster: true` (and `is_shared: false`). Shared and org-visible pets may include `primary_holder_name` (display name of the pet's primary holder) when the viewer is permitted to see it.

Share links are **single-use**: once accepted, the same link cannot be used by another user (`410`).

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
| `PUT /api/pets/:id/access/:userId/role` | Promote shared → guardian | Inc 5 |

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

### Pet Access — STUB

> **Status:** auth-gated (returns `401` without a valid token) but currently stubs — they return the static responses below without reading or writing the `pet_access` table. Real shared-access management lives in the sharing routes.

- **GET** `/api/pets/{id}/access` — Returns `[]`.
- **PUT** `/api/pets/{id}/access/{userId}/role` — No-op stub returning `{ "updated": true, "user_id": "{userId}" }`.
- **DELETE** `/api/pets/{id}/access/{userId}` — No-op stub returning `{ "deleted": true, "user_id": "{userId}" }`.

### Delete Pet Data

- **DELETE** `/api/pets/{id}/data` — Deletes pet-related rows (health, weight, timeline, shares, etc.) and purges health/pet upload files. Pet profile row remains until `DELETE /api/pets/{id}`.

### Mark Pet as Passed Away

- **POST** `/api/pets/{id}/passed-away` — Notifies collaborators (`notified_count` in response). Pet `passedAway` flag is persisted via `PUT /api/pets/{id}`.



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
