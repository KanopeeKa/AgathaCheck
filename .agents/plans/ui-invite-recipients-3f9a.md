# Invite recipients can sign in and come back to the invite

## Goal
A person who opens any of the four invitation links while signed out (`/shared/:code`, `/invite/:code`,
`/absence-invite/:code`, `/household-invite/:code`) sees who invited them and what they would get, has one
"Sign in or create an account" action, returns to the same invite after login, native login, signup and
first-pet onboarding, and must still accept or decline explicitly; nothing is ever accepted automatically.
Source findings: X-3, C-13.1, C-13.3, C-13.4, C-14.1, C-14.2, C-14.3, C-15.1, C-15.2, C-15.3, C-16.1, C-16.2,
C-16.3 and A-3.3 in `docs/design/plans/ui-ux-review-2026-11.md` (read the nine-part spec of each before coding);
split rationale in `docs/design/plans/ui-ux-review-2026-11-execute-plan-split.md`.
Return-to-invite rule (owner decision, part of this approval): the return target travels as one `returnTo`
query parameter on `/landing`; it is accepted only when it is a same-origin relative path (no scheme, no host,
no `//`, no backslash) that starts with exactly one of the four prefixes `/shared/`, `/invite/`,
`/absence-invite/`, `/household-invite/` followed by a code, at most 200 characters; anything else is ignored and
the normal post-login destination applies. The four prefixes live in one constant used by both the router's
signed-out allow-list and this validator. Public preview data stays exactly what the API returns today: no new
fields are added to anonymous previews (C-13.2 is limited to honest fallback copy when a name is missing).
Prerequisite: the shared widgets `AsyncErrorState` and `LabelledProgress` from
`flutter_app/lib/core/widgets/async_state/` (phase 0 PR) are on `main` before approval; use them for the
retryable preview errors.
Canonical docs: `docs/domains/sharing/features/specs.md`, `docs/domains/people/features/people-care-team.md`,
`docs/domains/pet_care/features/away-planning-carer-model.md`, `docs/domains/auth/features/specs.md`.

## Phases

### Phase 1 — Return-to-invite and recipient block
```json
{ "allowed_paths": [
    "flutter_app/lib/core/router/app_router.dart",
    "flutter_app/lib/core/router/invite_return.dart",
    "flutter_app/lib/core/widgets/invite_recipient_block.dart",
    "flutter_app/lib/features/auth/presentation/screens/landing_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart",
    "flutter_app/lib/features/experience/presentation/screens/pet_care_onboarding_screen.dart"
  ],
  "approved_sensitive_paths": [
    "flutter_app/lib/features/auth/presentation/screens/landing_screen.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "invite_return validator unit tests cover every accepted prefix and reject absolute, protocol-relative, backslash, unknown-prefix and over-long targets",
    "widget tests: login, native login, signup and new-account onboarding each end on the stored invite route",
    "/absence-invite/ is in the one shared signed-out allow-list constant",
    "resolver pet-load error shows AsyncErrorState with Retry instead of silently going to /pc/home (A-3.3)",
    "pre-push-changed green"
  ] }
```
Scope: add `invite_return.dart` (prefix constant, `returnTo` validator, read/consume helpers); use the prefix
constant in the router's signed-out allow-list and add `/absence-invite/`; carry a valid `returnTo` from `/landing`
through all three successful auth paths and through first-pet onboarding, consuming it once on arrival; build
`InviteRecipientBlock` (inviter, pets or household, access scope, one localized sign-in/create-account action that
goes to `/landing?returnTo=<encoded current path>`); resolver error state with Retry (A-3.3). EN and FR strings.
Out of scope: the four landing screens themselves (phases 2–4), the password-manager bridge, any change to the
landing forms other than passing `returnTo`, any API change.

### Phase 2 — Share link and email invite
```json
{ "allowed_paths": [
    "flutter_app/lib/features/sharing/presentation/screens/shared_pet_screen.dart",
    "flutter_app/lib/features/sharing/presentation/screens/invite_landing_screen.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/shared_pet_accept_section.dart",
    "flutter_app/lib/features/sharing/presentation/widgets/shared_pet_owner_card.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "signed-out /shared/:code and /invite/:code show InviteRecipientBlock and no accept/decline buttons",
    "signed-in recipients still see explicit Accept and Decline",
    "preview network failure offers Retry; expired and not-found keep their own copy (C-13.4, C-14.2)",
    "no exception text or literal English in accept/decline errors; ages and missing names localized (C-13.3, C-14.3)",
    "pre-push-changed green"
  ] }
```
Scope: C-13.1, C-13.3, C-13.4, C-14.1, C-14.2, C-14.3, and C-13.2 limited to a localized identity fallback.
Out of scope: share-management screens (`share_pet_screen.dart` and its widgets belong to another plan), API changes.

### Phase 3 — Away-plan invite
```json
{ "allowed_paths": [
    "flutter_app/lib/features/pet_care/context/presentation/screens/absence_invite_landing_screen.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "signed-out direct open renders the preview with InviteRecipientBlock; no /login?redirect remains",
    "every visible and semantic string comes from ARB in EN and FR; internal codes never shown (C-15.2)",
    "preview failure retries the same code; accept failure keeps the trip context and offers retry (C-15.3)",
    "pre-push-changed green"
  ] }
```
Scope: C-15.1 (screen side), C-15.2, C-15.3, and the scrollable recipient layout from C-16.2 for this screen.
Out of scope: away-plan hub, flow and edit screens.

### Phase 4 — Household invite
```json
{ "allowed_paths": [
    "flutter_app/lib/features/people/presentation/households/household_invite_landing_screen.dart",
    "flutter_app/lib/features/people/data/households_api.dart"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": ["flutter_app/lib/l10n/app_localizations*.dart"],
  "exit_checklist": [
    "signed-out recipients see InviteRecipientBlock and the screen never POSTs accept or decline without a session",
    "timeout and 500 show a retryable load error; 404 and expired keep not-found guidance (C-16.3)",
    "layout scrolls at 360x480 and 200% text without overflow (C-16.2)",
    "pre-push-changed green"
  ] }
```
Scope: C-16.1, C-16.2, C-16.3; `households_api.dart` keeps the existing request shapes and only exposes a structured
status/error code for the preview call.
Out of scope: household list and detail screens, server routes.

### Phase 5 — Journey coverage and docs
```json
{ "allowed_paths": [
    "e2e/playwright/tests/invite.recipient.spec.ts",
    "e2e/playwright/pages/**",
    "flutter_app/test/bdd/features/invite_recipient_return.feature"
  ],
  "forbidden_paths": [], "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "Playwright spec covers all four routes: signed-out open, sign in or create account, return to the same code, explicit decision",
    "Gherkin feature maps those scenarios with @bdd tags and the BDD coverage gate passes",
    "canonical docs listed in the Goal record the return-to-invite rule as Live requirements",
    "pre-push-changed green"
  ] }
```
Scope: end-to-end journey tests and canonical-doc sync for the whole plan.
Out of scope: product code.

## Proof on UAT
In a private window on https://uat.agathatrack.com, open one link of each kind (share link, email share invite,
away-plan invite, household invite) created by a test account; each shows who invited and what access is offered,
"Sign in or create an account" leads to `/landing`, and after creating a new account (including first-pet
onboarding) the browser returns to the same invite with Accept and Decline visible; nothing is accepted until
Accept is pressed.
