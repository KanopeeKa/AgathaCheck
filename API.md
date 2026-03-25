# API Documentation

## Authentication

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

## Test Coverage


### Automated Test Coverage

The signup endpoint is covered by automated tests that verify:
- Successful user creation returns a user object and valid JWT tokens (access and refresh)
- Duplicate email returns a 400 error with an appropriate message
- Missing email or password returns a 400 error with an appropriate message

Test implementation can be found in:
- `server/test/auth_signup.integration.test.js` (integration tests)
- `server/test/auth_signup.test.js` (unit tests)

*This file documents the authentication signup endpoint. Add more endpoints as needed for your API.*
