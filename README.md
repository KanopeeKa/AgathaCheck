# PetProfileApp

A modular Flutter application for managing pet profiles, built with clean architecture principles and feature-driven design.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    PetProfileApp                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌─────────── core/ ───────────┐                     │
│  │  theme/     - Material 3     │                    │
│  │  router/    - GoRouter       │                    │
│  │  utils/     - Constants      │                    │
│  └──────────────────────────────┘                    │
│                                                      │
│  ┌─────── features/pet_profile/ ───────────────────┐ │
│  │                                                  │ │
│  │  ┌── presentation/ ──┐  (UI Layer)              │ │
│  │  │  screens/          │  PetListScreen           │ │
│  │  │  widgets/          │  PetFormScreen           │ │
│  │  │  providers/        │  Riverpod notifiers      │ │
│  │  └───────────────────-┘                          │ │
│  │          │ depends on                            │ │
│  │          ▼                                       │ │
│  │  ┌── domain/ ────────┐  (Business Logic)        │ │
│  │  │  entities/         │  Pet                     │ │
│  │  │  usecases/         │  AddPet, GetAllPets...   │ │
│  │  │  repositories/     │  PetRepository (iface)   │ │
│  │  └───────────────────-┘                          │ │
│  │          │ depends on                            │ │
│  │          ▼                                       │ │
│  │  ┌── data/ ──────────┐  (Data Layer)            │ │
│  │  │  models/           │  PetModel (JSON)         │ │
│  │  │  datasources/      │  SharedPreferences       │ │
│  │  │  repositories/     │  PetRepositoryImpl       │ │
│  │  └───────────────────-┘                          │ │
│  │                                                  │ │
│  └──────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## Tech Stack

| Category           | Library              |
|--------------------|----------------------|
| State Management   | flutter_riverpod     |
| Navigation         | go_router            |
| Local Storage      | shared_preferences   |
| Image Picking      | image_picker         |
| Testing            | flutter_test, mockito|
| Design System      | Material 3           |

## Getting Started

### Prerequisites

- Flutter SDK 3.8+
- Dart 3.8+

### Setup

```bash
# Install dependencies
flutter pub get

# Generate mock files for tests
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app (web)
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0

# Run all tests
flutter test

# Run integration tests
flutter test test_integration/

# Analyze code
flutter analyze

# Generate documentation
dart doc
```

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── theme/app_theme.dart           # Material 3 theme
│   ├── router/app_router.dart         # GoRouter config
│   └── utils/constants.dart           # App constants
└── features/
    └── pet_profile/
        ├── pet_profile.dart           # Public API barrel file
        ├── data/
        │   ├── models/pet_model.dart
        │   ├── datasources/pet_local_datasource.dart
        │   └── repositories/pet_repository_impl.dart
        ├── domain/
        │   ├── entities/pet.dart
        │   ├── repositories/pet_repository.dart
        │   └── usecases/
        │       ├── add_pet.dart
        │       ├── delete_pet.dart
        │       ├── get_all_pets.dart
        │       └── update_pet.dart
        └── presentation/
            ├── providers/pet_providers.dart
            ├── screens/
            │   ├── pet_form_screen.dart
            │   └── pet_list_screen.dart
            └── widgets/pet_card.dart

test/
├── features/pet_profile/
│   ├── data/
│   │   ├── models/pet_model_test.dart
│   │   └── repositories/pet_repository_impl_test.dart
│   ├── domain/
│   │   ├── entities/pet_test.dart
│   │   └── usecases/
│   │       ├── add_pet_test.dart
│   │       ├── delete_pet_test.dart
│   │       ├── get_all_pets_test.dart
│   │       └── update_pet_test.dart
│   └── presentation/
│       └── widgets/pet_card_test.dart

test_integration/
└── pet_profile_flow_test.dart
```

## Features

- Add, edit, and delete pet profiles
- Photo picker for pet images
- Form validation for required fields
- Material 3 design with teal color scheme
- Local-only storage (no backend required)
- Clean architecture with clear layer separation
- Comprehensive test coverage

## CI/CD

GitHub Actions workflow at `.github/workflows/ci.yml` runs:
1. **Lint** - Static analysis with `flutter analyze`
2. **Test** - Unit, widget, and integration tests with coverage
3. **Build** - Web release build with artifact upload

## License

This project is private and not published to pub.dev.
