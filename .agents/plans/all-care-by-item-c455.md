# All care by care item

## Goal

Deliver one All care screen (`/pc/events`) where each care item is a multi-line card grouped into Today, Upcoming, Paused care, and Closed care, with pet chips in the address bar and deep links from the pet profile. Five phased PRs land on integration `cursor/all-care-by-item-c455-integration-*`, then one release PR to `main` and Pre-UAT. Product reference: `docs/domains/pet_care/changes/all-care-by-item-delivery-plan.md`. Bottom nav **Care** (FR **Soins**); screen **All care**. Away-plan rows stay on the legacy row model until a follow-up.

## Phases

### Phase 1 — Pet chips, URL filter, Paused/Closed shells
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/screens/pet_care/care_list/**",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/pet_care_global_events_filters.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/manage_events_collection_filter.dart",
    "docs/domains/pet_care/changes/all-care-by-item-delivery-plan.md",
    "docs/domains/pet_care/features/care-item-evolution.md",
    "docs/domains/pet_care/features/care-status-model.md",
    "docs/design/terminology.md",
    "docs/domains/pet_care/README.md",
    "flutter_app/test/features/experience/presentation/screens/pet_care/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [
    "flutter_app/lib/core/router/experience_routes.dart",
    "flutter_app/lib/l10n/**"
  ],
  "exit_checklist": [
    "Pet chips and ?pet= on /pc/events",
    "Paused and Closed collapsible sections on global list",
    "Planned rows in care-item-evolution and care-status-model",
    "pre-push-changed green"
  ]
}
```
Scope: Multi-select pet chips synced to query string; Paused care and Closed care collapsed sections on `/pc/events` using existing row presentation (Due soon and agenda rows unchanged). Canonical-docs Planned entries and delivery-plan sync.
Out of scope: Pet redirect; card lines; API field; dashboard/pet surfaces.

### Phase 2 — Redirect, rename, filter cleanup
```json
{
  "allowed_paths": [
    "flutter_app/lib/core/router/**",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/pet_manage_events_screen.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/all_care/**",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_care_section/pet_care_section.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/manage_events_filter_bar.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/manage_events_filter_dimensions.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/manage_events_filters.dart",
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_bottom_navigation.dart",
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_navigation_rail.dart",
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_navigation_sidebar.dart",
    "flutter_app/lib/l10n/**",
    "flutter_app/test/features/pet_profile/presentation/widgets/all_care/**",
    "flutter_app/test/features/experience/presentation/pet_care/pet_care_due_events_screen_test.dart"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": ["docs/design/terminology.md", "docs/domains/pet_care/README.md"],
  "exit_checklist": [
    "/pet/:petId/events redirects to /pc/events?pet=",
    "Tab Care and screen All care l10n",
    "Status and show-skipped removed from filter panel",
    "View all care uses chip deep link with returnTo",
    "pre-push-changed green"
  ]
}
```
Scope: Remove standalone pet All care route UI; redirect with `returnTo`; rename nav tab and screen; drop pet/status/skipped from filter panel (pet on chips). Interim UX still shows old rows and Due soon.
Out of scope: New card component; API; org-only release gates.

### Phase 3 — API completions today
```json
{
  "allowed_paths": [
    "server/routes/healthEntries/**",
    "server/lib/care/**",
    "server/lib/health/**",
    "server/test/healthEntries/**",
    "server/test/db/**",
    "flutter_app/lib/features/health_tracking/domain/entities/health_entry.dart",
    "flutter_app/lib/features/care_item/domain/care_item_schedule.dart",
    "flutter_app/lib/features/care_item/data/**",
    "flutter_app/test/features/care_item/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": ["docs/architecture/openapi/**", "docs/domains/pet_care/features/care-schedule-management.md"],
  "exit_checklist": [
    "completionsToday on list payloads",
    "Jest coverage for today completions in pet TZ",
    "Flutter deserializes field",
    "pre-push-changed green"
  ]
}
```
Scope: Additive `completionsToday` per care item on list/detail reads; no breaking wire change.
Out of scope: List card UI; client-side history reconstruction substitute.

### Phase 4 — Care cards on All care
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/screens/pet_care/care_list/**",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart",
    "flutter_app/lib/features/care_item/domain/care_list_ordering.dart",
    "flutter_app/lib/features/pet_care/presentation/widgets/care_list/**",
    "flutter_app/lib/l10n/**",
    "flutter_app/test/features/pet_care/presentation/widgets/care_list/**",
    "flutter_app/test/features/care_item/domain/care_list_ordering_test.dart",
    "flutter_app/test/bdd/features/care_agenda.feature",
    "e2e/playwright/pages/care-agenda.page.ts",
    "e2e/playwright/tests/care.agenda.spec.ts"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [
    "flutter_app/lib/features/care_item/domain/care_agenda.dart",
    "docs/domains/pet_care/features/care-item-evolution.md"
  ],
  "exit_checklist": [
    "Today and Upcoming sections with multi-line cards on /pc/events",
    "Skeleton loading on All care",
    "care_list_* semantics ids on global screen",
    "E2E for /pc/events card flows migrated",
    "pre-push-changed green"
  ]
}
```
Scope: Replace agenda rows on `/pc/events` with care-item cards (Due soon removed); org scope uses shared widgets; skeleton loading.
Out of scope: Dashboard and pet profile agenda; badge count; away plans.

### Phase 5 — Dashboard, pet screen, badge
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_upcoming_events_section.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/care_actions_attention_provider.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_care_section/**",
    "flutter_app/lib/features/pet_care/presentation/widgets/care_agenda/**",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart",
    "flutter_app/test/features/pet_profile/presentation/widgets/pet_care_section/**",
    "flutter_app/test/features/experience/presentation/screens/pet_care/care_actions_attention_provider_test.dart",
    "e2e/playwright/pages/health-dashboard.page.ts",
    "e2e/playwright/tests/care.agenda.spec.ts"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/all_care/**",
    "docs/domains/pet_care/features/care-item-evolution.md",
    "docs/design/terminology.md"
  ],
  "exit_checklist": [
    "Pet Today plus capped Upcoming uses care cards",
    "Dashboard Today only with shared card",
    "Care tab badge uses new Today grouping",
    "Legacy agenda row retired on dashboard and pet sections",
    "E2E dashboard and pet care scenarios on care_list ids",
    "pre-push-changed green"
  ]
}
```
Scope: Adopt cards on pet care section and dashboard Today; five-card Upcoming cap; rewire `careActionsAttentionCountProvider`; retire `CareEventRow`/`care_agenda` on those surfaces only (away plans unchanged).
Out of scope: Away-plan planned-care rows; org Pre-UAT blocking tests.

## Proof on UAT

On https://uat.agathatrack.com: sign in as a pet carer with due care → bottom tab **Care** → confirm multi-line cards under **Today**; tap a tick → **Done · Undo** snackbar; from pet profile **View all care** → correct chip selected; expand **Paused care** → header-only grey-pill rows.
