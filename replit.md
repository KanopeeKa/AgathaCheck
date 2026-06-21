# Agatha Track (PetProfileApp)

## Overview
Agatha Track is a modular Flutter application designed for comprehensive pet management. It enables users to manage pet profiles, track health, log weight, and maintain veterinarian contacts. The platform offers robust authentication, in-app notifications, detailed pet reports, and adheres to GDPR data rights and consent management. The project aims to provide a scalable, production-ready solution for pet owners and organizations, with future potential for native mobile and advanced sharing capabilities.

## User Preferences
- Clean architecture with feature-driven structure
- TDD/BDD with comprehensive testing
- Full dartdoc documentation
- Production-ready CI setup
- EU GDPR compliance

## System Architecture
The application is built with a clean architecture, separating concerns into data, domain, and presentation layers within feature modules. The UI follows Material 3 design principles with a deep purple/violet theme and utilizes GoRouter for navigation.

**Key Technical Implementations & Features:**

-   **Pet Profile Management**: CRUD operations for pet profiles, including dynamic age calculation, unique color assignment, and cascading deletion.
-   **Authentication & User Profile**: JWT-based authentication with comprehensive user profile management, including password reset and profile editing.
-   **Health Tracking**: Manages medications, preventives, and vet visits with scheduling, photo attachments, and a tabbed dashboard.
-   **Health Issues**: Tracks ongoing health conditions linked to pets, associating them with health entries.
-   **Weight Tracking**: Records and visualizes per-pet weight history with line charts.
-   **Veterinarian Management**: CRUD for veterinarian contacts, scoped per user.
-   **Notification System**: In-app notifications for due entries and general events, with per-pet mute options.
-   **Sharing Feature**: Multi-user pet access with guardian/shared roles via share links, managed through a `pet_access` table with pending share acceptance and visibility controls.
-   **Organization Support**: Comprehensive management for Professional and Charity organizations, including user roles, pet transfers, archiving, and an email-based invite flow. Org pets support family events with assigned members, date ranges, and reminder notifications.
-   **Pet Report Generation**: Customizable PDF reports for individual pets, including sections for profile, weight, health events, issues, family events, notifications, and sharing details.
-   **Localization**: Full English/French localization with locale persistence.
-   **Deployment**: Flutter web frontend served by an AOT compiled Dart API server.
-   **Database Migrations**: SQL migration files managed by two interoperable runners that share the same `_migrations` tracking table. (1) `server/bin/migrate.dart` (Dart, local/dev) supports four commands: `up` (apply pending `NNN_*.sql`), `down` (roll back the most recent), `status` (list applied/pending), and `fresh` (DROP every table and recreate from the canonical `v3__initial_uuid_schema.sql`, then mark every incremental migration as already applied — used for self-hosted installs onto an empty server). `fresh` requires `MIGRATE_CONFIRM=DROP_ALL` as a safety guard. (2) `server/scripts/migrate.js` (Node ESM, deploy/remote) supports `up` and `status` only — used by the prod deploy workflow because cPanel hosting has no Dart SDK. The two deploy workflows differ in transport: **prod** (`deploy-prod.yml`) has SSH, so it stages `db/migrations/` into `server/db/migrations/` before FTP, then SSH-runs `node scripts/migrate.js up` after `npm ci --omit=dev` and before `touch tmp/restart.txt` (schema applies automatically before restart). **UAT** (`deploy-uat.yml`) is intentionally FTP-only (no SSH — reserved for final prod); it still stages the migration SQL onto the box for reference and triggers a Passenger restart by uploading a freshly-timestamped `server/tmp/restart.txt`, but migrations and `npm install` on UAT are **manual**: apply `db/migrations/*.sql` in order via psql/pgAdmin, and run "Run NPM Install" in cPanel → Setup Node.js App when `server/package.json` changes. Replit-managed prod installs go through the Publish flow (not `fresh`).
-   **Database Schema (canonical)**: 19 application tables + `_migrations` tracker. `db/migrations/v3__initial_uuid_schema.sql` is the **single source of truth for fresh installs** — it inlines every column added by migrations 001–007. Existing DBs replay only the incremental `NNN_*.sql` files they have not yet applied (tracked in `_migrations`). Notable shape decisions: `archived_pets` is a transfer record (`organization_id`, `pet_id`, `pet_name`, `pdf_data`, `transfer_type`, `transferred_to_*`, `notes`, `archived_at`, `created_at`) — not a pet copy. `family_events` and `shared_pets` exist in the schema but are currently unused by any route (Node.js + Dart routes for family events are stubs). `notifications` keeps both `is_read` and legacy `read` columns (UPDATEs touch both).
-   **GDPR Data Rights**: Functionality for account deletion, data export (JSON), profile editing, and consent withdrawal.
-   **Consent Management**: Custom CMP-style banner for initial consent, with preferences stored locally and re-accessible.
-   **Accessibility**: Implemented across all screens with tooltips, keys, semantics, and proper form field labeling.
-   **API Auth Hardening**: All authenticated Node.js routes enforce JWT validation and user ID extraction to prevent unauthorized access and cross-user IDOR. In the sharing router, `/pending` and `/hidden` are declared before `/:code` so they are not swallowed by the parameterised route. The JWT signing secret is resolved in **one shared module per backend** (`server/config/jwtSecret.js` for Node, `server/lib/jwt_secret.dart` for Dart) imported by every route file — there is no longer a per-file `process.env.JWT_SECRET || ... || 'default_secret'`. Resolution is `JWT_SECRET || SESSION_SECRET`; when `NODE_ENV=production` a missing secret **throws at startup** (no insecure default reaches prod), while a `'default_secret'` dev/test fallback is kept so local runs and the Jest/CI suite work without extra env setup. The runtime secret for UAT/PROD must be set in the cPanel Node.js app environment (not GitHub Actions secrets, which the FTP/SSH deploy workflows do not inject).

## Testing
-   **Backend (Node.js)**: Jest is the canonical runner. Run `cd server && npx jest --env=node --forceExit` for 340 tests across 9 suites. The `--forceExit` flag avoids hangs caused by lingering pg client handles. Tests use the `createApp(mockPool)` factory and sign JWTs with `JWT_SECRET || SESSION_SECRET || 'default_secret'`. `babel-plugin-transform-import-meta` handles ESM `import.meta`. Mocha is legacy-only (`npm run test:mocha`).
-   **Backend (Dart)**: there is **no Dart test suite** — `server/pubspec.yaml` has no `test` dev dependency and `server/test/` contains only the Jest `.js` files. The Dart shelf server (`server/lib/*.dart`) is a route-for-route parity port of the Node backend; correctness is enforced by the Jest suite against the Node routes plus `dart analyze`, and the two backends are kept in lockstep by hand. Do **not** assume `dart test` runs anything here.
-   **Frontend (Flutter)**: `cd flutter_app && flutter test` runs unit/widget/model tests. Model tests live under `flutter_app/test/features/*/data/models/` and verify camelCase field mapping, defaults, and null handling. Remote-datasource tests (e.g. `flutter_app/test/features/health_tracking/data/datasources/health_remote_datasource_test.dart`) use `package:http/testing.dart` `MockClient` to assert outgoing requests attach the `Authorization: Bearer <token>` header. Run `flutter pub get` first if the pub cache is incomplete.
-   **Health entry completion semantics**: the Flutter UI derives "overdue"/"completed" purely from `next_due_date` (the entity has no status field). `mark-taken` for a `once` entry sets `next_due_date` to the 9999-12-31 sentinel (`isCompleted` true); for a recurring entry it advances `next_due_date` past today so the entry leaves the overdue state. `undo-complete` restores `once` entries to `start_date`. Covered by `healthEntries.test.js` (Node) and `health_entry_test.dart` (entity contract).
-   **BDD**: Gherkin features under `flutter_app/test/bdd/features/`.
-   **Pitfall**: Dart enum `.name` is minified in release builds — always use direct enum comparison or a `.label` getter, never `.name`.

## CI / CD
-   **`.github/workflows/ci.yml`**: triggered on push/PR to `main`. Two parallel jobs — `flutter` (cache → `pub get` → optional `build_runner` → analyze → test with coverage → optional integration tests → `flutter build web --release --no-tree-shake-icons` → upload `web-build` artifact) and `backend` (npm cache → `npm ci` → `npx jest --env=node --forceExit`).
-   **`.github/workflows/deploy-uat.yml`**: triggered on push to `release/uat-*`. Two jobs (`test` → `deploy`). Deploy job uses `environment: UAT` and is **FTP-only (no SSH)** — UAT has no SSH access. It FTP-publishes the Flutter web build to `./` and the Node.js backend to `./backend/` on `uat.agathatrack.com` (excluding `node_modules`, tests, and dev configs; the frontend deploy excludes `**/backend/**` so it isn't wiped). To restart the cPanel/Passenger Node app without a shell, it uploads `server/tmp/restart.txt` rewritten with a fresh UTC timestamp each run, so the changed mtime triggers a restart. Dependency installs (`npm install` via cPanel) and DB migrations (psql/pgAdmin) are **manual** on UAT.
-   **`.github/workflows/deploy-prod.yml`**: triggered on GitHub release publish. Mirrors UAT structure with `PROD_*` secrets and `environment: PROD`. Frontend deploys to `/public_html/Prod/`, backend to `/public_html/Prod/backend/`.
-   **Required secrets**: UAT (FTP-only) needs `UAT_FTP_SERVER|USERNAME|PASSWORD` — the `UAT_SSH_*` secrets are no longer used by the UAT workflow. PROD still needs `PROD_FTP_SERVER|USERNAME|PASSWORD` plus `PROD_SSH_HOST|USER|PRIVATE_KEY` (optional `PROD_SSH_PORT`, and `PROD_SSH_PASSPHRASE` only if the key is encrypted).

## External Dependencies
-   **Flutter**: Frontend framework
-   **flutter_riverpod**: State management
-   **go_router**: Navigation
-   **shared_preferences**: Local storage
-   **PostgreSQL**: Primary database
-   **dart_jsonwebtoken**: JWT handling
-   **dbcrypt**: Password hashing
-   **intl**: Date formatting
-   **fl_chart**: Interactive charts
-   **http**: API communication
-   **image_picker**: Photo selection
-   **pdf**, **printing**: PDF generation
-   **purchases_flutter**, **purchases_ui_flutter**: RevenueCat SDK
-   **web**: Dart web interop (for file downloads)