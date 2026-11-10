# Remove the frozen Shelter and Fostering code and the dead active widgets

## Goal
Delete the frozen Shelter/Fostering product code and the unreachable active widgets, and stop active screens from
describing those features, as decided in Part 5 of `docs/design/plans/ui-ux-review-2026-11.md` (§ 5.1 decision,
§ 5.2–5.3 inventories, § 5.6 dead code). Data, migrations, the GDPR export, CI workflow steps and the pre-push scripts
are out of scope. File ownership with the two sibling plans is in
`docs/design/plans/ui-ux-review-2026-11-execute-plan-split.md` §4.
Corrections to the review found while planning, which this plan follows: (1) only 14 of the 22 "frozen-only" server
modules are unused; `adoptionJourneys`, `custodyTransfers`, `fosterPlacements`, `fosterProfiles`, `fosterSessions`,
`orgMemberPrivacy`, `orgPetViewAccess` and `petCustody` are still imported by active code or by migrations and are
kept, so migrations `023`, `028` and `042` stay runnable without changes; (2) `scripts/check_frozen_domain_boundaries.sh`,
its fixture test, `docs/engineering/frozen-domains/manifest.json` and `server/jest.config.active.cjs` are called by
protected CI files and must be kept (the boundary check and its fixture test were run locally with the frozen roots
removed and pass); (3) `health_entry_edit_actions.dart` and `health_issues_section.dart` from § 5.6.1 no longer exist.
API payloads stay unchanged: `POST /pets/:id/transfer-to-org`, `pinned_organization_id`, the memberships array in the
login and `/me` payloads, and the `rejectFrozen*` guards on active pet routes keep their current behaviour; retiring
them is a later owner decision. Old `/o/*`, `/organizations*`, `/archived-pets` and `/pending-actions` links keep
working (redirect or a truthful screen), and `core/router/app_router.dart` is not edited by this plan.
Before approval the owner records in the removal note: a tag on `main` named `pre-frozen-domains-removal-2026-11`,
the production count of pets with a non-null `organization_id`, and confirmation that no producer still emits
foster, adoption or custody notification kinds.
Canonical docs: `docs/domains/help_about/features/specs.md`, `docs/domains/notifications/features/notifications-v2-spec.md`,
`docs/domains/navigation/features/navigation-brief.md`, `docs/design/terminology.md`, `docs/engineering/frozen-domains/README.md`.

## Phases

### Phase 1 — Flutter frozen roots
```json
{ "allowed_paths": [
    "flutter_app/lib/features/organization/**",
    "flutter_app/lib/features/fostering_session/**",
    "flutter_app/test/features/organization/**",
    "flutter_app/test/features/fostering_session/**",
    "flutter_app/analysis_options.yaml"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"], "companions": [],
  "exit_checklist": [
    "both frozen roots and their tests deleted; analyzer exclusion of those roots removed",
    "flutter analyze on the whole tree reports no new errors",
    "bash scripts/check_frozen_domain_boundaries.sh and scripts/test/check_frozen_domain_boundaries.test.sh pass",
    "pre-push-changed green"
  ] }
```
Scope: Part 5 § 5.2 rows for the two Flutter roots, their tests and the `analysis_options.yaml` exclusion.
Out of scope: active-code references to organisation or foster (later phases).

### Phase 2 — Server frozen routes, unused modules and their tests
```json
{ "allowed_paths": [
    "server/routes/organizations.js",
    "server/routes/organizations/**",
    "server/routes/fosterPlacements.js",
    "server/routes/custodyTransfers.js",
    "server/lib/adoptionVisits.js",
    "server/lib/deriveSessionStatus.js",
    "server/lib/fosterAgreementWithdrawal.js",
    "server/lib/fosterCapacity.js",
    "server/lib/fosterCompliance.js",
    "server/lib/fosteringActivitySummary.js",
    "server/lib/fosterInvite.js",
    "server/lib/fosterParentPresenter.js",
    "server/lib/fosterRequests.js",
    "server/lib/fosterVisibility.js",
    "server/lib/orgConnections.js",
    "server/lib/orgPermissions.js",
    "server/lib/orgPetShadow.js",
    "server/lib/sessionDetail.js",
    "server/lib/frozenDomains.js",
    "server/bin/server.js",
    "server/test/organizations/**",
    "server/jest.config.frozen.cjs",
    "server/jest.config.active.cjs",
    "scripts/test-frozen-domains.sh"
  ],
  "forbidden_paths": ["server/scripts/migrations/**", "server/routes/auth/**", "server/routes/pets/**"],
  "allowed_exceptions": ["tests", "docs"], "companions": [],
  "exit_checklist": [
    "frozen route files and the 14 unused modules deleted; no remaining import of any deleted file",
    "the frozen mount gate and frozen route mounts removed from server/bin/server.js; rejectFrozen* helpers kept with unchanged behaviour",
    "tests in server/test/organizations that cover kept modules are moved, not deleted",
    "migrations 023, 028 and 042 run on a fresh database (bootstrap-db.sh)",
    "server Jest suite green; GDPR export and account-deletion tests green",
    "pre-push-changed green"
  ] }
```
Scope: Part 5 § 5.2 server rows, limited to modules nothing active imports, plus the frozen Jest lane.
`jest.config.active.cjs` is edited, never deleted.
Out of scope: migrations, auth routers, active pet routes, kept modules listed in the Goal.

### Phase 3 — Frozen e-mails, seeds and end-to-end specs
```json
{ "allowed_paths": [
    "server/lib/email/**",
    "server/lib/emailTemplates.js",
    "server/db/seeds/scenarios/adoption.js",
    "server/db/seeds/scenarios/fostering.js",
    "server/db/seeds/scenarios/org-clinic.js",
    "server/db/seeds/scenarios/org-v3-demo.js",
    "server/db/seeds/scenarios/rescue-hearts.js",
    "server/db/seeds/scenarios/index.js",
    "server/db/seeds/demo-credentials-doc.js",
    "e2e/playwright/tests/**",
    "e2e/scripts/frozen-e2e-specs.mjs",
    "e2e/scripts/spec-domains.mjs",
    "e2e/scripts/shard-files.mjs",
    "flutter_app/test/bdd/**"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"], "companions": [],
  "exit_checklist": [
    "the two foster e-mail templates and their i18n and registry entries removed",
    "the five frozen seed scenarios removed from disk, scenarios/index.js and the demo credentials doc; remaining seeds run",
    "frozen Playwright specs and frozen BDD features removed after moving any helper an active spec imports",
    "BDD coverage gate and Playwright shard/frozen lists pass",
    "pre-push-changed green"
  ] }
```
Scope: Part 5 § 5.2 rows for e-mail templates, seeds, BDD features and Playwright specs.
Out of scope: active specs and features.

### Phase 4 — Unreachable active Flutter files
```json
{ "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_fostering_section.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_fostering_screen.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_assignment_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_bio_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_breed_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_chip_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_insurance_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_org_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_photo_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_radio_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_vet_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_weight_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/screens/widgets/vet_creation_sheet.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row_context.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row_host.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/entry_document_section.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/entry_form_labels.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/entry_frequency_fields.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/entry_remind_before_field.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/guardian_add_event_picker_sheet.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/mark_complete_sheet.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/recurrence_anchor_toggle.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_card.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_card_actions.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/pet_event_pet_card.dart",
    "flutter_app/lib/features/health_tracking/domain/health_events_scope.dart",
    "flutter_app/lib/features/health_tracking/data/services/events_pdf_service.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/download_report_section.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/other_events_section.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/widgets/pet_profile_card.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/controllers/other_events_controller.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/controllers/pet_profile_controller.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/providers/pet_care_status_provider.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/providers/pet_vet_contacts_provider.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_care_section/pet_care_temporal_group_section.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_care_section/pet_care_temporal_group_labels.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_care_section/pet_care_buckets_filter.dart",
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_today_orientation.dart",
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_today_header.dart",
    "flutter_app/lib/features/experience/presentation/widgets/org_experience_drawer.dart",
    "flutter_app/lib/features/experience/presentation/widgets/pet_care_experience_drawer.dart",
    "flutter_app/lib/features/experience/presentation/widgets/experience_settings_section.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_bulk_share.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_occurrence_menu.dart",
    "flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_schedule_action_bar.dart",
    "flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_plan_placeholder_screen.dart",
    "flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_details_section.dart",
    "flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_handover_note_section.dart",
    "flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_suggestions_section.dart",
    "flutter_app/lib/features/pet_care/context/presentation/away_plan_planner_copy.dart",
    "flutter_app/lib/features/people/presentation/widgets/people_directory_card.dart",
    "flutter_app/lib/features/people/presentation/utils/people_contact_role_labels.dart",
    "flutter_app/lib/core/widgets/contact_initials_avatar.dart",
    "flutter_app/lib/core/providers/http_client_provider.dart",
    "flutter_app/lib/core/widgets/form/app_form_sheet.dart",
    "flutter_app/lib/features/care_intelligence/presentation/widgets/suggestion_why_button.dart",
    "flutter_app/lib/features/care_taxonomy/presentation/widgets/care_classification_section.dart",
    "flutter_app/lib/features/care_taxonomy/presentation/widgets/care_classification_labels.dart",
    "flutter_app/lib/features/pet_profile/presentation/controllers/family_events_controller.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/care_source_labels.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/profile_prompt_row.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/pet_list_bulk_share_bar.dart",
    "flutter_app/lib/features/pet_profile/domain/entities/pet_species.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/shared_pet_health_entry_card.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/shared_pet_vet_card.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"], "companions": [],
  "exit_checklist": [
    "each listed file is confirmed unreachable from main.dart (or only referenced by tests) before deletion; any file found live is kept and named in the PR body",
    "tests that only covered deleted files are deleted; the three re-export shims in Part 5 § 5.6.3 are kept unless their tests are re-pointed in this PR",
    "flutter analyze reports no new errors and the active Flutter test shards pass",
    "pre-push-changed green"
  ] }
```
Scope: Part 5 § 5.6.1 except the auth-path files (phase 5) and the two files that no longer exist.
Out of scope: classes that share a file with live code (phase 6), any file outside the list.

### Phase 5 — Dead auth screens and the My details organisation row
```json
{ "allowed_paths": [
    "flutter_app/lib/features/auth/auth.dart",
    "flutter_app/lib/features/auth/presentation/screens/login_screen.dart",
    "flutter_app/lib/features/auth/presentation/screens/signup_screen.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_audience_section.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_path_card.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_logo.dart",
    "flutter_app/lib/features/auth/presentation/controllers/my_details_controller.dart",
    "flutter_app/lib/features/auth/presentation/screens/my_details_screen.dart",
    "flutter_app/lib/features/auth/presentation/widgets/my_details/profile_settings_section.dart",
    "flutter_app/test/features/auth/presentation/widgets/landing_audience_section_test.dart",
    "flutter_app/test/features/auth/presentation/widgets/landing_path_card_test.dart"
  ],
  "approved_sensitive_paths": [
    "flutter_app/lib/features/auth/auth.dart",
    "flutter_app/lib/features/auth/presentation/screens/login_screen.dart",
    "flutter_app/lib/features/auth/presentation/screens/signup_screen.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_audience_section.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_path_card.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_logo.dart",
    "flutter_app/lib/features/auth/presentation/controllers/my_details_controller.dart",
    "flutter_app/lib/features/auth/presentation/screens/my_details_screen.dart",
    "flutter_app/lib/features/auth/presentation/widgets/my_details/profile_settings_section.dart",
    "flutter_app/test/features/auth/presentation/widgets/landing_audience_section_test.dart",
    "flutter_app/test/features/auth/presentation/widgets/landing_path_card_test.dart"
  ],
  "forbidden_paths": ["flutter_app/lib/features/auth/presentation/screens/landing_screen.dart"],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "LoginScreen, SignupScreen and their barrel exports removed; no reference to /login or /signup remains in My details",
    "the My organisations row and its /organizations callback are gone from My details",
    "landing leftovers and my_details_controller removed after confirming nothing imports them",
    "sign-in, sign-up and password-change widget tests still pass",
    "pre-push-changed green"
  ] }
```
Scope: Part 5 § 5.5 decision (delete both screens), the auth-path files of § 5.6.1, A-7.3's dead `/login` literal and
the frozen My details row (A-7.4). Behaviour of sign-in, sign-up and password change is otherwise unchanged.
Out of scope: `landing_screen.dart` (another plan), the password-manager bridge, every other My details finding.

### Phase 6 — Single Pet Care experience and frozen notification kinds
```json
{ "allowed_paths": [
    "flutter_app/lib/core/experience/app_experience.dart",
    "flutter_app/lib/features/experience/domain/entities/app_experience.dart",
    "flutter_app/lib/features/experience/domain/entities/drawer_menu_item.dart",
    "flutter_app/lib/features/experience/presentation/providers/experience_providers.dart",
    "flutter_app/lib/core/router/experience_routes.dart",
    "flutter_app/lib/features/experience/presentation/screens/experience_chooser_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/experience_settings_screen.dart",
    "flutter_app/lib/features/experience/presentation/widgets/experience_workspace_toggle.dart",
    "flutter_app/lib/features/experience/presentation/widgets/experience_shell_scaffold.dart",
    "flutter_app/lib/core/router/experience_shell_scaffold.dart",
    "flutter_app/lib/features/experience/presentation/pet_profile/screens/pet_form_screen_actions.part.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart",
    "flutter_app/lib/core/widgets/collection_filter/org_context_collection_filter.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/org_filter_chips.dart",
    "flutter_app/lib/features/notifications/domain/entities/notification_scope.dart",
    "flutter_app/lib/features/notifications/domain/entities/notification_settings_matrix.dart",
    "flutter_app/lib/features/notifications/presentation/widgets/notification_settings_matrix_section.dart",
    "flutter_app/lib/features/notifications/presentation/utils/notification_navigation.dart",
    "flutter_app/lib/features/notifications/presentation/screens/pending_actions_screen.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/pending_foster_placements_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/pending_adoption_placements_section.dart",
    "flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/pending_custody_transfers_section.dart"
  ],
  "forbidden_paths": [
    "flutter_app/lib/core/router/app_router.dart",
    "flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care_onboarding_screen.dart",
    "flutter_app/lib/features/notifications/presentation/screens/notification_settings_screen.dart"
  ],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "AppExperience has one active value and experience_providers keeps the API the resolver screen uses",
    "the workspace toggle, chooser screen and ExperienceSettingsScreen class are gone; /app/choose redirects to /app/resolve; ExperienceInviteScreen still serves /pc/invite",
    "pet form create path no longer has /organizations branches; OrgDueEventsScreen, PetCareGlobalEventsFilterBar and the org filter chips are removed",
    "notification settings show no organisation/foster category; /pending-actions shows a truthful localized message with an Open inbox action and no frozen sections",
    "pre-push-changed green"
  ] }
```
Scope: Part 5 § 5.3 routing, experience model, pet form, events and notifications items; review findings A-3.1
(provider side), A-4.1, B-1.2, B-5.2 (organisation branches only), D-3.1, D-5.3 (frozen category only), D-6.1, D-6.2.
Out of scope: the router file, the resolver and onboarding screens, the notification settings screen.

### Phase 7 — Active content pass
```json
{ "allowed_paths": [
    "flutter_app/lib/features/help/presentation/screens/help_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/account_screen.dart",
    "flutter_app/lib/features/experience/presentation/widgets/account_organisation_settings_section.dart",
    "flutter_app/lib/features/about/presentation/screens/about_screen.dart",
    "flutter_app/web/index.html"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "Help has no organisation or Family Events group in EN or FR and retained answers describe active navigation (D-8.1, D-8.3)",
    "Account has no organisation block (D-1.1); appTagline and the web meta description describe only Pet Care (D-9.3)",
    "no unused ARB key is swept in this phase",
    "pre-push-changed green"
  ] }
```
Scope: X-4 content items of Part 5 § 5.3 and findings D-1.1, D-8.1, D-8.3, D-9.3, in EN and FR together.
Out of scope: the unused-ARB-key sweep (one follow-up PR after all three sibling plans release), other copy findings.

### Phase 8 — Removal record and docs
```json
{ "allowed_paths": [
    ".agents/memory/**"
  ],
  "forbidden_paths": ["docs/engineering/frozen-domains/manifest.json"],
  "allowed_exceptions": ["docs"], "companions": [],
  "exit_checklist": [
    "docs/engineering/frozen-domains/ is reduced to a removal record (date, tag, what was removed, kept modules and why, data decision pending) plus mvp-pivot-decisions.md; manifest.json is kept unchanged",
    "terminology.md keeps the rule that frozen words are not active vocabulary; design and navigation docs no longer describe removed screens",
    "agent memory notes that describe the freeze are updated",
    "docs gates green"
  ] }
```
Scope: Part 5 § 5.7 step 6, documentation half only.
Out of scope: removing the boundary script, its CI step or the frozen exclusions in the pre-push scripts (protected
files; a separate owner PR after release), any data change.

## Proof on UAT
On https://uat.agathatrack.com signed in as a pet parent: Help, Account, About and My details mention no shelter,
organisation, fostering or Family Events; notification settings show no organisation category; `/pending-actions`,
`/app/choose`, `/organizations` and `/o/anything` each land on a working page instead of a blank or not-found screen;
sign-in, sign-up, password change and the pet, care, away, people and sharing journeys still work. `curl` of
`/backend/api/organizations` gives the same response it gave before the removal (the routes were never mounted).
