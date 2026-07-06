# Pet routes (Node.js)

Modular Express routers for `/api/pets` and `/backend/api/pets`.

## Layout

| Module | Responsibility |
|--------|----------------|
| `shared.js` | Auth extraction, pet row mapping, color helpers, transactions |
| `transferRouter.js` | User-to-user and user-to-org pet transfers |
| `familyEventsRouter.js` | Legacy family events CRUD on org pets |
| `accessRouter.js` | Share links, follow, collaborator access |
| `lifecycleRouter.js` | Passed-away and data-delete stubs |
| `coreRouter.js` | Pet list and CRUD (`/all`, `/`, `/:id`) |
| `index.js` | Composes routers (specific paths before generic `/:id`) |

## Tests

`server/test/pets.test.js` — unchanged import path via `routes/pets.js` shim.
