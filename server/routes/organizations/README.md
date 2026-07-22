# Organization routes (Node.js)

Modular Express routers for `/api/organizations` and `/backend/api/organizations`.

## Layout

| Module | Responsibility |
|--------|----------------|
| `shared.js` | Auth extraction, role guards, org row mapping, image upload helpers |
| `invitesRouter.js` | Pending invites, accept/decline, join-by-code (501) |
| `coreRouter.js` | Org CRUD, photo/logo upload, primary contact |
| `membersRouter.js` | Members list, people directory, invites, role changes |
| `petsRouter.js` | Org pets, create, transfer, archived list |
| `fosterParentsRouter.js` | Foster parent directory (member + external) |
| `placementsRouter.js` | Foster placements lifecycle and direct adopt (`placements/` sub-modules) |
| `index.js` | Composes routers (static routes registered before `/:id`) |

## Tests

Mirrored under `server/test/organizations/`:

- `helpers.js` — mock pool and fixtures
- `authGuard.test.js`, `core.test.js`, `members.test.js`, `pets.test.js`
- `authorization.test.js`, `fosterParents.test.js`, `people.test.js`
- `placements.test.js`, `edgeCases.test.js`

## Shared libs

Shared helpers live under `server/lib/`: `orgRoles.js`, `orgPeople.js`, `fosterPlacements.js`, `petCustody.js`, and related modules (role guards, people directory, foster placements, custody transfers).
