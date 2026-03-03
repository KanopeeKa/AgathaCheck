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
- **Pet Profile Management**: CRUD operations for pet profiles, including linking vets and health entries. Each pet is assigned a unique color from a 15-color palette (persisted as `colorValue` in JSON). Colors are shown as a circular border ring on pet list cards, a tinted left strip on health entry cards, and a colored left border on the pet detail photo. Fields include: name, species, breed, gender, date of birth (age computed dynamically from DOB), weight, bio, insurance, neutered/spayed date, and ID/microchip number. Age is displayed as "X.X yrs" for pets over 1 year or "N months" for younger pets, recalculated on every render from `dateOfBirth`. The pet form uses a date picker (not a text field) for DOB. DB column: `date_of_birth DATE`. **Server-side pet storage** via `pets` PostgreSQL table with authenticated CRUD API (`GET/POST/PUT/DELETE /api/pets`). Pets are synced from server on login; local `SharedPreferences` serves as cache. `PetRepositoryImpl` merges remote and local data: server is primary, local-only pets are pushed to server, base64 photo paths are preserved from local cache. `PetRemoteDataSource` handles all server communication with JWT Bearer auth. Pet deletion cascades to all server-side data via `DELETE /api/pets/:petId/data` (health entries, health issues, health event photos, weight entries, notifications, pet_access, shared_pets).
- **Identification Reminder**: If a pet has no ID and the user hasn't dismissed the reminder, a species-specific reminder card appears on the pet detail screen. Messages are tailored per species (e.g., microchip for dogs/cats/ferrets/rabbits, passport for horses, leg ring for birds, tank label for fish, photo ID for hamsters). User can "Snooze" or dismiss (sets `chipDismissed = true`). Species list: Dog, Cat, Bird, Fish, Rabbit, Hamster, Ferret, Horse / Poney, Other. Neutering field is hidden for Bird, Fish, Hamster, Ferret, and Horse / Poney (configured in `AppConstants.speciesWithoutNeutering`). Horse/Poney uses a 🐴 emoji icon via `speciesIconWidget()` since Material Icons has no horse icon; all other species use Material `IconData`. `AppConstants.speciesIconWidget()` returns a `Widget` (emoji Text for horse, Icon for others).
- **Passed Away Memorial**: "Passed Away" button (heart icon) on pet cards allows guardians to mark a pet as having crossed the rainbow bridge. Two-step dialog flow: confirmation, then a sober condolence message. Notifies all shared users via `POST /api/pets/:petId/passed-away` (creates 'memorial' type notifications). Clears pending reminder/overdue notifications. Sets `passedAway = true` and `colorValue = 0xFFFFFFFF` (white). Pet photo gets a semi-transparent rainbow wings overlay (`assets/rainbow_wings.png`) with a lighten color filter on both the pet list card and pet detail screen. Profile is kept as an archive.
- **Authentication & User Profile**: JWT-based email/password authentication with signup, login, refresh, logout, profile management, password change, and forgot/reset password. Forgot password uses a 6-digit code with 15-minute expiry, rate-limited to 5 requests/hour per email. Two-step UI: enter email → enter code + new password. Routes: `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`. Flutter screen at `/forgot-password` (accessible without login). Enhanced user profile with first/last name, category (Pet Guardian / Professional Multi Pet), bio, and photo upload. Profile card displayed on "My Details" screen with edit bottom sheet. Profile info shared with pet-sharing recipients. Tokens stored in `SharedPreferences`.
- **Health Tracking**: Comprehensive health entry management (medications, preventives, vet visits, other) with scheduling, photo attachments, and a tabbed dashboard view ("Events" page with tabs: All, Medications, Preventives, Vet Visits, Other). Compact card design with pet photo+name strip on left, frequency badge, and "Done [date]" for completed entries. Delete moved to edit form. Frequency uses a two-field system: Interval (1-12) + Period (Day/Week/Month/Year). DB stores `frequency` (enum: once/daily/weekly/monthly/yearly/custom) and `frequency_interval` (INT, default 1). Server mark-taken logic multiplies the period by the interval for next due date calculation. Legacy `custom` frequency with `frequency_days` is preserved for backward compatibility. Data stored in PostgreSQL.
- **Health Issues**: Ongoing health conditions linked to pets (1:n) with optional start/end dates. Each issue can link to multiple health entries (n:n via junction table). Collapsible section in pet detail with create/edit/delete bottom sheets. Health entry form includes optional issue selector dropdown. Data stored in PostgreSQL (`health_issues`, `health_issue_events` tables).
- **Weight Tracking**: Per-pet weight history with line charts and unit selection (kg/lb). Data stored in PostgreSQL.
- **Veterinarian Management**: CRUD operations for veterinarian contacts, linkable to individual pets. Data stored in PostgreSQL.
- **Notification System**: In-app notification center with server-side due-entry checking and email reminder capabilities. Two notification categories: "Due Soon Alerts" (reminder/overdue types, clock icon) and "General" (bell icon, auto-generated on event/issue/share create/update/delete). Per-pet mute option in notification settings (stored server-side in `notification_preferences.muted_pet_ids`). Muted pets are filtered from the notification list and unread count. Data stored in PostgreSQL.
- **Sharing Feature**: Multi-user pet access system with guardian/shared roles. Guardians can invite others via share links, manage access, and toggle roles. Shared users see only the guardian who invited them. Each share link is tied to a specific guardian. `pet_access` table tracks per-user access with roles. Shared pet views include owner profile card. Accept-share flow for logged-in users. Data stored in PostgreSQL.
- **Pet Report Generation**: Generates comprehensive PDF reports for individual pets, including customizable sections for profile, weight tracking, health events, health issues (with linked events), and sharing (access list with roles).
- **Subscription (RevenueCat)**: In-app subscription management via RevenueCat SDK (`purchases_flutter`, `purchases_ui_flutter`). Entitlement: "Agatah Check Unlimited". On web: gracefully skipped (no-op). On iOS/Android: full initialization, paywall presentation via `RevenueCatUI.presentPaywall()`, customer center via `RevenueCatUI.presentCustomerCenter()`, entitlement checking, purchase restore, and customer info listener. Singleton `RevenueCatService` initialized in `main()`. Auth-synced login/logout via `SubscriptionNotifier` listening to `authProvider`. Subscription screen accessible from My Details. Providers: `subscriptionStatusProvider`, `hasUnlimitedProvider`, `revenueCatServiceProvider`.
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
- **purchases_flutter**, **purchases_ui_flutter**: RevenueCat in-app subscriptions

## SwiftUI Migration Notes
The Dart API server is the shared backend for both Flutter and a future SwiftUI native client. All API responses use consistent `snake_case` JSON field naming (e.g., `access_token`, `refresh_token`, `first_name`, `photo_url`). The server accepts both `snake_case` and `camelCase` input for backward compatibility on refresh/logout endpoints.

**API contract ready for native iOS:**
- Auth: `POST /api/auth/signup`, `/login`, `/refresh`, `/logout`, `GET/PUT /api/auth/me`, `POST /api/auth/me/photo`, `POST /api/auth/change-password`
- Health: `GET/POST /api/health-entries`, `PUT/DELETE /api/health-entries/:id`, `POST /:id/mark-taken`, `GET /:id/history`, photos via multipart
- Health Issues: `GET /api/health-issues?pet_id=X`, `POST /api/health-issues`, `PUT/DELETE /api/health-issues/:id`, `POST /api/health-issues/:id/events`, `DELETE /api/health-issues/:id/events/:entryId`
- Weight: `GET/POST /api/weight-entries`, `PUT/DELETE /:id`, `GET /latest`
- Vets: `GET/POST /api/vets`, `PUT/DELETE /:id`
- Notifications: `GET /api/notifications`, `GET /unread-count`, `PUT /read-all`, `GET/PUT /preferences`, `POST /check-due`
- Sharing: `POST /api/share`, `GET /api/share/:code`, `POST /api/share/:code/accept`, `GET /api/pets/:petId/access`, `PUT /api/pets/:petId/access/:userId/role`, `DELETE /api/pets/:petId/access/:userId`
- Pets: `GET/POST /api/pets`, `PUT/DELETE /api/pets/:id`, `POST /api/pets/:petId/passed-away`, `DELETE /api/pets/:petId/data`

**SwiftUI-specific considerations:**
- **Tokens**: Store in Keychain (not UserDefaults). JWT access tokens expire in 30 min; use refresh flow.
- **Pet profiles**: Stored server-side in `pets` PostgreSQL table. Use `GET/POST/PUT/DELETE /api/pets` with JWT Bearer auth for full cross-device sync.
- **Pet photos**: Currently Base64-encoded in local storage. Migrate to server upload (same pattern as `/api/auth/me/photo`) for cross-device access.
- **Image uploads**: Use standard `multipart/form-data` with field name `photo` (max 2MB).
- **PDF reports**: Re-implement using `UIGraphicsPDFRenderer` or `PDFKit` on iOS; report content logic stays client-side.
- **Dates**: Server returns ISO 8601 strings; use `ISO8601DateFormatter` in Swift.
- **IDs**: Returned as strings in JSON (even when numeric in DB). Use `String` type in Swift models.
- **Platform PDF**: `pdf_saver.dart` uses conditional exports — `pdf_saver_mobile.dart` (printing package share sheet) maps to `UIActivityViewController` in SwiftUI.

## Accessibility
Comprehensive accessibility support is implemented across all 17 screen files:
- **Tooltips**: All IconButtons, FABs, and PopupMenuButtons have descriptive tooltips (39 total)
- **Keys**: Interactive widgets have test-automation Keys following `feature_action` naming convention (53 total)
- **Semantics**: Custom tappable areas, date pickers, and profile cards wrapped with descriptive Semantics labels (44 total)
- **MergeSemantics**: Complex cards (pet card, health entry card, vet card, notification tile, profile card) wrapped for unified screen reader announcements (13 total)
- **ExcludeSemantics**: Decorative icons, dividers, and status indicators that duplicate text content are excluded from the semantic tree (13 total)
- **semanticLabel**: Logo images, pet photos, and meaningful icons have descriptive labels (10 total)
- **Form fields**: All TextFormFields use `labelText` for screen reader compatibility