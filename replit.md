# Agatha Track (PetProfileApp)

## Overview
Agatha is a modular Flutter application for comprehensive pet management, enabling users to manage pet profiles, track health, log weight, and maintain veterinarian contacts. It provides a centralized platform for pet owners with robust authentication, in-app notifications, and detailed pet reports. The project aims to deliver a scalable, production-ready solution with future potential for native mobile and sharing capabilities.

## User Preferences
- Clean architecture with feature-driven structure
- TDD/BDD with comprehensive testing
- Full dartdoc documentation
- Production-ready CI setup

## System Architecture
The application employs a clean architecture, separating concerns into data, domain, and presentation layers within feature modules. The UI adheres to Material 3 design principles with a deep purple/violet theme and uses GoRouter for navigation.

**Key Technical Implementations & Features:**
- **Pet Profile Management**: CRUD operations for pet profiles, linking vets and health entries. Pets are assigned a unique color from a 15-color palette for visual identification across the UI. Age is dynamically calculated from the date of birth. Server-side storage is via a `pets` PostgreSQL table, with `SharedPreferences` acting as a local cache. Pet deletion cascades to all associated server-side data.
- **Identification Reminder**: Displays species-specific reminders for pets without an ID, configurable for dismissal.
- **Passed Away Memorial**: Allows users to mark pets as passed away, triggering notifications, updating the pet's status, changing its color to white, and applying a rainbow wings overlay to its photo.
- **Authentication & User Profile**: JWT-based email/password authentication (signup, login, refresh, logout, profile management, password reset). User profiles include first/last name, category, bio, and photo.
- **Health Tracking**: Manages health entries (medications, preventives, vet visits) with scheduling, photo attachments, and a tabbed dashboard. Supports various frequencies for entries.
- **Health Issues**: Tracks ongoing health conditions linked to pets, with optional start/end dates and associations with health entries.
- **Weight Tracking**: Records per-pet weight history with line charts and unit selection.
- **Veterinarian Management**: CRUD operations for veterinarian contacts, linkable to pets.
- **Notification System**: In-app notification center for due entries and general events, with server-side processing and per-pet mute options.
- **Sharing Feature**: Multi-user pet access with guardian/shared roles via share links, managed through a `pet_access` table. Share link acceptance creates a `pending_shared` entry with a notification to the recipient. Pending shares appear at the top of the pet list with Accept/Decline buttons. When accepting, users choose personal list or an organization. Accepted shared pets appear in `GET /api/pets/all` with `is_shared: true`. Hidden shared pets: `pet_access.hidden` column controls visibility; hidden pets excluded from pet list, health dashboard, and notifications. Endpoints: `GET /api/share/pending`, `POST /api/share/pending/:petId/accept` (body: optional `organization_id`), `POST /api/share/pending/:petId/decline`, `PUT /api/share/:petId/hide` (body: `{hidden: bool}`), `GET /api/share/hidden`. Swipe-to-hide on shared pet cards in pet list; unhide via collapsed section in org detail screen.
- **Organization Support**: Comprehensive management for Professional and Charity organizations, including user roles, pet transfers, and archiving. Pet list groups pets by organization with filter chips (All Pets / My Pets / per-org). Health dashboard includes matching org filter. Server endpoint `GET /api/pets/all` returns personal + org pets with `organization_id` and `organization_name`. Email-based invite flow with role selection (member/super_user): `POST /api/organizations/:id/invite` sends invite, `GET /api/organizations/invites/pending` lists pending invites, `POST /api/organizations/invites/:id/accept` and `POST /api/organizations/invites/:id/decline` handle responses. Pending invites stored as `pending_member`/`pending_super_user` roles in `organization_users`. Org detail screen shows all members inline with an "Add User" button opening an email+role invite dialog. Dedicated `/organizations` page (OrganizationListScreen) with full org list, pending invites, and create/join buttons. My Details links to the organisations page via a simple tile. App bar business icon always visible, navigates to `/organizations`.
- **Family Events**: Org pets support family events (assigned member, date range, notes) via `family_events` table. CRUD via `GET/POST /api/pets/:id/family-events` and `PUT/DELETE /api/pets/:id/family-events/:id`. UI in pet detail screen shows collapsible Family Events section for org pets with add dialog and swipe-to-delete. Family events are also included in the To Do / health dashboard as `family_event` type entries (with a dedicated "Family Events" tab). When a family event with a "To date" is created, reminder notifications are sent to all org members. The health entries API passes the auth token so the server can include family events for the user's orgs.
- **Pet Report Generation**: Generates customizable PDF reports for individual pets, including profile, weight, health events, and issues.
- **Subscription (RevenueCat)**: Manages in-app subscriptions and entitlements across platforms.
- **Localization (EN/FR)**: Full English/French localization via Flutter's `intl` system, with locale persistence and server-side syncing.
- **Deployment**: Flutter web frontend is statically served by an AOT compiled Dart API server.
- **Accessibility**: Implemented across all screens with tooltips, keys, semantics, and proper form field labeling.

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