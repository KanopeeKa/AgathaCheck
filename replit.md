# PetProfileApp

## Overview
A modular Flutter application for managing pet profiles using clean architecture. Built with Material 3, Riverpod state management, GoRouter navigation, and SharedPreferences local storage.

## Current State
- First feature (pet_profile) fully implemented with CRUD operations
- Local-only storage (no backend)
- Comprehensive test suite (unit, widget, integration)
- GitHub Actions CI placeholder configured
- Deployed as static files served by a pure Dart server

## Project Architecture
```
bin/server.dart        - Pure Dart static file server (used for deployment)
deploy/public/         - Pre-built Flutter web files (static assets)
flutter_app/           - Flutter source code (development)
  lib/
    core/              - App-wide: theme, router, constants
    features/
      pet_profile/     - Feature module with data/domain/presentation layers
  test/                - Unit and widget tests
  test_integration/    - Integration tests
  pubspec.yaml         - Flutter dependencies
lib/                   - Legacy Flutter source (kept for reference)
pubspec.yaml           - Root: pure Dart (no Flutter deps) for deployment
```

## Deployment Strategy
Root pubspec.yaml is a pure Dart project with no Flutter dependencies, allowing `dart pub get` to succeed in deployment. The Dart server in `bin/server.dart` serves pre-built Flutter web files from `deploy/public/`. Deployment type: Autoscale.

## Tech Stack
- Flutter 3.32.0, Dart 3.8.0
- flutter_riverpod for state management
- go_router for navigation
- shared_preferences for local storage
- image_picker for photo selection
- mockito for test mocking
- Material 3 design system

## Key Commands
- `cd flutter_app && flutter pub get` - Install Flutter dependencies
- `cd flutter_app && flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0` - Run Flutter web dev
- `dart run bin/server.dart` - Serve pre-built static files
- `cd flutter_app && flutter test` - Run all tests
- `cd flutter_app && flutter analyze` - Lint/analyze code

## User Preferences
- Clean architecture with feature-driven structure
- Comprehensive testing from day one
- Full dartdoc documentation
- Production-ready CI setup
