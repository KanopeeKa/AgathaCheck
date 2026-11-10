# Async states: failed loads recover, unknown data never looks empty

## Goal
Every failed primary load on the active Pet Care screens below shows calm localized copy with Retry inside the
shell (no exception text, no lost title or back), and no failed or loading supplemental query is shown as "none",
"all set" or a false ownership/selection claim. Rules X-1, X-2 and part of X-7 from
`docs/design/plans/ui-ux-review-2026-11.md`; each phase lists the finding IDs to implement and the worker reads
each finding's nine-part spec before coding. Split rationale and file ownership:
`docs/design/plans/ui-ux-review-2026-11-execute-plan-split.md` §4.
Prerequisite: the shared widgets `AsyncErrorState`, `SupplementalStateCaption` and `LabelledProgress` in
`flutter_app/lib/core/widgets/async_state/` (phase 0 PR) are on `main` before approval; this plan uses them and
does not redefine them. Reuse the `routeShell` pattern from `care_item_detail_screen.dart` for shell chrome.
Never log or display raw exception text; keep existing E2E keys.
Not in this plan: auth and entry screens, the four invitation landings (another plan owns them), and any file on
the dead-code lists in the review's Part 5 § 5.6.
Canonical docs: `docs/design/system.md` § 6.10 (state contract) plus the feature doc of each touched domain
(`pet_profile`, `health_tracking`, `weight_tracking`, `pet_care`, `people`, `sharing`, `notifications`,
`subscription`, `help_about`).

## Phases

### Phase 1 — Home and pets
```json
{ "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/screens/experience_home_screens.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_all_pets_screen.dart",
    "flutter_app/lib/features/pet_tags/presentation/widgets/pet_tag_filter_bar.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_bulk_share_select_screen.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_list/pet_care_pets_tile_grid.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_edit_permission_guard.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/pet_detail_screen.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "widget tests: error -> Retry -> data for Home and Pet detail; no exception text in the tree",
    "tag filter has loading, unavailable-with-Retry and ready states and keeps a selected filter (B-3.1)",
    "bulk-share and home tiles never say All set while care data is loading or failed (B-4.1)",
    "edit guard is localized, inside the shell, and separates error from not found (B-5.1)",
    "pre-push-changed green"
  ] }
```
Scope: B-2.1, B-3.1, B-4.1, B-5.1, B-6.1.
Out of scope: navigation labels (B-1.x), pet form navigation (B-5.2), weight unit (B-5.3), section order (B-6.2).

### Phase 2 — Care screens
```json
{ "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/pet_health_issues_screen.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/pet_manage_events_screen.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/all_care/all_care_list.dart",
    "flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart",
    "flutter_app/lib/features/health_tracking/presentation/controllers/health_entry_form_controller.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_form/health_entry_form_screen_body.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_detail_screen.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_detail_body.dart",
    "flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_screen.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/pet_timeline_screen.dart",
    "flutter_app/lib/features/weight_tracking/presentation/screens/weight_hub_screen.dart",
    "flutter_app/lib/features/weight_tracking/presentation/widgets/weight_hub_summary_card.dart",
    "flutter_app/lib/features/weight_tracking/presentation/widgets/weight_hub_routines_card.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "every primary-load error in these screens uses AsyncErrorState with a working Retry and keeps shell chrome",
    "care item history failure leaves schedule and actions usable with a section-level Retry (B-11.1)",
    "edit form with a failed entry load shows an error state and Save stays disabled; a test proves Save cannot overwrite or create (B-10.2)",
    "weight overview failure shows target/routine unavailable with Retry while history still renders (B-14.1)",
    "occurrence initial load uses LabelledProgress (B-12.2)",
    "pre-push-changed green"
  ] }
```
Scope: B-7.1, B-8.1, B-8.2, B-10.2, B-11.1, B-12.2, B-13.1, B-14.1, B-14.2. For B-10.2, first establish what
`save()` does today when the entry never loaded and record it in the PR body.
Out of scope: copy-only findings (B-7.2, B-10.1, B-10.3, B-12.1), All actions queue (B-9.x), health-issue link row (B-11.2).

### Phase 3 — Away plans
```json
{ "allowed_paths": [
    "flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_hub_screen.dart",
    "flutter_app/lib/features/pet_care/context/presentation/widgets/planned_absence_hub_card.dart",
    "flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_flow_screen.dart",
    "flutter_app/lib/features/pet_care/context/presentation/widgets/planned_absence_pets_step.dart",
    "flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart",
    "flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_edit_screen.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "a saved plan never shows Select at least one pet while pet names load or fail (C-1.1)",
    "new away plan never shows No pets yet while pets load or fail, and Save waits for pets (C-2.1)",
    "plan and edit primary errors have Retry; edit Retry reruns its own loader (C-3.1, C-4.1)",
    "hub and plan loading use LabelledProgress (C-1.2, C-3.2)",
    "pre-push-changed green"
  ] }
```
Scope: C-1.1, C-1.2, C-2.1, C-3.1, C-3.2, C-4.1.
Out of scope: the away-plan invite landing, discard prompt (C-2.2), large-text checks (C-2.3, C-4.2).

### Phase 4 — People and households
```json
{ "allowed_paths": [
    "flutter_app/lib/features/people/presentation/detail/person_detail_page.dart",
    "flutter_app/lib/features/people/presentation/detail/person_detail_contact_view.dart",
    "flutter_app/lib/features/people/presentation/edit/person_edit_page.dart",
    "flutter_app/lib/features/people/presentation/edit/person_edit_contact_form.dart",
    "flutter_app/lib/features/people/presentation/households/households_page.dart",
    "flutter_app/lib/features/people/presentation/households/household_detail_page.dart",
    "flutter_app/lib/features/people/presentation/screens/legacy_vet_contact_redirect_screen.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "person detail/edit, households list/detail and the legacy vet resolver each have a working Retry; missing records get a safe exit",
    "household pets are never labelled as another member's while personal pets load or fail (C-10.1)",
    "the legacy vet resolver leaves its spinner on failure (C-11.1)",
    "pre-push-changed green"
  ] }
```
Scope: C-7.1, C-8.1, C-9.1, C-10.1, C-10.4, C-11.1.
Out of scope: household invite landing, add-person flow (C-6.x), rename validation (C-10.2), busy state (C-10.3).

### Phase 5 — Sharing management
```json
{ "allowed_paths": [
    "flutter_app/lib/features/sharing/presentation/screens/share_pet_screen.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/share_pet_owner_body.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/owner_sharing_content.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/follower_sharing_content.dart",
    "flutter_app/lib/features/sharing/presentation/providers/share_pet_providers.dart",
    "flutter_app/lib/features/sharing/presentation/sharing_error_messages.dart"
  ],
  "forbidden_paths": [
    "flutter_app/lib/features/sharing/presentation/screens/shared_pet_screen.dart",
    "flutter_app/lib/features/sharing/presentation/screens/invite_landing_screen.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/shared_pet_accept_section.dart"
  ],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "pets, direct access, links and household overview each show their own unavailable state with Retry; no authoritative empty list before data resolves (C-12.1)",
    "no literal Error: prefix or exception text in any sharing mutation message, EN and FR (C-12.2)",
    "the inactive organisation and foster branches in share_pet_screen.dart are removed",
    "pre-push-changed green"
  ] }
```
Scope: C-12.1, C-12.2, removal of the frozen branches in `share_pet_screen.dart` (Part 5 § 5.3), and one shared
sharing-error mapper in `sharing_error_messages.dart`.
Out of scope: the three recipient files listed as forbidden (another plan), chip accessibility (C-12.3).

### Phase 6 — Account, notifications, subscription and legal
```json
{ "allowed_paths": [
    "flutter_app/lib/features/pet_tags/presentation/screens/manage_pet_tags_screen.dart",
    "flutter_app/lib/features/notifications/presentation/screens/notifications_screen.dart",
    "flutter_app/lib/features/notifications/presentation/widgets/notification_panel_error_view.dart",
    "flutter_app/lib/features/notifications/presentation/screens/notification_settings_screen.dart",
    "flutter_app/lib/features/subscription/presentation/screens/paywall_screen.dart",
    "flutter_app/lib/features/subscription/presentation/widgets/paywall_body_content.dart",
    "flutter_app/lib/features/about/presentation/screens/legal_document_screen.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "pet tags, notifications inbox and panel, notification settings, subscription offers and the legal viewer each show localized error with a working Retry",
    "pet-tag delete failure keeps the tag and reports a localized retryable error (D-2.2)",
    "notification settings load and save errors are localized and a failed save keeps the draft (D-5.1, D-5.2)",
    "empty and failed subscription offer loads both show Retry and reload clears the stale error (D-7.5)",
    "pre-push-changed green"
  ] }
```
Scope: D-2.2, D-2.5, D-4.3, D-5.1, D-5.2, D-7.5, D-11.3.
Out of scope: notification panel destinations (D-4.1), subscription management and disclosure (D-7.1, D-7.2,
D-7.3), notification settings matrix (D-5.3), Help, About, Account and Pending actions.

## Proof on UAT
On https://uat.agathatrack.com with the browser's network set to offline after the app has loaded, open Home, a
pet's detail page, the away hub, a person in People, Share pet and Notifications: each shows a calm localized
"couldn't load" message with Retry and keeps the title and back; switching back online and pressing Retry loads the
content without leaving the screen. On All pets with a tag filter selected, going offline never shows pets as
"All set" or drops the selected filter silently.
