# PetProfileApp


A modular Flutter application for managing pet profiles, built with clean architecture principles and feature-driven design.

## Modular Structure (2024 Refactor)

This codebase is now fully modularized for maintainability, testability, and scalability. Key principles:

- **UI is split into small, reusable widgets** (see `lib/features/.../widgets/`)
- **Business logic is extracted into controllers/services** (see `lib/features/.../controllers/` and `lib/features/.../services/`)
- **Screens are thin, composed of widgets and controllers** (see `lib/features/.../screens/`)
- **Tests are provided for all major widgets, screens, and controllers** (see `test/features/.../widgets/`, `test/features/.../screens/`, etc.)

### Example Structure

```
lib/
    features/
        my_details/
            controllers/
                my_details_controller.dart
            screens/
                my_details_screen.dart
            widgets/
                profile_header_card.dart
                change_password_form.dart
                account_actions_section.dart
        shared_pet/
            controllers/
                shared_pet_controller.dart
            screens/
                shared_pet_screen.dart
            widgets/
                shared_pet_profile_card.dart
                shared_pet_accept_section.dart
                shared_pet_owner_card.dart
                shared_pet_vet_card.dart
                shared_pet_health_entry_card.dart
        health_dashboard/
            controllers/
                health_dashboard_controller.dart
            screens/
                health_dashboard_screen.dart
            widgets/
                health_dashboard_actions.dart
    core/
        ...
```

### Testing Structure

```
test/
    features/
        my_details/
            widgets/
                profile_header_card_test.dart
                change_password_form_test.dart
                account_actions_section_test.dart
            screens/
                my_details_screen_test.dart
        shared_pet/
            widgets/
                shared_pet_profile_card_test.dart
                shared_pet_accept_section_test.dart
                shared_pet_owner_card_test.dart
                shared_pet_vet_card_test.dart
                shared_pet_health_entry_card_test.dart
            screens/
                shared_pet_screen_test.dart
        health_dashboard/
            widgets/
                health_dashboard_actions_test.dart
            screens/
                health_dashboard_screen_test.dart
```

All new and refactored code is covered by widget and screen tests. Run `flutter test` to validate.


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
flutter test test/features/pet_profile/presentation/integration/

# Analyze code
flutter analyze

# Generate documentation
dart doc
```


## Legacy Structure

The previous structure (see below) has been replaced by the modular approach above. For legacy code, see the `pet_profile` feature as an example of the old organization.

```
lib/
    features/
        pet_profile/
            data/
            domain/
            presentation/
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
