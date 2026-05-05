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
  "category": "pet_guardian",    // optional, default: pet_guardian
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
    "category": "pet_guardian",
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
    "category": "pet_guardian",
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
- Transfers a pet to an organization. Requires JSON body with `organization_id`, `transfer_type`, and `notes`.
- **Response:** `{ "status": "transferred", "pet_id": "{id}" }`

### Family Events (per-pet) — STUB

> **Status:** the per-pet family-events routes below exist in both the Node.js and Dart servers but are currently stubs that return empty arrays / no-op responses. Real family events live on **organization pets** (see the organization routes) and are implemented there. The `family_events` table exists in the canonical schema but is not written to by these endpoints.

- **GET** `/api/pets/{id}/family-events` — Returns `[]`.
- **POST** `/api/pets/{id}/family-events` — No-op stub.
- **PUT** `/api/pets/{id}/family-events/{eventId}` — No-op stub.
- **DELETE** `/api/pets/{id}/family-events/{eventId}` — No-op stub.

### Pet Access

- **GET** `/api/pets/{id}/access` — List all users with access to a pet.
- **PUT** `/api/pets/{id}/access/{userId}/role` — Update a user's role for a pet.
- **DELETE** `/api/pets/{id}/access/{userId}` — Remove a user's access to a pet.
- **Response:** Standard JSON with access info or `{ "deleted": true }`/`{ "updated": true }`.

### Delete Pet Data

- **DELETE** `/api/pets/{id}/data` — Delete all data for a pet.
- **Response:** `{ "deleted": true, "pet_id": "{id}" }`

### Mark Pet as Passed Away

- **POST** `/api/pets/{id}/passed-away` — Mark a pet as passed away.
- **Response:** `{ "passed_away": true, "pet_id": "{id}" }`



### Notifications Endpoints

The notification system is fully implemented and persists to the `notifications` table (which keeps both `is_read` and a legacy `read` column for backward compatibility — UPDATEs touch both).

- **GET** `/backend/api/notifications` — Returns the authenticated user's notifications.
- **GET** `/backend/api/notifications/preferences` — Returns the user's notification preferences.
- **POST** `/backend/api/notifications/check-due` — Scans health entries for due/overdue items and creates notifications for the authenticated user.
- **PATCH** `/backend/api/notifications/{id}/read` — Marks a single notification as read.
- **POST** `/backend/api/notifications/mark-all-read` — Marks every unread notification for the user as read.

In-app notifications also support per-pet mute via the pet routes.

### Test Coverage

- See `server/test/pets_extended_endpoints.test.js` for endpoint tests with mocked DB logic.
- See `server/test/notifications.test.js` for notifications endpoint tests.
