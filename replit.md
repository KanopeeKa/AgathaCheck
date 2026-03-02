# Agatha (PetProfileApp)

## Overview
A modular Flutter application for managing pet profiles, health tracking, and veterinarian contacts using clean architecture. Built with Material 3, Riverpod state management, GoRouter navigation, SharedPreferences local storage for pets, and PostgreSQL for health entries, vets, and authentication.

## Current State
- Pet profile feature fully implemented with CRUD operations (SharedPreferences)
- Health tracking feature (MVP) with medications, preventives, vaccines (PostgreSQL)
- Veterinarian management feature with CRUD operations (PostgreSQL)
- Pet-to-health relationship: each pet has their own health entries shown in pet detail screen
- Pet-to-vet relationship: each pet can be linked to a veterinarian
- Authentication: JWT-based email/password auth with signup, login, refresh, logout, profile management, password change
- Weight tracking: per-pet weight history with line chart, add/delete entries (PostgreSQL)
- Notification system: in-app notification center with bell icon + badge, server-side due-entry checking, email reminder stubs
- API server with REST endpoints for health entries, weight entries, vets, sharing, auth, and notifications
- Deployed as static Flutter web files served by a Dart API server (AOT compiled)

## Project Architecture
```
bin/server.dart        - Dart API server + static file server (auth, health, vets, sharing)
deploy/public/         - Pre-built Flutter web files (static assets)
flutter_app/           - Flutter source code (development)
  lib/
    core/              - App-wide: theme, router, constants
    features/
      auth/            - Authentication feature
        data/auth_service.dart           - REST API client for auth endpoints
        presentation/providers/auth_providers.dart - Riverpod auth state management
        presentation/screens/
          login_screen.dart              - Login form
          signup_screen.dart             - Registration form
          my_details_screen.dart         - Profile view + password change
      pet_profile/     - Pet CRUD with data/domain/presentation layers
        presentation/screens/
          pet_list_screen.dart    - Home screen with pet cards + user menu
          pet_detail_screen.dart  - Pet profile + vet info + weight tracking + health events (collapsible sections)
          pet_form_screen.dart    - Add/edit pet form (with vet dropdown, gender)
      health_tracking/ - Health tracking with data/domain/presentation layers
      weight_tracking/ - Weight tracking with data/domain/presentation layers
      vet/             - Vet management with data/domain/presentation layers
      notifications/   - Notification center with data/domain/presentation layers
      sharing/         - Pet sharing feature
  test/                - Unit and widget tests
  test_integration/    - Integration tests
  web/                 - Flutter web template
  pubspec.yaml         - Flutter dependencies
pubspec.yaml           - Root: pure Dart + postgres + dart_jsonwebtoken + dbcrypt
```

## Navigation / Routes
- `/landing` - Landing page with branding text + login/signup tabs (shown to unauthenticated users)
- `/` - Pet list (home, requires auth) — user avatar menu with My Details and Log Out
- `/my-details` - User profile + change password (requires auth)
- `/add` - Add new pet
- `/edit/:id` - Edit pet
- `/pet/:petId` - Pet detail screen (profile info + vet info + health entries)
- `/pet/:petId/health/add` - Add health entry for a specific pet
- `/pet/:petId/health/edit/:id` - Edit health entry for a specific pet
- `/health` - Global health dashboard (all pets, all entries)
- `/health/add` - Add health entry (unscoped)
- `/health/edit/:id` - Edit health entry (unscoped)
- `/vets` - Vet list
- `/vets/add` - Add new vet
- `/vets/edit/:id` - Edit vet
- `/notifications` - Notification center (all notifications grouped by date)
- `/notifications/settings` - Notification settings (email reminders, alert toggles)
- `/shared/:code` - View shared pet (read-only, no auth needed)

## Authentication Feature
- **Database**: PostgreSQL users table (id, email, password_hash, name, created_at, updated_at) + refresh_tokens table
- **Password hashing**: bcrypt via dbcrypt package
- **Tokens**: JWT access tokens (30min expiry) + refresh tokens (30 day expiry) stored in DB
- **JWT Secret**: Uses SESSION_SECRET environment variable
- **API Endpoints**:
  - POST /api/auth/signup - Create account (email, password, name) → user + tokens
  - POST /api/auth/login - Login (email, password) → user + tokens
  - POST /api/auth/refresh - Refresh access token
  - POST /api/auth/logout - Invalidate refresh token
  - GET /api/auth/me - Get current user (requires Bearer token)
  - PUT /api/auth/me - Update profile (name)
  - POST /api/auth/change-password - Change password (invalidates all refresh tokens)
- **Frontend**: Tokens stored in SharedPreferences, auth state managed by Riverpod StateNotifier
- **Route guard**: GoRouter redirect sends unauthenticated users to `/landing`; only `/landing` and `/shared/:code` are public
- **UI**: Landing page with branding text + login/signup tabs; user avatar menu in app bar (My Details, Log Out); My Details screen with profile editing and password change form

## Health Tracking Feature
- **Relationship**: 1 pet -> many health entries (via pet_id foreign key)
- **Database**: PostgreSQL with health_entries and health_history tables
- **API Endpoints**:
  - GET /api/health-entries - List entries (filter by pet_id, type)
  - POST /api/health-entries - Create entry
  - GET /api/health-entries/:id - Get single entry
  - PUT /api/health-entries/:id - Update entry
  - DELETE /api/health-entries/:id - Delete entry
  - POST /api/health-entries/:id/mark-taken - Mark as taken (advances due date)
  - GET /api/health-entries/:id/history - View administration history
  - GET /api/health-entries/export - Export CSV
- **Scheduling**: Auto-calculates next due dates (daily/weekly/monthly/custom)
- **UI**: Tabbed dashboard (All/Medications/Preventives/Vaccines), entry cards with frequency badges, mark-taken button, add/edit form with multi-pet selector (FilterChip chips, Select All/Clear, creates 1 entry per selected pet)

## Weight Tracking Feature
- **Database**: PostgreSQL weight_entries table (id, pet_id, date, weight, notes, created_at)
- **Relationship**: 1 pet -> many weight entries (via pet_id)
- **API Endpoints**:
  - GET /api/weight-entries?pet_id=X - List weight entries sorted by date ASC
  - POST /api/weight-entries - Create weight entry
  - PUT /api/weight-entries/:id - Update weight entry
  - DELETE /api/weight-entries/:id - Delete weight entry
  - GET /api/weight-entries/latest?pet_id=X - Get latest weight entry
- **UI**: Collapsible ExpansionTile on pet detail screen with line chart (fl_chart), chronological entry list with delete, add entry bottom sheet (date picker, weight, notes)
- **Profile integration**: Weight chip in pet profile card shows latest tracked weight (falls back to pet.weight if no entries)
- **Architecture**: Clean architecture (domain/data/presentation) with Riverpod providers, following same patterns as health tracking feature

## Veterinarian Feature
- **Database**: PostgreSQL vets table (id, name, phone, email, website, address, notes)
- **Relationship**: 1 vet -> many pets (via vetId stored in pet's SharedPreferences data)
- **API Endpoints**:
  - GET /api/vets - List all vets
  - POST /api/vets - Create vet (name required, rest optional)
  - GET /api/vets/:id - Get single vet
  - PUT /api/vets/:id - Update vet
  - DELETE /api/vets/:id - Delete vet
- **UI**: Vet list screen with cards, add/edit form, vet dropdown in pet form, vet info card on pet detail screen

## Notification Feature
- **Database**: PostgreSQL notifications table (id, user_id, pet_id, health_entry_id, title, message, type, is_read, created_at) + notification_preferences table (user_id, email_reminders_enabled, reminder_days_before)
- **Server-side check**: POST /api/notifications/check-due queries health_entries where next_due_date <= NOW() + reminder_days, creates notification records (deduplicated within 1 day), optionally sends email if enabled
- **Email reminders**: Stub function logs email details; requires SENDGRID_API_KEY env var for actual sending
- **API Endpoints**:
  - GET /api/notifications - List notifications for authenticated user (sorted newest first)
  - GET /api/notifications/unread-count - Get unread count
  - PUT /api/notifications/:id/read - Mark single notification as read
  - PUT /api/notifications/read-all - Mark all as read
  - GET /api/notifications/preferences - Get user notification preferences
  - PUT /api/notifications/preferences - Update preferences (email_reminders_enabled, reminder_days_before)
  - POST /api/notifications/check-due - Check for due/overdue entries and create notifications
- **Frontend**: Notification bell icon with unread badge in pet list app bar; notifications screen grouped by date; notification settings screen with email toggle and reminder days selector
- **Architecture**: Clean architecture (domain/data/presentation) with Riverpod providers, following same patterns as health tracking feature
- **Future**: Local push notifications section shown in settings as placeholder for native mobile app migration

## Sharing Feature
- **Database**: PostgreSQL shared_pets table (id, share_code, pet_data JSONB, pet_id, created_at, updated_at)
- **Flow**: User taps share on pet detail → app sends pet data to server → server stores in shared_pets and returns 8-char share code → user copies link → recipient opens `/shared/:code` → read-only view of pet profile + health entries + vet info
- **API Endpoints**:
  - POST /api/share - Create/update share (sends pet JSON + pet_id, returns share_code; re-shares update existing)
  - GET /api/share/:code - Get shared pet data (returns pet, health_entries, vet)
- **UI**: Share button in pet detail app bar, dialog with copyable link, SharedPetScreen (read-only view)

## Deployment Strategy
Root pubspec.yaml is a pure Dart project with postgres, dart_jsonwebtoken, and dbcrypt packages (no Flutter deps). Build step: `dart compile exe bin/server.dart -o bin/server`. Run step: `./bin/server`. The compiled binary serves both API endpoints and pre-built Flutter web files from `deploy/public/`. Deployment type: Autoscale. SSL mode auto-detected (disabled locally, required in deployment).

## Tech Stack
- Flutter 3.32.0, Dart 3.8.0
- flutter_riverpod for state management
- go_router for navigation
- shared_preferences for pet profile storage + auth token persistence
- PostgreSQL (via postgres package) for health tracking, vets, users, refresh tokens
- dart_jsonwebtoken for JWT access tokens
- dbcrypt for bcrypt password hashing
- intl for date formatting
- fl_chart for interactive weight tracking charts
- http package for Flutter-to-API communication
- image_picker for photo selection
- mockito for test mocking
- Material 3 design system with deep purple/violet theme

## Key Commands
- `cd flutter_app && flutter pub get` - Install Flutter dependencies
- `cd flutter_app && flutter build web --release` - Build web release
- `dart run bin/server.dart` - Start API + static file server
- `cd flutter_app && flutter test` - Run all tests
- `cd flutter_app && flutter analyze` - Lint/analyze code

## User Preferences
- Clean architecture with feature-driven structure
- TDD/BDD with comprehensive testing
- Full dartdoc documentation
- Production-ready CI setup
