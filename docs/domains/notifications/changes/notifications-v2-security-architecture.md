---
title: Notifications v2 — account security architecture (PR7)
owner: Engineering
audience: both
status: active
last_updated: 2026-10-05
tags: [notifications, security, account, privacy]
domain: notifications
---

# Account security architecture (PR7)

Companion to [notifications-v2-spec.md](../features/notifications-v2-spec.md) §3.5, FR-ACC-*, FR-IA-7, and decision **N11–N13**. Implementation lives on plan `notifications-v2-pr7-7f3b` phase 2.

## Scope

| In PR7 | Out of PR7 |
|--------|------------|
| A1 `accountNewSignIn`, A2 `accountPasswordChanged`, A3 `accountSignedOutEverywhere`, A6 `accountDeletionRequested` | A4/A5 email-change (no product flow yet) |
| `device_label` storage + 90-day first-seen | A7–A11 subscription (PR8 / billing provider) |
| Inline **This was me** / **Secure my account** on A1 | IP geolocation or fine-grained device fingerprint |
| Security emails (mandatory, no auth links) | Push to the signing-in device for A1 |

## Device labels (`device_label`)

### Purpose

Refresh sessions today carry **no device metadata** (`refreshSessions.js`). A1 (“new sign-in”) compares a **coarse label** derived at login against historical labels for the account.

### Storage

New table `account_device_labels` (name may be shortened in migration):

| Column | Type | Notes |
|--------|------|--------|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users, indexed |
| `label` | text | Coarse string, e.g. `Chrome on Windows`, `Safari on iOS`, `Agatha app on Android`, or `Unknown device` |
| `first_seen_at` | timestamptz | First login with this label |
| `last_seen_at` | timestamptz | Updated on each login with same label |
| `session_family_id` | uuid | Optional link to refresh session family for push routing |

Unique constraint: `(user_id, label)`.

### Derivation (N13)

- Parsed from client `User-Agent` (web) or app platform + OS family (Flutter), **never** from IP.
- If parsing fails → label `Unknown device` (A1 **is** emitted per FR-ACC-3).
- No IP, GPS, or full UA string stored.

### Retention

- Rows older than **90 days** since `last_seen_at` may be purged by a scheduled job (same window as “seen in last 90 days” in FR-ACC-3).
- Purge is best-effort; absence of history must not block login.

### Erasure

- On account deletion (GDPR erasure path), delete all `account_device_labels` for `user_id` in the same transaction batch as refresh sessions and notifications.
- A6 is **email-only**; no inbox row after deletion starts.

### DPIA / privacy

- Cross-reference organisation DPIA for **session/device metadata** (spec N13).
- User-facing copy: masked email in emails (`f•••@g•••.com`), coarse device label only in inbox/email/push.

## A1 delivery matrix

| Channel | Signing-in device | Other devices (same account) |
|---------|-------------------|------------------------------|
| Inbox row | Yes | No (account-scoped, one row per event) |
| Email | Yes (account email) | No separate copy |
| Push | **No** | **Yes** — all push tokens registered to **other** session families |

Push payload: title/body with device label + time; **no** sign-in link (N11). Data/silent payload triggers inbox refresh (FR-BG-6).

### Suppression rules (FR-ACC-3)

- No A1 on **first login after signup** (account `created_at` window or explicit flag on user).
- No A1 if `(user_id, label)` has `last_seen_at` within rolling **90 days**.
- Mandatory: cannot be disabled in settings matrix (§8.3).

### Resolution (FR-ACC-2)

- **This was me** → mark notification resolved; decrement bell.
- **Secure my account** → flow below; resolve on completion.
- Unanswered → auto-resolve after **14 days**.

## A2, A3, A6 (summary)

| Type | Channels | Inline / action |
|------|----------|-----------------|
| A2 `accountPasswordChanged` | Inbox + email | Optional **Secure my account** on row for 7 days |
| A3 `accountSignedOutEverywhere` | Inbox + email | Informational; **not** emitted for voluntary single-device logout |
| A6 `accountDeletionRequested` | **Email only** | No inbox row |

A3 must **not** fire on normal `POST /logout` (spec §3.5); only forced revocation (Secure my account, admin, password reset that revokes all, etc.).

## “Secure my account” flow (A1 / A2)

Single in-app flow; order is security-critical:

1. User starts from A1/A2 row (**Secure my account**).
2. **Revoke all refresh sessions except the current session family** (same family as the device running the flow).
3. Present **change password** (required) — current session remains valid through password change via **session renewal on the current family only** (do not call `revokeAllUserRefreshSessions` after password update on this path).
4. On success: resolve triggering notification(s); optional A2 already sent by password change endpoint.
5. Other devices lose refresh tokens and stop receiving push until re-login.

Flutter: dedicated route under auth/notifications; notifications feature uses `NotificationInlineActions` pattern or account-specific port to avoid new cross-feature imports.

## API surface (phase 2)

| Endpoint | Role |
|----------|------|
| `POST /api/auth/login` (+ refresh) | Upsert `device_label`; evaluate A1; emit notification |
| `POST /api/notifications/:id/account-security-feedback` | `this_was_me` \| `start_secure_flow` |
| `POST /api/auth/secure-account` | Revoke others + password change (preserves caller session) |
| Existing password change | Emits A2; uses distinct path from secure-account |

Exact paths follow existing auth router layout (`server/routes/auth/**`).

## Testing hooks

- Jest: new device label → A1 once; repeat label within 90d → no A1; first signup login → no A1.
- Jest: secure-account leaves current refresh valid.
- Flutter widget: A1 row shows two inline buttons.
- BDD: map AC-ACS-1..4, AC-ACS-10 to `notifications_v2.feature` (@P1).

## References

- Spec: §3.5, §13.12 AC-ACS-*
- Programme: [notifications-v2-programme.md](./notifications-v2-programme.md)
- Privacy: `docs/engineering/privacy/` (DPIA index)
