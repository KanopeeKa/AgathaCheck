# PetProfileApp

## Overview
A modular Flutter application for managing pet profiles using clean architecture. Built with Material 3, Riverpod state management, GoRouter navigation, and SharedPreferences local storage.

## Current State
- First feature (pet_profile) fully implemented with CRUD operations
- Local-only storage (no backend)
- Comprehensive test suite (unit, widget, integration)
- GitHub Actions CI placeholder configured

## Project Architecture
```
lib/
  core/          - App-wide: theme, router, constants
  features/
    pet_profile/ - Feature module with data/domain/presentation layers
```

## Tech Stack
- Flutter 3.32.0, Dart 3.8.0
- flutter_riverpod for state management
- go_router for navigation
- shared_preferences for local storage
- image_picker for photo selection
- mockito for test mocking
- Material 3 design system

## Key Commands
- `flutter pub get` - Install dependencies
- `flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0` - Run web
- `flutter test` - Run all tests
- `flutter analyze` - Lint/analyze code

## User Preferences
- Clean architecture with feature-driven structure
- Comprehensive testing from day one
- Full dartdoc documentation
- Production-ready CI setup
