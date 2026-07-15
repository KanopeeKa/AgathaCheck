# Agatha Track

A modular Flutter web application for comprehensive pet management, built with clean architecture principles and feature-driven design. Backed by a Postgres database and an interchangeable Dart **or** Node.js API server.

> The historical project name was **PetProfileApp**; the product is now **Agatha Track**. Some legacy paths and class names still use the old name.

## Modular Structure (2024 Refactor)

This codebase is now fully modularized for maintainability, testability, and scalability. Key principles:

- **UI is split into small, reusable widgets** (see `lib/features/.../widgets/`)
- **Business logic is extracted into controllers/services** (see `lib/features/.../controllers/` and `lib/features/.../services/`)
- **Screens are thin, composed of widgets and controllers** (see `lib/features/.../screens/`)
- **Tests cover domain logic, data models, providers/controllers, and key widgets**, with integration flows for critical paths (see `test/features/.../`). Coverage varies by feature and is strongest at the data/domain and provider layers.

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

Tests span domain, data, provider/controller, and widget layers, with integration flows for critical paths; coverage depth varies by feature. Run `flutter test` to validate.


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

## Documentation

- [`API.md`](API.md) — REST endpoint reference (authoritative section at the top)
- [`docs/calendar-dates.md`](docs/calendar-dates.md) — calendar-date wire format (`YYYY-MM-DD`)
- [`docs/org-fostering-strategy.md`](docs/org-fostering-strategy.md) — organisation roles, fostering increments, and permission matrix
- [`docs/technical-debt.md`](docs/technical-debt.md) — deferred work and low-priority improvements

## Tech Stack

| Category           | Library                                  |
|--------------------|------------------------------------------|
| State Management   | flutter_riverpod                         |
| Navigation         | go_router                                |
| Local Storage      | shared_preferences                       |
| HTTP Client        | http                                     |
| Image Picking      | image_picker                             |
| Charts             | fl_chart                                 |
| PDF                | pdf, printing                            |
| Payments / Subs    | purchases_flutter, purchases_ui_flutter  |
| Localization       | intl (EN / FR)                           |
| Testing            | flutter_test, mockito                    |
| Design System      | Material 3 (deep purple / violet theme)  |
| Backend (Dart)     | shelf, postgres, dart_jsonwebtoken       |
| Backend (Node.js)  | express, pg, jsonwebtoken, bcrypt        |
| Database           | PostgreSQL 14+                           |

## Getting Started

> **Repository layout.** The canonical Flutter app lives in **`flutter_app/`** and
> the backend in **`server/`**. Run all Flutter commands from `flutter_app/` and
> all backend commands from `server/`.

### Prerequisites

- Flutter SDK 3.8+ / Dart 3.8+ (CI pins Flutter 3.32.0)
- Node.js 20+ (backend)
- PostgreSQL 14+

### Frontend (Flutter web)

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Generate mock files for tests (required before analyze/test)
dart run build_runner build --delete-conflicting-outputs

# Analyze, test, build
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons

# Run the app against the backend (see below). On web the app calls the API at
# `/backend` on the same origin, so for an end-to-end run serve the built web
# bundle from the backend rather than the Flutter dev server.
```

### Backend (Node.js API + PostgreSQL)

```bash
cd server
npm ci

# Configure the database connection (see server/.env.example):
#   PGUSER / PGPASSWORD / PGHOST / PGPORT / PGDATABASE  (or a single DATABASE_URL)
#   JWT_SECRET  — required in production; a dev fallback is used otherwise
# Apply the schema, then start the API (serves the Flutter web build + API on
# the same origin at http://localhost:3000):
node scripts/migrate.js up      # or: dart run bin/migrate.dart up
node bin/start.js               # note: `npm start` only exports the app; use bin/start.js
```

The backend ships as two interchangeable implementations sharing one Postgres
schema — Node.js/Express (canonical, Jest-tested) and Dart/Shelf. Run **one** of
them. Backend tests: `npx jest --env=node --forceExit`.


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

- Pet profile CRUD with dynamic age, color assignment, and photo support
- JWT-based authentication, password reset, profile editing
- Health tracking: medications, preventives, vet visits, and ongoing health issues
- Per-pet weight history with line charts
- Veterinarian contact management
- In-app notifications with per-pet mute
- Pet sharing across users (guardian / shared roles, share links, hidden pets)
- Organizations (Professional / Charity) with roles, invites, transfers, archiving, and family events
- Customizable per-pet PDF reports
- Full English / French localization with locale persistence
- GDPR data rights: account deletion, JSON export, consent management
- Observability: tiered audit logging, structured API logs, consent-gated PostHog analytics (see `docs/observability.md`)
- Material 3 design with deep purple / violet theme
- Clean architecture with clear layer separation
- Comprehensive test coverage (Flutter widget/model tests, 380+ backend Jest tests, Dart parity backend)

## Backend & Database

The backend lives in `server/`. Two interchangeable implementations share the same Postgres schema:

- `server/bin/server.dart` — Dart / Shelf (used by the Replit workflow)
- `server/bin/server.js` — Node.js / Express (used by the cPanel deployment)

Database schema is managed by `server/bin/migrate.dart`:

```bash
cd server
dart run bin/migrate.dart status                                # show applied / pending
dart run bin/migrate.dart up                                    # apply pending NNN_*.sql migrations
dart run bin/migrate.dart down                                  # roll back the most recent migration
MIGRATE_CONFIRM=DROP_ALL dart run bin/migrate.dart fresh        # wipe + recreate from canonical v3 schema
```

See `DEPLOYMENT_DB.md` for the full database deployment guide and `DEPLOYMENT_CPANEL_NODEJS.md` for cPanel-specific instructions.

## CI/CD

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR → `main` (+ manual dispatch) | Lint, unit/widget tests, backend Jest, web build |
| `codeql.yml` | PR → `main` (+ weekly schedule) | Static security analysis (JavaScript/TypeScript) |
| `e2e.yml` | manual dispatch | Full Playwright E2E on demand (six localhost shards; not per PR commit) |
| `deploy-uat.yml` | `release/uat-*` | Fast UAT deploy + smoke + E2E gates → `prod-ready` |
| `deploy-prod.yml` | manual dispatch / release | Prod deploy + post-deploy smoke |

See `replit.md` § CI/CD and `e2e/README.md` for the full pipeline.

## License

This project is private and not published to pub.dev.
