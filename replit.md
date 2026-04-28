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
-   **Database Migrations**: SQL migration files managed with a Dart runner for `up` and `down` operations.
-   **GDPR Data Rights**: Functionality for account deletion, data export (JSON), profile editing, and consent withdrawal.
-   **Consent Management**: Custom CMP-style banner for initial consent, with preferences stored locally and re-accessible.
-   **Accessibility**: Implemented across all screens with tooltips, keys, semantics, and proper form field labeling.
-   **API Auth Hardening**: All authenticated Node.js routes enforce JWT validation and user ID extraction to prevent unauthorized access and cross-user IDOR. In the sharing router, `/pending` and `/hidden` are declared before `/:code` so they are not swallowed by the parameterised route.

## Testing
-   **Backend (Node.js)**: Jest is the canonical runner. Run `cd server && npx jest --env=node --forceExit` for ~338 tests across 9 suites. The `--forceExit` flag avoids hangs caused by lingering pg client handles. Tests use the `createApp(mockPool)` factory and sign JWTs with `JWT_SECRET || SESSION_SECRET || 'default_secret'`. `babel-plugin-transform-import-meta` handles ESM `import.meta`. Mocha is legacy-only (`npm run test:mocha`).
-   **Backend (Dart)**: `cd server && dart test` runs parity tests for the shelf server.
-   **Frontend (Flutter)**: `cd flutter_app && flutter test` runs unit/widget/model tests. Model tests live under `flutter_app/test/features/*/data/models/` and verify camelCase field mapping, defaults, and null handling.
-   **BDD**: Gherkin features under `flutter_app/test/bdd/features/`.
-   **Pitfall**: Dart enum `.name` is minified in release builds — always use direct enum comparison or a `.label` getter, never `.name`.

## CI / CD
-   **`.github/workflows/ci.yml`**: triggered on push/PR to `main`. Two parallel jobs — `flutter` (cache → `pub get` → optional `build_runner` → analyze → test with coverage → optional integration tests → `flutter build web --release --no-tree-shake-icons` → upload `web-build` artifact) and `backend` (npm cache → `npm ci` → `npx jest --env=node --forceExit`).
-   **`.github/workflows/deploy-uat.yml`**: triggered on push to `release/uat-*`. Two jobs (`test` → `deploy`). Deploy job uses `environment: UAT`, FTP-publishes the Flutter web build to `./` and the Node.js backend to `./backend/` on `uat.agathatrack.com` (excluding `node_modules`, tests, and dev configs; the frontend deploy excludes `**/backend/**` so it isn't wiped), then SSHes in to run `npm install --omit=dev` and `touch tmp/restart.txt`.
-   **`.github/workflows/deploy-prod.yml`**: triggered on GitHub release publish. Mirrors UAT structure with `PROD_*` secrets and `environment: PROD`. Frontend deploys to `/public_html/Prod/`, backend to `/public_html/Prod/backend/`.
-   **Required secrets**: `UAT_FTP_SERVER|USERNAME|PASSWORD`, `UAT_SSH_HOST|USER|PRIVATE_KEY` (optional `UAT_SSH_PORT`), and the equivalent `PROD_*` set.

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