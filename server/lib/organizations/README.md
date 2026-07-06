# Dart organization routes (Shelf)

Mirrors the Node module layout in `server/routes/organizations/`.

| Module | Routes |
|--------|--------|
| `org_shared.dart` | Auth helpers, role guards, row mapping |
| `invites_routes.dart` | Pending invites, accept/decline |
| `core_routes.dart` | Org CRUD |
| `members_routes.dart` | Members list, invite, people directory, role changes |
| `pets_routes.dart` | Org pets, archived |
| `foster_parents_routes.dart` | Foster parent directory (member + external) |
| `placements_routes.dart` | Foster placements lifecycle and direct adopt |

Shared libs: `server/lib/org_roles.dart`, `org_people.dart`, `foster_placements.dart`.

Parity gaps vs Node (documented): external foster notice email is not sent from Dart.
