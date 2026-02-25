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
- API server with REST endpoints for health entries, vets, sharing, and auth
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
          pet_detail_screen.dart  - Pet profile + vet info + health entries (tabbed)
          pet_form_screen.dart    - Add/edit pet form (with vet dropdown)
      health_tracking/ - Health tracking with data/domain/presentation layers
      vet/             - Vet management with data/domain/presentation layers
      sharing/         - Pet sharing feature
  test/                - Unit and widget tests
  test_integration/    - Integration tests
  web/                 - Flutter web template
  pubspec.yaml         - Flutter dependencies
pubspec.yaml           - Root: pure Dart + postgres + dart_jsonwebtoken + dbcrypt
```

## Navigation / Routes
- `/` - Pet list (home) — shows "Sign In" button when logged out, user avatar menu when logged in
- `/login` - Login screen
- `/signup` - Signup screen
- `/my-details` - User profile + change password
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
- **UI**: User avatar menu in app bar (My Details, Log Out), login/signup screens with logo, My Details screen with profile editing and password change form

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
- **UI**: Tabbed dashboard (All/Medications/Preventives/Vaccines), entry cards with frequency badges, mark-taken button, add/edit form

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
