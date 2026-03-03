# Agatha (PetProfileApp)

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
- **Sharing Feature**: Multi-user pet access with guardian/shared roles via share links, managed through a `pet_access` table.
- **Organization Support**: Comprehensive management for Professional and Charity organizations, including user roles, pet transfers, and archiving.
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