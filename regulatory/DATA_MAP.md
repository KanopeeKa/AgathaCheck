# Agatha Track — Data Map

## 1. Personal Data Fields Collected

### 1.1 Users Table

| Field | Type | Purpose | Sensitive |
|-------|------|---------|-----------|
| `id` | Integer (auto) | Internal user identifier | No |
| `email` | VARCHAR(255) | Authentication, account identification, communication | Yes |
| `password_hash` | VARCHAR(255) | Authentication (bcrypt-hashed, never stored in plaintext) | Yes |
| `name` | VARCHAR(255) | Display name | Yes |
| `first_name` | VARCHAR(100) | User profile personalisation | Yes |
| `last_name` | VARCHAR(100) | User profile personalisation | Yes |
| `category` | VARCHAR(50) | User type classification (e.g. `pet_guardian`) | No |
| `bio` | TEXT | User-provided biography | Yes |
| `photo_url` | TEXT | Profile photo URL/path | Yes |
| `locale` | VARCHAR(10) | Language preference (`en`, `fr`) | No |
| `created_at` | TIMESTAMPTZ | Account creation timestamp | No |
| `updated_at` | TIMESTAMPTZ | Last profile update timestamp | No |

### 1.2 Pets Table

| Field | Type | Purpose | Sensitive |
|-------|------|---------|-----------|
| `id` | VARCHAR(255) | Unique pet identifier (UUID) | No |
| `user_id` | INTEGER | Owner reference | No |
| `name` | VARCHAR(255) | Pet name | Yes |
| `species` | VARCHAR(100) | Pet species | No |
| `breed` | VARCHAR(255) | Pet breed | No |
| `age` | DOUBLE PRECISION | Pet age (legacy, calculated from DOB) | No |
| `date_of_birth` | DATE | Pet date of birth | No |
| `weight` | DOUBLE PRECISION | Current weight | No |
| `gender` | VARCHAR(50) | Pet gender | No |
| `bio` | TEXT | Pet biography/notes | Yes |
| `insurance` | TEXT | Insurance information | Yes |
| `neutered_date` | DATE | Neutering date | No |
| `neuter_dismissed` | BOOLEAN | Whether neuter reminder is dismissed | No |
| `chip_id` | VARCHAR(255) | Microchip identification number | Yes |
| `chip_dismissed` | BOOLEAN | Whether chip reminder is dismissed | No |
| `photo_path` | TEXT | Pet photo file path | No |
| `vet_id` | VARCHAR(255) | Associated veterinarian | No |
| `color_value` | BIGINT | UI colour assignment | No |
| `passed_away` | BOOLEAN | Memorial status | No |
| `organization_id` | INTEGER | Associated organisation | No |
| `created_at` | TIMESTAMPTZ | Record creation timestamp | No |
| `updated_at` | TIMESTAMPTZ | Last update timestamp | No |

### 1.3 Health Entries (via health_entries table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | UUID | Entry identifier |
| `pet_id` | VARCHAR(255) | Associated pet |
| `type` | VARCHAR | Entry type (medication, preventive, vet_visit, procedure) |
| `frequency` | VARCHAR | Scheduling frequency |
| `frequency_interval` | INTEGER | Custom frequency interval |
| `repeat_end_date` | DATE | End date for recurring entries |
| `remind_days_before` | INTEGER | Reminder lead time |
| `health_issue_id` | INTEGER | Linked health issue |

### 1.4 Health Issues (health_issues table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | SERIAL | Issue identifier |
| `pet_id` | VARCHAR(255) | Associated pet |
| `title` | VARCHAR(255) | Issue title |
| `description` | TEXT | Issue description |
| `start_date` | DATE | Issue start date |
| `end_date` | DATE | Issue resolution date |

### 1.5 Health Event Photos (health_event_photos table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | SERIAL | Photo identifier |
| `event_id` | VARCHAR(255) | Associated health event |
| `photo_path` | TEXT | File path to uploaded photo |
| `caption` | TEXT | User-provided caption |

### 1.6 Weight Entries (weight_entries table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | SERIAL | Entry identifier |
| `pet_id` | VARCHAR(255) | Associated pet |
| `date` | DATE | Measurement date |
| `weight` | DOUBLE PRECISION | Weight value |
| `notes` | TEXT | User notes |

### 1.7 Veterinarian Data (stored in shared_pets / pet data)

Veterinarian contact information stored includes: name, clinic, phone, email, address, and notes.

### 1.8 Notifications (notifications table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | SERIAL | Notification identifier |
| `user_id` | INTEGER | Recipient user |
| `pet_id` | VARCHAR(255) | Related pet |
| `health_entry_id` | VARCHAR(255) | Related health entry |
| `organization_id` | INTEGER | Related organisation |
| `title` | VARCHAR(500) | Notification title |
| `message` | TEXT | Notification body |
| `type` | VARCHAR(50) | Notification type |
| `is_read` | BOOLEAN | Read status |

### 1.9 Notification Preferences (notification_preferences table)

| Field | Type | Purpose |
|-------|------|---------|
| `user_id` | INTEGER | User reference |
| `email_reminders_enabled` | BOOLEAN | Email reminder opt-in |
| `reminder_days_before` | INTEGER | Default reminder lead time |
| `notify_completed` | BOOLEAN | Completion notification preference |
| `muted_pet_ids` | TEXT | Comma-separated list of muted pet IDs |

### 1.10 Sharing & Access (pet_access table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | SERIAL | Access record identifier |
| `pet_id` | VARCHAR(255) | Shared pet |
| `user_id` | INTEGER | User with access |
| `role` | VARCHAR(20) | Access role (guardian, shared, pending_shared) |
| `invited_by` | INTEGER | Inviting user |
| `share_code` | VARCHAR(12) | Unique share link code |
| `target_organization_id` | INTEGER | Target organisation for shared pet |
| `hidden` | BOOLEAN | Whether shared pet is hidden from view |

### 1.11 Organisations (organizations table)

| Field | Type | Purpose |
|-------|------|---------|
| `id` | SERIAL | Organisation identifier |
| `name` | VARCHAR(255) | Organisation name |
| `type` | VARCHAR(50) | Organisation type (professional, charity) |
| `email` | VARCHAR(255) | Contact email |
| `phone` | VARCHAR(100) | Contact phone |
| `address` | TEXT | Physical address |
| `website` | VARCHAR(255) | Website URL |
| `bio` | TEXT | Organisation description |
| `photo_url` | TEXT | Logo/photo URL |
| `created_by` | INTEGER | Creator user ID |

### 1.12 Organisation Members (organization_users table)

| Field | Type | Purpose |
|-------|------|---------|
| `organization_id` | INTEGER | Organisation reference |
| `user_id` | INTEGER | Member user reference |
| `role` | VARCHAR(20) | Role (admin, super_user, member, pending_member, pending_super_user) |
| `invited_by` | INTEGER | Inviting user |
| `invite_code` | VARCHAR(20) | Invitation code |
| `invite_expires_at` | TIMESTAMPTZ | Invitation expiry |

### 1.13 Archived Pets (archived_pets table)

| Field | Type | Purpose |
|-------|------|---------|
| `organization_id` | INTEGER | Source organisation |
| `user_id` | INTEGER | Source user |
| `pet_id` | VARCHAR(255) | Original pet ID |
| `pet_name` | VARCHAR(255) | Pet name at time of archival |
| `species` | VARCHAR(100) | Species at time of archival |
| `pdf_data` | TEXT | Archived PDF report data |
| `transfer_type` | VARCHAR(50) | Type of transfer |
| `transferred_to_user_id` | INTEGER | Recipient user |
| `transferred_to_org_id` | INTEGER | Recipient organisation |
| `notes` | TEXT | Transfer notes |

### 1.14 Family Events (family_events table)

| Field | Type | Purpose |
|-------|------|---------|
| `pet_id` | VARCHAR(255) | Associated pet |
| `organization_id` | INTEGER | Associated organisation |
| `assigned_to_user_id` | INTEGER | Assigned caretaker |
| `from_date` | DATE | Event start date |
| `to_date` | DATE | Event end date |
| `notes` | TEXT | Event notes |
| `created_by` | INTEGER | Creator user |

### 1.15 Authentication Tokens

| Table | Fields | Purpose |
|-------|--------|---------|
| `refresh_tokens` | `user_id`, `token`, `expires_at` | JWT refresh token storage |
| `password_reset_tokens` | `user_id`, `code`, `expires_at`, `used` | Password reset flow |

### 1.16 Local Storage (Client-Side)

| Key | Purpose |
|-----|---------|
| SharedPreferences: pet data cache | Offline access to pet profiles |
| SharedPreferences: locale | Language preference |
| SharedPreferences: consent state | Cookie/consent banner preferences |

---

## 2. SDKs and Libraries Used

### 2.1 Server-Side (Dart)

| Package | Version | Purpose | Data Access |
|---------|---------|---------|-------------|
| `postgres` | 3.5.7 | PostgreSQL database driver | Full database access |
| `dart_jsonwebtoken` | ^3.3.1 | JWT token creation and verification | User identity claims |
| `dbcrypt` | ^2.0.0 | Password hashing (bcrypt) | Password hashes only |

### 2.2 Client-Side (Flutter)

| Package | Version | Purpose | Data Access |
|---------|---------|---------|-------------|
| `flutter_riverpod` | ^2.6.1 | State management | In-memory state only |
| `go_router` | ^14.8.1 | Navigation/routing | No data access |
| `shared_preferences` | ^2.3.4 | Local key-value storage | Local device storage |
| `image_picker` | ^1.1.2 | Photo selection from device | Device camera/gallery |
| `http` | ^1.6.0 | HTTP client for API calls | API request/response data |
| `intl` | ^0.20.2 | Internationalisation and date formatting | Locale data |
| `fl_chart` | ^0.69.2 | Chart rendering (weight tracking) | In-memory chart data |
| `pdf` | ^3.11.2 | PDF document generation | Pet report data |
| `printing` | ^5.13.4 | PDF printing/sharing | Generated PDF documents |
| `web` | ^1.1.0 | Web platform interop | Browser APIs |
| `purchases_flutter` | ^9.12.3 | RevenueCat subscription SDK | Subscription/entitlement status |
| `purchases_ui_flutter` | ^9.12.3 | RevenueCat paywall UI | Subscription UI |
| `uuid` | ^4.5.1 | UUID generation | No personal data |
| `cupertino_icons` | ^1.0.8 | iOS-style icons | No data access |

---

## 3. Data Flow

```
┌─────────────────┐         HTTPS/REST API          ┌──────────────────┐
│                 │  ──────────────────────────────► │                  │
│  Flutter Web    │  JSON requests with JWT auth     │  Dart API Server │
│  Client         │  ◄────────────────────────────── │  (bin/server.dart)│
│                 │  JSON responses                  │                  │
└────────┬────────┘                                  └────────┬─────────┘
         │                                                    │
         │ Local Storage                                      │ SQL Queries
         ▼                                                    ▼
┌─────────────────┐                                  ┌──────────────────┐
│ SharedPreferences│                                  │   PostgreSQL     │
│ (device-local)  │                                  │   Database       │
└─────────────────┘                                  └──────────────────┘

         │                                                    │
         │                                                    │ File Storage
         │                                                    ▼
         │                                           ┌──────────────────┐
         │                                           │  /uploads/       │
         │                                           │  (server disk)   │
         └───────────────────────────────────────────►└──────────────────┘
                    Photo uploads via multipart POST
```

### 3.1 Authentication Flow
1. User submits email + password via HTTPS POST
2. Server hashes password with bcrypt, stores in `users` table
3. Server returns JWT access token (30 min) + refresh token (30 days)
4. Client stores tokens in memory, sends access token in `Authorization` header
5. Refresh tokens stored in `refresh_tokens` table with expiry

### 3.2 Data Storage Flow
1. Client sends JSON payloads to REST API endpoints
2. Server validates JWT, extracts `user_id` from token claims
3. Server executes parameterised SQL queries against PostgreSQL
4. Uploaded files (photos) stored on server filesystem under `/uploads/`
5. Client caches pet data locally via SharedPreferences

### 3.3 Photo Upload Flow
1. User selects photo via `image_picker` (camera or gallery)
2. Client sends multipart POST to `/api/health-entries/:id/photos` or similar
3. Server stores file in `/uploads/health/<event_id>/` directory
4. Server records file path in `health_event_photos` table
5. Client accesses photos via `/uploads/` static file serving

---

## 4. Third-Party Data Sharing

### 4.1 RevenueCat (Subscription Management)

| Aspect | Detail |
|--------|--------|
| **SDK** | `purchases_flutter` v9.12.3 |
| **Data Shared** | Anonymous app user ID, purchase transactions, entitlement status |
| **Purpose** | In-app subscription management and entitlement verification |
| **Legal Basis** | Contractual necessity (Art. 6(1)(b) GDPR) |
| **Data Location** | RevenueCat servers (US, with EU data processing) |
| **Privacy Policy** | https://www.revenuecat.com/privacy |
| **DPA Available** | Yes |

### 4.2 No Other Third-Party Data Sharing

The application does **not** currently integrate:
- Analytics SDKs (no Google Analytics, Firebase Analytics, Mixpanel, etc.)
- Advertising SDKs (no ad networks)
- Social login providers (no Google/Apple/Facebook sign-in)
- Crash reporting SDKs (no Sentry, Crashlytics, etc.)
- Push notification services (notifications are in-app only)
- CDN or image hosting services (photos stored on own server)

All data processing occurs on the application's own server infrastructure with the sole exception of RevenueCat for subscription management.

---

## 5. Data Categories Summary

| Category | Examples | Storage | Retention |
|----------|----------|---------|-----------|
| **Account Data** | Email, name, password hash | PostgreSQL | Until account deletion |
| **Profile Data** | First/last name, bio, photo, category | PostgreSQL + filesystem | Until account deletion |
| **Pet Data** | Pet name, species, breed, DOB, chip ID, insurance | PostgreSQL | Until pet or account deletion |
| **Health Data** | Medications, vet visits, procedures, health issues | PostgreSQL | Until entry or account deletion |
| **Weight Data** | Weight measurements and dates | PostgreSQL | Until entry or account deletion |
| **Photo Data** | Health event photos, profile photos | Server filesystem | Until entry or account deletion |
| **Veterinarian Data** | Vet name, clinic, contact details | PostgreSQL | Until vet or account deletion |
| **Notification Data** | Reminders, alerts, system messages | PostgreSQL | Until read/dismissed or account deletion |
| **Organisation Data** | Org name, contact, membership | PostgreSQL | Until org deletion or membership removal |
| **Sharing Data** | Access grants, share codes | PostgreSQL | Until access revoked or account deletion |
| **Authentication Tokens** | JWT access/refresh tokens | PostgreSQL + memory | 30 min (access) / 30 days (refresh) |
| **Subscription Data** | Purchase status, entitlements | RevenueCat (third-party) | Per RevenueCat retention policy |
| **Local Preferences** | Locale, consent state, cached data | SharedPreferences (device) | Until app uninstall or manual clear |
