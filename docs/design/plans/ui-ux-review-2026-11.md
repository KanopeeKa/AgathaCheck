---
title: UI/UX review of all active screens (November 2026)
owner: Documentation Team
audience: both
status: draft
last_updated: 2026-11-09
tags: [design,ui,ux,review]
---
# UI/UX review of all active screens (November 2026)

Analysis only. No app code, theme, copy, tests or routes were changed. Graded against the repository's own guidance ([`true-north.md`](../true-north.md), [`principles.md`](../principles.md), [`system.md`](../system.md), [`tokens.md`](../tokens.md), [`copy-tone.md`](../copy-tone.md), [`terminology.md`](../terminology.md), the `ui-design-deep` skill) and against public material from comparable pet apps (Part 3).

## Summary

**Overall assessment.** The product has a coherent, calm foundation that matches True North: a role-neutral entry, one responsive Pet Care shell (bottom navigation, rail, sidebar), server-authoritative care data, confirmations before consequential changes in People and Away, and no streaks or engagement mechanics. The problems sit at the edges of the main journeys, not in their centre:

1. People who receive an invitation or share link and are not signed in reach a screen that cannot be acted on, or never reach it.
2. Several confirmations and controls say something that is not true (data export, "Manage subscription", password-change redirect).
3. Frozen Shelter/Fostering content still shows in active screens.
4. Failure states are handled unevenly: raw exceptions, no retry, and failed loads that look like "nothing here".
5. Hard-coded English, unlabeled progress states, and a few one-off styles drift from the design system.

Of 159 findings across 54 reviewed screens and surfaces, 11 were withdrawn on the second pass (kept in the text as audit records) and 148 stand: 8 are High (all requirements), 79 are Medium (61 requirements, 18 recommendations), and 61 are Low. Every finding in all four areas was re-read against the source and written as a full nine-part specification; the second pass changed 51 grades: 30 up, mostly to requirement under `system.md` § 6.10 (plain-language error with retry, no raw backend message), and 21 down where the source did not support the first-pass claim. No finding concerns the core care-completion logic or the visual identity. Part 5 records the owner's decision to delete the frozen Shelter/Fostering code and inventories the unrouted and dead widgets found on the way (about 5,000 lines of active-tree code that nothing reaches, plus 29,000 lines in the frozen roots).

**Top five issues (ranked).**

| # | Issue | Where | Why it ranks here |
|---|---|---|---|
| 1 | Signed-out recipients of an invitation cannot continue. `/shared/:code` and `/invite/:code` show the content but hide accept and decline, `/household-invite/:code` shows actions that can only fail, and `/absence-invite/:code` is redirected to `/landing` by the auth guard before it renders. | C-13.1, C-14.1, C-15.1, C-16.1 | Sitters and relatives are the first-impression audience and the growth path. Their first screen is a dead end. |
| 2 | Controls and messages that misstate what happened. Export on iOS/Android reports "Data exported" without producing a file; "Manage subscription" has an empty handler; the profile editor reports success after the notifier swallowed a save failure; Delete account and Secure account submit without client validation and show raw service errors. | D-12.1, D-7.1, A-7.6, A-7.5, A-8.1, A-8.3 | Trust and data-rights obligations. These are small fixes with high credibility cost if left. (The first pass's "password change lands on an unregistered `/login`" was withdrawn: the change signs the user out and the guard sends them to `/landing`.) |
| 3 | Frozen-domain and legacy content in active screens. Help documents organisations and "Family Events" (a retired term), Pending actions renders three no-op foster, adoption and custody sections, Account shows an "Organisation settings" block, the public About page says "in a shelter, or as part of a team". | D-8.1, D-6.1, D-1.1, D-9.3; Part 5 | Active users are told about features that do not exist. Breaks the copy rules in terminology.md. Part 5 decides to delete the frozen code so that this content pass can be checked mechanically. |
| 4 | Failure handling is inconsistent across about 20 screens: raw exception text, no retry, shell chrome lost, and supplemental-data failures that render as empty or all-clear (tag filter, bulk-share care summary, weight overview, absence pet list, household pets). | Part 4 X-1, X-2 | Silent fallbacks are the product's own stated anti-pattern, and offline or flaky mobile networks make this common. |
| 5 | Notifications are hard to reach and the not-found page is a dead end. The shell bell opens a panel with no link to the full inbox or settings, and `/pc/notifications` redirects home. Unknown links show `Page not found: <uri>` in English with no way out. | D-4.1, D-13.1 | Reminders are the main way the app earns trust between visits. |

**Flagged screens** (full ranking in "Needs particular attention"): the four invitation landings, My details (data rights and profile save), Subscription, Notifications (entry and inbox), Help, Pending actions, Secure account, Pet Care onboarding, the not-found page and the first-use consent popup.

**How to read this document.** Part 1 lists every screen. Part 2 has the per-screen findings, grouped in four areas, each finding in the full nine-part specification; each area ends with the patterns it feeds into Part 4 and the list of grade changes from the first pass. Part 3 holds benchmark notes. Part 4 collects patterns that repeat, stated as rule, shared component and screens. Part 5 is the code-removal record: the decision to delete the frozen Shelter/Fostering code, the inventory of frozen semantics left in active code, the data that is deliberately kept, why the unrouted auth screens exist and what the password-manager bridge does and does not cover, and the list of dead and duplicate widgets. "Needs particular attention" ranks the screens to examine first. "Method and limits" says what was and was not seen live.

**Finding labels.** Each finding is a *requirement* (accessibility, usability, policy or correctness breach), a *recommendation*, or a *preference*, with severity High, Medium or Low. IDs are `<area letter>-<screen number>.<n>`. This follows the labels in [`principles.md`](../principles.md#review-output-deep-tasks); every finding is written in the nine-part structure (problem, why it matters, UX impact, a11y impact, system impact, fix, reusable rule, implementation notes, acceptance checklist). A heading suffix records the second pass: "(was …)" gives the first-pass grade when it changed, "(verify)" marks a finding whose remaining doubt needs a rendered or runtime check, and "(withdrawn)" marks a first-pass claim the source did not support; withdrawn entries are kept at recommendation · Low for traceability and are not counted as open defects.


---

# Part 1 — Screen inventory

Active MVP only (Pet Care plus auth, sharing, account, subscription). Paths are under `flutter_app/lib/`. "Review" gives the finding ID prefix in Part 2.

## Entry and auth

| Screen | Route | Purpose | Source | Review |
|---|---|---|---|---|
| Landing, sign in, create account | `/landing` | Role-neutral public entry with login and signup | `features/auth/presentation/screens/landing_screen.dart`, `widgets/landing/*` | A-1 |
| Forgot password | `/forgot-password` | Request reset code, set a new password | `features/auth/presentation/screens/forgot_password_screen.dart` | A-2 |
| Experience resolve | `/app/resolve` (also `/`) | Post-login routing to Pet Care home or onboarding | `features/experience/presentation/screens/experience_resolve_screen.dart` | A-3 |
| Experience chooser | `/app/choose` | Single "start with Pet Care" card; not reached by the current login path | `features/experience/presentation/screens/experience_chooser_screen.dart` | A-4 |
| Pet Care onboarding | `/pc/onboarding` | Welcome and optional first pet | `features/experience/presentation/screens/pet_care_onboarding_screen.dart` | A-5 |
| Care desk design preview | `/preview/guardian-desk` | Internal layout preview; only registered on localhost and `*.replit.dev` | `features/experience/presentation/screens/pet_care/pet_care_desk_preview_screen.dart` | A-6 |
| My details | `/my-details` | Profile, language, timezone, password, export, delete account | `features/auth/presentation/screens/my_details_screen.dart` | A-7, D-12 |
| Secure account | `/secure-account` | Change password and sign out other sessions, from a security notification | `features/auth/presentation/screens/secure_account_screen.dart` | A-8 |
| Consent settings | `/consent-settings` | Essential, analytics and marketing consent | `core/widgets/consent/consent_settings_screen.dart` | A-9 |
| First-use consent banner | global overlay | Cookie and analytics consent prompt | `core/widgets/consent_banner.dart`, `consent/consent_banner_surface.dart` | A-10 |

## Home, pets and care

| Screen | Route | Purpose | Source | Review |
|---|---|---|---|---|
| Shell and navigation | all `/pc/*` | Bottom nav, rail, sidebar, drawer, notification bell | `features/experience/presentation/widgets/experience_shell_scaffold.dart` and navigation widgets | B-1 |
| Pet Care home (Today) | `/pc/home` | Today orientation, pets, care, away, people | `features/experience/presentation/screens/experience_home_screens.dart`, `pet_care_shell_home_content.dart` | B-2 |
| All pets | `/pc/pets` | Browse, filter, add or share | `features/experience/presentation/screens/pet_care/pet_care_all_pets_screen.dart` | B-3 |
| Bulk share select | `/pc/pets/bulk-share` | Choose pets to share | `features/experience/presentation/screens/pet_care/pet_care_bulk_share_select_screen.dart` | B-4 |
| Add pet, edit pet | `/add`, `/edit/:id` | Pet profile form | `features/experience/presentation/pet_profile/screens/pet_form_screen.dart` | B-5 |
| Pet detail | `/pet/:petId` | Profile, care, people, links to history | `features/experience/presentation/pet_profile/screens/pet_detail_screen.dart` | B-6 |
| Pet health issues | `/pet/:petId/health-issues` | Health issue list | `features/experience/presentation/pet_profile/screens/pet_health_issues_screen.dart` | B-7 |
| All care for a pet | `/pet/:petId/events` | Planned and inactive care for one pet | `features/experience/presentation/pet_profile/screens/pet_manage_events_screen.dart` | B-8 |
| All actions queue | `/pc/events` | Care agenda across pets | `core/router/experience_routes.dart` builder, `features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart` | B-9 |
| Add and edit care entry | `/care/add`, `/pet/:petId/care/add`, `/pet/:petId/events/:entryId/edit`, `/health/edit/:id` | Unified care form | `features/health_tracking/presentation/screens/health_entry_form_screen.dart` | B-10 |
| Care item detail | `/pet/:petId/events/:entryId` | Status, schedule, upcoming, history | `features/experience/presentation/care_item/detail/care_item_detail_screen.dart` | B-11 |
| Occurrence (care date) | `/pet/:petId/events/:entryId/occurrences/:occurrenceId` | Act on one scheduled date | `features/experience/presentation/care_item/occurrence/occurrence_screen.dart` | B-12 |
| Pet timeline | `/pet/:petId/timeline` | Composite history | `features/pet_profile/presentation/screens/pet_timeline_screen.dart` | B-13 |
| Weight hub | `/pet/:petId/weight` | Weight history and chart | `features/weight_tracking/presentation/screens/weight_hub_screen.dart` | B-14 |

## Away plans

| Screen | Route | Purpose | Source | Review |
|---|---|---|---|---|
| Away hub | `/pc/away` | Upcoming and past away plans | `features/pet_care/context/presentation/screens/planned_absence_hub_screen.dart` | C-1 |
| New away plan | `/pc/away/new` | Dates, pets, care preview | `features/pet_care/context/presentation/screens/planned_absence_flow_screen.dart` | C-2 |
| Away plan | `/pc/away/:id` | Carers, coverage, handover, PDF | `features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart` | C-3 |
| Edit away plan | `/pc/away/:id/edit` | Edit or cancel a plan | `features/pet_care/context/presentation/screens/planned_absence_edit_screen.dart` | C-4 |

## People and households (vets live here)

| Screen | Route | Purpose | Source | Review |
|---|---|---|---|---|
| Contacts hub | `/pc/people` | Searchable roster, two-pane on wide screens | `features/people/presentation/hub/*` | C-5 |
| Add person | `/pc/people/new` | Five-step add flow | `features/people/presentation/add/add_person_flow.dart` | C-6 |
| Person detail | `/pc/people/:personId` | Contact and relationships | `features/people/presentation/detail/person_detail_page.dart` | C-7 |
| Edit person | `/pc/people/:personId/edit` | Edit, deactivate, remove | `features/people/presentation/edit/person_edit_page.dart` | C-8 |
| Households | `/pc/people/households` | List and create | `features/people/presentation/households/households_page.dart` | C-9 |
| Household detail | `/pc/people/households/:id` | Members, invites, pets | `features/people/presentation/households/household_detail_page.dart` | C-10 |
| Legacy vet redirect | `/pc/vets/:id`, `/pc/vets/edit/:id` | Maps old vet IDs to People | `features/people/presentation/screens/legacy_vet_contact_redirect_screen.dart` | C-11 |

## Sharing and invites

| Screen | Route | Purpose | Source | Review |
|---|---|---|---|---|
| Share pet | `/pet/:petId/share`, `/pc/pets/share` | Links, email invites, access list | `features/sharing/presentation/screens/share_pet_screen.dart` | C-12 |
| Shared pet view | `/shared/:code` (public) | Link recipient preview | `features/sharing/presentation/screens/shared_pet_screen.dart` | C-13 |
| Share invite landing | `/invite/:code` (public) | Accept or decline an email share | `features/sharing/presentation/screens/invite_landing_screen.dart` | C-14 |
| Absence invite landing | `/absence-invite/:code` | Accept a temporary care invitation | `features/pet_care/context/presentation/screens/absence_invite_landing_screen.dart` | C-15 |
| Household invite landing | `/household-invite/:code` (public) | Accept or decline a household invitation | `features/people/presentation/households/household_invite_landing_screen.dart` | C-16 |
| Invite | `/pc/invite` | Invite entry from the shell | `features/experience/presentation/screens/experience_settings_screen.dart` (`ExperienceInviteScreen`) | C-17 |

## Notifications, account, subscription, help and legal

| Screen | Route | Purpose | Source | Review |
|---|---|---|---|---|
| Account | `/account` | Utility hub | `features/experience/presentation/screens/account_screen.dart` | D-1 |
| Manage pet tags | `/account/pet-tags` | Create, rename, delete tags | `features/pet_tags/presentation/screens/manage_pet_tags_screen.dart` | D-2 |
| Notifications | `/notifications` | Activity and For you inbox | `features/notifications/presentation/screens/notifications_screen.dart` | D-4 |
| Notification settings | `/notifications/settings` | Channels, care reminders, muted pets | `features/notifications/presentation/screens/notification_settings_screen.dart` | D-5 |
| Pending actions | `/pending-actions` | Placement and transfer actions from notification links | `features/notifications/presentation/screens/pending_actions_screen.dart` | D-6 |
| Subscription | `/subscription` | Entitlement, offers, restore, manage | `features/subscription/presentation/screens/paywall_screen.dart` | D-7 |
| Help | `/help` | FAQ | `features/help/presentation/screens/help_screen.dart` | D-8 |
| About | `/about` | Product description, version, legal links | `features/about/presentation/screens/about_screen.dart` | D-9 |
| Legal documents | `/legal` (public) | Index of four documents | `features/about/presentation/screens/legal_documents_screen.dart` | D-10 |
| Legal document | `/legal/:document` (public) | Reader | `features/about/presentation/screens/legal_document_screen.dart` | D-11 |
| Not found | router `errorBuilder` | Unknown route | `core/router/app_router.dart:446` | D-13 |

My details (data rights) is reviewed under both A-7 and D-12.

## Aliases and redirects (not screens)

| Route | Goes to |
|---|---|
| `/g/*` (legacy Guardian paths) | `/pc/*` |
| `/pc/settings`, `/g/settings` | `/account` |
| `/pc/notifications`, `/g/notifications` | `/pc/home` |
| `/health`, `/health/add` and pet-scoped `/health/*`, `/other/*` | `/pc/events` or the care form |
| `/pet/:petId/care-rhythms` | All care for a pet |
| `/privacy-policy`, `/terms-of-service` | `/legal/privacy-notice`, `/legal/terms-of-use` |
| `/vets`, `/vets/*`, `/g/vets*`, `/pc/vets*` | People hub (legacy vet IDs via the redirect screen) |
| `/account/people`, `/account/people/new` | `/pc/people`, `/pc/people/new` |
| `/o/*`, `/organizations*`, `/archived-pets`, `/pc/fostering`, `/g/fostering`, `/pet/:petId/fostering-session` | `/pc/home` or `/pet/:petId` |

## Excluded, and dead code found

- **Frozen:** Shelter and Fostering screens (organisation, fostering session, manage fosters, adoption screening, foster requests). Not reachable in the MVP; see [`frozen-domains`](../../engineering/frozen-domains/README.md).
- **Unrouted widgets:** standalone `LoginScreen` and `SignupScreen` (their links point to `/login` and `/signup`, which are not registered); `ExperienceSettingsScreen` (`/pc/settings` redirects to `/account`); `PlannedAbsencePlanPlaceholderScreen` (no references). The workspace toggle in the shell always renders nothing. A reachability check found 73 further active files (5,061 lines) that no live code imports, including `pet_care_today_orientation.dart`, which the first pass reviewed as part of Home. Part 5 § 5.5 explains why the two auth screens exist and § 5.6 lists everything with a delete/keep decision.

---

# Part 2 — Per-screen review

Each screen has purpose, strengths, a findings table, an attention flag and, where it adds something, a benchmark note. Area summaries and the patterns seen in each area bracket the screens.

## Area A — Entry, auth and onboarding (detailed)

This area was re-reviewed finding by finding using source-file reads, including direct children, providers, routing and relevant EN/FR ARB values. Grades follow [`system.md`](../system.md) § 6.10 (plain-language errors, meaningful retry and no raw backend messages), § 7.1 (48 dp controls, safe areas and preservation of the native web authentication bridge), § 2.3 (200% text scaling), [`tokens.md`](../tokens.md), [`terminology.md`](../terminology.md) and [`copy-tone.md`](../copy-tone.md). The nine-part structure follows [`principles.md`](../principles.md#review-output-deep-tasks). Evidence is code-based, not a claim of observed screen-reader, browser-extension or device behaviour; those dependencies are marked “verify”. Paths below are relative to `flutter_app/lib/` unless prefixed otherwise.

**Area summary.** Public entry is role-neutral, localized and scrollable, recovery has a clear two-stage form, and post-login routing deliberately chooses the active Pet Care product. The chooser is not a missing post-login step. Confirmed weaknesses are silent blank-name onboarding validation, untranslated species and account strings, unsurfaced profile-save failure, incomplete Secure account form support, raw service messages, and an invalid compact consent-button flex arrangement. Several first-pass conclusions were overstated: determinate onboarding progress has framework-provided numeric semantics, Operations colours now alias the current palette, overlay shadows are permitted, and password change clears authentication before routing, so the claimed inevitable `/login` not-found page is not supported. Frozen Shelter/Fostering removal and the standalone auth/native-bridge investigation belong to Part 5.

**Shared fix that covers most of Area A.** Apply X-5/X-7 through one guarded form-submit/status pattern, with inline validation and localized announced results; use the existing `ChangePasswordForm`, `AppFormSection`, `AppFormLabeledField` and `AppFormActionsBar` rather than another bespoke credential form. Reuse B-12.2's planned labelled progress and B-2.1's planned `AsyncErrorState` where a persistent load actually fails; do not replace editable forms with a load-error widget for ordinary field errors. Coordinate X-12 bridge work with Part 5.

---

### A-1 Landing, sign in and create account — `/landing`

- **Source:** `features/auth/presentation/screens/landing_screen.dart`, `features/auth/presentation/widgets/landing/landing_operations_desk_page.dart`, `landing_auth_card.dart`, `landing_branding_section.dart`, `landing_login_form.dart`, `landing_signup_form.dart`; `core/web/native_login_web.dart`; `flutter_app/web/index.html`.
- **Purpose:** One public entry for signing in or creating a Pet Care account.
- **Strengths (confirmed):** localized tabs and credential validation; sign-up has confirmation, visibility controls and Flutter autofill hints; login conditionally mounts the native HTML bridge and detaches on disposal; compact content scrolls and wide panes scroll independently; primary controls have a 50 dp minimum.
- **Attention flag:** Watch.

#### A-1.1 Signup lacks the login DOM bridge (verify) — A11y · requirement · Medium

1. **Problem.** `landing_signup_form.dart:43-44, 70-139` builds Flutter fields inside `AutofillGroup`, while `landing_login_form.dart:91-95` mounts `NativeLoginInlineView` when available. The DOM bridge is login-specific (`native_login_web.dart:58-76`; `flutter_app/web/index.html:180-188`); absence of signup parity is confirmed, but failure in a particular password manager needs runtime verification.
2. **Why it matters.** `system.md` § 7.1 explicitly preserves the native authentication bridge; X-12 extends the password-manager strategy across credential entry.
3. **UX impact.** Password generation, saving and filling may differ between account creation and later login.
4. **A11y impact.** Password managers reduce memory and typing burden; Flutter hints already exist, so this is not a claim that all autofill is absent.
5. **System impact.** Two credential-rendering paths need one tested contract.
6. **Proposed fix.** Extend the supported native credential strategy to signup without removing its validation, confirmation or localized labels; the detailed bridge investigation is in Part 5.
7. **Reusable rule.** X-12: every supported credential flow has a tested password-manager path.
8. **Implementation notes.** Coordinate `landing_signup_form.dart`, `core/web/native_login_web.dart` and `flutter_app/web/index.html` in Part 5; reuse ARB `email`, `newPassword`, `confirmPassword`, `showPassword` and `hidePassword`.
9. **Acceptance checklist.** Supported browsers/managers can generate, save and refill a signup password; EN/FR labels and validation remain correct; mobile Flutter autofill still works.

#### A-1.2 Eyebrow casing is transformed in the widget — i18n · recommendation · Low

1. **Problem.** `landing_branding_section.dart:62-68` applies `.toUpperCase()` to `landingDeskEyebrow`. The text is localized; this is not hard-coded English.
2. **Why it matters.** `system.md` § 2.3 and `tokens.md` permit compact uppercase eyebrows, so uppercase itself is not a breach; locale-owned casing would be easier to control.
3. **UX impact.** Minor typographic inconsistency if future locales need different casing.
4. **A11y impact.** None established.
5. **System impact.** Translators cannot fully control the displayed string.
6. **Proposed fix.** Render the localized string without transformation, or provide a dedicated approved eyebrow value per locale.
7. **Reusable rule.** X-6: localization owns displayed wording; uppercase styling stays limited to compact metadata.
8. **Implementation notes.** Update `landing_branding_section.dart` and review `landingDeskEyebrow` in `app_en.arb` and `app_fr.arb`; retain theme label styling.
9. **Acceptance checklist.** EN/FR eyebrow casing matches approved ARB values; no runtime case conversion remains at this call site.

#### A-1.3 Missing name validators are not an incomplete-identity error (withdrawn) — UX · recommendation · Low (was recommendation · Medium)

1. **Problem.** Names have no validators (`landing_signup_form.dart:48-68`), but the client service explicitly defaults both names to empty (`features/auth/data/auth_service.dart:39-44`) and the server defaults them too, requiring only email/password (`server/routes/auth/sessionRouter.js:33-45`). The first pass's implication that blank names necessarily cause a server rejection was unsupported.
2. **Why it matters.** Optional identity fields should not become mandatory without a product need.
3. **UX impact.** None established from accepting blank names.
4. **A11y impact.** None.
5. **System impact.** Client and server agree on optionality.
6. **Proposed fix.** Do not add required-name validation on this evidence; optionally label the fields as optional during a deliberate form-copy pass.
7. **Reusable rule.** Validate against the real data contract, not assumptions about a complete profile.
8. **Implementation notes.** Preserve `landing_signup_form.dart` behaviour; any optional helper would use new EN/FR ARB keys such as `firstNameOptional` and `lastNameOptional`.
9. **Acceptance checklist.** Signup with blank names succeeds when email/password are valid; no unnecessary name-required errors are introduced.

#### A-1.4 Auth card uses bespoke radius and padding — Design · recommendation · Low

1. **Problem.** `landing_auth_card.dart:30-38` uses radius 28 and padding 30. `system.md` §§ 3–4 and `tokens.md`'s landing shape guidance specify 16–17 dp cards and 24 dp featured padding.
2. **Why it matters.** This is token drift, not an established accessibility defect; the lens is corrected from A11y to Design.
3. **UX impact.** The auth surface may feel more padded than other forms, but no clipping is proven.
4. **A11y impact.** None established.
5. **System impact.** Bespoke shape values weaken shared component consistency.
6. **Proposed fix.** Use the approved card radius and featured-card padding, or explicitly approve a landing exception.
7. **Reusable rule.** X-10: shape and spacing come from the documented component family.
8. **Implementation notes.** Adjust `LandingAuthCard` in `landing_auth_card.dart`; retain its existing border, zero elevation, theme typography and localized tab labels.
9. **Acceptance checklist.** Card radius/padding match the chosen documented tokens; EN/FR forms remain readable at compact width and 200% text.

#### A-1.5 Compact story follows a long form (verify) — UX · recommendation · Low

1. **Problem.** Compact layout renders auth then story in one scroll view (`landing_operations_desk_page.dart:49-54`), and the compact hero is 350 dp (`landing_branding_section.dart:24, 39-46`). The resulting perceived page length depends on locale, viewport and active tab.
2. **Why it matters.** Context follows the primary action, which is sensible; whether the image adds excessive scrolling needs a rendered check.
3. **UX impact.** Possible extra scrolling to reach story content, not a blocked signup journey.
4. **A11y impact.** None established; the page is scrollable.
5. **System impact.** Compact story treatment can be tuned without changing authentication.
6. **Proposed fix.** Keep auth first; verify realistic compact signup and shorten or collapse the hero only if it delays useful context.
7. **Reusable rule.** X-8: decoration yields space before forms or text are compressed.
8. **Implementation notes.** Use the existing `compact` parameter in `LandingBrandingSection` and `LandingOperationsDeskPage`; keep `landingDeskHeadline` and `landingDeskBody` localized.
9. **Acceptance checklist.** At 360 dp width in EN/FR and 200% text, all form actions and legal links remain scroll-reachable; a documented compact hero choice follows visual review.

---

### A-2 Forgot password — `/forgot-password`

- **Source:** `features/auth/presentation/screens/forgot_password_screen.dart`, `features/auth/data/auth_service.dart`.
- **Purpose:** Request a reset code and replace a forgotten password.
- **Strengths (confirmed):** two separate validated forms; localized non-enumerating code-sent confirmation; one-time-code and new-password hints; confirmation/visibility controls; guarded submit buttons; scrollable safe-area layout; successful reset offers Sign in.
- **Attention flag:** Watch.

#### A-2.1 Code-sent status has no explicit announcement (verify) — A11y · requirement · Low

1. **Problem.** Code request inserts `_successMessage` into a plain icon/text container (`forgot_password_screen.dart:55-60, 163-190`), without an explicit live region or focus transfer. Whether it is announced automatically is runtime-dependent.
2. **Why it matters.** X-7 requires asynchronous status to be perceivable without watching the display.
3. **UX impact.** Sighted users see both confirmation and the next form.
4. **A11y impact.** Users may not hear that the code was sent or that the next step appeared; absence of a merged label alone is not proof of unreadable content.
5. **System impact.** The same status-wrapper pattern is needed by Secure account.
6. **Proposed fix.** Give the confirmation live-region semantics and announce/focus the reset-step heading without duplicate reading.
7. **Reusable rule.** X-7: announce a meaningful status transition, not just a spinner.
8. **Implementation notes.** Wrap the existing `resetCodeSentMessage` in a shared status wrapper in `forgot_password_screen.dart`; reuse B-12.2's planned labelled progress for submit waits.
9. **Acceptance checklist.** VoiceOver/TalkBack announces the localized confirmation once; keyboard focus reaches code entry logically; failed requests do not announce success.

#### A-2.2 Reset success displays server-authored English — i18n · requirement · Medium (was recommendation · Low)

1. **Problem.** The success dialog displays repository `message` directly (`forgot_password_screen.dart:78-98`); `auth_service.dart:264-268` returns the response message, and `server/routes/auth/passwordRouter.js:163` supplies literal English, “Password has been reset successfully”.
2. **Why it matters.** This is confirmed untranslated production copy, not merely a hypothetical variable tone; `terminology.md` requires all user-facing strings in ARB.
3. **UX impact.** French recovery finishes with an English confirmation.
4. **A11y impact.** Assistive technology receives the same mixed-language content.
5. **System impact.** Service response prose is coupled to presentation.
6. **Proposed fix.** Show a localized reset-completed body after confirmed success; keep the existing Sign in action.
7. **Reusable rule.** X-6 and X-5: localize presentation and report only confirmed results.
8. **Implementation notes.** Replace `Text(message)` in `forgot_password_screen.dart` with a new `passwordResetSuccessMessage` ARB key in EN/FR; retain existing `passwordResetTitle`, `signIn` and `/landing`.
9. **Acceptance checklist.** A French reset shows only French confirmation copy; changing the service's message does not change the dialog; Sign in opens `/landing`.

#### A-2.3 Code validator checks length, not digits — UX · recommendation · Low

1. **Problem.** `forgot_password_screen.dart:295-301` selects a numeric keyboard and six-character limit, but validates only trimmed length; no digit filter or numeric pattern exists.
2. **Why it matters.** A keyboard hint does not constrain pasted text.
3. **UX impact.** Six non-digit characters can reach the API and produce an avoidable rejection.
4. **A11y impact.** None specific; this is input guidance rather than a demonstrated A11y breach, so the lens changes from A11y to UX.
5. **System impact.** Client validation is looser than the “6-digit code” copy.
6. **Proposed fix.** Validate six digits and optionally filter input, preserving paste and one-time-code autofill.
7. **Reusable rule.** Form validation matches the format described beside the field.
8. **Implementation notes.** In `forgot_password_screen.dart`, add a digit-pattern validator or `FilteringTextInputFormatter.digitsOnly` via Flutter services; reuse `enterSixDigitCode` and `codeRequired`.
9. **Acceptance checklist.** Six letters fail locally; a valid six-digit pasted/autofilled code is accepted; EN/FR errors remain localized.

#### A-2.4 Recovery failures print service exceptions — UX · requirement · Medium

1. **Problem.** Both request and reset catches assign `e.toString().replaceFirst('Exception: ', '')`, then render `_error` (`forgot_password_screen.dart:61-65, 109-113, 192-215`). The service forwards backend `error` or English fallback text (`auth_service.dart:243-245, 264-266`).
2. **Why it matters.** `system.md` § 6.10 forbids raw backend messages; removing an exception prefix is not user-facing error mapping.
3. **UX impact.** Connectivity, expired-code and service failures can produce technical or untranslated wording.
4. **A11y impact.** Raw text is also spoken; explicit announcement should follow A-2.1.
5. **System impact.** Shared auth error mapping would serve Secure account and account forms too.
6. **Proposed fix.** Map known failures to calm localized messages, keep values for correction, and offer meaningful retry through the existing submit action.
7. **Reusable rule.** X-1/X-6: exceptions are logged, never rendered as copy.
8. **Implementation notes.** Update `forgot_password_screen.dart` with typed failure mapping; add EN/FR `resetRequestFailed`, `resetCodeInvalidOrExpired` and `passwordResetFailed`, reusing current form buttons rather than a full-page `AsyncErrorState`.
9. **Acceptance checklist.** Network/500/invalid-code tests show localized copy without exception text; retry reuses the entered email/code appropriately; busy state prevents duplicate requests.

---

### A-3 Experience resolve — `/app/resolve`

- **Source:** `features/experience/presentation/screens/experience_resolve_screen.dart`, `presentation/providers/experience_providers.dart`, `domain/services/experience_eligibility.dart`, `domain/services/pet_care_onboarding_rules.dart`.
- **Purpose:** Resolve authenticated entry into Pet Care home or first-pet onboarding.
- **Strengths (confirmed):** one navigation guard; existing and newly arriving provider data are handled; active Pet Care destination is deliberate; onboarding depends on owned-pet data and completion state.
- **Attention flag:** Watch.

#### A-3.1 Multi-domain eligibility is dormant MVP plumbing — UX · recommendation · Low (was recommendation · Medium)

1. **Problem.** `experience_providers.dart:33-49` fixes organisation membership to zero/false and `:59-72` resolves only Pet Care. `experience_eligibility.dart:18-37` retains multi-experience logic, but no supported second domain is being withheld.
2. **Why it matters.** Shelter/Fostering are frozen and scheduled for deletion; restoring membership fetching or inserting a chooser is not an MVP UX fix.
3. **UX impact.** None established for active users; direct Pet Care entry is appropriate.
4. **A11y impact.** None.
5. **System impact.** Unused parameters and domain concepts complicate routing maintenance.
6. **Proposed fix.** Simplify active destination resolution during frozen-domain removal, retaining the first-pet decision; refer deletion boundaries to Part 5.
7. **Reusable rule.** X-4: remove frozen abstractions rather than reconnecting them to active entry.
8. **Implementation notes.** Simplify `experience_providers.dart` and its use in `experience_resolve_screen.dart`; retain `PetCareOnboardingRules` and `petCareOnboardingCompletedProvider`, with route tests for both Pet Care outcomes.
9. **Acceptance checklist.** Login reaches home or onboarding without `/app/choose`; no new Shelter/Fostering membership query is introduced; destination tests pass.

#### A-3.2 Routing wait has no purpose label — A11y · recommendation · Low

1. **Problem.** `experience_resolve_screen.dart:63` returns a centered `CircularProgressIndicator` without a semantic label. Framework spinner semantics do not name why entry is waiting.
2. **Why it matters.** A short routing wait can become long on a weak connection.
3. **UX impact.** Sighted users see progress but no context.
4. **A11y impact.** Loading role alone gives less orientation than “Opening Pet Care”.
5. **System impact.** This is the same labelled-progress gap as B-12.2.
6. **Proposed fix.** Use shared labelled progress with localized routing status.
7. **Reusable rule.** X-7: every wait has a meaningful localized label.
8. **Implementation notes.** Import `AppLocalizations` in `experience_resolve_screen.dart`; add `openingPetCare` to both ARBs and reuse the progress pattern planned in B-12.2.
9. **Acceptance checklist.** While `experienceEligibilityProvider` is loading, the semantics tree contains the routing label; resolved data navigates once.

#### A-3.3 Eligibility failure silently hands off to Home — UX · recommendation · Medium

1. **Problem.** `experience_resolve_screen.dart:54-59` routes an eligibility error to `/pc/home` with no notice. Eligibility is derived from `petListProvider` (`experience_providers.dart:35-42`), so this bypasses the normal onboarding decision after a pet-load failure.
2. **Why it matters.** Unknown pet state is not a verified reason to bypass setup, but the fallback itself makes no “all clear” claim; it is not graded as a false-status requirement.
3. **UX impact.** Entry may hand users to Home's load-error state instead of explaining the routing interruption.
4. **A11y impact.** No routing failure is announced.
5. **System impact.** Recovery responsibility is split between resolver and Home (B-2.1).
6. **Proposed fix.** Prefer a persistent localized routing error with Retry, or explicitly hand off error recovery to a corrected Home without claiming eligibility resolved.
7. **Reusable rule.** X-1/X-2: unresolved routing data stays distinct from a successful destination decision.
8. **Implementation notes.** Use planned `AsyncErrorState` in `experience_resolve_screen.dart` with `ref.invalidate(petListProvider)`; add `entryResolutionFailed` and reuse `retry`; keep `_navigated` false until actual navigation.
9. **Acceptance checklist.** A pet-load failure has a visible recovery path; after retry, a new user reaches onboarding and an existing user reaches Home; no duplicate navigation occurs.

---

### A-4 Experience chooser — `/app/choose`

- **Source:** `features/experience/presentation/screens/experience_chooser_screen.dart`, `core/router/experience_routes.dart`, `features/experience/presentation/providers/experience_providers.dart`.
- **Purpose:** A directly addressable, single-action setup entry, not the current post-login gateway.
- **Strengths (confirmed):** route is registered; one localized full-row action uses the existing onboarding destination rules.
- **Attention flag:** None.

#### A-4.1 Chooser is not an active journey requirement — UX · recommendation · Low (was requirement · Medium)

1. **Problem.** `/app/choose` exists (`experience_routes.dart:29-33`) and renders one Pet Care action (`experience_chooser_screen.dart:38-49`), but `resolvePostLoginPath` never returns it (`experience_providers.dart:59-72`). That is intentional single-product routing, not a broken step users must traverse.
2. **Why it matters.** Frozen domains are out of scope; a second destination should not be resurrected to justify this screen.
3. **UX impact.** No normal login impact; only direct entry exposes a redundant choice.
4. **A11y impact.** None established.
5. **System impact.** Dormant route and historical comments increase maintenance.
6. **Proposed fix.** Retire the chooser or redirect it to the resolver as part of Part 5's frozen/legacy cleanup.
7. **Reusable rule.** X-4/X-11: only supported, necessary steps belong in active entry.
8. **Implementation notes.** Update the `experienceChoose` registration in `experience_routes.dart` if retired; preserve incoming links with a safe `/app/resolve` redirect and keep active onboarding rules.
9. **Acceptance checklist.** Post-login route tests never require the chooser; direct `/app/choose` reaches a registered Pet Care destination if retired; no frozen choice is added.

#### A-4.2 Retained chooser heading is generic — Copy · recommendation · Low

1. **Problem.** The screen uses `ftueTitle` and `ftueSubtitle` (`experience_chooser_screen.dart:34-38`); their EN values ask “What would you like to do first?” above a single action (`app_en.arb:2165-2168`).
2. **Why it matters.** Generic welcome copy implies more choice than is present.
3. **UX impact.** Minor uncertainty on a route outside normal entry.
4. **A11y impact.** None beyond the same wording.
5. **System impact.** Do not spend on copy for a screen about to be deleted.
6. **Proposed fix.** If retained, call it Pet Care setup; otherwise resolve through A-4.1 without adding copy.
7. **Reusable rule.** `copy-tone.md`: each message makes the actual next step clearer.
8. **Implementation notes.** Reuse `petCareOnboardingTitle` or add a precise EN/FR setup key in `experience_chooser_screen.dart`; unused frozen `ftueActionRunShelter*` and `ftueActionFostering*` keys belong to Part 5, not this active screen.
9. **Acceptance checklist.** A retained screen's title describes its sole action in EN/FR; a retired screen introduces no new translation work.

---

### A-5 Pet Care onboarding — `/pc/onboarding`

- **Source:** `features/experience/presentation/screens/pet_care_onboarding_screen.dart`, `features/experience/data/pet_care_onboarding_store.dart`, `core/utils/constants.dart`.
- **Purpose:** Welcome a new user and optionally create their first pet.
- **Strengths (confirmed):** two steps, a skip action, localized labels, save-busy protection, a scrollable pet-entry step and a determinate progress bar; completion navigates to registered Pet Care home.
- **Attention flag:** FLAG.

#### A-5.1 Blank pet name makes Finish silently do nothing — UX · requirement · Medium

1. **Problem.** `_nextStep` returns for a blank name and `_finish` repeats that silent guard (`pet_care_onboarding_screen.dart:49-52, 72-76`), while Finish is disabled only for `_isSaving` (`:144-159`). The name is a plain `TextField` without an error channel (`:235-243`).
2. **Why it matters.** An enabled action that fails without explanation is a usability breach in first-use setup.
3. **UX impact.** Users can reasonably think Finish is broken.
4. **A11y impact.** No error text, announcement or focus cue explains what must change.
5. **System impact.** Onboarding bypasses the standard form-validation pattern used in recovery and password change.
6. **Proposed fix.** Validate the trimmed name inline on Finish, focus the name field and keep Skip as the explicit alternative.
7. **Reusable rule.** X-5: rejected required input produces a visible, actionable inline explanation.
8. **Implementation notes.** Convert `_PetStep` to a `Form`/`TextFormField` in `pet_care_onboarding_screen.dart`, using existing `petNameRequired` and a parent-held `GlobalKey<FormState>`/focus node; reuse `AppFormLabeledField` where appropriate.
9. **Acceptance checklist.** Blank/whitespace Finish displays the localized required message and focuses name; no request is sent; a valid name sends one create request; Skip remains available when idle.

#### A-5.2 Progress lacks step wording, not all semantics — A11y · recommendation · Low (was requirement · Medium)

1. **Problem.** `pet_care_onboarding_screen.dart:114-119` supplies `value: (_step + 1) / _stepCount` but no step label. Contrary to the first pass, Flutter supplies determinate progress semantics with numeric value and range (`.cache/agatha-track/flutter-3.44.0-linux/packages/flutter/lib/src/material/progress_indicator.dart:146-158` in the local SDK cache).
2. **Why it matters.** “Step 1 of 2” is clearer than an unexplained 50/100 value, but this is not a proven colour-only or missing-value failure.
3. **UX impact.** Users do not see how many steps remain.
4. **A11y impact.** Existing numeric progress is useful; a purpose/step label would improve orientation.
5. **System impact.** Can share the labelled-progress convention with B-12.2.
6. **Proposed fix.** Add visible localized step text and equivalent semantics without removing the determinate value.
7. **Reusable rule.** X-7: name the unit of progress as well as its quantity.
8. **Implementation notes.** Add `onboardingStepOfTotal` with integer placeholders to EN/FR ARBs; render it beside the indicator in `pet_care_onboarding_screen.dart` and avoid announcing both duplicate numeric and textual labels.
9. **Acceptance checklist.** Steps display localized “1 of 2” and “2 of 2”; semantics expose meaningful progress; completion is not conveyed by colour alone.

#### A-5.3 Welcome step may overflow at large text (verify) — A11y · recommendation · Medium

1. **Problem.** The welcome page is a non-scrolling `Column` with a 72 dp icon and fixed gaps (`pet_care_onboarding_screen.dart:185-205`) inside an `Expanded` PageView above the separate bottom action (`:120-162`). Actual overflow depends on viewport, keyboard and text metrics.
2. **Why it matters.** `system.md` §§ 2.3 and 7.1 require 200% text support; source shows risk, not a measured failure.
3. **UX impact.** Short displays may crowd the introduction or bottom action.
4. **A11y impact.** Enlarged text could become inaccessible if the page exceeds its allotted height.
5. **System impact.** The pet step already uses a `ListView`, offering a local reference.
6. **Proposed fix.** Verify at short portrait sizes; make welcome content scrollable while retaining the reachable primary action if content does not fit.
7. **Reusable rule.** X-8: content-driven forms and welcome pages scroll rather than clip at 200%.
8. **Implementation notes.** Replace `_WelcomeStep`'s fixed column arrangement in `pet_care_onboarding_screen.dart` with a constrained scrollable layout; retain existing `petCareOnboardingWelcomeTitle`/`Body` ARB keys and check bottom safe-area treatment.
9. **Acceptance checklist.** At 360 × 640 dp with 200% EN/FR text, all welcome content and Continue are reachable without overflow; the pet step remains keyboard-scrollable.

#### A-5.4 Skip has no persistence busy/error handling — UX · recommendation · Low

1. **Problem.** `_skip` awaits local completion and navigates without its own busy flag/catch (`pet_care_onboarding_screen.dart:38-47`); its button is guarded only by the separate create-save flag (`:105-108`). `PetCareOnboardingStore.markCompleted` also ignores boolean write results (`pet_care_onboarding_store.dart:17-19`).
2. **Why it matters.** A thrown write can strand the wizard silently, while a false write result can allow exit without persistence; the first pass described only the former.
3. **UX impact.** Repeated taps or repeated setup on the next entry are possible.
4. **A11y impact.** No skip-wait or failure status is exposed.
5. **System impact.** Completion persistence needs an explicit result contract shared by Skip and Finish.
6. **Proposed fix.** Guard Skip while awaiting and handle both thrown and unsuccessful writes with localized retryable feedback.
7. **Reusable rule.** X-5/X-7: completion includes persistence outcome, busy protection and a perceivable result.
8. **Implementation notes.** Return a checked result from `PetCareOnboardingStore.markCompleted`, consume it in `pet_care_onboarding_screen.dart`, and add `onboardingCompletionSaveFailed` in EN/FR; reuse labelled progress rather than another unlabelled spinner.
9. **Acceptance checklist.** Slow persistence disables Skip/Finish consistently; false/throwing writes show a localized retry path; success navigates once and completion survives re-entry.

#### A-5.5 Species are confirmed English literals — i18n · requirement · Medium (was recommendation · Low)

1. **Problem.** The dropdown displays `Text(s)` from `AppConstants.species` (`pet_care_onboarding_screen.dart:252-254`), whose values include Dog, Cat, Bird and Other (`core/utils/constants.dart:14-23`). French translations already exist (`app_fr.arb:780-788`).
2. **Why it matters.** This is confirmed user-visible English in French, a requirement under `terminology.md`'s localization rule, not “may remain English”.
3. **UX impact.** French first-use setup mixes languages.
4. **A11y impact.** Species options are spoken in the wrong language.
5. **System impact.** Other pet forms already separate stable values from translated labels.
6. **Proposed fix.** Localize display labels while keeping stored species values unchanged.
7. **Reusable rule.** X-6: stable enum/data values are never used as localized labels.
8. **Implementation notes.** Extract/reuse the mapping in `features/pet_profile/presentation/screens/widgets/pet_species_section.dart:18-39`; use `speciesDog` through `speciesOther` in `pet_care_onboarding_screen.dart`, without migrating persisted strings.
9. **Acceptance checklist.** French dropdown shows Chien/Chat/Oiseau/Autre; selecting Chien still sends `Dog`; all supported species are translated in EN/FR.

#### A-5.6 Onboarding save feedback embeds the exception — UX · requirement · Medium

1. **Problem.** The save catch displays `l.failedToSaveOnboarding(e.toString())` (`pet_care_onboarding_screen.dart:62-65`); the FR ARB interpolates `{error}` directly (`app_fr.arb:2133-2134`).
2. **Why it matters.** `system.md` § 6.10 prohibits raw backend messages even inside a localized wrapper.
3. **UX impact.** Creation or persistence failure produces technical text rather than a next step.
4. **A11y impact.** A transient snackbar may not provide a reliable correction target; raw details are spoken too.
5. **System impact.** The catch spans pet creation and local completion persistence, which need different recovery behaviour.
6. **Proposed fix.** Use localized failure categories and retain fields; if the pet was created but completion persistence failed, retry only persistence rather than creating another pet.
7. **Reusable rule.** X-1/X-5: plain-language failure and honest partial-success handling.
8. **Implementation notes.** Split create/persist outcomes in `_finish` in `pet_care_onboarding_screen.dart`; replace exception interpolation with new `onboardingPetSaveFailed` and A-5.4's `onboardingCompletionSaveFailed`; log details outside UI.
9. **Acceptance checklist.** API failure displays localized copy and preserves input; persistence failure after creation does not create a duplicate on retry; no exception string reaches the widget tree.

---

### A-6 Care desk design preview — `/preview/guardian-desk`

- **Source:** `features/experience/presentation/screens/pet_care/pet_care_desk_preview_screen.dart`; `core/router/app_router.dart`.
- **Purpose:** Internal populated-layout reference with synthetic pets and care/professional rows.
- **Strengths (confirmed):** synthetic data is documented; production route registration is host-gated (`app_router.dart:25-30, 144-149`); the preview reuses `PetCareOperationsDeskLayout`.
- **Attention flag:** None.

#### A-6.1 Preview contains English-only sample copy — i18n · requirement · Low

1. **Problem.** `pet_care_desk_preview_screen.dart:94-120` hard-codes sample care/status/professional text. This is a development-only exception in severity, not production copy debt.
2. **Why it matters.** A French preview is mixed-language and cannot demonstrate translated layout accurately.
3. **UX impact.** Internal review may overestimate localization readiness.
4. **A11y impact.** Preview semantics inherit English sample text.
5. **System impact.** The sample also includes a foster/org pet (`:42-50`); frozen-domain sample removal belongs to Part 5 and is not a reason to expand that domain.
6. **Proposed fix.** Localize meaningful sample statuses or explicitly label the preview English-only; remove the frozen-domain fixture during Part 5.
7. **Reusable rule.** X-6/X-4: preview scope is explicit and does not become active-product guidance.
8. **Implementation notes.** Update only the preview implementation in a future task; reuse localized status keys and introduce a preview-only `designPreviewEnglishOnly` key if choosing disclosure, without treating fictitious proper names as translatable production copy.
9. **Acceptance checklist.** French preview either has translated operational labels or an explicit language disclaimer; no frozen-domain fixture is used as active MVP acceptance evidence.

#### A-6.2 Preview demonstrates only a populated state — Design · preference · Low

1. **Problem.** The layout is always fed static non-empty pets and rows (`pet_care_desk_preview_screen.dart:76-120`); no state selector or async variants exist.
2. **Why it matters.** A populated-only reference cannot validate loading, empty and error layouts, but this is not a production usability defect.
3. **UX impact.** None for production users.
4. **A11y impact.** None established.
5. **System impact.** Internal design acceptance has limited state coverage.
6. **Proposed fix.** Add state variants only if this preview is retained as an acceptance tool.
7. **Reusable rule.** State demonstrations should cover the states they claim to validate.
8. **Implementation notes.** In `pet_care_desk_preview_screen.dart`, reuse planned `AsyncErrorState`, labelled progress and real empty-state widgets rather than inventing alternate sample components; a selector needs localized preview labels.
9. **Acceptance checklist.** If adopted for state review, loading/empty/error/populated can each be selected; no variant changes the production router gate or calls live APIs.

---

### A-7 My details — `/my-details`

- **Source:** `features/auth/presentation/screens/my_details_screen.dart`, `widgets/my_details/profile_settings_section.dart`, `profile_editor_sheet.dart`, `widgets/change_password_form.dart`, `account_actions_section.dart`, `features/auth/application/auth_providers.dart`.
- **Purpose:** Profile, language/timezone, password and account utility actions; export/deletion outcomes are also covered in Area D.
- **Strengths (confirmed):** bounded scrollable layout; editor dirty/busy controls; password form has validation, confirmation, autofill hints and tooltip-labelled visibility actions; deletion asks for a password and shows consequence copy.
- **Attention flag:** FLAG.

#### A-7.1 Timezone, bio hint and photo semantics are English literals — i18n · requirement · Medium

1. **Problem.** `profile_settings_section.dart:78` displays “Time zone”; `profile_editor_sheet.dart:186-188, 229-231` uses English photo semantics and bio hint.
2. **Why it matters.** `terminology.md` requires localization of all user-facing strings, including assistive labels.
3. **UX impact.** French account editing mixes languages.
4. **A11y impact.** The photo's action is announced in English.
5. **System impact.** Shared form widgets do not prevent literal helper/semantic copy.
6. **Proposed fix.** Move the three strings into EN/FR ARB resources.
7. **Reusable rule.** X-6: helper text and semantics are part of localization, not implementation detail.
8. **Implementation notes.** Add `timeZoneLabel`, `profileBioHint` and `profilePhotoChangeLabel` to both ARBs and wire them in the two files; retain `AppFormLabeledField` and existing photo-button semantics.
9. **Acceptance checklist.** In French the timezone title, bio hint and photo semantic label are translated; no new literal English appears in these controls.

#### A-7.2 Preference-save failures are not surfaced — UX · requirement · Medium (was recommendation)

1. **Problem.** Locale changes update `localeProvider` immediately and invoke `updateProfile` without awaiting; timezone updates are also fire-and-forget (`my_details_screen.dart:170-179`). `updateProfile` catches failures into `auth.error` (`application/auth_providers.dart:202-230`), but this screen does not display that state.
2. **Why it matters.** The local language can diverge from the saved preference without explanation; this is correctness feedback, not just a missing progress nicety.
3. **UX impact.** Language may revert on another device/session; timezone failure leaves the previous user value rather than reliably showing the newly selected value, correcting the first pass's blanket “selection looks persisted” claim.
4. **A11y impact.** No status reports success or failure.
5. **System impact.** Global auth loading/error is not a usable per-preference save contract.
6. **Proposed fix.** Give these changes explicit pending/result state, report failures and reconcile local locale with the confirmed saved value.
7. **Reusable rule.** X-5/X-7: a persisted setting exposes its actual outcome.
8. **Implementation notes.** Update callbacks in `my_details_screen.dart` and status props in `profile_settings_section.dart`; have `authProvider.notifier.updateProfile` return a typed result rather than swallowing failure, and add localized `profilePreferenceSaveFailed`/saved status keys.
9. **Acceptance checklist.** A failed locale update is reported and the local/server preference mismatch is resolved explicitly; a failed timezone update is reported; slow saves disable only affected controls and cannot overlap.

#### A-7.3 Inevitable password-success not-found page is not supported (withdrawn) — UX · recommendation · Low (was requirement · High)

1. **Problem.** `/login` is indeed unregistered and is requested after a two-second delay (`my_details_screen.dart:102-116`), but `changePassword` first clears tokens and sets signed-out state (`application/auth_providers.dart:270-282`). The auth refresh and signed-out guard redirect to `/landing` (`app_router.dart:32-43, 83-88, 111-123`); GoRouter 14.8.1 runs the top-level redirect even on initial unmatched routes (`lib/src/parser.dart:90-101`, `configuration.dart:412-426` in the installed package).
2. **Why it matters.** The first pass skipped the sign-out transition: an inevitable error page after successful change is not established. If `/login` is opened while still signed in, the guard returns null and `app_router.dart:446-447` supplies the not-found page.
3. **UX impact.** Stale destination code remains, but the ordinary success path is guarded to the registered landing page, not proven broken.
4. **A11y impact.** None established for the withdrawn dead-end claim.
5. **System impact.** The delayed callback may never execute because the auth redirect unmounts the screen.
6. **Proposed fix.** Remove the delayed stale navigation and explicitly coordinate signed-out landing confirmation with the actual session-clearing result.
7. **Reusable rule.** X-11/X-5: verify the whole auth transition before diagnosing a route failure.
8. **Implementation notes.** Use named route `landing` in `my_details_screen.dart` if explicit navigation is retained; preserve token clearing in `authProvider`; add a localized landing success key instead of relying on transient password-form content.
9. **Acceptance checklist.** A successful password change clears credentials and reaches `/landing` without a not-found page; no `/login` call remains; failure leaves the user signed in with actionable feedback.

#### A-7.4 Section hierarchy can be clearer, but a password heading exists — UX · recommendation · Low (was recommendation · Medium)

1. **Problem.** `my_details_screen.dart:154-225` stacks settings, password and utility groups; however, `ChangePasswordForm` explicitly uses `AppFormSection(title: l10nChangePassword)` (`change_password_form.dart:64-72`). The first pass's “no visible section headings” claim was too broad.
2. **Why it matters.** Additional localized group headings may help scanning, but this is not one continuous unlabelled form.
3. **UX impact.** Minor extra scanning among preferences and account utilities.
4. **A11y impact.** More semantic headings could shorten navigation, but the existing password heading must be preserved.
5. **System impact.** `profile_settings_section.dart:47-54` also exposes My organisations via `/organizations` (`my_details_screen.dart:169`), which is a frozen-domain redirect (`frozen_domain_route_stubs.dart:7-10`); remove that entry in Part 5, not by restoring the domain.
6. **Proposed fix.** Preserve the password section; consider Preferences and Account actions headings after removing the frozen organisation row.
7. **Reusable rule.** X-4 plus: group settings by task and distinguish destructive utilities without inventing redundant headings.
8. **Implementation notes.** Reuse `AppFormSection` or a shared semantic section heading in `profile_settings_section.dart` and `account_actions_section.dart`; add EN/FR `accountPreferencesHeading` and `accountActionsHeading` only if these groups are retained.
9. **Acceptance checklist.** Password remains visibly labelled; any added groups are localized and exposed as headings; no active organisation utility remains after Part 5 cleanup.

#### A-7.5 Empty delete password fails silently — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** Delete uses a plain `TextField` and returns immediately on empty trimmed password (`my_details_screen.dart:275-284, 297-300`) without inline feedback.
2. **Why it matters.** An enabled destructive confirmation must explain rejected input; X-5 specifically requires inline validation.
3. **UX impact.** Users do not know why Delete did nothing.
4. **A11y impact.** No error is announced or associated with the field; the issue affects all users, so UX replaces the first-pass A11y lens.
5. **System impact.** This overlaps Area D's deletion specification; implement once, not as two competing dialogs.
6. **Proposed fix.** Keep the dialog open, validate the password inline and focus the invalid field; coordinate the full destructive flow with D-12.
7. **Reusable rule.** X-5: confirmations validate before dismissing and expose an actionable result.
8. **Implementation notes.** Change the dialog in `my_details_screen.dart` to a stateful `Form`/`TextFormField` using `currentPasswordRequired`, existing `cancel` and `deleteAccount`; reuse shared confirm-and-act work from Area D.
9. **Acceptance checklist.** Empty/whitespace submission stays in the dialog with a localized field error and no API request; valid input follows the Area D busy/error contract.

#### A-7.6 Profile editor reports success after a failed profile update — UX · requirement · Medium

1. **Problem.** Editor `_save` awaits `widget.onSave` then closes and shows `profileUpdated` (`profile_editor_sheet.dart:111-127`); its caller merely awaits `updateProfile` (`my_details_screen.dart:82-89`). That notifier catches repository errors and returns normally (`application/auth_providers.dart:213-230`), so the editor's catch cannot detect profile-update failure.
2. **Why it matters.** `system.md:642-644` requires completion messages to state the confirmed result; this path can claim success without a saved profile.
3. **UX impact.** Users trust changes that were not persisted and lose the open editing context.
4. **A11y impact.** The false success snackbar is the only result message.
5. **System impact.** A photo upload can succeed before profile fields fail, making explicit partial-result handling important.
6. **Proposed fix.** Return/propagate a typed save outcome, keep the sheet and entered values on failure, and report completed versus failed portions honestly.
7. **Reusable rule.** X-5: a swallowed exception cannot be interpreted as confirmed save success.
8. **Implementation notes.** Change `authProvider.notifier.updateProfile` in `application/auth_providers.dart`, then consume the result in `my_details_screen.dart` and `profile_editor_sheet.dart`; retain `AppFormActionsBar` and add localized `profileSaveFailed`/partial-result keys without raw exception interpolation.
9. **Acceptance checklist.** A failed `updateMe` keeps the editor open and never shows `profileUpdated`; retry preserves input; successful upload plus failed profile text is accurately reported; full success closes once.

---

### A-8 Secure account — `/secure-account`

- **Source:** `features/auth/presentation/screens/secure_account_screen.dart`, `features/auth/application/auth_providers.dart`, `features/auth/data/auth_service.dart`, `core/router/app_router.dart`.
- **Purpose:** Change a password during a security response and carry an optional notification identifier to the service.
- **Strengths (confirmed):** localized explanation and field labels; `_busy` prevents duplicate submission; errors remain in the form; safe-area scrollable body; notification context is forwarded.
- **Attention flag:** FLAG.

#### A-8.1 Security form has no client validation or typo recovery — UX · requirement · Medium (was requirement · High)

1. **Problem.** Both inputs are obscured plain `TextField`s with no validator, confirmation or visibility control (`secure_account_screen.dart:72-82`), and `_submit` sends them without checking (`:31-44`). The server rejects missing/weak values (`server/routes/auth/secureAccountRouter.js:38-45`), so this is not evidence of accepting empty credentials or compromised account data.
2. **Why it matters.** Sensitive input needs actionable correction; server-side rejection limits the demonstrated harm to usability, so High was excessive.
3. **UX impact.** Empty, short or mistyped new passwords reach the service unnecessarily; hidden typos are harder to discover.
4. **A11y impact.** No field-associated required/policy errors identify what to fix.
5. **System impact.** A more complete `ChangePasswordForm` already exists on My details.
6. **Proposed fix.** Reuse its validated credential pattern, current/new roles, confirmation and visibility controls while preserving Secure account's security-specific action and explanation.
7. **Reusable rule.** X-5: sensitive forms validate inline and offer a practical typo-recovery path.
8. **Implementation notes.** Adapt `widgets/change_password_form.dart` or extract shared fields for `secure_account_screen.dart`; use `currentPasswordRequired`, `newPasswordRequired`, `atLeast6Characters`, `confirmNewPassword`, `passwordsDoNotMatch`, and existing show/hide ARB keys; confirm the policy with the auth contract rather than inventing a stronger rule.
9. **Acceptance checklist.** Empty/short/mismatched values show localized inline errors without a request; valid values submit once; current/new visibility toggles have localized tooltips and 48 dp targets; server validation remains authoritative.

#### A-8.2 Current/new password autofill roles are absent — A11y · requirement · Medium

1. **Problem.** `secure_account_screen.dart:72-82` has neither `autofillHints` nor an `AutofillGroup`; unlike My details, it does not identify current versus replacement credentials.
2. **Why it matters.** Password-manager support reduces memory/typing demands and is part of the authentication strategy preserved by `system.md` § 7.1.
3. **UX impact.** Filling the current password and generating/saving the new one has no explicit Flutter autofill contract.
4. **A11y impact.** Users relying on stored/generated credentials receive less support; actual manager-specific behaviour must be tested, not assumed.
5. **System impact.** Credential flows differ across the app.
6. **Proposed fix.** Add current/new password hints and a group as part of the shared credential form; keep web bridge parity scoped to Part 5.
7. **Reusable rule.** X-12: declare credential purpose and test the supported platform strategy.
8. **Implementation notes.** Reuse `ChangePasswordForm`'s `AutofillHints.password`/`newPassword` in `secure_account_screen.dart`; retain existing localized labels; coordinate `native_login_web.dart` and `flutter_app/web/index.html` only through Part 5.
9. **Acceptance checklist.** Semantics/autofill configuration distinguishes current/new/confirm fields; supported mobile managers fill/generate correctly; web bridge tests follow Part 5 without regressing login.

#### A-8.3 Failure text exposes the raw service error — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** `_error` is derived from `e.toString()` with only the exception prefix removed (`secure_account_screen.dart:52-55`) and rendered directly (`:83-90`); `auth_service.dart:207-209` forwards backend error text. The first pass's “colour-only” wording was inaccurate: there is visible explanatory text, just not controlled localized copy or explicit live-region semantics.
2. **Why it matters.** `system.md` § 6.10 prohibits raw backend messages, making this a requirement rather than a cosmetic status recommendation.
3. **UX impact.** English, technical or inconsistent failures appear during a security task.
4. **A11y impact.** Text is available to read but automatic announcement is not established; preserve focus and explicitly expose status.
5. **System impact.** Same localized auth failure mapping as A-2.4.
6. **Proposed fix.** Map known credential/network failures to localized actionable text; expose one announced status and keep entered values for correction.
7. **Reusable rule.** X-1/X-6/X-7: localized errors are both readable and perceivable without rendering exceptions.
8. **Implementation notes.** Replace exception interpolation in `secure_account_screen.dart` with typed failure handling; add EN/FR `secureAccountFailed`/`secureAccountCurrentPasswordIncorrect` and use the shared form-status wrapper rather than a primary-load `AsyncErrorState`.
9. **Acceptance checklist.** Incorrect-current-password, offline and 500 responses show localized text without raw details; the status is announced once in screen-reader testing; the form remains usable for retry.

#### A-8.4 Success assumes a previous route (verify) — UX · recommendation · Medium

1. **Problem.** Success calls `context.pop()` unconditionally and then obtains snackbar/localizations from the same context (`secure_account_screen.dart:45-50`). `/secure-account` is a top-level route accepting notification context (`app_router.dart:165-170`); its builder supplies no guaranteed previous page.
2. **Why it matters.** Direct entry and notification entry need an explicit completion destination; the actual stack and post-pop context lifetime depend on runtime entry.
3. **UX impact.** A direct-open success may have nothing useful to pop to, or its confirmation may not appear where expected.
4. **A11y impact.** Destination/focus and success announcement may be lost.
5. **System impact.** Shared post-action routing can handle both pushed and direct routes.
6. **Proposed fix.** Pop only when a useful in-app predecessor exists; otherwise navigate to Account or Pet Care home and display the confirmed result there.
7. **Reusable rule.** X-11: every completion path works without navigation history.
8. **Implementation notes.** Update `secure_account_screen.dart` using `context.canPop()` plus a registered fallback such as `/account`; resolve the messenger/result delivery before navigation or pass result state to the destination, retaining `secureAccountSuccess` and `notificationId`.
9. **Acceptance checklist.** Both pushed and fresh deep-link sessions complete at a usable registered destination; one localized success message appears; no cannot-pop exception or deactivated-context lookup occurs.

---

### A-9 Consent settings — `/consent-settings`

- **Source:** `core/widgets/consent/consent_settings_screen.dart`, `consent_preferences_sheet.dart`, `core/services/consent_service.dart`.
- **Purpose:** Review and save essential and optional consent preferences.
- **Strengths (confirmed):** essential consent is visibly locked; optional categories use native switches and localized explanations; a timestamp and localized save result exist; wider content is bounded to 500 dp.
- **Attention flag:** Watch.

#### A-9.1 Local draft can diverge from later service changes (verify) — UX · recommendation · Medium

1. **Problem.** `_analytics`/`_marketing` are copied once in `initState` (`consent_settings_screen.dart:21-27`), while the timestamp comes from a watched service (`:33, 50-71`) and switches continue using the local draft (`:96-111`). A later external service change can therefore update the timestamp without updating those switches.
2. **Why it matters.** Draft state is legitimate while editing; the first pass did not establish how often an external write actually occurs on this route.
3. **UX impact.** If another surface saves while this page stays alive, displayed draft and saved timestamp may describe different choices.
4. **A11y impact.** The same ambiguity affects spoken switch states.
5. **System impact.** The settings page and global preferences sheet are separate editors over `consentServiceProvider`.
6. **Proposed fix.** Define draft ownership: sync clean drafts on service changes, preserve dirty drafts with a clear conflict notice rather than overwriting edits.
7. **Reusable rule.** X-5: distinguish a draft from the currently persisted preference set.
8. **Implementation notes.** Add baseline/dirty tracking and a provider listener in `consent_settings_screen.dart`; reuse `consentServiceProvider`, native `SwitchListTile`s and `consentLastUpdated`; introduce EN/FR `consentPreferencesChangedElsewhere` only if a conflicting-write path is supported.
9. **Acceptance checklist.** A provider update refreshes a clean draft; a dirty draft is not silently overwritten; the saved timestamp never implies that unsaved choices were saved; exercise the real alternate-editor path before promotion in severity.

#### A-9.2 Consent Save lacks an in-flight guard — UX · recommendation · Low

1. **Problem.** The async Save callback remains enabled and switches remain editable while `savePreferences` runs (`consent_settings_screen.dart:96-111, 125-148`); results are snackbar-only. This is a confirmed busy-state omission, not proof that Flutter snackbars fail to announce.
2. **Why it matters.** Changes during an outstanding save can make it unclear which values were written.
3. **UX impact.** Repeated taps can overlap local writes or produce multiple result messages.
4. **A11y impact.** Verify result announcement; no categorical snackbar accessibility failure is asserted.
5. **System impact.** `ConsentPreferencesSheet` already has `_saving` and disables switches/Save (`consent_preferences_sheet.dart:32-42, 138-155, 170`).
6. **Proposed fix.** Bring settings to parity with the existing sheet's guarded save and expose a stable result status.
7. **Reusable rule.** X-5/X-7: one in-flight setting save, one reported outcome.
8. **Implementation notes.** Port `_saving` and a guarded handler from `consent_preferences_sheet.dart` into `consent_settings_screen.dart`; reuse `consentPreferencesSaved`, `consentPreferencesSaveFailed` and planned labelled progress/status wrappers.
9. **Acceptance checklist.** Slow save disables Save and both optional switches; repeated taps write once; success/failure is localized and announced in assistive-technology testing; failure preserves the draft.

#### A-9.3 Timestamp uses a fixed format and no local conversion — i18n · recommendation · Low

1. **Problem.** `_formatTimestamp` manually builds day/month/year and 24-hour time (`consent_settings_screen.dart:159-164`), whereas the sheet uses `DateFormat.yMd(locale).add_Hm()` after `.toLocal()` (`consent_preferences_sheet.dart:187-193`).
2. **Why it matters.** Date presentation should follow locale conventions and a deliberate timezone; the manual pattern is not itself hard-coded English.
3. **UX impact.** Settings and sheet may display inconsistent dates/times for the same saved consent.
4. **A11y impact.** Numeric dates can be harder to interpret without locale consistency.
5. **System impact.** Two formatters exist for one timestamp.
6. **Proposed fix.** Reuse a locale-aware formatter in both places, including an explicit local-time policy.
7. **Reusable rule.** X-6: dates are formatted as localized data, not concatenated strings.
8. **Implementation notes.** Extract the `intl` formatter already in `consent_preferences_sheet.dart` and use it in `consent_settings_screen.dart`; retain `consentLastUpdated`, with a localized unavailable value instead of raw malformed ISO if needed.
9. **Acceptance checklist.** EN/FR settings and sheet show the same instant consistently; UTC and offset input are tested; malformed values do not leak technical strings.

---

### A-10 First-use cookie/consent popup — `global overlay`

- **Source:** `main.dart`, `core/widgets/consent_banner.dart`, `core/widgets/consent/consent_banner_surface.dart`, `consent_preferences_sheet.dart`, `core/services/consent_service.dart`.
- **Purpose:** Request an initial choice about optional analytics/marketing while retaining essential services.
- **Strengths (confirmed):** hidden after a response; essential and optional categories are distinct; banner has a live region and heading; overlay already uses `SafeArea` with 16 dp minimum; preferences sheet supports individual choices and guards Save.
- **Attention flag:** FLAG.

#### A-10.1 Declining optional consent requires opening preferences — UX · recommendation · Medium

1. **Problem.** Banner exposes only Manage preferences and Accept all (`consent_banner_surface.dart:74-96`; `consent_banner.dart:29-34`). There is no one-tap reject-optional action.
2. **Why it matters.** Declining is less direct than acceptance; no jurisdiction-specific compliance violation is inferred without policy/legal review.
3. **UX impact.** Users must open and save a second surface to keep optional categories off.
4. **A11y impact.** Additional focus traversal and a modal transition are needed to decline.
5. **System impact.** `ConsentService.withdrawAll` already exists (`consent_service.dart:97-110`), but a first-response action needs checked persistence and result handling.
6. **Proposed fix.** Provide an equally discoverable Reject optional action alongside acceptance and granular management.
7. **Reusable rule.** Privacy decisions should offer comparably direct acceptance and refusal paths.
8. **Implementation notes.** Add an `onRejectOptional` callback to `ConsentBannerSurface` and EN/FR `consentRejectOptional`; call checked `savePreferences(analyticsConsent: false, marketingConsent: false)` from `consent_banner.dart` and display `consentPreferencesSaveFailed` on failure.
9. **Acceptance checklist.** One tap rejects optional categories and persists the response; failure leaves a retryable banner; all choices remain reachable at compact width and 200% text.

#### A-10.2 Overlay elevation is permitted; bespoke treatment needs review — Design · recommendation · Low (was requirement · Medium)

1. **Problem.** The banner has `elevation: 6`, a border and radius 20 (`consent_banner_surface.dart:25-34`). `system.md` § 5 explicitly allows stronger elevation for overlays above a task, so the first pass's blanket no-shadow requirement for this overlay was incorrect.
2. **Why it matters.** The useful question is whether its elevation matches an intentional overlay token, not whether any shadow is forbidden.
3. **UX impact.** Potentially excessive visual prominence, not a confirmed blocked task.
4. **A11y impact.** None established.
5. **System impact.** A documented overlay treatment would avoid arbitrary elevation values.
6. **Proposed fix.** Keep the existing border; select the least necessary approved overlay elevation, or document why this utility needs stronger separation.
7. **Reusable rule.** X-10: default cards are flat, while overlay elevation is a deliberate exception under `system.md` § 5.
8. **Implementation notes.** Adjust `ConsentBannerSurface`'s `Material` through shared theme/token treatment; 20 dp can remain if classified as an overlay/dialog family rather than a standard card; no ARB change is needed.
9. **Acceptance checklist.** Chosen radius/elevation is documented against the component family; border remains visible; no claim of a universal shadow ban remains in acceptance criteria.

#### A-10.3 Nonmodal banner may obscure underlying work (verify) — UX · recommendation · Medium

1. **Problem.** `main.dart:141-155` stacks an aligned banner above the page without a modal barrier or reserving page space. Contrary to the first pass's implication, `SafeArea(minimum: EdgeInsets.all(16))` is already present (`:146-147`).
2. **Why it matters.** A nonmodal notice is legitimate; obscured controls, focus conflicts or keyboard problems must be demonstrated at runtime before calling it a breach.
3. **UX impact.** On short screens the banner may cover page actions while other page regions remain interactive.
4. **A11y impact.** Focus may traverse underlying content out of visual context; no focus trap failure has been observed.
5. **System impact.** Global utility behaviour affects public entry and signed-in pages alike.
6. **Proposed fix.** Explicitly choose nonmodal, space-reserving notice behaviour or a proper modal decision surface; preserve safe areas either way.
7. **Reusable rule.** X-8/X-9: a global overlay has a defined interaction and focus model, not merely a visual position.
8. **Implementation notes.** Review `_ConsentOverlay` in `main.dart` with `ConsentBanner` and `ConsentPreferencesSheet`; reuse existing modal-sheet focus behaviour if choosing modality; no new localization is required unless explanatory copy changes.
9. **Acceptance checklist.** Phone/desktop, keyboard-open and 200% EN/FR tests show all decision actions reachable; underlying critical actions are not invisibly focusable/obscured; selected modal/nonmodal behaviour is documented.

#### A-10.4 Legacy olive/gold palette claim is false (withdrawn) — Design · recommendation · Low

1. **Problem.** Although `consent_banner_surface.dart:26-32, 79-92` uses Operations identifiers, `app_color_tokens.dart:75-83` aliases `operationsOlive` to current `landingTealDeep`, `operationsSurface` to `landingSurface` and `operationsGold` to `petCarePrimary`. The first-pass claim of a visibly obsolete olive/gold palette is not supported.
2. **Why it matters.** Legacy names should not be mistaken for legacy rendered colours; `tokens.md` expressly permits the current plum/teal landing family.
3. **UX impact.** None established from palette mismatch.
4. **A11y impact.** No contrast failure is asserted; actual contrast still requires a rendered check.
5. **System impact.** Transitional alias naming remains maintenance debt, not a demonstrated visual defect.
6. **Proposed fix.** No recolouring on this evidence; use semantic names when the consent files are next touched.
7. **Reusable rule.** X-10: inspect token values before judging colour use by identifier.
8. **Implementation notes.** Rename Operations references in `consent_banner_surface.dart`, `consent_settings_screen.dart` and `consent_preferences_sheet.dart` to equivalent landing/Pet Care roles without changing values; no ARB change applies.
9. **Acceptance checklist.** An alias cleanup does not change rendered colour values; any later contrast finding is separately measured, not inherited from this withdrawn claim.

#### A-10.5 Compact consent actions flex inside an unbounded column — UX · requirement · Medium

1. **Problem.** Actions are built as `Expanded` widgets (`consent_banner_surface.dart:74-96`) and reused directly in the `<400` width `Column` (`:99-107`). That column sits in the banner's outer `Column(mainAxisSize: MainAxisSize.min)` (`:38-40`), which gives a non-flex child unbounded vertical constraints; `Expanded` requires finite main-axis space.
2. **Why it matters.** This is a verified Flutter layout-constraint violation at the compact breakpoint, not just the first pass's speculative overlay crowding. It can prevent the privacy decision surface from laying out correctly.
3. **UX impact.** Compact first-use consent can fail to render usable actions.
4. **A11y impact.** If layout fails, neither visual nor assistive access to the decision controls is dependable.
5. **System impact.** One presentational widget affects every route when no response has been stored.
6. **Proposed fix.** Build plain buttons first; wrap them in `Expanded` only for the horizontal Row and use unconstrained-height, full-width buttons in the compact Column.
7. **Reusable rule.** X-8: responsive actions change flex strategy with axis; vertical content-sized stacks do not inherit horizontal `Expanded` wrappers.
8. **Implementation notes.** Refactor `ConsentBannerSurface`'s `LayoutBuilder`; preserve `consentManagePreferences`, `consentAcceptAll` and A-10.1's proposed reject key; keep 48 dp minimum targets and the existing live-region heading.
9. **Acceptance checklist.** Widget layout at 320, 360, 399, 400 and 480 dp reports no unbounded-flex exception; buttons render and invoke their callbacks; 200% French labels wrap without clipping.

---

**Patterns seen in this area** (feed Part 4):

- X-1/X-6: never render auth/service exception prose → typed auth failure mapping + localized form status; planned `AsyncErrorState` only for persistent load failure → Forgot password, onboarding save, Secure account, resolver.
- X-5/X-7: validate, guard submission and announce the actual persisted result → shared form-status pattern using `AppFormSection`, `AppFormLabeledField`, `AppFormActionsBar` → onboarding, My details preference/profile/delete flows, Secure account, consent settings.
- X-7: label progress in domain units without denying framework semantics → shared labelled progress (B-12.2) + step ARB message → resolver and onboarding.
- X-6: translate display labels, not stable values → shared species mapping + ARB helper/semantic strings and locale-aware formatter → onboarding, profile editor, timezone, reset confirmation, consent dates, dev preview.
- X-8: content-sized layouts at 200% and axis-appropriate action flex → shared responsive action composition and scale tests → landing story, onboarding welcome, consent banner.
- X-10: inspect actual tokens and component class before diagnosing style debt → semantic-token/theme pass → auth card and consent overlay; Operations aliases are not an obsolete palette.
- X-11: inspect auth state and direct-entry stack before defining completion → named post-action routing/result delivery → My details password change, Secure account.
- X-4: single-product entry needs no frozen-domain chooser → active Pet Care resolver + Part 5 cleanup → eligibility, chooser, My details organisation utility and preview foster fixture.
- X-12: credential fields have a tested manager strategy → existing native login bridge + shared Flutter credential fields, with detailed bridge scope in Part 5 → landing signup, Secure account and My details.

**Changes from the first pass (Area A).**

- **A-1.3:** recommendation Medium → recommendation Low; retained as **withdrawn** because names are optional in both client and server, not incomplete required identity.
- **A-2.2:** recommendation Low → requirement Medium, lens UX → i18n; traced reset success through the service to literal English server copy.
- **A-3.1:** recommendation Medium → recommendation Low; multi-domain eligibility is intentionally frozen, not a missing supported journey.
- **A-4.1:** requirement Medium → recommendation Low; `/app/choose` is absent from login by design and can be retired, not inserted.
- **A-5.2:** requirement Medium → recommendation Low; determinate Flutter progress already exposes numeric value/range; the remaining improvement is step/purpose wording, not fixing colour-only progress.
- **A-5.5:** recommendation Low → requirement Medium; English species labels are confirmed, and existing French ARB keys are unused here.
- **A-7.2:** recommendation Medium → requirement Medium; notifier failure is swallowed into an undisplayed auth error and local language can diverge from persistence.
- **A-7.3:** requirement High → recommendation Low; retained as **withdrawn** for the claimed inevitable not-found result, because successful change clears auth and the top-level guard handles even an unmatched `/login`; stale route cleanup remains sensible.
- **A-7.4:** recommendation Medium → recommendation Low; password already has an `AppFormSection` heading, leaving only a modest broader grouping suggestion.
- **A-7.5:** recommendation Low → requirement Medium, lens A11y → UX; enabled Delete silently rejects missing input and violates the X-5 validation rule; coordinate implementation with D-12.
- **A-8.1:** requirement High → requirement Medium; empty/weak credentials are submitted but rejected by server validation, so no accepted-empty-password or account-compromise claim is established.
- **A-8.3:** recommendation Low → requirement Medium, lens A11y → UX; raw service errors are confirmed under § 6.10, while “colour-only failure” was inaccurate because text is present.
- **A-10.2:** requirement Medium → recommendation Low; `system.md` § 5 permits overlay elevation and this surface already has a border.
- **A-10.4:** retained as **withdrawn**, recommendation Low unchanged; Operations aliases resolve to current plum/teal/surface tokens, not retired olive/gold colours.
- **Other lens corrections, unchanged grades:** A-1.4 A11y → Design (token drift, no proven A11y failure); A-2.3 A11y → UX (code-format validation); A-9.2 A11y → UX (busy guard is confirmed, snackbar announcement failure is not).
- **Marked verify:** A-1.1 (manager-specific signup autofill impact), A-1.5 (compact story length), A-2.1 (status announcement), A-5.3 (200% welcome overflow), A-8.4 (direct-entry success stack/context), A-9.1 (real external-save path), A-10.3 (occlusion/focus behaviour). No rendered contrast, focus order, actual screen-reader output or browser-manager behaviour is claimed as observed.
- **New findings, fully traced in source:** A-2.4 recovery raw errors; A-5.6 onboarding raw save errors/partial-result recovery; A-7.6 false profile-save success; A-10.5 compact consent flex constraint. Each is requirement Medium.
- No IDs were removed; all 36 original findings remain, with 4 additions (40 total). Standalone unrouted `LoginScreen`/`SignupScreen`, native HTML bridge internals and frozen-domain deletion are delegated to Part 5 rather than expanded here. Summary/attention flags change accordingly: Forgot password is Watch; My details remains FLAG for verified persistence/validation feedback, not the withdrawn routing claim; the consent overlay is FLAG for A-10.5.

---

## Area B — Home, pets and care (detailed)

This area was re-reviewed screen by screen against the source after the first pass. Every finding below was re-read in code; levels and severities were adjusted where the repository's own rules decide the matter (mainly [`system.md` § 6.10](../system.md), which requires that an error state use plain language with a retry where meaningful and no raw backend message, and that no empty or status copy is shown while data is unresolved). Each finding is written in the nine-part structure from [`principles.md`](../principles.md#review-output-deep-tasks). Changes from the first pass are listed at the end of the area.

**Area summary.** The central Pet Care routes are connected to live screens, share one shell, use localized labels and responsive layouts, and build the care agenda from server schedule values. The strongest screens are the occurrence (care date) screen, the pet timeline, the all-actions queue and the two main forms: they handle discard, validation, gone-state and retry deliberately. The repeating weakness is the failure path of primary loads: six screens print the raw exception or a localized wrapper around it, and eight have no retry. A second repeating weakness is supplemental data that fails quietly and leaves a confident-looking result (tag filter, bulk-share care status, weight overview). Visible care vocabulary follows [`terminology.md`](../terminology.md); the retired words survive only in identifiers and ARB key names. No public screen exists in this area; all findings are from code.

**Shared fix that covers most of Area B.** Fourteen of the thirty-two findings are instances of three rules (X-1 error-with-retry, X-2 supplemental-state, X-7 labelled progress). Building the shared async-state widget first (see B-2.1 "Implementation notes") and then applying it screen by screen is the cheapest path; the per-screen specs below say what each call site needs in addition.

---

### B-1 Shell and navigation — `/pc/*`

- **Source:** `features/experience/presentation/widgets/experience_shell_scaffold.dart`, `pet_care_bottom_navigation.dart`, `pet_care_navigation_rail.dart`, `pet_care_navigation_sidebar.dart`, `pet_care_primary_destinations.dart`, `experience_workspace_toggle.dart`
- **Purpose:** Pet Care chrome: compact bottom navigation (five destinations: Home, Pets, All actions, People, Account), medium rail, wide sidebar, notification bell, back handling.
- **Strengths (confirmed):** one destination list drives all three layouts; every destination has a localized semantic label, `button: true`, and a 48 × 48 target; the All actions destination carries an attention badge; back handling returns to the section root when no return path is known.
- **Attention flag:** Watch.

#### B-1.1 Compact navigation shows no visible labels — Design/UX · recommendation · Medium (was requirement)

1. **Problem.** `BottomNavigationBar` is built with `showSelectedLabels: false` and `showUnselectedLabels: false` (`pet_care_bottom_navigation.dart:47-48`). Five destinations are identified by icon alone on phones; the label exists only for assistive technology.
2. **Why it matters.** Five icons (house, paw, checklist, people, person) without text require the user to learn the mapping. "All actions" and "People" in particular have no universally understood glyph. Material guidance for three to five destinations is to show labels, at least for the active item.
3. **UX impact.** Slower first-week orientation; mis-taps between People and Account (both person-shaped icons) are likely. The attention badge on All actions loses meaning if the user does not know what that tab is.
4. **A11y impact.** Screen-reader users are served (labels present). Sighted users with cognitive or memory impairments, and anyone with low vision who relies on text rather than icon shape, are not. Not a WCAG failure, which is why this is downgraded from requirement.
5. **System impact.** The rail and sidebar already show labels, so the compact layout is the odd one out; adding labels aligns the three layouts.
6. **Proposed fix.** Show labels for all five destinations in compact layout (`showSelectedLabels: true`, `showUnselectedLabels: true`) using `labelMedium` from the theme; keep the 48 dp targets and the existing semantics. If space is the concern, show the selected label only, as a first step.
7. **Reusable rule.** Icon-only navigation is allowed only when the icon set is conventional and there are three or fewer destinations; otherwise a visible label accompanies the icon.
8. **Implementation notes.** Keep `type: fixed`. Check French labels ("Toutes les actions", "Personnes") at 200% text scale in the 360 dp width; `BottomNavigationBar` truncates rather than wraps, so set `maxLines: 1` with ellipsis as the fallback and shorten the French label in ARB if needed. The existing `_BottomNavDestinationIcon` semantics should stay to keep E2E identifiers intact.
9. **Acceptance checklist.** Labels visible for all destinations at default and 200% scale on a 360 dp wide phone; no label clipped; semantics labels unchanged; E2E navigation tests still find the destinations by identifier.

#### B-1.2 The workspace toggle slot renders nothing — Design · recommendation · Low

1. **Problem.** `_buildCompactShellLeading` always instantiates `ExperienceWorkspaceToggle`, which returns `SizedBox.shrink()` by design (`experience_workspace_toggle.dart:17-20`, `experience_shell_scaffold.dart:330-350`). On root screens the leading slot is therefore an 8 dp padding around nothing.
2. **Why it matters.** The toggle is a frozen-domain concept (Pet Care ↔ Shelter). Keeping the slot keeps the concept in the active shell's structure and in every reader's head.
3. **UX impact.** None visible today; the app bar leading area is simply empty on root screens.
4. **A11y impact.** None; the shrunk box has no semantics.
5. **System impact.** Dead abstraction in the most-used widget; it also forces the shell to carry `showShelterWorkspace` plumbing that has no effect.
6. **Proposed fix.** Remove the toggle widget, the `showShelterWorkspace` parameter and the leading padding; let `isRoot` return `null` leading so the title aligns to the standard inset.
7. **Reusable rule.** When a domain is frozen, its UI entry points are removed from the active shell, not blanked.
8. **Implementation notes.** Check `experience_shell_scaffold` golden or widget tests that may assert the leading widget's presence; the drawer and back behaviour are independent of the toggle.
9. **Acceptance checklist.** Shell has no reference to `ExperienceWorkspaceToggle`; root screens' title inset matches Material default; shell tests pass.

#### B-1.3 Rail and sidebar labels use bespoke 11 px / 14 px styles — Design · recommendation · Low

1. **Problem.** `NavigationRail` label styles set `fontSize: 11` (`pet_care_navigation_rail.dart:48-55`) and the sidebar sets `fontSize: 14` with `maxLines: 1`, ellipsis (`pet_care_navigation_sidebar.dart:157-168`). Neither uses `textTheme`.
2. **Why it matters.** `tokens.md` defines the type scale; 11 px is below the smallest token and is hard to read on medium screens. Hard-coded sizes also escape any future theme change.
3. **UX impact.** Rail labels are small for a primary navigation surface at 600–839 px.
4. **A11y impact.** Sizes still scale with the system text scaler, so this is not a hard failure; but the sidebar's `maxLines: 1` will ellipsise French labels at large scale.
5. **System impact.** Two more places where typography is set outside the theme.
6. **Proposed fix.** Rail: `labelSmall` (12 px) or `labelMedium`; sidebar: `labelLarge`, `maxLines: 2`, no ellipsis until two lines. Colour and weight can stay as they are.
7. **Reusable rule.** Navigation text uses theme label styles; no literal font sizes in widgets.
8. **Implementation notes.** `NavigationRailThemeData` can carry these styles once in `app_theme.dart` so the widget does not need them.
9. **Acceptance checklist.** No `fontSize:` literals in the three navigation widgets; French labels readable at 200% on an 800 px wide window without ellipsis.

---

### B-2 Pet Care home (Today) — `/pc/home`

- **Source:** `features/experience/presentation/screens/experience_home_screens.dart`, `widgets/pet_care_shell_home_content.dart`, `pet_care_operations_desk_layout.dart`, `screens/pet_care/pet_care_my_pets_section.dart`, `pet_care_upcoming_events_section.dart`, `pet_care_planned_absence_section.dart`, `pet_care_dashboard_contextual_slot_section.dart`
- **Purpose:** Orient the user to today; surface pets, due care, away plans and people.
- **Strengths (confirmed):** the per-pet care section has a localized error and a retry; the onboarding redirect is driven by data, not by a flag alone. (The first pass credited a "Today orientation" card with distinct loading, error, attention and all-clear states; that widget, `pet_care_today_orientation.dart`, is not imported by any live file and the home test asserts its key is absent. See Part 5 § 5.6.)
- **Attention flag:** Watch.

#### B-2.1 Pet-list failure on Home prints the raw exception with no retry — UX · requirement · Medium

1. **Problem.** `petListAsync.when(error: (e, _) => Center(child: Text('$e')))` (`experience_home_screens.dart:61-64`). The whole home body is replaced by the exception string.
2. **Why it matters.** This is the first screen after sign-in and the one that opens on every launch. `system.md` § 6.10 forbids raw backend messages and asks for a retry where meaningful; here it is the only way back short of a restart.
3. **UX impact.** On a flaky network the app appears broken at launch. Pull-to-refresh is not available in this branch, and the stale-data banner is only shown in the `data` branch.
4. **A11y impact.** A `DioException` string is read aloud verbatim; no heading, no action to focus.
5. **System impact.** The same `petListProvider` is consumed by All pets, Bulk share and Pet detail with different error treatments, so the user sees four different failure styles for one data source.
6. **Proposed fix.** Replace the branch with the shared async error state (below): title "We couldn't load your pets", one line "Check your connection and try again", a Retry button that calls `ref.invalidate(petListProvider)` (or the notifier's refresh), and, when a cached list exists, keep showing it with the stale banner instead of the error.
7. **Reusable rule.** X-1: a failed primary load shows localized plain-language copy and a retry, keeps shell chrome, and never shows exception text.
8. **Implementation notes.** Build one widget, for example `AsyncErrorState({required String title, String? detail, required VoidCallback onRetry, Key? key})`, in `core/widgets/`, using `Semantics(liveRegion: true)` on the title, an outlined Retry button of 48 dp height, and `textTheme.titleMedium` / `bodyMedium`. Add two ARB strings (`loadErrorGeneric`, `loadErrorRetryHint`) plus per-screen titles where the subject matters ("your pets", "care", "history"). Log the exception with the existing logger; do not pass it to the widget. This widget is the dependency for B-6.1, B-7.1, B-8.1, B-11.1, B-13.1, B-14.2 and most of Area C and D's error findings.
9. **Acceptance checklist.** With the API returning 500 for `/pets`, Home shows the localized error and Retry; tapping Retry re-requests and renders pets when the API recovers; no exception text anywhere in the widget tree; screen reader announces the title on arrival; widget test covers error → retry → data.

#### B-2.2 Today orientation uses a 20 dp radius (withdrawn) — Design · recommendation · Low

1. **Problem.** *Withdrawn on the second pass: `pet_care_today_orientation.dart` is unreachable from `main.dart` and is listed for deletion in Part 5 § 5.6; the text below is kept as the audit record.* `BorderRadius.circular(20)` on the Today card (`pet_care_today_orientation.dart:38-44`). `system.md` § 4 assigns 16 px to cards and featured sections and 20 px to dialogs and bottom sheets.
2. **Why it matters.** The card sits above a grid of 16 px cards; the difference is visible and unexplained.
3. **UX impact.** Minor; reads as a slightly different component family.
4. **A11y impact.** None.
5. **System impact.** One more literal radius outside the token set.
6. **Proposed fix.** Use the card radius token (16). If the design intent is to make Today a "featured" surface, that is still 16 per the table.
7. **Reusable rule.** Radii come from the token table; 20 is reserved for sheets and dialogs.
8. **Implementation notes.** The border colour also uses `operationsOlive` at 20% alpha; check it against `tokens.md` while there.
9. **Acceptance checklist.** Radius token used; golden updated.

#### B-2.3 Count pills are hidden from semantics in favour of one summary (withdrawn) — A11y · recommendation · Low

1. **Problem.** *Withdrawn on the second pass for the same reason as B-2.2: the widget is dead code.* `_attentionBody` wraps the three pills in `ExcludeSemantics` and the container exposes a single label built by `_attentionLabel` (`pet_care_today_orientation.dart:32-36, 169-207`).
2. **Why it matters.** A single sentence ("Today: 2 overdue. 3 due today. 5 upcoming.") is a good summary. The cost is that a screen-reader user cannot move between the three counts or act on one.
3. **UX impact.** None for sighted users.
4. **A11y impact.** Acceptable for a status card; would become a problem if the pills gain tap actions (filtering All actions by zone), because the actions would be unreachable.
5. **System impact.** None today.
6. **Proposed fix.** Keep the summary. If pills become interactive, drop `ExcludeSemantics` and give each pill its own button semantics with the same text.
7. **Reusable rule.** A merged semantic summary is fine for read-only groups; interactive children must stay individually reachable.
8. **Implementation notes.** The upcoming pill concatenates a number and `careStatusUpcoming` by string interpolation; move it to a plural ARB message like the other two so French word order is right.
9. **Acceptance checklist.** TalkBack/VoiceOver reads one summary; if pills are made tappable, each is focusable and announces its count.

---

### B-3 All pets — `/pc/pets`

- **Source:** `features/experience/presentation/screens/pet_care/pet_care_all_pets_screen.dart`, `pet_tag_filter_bar.dart`, `pet_list_screen.dart`, `pet_care_pets_tile_grid.dart`, `pet_profile/presentation/utils/pet_tile_dimensions.dart`
- **Purpose:** Browse and filter pets; add or share.
- **Strengths (confirmed):** list body handles loading, error with retry, empty and filtered-empty; add and share live in a fixed bottom bar; tile height already grows with the text scaler.
- **Attention flag:** Watch.

#### B-3.1 A failed or loading tag fetch silently shows every pet — UX · requirement · Medium

1. **Problem.** `visiblePetIds` is computed with `tagsAsync.maybeWhen(data: ..., orElse: () => null)` and `null` means "no filter" (`pet_care_all_pets_screen.dart:19-28`). `PetTagFilterBar` renders `SizedBox.shrink()` on both loading and error (`pet_tag_filter_bar.dart:21-23`). If the tag request fails, the filter bar disappears and the list shows all pets as if nothing were wrong; if the user had a filter selected, it is silently dropped.
2. **Why it matters.** This is the "silent fallback" anti-pattern named in the project's own principles. The user cannot tell "no tags defined" from "tags unavailable".
3. **UX impact.** Someone who filtered to "Cats" and then loses connectivity sees dogs reappear without explanation. Someone who created tags sees the filter bar vanish and may recreate tags.
4. **A11y impact.** Nothing is announced when the bar disappears.
5. **System impact.** Same pattern reappears in B-4.1 and B-14.1; fixing the rule once (X-2) resolves all three.
6. **Proposed fix.** Make the filter state three-valued: *loading* (bar shows a disabled skeleton, list waits or shows unfiltered with a "Filters loading" caption), *unavailable* (bar shows "Tag filters unavailable · Retry" and the list shows all pets with that caption), *ready* (current behaviour). When a filter is selected and tags later fail, keep the selection and show the unavailable caption rather than dropping it.
7. **Reusable rule.** X-2: supplemental data that fails must render a visible "unavailable" state next to the content it would have changed; it never degrades silently to the default.
8. **Implementation notes.** Expose `tagsAsync` state to `PetTagFilterBar` instead of collapsing it; add a small `SupplementalStateCaption(state, onRetry)` widget reused by B-4.1/B-14.1; strings: `tagFiltersLoading`, `tagFiltersUnavailable`, reuse `retry`. Retry calls `ref.invalidate(petTagListProvider)`.
9. **Acceptance checklist.** With `/pet-tags` failing: bar shows the unavailable caption with Retry, list shows all pets, selected filter is preserved after recovery; with no tags defined: bar hidden as today; widget test for each of the three states.

#### B-3.2 Tile size at large text — A11y · recommendation · Low (verify)

1. **Problem.** Tiles have fixed width (128–172) and a height computed from text scale (`pet_tile_dimensions.dart:15-29`). Height growth is capped (+70 dp plus a 16 dp bump above 1.75×). Width does not grow.
2. **Why it matters.** At 200% a two-word pet name and a two-line status may exceed the capped height or wrap awkwardly in 128 dp.
3. **UX impact.** Possible clipping or ellipsis of the status line at 200%.
4. **A11y impact.** `system.md` § 2.3 requires no clipped labels at 200%.
5. **System impact.** The same tile is used in Home, All pets and Bulk share.
6. **Proposed fix.** Verify at 200% with a long French status ("À faire aujourd'hui") and a 14-character name. If clipped, let `UnifiedPetTile` size itself from its content (intrinsic height within the `Wrap`) and reduce columns at large scale (two per row under 600 dp).
7. **Reusable rule.** X-8: fixed-height tiles are a last resort; prefer content-sized tiles in a `Wrap`.
8. **Implementation notes.** A golden at `textScaleFactor: 2.0` for the tile grid would catch regressions.
9. **Acceptance checklist.** No clipped or ellipsised name/status at 200% in EN and FR; tiles still align in rows.

---

### B-4 Bulk share select — `/pc/pets/bulk-share`

- **Source:** `features/experience/presentation/screens/pet_care/pet_care_bulk_share_select_screen.dart`, `pet_care_pets_tile_grid.dart`
- **Purpose:** Choose eligible pets, continue to sharing.
- **Strengths (confirmed):** continue button disabled until a selection exists and shows the count; select-all state derived from eligible pets; explicit back to `/pc/pets`.
- **Attention flag:** Watch.

#### B-4.1 Tiles say "All set" while care data is loading or failed — UX · requirement · Medium (was recommendation)

1. **Problem.** `careSummary` is `null` until `healthEntriesNotifierProvider` has a value, and `_tileFor` maps `careSummary == null` to `CareStatus.allSet` (`pet_care_bulk_share_select_screen.dart:80-86`, `pet_care_pets_tile_grid.dart:81-88`). A failed entries load leaves every tile reading "All set" indefinitely.
2. **Why it matters.** `system.md` § 6.10: do not show status copy while data is unresolved. "All set" is a claim about care that the app has not verified; the owner is about to share pets on that basis.
3. **UX impact.** Misleading reassurance at the moment of sharing; the sitter may receive a pet with overdue care that the owner thought was fine.
4. **A11y impact.** The false status is also in the tile's semantic label.
5. **System impact.** `PetCarePetsTileGrid` is shared with Home; the same default applies wherever the caller passes `null`.
6. **Proposed fix.** Give the grid an explicit `careSummaryState` (loading / unavailable / ready). While loading, omit the status line (or show a short skeleton); when unavailable, show "Care status unavailable" muted text and a screen-level caption with Retry (X-2). Never default to `allSet`.
7. **Reusable rule.** X-2, plus: a status enum must not have a value that doubles as "unknown".
8. **Implementation notes.** Change the `careSummary == null ? CareStatus.allSet` branch to return `null` status and let `resolvePetTileStatusLine` accept null; watch `healthEntriesNotifierProvider` with `.when` in the screen to drive the caption. Same `SupplementalStateCaption` as B-3.1.
9. **Acceptance checklist.** With entries failing: tiles show no care claim and the caption offers Retry; with entries loading: no "All set"; with entries loaded: unchanged; Home's grid behaves the same.

#### B-4.2 "No pets yet" shown when pets exist but none is shareable — Copy · recommendation · Low

1. **Problem.** `eligible.isEmpty` renders `l.noPetsYet` (`pet_care_bulk_share_select_screen.dart:117-123`) even when `allPets` is non-empty.
2. **Why it matters.** The sentence is false in that case and suggests data loss.
3. **UX impact.** Confusion; the user may go back to check whether their pets are gone.
4. **A11y impact.** None beyond the copy.
5. **System impact.** None.
6. **Proposed fix.** Branch: `allPets.isEmpty` → "No pets yet" with an Add pet action; `allPets.isNotEmpty && eligible.isEmpty` → "None of your pets can be shared from here" with one line explaining why (for example, shared-with-you pets are managed by their owner) and a link back.
7. **Reusable rule.** Empty states name the real reason; a filtered-empty state is never worded as a true empty.
8. **Implementation notes.** New ARB string `bulkShareNoEligiblePets`; `_eligiblePets` already encodes the rule, so the explanation can be derived from it.
9. **Acceptance checklist.** Both branches covered by a widget test; copy reviewed against `copy-tone.md`.

---

### B-5 Add pet, edit pet — `/add`, `/edit/:id`

- **Source:** `features/experience/presentation/pet_profile/screens/pet_form_screen.dart` and parts, `widgets/pet_edit_permission_guard.dart`
- **Purpose:** Create or update a pet profile.
- **Strengths (confirmed):** edit permission checked before the form renders; dirty-state guard on system back and explicit back; sticky actions on phone; delete and passed-away are separate confirmations.
- **Attention flag:** Watch.

#### B-5.1 Edit guard shows hard-coded "Pet not found" — i18n · requirement · Medium

1. **Problem.** `const Scaffold(body: Center(child: Text('Pet not found')))` (`pet_edit_permission_guard.dart:25-27`). The ARB has `petNotFound` already (`app_en.arb:201`).
2. **Why it matters.** Any stale `/edit/:id` link in French shows English, outside the shell, with no back control.
3. **UX impact.** A bare page with one English sentence and no way out other than system back.
4. **A11y impact.** No heading, no action.
5. **System impact.** Also returns a bare `Scaffold` while loading, so the title and bell disappear during the check.
6. **Proposed fix.** Use `l.petNotFound`, render inside `ExperienceShellScaffold` with a back path to `/pc/pets`, and add a "Back to pets" button. Keep the loading branch inside the shell as well.
7. **Reusable rule.** X-6 (all strings from ARB) and X-1 (states keep shell chrome).
8. **Implementation notes.** The guard is `ConsumerWidget`; it can read `AppLocalizations.of(context)!` directly. Note that `petsAsync.value` is used without checking `hasError`; an error is currently indistinguishable from "not found". Add the error branch with the shared error state.
9. **Acceptance checklist.** French locale shows the French string; the page has a back control and the shell title; a provider error shows the error state rather than "Pet not found".

#### B-5.2 After adding a pet the form navigates to `/` (and to frozen org routes) — UX · recommendation · Medium (was requirement)

1. **Problem.** `_navigateAfterForm` goes to `/` for a new personal pet, and to `/organizations/<id>` when an org id is present (`pet_form_screen_actions.part.dart:4-18`). `/` resolves through `/app/resolve` to `/pc/home`; `/organizations/*` is a frozen route that redirects to `/pc/home`.
2. **Why it matters.** The user came from All pets, Home or onboarding, and lands on Home via two redirects. The org branches are dead code that still compiles into the active product.
3. **UX impact.** Loss of place after the most common creation flow; a visible flash through the resolve screen on slow devices.
4. **A11y impact.** Focus lands on a screen the user did not choose.
5. **System impact.** Frozen-domain branches in an active file, contrary to the frozen-domain boundary rules.
6. **Proposed fix.** On create, go to the new pet's detail (`goToPetDetail`) so the user sees the result and can add care; or pop to the originating route when one is known. Remove the two `/organizations` branches.
7. **Reusable rule.** X-11: after a flow ends, go to a registered, sensible destination; creation flows land on the created object.
8. **Implementation notes.** `PetFormScreen` already receives a `petId` after save in the edit path; the create path needs the returned id from the controller's outcome. The dirty-guard must be cleared before navigation to avoid a discard prompt.
9. **Acceptance checklist.** After Add pet, the new pet's detail is shown without passing through `/app/resolve`; no `/organizations` string remains in the file; frozen-domain boundary check passes.

#### B-5.3 Preview weight hard-codes "kg" — i18n · recommendation · Medium

1. **Problem.** `_previewWeightLabel` returns `'${parsed.toStringAsFixed(1)} kg'` (`pet_form_screen_actions.part.dart:71-79`). A unit preference provider exists (`core/weight/weight_unit_preference.dart`) and is used by the weight hub.
2. **Why it matters.** A user whose preference is lb types "12" and the preview shows "12.0 kg".
3. **UX impact.** Wrong unit in the live preview; possible wrong data entry if the user "corrects" the number.
4. **A11y impact.** None beyond the copy.
5. **System impact.** Two formatting paths for the same value.
6. **Proposed fix.** Use the same unit preference and formatter as `weight_hub_labels.dart`; the input field's suffix should show the same unit.
7. **Reusable rule.** One formatter per physical quantity; widgets never append unit strings.
8. **Implementation notes.** Check whether the input itself is interpreted as kg on save; if so the whole field needs the unit conversion, not only the preview.
9. **Acceptance checklist.** With lb preference, preview and suffix show lb and the saved value is correct in kg on the server.

---

### B-6 Pet detail — `/pet/:petId`

- **Source:** `features/experience/presentation/pet_profile/screens/pet_detail_screen.dart`, `widgets/pet_detail_scroll_body.dart`
- **Purpose:** Profile, current care, suggestions, people, history links.
- **Strengths (confirmed):** loading, error and missing-pet branches are explicit and localized; desktop uses two columns with care first; share/export permission-filtered in an overflow menu with tooltip.
- **Attention flag:** Watch.

#### B-6.1 Load error has no retry and drops the shell — UX · requirement · Medium (was recommendation)

1. **Problem.** `error: (error, _) => Scaffold(body: Center(child: Text(l.errorWithMessage(error.toString()))))` (`pet_detail_screen.dart:41-46`). Loading and missing-pet branches also return bare `Scaffold`s.
2. **Why it matters.** `system.md` § 6.10 (retry, no raw message: `errorWithMessage` interpolates the exception). This screen is a deep-link target from notifications and share flows.
3. **UX impact.** From a notification tap on a weak connection, the user gets "Error: DioException …" with no app bar.
4. **A11y impact.** No heading, no action, no back control.
5. **System impact.** Same provider as Home; same fix.
6. **Proposed fix.** Wrap all three non-data branches in `ExperienceShellScaffold` with the pet-neutral title; use the shared error state with Retry on `petListProvider`; missing pet gets "This pet isn't available" and a Back to pets button.
7. **Reusable rule.** X-1.
8. **Implementation notes.** `routeShell` helper as used in `care_item_detail_screen.dart:38-71` is the pattern to copy.
9. **Acceptance checklist.** Error, loading and missing branches keep title, back and bell; Retry recovers; no exception text.

#### B-6.2 Section order on mobile — UX · recommendation · Low (verify with content)

1. **Problem.** Primary column: profile, safeguards, care, suggestions, completeness, people, tags; then weight and history (`pet_detail_scroll_body.dart:35-51`). On a phone, history and weight are below seven sections.
2. **Why it matters.** History and weight are the two destinations people revisit; completeness and suggestions are prompts.
3. **UX impact.** Long scroll to reach history for a pet with several people and tags.
4. **A11y impact.** Longer swipe path for screen-reader users.
5. **System impact.** None.
6. **Proposed fix.** Verify with realistic data (three people, four tags). If history is below the fold on a 740 dp tall phone, move "History" and "Weight" entry rows directly after Care as compact link rows, keeping their full cards lower, or collapse Suggestions and Completeness by default once the profile is mostly complete.
7. **Reusable rule.** Prompts (suggestions, completeness) never sit between a pet's care and its history.
8. **Implementation notes.** `PetProfileHealthHistorySection` already acts as a link row on desktop; reuse it as the compact row.
9. **Acceptance checklist.** History reachable within one screen height on a 360 × 740 phone with a populated pet.

---

### B-7 Pet health issues — `/pet/:petId/health-issues`

- **Source:** `features/experience/presentation/pet_profile/screens/pet_health_issues_screen.dart`
- **Purpose:** List and manage a pet's health issues.
- **Strengths (confirmed):** title, add action (with tooltip) and empty copy localized; states not conflated; shared card.
- **Attention flag:** None.

#### B-7.1 Error has no retry and shows the exception — UX · requirement · Medium (was recommendation)

1. **Problem.** `Text(l.errorWithMessage(e.toString()))` in error colour, nothing else (`pet_health_issues_screen.dart:40-50`).
2. **Why it matters.** § 6.10. The screen is reached from a care item's "Relates to health issue" link, so a failure interrupts a care task.
3. **UX impact.** Dead end; the user must leave and return.
4. **A11y impact.** No action to focus.
5. **System impact.** Shared fix.
6. **Proposed fix.** Shared error state, Retry invalidates the pet's issues provider.
7. **Reusable rule.** X-1.
8. **Implementation notes.** Keep the app-bar add action enabled only in the `data` branch (§ 6.10: loading controls are disabled, not repurposed).
9. **Acceptance checklist.** Error shows Retry; Retry recovers; add action disabled while loading.

#### B-7.2 Empty state says "No entries yet" — Copy · recommendation · Low

1. **Problem.** Generic `noEntriesYet` (`pet_health_issues_screen.dart:52-64`).
2. **Why it matters.** "Entries" is the word for care items elsewhere; here it should reassure: no health issues recorded.
3. **UX impact.** Slight ambiguity about what the page tracks.
4. **A11y impact.** None.
5. **System impact.** `noEntriesYet` is reused in seven widgets (B-9.1 among them); each should get a precise string.
6. **Proposed fix.** "No health issues recorded for {name}" plus an inline "Add a health issue" button (the app-bar icon alone is easy to miss).
7. **Reusable rule.** Empty states name the object and offer one action (§ 6.10).
8. **Implementation notes.** New ARB string with `{name}` placeholder; reuse the app-bar handler.
9. **Acceptance checklist.** Copy approved against `copy-tone.md`; FR string present; button 48 dp.

---

### B-8 All care for a pet — `/pet/:petId/events`

- **Source:** `features/experience/presentation/pet_profile/screens/pet_manage_events_screen.dart`, `widgets/all_care_list.dart`
- **Purpose:** Planned care agenda and inactive care for one pet.
- **Strengths (confirmed):** pet-scoped title per terminology; shared server-backed agenda; empty state with add action.
- **Attention flag:** Watch.

#### B-8.1 Raw `$error`, no retry, at two levels — UX · requirement · Medium

1. **Problem.** Pet lookup error prints `'$error'` (`pet_manage_events_screen.dart:27`); entries error prints `errorWithMessage('$error')` with no retry (`all_care_list.dart:33-36`).
2. **Why it matters.** § 6.10; the per-pet section on Home already does this correctly with a Retry on `healthEntriesNotifierProvider` (`pet_care_section.dart:44-60`), so the product has two behaviours for the same data.
3. **UX impact.** Dead end on a screen linked from Pet detail and from the care item screen's back path.
4. **A11y impact.** No action.
5. **System impact.** Shared fix.
6. **Proposed fix.** Shared error state at both levels; Retry invalidates `allPetsIncludingOrgProvider` or refreshes the entries notifier respectively.
7. **Reusable rule.** X-1.
8. **Implementation notes.** Copy the retry wiring from `pet_care_section.dart`.
9. **Acceptance checklist.** Both failure levels show Retry; no `$error` text.

#### B-8.2 Loading, error and missing-pet lose the shell — UX · recommendation · Low

1. **Problem.** The three non-data branches return bare `Scaffold`s (`pet_manage_events_screen.dart:25-33`); only the `data` branch builds `ExperienceShellScaffold`.
2. **Why it matters.** Title, back path and bell disappear during loading, which is the common case on entry.
3. **UX impact.** A flash of blank app-bar-less page on each entry; no back during a slow load.
4. **A11y impact.** Focus has nothing to land on.
5. **System impact.** Same shape as B-6.1; `routeShell` helper pattern.
6. **Proposed fix.** Build the shell first with a pet-neutral title ("All care"), put the `when` inside, and update the title once the pet is known.
7. **Reusable rule.** X-1 (states keep chrome).
8. **Implementation notes.** `ExperienceShellScaffold` accepts a `screenTitle`; use `l.allCareTitle('')`-safe fallback or a dedicated neutral string.
9. **Acceptance checklist.** App bar present in all four states.

---

### B-9 All actions queue — `/pc/events`

- **Source:** `core/router/experience_routes.dart` (builder), `features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart`, `global_events_list.dart`
- **Purpose:** Act on care across all pets.
- **Strengths (confirmed):** shell title, back path, accessible add; agenda from server schedule; error view with retry already exists here (`_ErrorRetryView`); pull-to-refresh.
- **Attention flag:** Watch.

#### B-9.1 Filtered-empty uses the generic "No entries yet" — UX · recommendation · Medium

1. **Problem.** `if (visible.isEmpty) return _EmptyState(label: l.noEntriesYet)` regardless of whether `_petCareFilters` (cohorts, pets, event filters) excluded everything (`global_events_list.dart:152-161, 241-256`).
2. **Why it matters.** A user who filtered to one pet and "Overdue" sees "No entries yet", which reads as "you have no care at all". There is no clear-filters action in the empty state.
3. **UX impact.** Misreads the state of their care; may add duplicate items.
4. **A11y impact.** Empty text is plain, not a live region, so the change after filtering is not announced.
5. **System impact.** `PetCareGlobalEventsFilters` already knows whether it is active (`cohorts.isEmpty`, `petIds.isEmpty`), so the branch is cheap.
6. **Proposed fix.** Three empties: no care at all → "Nothing planned yet" with Add care; filters active → "Nothing matches these filters" with a Clear filters button; all done → the existing all-clear tone ("Nothing due. Silence is fine."). Announce the empty text as a live region after a filter change.
7. **Reusable rule.** Filtered-empty and true-empty are different states with different copy and actions.
8. **Implementation notes.** Add `isDefault` to the filters class; `_EmptyState` gains an optional action; strings `allActionsEmptyFiltered`, `allActionsClearFilters`.
9. **Acceptance checklist.** Widget tests for the three empties; Clear filters resets `_petCareFilters` to default; VoiceOver announces the change.

#### B-9.2 First paint waits for every entry's history — UX · recommendation · Medium

1. **Problem.** `guardianGlobalEventHistoriesProvider` awaits `entryHistoryProvider` for each scoped entry with `Future.wait` before resolving (`pet_care_due_events_screen.dart:22-42`); `_buildBody` shows a spinner until both entries and histories have values (`global_events_list.dart:133-148`).
2. **Why it matters.** With 30 care items that is 30 requests before the queue shows anything; on mobile data the main daily screen can sit on a spinner for several seconds. Histories are needed only to filter by "done" cohorts and to show "last done" lines.
3. **UX impact.** Slow first useful paint on the screen that the attention badge points to.
4. **A11y impact.** Long unlabelled spinner (see X-7).
5. **System impact.** N+1 request pattern; the server already returns `schedule` on each entry, which is enough for the agenda rows.
6. **Proposed fix.** Render the agenda as soon as entries are available; load histories in the background and fill in the "last done" lines and done-cohort filtering when they arrive (with a small "updating" caption). Longer term, ask the backend for a bulk histories endpoint or include `last_completed_on` in the entries payload.
7. **Reusable rule.** A list renders from its primary query; secondary queries decorate rows progressively.
8. **Implementation notes.** Change `_buildBody` to treat `historiesLoading` as non-blocking unless a done-cohort filter is active; keep `_ErrorRetryView` for the entries error and show a caption for a histories error. Label the spinner (see B-12.2).
9. **Acceptance checklist.** With 30 entries and throttled network, rows appear after the entries request; "last done" fills in later; filters that depend on history disable themselves until it arrives.

---

### B-10 Add and edit care entry — `/care/add`, `/pet/:petId/care/add`, `/pet/:petId/events/:entryId/edit`, `/health/edit/:id`

- **Source:** `features/health_tracking/presentation/screens/health_entry_form_screen.dart`, `health_entry_form_screen_body.dart`, `widgets/health_entry_form_preview_card.dart`, `controllers/health_entry_form_controller.dart`
- **Purpose:** Create, record or edit a care entry and its plan.
- **Strengths (confirmed):** all four routes reach one form with preselection from the route; dirty guard, validation and lifecycle confirmation; sticky actions on phone, constrained width on desktop with a live preview card.
- **Attention flag:** Watch (first-pass FLAG removed after verification of B-10.1).

#### B-10.1 Retired word "dose" in identifiers only — Copy · recommendation · Low

1. **Problem.** `doseLine`, `occurrence_dose_line` key and a class comment in `occurrence_care_context_card.dart:12, 91-95`; "scheduling doses" in a doc comment in `health_entry_schedule_times_section.dart:6`. Displayed strings use "Dosage" (the field label, `app_en.arb:615`) and time wording. `terminology.md` retires "dose(s)" in copy; terminology.md retires "dose" "in every family" (row for Done) but lists "Dosage" nowhere, so the field label needs an explicit decision.
2. **Why it matters.** Low: nothing visible breaches the rule today. Identifiers tend to leak into new strings and test names.
3. **UX impact.** None.
4. **A11y impact.** None.
5. **System impact.** Minor naming debt.
6. **Proposed fix.** Rename when the files are next touched (`amountLine`, `occurrence_amount_line`); confirm with the terminology owner whether "Dosage" stays as the field label.
7. **Reusable rule.** Retired words are removed from identifiers and keys when the code is next edited, not in a dedicated pass.
8. **Implementation notes.** The E2E suite may reference `occurrence_dose_line`; rename there too.
9. **Acceptance checklist.** No new visible string contains "dose"; identifier rename lands with its tests.

#### B-10.2 Edit-load failure is a snackbar, then an editable empty form — UX · recommendation · Medium (verify save path)

1. **Problem.** In `initState`, `loadEntry` failure is caught, `captureBaseline()` is called and a snackbar shows `failedToLoadEntry('$e')` (`health_entry_form_screen.dart:104-124`). The form remains on screen in edit mode (`isEdit: true`) with empty fields.
2. **Why it matters.** The snackbar disappears after a few seconds; the user is left with an empty "edit" form. Depending on how the controller saves in edit mode with no loaded entry, Save could error, create a new entry, or overwrite the existing one with blanks. This review could not determine which without running it, hence "verify".
3. **UX impact.** Confusing at best; a data-integrity risk at worst.
4. **A11y impact.** Snackbars are not reliably announced; the raw exception is in the text.
5. **System impact.** Edit routes are reached from the care item menu and deep links.
6. **Proposed fix.** Make load failure a persistent in-form state: replace the body with the shared error state ("We couldn't load this care item") and Retry; disable Save until the entry has loaded; if `loadEntry` returns `false` (entry not found) show "This care item isn't available" with Back. Drop the exception from the message.
7. **Reusable rule.** X-1, plus: an edit form never becomes editable before its subject has loaded.
8. **Implementation notes.** Add `loadFailed` / `notFound` to the controller state; the body already branches on `isLoading`. Verify first what `save()` does when `isEdit && entryId != null` but no entry was loaded, and add a guard regardless.
9. **Acceptance checklist.** With `/entries/:id` failing, the form shows the error state and Save is disabled; Retry loads the entry; not-found shows the message; no snackbar with exception text.

#### B-10.3 Desktop preview shows raw `form.dosage` — i18n · recommendation · Low (was Medium)

1. **Problem.** `HealthEntryFormPreviewCard(dosage: form.dosage, …)` prints the free-text field as typed (`health_entry_form_screen_body.dart:87-95`, `preview_card.dart:63-66`); the type label is localized correctly.
2. **Why it matters.** The value is user-entered free text, so echoing it is correct; the only issue is that it appears without the "Dosage" label, and it is shown for categories where dosage does not apply. Downgraded after reading the card.
3. **UX impact.** Minor: an unlabelled line in the preview.
4. **A11y impact.** Unlabelled value in the semantic tree.
5. **System impact.** None.
6. **Proposed fix.** Prefix with the field label (`l.dosage`) and show only when the selected category has the dosage field.
7. **Reusable rule.** Preview cards label every value they echo.
8. **Implementation notes.** The controller already knows which fields the category exposes (`loadedUncategorised` and the category rules).
9. **Acceptance checklist.** Preview shows "Dosage: 1 tablet" only for categories with dosage.

---

### B-11 Care item detail — `/pet/:petId/events/:entryId`

- **Source:** `features/experience/presentation/care_item/detail/care_item_detail_screen.dart`, `care_item_detail_body.dart`
- **Purpose:** Status, schedule, upcoming dates, history, lifecycle actions.
- **Strengths (confirmed):** `routeShell` keeps the shell title in every state (the pattern other screens should copy); lifecycle actions in one menu; two-column wide layout with mobile-first order.
- **Attention flag:** Watch.

#### B-11.1 Three error branches without retry; two interpolate the exception — UX · requirement · Medium

1. **Problem.** Pets error and entry error use `errorWithMessage('$error')`; history error uses `failedToLoadHistory('$error')`; none offers Retry (`care_item_detail_screen.dart:51-71, 223-227`).
2. **Why it matters.** § 6.10. The screen is the hub for every care action and a notification deep-link target.
3. **UX impact.** The history failure case is the worst: the item loaded, but the whole body is replaced by the history error, so schedule and actions are hidden because history failed.
4. **A11y impact.** No action to reach.
5. **System impact.** Shared fix, with one specific: history is supplemental to the body.
6. **Proposed fix.** Pets/entry errors: shared error state with Retry inside `routeShell`. History error: render the body with the history section showing "History unavailable · Retry" (X-2) rather than replacing the body.
7. **Reusable rule.** X-1 for primary data; X-2 for sections.
8. **Implementation notes.** `CareItemDetailBody` takes `history`; make it nullable or pass an `AsyncValue` and let the history module render its own state.
9. **Acceptance checklist.** With history failing, schedule and actions still work and the history section shows Retry; primary errors show Retry; no exception text.

#### B-11.2 Health-issue link row is a bare `InkWell` — A11y · recommendation · Medium

1. **Problem.** `InkWell(onTap: …, child: Row(Text, chevron))` with no minimum height, no `Semantics(button/link)` and no focus styling beyond the ink splash (`care_item_detail_body.dart:447-470`).
2. **Why it matters.** Row height is the text height (about 20 dp), under the 48 dp minimum in `system.md` § 7.1; screen readers announce it as text unless the platform infers a tap action.
3. **UX impact.** Small target next to other content.
4. **A11y impact.** Target size and role.
5. **System impact.** The same "label + chevron link row" exists in Pet detail (history, weight) and People; a shared row would fix all.
6. **Proposed fix.** Replace with a shared `DestinationRow` (ListTile-like, `minVerticalPadding` to reach 48 dp, `Semantics(button: true, label: "<issue name>, opens health issues")`, visible focus ring).
7. **Reusable rule.** X-9: any tappable row is at least 48 dp tall and has button/link semantics.
8. **Implementation notes.** Keep the `care_item_health_issue_link` key for E2E.
9. **Acceptance checklist.** Row height ≥ 48 dp; announced as a button with the issue name; keyboard-focusable on web.

---

### B-12 Occurrence (care date) — `/pet/:petId/events/:entryId/occurrences/:occurrenceId`

- **Source:** `features/experience/presentation/care_item/occurrence/occurrence_screen.dart`, `occurrence_screen_body.dart`
- **Purpose:** Act on one scheduled date.
- **Strengths (confirmed):** distinguishes gone (with "Open care details") from generic failure (with Retry); skip/undo expose busy state and refresh; this is the reference implementation for error handling in the area.
- **Attention flag:** None (downgraded from Watch after verification).

#### B-12.1 Retired word "Missed" in ARB key names only — Copy · recommendation · Low

1. **Problem.** Keys `occurrenceZoneMissed`, `occurrenceMissedCount`, `occurrenceSkipEarlierMissed`, `occurrenceSkipAllMissed` (`app_en.arb:2613-2631`); their values read "Overdue", "{count} overdue", "Skip all overdue", which comply.
2. **Why it matters.** Low; key names are invisible to users but visible to translators and future authors.
3. **UX impact.** None.
4. **A11y impact.** None.
5. **System impact.** Minor naming debt.
6. **Proposed fix.** Rename keys to `…Overdue…` when the strings are next edited; keep values.
7. **Reusable rule.** As B-10.1.
8. **Implementation notes.** Generated `AppLocalizations` getters change name; a mechanical rename.
9. **Acceptance checklist.** No `Missed` in ARB key names for the occurrence screen.

#### B-12.2 Initial load state is an unlabelled spinner — A11y · recommendation · Low

1. **Problem.** `null => const Center(child: CircularProgressIndicator())` (`occurrence_screen.dart:103`); after a Retry the state resets to `null` and the same spinner shows. No `Semantics(label)` and no announcement when the body arrives.
2. **Why it matters.** Screen-reader users hear nothing while loading and nothing on success; after Retry they cannot tell whether anything happened.
3. **UX impact.** None for sighted users.
4. **A11y impact.** X-7.
5. **System impact.** Same gap on every spinner in the area.
6. **Proposed fix.** Use one shared labelled progress widget (`Semantics(label: <localized 'Loading'>, liveRegion: true)` (no `loading` ARB key exists yet)) and announce "Loaded" via `SemanticsService.announce` or a live-region header when the body renders.
7. **Reusable rule.** X-7: every progress indicator has a label; state changes are announced.
8. **Implementation notes.** Apply the same widget in B-9.2 and the shared error state.
9. **Acceptance checklist.** VoiceOver reads "Loading" during fetch and the screen heading after load; Retry triggers both again.

---

### B-13 Pet timeline — `/pet/:petId/timeline`

- **Source:** `features/pet_profile/presentation/screens/pet_timeline_screen.dart`, `pet_timeline_view.dart`
- **Purpose:** Composite history; add a timeline entry.
- **Strengths (confirmed):** reachable from pet history; distinct localized loading, error, no-data states; add action with tooltip.
- **Attention flag:** None.

#### B-13.1 Load error without retry — UX · requirement · Medium (was recommendation)

1. **Problem.** Error branch is localized text only (`petTimelineLoadError`, `pet_timeline_screen.dart:54-67`); no retry.
2. **Why it matters.** § 6.10. The copy is already right; only the action is missing.
3. **UX impact.** Dead end on a history destination.
4. **A11y impact.** No action.
5. **System impact.** Shared fix.
6. **Proposed fix.** Shared error state with Retry invalidating the timeline provider; keep the existing string as the title.
7. **Reusable rule.** X-1.
8. **Implementation notes.** Disable the bottom Add button while in the error state only if adding depends on the loaded data (it depends on `petName`, which comes separately, so it can stay enabled).
9. **Acceptance checklist.** Retry present and working.

#### B-13.2 Three Add buttons on one screen — UX · preference · Low

1. **Problem.** App-bar icon, empty-state button and persistent bottom button all open the add sheet (`pet_timeline_screen.dart:43-48, 68-81, 92-103`).
2. **Why it matters.** On an empty timeline the user sees two Add buttons at once (empty state and bottom), plus the icon.
3. **UX impact.** Mild clutter; no functional problem.
4. **A11y impact.** Three identical actions in the traversal order.
5. **System impact.** None.
6. **Proposed fix.** Keep the app-bar icon on all states; show the bottom button only when the list is populated; keep the empty-state button only when empty.
7. **Reusable rule.** One primary action per state, plus at most one secondary placement.
8. **Implementation notes.** Trivial conditional on `entries.isEmpty`.
9. **Acceptance checklist.** Empty: icon + empty-state button; populated: icon + bottom button.

---

### B-14 Weight hub — `/pet/:petId/weight`

- **Source:** `features/weight_tracking/presentation/screens/weight_hub_screen.dart`, summary/chart/history/routines widgets
- **Purpose:** Weight history, chart, routine context; record a weigh-in.
- **Strengths (confirmed):** summary + chart + history + routines in one hub; empty state explains the first step with merged semantics; delete dialog explains linked care dates; unit preference respected.
- **Attention flag:** Watch.

#### B-14.1 Overview failure silently removes target and routine context — UX · recommendation · Medium

1. **Problem.** `overviewAsync.valueOrNull` feeds the summary card, the chart's `targetKg` and the routines card (`weight_hub_screen.dart:29, 53-56, 62-77`). If the overview request fails or is still loading, those widgets render as if no target or routine exists.
2. **Why it matters.** "No target set" and "target unavailable" are different messages to a pet parent managing a weight plan; the chart drops the reference line without saying why.
3. **UX impact.** The user may re-enter a target that already exists, or think the routine was deleted.
4. **A11y impact.** Nothing announced.
5. **System impact.** X-2 again; the same caption component as B-3.1/B-4.1.
6. **Proposed fix.** Pass `overviewAsync` (not its value) to the summary and routines cards; while loading show a one-line skeleton; on error show "Target and routine unavailable · Retry" in the summary card and keep the chart without the reference line.
7. **Reusable rule.** X-2.
8. **Implementation notes.** `ref.invalidate(weightOverviewProvider(petId))` on Retry; entries and overview remain independent so history still renders.
9. **Acceptance checklist.** With `/weight/overview` failing, history and chart render, the summary shows the unavailable caption with Retry; after recovery the target line appears.

#### B-14.2 Entries error is a bare, un-centred text with the exception and no retry — UX · requirement · Medium (was recommendation)

1. **Problem.** `Padding(child: Text(l.errorLoadingWeightData(error.toString())))` (`weight_hub_screen.dart:46-51`): top-left aligned body text, exception interpolated, no action.
2. **Why it matters.** § 6.10 on all three counts.
3. **UX impact.** Easy to miss; no recovery.
4. **A11y impact.** No action.
5. **System impact.** Shared fix.
6. **Proposed fix.** Shared error state with Retry on `weightEntriesNotifierProvider(petId)`; keep the add actions enabled (recording does not depend on the list).
7. **Reusable rule.** X-1.
8. **Implementation notes.** Replace `errorLoadingWeightData` usage with the generic title plus a subject string.
9. **Acceptance checklist.** Retry present and working; no exception text; layout centred.

---

**Patterns seen in this area** (feed Part 4):

- Failed primary loads print exceptions or offer no retry → shared `AsyncErrorState` → Home, Pet detail, Health issues, All care, Care item, Timeline, Weight hub, Care form load.
- Supplemental data fails to a confident default → `SupplementalStateCaption` + nullable status → Tag filter, Bulk share care status, Weight overview, Care item history.
- Non-data states drop the shell → `routeShell` pattern from Care item detail → Pet detail, All care, Edit guard.
- Spinners are unlabelled → shared labelled progress → Occurrence, All actions, every `when(loading:)`.
- Generic "No entries yet" hides the real reason → per-screen empty strings with one action → Health issues, All actions (filtered), Bulk share (no eligible).
- Retired words survive in identifiers and keys → rename on next edit → Occurrence, Care context card, Schedule times section.
- Post-flow destinations → land on the created object, remove frozen branches → Pet form.

**Changes from the first pass (Area B).** Withdrawn after the reachability check in Part 5: B-2.2 and B-2.3 describe `pet_care_today_orientation.dart`, which no live screen imports (home test asserts the key is absent); the B-2 source list and strengths were corrected. Upgraded to requirement on the basis of `system.md` § 6.10: B-4.1, B-6.1, B-7.1, B-13.1, B-14.2. Downgraded: B-1.1 (requirement → recommendation; labels exist for assistive technology), B-5.2 (requirement → recommendation; the route works via redirects), B-10.3 (Medium → Low; the value is user text, only the label is missing). B-12 attention flag None (its error handling is the area's reference). B-10.2 and B-6.2 marked "verify". Counts for the whole document were updated in the summary.

## Area C — Away plans, people and sharing (detailed)

This area was re-reviewed screen by screen against the source, including every first-pass finding and its cited branches, using file reads rather than search snippets. Grades follow [`system.md` § 6.10](../system.md#610-loading-empty-error-and-permission-states), § 2.3 and § 7.1, [`terminology.md`](../terminology.md) and [`copy-tone.md`](../copy-tone.md); reusable rules refer to Part 4's X-ids. File paths below are relative to `flutter_app/lib/` unless another root is stated. This is analysis only: no application code changed, and rendered layout, focus and screen-reader behaviour were not tested; dependent claims are marked “(verify)”.

**Area summary.** Away planning and Contacts have a strong base: one scrollable creation form, explicit preview retry, protected edits, a searchable adaptive roster, and server-previewed household removal. The four recipient journeys remain the highest-impact problem: two hide the signed-out continuation, one exposes authenticated commands without authentication, and the absence invite is blocked by the guard. Primary-load errors and dependent collections need consistent state handling. Verification corrected several overstatements: add-person invite failure is caught but misreported as total save failure; household pets remain visible but can be wrongly attributed to another member; shared-pet preview is already restricted; chips wrap; the household-create dialog has no 720 dp height cap.

**Shared fix that covers most of Area C.** Apply X-1/X-2 with the planned `AsyncErrorState` (B-2.1), `SupplementalStateCaption` (B-3.1/B-4.1) and labelled progress (B-12.2). For X-3, build one auth-aware recipient block showing who invited, the pets/household and exact access scope, plus one “Sign in or create an account to continue” action; authenticated users then make the explicit accept/decline decision. Send that action to `/landing?returnTo=<encoded invite URI>`, validate the target against the four recipient routes, preserve it through login, native login, signup and any onboarding, and consume it only when returning to that invite; never auto-accept. Centralise those four public route prefixes in `app_router.dart` and add `/absence-invite/`, leaving mutations authenticated.

The existing `shell_return_navigation.dart:14-44` safely parses in-app `returnTo` for **back navigation**, not authentication. `landing_screen.dart:56-108` sends all three successful auth paths to `/app/resolve`; `app_router.dart:126-132` does likewise for signed-in `/landing` and `/`; `experience_resolve_screen.dart:22-35, 54-58` chooses onboarding/home with no invite continuation. No auth consumer of `redirect`, `returnTo` or `from` was found in the auth/router code searched and read. The absence screen's `/login?redirect=…` (`absence_invite_landing_screen.dart:64-69`) is only an attempted mechanism: `/login` is not registered, and signed-out routing replaces it with `/landing` without the parameter.

---

### C-1 Away planning hub — `/pc/away`

- **Source:** `core/router/away_routes.dart`, `features/pet_care/context/presentation/screens/planned_absence_hub_screen.dart`, `widgets/planned_absence_hub_card.dart`
- **Purpose:** Browse upcoming/past away plans and create another.
- **Strengths (confirmed):** plans have independent loading, localized error with retry, and an empty create action; upcoming and past sections are separate; cards expose button semantics.
- **Attention flag:** Watch.

#### C-1.1 Unavailable pet names become a selection instruction — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** `planned_absence_hub_screen.dart:21-25, 58-62` collapses unresolved/failed `petListProvider` to an empty name map. `planned_absence_hub_card.dart:95-107` then substitutes `careContextAwayPetsRequired`, whose value is “Select at least one pet” (`app_en.arb:2696`; FR: `app_fr.arb:2567`), even for an existing plan with pet IDs.
2. **Why it matters.** This is not merely a missing decoration: the fallback makes a false corrective claim, contrary to `system.md` § 6.10 and X-2.
3. **UX impact.** A valid saved plan looks incomplete and asks for a selection from a card that opens its detail, not its pet selector.
4. **A11y impact.** The same false instruction enters the card's semantic label (`planned_absence_hub_card.dart:46-48`).
5. **System impact.** Primary plans can remain usable while supplemental pet identity is unavailable.
6. **Proposed fix.** Keep plans visible, reserve the name lines while loading, and show “Pet names unavailable” with one hub-level Retry on failure; reserve the selection instruction for actual form validation.
7. **Reusable rule.** X-2: unknown supplemental data must not become a claim about the saved object.
8. **Implementation notes.** Pass pet-state information from `planned_absence_hub_screen.dart` to the card; reuse planned `SupplementalStateCaption`, invalidate `petListProvider`, and add `awayPetNamesUnavailable` in both ARBs.
9. **Acceptance checklist.** A plan with pet IDs never says “Select at least one pet” while pets load/fail; Retry restores names; truly empty plan IDs are handled separately; semantic labels match the actual state.

#### C-1.2 Hub loading has no task-specific progress label — A11y · recommendation · Low

1. **Problem.** The loading branch is a bare `CircularProgressIndicator` (`planned_absence_hub_screen.dart:45-46`) without `semanticsLabel` or a surrounding status label.
2. **Why it matters.** Generic platform progress semantics do not identify which content is arriving; Part 4 X-7 asks for labelled waits.
3. **UX impact.** None for sighted users beyond an indefinite wait.
4. **A11y impact.** No explicit “Loading away plans” message is supplied; actual speech depends on Flutter/platform behaviour, not a proven completely silent state.
5. **System impact.** The same progress gap recurs on the plan screen.
6. **Proposed fix.** Use the shared labelled progress pattern, with a localized task label and a live-region heading when content arrives.
7. **Reusable rule.** X-7: progress identifies the task, not just activity.
8. **Implementation notes.** Replace the branch in `planned_absence_hub_screen.dart` with B-12.2's planned labelled progress; add `awayPlansLoading` to `app_en.arb` and `app_fr.arb`.
9. **Acceptance checklist.** Semantics tests expose the localized loading label; a device screen-reader check announces the wait and then the plan heading without duplicate announcements.

---

### C-2 New away plan — `/pc/away/new`

- **Source:** `features/pet_care/context/presentation/screens/planned_absence_flow_screen.dart`, `widgets/planned_absence_pets_step.dart`, `planned_absence_preview_step.dart`
- **Purpose:** Choose dates and pets, preview care, and save a plan.
- **Strengths (confirmed):** single scrollable form; date/pet validation; phone sticky actions; per-pet preview loading/error/retry; successful creation navigates to the created plan.
- **Attention flag:** Watch.

#### C-2.1 Pet loading and failure render “No pets yet” — UX · requirement · Medium

1. **Problem.** `planned_absence_flow_screen.dart:252-254` converts `petsAsync.valueOrNull` to `[]`, and `planned_absence_pets_step.dart:38-44` displays `noPetsYet`. Both initial loading and an uncached failure therefore look like a resolved empty account.
2. **Why it matters.** `system.md` § 6.10 explicitly prohibits empty copy while unresolved and requires useful recovery; pet selection is a prerequisite, not an optional enhancement.
3. **UX impact.** The user cannot select pets or understand why saving is unavailable; retrying requires leaving the flow.
4. **A11y impact.** Assistive technology receives the false empty message, with no retry to focus.
5. **System impact.** Selected IDs persist locally, so save eligibility must also consider provider readiness rather than only dates/selection.
6. **Proposed fix.** Render distinct loading, error-with-retry, resolved-empty and ready pet sections; gate Save until eligible pets resolve, retaining entered dates/title through retry.
7. **Reusable rule.** X-1/X-2: prerequisite lists never fall back to empty, and controls remain disabled while prerequisites are unresolved.
8. **Implementation notes.** Branch on `petListProvider` in `planned_absence_flow_screen.dart`, reuse planned `AsyncErrorState`/labelled progress, invalidate that provider, and add `awayPetsLoadError` plus a precise `awayNoEligiblePets` in both ARBs.
9. **Acceptance checklist.** Slow/failing pets never show `noPetsYet`; Save is unavailable until ready; Retry preserves the form and restores choices; a real empty account offers one safe Add pet action and a filtered-empty account explains eligibility.

#### C-2.2 Cancel drops entered changes without confirmation — UX · recommendation · Low

1. **Problem.** `_handleCancel` only calls `context.pop()` (`planned_absence_flow_screen.dart:170-172`); the screen has no dirty-state `PopScope` (`274-331`).
2. **Why it matters.** Editing the same plan already has deliberate discard protection; creation can involve dates, a title and multiple selections.
3. **UX impact.** Accidental Cancel/back can require re-entry; direct-link Cancel also lacks the explicit no-stack fallback used by edit.
4. **A11y impact.** A mistaken navigation action has no correction opportunity.
5. **System impact.** Create and edit use the same action widgets but different exit policies.
6. **Proposed fix.** Track a baseline after automatic pet preselection, confirm meaningful changes, and pop or return to `/pc/away` when no stack exists.
7. **Reusable rule.** X-11: form exits protect entered work and have a sensible deep-link fallback.
8. **Implementation notes.** Reuse `confirmDiscardFormChanges` from `core/widgets/form/app_form_discard_dialog.dart` and `planned_absence_edit_screen.dart`'s `PopScope`; reuse `formUnsavedTitle`, `formUnsavedBody`, `formDiscard` and `cancel` in both ARBs rather than creating alternate copy.
9. **Acceptance checklist.** Untouched form exits without prompt; changed title/dates/selection prompts on Cancel and system back; Stay retains values; direct-link exit reaches the hub; successful save does not prompt.

#### C-2.3 Large-text sticky actions (verify) — A11y · recommendation · Low

1. **Problem.** The phone layout combines an `Expanded` scroll body with `AppFormStickyActionsBar` (`planned_absence_flow_screen.dart:279-328`). The shared bar uses two expanded buttons in a `Row`, not a fixed-height action region (`app_form_actions_bar.dart:43-75, 110-128`); overflow at large text is unconfirmed.
2. **Why it matters.** `system.md` § 2.3 requires 200% text without clipping, and § 7.2 calls for stacked compact actions when labels wrap.
3. **UX impact.** Long French save labels may crowd Cancel or reduce the visible form; this needs a rendered test.
4. **A11y impact.** Targets already have a 48 dp minimum and the sticky bar has `SafeArea`; neither a small target nor missing safe-area breach is established.
5. **System impact.** Any confirmed action-layout fix belongs in the shared bar, not this one flow.
6. **Proposed fix.** Verify at 200% with keyboard open; stack actions when the available width/text scale cannot accommodate both labels.
7. **Reusable rule.** X-8: content-sized, safe-area-aware action bars adapt to text rather than force it into one row.
8. **Implementation notes.** Exercise `AppFormStickyActionsBar` in `core/widgets/form/app_form_actions_bar.dart` and `planned_absence_flow_screen.dart`; use existing `careContextAwaySaveAction`/`cancel` EN/FR values and preserve the existing action keys.
9. **Acceptance checklist.** At 360 × 640 dp, 200% EN/FR and with keyboard open, every field and action is reachable, labels are unclipped, targets remain at least 48 dp, and no render overflow occurs.

---

### C-3 Away plan — `/pc/away/:id`

- **Source:** `features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart`, `core/router/away_routes.dart`
- **Purpose:** Review dates, readiness, carers and care; edit or export a handover.
- **Strengths (confirmed):** the active route builds the full screen, not the placeholder; its local shell helper preserves chrome in all states; plan/readiness errors have retry; care coverage has its own invalidation callback.
- **Attention flag:** Watch.

#### C-3.1 Pet failure prints an exception without retry — UX · requirement · Medium (was recommendation)

1. **Problem.** The `allPetsIncludingOrgProvider` error branch displays `l.errorWithMessage('$error')` only (`planned_absence_plan_screen.dart:63-67`), despite the other two prerequisite loads having retry.
2. **Why it matters.** `system.md` § 6.10 requires plain language and meaningful retry, not a translated prefix around a raw exception.
3. **UX impact.** A temporary pet failure blocks the entire handover body and its export/edit controls.
4. **A11y impact.** Technical exception text is exposed with no recovery action.
5. **System impact.** The shell is already preserved; no new route scaffold is needed.
6. **Proposed fix.** Use a localized pets-load error and Retry inside the existing shell; consider retaining the plan summary when only names are unavailable.
7. **Reusable rule.** X-1 for the blocking branch; X-2 if pet identities become progressively enhanced content.
8. **Implementation notes.** In `planned_absence_plan_screen.dart`, reuse planned `AsyncErrorState`, invalidate `allPetsIncludingOrgProvider`, and add `awayPlanPetsLoadError` to both ARBs; retain the existing `shell` helper.
9. **Acceptance checklist.** Failed pet lookup shows no exception, keeps title/back, and provides Retry; recovery restores the plan and export controls without navigation.

#### C-3.2 Three prerequisite waits have no task label — A11y · recommendation · Low

1. **Problem.** Absence, readiness and pet loading each return a bare progress indicator (`planned_absence_plan_screen.dart:39-65`).
2. **Why it matters.** X-7 calls for a perceivable waiting state; serial body gates can make a generic spinner feel indefinite.
3. **UX impact.** The title stays visible, but no wording identifies the current load.
4. **A11y impact.** There is no explicit task label; actual platform announcements require device testing.
5. **System impact.** One shared progress widget covers all three branches and the hub.
6. **Proposed fix.** Supply a stable “Loading away plan” label, avoiding three repetitive announcements when dependencies resolve closely together.
7. **Reusable rule.** X-7: label progress and announce the resulting heading, not every internal request.
8. **Implementation notes.** Apply B-12.2's labelled progress in `planned_absence_plan_screen.dart`; add `awayPlanLoading` in both ARBs and keep the existing shell.
9. **Acceptance checklist.** All loading branches expose the localized label; screen-reader testing hears one coherent wait followed by the plan heading.

---

### C-4 Edit away plan — `/pc/away/:id/edit`

- **Source:** `features/pet_care/context/presentation/screens/planned_absence_edit_screen.dart`, `core/widgets/form/app_form_actions_bar.dart`
- **Purpose:** Change title/dates/handover note or cancel a plan.
- **Strengths (confirmed):** dirty-state back guard; date-change and guest-access-widen confirmation; confirmed cancellation; save/delete errors mapped to localized copy; content scrolls and actions adapt by breakpoint.
- **Attention flag:** Watch.

#### C-4.1 Initial failure has no retry — UX · requirement · Medium (was recommendation)

1. **Problem.** `_loadAbsence` records `_loadFailed` (`planned_absence_edit_screen.dart:78-100`), but the error body is just `careContextAwayPlanLoadError` (`369-372`).
2. **Why it matters.** A failed primary load without meaningful retry breaches `system.md` § 6.10.
3. **UX impact.** The user must leave and reopen before editing; the phone actions are correctly hidden, but recovery is absent.
4. **A11y impact.** There is a title/back control but no recovery action in the error body.
5. **System impact.** Loading uses a local repository method, so invalidating the detail provider alone would not reload this form.
6. **Proposed fix.** Render `AsyncErrorState` with the existing localized message and Retry calling `_loadAbsence`.
7. **Reusable rule.** X-1: retry re-runs the actual loader driving the screen.
8. **Implementation notes.** Update the error branch in `planned_absence_edit_screen.dart`; reuse `careContextAwayPlanLoadError`, `retry` and B-2.1's planned shared widget, leaving the existing dirty baseline capture intact.
9. **Acceptance checklist.** Error shows Retry and no editable form; Retry invokes a new request and populates all baseline fields on success; normal dirty/discard protection still works afterward.

#### C-4.2 Edit actions with enlarged text (verify) — A11y · recommendation · Low

1. **Problem.** Edit uses shared inline/sticky actions (`planned_absence_edit_screen.dart:294-303, 402-413`); their 20 dp spinner is an icon **inside** a button with a 48 dp minimum (`app_form_actions_bar.dart:59-72`), not a 20 dp tap target.
2. **Why it matters.** The remaining question is responsive text/focus behaviour under `system.md` § 2.3/§ 7.1, not spinner size.
3. **UX impact.** Crowding of the French save label at 200% remains possible but unobserved.
4. **A11y impact.** `SafeArea` and minimum targets already exist; keyboard traversal and text clipping need runtime verification.
5. **System impact.** This is the same shared action-bar test as C-2.3.
6. **Proposed fix.** Verify the loaded, saving, cancelling and keyboard-open states; if needed, stack the actions in the shared widget.
7. **Reusable rule.** X-8/X-9: inspect the interactive parent, not its icon dimensions, and test text scaling.
8. **Implementation notes.** Test `planned_absence_edit_screen.dart` with `AppFormStickyActionsBar`; reuse `careContextAwaySaveAction`, `cancel` and existing busy/discard strings in both ARBs, with B-12.2 labelled progress if adding a busy label.
9. **Acceptance checklist.** At 200% EN/FR, no clipped actions or overflow; keyboard focus remains visible; both buttons are at least 48 dp; saving prevents duplicate submissions.

---

### C-5 Contacts hub / roster — `/pc/people`

- **Source:** `features/people/presentation/hub/people_hub_layout.dart`, `people_hub_placeholder.dart`, `roster_list.dart`, `roster_list_sections.dart`, `hub_search_field.dart`, `core/widgets/collection_filter/filter_dimension_menu.dart`
- **Purpose:** Search/filter the directory and select a person.
- **Strengths (confirmed):** wide list-detail and narrow single-pane layout; localized search; roster skeletons, retry and add action; query-backed navigation; standard checkbox filter controls and minimum-height person cards.
- **Attention flag:** None.

#### C-5.1 More orientation in the wide placeholder — UX · preference · Low (was recommendation)

1. **Problem.** The wide index detail pane displays `peopleHubSelectSomeone` (`people_hub_layout.dart:37-46`; `people_hub_placeholder.dart:11-21`), while the roster already has its Add person action (`roster_list.dart:178-193`).
2. **Why it matters.** The current instruction is accurate for an unselected pane, not a broken empty state; additional orientation is a content preference rather than a usability breach.
3. **UX impact.** A short explanation could help first-time visitors, but is not necessary to operate the existing controls.
4. **A11y impact.** None.
5. **System impact.** Additional copy must not repeat a second primary Add action or clutter every visit.
6. **Proposed fix.** Optionally add one quiet line explaining contact/pet relationships, retaining the existing selection instruction and roster action.
7. **Reusable rule.** An unselected detail pane is not an empty account; keep orientation concise and contextual.
8. **Implementation notes.** Only `people_hub_placeholder.dart` needs presentation changes; keep `peopleHubSelectSomeone` and optionally add `peopleHubOrientation` to both ARBs, using theme body text.
9. **Acceptance checklist.** Wide unselected pane remains accurate for both populated and empty rosters; the roster's single Add action stays available; no duplicated call to action appears.

#### C-5.2 Filter and current-person announcements (verify) — A11y · recommendation · Low

1. **Problem.** `RosterList.selectedPersonId` is accepted but not passed into row rendering (`roster_list.dart:19-27, 85-90`); `PersonCard` supplies button semantics but no selected state (`person_card.dart:61-80`). Filters already use `CheckboxListTile(value: selected)` and 48 dp menu triggers (`filter_dimension_menu.dart:58-74, 95-127`), so a blanket “filters lack state” claim is unsupported.
2. **Why it matters.** In a persistent wide roster, identifying the currently opened person is useful; actual combined selection announcements and keyboard focus need verification.
3. **UX impact.** Re-orientation between list and detail may be harder; no broken keyboard interaction is established from code.
4. **A11y impact.** Current-person state is not explicitly supplied; standard filter state semantics should be preserved rather than replaced.
5. **System impact.** An optional selected parameter on `PersonCard` could serve other master-detail contexts.
6. **Proposed fix.** Verify keyboard/filter semantics first; thread the selected ID into rows and expose `Semantics(selected: true)` for the active person if that state is needed.
7. **Reusable rule.** X-7/X-9: preserve standard control semantics and expose the current item in a master-detail list.
8. **Implementation notes.** Update `roster_list.dart`, `roster_list_sections.dart` and `person_card.dart`; retain existing localized person labels and `peopleHubSearchHint`, without inventing an English “selected” suffix.
9. **Acceptance checklist.** Keyboard can open/select/clear filters and open a person; semantics reports checkbox values and the current roster item once; list-to-detail focus remains predictable at wide/narrow breakpoints.

#### C-5.3 URL updates and typing/browser navigation (verify) — UX · recommendation · Low

1. **Problem.** Every search change trims the text and calls `context.go` (`roster_list.dart:63-66, 147-153`); `HubSearchField.didUpdateWidget` assigns `_controller.text` when the routed query differs (`hub_search_field.dart:29-33`). Rebuild-driven caret changes and browser-history behaviour are not observable from these calls alone.
2. **Why it matters.** Query persistence is valuable, but typing spaces and editing mid-query should not fight URL normalization.
3. **UX impact.** Possible caret/composition disruption or excessive history entries; neither is asserted as reproduced.
4. **A11y impact.** Focus loss, if present, would especially affect keyboard and assistive-technology users.
5. **System impact.** Search state and router state need clear ownership rather than reciprocal uncontrolled updates.
6. **Proposed fix.** Verify spaces, composition and Back/Forward; keep the live controller value while typing and debounce/replace URL updates if needed.
7. **Reusable rule.** URL synchronization must not interrupt an active editing session.
8. **Implementation notes.** Test `roster_list.dart`, `hub_search_field.dart` and `RosterHubQuery`; retain `peopleHubSearchHint` and the `people_list_search` key, and preserve meaningful filter/person navigation history.
9. **Acceptance checklist.** Typing “Marie Claire”, editing in the middle and composing accented text preserve caret/focus; Back/Forward restores meaningful queries without replaying every character.

---

### C-6 Add person — `/pc/people/new`

- **Source:** `features/people/presentation/add/add_person_flow.dart`, `features/people/presentation/routes/people_routes.dart`
- **Purpose:** Create a directory contact and optionally continue to pet sharing or a household invitation.
- **Strengths (confirmed):** five-step localized progress; disabled save while busy; scrollable step body with safe-area actions; mapped save errors; pet-share handoff includes selected pets, contact and email.
- **Attention flag:** Watch.

#### C-6.1 Invite failure is caught as total save failure after contact creation — UX · requirement · Medium

1. **Problem.** Contact creation succeeds before awaited `_afterSave(detail)` (`add_person_flow.dart:69-84`); household invite creation occurs later (`137-147`). Contrary to the first pass, exceptions **are caught** by `_save` (`84-95`), but only a generic/mapped save error is shown, with no retained saved-contact outcome or invite-only retry.
2. **Why it matters.** X-5 and `system.md` § 6.9 require reporting the actual result, including partial success; a second Save repeats contact creation rather than just invitation.
3. **UX impact.** Users may believe nothing saved and retry the whole flow; the code permits duplicate attempts, although server deduplication outcomes were not tested.
4. **A11y impact.** A transient snackbar does not provide a persistent partial-success explanation or a clear retry target.
5. **System impact.** `_resolveHouseholdId` also runs before and after contact creation, so the chosen household should be retained with the saved contact.
6. **Proposed fix.** Model contact-created/invite-pending/invite-failed separately; say “Contact saved; invitation not sent” and offer invite-only Retry or Open contact.
7. **Reusable rule.** X-5: multi-mutation flows report each committed result and retry only the failed stage.
8. **Implementation notes.** Retain `ContactDetail` and household ID in `add_person_flow.dart`/its controller; call `createHouseholdInvite` with that existing contact; add `peopleContactSavedInviteFailed` and `peopleRetryHouseholdInvite` to both ARBs, using a persistent live-region status.
9. **Acceptance checklist.** With contact POST succeeding and invite POST failing, one contact exists, the partial result remains visible, Retry sends only the invitation, and leaving opens the saved contact without a second create request.

#### C-6.2 Step focus and progress announcement (verify) — A11y · recommendation · Low

1. **Problem.** Advancing/back changes the controller step (`add_person_flow.dart:196-212`), swaps the body (`282-299`) and updates ordinary progress text (`238-250`), with no explicit heading focus or live-region management.
2. **Why it matters.** Users should perceive that the step changed, not search for where the previous button led; existing “step” wording is a strength.
3. **UX impact.** Keyboard position may remain on Next while the content above changes; actual traversal was not tested.
4. **A11y impact.** Whether progress is automatically announced depends on platform semantics, so this remains a verification recommendation.
5. **System impact.** A shared step-heading focus pattern could also support onboarding.
6. **Proposed fix.** Verify first, then focus the new step heading or announce the localized progress once, avoiding duplicate spoken updates.
7. **Reusable rule.** X-7: changing a step exposes both position and the new content's heading.
8. **Implementation notes.** Add a heading focus node/live region in `_AddPersonFlowBody` in `add_person_flow.dart`; reuse `peopleAddStepProgress` and existing step titles from both ARBs.
9. **Acceptance checklist.** Next/Back updates an announced step number; focus reaches the new heading or first field predictably; invalid fields receive focus; no duplicate announcement occurs on simple field edits.

#### C-6.3 Dialog-looking route dismissal (verify) — UX · recommendation · Low

1. **Problem.** Medium/wide layouts return a `Dialog` widget (`add_person_flow.dart:160-184`), but `people_routes.dart:24-31` installs an ordinary route builder, not a dialog route. Phone gets a `Scaffold`, and first-step Back calls `context.pop()` (`187-201`).
2. **Why it matters.** A dialog appearance alone does not guarantee modal focus trapping, Escape dismissal or a valid direct-link pop destination.
3. **UX impact.** Direct entry or keyboard dismissal may differ from a true modal; no runtime failure is claimed.
4. **A11y impact.** Focus containment and return focus require an actual keyboard/screen-reader check.
5. **System impact.** The team should choose a full routed form or a proper modal route consistently.
6. **Proposed fix.** Verify route/back/Escape; prefer a clearly routed form with explicit Close and a `/pc/people` fallback, or deliberately supply modal route semantics.
7. **Reusable rule.** X-8/X-11: modal-looking surfaces have deliberate modal behaviour and reliable exits.
8. **Implementation notes.** Coordinate `add_person_flow.dart` with `people_routes.dart`; reuse `AppFormBreakpoints`, existing `peopleAddBack`/`cancel` strings and the shared discard dialog if dirty exit protection is added.
9. **Acceptance checklist.** Pushed and directly opened routes exit to Contacts safely; Tab/Shift-Tab and Escape behave consistently with the chosen modal/page model; closing restores focus where possible.

---

### C-7 Person detail — `/pc/people/:personId`

- **Source:** `features/people/presentation/detail/person_detail_page.dart`, `person_detail_contact_view.dart`, `person_detail_shell.dart`
- **Purpose:** View identity, contact actions, linked pets/access, notes and related care.
- **Strengths (confirmed):** summary can persist during detail loading; contextual tabs; localized edit tooltip; separate contact/member/invite targets; surrounding People layout preserves the wide roster.
- **Attention flag:** Watch.

#### C-7.1 Primary detail errors have no retry — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** Roster failure/not-found is centered text (`person_detail_page.dart:26-33`); contact-detail failure/null is likewise text (`person_detail_contact_view.dart:50-56`). No retry exists in these branches; however, the surrounding People shell/roster and `PersonDetailShell` already provide navigation, so “no way back at all” overstates the evidence.
2. **Why it matters.** Primary failure without retry breaches `system.md` § 6.10 even with correctly localized error text.
3. **UX impact.** Users must leave/re-enter or use a separate roster refresh that does not explicitly retry the contact-detail request.
4. **A11y impact.** The error body offers no focusable recovery action.
5. **System impact.** Roster and detail are distinct providers and need the correct retry wiring at each level.
6. **Proposed fix.** Show `AsyncErrorState` for failures; treat a resolved null as unavailable, with one Back to contacts action rather than calling it a network error.
7. **Reusable rule.** X-1: failures and confirmed missing records are different recoverable states.
8. **Implementation notes.** Retry `rosterProvider.notifier.refresh()` or invalidate `personDetailProvider(contactId)` in their respective files; retain `PersonDetailShell`/People shell, reuse `peopleListLoadError`, `peopleDetailNotFound`, `retry`, and add `peopleBackToContacts` in both ARBs.
9. **Acceptance checklist.** Each provider failure has a working retry; null shows only unavailable/back guidance; the roster remains usable in wide mode and shell navigation remains present in compact mode.

#### C-7.2 Scrollable tabs and focus order (verify) — A11y · recommendation · Low

1. **Problem.** Standard `DefaultTabController`, scrollable `TabBar` and `TabBarView` wrap labeled semantic children (`person_detail_contact_view.dart:127-159`); this supplies a standard selection mechanism, not proof of a missing selected state.
2. **Why it matters.** Header/contact actions precede a variable number of tabs; runtime traversal should remain comprehensible.
3. **UX impact.** Possible navigation friction in a dense wide detail pane, not an observed defect.
4. **A11y impact.** Keyboard switching, selected-tab announcement and focus after body changes need verification.
5. **System impact.** Preserve Material tab semantics instead of replacing them with bespoke controls.
6. **Proposed fix.** Verify with carer/professional and member-only tab sets; fix only reproducible focus or semantic duplication problems.
7. **Reusable rule.** X-7: standard tabs retain their role, selected state and meaningful content order.
8. **Implementation notes.** Test `person_detail_contact_view.dart`, `ContactActionBar` and existing `people_detail_tab_*` identifiers; keep `peopleDetailTabOverview`, `peopleDetailTabPetsAccess`, `peopleDetailTabRelatedCare`, `peopleDetailTabNotes` in both ARBs.
9. **Acceptance checklist.** Keyboard reaches all tabs and their content; the active tab is announced once; horizontal tab scrolling does not hide the focused tab at 200% EN/FR.

---

### C-8 Edit person — `/pc/people/:personId/edit`

- **Source:** `features/people/presentation/edit/person_edit_page.dart`, `person_edit_contact_form.dart`, `sections/person_edit_pets_section.dart`
- **Purpose:** Update identity/contact details and linked-pet relationships.
- **Strengths (confirmed):** mapped contact-save errors; dirty-state confirmation; shared responsive form actions; distinct danger-zone section; linked-pet controls are separate from the identity form.
- **Attention flag:** Watch.

#### C-8.1 Roster and contact edit-load errors lack retry — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** Roster error is a text-only scaffold (`person_edit_page.dart:21-35`); the contact form's own detail error/null wrappers repeat that shape (`person_edit_contact_form.dart:162-176`). App bars already exist and may receive an automatic back button, so a universal missing-back claim is unsupported.
2. **Why it matters.** The absent retry on both primary loads violates `system.md` § 6.10; no edit should become available before its subject loads.
3. **UX impact.** Temporary failure blocks editing with no direct recovery.
4. **A11y impact.** No recovery action appears in the failed body.
5. **System impact.** Correct error handling must cover both provider levels, not just the route wrapper.
6. **Proposed fix.** Put `AsyncErrorState` inside each existing scaffold; give a confirmed missing person an explicit Contacts destination safe for direct links.
7. **Reusable rule.** X-1/X-11: every prerequisite failure has retry and every unavailable subject has a valid exit.
8. **Implementation notes.** In `person_edit_page.dart` refresh `rosterProvider`; in `person_edit_contact_form.dart` invalidate `personDetailProvider(widget.contactId)`; reuse `peopleListLoadError`, `peopleDetailNotFound`, `retry` and proposed `peopleBackToContacts` in both ARBs.
9. **Acceptance checklist.** Both failed requests can recover in-place; no editable fields/save appear before detail loads; missing records have a working Contacts action even on direct entry.

#### C-8.2 Long-form and emergency reorder accessibility (verify) — A11y · recommendation · Low

1. **Problem.** The form scrolls with sticky compact actions (`person_edit_contact_form.dart:116-145, 193-231`); emergency reorder uses arrow-only `IconButton`s without explicit tooltips (`person_edit_pets_section.dart:263-292`). The first-pass cited range mainly covered the pet menu, not those reorder buttons.
2. **Why it matters.** `system.md` § 2.3/§ 7.1 requires scalable content and named controls; actual target geometry/focus cannot be inferred from icon size.
3. **UX impact.** Long translated content and reorder controls need checking; no clipping or undersized target is claimed as reproduced.
4. **A11y impact.** Reorder actions should identify direction and person, and announce the resulting order; platform-inferred speech remains unverified.
5. **System impact.** The shared action bar already provides SafeArea and 48 dp minima; keep fixes there when applicable.
6. **Proposed fix.** Verify full-form traversal and 200% layout; add localized “Move {name} up/down” tooltips/semantic labels to reorder controls and announce confirmed order changes.
7. **Reusable rule.** X-8/X-9/X-7: long forms scale, and icon actions name their object and result.
8. **Implementation notes.** Update `sections/person_edit_pets_section.dart`, retaining reorder keys and `peopleCommandsProvider.reorderEmergencyContacts`; add `peopleEmergencyMoveUp`/`peopleEmergencyMoveDown` placeholders to both ARBs and reuse shared labelled busy/status treatment.
9. **Acceptance checklist.** At 200% EN/FR, all fields/danger actions remain reachable; reorder controls announce person/direction, are at least 48 dp, and preserve focus after a confirmed move.

---

### C-9 Households list — `/pc/people/households`

- **Source:** `features/people/presentation/households/households_page.dart`, `household_create_flow.dart`
- **Purpose:** Browse household groups and create a household.
- **Strengths (confirmed):** localized empty explanation and Create action; tier-labeled destination rows; pull-to-refresh in the loaded state; creation has a name step, pet review and localized save failure.
- **Attention flag:** Watch.

#### C-9.1 List failure has no retry — UX · requirement · Medium (was recommendation)

1. **Problem.** `peopleHouseholdsProvider` error renders only `peopleListLoadError` (`households_page.dart:19-24`); the refresh gesture is installed only in the data branch.
2. **Why it matters.** `system.md` § 6.10 requires retry for a recoverable primary load.
3. **UX impact.** A temporary outage prevents browsing and creating from this page until it is reopened.
4. **A11y impact.** The failed body has no focusable recovery.
5. **System impact.** Contacts already offers an explicit roster retry, so household recovery is inconsistent within People.
6. **Proposed fix.** Replace the text-only branch with the planned async error state and keep surrounding navigation.
7. **Reusable rule.** X-1: pull-to-refresh available only after success is not error recovery.
8. **Implementation notes.** In `households_page.dart`, invalidate `peopleHouseholdsProvider` on Retry; reuse `peopleListLoadError`, `retry`, and planned `AsyncErrorState` rather than introducing raw API copy.
9. **Acceptance checklist.** Initial failure shows Retry; a successful retry displays households; embedded/standalone modes keep their existing shell/back controls.

#### C-9.2 Household-create 720 dp height constraint (withdrawn) — A11y · recommendation · Low

1. **Problem.** The first pass attributed a 720 dp maximum height to `household_create_flow.dart`; no such constraint exists. The actual source uses `AlertDialog`, a `SizedBox(width: 420)` preference and a scrollable pet-review body (`64-102`); the 720 cap is in **add-person** (`add_person_flow.dart:175-181`).
2. **Why it matters.** A requested dialog width does not establish viewport overflow under Flutter constraints; this finding's specific premise was wrong.
3. **UX impact.** None.
4. **A11y impact.** None. Large-text dialog testing remains general QA, not evidence of this claimed defect.
5. **System impact.** None.
6. **Proposed fix.** No height-constraint removal is warranted; retain ordinary viewport/text-scale coverage for the dialog.
7. **Reusable rule.** X-8: verify actual constraints and parent behaviour before declaring fixed-size overflow.
8. **Implementation notes.** Keep `household_create_flow.dart`'s `AlertDialog` and `SingleChildScrollView`; test with existing `householdCreate`, `peopleHouseholdPetReviewTitle` and EN/FR values, not new sizing code for a nonexistent cap.
9. **Acceptance checklist.** Source review finds no 720 dp cap in this file; regression tests at short height/200% keep title, pet review and dialog actions reachable.

---

### C-10 Household detail — `/pc/people/households/:id`

- **Source:** `features/people/presentation/households/household_detail_page.dart`, `household_member_removal_dialog.dart`, `features/people/application/people_providers.dart`
- **Purpose:** Manage members, invitations, household name and pet inclusion.
- **Strengths (confirmed):** member removal obtains a server preview; removal dialog distinguishes household-only/all-access and requires a successor where necessary; rename/removal have tooltips; mutation errors use localized messages.
- **Attention flag:** Watch.

#### C-10.1 Missing pet data also misattributes household pets — UX · requirement · Medium (was recommendation)

1. **Problem.** `myPets` collapses unresolved/failed `petListProvider` to `[]` (`household_detail_page.dart:243-244`). Existing `household.pets` do **not** disappear: each becomes a read-only row labelled `peopleHouseholdPetOtherOwner` because none matches `myPets` (`339-353`), while inclusion checkboxes vanish.
2. **Why it matters.** This is stronger than an empty-looking section: “Owned by another household member” is an unsupported ownership claim, violating `system.md` § 6.10 and X-2.
3. **UX impact.** Users can think control/ownership changed when only their pet query failed.
4. **A11y impact.** The inaccurate ownership subtitle is also exposed to assistive technology.
5. **System impact.** Household membership data and personal-pet eligibility are separate; one failure must not rewrite the meaning of the other.
6. **Proposed fix.** Keep known household pet names, mark ownership/selection unavailable until personal pets resolve, and offer Retry; gate edits to those dependent controls.
7. **Reusable rule.** X-2: collection subtraction against unknown data cannot establish ownership or permission.
8. **Implementation notes.** Branch on `petsAsync` in `household_detail_page.dart`, reuse planned `SupplementalStateCaption`, invalidate `petListProvider`, and add `householdPetsUnavailable` to both ARBs; only use `peopleHouseholdPetOtherOwner` after a successful comparison.
9. **Acceptance checklist.** While personal pets load/fail, a known household pet is not labelled another member's solely because the lookup is unavailable; names remain visible, Retry works, and resolved data restores correct checkboxes/subtitles.

#### C-10.2 Rename closes before explaining invalid input — UX · recommendation · Low

1. **Problem.** Save pops with trimmed text, then silently returns if empty (`household_detail_page.dart:83-107`); the field has no max length or inline validator. Whitespace-only names are **not saved**, contrary to any implication otherwise in the first pass.
2. **Why it matters.** A blank submission closes the dialog without explaining why the name stayed unchanged; long-name correction relies on generic save failure.
3. **UX impact.** Small but avoidable correction friction.
4. **A11y impact.** No field-level error identifies what to fix.
5. **System impact.** Creation also trims its name, so validation rules should be shared with rename and the server contract.
6. **Proposed fix.** Validate trimmed non-empty input before closing and show inline feedback; apply the documented API length limit if one exists rather than inventing a number.
7. **Reusable rule.** X-5: validate before dismissing a committing dialog.
8. **Implementation notes.** Use a `Form`/`TextFormField` in `_rename` within `household_detail_page.dart`; retain `householdNameLabel`, add `householdNameRequired` in both ARBs, and coordinate any length rule with household creation.
9. **Acceptance checklist.** Blank/spaces keep the dialog open with localized feedback; valid trimmed input saves; a server-rejected name remains recoverable without losing the input.

#### C-10.3 Busy-state feedback (verify) — A11y · recommendation · Low

1. **Problem.** `_busy` absorbs pointers over the whole list (`household_detail_page.dart:367-379`) and disables mutation handlers, but supplies no visible progress or explicit live-region busy message. This is not proof that screen readers perceive a wholly “frozen” tree.
2. **Why it matters.** A slow access/pet mutation needs perceivable feedback so users know to wait rather than repeat it.
3. **UX impact.** The page can look unchanged while controls are blocked.
4. **A11y impact.** Busy announcements and actual focus behaviour need runtime verification; `AbsorbPointer` alone is not a comprehensive accessibility busy state.
5. **System impact.** Several distinct operations share one Boolean, making localized operation-specific status difficult.
6. **Proposed fix.** Name the pending operation, show labelled progress beside it, announce completion/error, and block only conflicting actions where safe.
7. **Reusable rule.** X-7/X-5: disabling input is not progress feedback or a result message.
8. **Implementation notes.** Replace/augment `_busy` in `household_detail_page.dart` with an operation state; reuse B-12.2's labelled progress/live-region wrapper and add `householdUpdating` to both ARBs, keeping existing `peopleSaveError`/`peopleRemoveError`.
9. **Acceptance checklist.** A delayed mutation shows and announces a localized pending state; duplicate commands are blocked; success/failure restores controls and useful focus; unrelated navigation remains operable.

#### C-10.4 Household detail failure has no recovery action — UX · requirement · Medium

1. **Problem.** The primary error branch renders only `peopleListLoadError`, and the null branch only `peopleDetailNotFound` (`household_detail_page.dart:31-39`); these run before the standalone body scaffold. `householdDetailProvider` also catches detail errors and may return a roster/list household instead (`people_providers.dart:111-123`), so not every failed detail request reaches the error branch.
2. **Why it matters.** The reachable primary-error state still violates `system.md` § 6.10; fallback data should not be described as a confirmed fresh detail response.
3. **UX impact.** If detail and fallback loading cannot resolve, users have no direct retry; outer People navigation remains available, so this is not an absolute navigation trap.
4. **A11y impact.** No recovery action or status heading in the failed pane.
5. **System impact.** Detail/fallback behaviour should preserve provenance and avoid silently treating stale roster data as fresh.
6. **Proposed fix.** Keep the route shell around all states, show error-with-retry, and treat resolved missing household separately with Back to households.
7. **Reusable rule.** X-1/X-2: primary recovery and fallback provenance must be explicit.
8. **Implementation notes.** Apply `routeShell` from `care_item_detail_screen.dart` and planned `AsyncErrorState` in `household_detail_page.dart`; invalidate `householdDetailProvider(householdId)` and relevant failed fallback providers, reuse `peopleListLoadError`/`retry`, and add `peopleBackToHouseholds` in both ARBs.
9. **Acceptance checklist.** With detail and fallbacks failing, a titled error pane offers Retry; recovery opens the household; confirmed missing shows Back to households; any retained fallback is identified as not freshly loaded.

---

### C-11 Legacy vet contact redirect — `/pc/vets/:id`, `/pc/vets/edit/:id`

- **Source:** `core/router/vet_routes.dart`, `features/people/presentation/screens/legacy_vet_contact_redirect_screen.dart`
- **Purpose:** Resolve legacy vet IDs into canonical People detail/edit routes.
- **Strengths (confirmed):** mapped IDs go to People rather than a duplicate vet UI; null mappings go to the professionals filter, which `RosterHubQuery.fromUri` still supports.
- **Attention flag:** Watch.

#### C-11.1 Failed mapping never leaves the loading UI — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** `_redirect` awaits `legacyVetContactIdProvider(...).future` without a catch (`legacy_vet_contact_redirect_screen.dart:31-43`); `build` watches the provider but always returns a spinner (`46-49`).
2. **Why it matters.** A failed primary lookup has neither an error state nor retry, violating `system.md` § 6.10; a thrown future cannot turn this unconditional UI into recovery.
3. **UX impact.** Legacy links remain on a loading page after failure; null is correctly handled and should not be conflated with failure.
4. **A11y impact.** No explicit error announcement or focusable recovery.
5. **System impact.** Both legacy detail and edit use this resolver.
6. **Proposed fix.** Catch lookup failure, show localized error plus Retry, and offer Contacts as a secondary exit; retain successful/null routing.
7. **Reusable rule.** X-1/X-11: redirect loaders need the same failure/exit contract as content screens.
8. **Implementation notes.** In `legacy_vet_contact_redirect_screen.dart`, invalidate `legacyVetContactIdProvider(widget.vetId)` before retrying `_redirect`; reuse planned `AsyncErrorState`/labelled progress, `peopleListLoadError`, `retry`, and proposed `peopleBackToContacts`.
9. **Acceptance checklist.** Failed lookup stops the spinner and shows Retry; recovery routes to the correct detail/edit screen; null opens `/pc/people?filter=professionals`; direct-link error has a working exit.

---

### C-12 Share pet — `/pet/:petId/share`, `/pc/pets/share`

- **Source:** `features/sharing/presentation/screens/share_pet_screen.dart`, `widgets/share_pet_owner_body.dart`, `owner_sharing_content.dart`, `follower_sharing_content.dart`, `share_pet_selector.dart`, `providers/share_pet_providers.dart`
- **Purpose:** Send invitations/create links and inspect or change pet access.
- **Strengths (confirmed):** shell/back paths preserved; owner/co-parent and shared-carer controls differ; pet choices use wrapping selected chips; invitation cancellation and ownership transfer have explicit confirmation.
- **Attention flag:** Watch.

#### C-12.1 Sharing loads offer no retry and access fails to empty — UX · requirement · Medium (was recommendation)

1. **Problem.** Primary pet failure prints `errorWithMessage` (`share_pet_screen.dart:75-80`); access failure shows a warning but passes `[]` for access/invites (`105-131`), as the notifier clears `accessByPet` on error (`share_pet_providers.dart:76-88`). Owner/foster link-load errors show text without retry (`share_pet_screen.dart:168-186`), and household overview loading/error is silently omitted (`owner_sharing_content.dart:36-45`).
2. **Why it matters.** `system.md` § 6.10 requires recoverable primary errors and prohibits unresolved content looking authoritatively empty; access management particularly needs to distinguish unknown from none.
3. **UX impact.** A warning exists for the access failure, so it is not wholly silent, but empty access rows and hidden household access can still mislead someone auditing permissions.
4. **A11y impact.** A colored text warning alone supplies no recovery target; empty rows do not communicate which access data is unavailable.
5. **System impact.** Pets, direct access, links and household overview have distinct loaders and should have independent states.
6. **Proposed fix.** Use primary error-with-retry for pets; keep usable sharing content with section-level unavailable/retry states for access, links and household overview; do not render an authoritative empty list until resolved.
7. **Reusable rule.** X-1/X-2: permission inventories are known-empty only after successful retrieval.
8. **Implementation notes.** Reuse planned `AsyncErrorState`/`SupplementalStateCaption`; retry pets by invalidating `allPetsIncludingOrgProvider` (the source watched by `sharePetListProvider`, `share_pet_providers.dart:155-162`), call the `sharePetNotifierProvider(_petIds)` notifier's `refresh()`, and invalidate `petShareLinksNotifierProvider(pet.id)`/`petAccessOverviewProvider(petId)` for their sections; reuse `couldNotLoadSharingInfo`/`retry` and add `shareAccessUnavailable` in both ARBs.
9. **Acceptance checklist.** Inject failure separately into all four queries: each identifies the unavailable section and retries the right source; no exception or false no-access claim appears; successful recovery restores actual access without recreating invites.

#### C-12.2 Mutation errors expose English and exception text — Copy · requirement · Medium (was recommendation · Low)

1. **Problem.** Link creation/hide failures print literal `Error: $e` (`owner_sharing_content.dart:119-124, 147-152`; `follower_sharing_content.dart:76-81, 110-115`). Invite send/cancel and transfer also expose stripped/raw exception text (`share_pet_owner_body.dart:66-71, 122-126`; `owner_sharing_content.dart:260-265`).
2. **Why it matters.** `system.md` § 6.10 forbids raw backend text, and `terminology.md` requires all user-visible strings in ARB; hard-coded English is requirement · Medium.
3. **UX impact.** Access-changing operations produce unpredictable technical guidance rather than explaining what can safely be retried.
4. **A11y impact.** Long exception strings are noisy when spoken and do not identify a useful next step.
5. **System impact.** Multiple callers independently strip `Exception: ` instead of sharing an error taxonomy.
6. **Proposed fix.** Map known permission/session/conflict failures to calm localized messages; retain context and expose a safe retry for the failed operation, without replaying successful operations.
7. **Reusable rule.** X-1/X-5/X-6: mutation feedback is localized, actionable and specific about the confirmed result.
8. **Implementation notes.** Centralize sharing-error mapping used by the three widget files; reuse existing operation labels, add `shareUpdateFailed`/`shareSessionExpired` in both ARBs, and use the People `personFormSaveErrorMessage` pattern as an implementation reference.
9. **Acceptance checklist.** Trigger each mutation failure in EN/FR: no exception class/status dump or literal English prefix appears, entered values remain, and retry never repeats a confirmed transfer/invite.

#### C-12.3 Wrapping pet-chip accessibility (verify) — A11y · recommendation · Low

1. **Problem.** `SharePetSelector` uses a `Wrap`, not a single non-wrapping row, and `FilterChip(selected: selected)` already carries standard selection state (`share_pet_selector.dart:28-40`). Actual focus, chip hit geometry and post-share focus remain untested.
2. **Why it matters.** `system.md` § 7.1 requires 48 dp targets; standard controls are a good start but theme/platform density and large text need rendered checking.
3. **UX impact.** No overflow is established; many long pet names should remain navigable.
4. **A11y impact.** Confirm selected state, keyboard operation and focus after actions rather than assuming the chips lack semantics.
5. **System impact.** Keep the common Material chip implementation if it meets the product minimum.
6. **Proposed fix.** Verify many pets/long names at 200%, keyboard selection and recovery focus; enlarge hit padding only if measured targets are under 48 dp.
7. **Reusable rule.** X-8/X-9: wrapping and standard selection semantics are preserved, while actual targets are measured.
8. **Implementation notes.** Test `share_pet_selector.dart` through `share_pet_screen.dart`, retaining `share_pet_chip_*` keys and `sharePetSelectPet` EN/FR text; keep user-entered names unchanged.
9. **Acceptance checklist.** Every chip can be selected by keyboard and screen reader, reports selection once, has at least a 48 dp hit region, wraps without clipping at 200%, and does not lose useful focus after sending.

Frozen-domain note: `share_pet_screen.dart:90-91, 166-175` still contains organisation/foster branches. These are not a model to extend for active Pet Care; frozen Shelter/Fostering removal belongs to **Part 5**. The access-state findings above apply to active owner/co-parent/shared-carer paths regardless of that cleanup.

---

### C-13 Shared pet preview — `/shared/:code`

- **Source:** `features/sharing/presentation/screens/shared_pet_screen.dart`, `widgets/shared_pet_accept_section.dart`, `core/router/app_router.dart`
- **Purpose:** Preview a shared pet and accept access into an authenticated account.
- **Strengths (confirmed):** public guard exemption; view-only badge and home tooltip; limited profile call omits weight/vet/bio; optional sharer identity; differentiated network/not-found loader state.
- **Attention flag:** FLAG.

#### C-13.1 Signed-out recipients have no continuation — UX · requirement · High

1. **Problem.** The screen passes auth state into `SharedPetAcceptSection` (`shared_pet_screen.dart:176-179`), which immediately returns `SizedBox.shrink()` when signed out (`shared_pet_accept_section.dart:24-25`). No sign-in/create-account alternative is rendered.
2. **Why it matters.** This blocks the document Summary's top-ranked recipient journey, justifying High; the route is public (`app_router.dart:117, 408-413`) but the intended next step disappears.
3. **UX impact.** A new sitter/relative can inspect the pet but cannot continue from the link into accepting care access.
4. **A11y impact.** No discoverable continuation exists in the semantic tree either.
5. **System impact.** The same widget causes C-14.1, and auth currently discards invite context.
6. **Proposed fix.** Apply the shared X-3 recipient block described above: sharer/scope plus one sign-in/create-account action returning to the same `/shared/:code`; require explicit acceptance after auth.
7. **Reusable rule.** X-3: public preview and account continuation form one complete recipient journey.
8. **Implementation notes.** Extend `shared_pet_accept_section.dart`, `shared_pet_screen.dart`, `landing_screen.dart`, `experience_resolve_screen.dart` and the router; reuse safe local-path parsing but allow only recipient destinations, add `inviteContinueWithAccount` and scope copy to both ARBs, and do not route to unregistered `/login`.
9. **Acceptance checklist.** Signed-out valid link shows identity/scope and one auth CTA; login/native login/signup return to the identical code, including onboarding if needed; cancellation grants nothing; explicit acceptance succeeds once; external return URLs are rejected.

#### C-13.2 Confirm preview identity and scope policy (verify) — Copy · recommendation · Low

1. **Problem.** `shared_pet_screen.dart:161-169` already limits the profile by passing no weight/vet and an empty bio; `213-228` shows sharer identity only if `owner.first_name` is non-empty. The code confirms a conditional identity block, not an accidental privacy leak.
2. **Why it matters.** A first-time recipient should assess trust before account creation, but whether this public field set is intentional requires the product/privacy contract, not widget inference.
3. **UX impact.** A preview lacking owner first name may show no sharer explanation; scope could be clearer alongside the continuation.
4. **A11y impact.** Identity/scope should be present as text and precede the decision, not depend on the profile photo.
5. **System impact.** The API's preview policy must remain authoritative; do not expand public payloads merely to fill a card.
6. **Proposed fix.** Confirm the allowed preview field set and provide an honest localized “Shared pet link” identity fallback when a name is not supplied; describe actual access, not a guessed role.
7. **Reusable rule.** X-3: establish invitation trust with minimal disclosed context; absence of identity never invites fabricated identity.
8. **Implementation notes.** Coordinate `shared_pet_screen.dart`/`shared_pet_owner_card.dart` with the preview contract; reuse `sharedBy` and add `sharedPetLinkIdentityUnavailable` in both ARBs inside the shared recipient block.
9. **Acceptance checklist.** Product confirms allowed public fields; named and missing-name previews both explain source/scope honestly; private health/contact data is not added to anonymous preview; text remains readable without images.

#### C-13.3 Age and missing name are hard-coded English — i18n · requirement · Medium (was recommendation · Low)

1. **Problem.** `shared_pet_screen.dart:104-120` uses literal `Unknown`, `1 month`, `$months months` and `yrs`, with a dot-formatted decimal year.
2. **Why it matters.** User-visible English outside ARB is requirement · Medium under `terminology.md`'s Localization rules and Part 4 X-6.
3. **UX impact.** French recipients see mixed-language identity/age data at first contact.
4. **A11y impact.** Abbreviated English years and unlocalized plurals are also spoken as supplied.
5. **System impact.** This preview builds an independent age formatter rather than using locale-aware messages.
6. **Proposed fix.** Use localized unknown-pet copy and plural age messages with locale-aware number formatting; preserve the calendar-date parsing already present.
7. **Reusable rule.** X-6: fallbacks, units, plurals and numeric formatting are localized, not just headings.
8. **Implementation notes.** Replace literals in `shared_pet_screen.dart`; reuse `unknownPet` if its meaning fits and add `sharedPetAgeMonths`/`sharedPetAgeYears` with typed placeholders to both ARBs, using locale number formatting rather than `toStringAsFixed` as display copy.
9. **Acceptance checklist.** Missing name and zero/one/many-month/year ages render correctly in EN/FR; decimal punctuation follows locale; no `month`/`yrs` literals remain in the display path.

#### C-13.4 Preview load and accept failures lack safe recovery copy — UX · requirement · Medium

1. **Problem.** Network failure maps to `sharedPetLoadFailed` but offers only Home, not Retry (`shared_pet_screen.dart:77-100`); accept failure prints literal `Error:` plus the exception (`195-202`).
2. **Why it matters.** Both violate `system.md` § 6.10; C-13.1 covers the missing auth journey, not these separate failure branches.
3. **UX impact.** A valid link cannot recover from a transient fetch without reopening, while acceptance errors provide technical rather than actionable guidance.
4. **A11y impact.** The preview error lacks a recovery target; raw accept errors create noisy spoken feedback.
5. **System impact.** This is the same public error-state pattern as the email invite.
6. **Proposed fix.** Add Retry only for transient fetch failures, keep expired/not-found guidance distinct, and map acceptance errors while retaining the preview and explicit decision.
7. **Reusable rule.** X-1/X-6: recipient errors preserve context, distinguish gone from unavailable, and never display exception strings.
8. **Implementation notes.** Update `_loadSharedPet` in `shared_pet_screen.dart` to reset `_loading`/`_errorKey` for retry and guard mounted state; reuse planned `AsyncErrorState`, `sharedPetLoadFailed`, `retry`, and add `shareAcceptFailed`/expired-link guidance to both ARBs.
9. **Acceptance checklist.** Network failure offers Retry and recovers the same code; expired links explain obtaining a fresh link; accept failure preserves preview and uses localized copy without an exception; retry does not grant access twice.

---

### C-14 Share email invite — `/invite/:code`

- **Source:** `features/sharing/presentation/screens/invite_landing_screen.dart`, `widgets/shared_pet_accept_section.dart`
- **Purpose:** Preview inviter, pets and access role; accept or decline an invitation.
- **Strengths (confirmed):** localized inviter/pet/role summary; explicit already-accepted state; busy action states; successful decisions use localized confirmation.
- **Attention flag:** FLAG.

#### C-14.1 Signed-out accept and decline disappear — UX · requirement · High

1. **Problem.** Accept delegates to the auth-hiding widget and decline is also conditional on `isLoggedIn` (`invite_landing_screen.dart:165-188`; `shared_pet_accept_section.dart:25`); neither is replaced with an auth CTA.
2. **Why it matters.** This is another instance of the Summary's top-ranked blocked recipient journey, not a secondary navigation preference.
3. **UX impact.** An emailed invitation explains the offer but gives a new recipient no way to act on it.
4. **A11y impact.** The action absence affects every input/assistive modality.
5. **System impact.** The fix should be shared with C-13.1, not another login implementation.
6. **Proposed fix.** Use the common X-3 auth continuation, preserving the current inviter/pet/role summary and returning to the same invite for an explicit decision.
7. **Reusable rule.** X-3: authentication is a continuation of an invitation, not a detour to Home.
8. **Implementation notes.** Integrate the shared block in `invite_landing_screen.dart`/`shared_pet_accept_section.dart`; carry validated `returnTo` through `landing_screen.dart` and resolver, reuse `shareInviteLandingHeadline`, `shareInviteLandingPets`, `shareInviteLandingRole`, and proposed `inviteContinueWithAccount` in both ARBs.
9. **Acceptance checklist.** Signed-out unaccepted invitation exposes one auth action; all successful auth paths return to its code and show Accept/Decline; accepted invites remain clearly accepted; no auth step automatically accepts.

#### C-14.2 Transient preview error has no retry — UX · requirement · Medium (was recommendation)

1. **Problem.** `_errorKey` distinguishes expired/not-found/load-failed, but every error branch offers only `goToPetCare` (`invite_landing_screen.dart:74-103`).
2. **Why it matters.** A recoverable primary fetch needs Retry under `system.md` § 6.10; not-found/expired are different states and need no pointless retry loop.
3. **UX impact.** A temporary network fault looks terminal unless the user reopens the email.
4. **A11y impact.** No direct recovery action exists for the failed request.
5. **System impact.** `_loadPreview` needs explicit reset logic before it can be safely reused as retry.
6. **Proposed fix.** Retry network failure; expired/not-found copy should explain requesting a fresh invitation, retaining a safe exit.
7. **Reusable rule.** X-1: distinguish recoverable unavailability from a gone link.
8. **Implementation notes.** Reset `_errorKey`/`_loading` and guard mounted state in `invite_landing_screen.dart`; use planned `AsyncErrorState`, `sharedPetLoadFailed`, `retry`, `shareInviteExpired`/`shareInviteNotFound`, adding fresh-invite guidance to both ARBs if needed.
9. **Acceptance checklist.** A failed preview retries the same code and recovers; expired/missing invites show accurate guidance, not endless Retry; signed-out exit remains safe and does not claim the invite was accepted.

#### C-14.3 Accept/decline expose raw exception text — Copy · requirement · Medium (was recommendation · Low)

1. **Problem.** Catch branches strip `Exception: ` and display the rest verbatim (`invite_landing_screen.dart:209-213, 234-238`).
2. **Why it matters.** Removing a prefix is not localization or error mapping; `system.md` § 6.10 explicitly forbids raw backend messages.
3. **UX impact.** The recipient cannot reliably distinguish session expiry, wrong account, gone invitation or a transient failure.
4. **A11y impact.** Technical snackbar content is difficult to interpret and disappears without persistent guidance.
5. **System impact.** The same mapper should serve shared-link and sharing-management mutations.
6. **Proposed fix.** Map known failures to localized actionable messages, keep the invite summary, and distinguish whether the server committed the decision before any later refresh failed.
7. **Reusable rule.** X-1/X-5/X-6: errors describe the failed stage without concealing a confirmed decision.
8. **Implementation notes.** Replace catches in `invite_landing_screen.dart` with the shared sharing-error mapper from C-12.2; reuse `shareInviteAccept`/`shareInviteDecline`, add `shareInviteDecisionFailed` and session/account guidance to both ARBs, and separate post-accept pet refresh from the mutation result.
9. **Acceptance checklist.** EN/FR failure cases show no exception text; wrong account/session expiry has a useful action; a successful accept followed by pet-refresh failure is not reported as a failed acceptance.

---

### C-15 Away-plan invite — `/absence-invite/:code`

- **Source:** `core/router/app_router.dart`, `features/pet_care/context/presentation/screens/absence_invite_landing_screen.dart`
- **Purpose:** Preview an away plan and accept temporary care access.
- **Strengths (confirmed):** the screen checks for an access token before mutation; preview contains inviter/trip context; trip label/date display uses `PlannedAbsenceDisplay`. Its attempted login return URL is not functional.
- **Attention flag:** FLAG.

#### C-15.1 Guard blocks signed-out recipients and attempted login is unrouted — UX · requirement · High

1. **Problem.** `app_router.dart:111-123` permits `/shared/`, `/invite/`, `/household-invite/` but not `/absence-invite/`, despite registering it at `424-430`. The screen's own fallback pushes `/login?redirect=…` (`absence_invite_landing_screen.dart:64-69`), which is not registered and is redirected to parameterless `/landing` when signed out.
2. **Why it matters.** This fully blocks the top-ranked recipient journey before preview; simply allow-listing the route will not repair the broken auth continuation.
3. **UX impact.** New invitees land on generic sign-in with no trip context and no automatic return to the invitation.
4. **A11y impact.** Context loss and inability to complete affect all users.
5. **System impact.** Existing shell `returnTo` is back-navigation plumbing, not a working login callback; login/native login/signup always go through the resolver.
6. **Proposed fix.** Add the route to one shared public-recipient allow-list and replace `/login?redirect` with the shared `/landing` continuation; preserve the invite through onboarding without auto-accept.
7. **Reusable rule.** X-3/X-11: every public invitation has a registered auth destination and validated post-auth return.
8. **Implementation notes.** Coordinate `app_router.dart`, `absence_invite_landing_screen.dart`, `landing_screen.dart` and `experience_resolve_screen.dart`; reuse `parseShellReturnTo` only with recipient-route allow-listing, and proposed `inviteContinueWithAccount` in both ARBs.
9. **Acceptance checklist.** Signed-out direct opening renders preview; all auth methods resume the same code, including new-account onboarding; external/invalid returns are rejected; acceptance still requires an authenticated explicit action.

#### C-15.2 Away invitation is partly untranslated and displays error codes — i18n · requirement · Medium

1. **Problem.** Literal `Absence invite`, `Invitation unavailable`, `Someone`, the inviter sentence and accept/busy labels appear at `absence_invite_landing_screen.dart:92-99, 116-140`. Errors actually show `_error` values `load_failed`/`accept_failed` (`55-59, 78-95`), not a polished generic message.
2. **Why it matters.** `terminology.md` requires all user-facing copy in ARB; `system.md` § 6.10 requires plain-language errors, not internal codes.
3. **UX impact.** French recipients see English and technical state identifiers at a high-trust entry point.
4. **A11y impact.** Error-code speech supplies no understandable next step.
5. **System impact.** Importing `AppLocalizations` does not localize the rest of the screen; only trip display currently uses it.
6. **Proposed fix.** Localize every visible/semantic string and map internal states to distinct plain-language messages; keep inviter/plan names as user data.
7. **Reusable rule.** X-6/X-1: localize fallback and busy/error states as carefully as the successful headline.
8. **Implementation notes.** In `absence_invite_landing_screen.dart`, add `absenceInviteTitle`, `absenceInviteHeadline`, `absenceInviteUnknownInviter`, `absenceInviteAccept`, `absenceInviteAccepting`, `absenceInviteLoadFailed`, `absenceInviteAcceptFailed` to both ARBs with typed placeholders; retain `PlannedAbsenceDisplay`.
9. **Acceptance checklist.** EN/FR covers preview/loading/error/accepting; no literal English or `load_failed`/`accept_failed` reaches the widget tree; translated title and action wrap without clipping.

#### C-15.3 Failure removes context and has no retry — UX · requirement · Medium (was recommendation)

1. **Problem.** Load failure sets `_error`, and accept failure also sets `_error`, causing both to replace the body with a text-only scaffold (`absence_invite_landing_screen.dart:55-60, 78-95`); the previously loaded trip is no longer shown.
2. **Why it matters.** This violates the primary-error/retry contract in `system.md` § 6.10 and erases useful decision context after a mutation fails.
3. **UX impact.** An authenticated invitee cannot retry acceptance or verify which trip failed without reopening the link.
4. **A11y impact.** No recovery action remains in the body.
5. **System impact.** Preview-load and decision errors need separate state, not a single screen-replacing string.
6. **Proposed fix.** Use error-with-retry for preview loading; keep the preview with a persistent localized inline decision error and an enabled retry action after acceptance failure.
7. **Reusable rule.** X-1/X-5: a failed mutation does not erase a successful preview.
8. **Implementation notes.** Split `_error` in `absence_invite_landing_screen.dart`, reset loading/error before `_loadPreview`, reuse planned `AsyncErrorState`, `retry` and the C-15.2 ARB keys; retain the shared recipient block from C-15.1.
9. **Acceptance checklist.** Preview failure can retry the same code; accept failure retains inviter/dates and offers safe retry; busy state prevents duplicates; no internal code is displayed.

---

### C-16 Household invite — `/household-invite/:code`

- **Source:** `features/people/presentation/households/household_invite_landing_screen.dart`, `features/people/data/households_api.dart`, `core/router/app_router.dart`; server confirmation: `server/routes/households/inviteRoutes.js`
- **Purpose:** Preview household membership and accept or decline.
- **Strengths (confirmed):** public guard exemption; localized household/inviter/tier summary; SafeArea already present; accept/decline are distinct and disabled while busy.
- **Attention flag:** FLAG.

#### C-16.1 Signed-out actions call authenticated endpoints — UX · requirement · High

1. **Problem.** Accept/decline unconditionally call People commands (`household_invite_landing_screen.dart:52-89, 125-134`) without checking auth or offering sign-in. The API omits Authorization without a token (`households_api.dart:17-20, 209-224`), and both server handlers explicitly return 401 without a user (`server/routes/households/inviteRoutes.js:25-27, 41-43`).
2. **Why it matters.** Unlike hidden actions on the other landings, these appear usable but cannot succeed signed out; this is the same top-ranked High recipient blocker.
3. **UX impact.** Recipients get generic save failure from a valid household invitation and no account continuation.
4. **A11y impact.** Enabled-looking actions give no warning that authentication is missing.
5. **System impact.** The server correctly enforces auth; the client continuation must change, not that enforcement.
6. **Proposed fix.** Show the shared auth-aware recipient block when signed out; return to the same code after login/signup, then offer explicit Accept/Decline.
7. **Reusable rule.** X-3: public preview never presents an authenticated mutation as available before auth.
8. **Implementation notes.** Watch `authProvider` in `household_invite_landing_screen.dart`, reuse existing household preview/tier copy and proposed `inviteContinueWithAccount` in both ARBs, and integrate the shared router/landing/resolver return contract.
9. **Acceptance checklist.** Signed-out buttons do not POST accept/decline; auth CTA resumes this invitation after every auth method; authenticated decisions work; server still rejects unauthorized direct API calls.

#### C-16.2 Short-view invitation layout (verify) — A11y · recommendation · Low

1. **Problem.** `SafeArea > Padding > Column` uses `Spacer` above actions with no scrolling (`household_invite_landing_screen.dart:107-139`); large text/short-height overflow is a credible risk, not a rendered observation.
2. **Why it matters.** `system.md` § 2.3/§ 7.1 requires 200% text and reachable core actions; SafeArea is already supplied and is not the missing piece.
3. **UX impact.** Long household/inviter names plus French tier copy may crowd or displace actions.
4. **A11y impact.** Potential text/action loss at enlarged type needs a runtime check.
5. **System impact.** The absence-invite body uses a similar non-scrollable Column/Spacer pattern and should share the recipient layout.
6. **Proposed fix.** Use a scrollable content region with content-sized safe-area actions, removing the need for a flex spacer in a constrained viewport.
7. **Reusable rule.** X-8: recipient context and actions remain reachable at short heights and large text.
8. **Implementation notes.** Apply the shared recipient layout to `household_invite_landing_screen.dart` and `absence_invite_landing_screen.dart`; reuse existing `peopleHouseholdInviteLandingTitle`/`peopleHouseholdInviteLandingBody` and action keys, with 48 dp buttons and no new literal copy.
9. **Acceptance checklist.** At 360 × 480 dp and 200% EN/FR with long names, all text and actions are reachable without overflow; actions stay clear of system insets and keyboard focus is visible.

#### C-16.3 Every preview failure is called “not found” — UX · requirement · Medium (was recommendation · Low)

1. **Problem.** `_load` catches every exception as `_notFound = true` (`household_invite_landing_screen.dart:35-49`), then shows only `shareInviteNotFound` (`98-100`) without retry.
2. **Why it matters.** A network/server failure is not proof of a missing invitation; this primary-load error violates `system.md` § 6.10.
3. **UX impact.** A legitimate link can look invalid, encouraging the inviter to send unnecessary replacements.
4. **A11y impact.** No recovery target or explanatory error heading exists.
5. **System impact.** The API currently throws a generic status-coded exception for all preview failures (`households_api.dart:190-195`); structured error classification is needed.
6. **Proposed fix.** Separate loading, failed, expired/not-found and ready states; Retry only recoverable failures, with a useful exit/fresh-invite explanation for gone links.
7. **Reusable rule.** X-1: unavailable is not not-found.
8. **Implementation notes.** Update `households_api.dart` to preserve structured status/error codes and `household_invite_landing_screen.dart` to classify them; reuse planned `AsyncErrorState`, `sharedPetLoadFailed`, `shareInviteNotFound`, `retry`, and add household-specific gone guidance to both ARBs.
9. **Acceptance checklist.** Timeout/500 shows load failure with working Retry; 404/expired uses accurate gone guidance; recovery returns the same code; no API exception text reaches the UI.

---

### C-17 Pet Care invite entry — `/pc/invite`

- **Source:** `core/router/experience_routes.dart`, `features/experience/presentation/screens/experience_settings_screen.dart` (`ExperienceInviteScreen`)
- **Purpose:** Provide an invitation entry point; currently an instructional page with Add pet.
- **Strengths (confirmed):** localized title/hint/action; hint explicitly mentions sharing from a pet profile; the active route passes `AppExperience.petCare`.
- **Attention flag:** None.

#### C-17.1 “Invite” primarily starts pet creation — UX · recommendation · Medium

1. **Problem.** `/pc/invite` builds `ExperienceInviteScreen` (`experience_routes.dart:136-140`); its heading is `invite`, its hint mentions adding or opening a pet, but its only active action is `addPet → /add` (`experience_settings_screen.dart:66-79`).
2. **Why it matters.** This is a functional informational route, not an invite composer or dead button; existing-pet users still receive a primary action unrelated to their immediate invitation task.
3. **UX impact.** Users can start unnecessary pet creation instead of sharing or adding a person.
4. **A11y impact.** None beyond task/label mismatch; the button itself names its actual destination.
5. **System impact.** This transitional route competes with the concrete People/share entry points.
6. **Proposed fix.** Make the primary destination Add a person or Choose a pet to share, leaving Add pet only as a contextual empty-account action; alternatively retire/redirect this route to a real invitation entry.
7. **Reusable rule.** X-11: a flow entry's main action advances the task promised by its title.
8. **Implementation notes.** Update `ExperienceInviteScreen` in `experience_settings_screen.dart` and `/pc/invite` routing; reuse `peopleAddPerson` and `sharePet`, with links to `/pc/people/new` or `/pc/pets`, and revise `experiencePetCareInviteHint` in both ARBs only if the route remains.
9. **Acceptance checklist.** An existing-pet user reaches a person/share task from the primary Invite action; a genuine no-pets state can still Add pet; no action silently selects the first pet or starts unrelated creation.

#### C-17.2 Share instructions lack a direct destination — UX · recommendation · Low

1. **Problem.** The hint tells users to open a pet profile but includes no link to pets or Contacts (`experience_settings_screen.dart:68-79`; `app_en.arb:2229`; `app_fr.arb:2108`).
2. **Why it matters.** Even if Add pet stays for empty accounts, existing users must reconstruct the instructed navigation manually.
3. **UX impact.** Extra navigation/discovery effort; the route is not itself sending invitations.
4. **A11y impact.** A concrete destination action would reduce traversal through the app shell.
5. **System impact.** This is a subordinate discoverability aspect of C-17.1, not a second independent composer to build.
6. **Proposed fix.** If the screen remains, provide a direct pet-selection/Contacts destination appropriate to its wording; do not duplicate C-17.1's primary action.
7. **Reusable rule.** X-11/X-9: instructions to navigate to an existing destination provide an accessible destination control.
8. **Implementation notes.** Reuse the planned `DestinationRow` (B-11.2) in `ExperienceInviteScreen` with existing localized pet/Contacts labels and `/pc/pets` or `/pc/people`; if C-17.1 redirects the route, close this finding with that same change.
9. **Acceptance checklist.** The retained page links directly to its instructed destination with a labelled 48 dp control, or the route redirects to that task; no duplicate primary invitation action remains.

Frozen-domain note: this file also contains an unrouted `ExperienceSettingsScreen` and an organisation branch in `ExperienceInviteScreen` (`experience_settings_screen.dart:9-38, 69-83`). The active `/pc/invite` route never selects that branch; remove it through **Part 5**, not by extending frozen organisation invitation UX.

---

**Patterns seen in this area** (feed Part 4):

- X-1: failed primary loads use localized error-with-retry and keep route context → planned `AsyncErrorState` plus `routeShell` → Away plan/edit, Person detail/edit, Households list/detail, legacy vet resolver, Share pet and recipient landings.
- X-2: unknown dependent data cannot assert empty, missing selection, ownership or no access → planned `SupplementalStateCaption` and explicit async section state → Away hub names, New away plan pets, Household pets, sharing access/links/overview.
- X-3: explain inviter/scope and provide one auth continuation returning to the same invite → shared recipient block, centralized public-prefix allow-list and validated auth `returnTo` → all four recipient routes.
- X-5: report committed stages and retry only what failed → persistent partial-success/result state → Add person then household invite; invitation acceptance followed by pet refresh; sharing mutations.
- X-6: fallback/plural/error/busy strings belong in both ARBs → shared localized error mapper and age messages → Shared pet, Share pet, email invite and away invite.
- X-7: task-specific progress and perceivable status/step transitions → planned labelled progress/live-region wrapper → Away hub/plan, add-person steps, household busy states and mutation feedback.
- X-8/X-9: text and controls adapt to the viewport, retain standard semantics and provide named 48 dp actions → shared form actions, recipient layout, `DestinationRow` and existing Material tabs/chips → away forms, add/edit person, household invite, share selector and Invite entry.
- X-11: direct links and form exits have meaningful destinations → existing safe shell return helpers plus explicit no-stack fallbacks → New away plan, add/edit person, legacy resolver, Invite entry.
- X-4: frozen branches are removed rather than used as design inputs → **Part 5** cleanup → Share pet foster/organisation branches, `ExperienceInviteScreen` organisation branch and unrouted settings/away placeholder surfaces.

**Changes from the first pass (Area C).**

- **Grade changes:** C-1.1 recommendation · Low → requirement · Medium (card fallback actually instructs selection for saved plans); C-3.1 and C-4.1 recommendation · Medium → requirement · Medium (§ 6.10 primary error/retry); C-5.1 recommendation · Low → preference · Low (the existing unselected-pane instruction and Add action are valid).
- **Grade changes continued:** C-7.1 and C-8.1 recommendation · Low → requirement · Medium (primary load retry missing at both provider levels); C-9.1 recommendation · Medium → requirement · Medium (retry exists only after successful load); C-10.1 recommendation · Medium → requirement · Medium (failed pet lookup makes an ownership claim); C-11.1 recommendation · Low → requirement · Medium (failed primary redirect lookup never leaves its spinner).
- **Grade changes continued:** C-12.1 recommendation · Medium → requirement · Medium (raw primary error/no retry plus unresolved access inventory); C-12.2 recommendation · Low → requirement · Medium (raw exception messages and literal English); C-13.3 recommendation · Low → requirement · Medium (hard-coded visible age/name text); C-14.2 recommendation · Medium → requirement · Medium (primary fetch failure without retry); C-14.3 recommendation · Low → requirement · Medium (raw decision exceptions); C-15.3 recommendation · Medium → requirement · Medium (primary error without retry and mutation context loss); C-16.3 recommendation · Low → requirement · Medium (all preview failures called missing, with no retry).
- **Withdrawn:** C-9.2 remains recommendation · Low only as an audit record: the household-create file has no 720 dp height cap, and `AlertDialog`/scrolling means the requested 420 dp width alone does not establish overflow. No finding ID was deleted.
- **Marked (verify):** C-2.3, C-4.2, C-5.2, C-5.3, C-6.2, C-6.3, C-7.2, C-8.2, C-10.3, C-12.3 and C-16.2 require rendered text-scale, focus, target or announcement checks; C-13.2 requires confirmation of the intended public preview/identity contract. These remain recommendation · Low, not proven accessibility/privacy failures.
- **Corrected without changing grade:** C-6.1's invite exception is caught by `_save`; the real failure is misreported partial success and retrying creation, not a silent uncaught exception. C-10.2 trims/rejects whitespace-only names but dismisses without inline feedback. C-12.3 uses wrapping `FilterChip`s with selected state, not a single row. C-13.2 already omits health/vet/bio content and sometimes identifies the sharer; no leak is established.
- **Other verification corrections:** C-7.1/C-8.1 do not establish loss of all back navigation because outer shells/app bars exist; C-4.2's small spinner is not the tap target, and shared form actions already supply SafeArea/48 dp minima. C-15.1's attempted `/login?redirect` is unrouted and never consumed by auth, so allow-listing alone is insufficient; C-15.3 displays internal codes, not a calm generic error. C-17 is a real instructional route that only opens Add pet, not an invite sender; its frozen organisation branch is inactive on `/pc/invite`.
- **New, code-confirmed findings:** C-10.4 (household primary detail error lacks recovery, with fallback nuance) and C-13.4 (shared preview load lacks Retry and acceptance prints an exception), both requirement · Medium. No other new findings added.
- **Attention changes:** C-1, C-4, C-7, C-8, C-9, C-11 and C-12 move from None to Watch for confirmed state-contract requirements; C-16 moves from Watch to FLAG because its existing High finding is server-confirmed. C-13/C-14/C-15 remain FLAG.
- **Area totals (including the withdrawn audit record):** 44 findings: requirement · High 4; requirement · Medium 20; recommendation · Medium 1; recommendation · Low 18; preference · Low 1; all other level/severity combinations 0. Excluding withdrawn C-9.2 leaves 43 actionable/verification findings and 17 recommendation · Low findings.

---

## Area D — Account, notifications, subscription, help and legal (detailed)

This area was re-reviewed against the source file by file, including the first-pass evidence, child widgets, router allow-list, token aliases and EN/FR ARB values. Grades follow [`system.md`](../system.md) § 6.10 (truthful loading/empty states, plain-language errors and meaningful retry), § 7.1 (48 dp targets, reduced motion and scaling), § 2.3 (200% text), [`terminology.md`](../terminology.md) and [`copy-tone.md`](../copy-tone.md). This is analysis only: no application code was changed and no runtime accessibility, store checkout or signed-in UI was tested. Source paths below are relative to `flutter_app/lib/` unless explicitly prefixed otherwise.

**Area summary.** Account is a useful, constrained utility hub; notification preferences have explicit saving and honest push deferral; legal documents use localized titles, selectable text and readable widths. The material failures are an inert subscription-management button, native export reporting success without producing a file, notification preferences being inaccessible from the shell panel, and primary-load failures without safe recovery. Frozen content needs removal, not a redesign of Shelter/Fostering (see Part 5). Several first-pass assertions were overstated: popup menus have a framework tooltip, identity descendants are not excluded from semantics, the account accent alias is already Pet Care plum, deletion already explains irreversibility, and About does not render `aboutIntro`. **Router evidence also corrects a working assumption of the first pass:** `/help` is auth-gated, but `/about` is explicitly included in `LegalDocumentId.publicRoutes` (`core/legal/legal_document_id.dart:43-52`) and that list is allowed by `app_router.dart:121`; About is therefore public in this source snapshot.

**Shared fix that covers most of Area D.** Apply the planned `AsyncErrorState` (B-2.1) and labelled progress (B-12.2) to utility loads; use the `routeShell` pattern where a Pet Care screen needs stable chrome. One confirm-and-act pattern (X-5), one active-product EN/FR content pass (X-4/X-6), and explicit notification-panel destinations cover most remaining repetition. `SupplementalStateCaption` is appropriate for dependent pet data, not a substitute for primary-load errors.

There are 43 retained entries across 13 screens: requirement × High 4 / Medium 17 / Low 0; recommendation × High 0 / Medium 3 / Low 18; preference × High 0 / Medium 0 / Low 1. Five recommendation · Low entries are withdrawn, leaving 38 non-withdrawn entries (including five explicitly marked verification items).

---

### D-1 Account — `/account`

- **Source:** `features/experience/presentation/screens/account_screen.dart`, `widgets/account_organisation_settings_section.dart`, `core/theme/app_color_tokens.dart`
- **Purpose:** Authenticated entry to identity, preferences, support, legal and sign-out.
- **Strengths (confirmed):** 760 dp maximum width, scrollable content, localized rows with 52 dp minimum height, explicit destructive sign-out styling, and direct My details/Help/About/Legal routes.
- **Attention flag:** Watch.

#### D-1.1 Frozen organisation placeholder remains in Preferences — UX · recommendation · Medium

1. **Problem.** Preferences always renders `accountOrgSettingsTitle` and `AccountOrganisationSettingsSection` (`account_screen.dart:57-71`); that child only returns `accountOrgSettingsEmpty` (`account_organisation_settings_section.dart:5-16`), whose value says the user is not a member (`app_en.arb:2372-2373`).
2. **Why it matters.** It suggests an unavailable configuration area and presents a membership statement without a membership lookup; `terminology.md:12-14` keeps frozen vocabulary outside active Pet Care direction.
3. **UX impact.** A non-actionable block competes with working pet-tag and People links.
4. **A11y impact.** Extra static content lengthens traversal, but no inaccessible control is established.
5. **System impact.** This is frozen-domain residue covered by X-4 and the Part 5 deletion decision.
6. **Proposed fix.** Remove the organisation heading and placeholder from Account; retain pet tags and People without inventing a replacement preference.
7. **Reusable rule.** X-4: active utility hubs show only active product destinations, not frozen placeholders.
8. **Implementation notes.** Remove the import and embedded child in `account_screen.dart`, then remove `account_organisation_settings_section.dart` through Part 5; retire `accountOrgSettingsTitle`/`accountOrgSettingsEmpty` from both ARBs only after checking other references.
9. **Acceptance checklist.** Account contains no organisation heading or membership assertion in EN or FR; pet tags and People still open their registered destinations.

#### D-1.2 Identity card announcement needs checking (verify) — A11y · recommendation · Low (was requirement · Medium)

1. **Problem.** The outer `Semantics(button: true, label: title)` labels the card “Account” (`account_screen.dart:173-176`), but visible name/email remain descendants (`207-223`) and there is no `ExcludeSemantics`; source does not prove the first-pass claim that identity is lost.
2. **Why it matters.** Framework semantics can combine descendant labels; only the resulting semantics tree and spoken output can establish repetition or missing identity.
3. **UX impact.** None confirmed for sighted users.
4. **A11y impact.** Possible redundant “Account”, initials and identity announcement rather than a concise identity-and-destination label.
5. **System impact.** Account rows also supply explicit parent labels, so a verified solution should be shared rather than copied inconsistently.
6. **Proposed fix.** Inspect the semantics tree first; if noisy, expose one localized “{identity}, open My details” label and deliberately exclude duplicate decorative text.
7. **Reusable rule.** X-9: an interactive summary announces its content and destination once; absence of an explicit composite label alone is not a proven failure.
8. **Implementation notes.** Test `_AccountIdentityLeadIn` in `account_screen.dart`; reuse `_AccountRow`/planned `DestinationRow` conventions and add `accountIdentityOpenDetails` to both ARBs only if a composed label is needed.
9. **Acceptance checklist.** A semantics test and VoiceOver/TalkBack check expose name or email and the My details action exactly once, with no decorative initials duplication.

#### D-1.3 Account accent is already the Pet Care token (withdrawn) — Design · recommendation · Low

1. **Problem.** Account uses `operationsGold` (`account_screen.dart:49,59,89`), but the alias equals `petCarePrimary` (`app_color_tokens.dart:75-82`), which is the `landingPlum` primary token (`app_color_tokens.dart:26`, `tokens.md`); the asserted one-off legacy gold colour is not present.
2. **Why it matters.** [`tokens.md`](../tokens.md):132-140 confirms this is the approved Pet Care primary, so a visual restyle is not justified.
3. **UX impact.** None.
4. **A11y impact.** None.
5. **System impact.** Only legacy naming debt remains.
6. **Proposed fix.** No visual change; optionally replace the alias with the canonical token when Account is next touched.
7. **Reusable rule.** X-10: resolve a token alias before reporting a palette breach.
8. **Implementation notes.** In `account_screen.dart`, a mechanical `operationsGold` → `petCarePrimary` substitution is sufficient; keep `DashboardSection`, with no ARB or provider change.
9. **Acceptance checklist.** If renamed, before/after colours are identical and existing Account goldens have no visual difference.

#### D-1.4 Contact launch failure is silent — UX · recommendation · Low

1. **Problem.** `_launchContact` only launches when `canLaunchUrl` is true and ignores the launch result (`account_screen.dart:140-143`); no fallback is presented.
2. **Why it matters.** Browsers and devices without a mail handler can leave a support request with no apparent response.
3. **UX impact.** The user must search elsewhere for the contact address.
4. **A11y impact.** There is no failure status to announce.
5. **System impact.** Legal external links have the same silent-result pattern (D-11.2).
6. **Proposed fix.** Handle false results and exceptions with a localized notice containing the actual contact email and a Copy email action.
7. **Reusable rule.** X-11: a destination action either opens its destination or offers a visible fallback.
8. **Implementation notes.** Pass context into `_launchContact` in `account_screen.dart`, keep `DrawerMenuConfig.contactEmail` as the address source, and add `contactLaunchFailed`/`copyEmail` in both ARBs using a selectable fallback dialog.
9. **Acceptance checklist.** With no mail handler and with a thrown launch exception, the address remains readable/copyable and the localized failure is announced.

---

### D-2 Manage pet tags — `/account/pet-tags`

- **Source:** `features/pet_tags/presentation/screens/manage_pet_tags_screen.dart`, `providers/pet_tag_providers.dart`
- **Purpose:** Create, rename and delete reusable pet tags.
- **Strengths (confirmed):** stable experience shell, separate loading/error/data branches, localized empty copy and create action, and cancel-first deletion confirmation.
- **Attention flag:** Watch.

#### D-2.1 Overflow is not an unlabelled icon (withdrawn) — A11y · recommendation · Low (was requirement · Medium)

1. **Problem.** `PopupMenuButton<String>` has no custom tooltip (`manage_pet_tags_screen.dart:65-88`), but this Material control supplies the localized framework “Show menu” tooltip when omitted; absence of a custom string does not establish an unlabelled icon.
2. **Why it matters.** Native control defaults must be considered before alleging an accessibility breach.
3. **UX impact.** A tag-specific action label could improve clarity, but basic menu discoverability exists.
4. **A11y impact.** No missing-name failure is confirmed; actual target size still warrants the normal § 7.1 regression check.
5. **System impact.** A bespoke overflow component is not required solely to add the default tooltip back.
6. **Proposed fix.** Keep the native popup; optionally use a localized “Actions for {tag}” tooltip for context.
7. **Reusable rule.** X-9: verify framework semantics before replacing accessible native controls.
8. **Implementation notes.** In `manage_pet_tags_screen.dart`, reuse `PopupMenuButton`; if specificity is desired, add `petTagActions(name)` to both ARBs without changing rename/delete handlers.
9. **Acceptance checklist.** The menu has a non-empty localized name, opens by keyboard and assistive technology, and measures at least 48 × 48 dp in the supported theme.

#### D-2.2 Delete failures escape without feedback — UX · requirement · Medium (was recommendation)

1. **Problem.** `_deleteTag` awaits `deleteTag(tag.id)` without a catch (`manage_pet_tags_screen.dart:145-169`); the notifier awaits the repository directly before refresh (`pet_tag_providers.dart:59-62`), so it does not absorb a failed mutation.
2. **Why it matters.** A destructive action needs a perceivable outcome and safe recovery under `system.md` § 6.9-6.10, not an unhandled asynchronous error.
3. **UX impact.** The confirmation closes but a failed request produces no local explanation or retry.
4. **A11y impact.** No failure status is available for announcement.
5. **System impact.** Create/rename catch errors already, although their raw-message copy also needs the X-1 treatment.
6. **Proposed fix.** Catch deletion failure, preserve the row and show safe localized feedback with a retry that retains the tag identity.
7. **Reusable rule.** X-5: confirmation is followed by busy, success or recoverable failure, never silence.
8. **Implementation notes.** Use a shared confirm-and-act dialog around `_deleteTag` in `manage_pet_tags_screen.dart`, call `petTagListProvider.notifier.deleteTag`, and add `petTagDeleteFailed`; do not interpolate the exception through `errorWithMessage`.
9. **Acceptance checklist.** A rejected/offline delete keeps the tag and shows localized feedback; retry after recovery deletes it once, and repeated taps cannot send duplicate mutations.

#### D-2.3 Blank tag names close the dialog without validation — UX · recommendation · Low

1. **Problem.** Submit and Save pop the raw field value (`manage_pet_tags_screen.dart:183-196`), after which create/rename silently return for blank input (`110-114,125-134`).
2. **Why it matters.** The user cannot tell whether Save was accepted or why nothing changed.
3. **UX impact.** The dialog and typed context disappear instead of explaining the correction.
4. **A11y impact.** There is no field error or focus cue.
5. **System impact.** One shared prompt serves both mutations; duplicate and length constraints were not verified and must not be invented.
6. **Proposed fix.** Validate a trimmed non-empty name in the dialog and keep it open on invalid submission; surface any documented server constraint safely.
7. **Reusable rule.** X-5: invalid forms stay open with errors next to their fields.
8. **Implementation notes.** Convert `_promptForName` in `manage_pet_tags_screen.dart` to a `Form`/`TextFormField`, reuse `petTagsNameHint`, add `petTagNameRequired` in both ARBs, and dispose the controller after the dialog completes.
9. **Acceptance checklist.** Save and keyboard submit with whitespace keep the dialog open and expose the field error; a valid trimmed name returns once for create and rename.

#### D-2.4 Usage chip needs an explicit noun — A11y · recommendation · Low (was requirement)

1. **Problem.** A chip displays only `tag.petIds.length` next to the tag title (`manage_pet_tags_screen.dart:51-63`), without saying that the number counts pets.
2. **Why it matters.** The number is readable but its meaning is implicit; code does not establish an inaccessible action or missing value.
3. **UX impact.** Users may read it as a notification count or an arbitrary tag count.
4. **A11y impact.** A scan can announce a bare number with no unit.
5. **System impact.** A localized plural can provide one count format wherever tag usage appears.
6. **Proposed fix.** Label it “Used by {count} pets” semantically, or show the noun visibly when space permits.
7. **Reusable rule.** X-6/X-9: count metadata names its subject; readability ambiguity alone is not a demonstrated requirement breach.
8. **Implementation notes.** Wrap the chip in one non-duplicated `Semantics` label in `manage_pet_tags_screen.dart` and add plural `petTagUsageCount(count)` to both ARBs.
9. **Acceptance checklist.** Counts 1 and 2 announce the correct localized pet noun and number once; long tag names still fit at 200%.

#### D-2.5 Primary tag-load error prints the exception with no retry — UX · requirement · Medium

1. **Problem.** The primary list error is only `Text(l.errorWithMessage('$error'))` (`manage_pet_tags_screen.dart:22-24`); unlike the data branch, it offers no action.
2. **Why it matters.** `system.md` § 6.10 explicitly forbids raw backend messages and requires a meaningful retry.
3. **UX impact.** A transient failure prevents tag management until the screen/provider is reloaded elsewhere.
4. **A11y impact.** Technical text replaces a comprehensible state and focusable recovery control.
5. **System impact.** This is the same X-1 defect as notification settings and subscription loading.
6. **Proposed fix.** Render the planned shared error state inside the existing shell, with “We couldn't load your tags” and Retry.
7. **Reusable rule.** X-1: primary-load errors use safe localized copy and explicit recovery.
8. **Implementation notes.** Apply `AsyncErrorState` from B-2.1 in `manage_pet_tags_screen.dart`, add `petTagsLoadError` in both ARBs, and call `ref.read(petTagListProvider.notifier).refresh()`; use B-12.2 labelled progress for loading.
9. **Acceptance checklist.** A failing tag request shows no exception and offers Retry; recovery renders tags without leaving the screen, while shell title and navigation remain present.

---

### D-3 Experience settings redirect — `/pc/settings`

- **Source:** `core/router/experience_routes.dart`, `features/experience/presentation/screens/experience_settings_screen.dart`
- **Purpose:** Compatibility alias to Account; no settings screen is rendered at this route.
- **Strengths (confirmed):** explicit redirect to `/account` preserves legacy settings links.
- **Attention flag:** None.

#### D-3.1 Unrouted settings class remains beside a routed invite class — UX · recommendation · Low

1. **Problem.** `/pc/settings` redirects to Account (`experience_routes.dart:142-146`), while `ExperienceSettingsScreen` still implements a one-row settings surface (`experience_settings_screen.dart:9-38`).
2. **Why it matters.** A dead alternative can mislead maintainers into changing a screen users never reach.
3. **UX impact.** None in the current route.
4. **A11y impact.** None.
5. **System impact.** The same file also defines `ExperienceInviteScreen` (`40-90`), which remains referenced by `/pc/invite` (`experience_routes.dart:136-140`); deleting the whole file would break an active builder.
6. **Proposed fix.** Remove only the unrouted settings class after a reference check and retain the compatibility redirect.
7. **Reusable rule.** X-4/X-11: remove dead screens without removing a live neighbour or compatibility route.
8. **Implementation notes.** Edit `experience_settings_screen.dart` and, if needed, its import naming in `experience_routes.dart`; keep `ExperienceInviteScreen` and its localized invite strings until its separate scope review.
9. **Acceptance checklist.** Old `/pc/settings` links reach Account; no constructor reference to the deleted settings class remains; `/pc/invite` still resolves.

---

