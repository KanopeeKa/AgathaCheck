# Dart organization routes (Shelf)

Mirrors the Node module layout in `server/routes/organizations/`.
The Dart implementation currently covers a **subset** of Node routes
(foster parents, placements, and people directory are Node-only today).

| Module | Routes |
|--------|--------|
| `org_shared.dart` | Auth helpers, role guards, row mapping |
| `invites_routes.dart` | Pending invites, accept/decline |
| `core_routes.dart` | Org CRUD |
| `members_routes.dart` | Members list, invite |
| `pets_routes.dart` | Org pets, archived |
