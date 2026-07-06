# Auth routes (Node.js)

Modular Express routers for `/api/auth` and `/backend/api/auth`.

## Layout

| Module | Responsibility |
|--------|----------------|
| `shared.js` | JWT helpers, `extractToken`, `userRowToMap` |
| `sessionRouter.js` | Signup, login, refresh, logout |
| `profileRouter.js` | `/me`, profile update, photo, export, account deletion |
| `passwordRouter.js` | Change password, forgot/reset password |
| `index.js` | Composes routers |

## Tests

- `server/test/auth.test.js`
- `server/test/auth.audit.test.js`
- `server/test/auth.forgot-password-mail.test.js`

Import path unchanged via `routes/auth.js` shim.
