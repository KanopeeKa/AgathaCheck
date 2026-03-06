# Agatha Track (PetProfileApp)

## Overview
Agatha is a modular Flutter application for comprehensive pet management, enabling users to manage pet profiles, track health, log weight, and maintain veterinarian contacts. It provides a centralized platform for pet owners and organisations with robust authentication, in-app notifications, detailed pet reports, GDPR-compliant data rights, and consent management. The project aims to deliver a scalable, production-ready solution with future potential for native mobile and sharing capabilities.

## User Preferences
- Clean architecture with feature-driven structure
- TDD/BDD with comprehensive testing
- Full dartdoc documentation
- Production-ready CI setup
- EU GDPR compliance

## System Architecture
The application employs a clean architecture, separating concerns into data, domain, and presentation layers within feature modules. The UI adheres to Material 3 design principles with a deep purple/violet theme and uses GoRouter for navigation. Database connection is configured via `DATABASE_URL` environment variable parsed in `_parseDbUrl()`, with schema managed through migration files.

**Key Technical Implementations & Features:**
- **Pet Profile Management**: CRUD operations for pet profiles, linking vets and health entries. Pets are assigned a unique color from a 15-color palette for visual identification across the UI. Age is dynamically calculated from the date of birth. Server-side storage is via a `pets` PostgreSQL table, with `SharedPreferences` acting as a local cache. Pet deletion cascades to all associated server-side data.
- **Identification Reminder**: Displays species-specific reminders for pets without an ID, configurable for dismissal.
- **Passed Away Memorial**: Allows users to mark pets as passed away, triggering notifications, updating the pet's status, changing its color to white, and applying a rainbow wings overlay to its photo.
- **Authentication & User Profile**: JWT-based email/password authentication (signup, login, refresh, logout, profile management, password reset). User profiles include first/last name, category, bio, and photo.
- **Health Tracking**: Manages health entries (medications, preventives, vet visits) with scheduling, photo attachments, and a tabbed dashboard. Supports various frequencies for entries.
- **Health Issues**: Tracks ongoing health conditions linked to pets, with optional start/end dates and associations with health entries.
- **Weight Tracking**: Records per-pet weight history with line charts and unit selection.
- **Veterinarian Management**: CRUD operations for veterinarian contacts, linkable to pets. Vets are scoped to users via `user_id` column for data isolation. `pets.vet_id` is INTEGER matching `vets.id`.
- **Notification System**: In-app notification center for due entries and general events, with server-side processing and per-pet mute options.
- **Sharing Feature**: Multi-user pet access with guardian/shared roles via share links, managed through a `pet_access` table. Share link acceptance creates a `pending_shared` entry with a notification to the recipient. Pending shares appear at the top of the pet list with Accept/Decline buttons. When accepting, users choose personal list or an organization. Accepted shared pets appear in `GET /api/pets/all` with `is_shared: true`. Hidden shared pets: `pet_access.hidden` column controls visibility; hidden pets excluded from pet list, health dashboard, and notifications. Endpoints: `GET /api/share/pending`, `POST /api/share/pending/:petId/accept` (body: optional `organization_id`), `POST /api/share/pending/:petId/decline`, `PUT /api/share/:petId/hide` (body: `{hidden: bool}`), `GET /api/share/hidden`. Swipe-to-hide on shared pet cards in pet list; unhide via collapsed section in org detail screen.
- **Organization Support**: Comprehensive management for Professional and Charity organizations, including user roles, pet transfers, and archiving. Pet list groups pets by organization with filter chips (All Pets / My Pets / per-org). Health dashboard includes matching org filter. Server endpoint `GET /api/pets/all` returns personal + org pets with `organization_id` and `organization_name`. Email-based invite flow with role selection (member/super_user): `POST /api/organizations/:id/invite` sends invite, `GET /api/organizations/invites/pending` lists pending invites, `POST /api/organizations/invites/:id/accept` and `POST /api/organizations/invites/:id/decline` handle responses. Pending invites stored as `pending_member`/`pending_super_user` roles in `organization_users`. Org detail screen shows all members inline with an "Add User" button opening an email+role invite dialog. Dedicated `/organizations` page (OrganizationListScreen) with full org list, pending invites, and create/join buttons. My Details links to the organisations page via a simple tile. App bar business icon always visible, navigates to `/organizations`.
- **Family Events**: Org pets support family events (assigned member, date range, notes) via `family_events` table. CRUD via `GET/POST /api/pets/:id/family-events` and `PUT/DELETE /api/pets/:id/family-events/:id`. UI in pet detail screen shows collapsible Family Events section for org pets with add dialog and swipe-to-delete. Family events are also included in the To Do / health dashboard as `family_event` type entries (with a dedicated "Family Events" tab). When a family event with a "To date" is created, reminder notifications are sent to all org members. The health entries API passes the auth token so the server can include family events for the user's orgs.
- **Pet Report Generation**: Generates customizable PDF reports for individual pets with 7 optional sections: pet profile, weight tracking (chart + table), health events (with optional administration log), health issues, family events (care assignments and foster stays, for org pets), recent notifications/alerts, and sharing access details.
- **Subscription (RevenueCat)**: Manages in-app subscriptions and entitlements across platforms.
- **Localization (EN/FR)**: Full English/French localization via Flutter's `intl` system, with locale persistence and server-side syncing.
- **Deployment**: Flutter web frontend is statically served by an AOT compiled Dart API server. Database is configured via `DATABASE_URL` env var. See `DEPLOYMENT_DB.md` for provisioning and migration instructions.
- **Database Migrations**: SQL migration files in `db/migrations/` with a Dart runner at `bin/migrate.dart`. Supports `up` and `down` migrations. Migration tracking via `_migrations` table.
- **Help & FAQ**: In-app help page (`/help`) accessible from the user menu, with 12 collapsible FAQ sections covering every feature. Fully localised in EN/FR. Route: `/help`, screen: `HelpScreen`.
- **About Us Screen**: `/about` screen with app logo, intro text, and links to Privacy Policy (`/privacy-policy`) and Terms of Service (`/terms-of-service`). Accessible from My Details.
- **GDPR Data Rights**: Delete account (`DELETE /api/auth/me` with password confirmation, cascades all data), export data (`GET /api/auth/me/export` returns full JSON), edit profile, withdraw consent. All accessible from My Details screen.
- **Consent Banner**: Custom CMP-style banner on first launch with Accept All / Manage Preferences. Stores consent state in SharedPreferences (essential/analytics/marketing). Re-accessible from My Details → Privacy Preferences or `/consent-settings` route.
- **Regulatory Documentation**: Internal GDPR docs at `regulatory/` — `DATA_MAP.md` (personal data + SDK inventory), `INTERNAL_GDPR.md` (DPO, hosting, retention, processing activities), `PRIVACY_POLICY.md`, `TERMS_OF_SERVICE.md`.
- **Accessibility**: Implemented across all screens with tooltips, keys, semantics, and proper form field labeling.
- **BDD Tests**: Gherkin `.feature` files under `flutter_app/test/bdd/features/` covering all features: authentication, pet profiles, health tracking, weight tracking, vet management, sharing, notifications, subscriptions, help/FAQ, plus organisation management, pet management, timeline, and adoption.

## Database
- **Connection**: `DATABASE_URL` environment variable (PostgreSQL connection string). Parsed via `_parseDbUrl()` in `bin/server.dart`. Falls back to individual `PG*` vars if URL host is empty.
- **Migration runner**: `dart run bin/migrate.dart [up|down]` — applies SQL files from `db/migrations/`
- **Schema**: 19 tables — users, pets, vets (with user_id), health_entries, health_history, health_issues, health_issue_events, health_event_photos, weight_entries, notifications, notification_preferences, pet_access, shared_pets, organizations, organization_users, archived_pets, family_events, refresh_tokens, password_reset_tokens, _migrations
- **Key fixes applied**: `vets.user_id` added for data isolation; `pets.vet_id` normalised from VARCHAR to INTEGER; performance indexes added

## External Dependencies
- **Flutter**: Frontend framework
- **flutter_riverpod**: State management
- **go_router**: Navigation
- **shared_preferences**: Local storage
- **PostgreSQL**: Primary database
- **dart_jsonwebtoken**: JWT handling
- **dbcrypt**: Password hashing
- **intl**: Date formatting
- **fl_chart**: Interactive charts
- **http**: API communication
- **image_picker**: Photo selection
- **pdf**, **printing**: PDF generation
- **purchases_flutter**, **purchases_ui_flutter**: RevenueCat SDK
- **web**: Dart web interop (for file downloads)
