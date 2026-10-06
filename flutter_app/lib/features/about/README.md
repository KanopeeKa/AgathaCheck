---
title: About feature
owner: Pet Care team
status: active
component_id: flutter.feature.about
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

In-app About screen and legal document viewers (privacy, terms). **Non-goals:** account settings, subscription, or help FAQ content.

## Public entrypoint

`package:pet_profile_app/features/about/about.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `LegalDocumentId` | domain enum | Route/query parameter for legal docs |
| `AboutScreen` | UI screen | Router destination |
| `LegalDocumentsScreen` | UI screen | Legal index |
| `LegalDocumentScreen` | UI screen | Single document viewer |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `core/`, `l10n/` | Other features' `data/` or private `presentation/` (use their entrypoints) |

## Side effects & freshness

Read-only static/legal content; no remote cache policy.

## Permissions

None beyond authenticated app access for navigation.

## Tests

`flutter_app/test/features/about/`
