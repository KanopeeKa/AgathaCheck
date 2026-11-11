# Truthful outcomes (subscription, bell, consent, confirms, export)

## Goal
Every control on the subscription, bell-panel, consent, small confirm, and data-export surfaces does what its label
says. Every confirmation states only what happened. Invalid input is explained inline instead of being silently
ignored. Phased delivery on one integration branch, one release PR to `main`, then driver Pre-UAT and UAT promotion.
Source: findings in `docs/design/plans/ui-ux-review-2026-11.md` — workers read each finding's nine-part spec before
coding. Reuse `AsyncErrorState`, `LabelledProgress`, and `SupplementalStateCaption` from
`flutter_app/lib/core/widgets/async_state/`. User-facing strings go in both ARB files next to related keys; never
re-sort ARB files.
Programme exclusions (not in any phase): D-4.3 (already fixed in tree); A-10.2 and A-10.3 (consent banner elevation
and modality); A-9.1 (consent settings draft sync); C-6.2 and C-6.3 (add-person step focus and dialog route); every
care-plan, router, navigation-widget, and frozen-removal file except where a phase explicitly allows a narrow path.
Canonical docs to update in the journey phase:
`docs/domains/subscription/features/specs.md`, `docs/domains/notifications/features/notifications-v2-spec.md`,
`docs/domains/people/features/people-care-team.md`, and the consent rule in `docs/design/system.md` § 6.10.
Scheduling: phases 1–5 may start as soon as the programme is approved. **Phase 6 must not be dispatched until frozen-
removal plan #2192 is merged to `main` and integration has been synced** (driver `wait`; no phase-6 worker until then).
ARB merge conflicts with the care plan are resolved by syncing integration and regenerating l10n companions.

## Phases

### Phase 1 — Subscription
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/subscription/presentation/screens/paywall_screen.dart",
    "flutter_app/lib/features/subscription/presentation/widgets/paywall_body_content.dart",
    "flutter_app/lib/features/subscription/presentation/widgets/paywall_offering_card.dart",
    "flutter_app/lib/features/subscription/presentation/widgets/paywall_feature_list_card.dart",
    "flutter_app/lib/features/subscription/presentation/widgets/paywall_offer_display.dart",
    "flutter_app/lib/features/subscription/domain/entities/subscription_status.dart",
    "flutter_app/lib/features/subscription/data/services/revenuecat_service.dart"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "Manage subscription launches managementUrl externally; a false or throwing launch shows localized copy with a copyable URL; with no URL the control is absent or disabled with an explanation (D-7.1)",
    "Each offer card shows recurring price and cadence from the store product subscription period, an auto-renew sentence, how to cancel, and links to /legal/terms-of-use and /legal/privacy-notice (D-7.2)",
    "Trial or intro text appears only when the store product carries an introductory price; no trial length is ever invented",
    "Best Value appears only when the annual package monthly cost is lower than the monthly package in the same offering; with one cadence there is no tag",
    "All app-written status, period, feature, and error copy comes from ARB in EN and FR; purchase and restore errors never show exception text (D-7.3)",
    "The date is labelled renewal only when the status says the subscription will renew; otherwise it reads as active until (D-7.3)",
    "Offer cards use 16 dp radius, 1 px themed outline, zero elevation (D-7.4)",
    "Empty and failed offering loads both show AsyncErrorState with a working Retry; reload clears the old error (D-7.5)",
    "Widget tests cover disclosure lines via paywall_offer_display with plain test DTOs (not platform StoreProduct construction), no tag with one cadence, and manage with and without URL",
    "pre-push-changed green"
  ]
}
```
Scope: D-7.1, D-7.2, D-7.3 (including purchase and restore errors), D-7.4, D-7.5. Add `paywall_offer_display.dart` as a
display model from store product data. `subscription_status.dart` and `revenuecat_service.dart` may gain a will-renew
flag only if the SDK exposes one.
Out of scope: purchase flow logic, entitlement rules, server.

### Phase 2 — Notification bell panel
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/notifications/presentation/widgets/notification_panel.dart",
    "flutter_app/lib/features/notifications/presentation/widgets/notification_panel_header.dart",
    "flutter_app/lib/features/notifications/presentation/widgets/notification_inbox_list.dart",
    "flutter_app/lib/features/notifications/presentation/screens/notifications_screen.dart",
    "flutter_app/lib/features/notifications/presentation/utils/mark_all_read_eligibility.dart"
  ],
  "forbidden_paths": [
    "flutter_app/lib/core/router/**",
    "flutter_app/lib/features/notifications/presentation/utils/notification_navigation.dart",
    "flutter_app/lib/features/notifications/presentation/widgets/notification_settings_matrix_section.dart"
  ],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "Panel header has Open full inbox and Notification settings as 48 dp controls with tooltips and semantics identifiers; each closes the drawer then pushes /notifications or /notifications/settings (D-4.1)",
    "One shared helper decides mark-all-read eligibility from NotificationInboxV2Rules; panel and full inbox both disable it while loading and when the tab has nothing unread; success shows a distinct localized result (D-4.4)",
    "Unit tests on mark_all_read_eligibility cover tab, loading, and unread fixtures",
    "For you empty copy shortened in EN and FR (D-4.2)",
    "pre-push-changed green"
  ]
}
```
Scope: D-4.1, D-4.2, D-4.4. The `/pc/notifications` redirect stays unchanged.
Out of scope: notification settings matrix, pending actions, D-4.3.

### Phase 3 — Consent banner and settings
```json
{
  "allowed_paths": [
    "flutter_app/lib/core/widgets/consent/consent_banner_surface.dart",
    "flutter_app/lib/core/widgets/consent/consent_settings_screen.dart",
    "flutter_app/lib/core/widgets/consent/consent_preferences_sheet.dart",
    "flutter_app/lib/core/widgets/consent_banner.dart",
    "flutter_app/lib/core/widgets/consent/consent_timestamp_format.dart"
  ],
  "forbidden_paths": [
    "flutter_app/lib/main.dart",
    "flutter_app/lib/core/services/consent_service.dart"
  ],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "Action buttons are built without Expanded and wrapped in Expanded only in the wide Row; widget tests at 320, 360, 399, 400 and 480 dp show no layout exception (A-10.5)",
    "Reject optional calls savePreferences with analytics and marketing off, shows LabelledProgress while saving, keeps the banner with a localized retryable error when it returns false (A-10.1)",
    "Consent settings disables Save and both switches while saving and writes once (A-9.2)",
    "Settings and sheet share one locale-aware local-time formatter via consent_timestamp_format.dart (A-9.3)",
    "A French-locale test at 2.0 text scale renders all banner actions without overflow",
    "pre-push-changed green"
  ]
}
```
Scope: A-10.5, A-10.1, A-9.2, A-9.3. `consent_service.dart` is unchanged; Reject optional uses `savePreferences` because
it returns a result.
Out of scope: A-10.2, A-10.3, A-9.1.

### Phase 4 — Confirm dialogs and partial success
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/pet_tags/presentation/screens/manage_pet_tags_screen.dart",
    "flutter_app/lib/features/people/presentation/add/add_person_flow.dart",
    "flutter_app/lib/features/people/presentation/add/add_person_flow_controller.dart",
    "flutter_app/lib/features/people/presentation/add/add_person_step_finalize.dart",
    "flutter_app/lib/features/people/presentation/households/household_detail_page.dart",
    "flutter_app/lib/features/about/presentation/widgets/legal_document_body.dart"
  ],
  "forbidden_paths": ["flutter_app/lib/features/about/presentation/screens/**"],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "Tag name dialog stays open with a field error on blank input; usage chip says Used by N pets (D-2.3, D-2.4)",
    "Add person: the current save path is described in the PR body before changes; contact-saved/invite-failed is shown persistently and Retry sends only the invite; a test proves one contact POST (C-6.1)",
    "Household rename validates trimmed input before closing (C-10.2)",
    "Legal external links await launchUrl; a false or throwing result shows a localized notice with a copyable URL (D-11.2)",
    "pre-push-changed green"
  ]
}
```
Scope: D-2.3, D-2.4, C-6.1, C-10.2, D-11.2.
Out of scope: C-6.2, C-6.3; About screens (frozen plan edits `about_screen.dart` only).

### Phase 5 — Journey coverage and docs
```json
{
  "allowed_paths": [
    "e2e/playwright/tests/trust.surfaces.spec.ts",
    "e2e/playwright/pages/notification-panel.page.ts",
    "flutter_app/test/bdd/features/trust_surfaces.feature"
  ],
  "forbidden_paths": [
    "e2e/playwright/pages/care-agenda.page.ts",
    "e2e/playwright/pages/health-dashboard.page.ts"
  ],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "Gherkin scenarios and a Playwright spec with an exact /** @bdd */ header cover bell to settings, bell to full inbox, and consent Reject optional",
    "BDD coverage gate and Playwright shard/affected-spec checks pass",
    "Subscription disclosure is recorded as a manual UAT check in the canonical subscription doc (store data cannot be mocked end to end)",
    "Canonical docs listed in the Goal are updated",
    "pre-push-changed green"
  ]
}
```
Scope: automated journey coverage for bell and consent; canonical doc updates for subscription, notifications, people,
and consent rule.
Out of scope: care-agenda and health-dashboard page objects; native export (phase 6).

### Phase 6 — Native data export
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/auth/presentation/screens/my_details_screen.dart",
    "flutter_app/lib/features/auth/presentation/screens/export_data_stub.dart",
    "flutter_app/lib/features/auth/presentation/screens/export_data_web.dart",
    "flutter_app/lib/features/auth/presentation/screens/export_data_io.dart"
  ],
  "approved_sensitive_paths": [
    "flutter_app/lib/features/auth/presentation/screens/my_details_screen.dart",
    "flutter_app/lib/features/auth/presentation/screens/export_data_stub.dart",
    "flutter_app/lib/features/auth/presentation/screens/export_data_web.dart",
    "flutter_app/lib/features/auth/presentation/screens/export_data_io.dart"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "Web still downloads a valid JSON file",
    "iOS and Android save the file through the existing file_picker save dialog; cancel is not reported as success",
    "A platform with no delivery path says so before exporting and never shows Data exported",
    "Only the export method and export platform files change in my_details_screen.dart (no unrelated profile or delete-account edits)",
    "pre-push-changed green"
  ]
}
```
Scope: D-12.1 only. Conditional `export_data_io.dart` for mobile; minimal `_exportData` changes.
Out of scope: delete-account dialog, profile save, password change.
Prerequisite: frozen-removal #2192 merged to `main` and integration synced before this phase starts.

## Proof on UAT
Bell: panel reaches settings and the full inbox in one tap each. Fresh private window at 360 px: consent banner shows
Reject optional; one tap dismisses it and persists the choice. Offers page (manual, needs store data): each offer shows
renewal and cancellation terms; a subscribed account's Manage subscription opens the store management page. Phone build:
export produces a file or states that it cannot (phase 6).
