# PetProfileApp

## Overview
A modular Flutter application for managing pet profiles and health tracking using clean architecture. Built with Material 3, Riverpod state management, GoRouter navigation, SharedPreferences local storage for pets, and PostgreSQL for health entries.

## Current State
- Pet profile feature fully implemented with CRUD operations (SharedPreferences)
- Health tracking feature (MVP) with medications, preventives, vaccines (PostgreSQL)
- API server with REST endpoints for health entries
- 74 tests passing (unit, widget, integration)
- Deployed as static Flutter web files served by a Dart API server

## Project Architecture
```
bin/server.dart        - Dart API server + static file server
deploy/public/         - Pre-built Flutter web files (static assets)
flutter_app/           - Flutter source code (development)
  lib/
    core/              - App-wide: theme, router, constants
    features/
      pet_profile/     - Pet CRUD with data/domain/presentation layers
      health_tracking/ - Health tracking with data/domain/presentation layers
  test/                - Unit and widget tests (74 total)
  test_integration/    - Integration tests
  web/                 - Flutter web template
  pubspec.yaml         - Flutter dependencies
pubspec.yaml           - Root: pure Dart + postgres for deployment
```

## Health Tracking Feature
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

## Deployment Strategy
Root pubspec.yaml is a pure Dart project with postgres package (no Flutter deps), allowing `dart pub get` to succeed in deployment. The Dart server in `bin/server.dart` serves both API endpoints and pre-built Flutter web files from `deploy/public/`. Deployment type: Autoscale.

## Tech Stack
- Flutter 3.32.0, Dart 3.8.0
- flutter_riverpod for state management
- go_router for navigation
- shared_preferences for pet profile storage
- PostgreSQL (via postgres package) for health tracking
- http package for Flutter-to-API communication
- image_picker for photo selection
- mockito for test mocking
- Material 3 design system with teal theme

## Key Commands
- `cd flutter_app && flutter pub get` - Install Flutter dependencies
- `cd flutter_app && flutter build web --release` - Build web release
- `dart run bin/server.dart` - Start API + static file server
- `cd flutter_app && flutter test` - Run all tests (74)
- `cd flutter_app && flutter analyze` - Lint/analyze code

## User Preferences
- Clean architecture with feature-driven structure
- TDD/BDD with comprehensive testing
- Full dartdoc documentation
- Production-ready CI setup
