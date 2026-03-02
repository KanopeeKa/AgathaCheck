# Agatha (PetProfileApp)

## Overview
Agatha is a modular Flutter application designed for comprehensive pet management. It allows users to manage pet profiles, track health, log weight, and maintain veterinarian contacts. The application aims to provide a centralized platform for pet owners, offering features like robust authentication, in-app notifications for health events, and the ability to generate detailed pet reports. The project vision is to offer a production-ready, scalable solution for pet care management, with future potential for mobile native and sharing capabilities.

## User Preferences
- Clean architecture with feature-driven structure
- TDD/BDD with comprehensive testing
- Full dartdoc documentation
- Production-ready CI setup

## System Architecture
The application follows a clean architecture approach, separating concerns into data, domain, and presentation layers within feature modules (e.g., `auth`, `pet_profile`, `health_tracking`). The UI adheres to Material 3 design principles, utilizing a deep purple/violet theme. Navigation is managed using GoRouter.

**Key Technical Implementations & Features:**
- **Pet Profile Management**: CRUD operations for pet profiles, including linking vets and health entries. Uses `SharedPreferences` for local pet data storage.
- **Authentication & User Profile**: JWT-based email/password authentication with signup, login, refresh, logout, profile management, and password change. Enhanced user profile with first/last name, category (Pet Guardian / Professional Multi Pet), bio, and photo upload. Profile card displayed on "My Details" screen with edit bottom sheet. Profile info shared with pet-sharing recipients. Tokens stored in `SharedPreferences`.
- **Health Tracking**: Comprehensive health entry management (medications, preventives, vaccines) with scheduling, photo attachments, and a tabbed dashboard view. Data stored in PostgreSQL.
- **Weight Tracking**: Per-pet weight history with line charts and unit selection (kg/lb). Data stored in PostgreSQL.
- **Veterinarian Management**: CRUD operations for veterinarian contacts, linkable to individual pets. Data stored in PostgreSQL.
- **Notification System**: In-app notification center with server-side due-entry checking and email reminder capabilities. Data stored in PostgreSQL.
- **Sharing Feature**: Allows sharing pet profiles and health data via a unique code for read-only access. Shared views include owner profile card (name, category, bio, photo). Data stored in PostgreSQL.
- **Pet Report Generation**: Generates comprehensive PDF reports for individual pets, including customizable sections for profile, weight tracking, and health events.
- **Deployment**: The Flutter web frontend is served statically by a Dart API server, which is AOT compiled for production.

## External Dependencies
- **Flutter**: Frontend framework
- **flutter_riverpod**: State management
- **go_router**: Navigation
- **shared_preferences**: Local storage for pet profiles and auth tokens
- **PostgreSQL**: Primary database for health entries, vets, users, weight entries, and notifications (via `postgres` package)
- **dart_jsonwebtoken**: JWT access token handling
- **dbcrypt**: bcrypt password hashing
- **intl**: Date formatting
- **fl_chart**: Interactive charts for weight tracking
- **http**: For Flutter-to-API communication
- **image_picker**: Photo selection for health entries
- **pdf**, **printing**: PDF generation and sharing