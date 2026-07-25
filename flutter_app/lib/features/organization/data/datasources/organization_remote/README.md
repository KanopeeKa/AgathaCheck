# Organization remote datasource (Flutter)

Modular HTTP clients for organization APIs. Mirrors `server/routes/organizations/`.

## Layout

| Module | Responsibility |
|--------|----------------|
| `organization_remote_context.dart` | Shared `http.Client`, base URL, auth headers |
| `organization_core_remote.dart` | Org CRUD, photo/logo upload, primary contact |
| `organization_invites_remote.dart` | Pending invites, accept/decline |
| `organization_members_remote.dart` | Members list, invite-by-email, role changes |
| `organization_pets_remote.dart` | Org pets, transfers, archived pets, family events |
| `organization_foster_parents_remote.dart` | Foster parent directory, people directory |
| `organization_foster_requests_remote.dart` | Foster request send/list/detail/respond |
| `organization_placements_remote.dart` | Foster placements and adoption lifecycle |

`../organization_remote_datasource.dart` is the **facade** — same public API as before the split.

## Tests

Provider/repository coverage: `test/features/organization/presentation/providers/`.

Unit tests for shared context: `test/features/organization/data/datasources/organization_remote_context_test.dart`.
