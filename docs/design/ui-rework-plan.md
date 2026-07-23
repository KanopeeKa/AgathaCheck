# UI rework — phased execution plan

**Status:** Complete (phases 0–7 merged 2026-07-23)  
**Companion:** `docs/design/index.md` (tiers), `docs/design/principles.md` (personality), `docs/design/tokens.md` (created in Phase 0)  
**Skill:** `/ui-design-deep` for reviews; `/ui-check` per PR before merge

Product goal: calm, trustworthy care coordination — warm neutrals, sage operational accent, restrained guardian warmth. See `principles.md`.

**Policy:** One verifiable outcome per PR. `./scripts/pre-push-changed.sh` during work; `./scripts/pre-push.sh` before final integration PR if batched.

---

## Current state (baseline)

| Item | Location | Notes |
|------|----------|-------|
| Theme | `flutter_app/lib/core/theme/app_theme.dart` | Material 3, purple seed `#6750A4` |
| Org palette constants | `AppTheme.org*` in same file | Used across ~20 org widgets |
| Hardcoded `Color(0x…)` | 5 files outside theme | `org_person_card`, `pet_card`, `pet_form_edit_actions`, `pet_photo`, `app_theme` |
| Screens | 67 under `presentation/screens/` | Many already split into widgets |
| A11y gate | `@smoke-a11y` Playwright + axe | UAT tier; not every PR |
| Design governance | `.cursor/rules/design.mdc`, skills `/ui-check`, `/ui-design-deep` | Lightweight tiers |

---

## Locked decisions (confirm before Phase 0)

| # | Decision | Proposal |
|---|----------|----------|
| D1 | Guardian primary | Plum `#755B68` — full primary on `/g/*` |
| D2 | Organisation primary | Teal `#218B6C` — full primary on `/o/*` |
| D3 | Warm accent | Coral `#D6A08F` — never primary CTA |
| D4 | Success | `#2B7A2E` (S2) |
| D5 | Surfaces | `#F8F5F1` background; white cards |
| D6 | Typography | Material 3 defaults |
| D7 | Dark mode | Out of scope until native apps |
| D8 | Org branding | Logo/name/photo only (`copy-tone.md`) |
| D9 | Implementation | `ThemeData` + `ExperienceColors` extension |

---

## Phase overview

```
Phase 0  Tokens + theme foundation     app_theme.dart, tokens.md
Phase 1  Shared component pass         theme roles, org constant migration
Phase 2  Entry + onboarding           landing, auth, chooser, onboarding
Phase 3  Core guardian shell           shell, home, pet list/detail, notifications
Phase 4  Health + forms                health dashboard/forms, vet, weight UI
Phase 5  Organisation                  org screens, foster portal, branding
Phase 6  Long tail                     sharing, help, about, paywall, stragglers
Phase 7  QA + docs closeout            a11y coverage, doc cleanup, debt sweep
```

Each phase = one or more atomic PRs. Prefer merge to `main` when CI green (single-agent); use integration branch only if parallel agents (see `.cursor/rules/merge-policy.mdc`).

---

## Phase 0 — Tokens and theme foundation

**Outcome:** `app_theme.dart` implements the new palette from a documented token file; no screen-file edits.

### Deliverables

- [ ] `docs/design/tokens.md` — colors, typography roles, spacing rhythm, radii, touch min (48dp), motion notes
- [ ] `flutter_app/lib/core/theme/app_theme.dart` — `ColorScheme` from new seed/slots (not purple)
- [ ] Map `AppTheme.org*` constants → semantic roles in tokens doc (even if values unchanged initially)
- [ ] Contrast check documented for primary/on-primary, error/on-error, text on surface

### Do not

- Edit feature screens or widgets
- Change copy or layout

### Verify

```bash
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration
```

### Acceptance

- App compiles; global chrome (buttons, inputs, cards, app bars) reflects new theme
- `principles.md` “current purple” caveat removed or updated

---

## Phase 1 — Shared component and constant cleanup

**Outcome:** Reusable UI uses theme tokens; org-specific colors reference tokens, not scattered literals.

### Scope

- Migrate `AppTheme.orgBlue`, `orgCharityBg`, etc. to named semantic tokens in `tokens.md`
- Replace hardcoded `Color(0x…)` in:
  - `org_person_card.dart`
  - `pet_card.dart`
  - `pet_form_edit_actions.dart`
  - `pet_detail/pet_photo.dart`
- Ensure `filledButton`, `inputDecoration`, `card`, `chip`, `snackBar`, `dialog`, `bottomSheet` themes match tokens
- Document empty/loading/error pattern (widget or convention) in `tokens.md` or `index.md`

### Reference implementations (match after theme)

- `org_card.dart` — semantics + card pattern
- `landing_branding_section.dart` — hierarchy (will be refined in Phase 2)

### Verify

- Widget tests for touched shared widgets
- `./scripts/pre-push-changed.sh`

---

## Phase 2 — Entry, auth, and onboarding

**Outcome:** Landing and first-run flows establish trust with new theme — stronger hierarchy, grounded contrast.

### Screens / flows

| Path | Files |
|------|-------|
| Landing / login / signup | `auth/presentation/screens/landing_screen.dart`, widgets under `landing/` |
| Forgot password | `forgot_password_screen.dart` |
| Experience resolve + chooser | `experience_resolve_screen.dart`, `experience_chooser_screen.dart` |
| Onboarding | `guardian_onboarding_screen.dart`, `org_onboarding_screen.dart` |

### Constraints

- Flutter web auth: `.agents/memory/flutter-web-password-managers.md` — do not break native login bridge
- Centered layout OK for auth; improve separation of brand vs action areas

### E2E (run or extend)

- `auth.login.spec.ts`, `auth.signup.spec.ts`
- `guardian.onboarding.spec.ts`, `org.onboarding.spec.ts`
- `experience.navigation.spec.ts`

### Acceptance

- `/ui-check` on each touched screen
- Axe clean on auth + onboarding journeys where `@smoke-a11y` exists

---

## Phase 3 — Guardian shell and core pet flows

**Outcome:** Daily guardian use paths feel coherent under the new system.

### Screens / flows

| Area | Files |
|------|-------|
| Shell | `experience_shell_scaffold.dart`, `guardian_experience_drawer.dart`, `guardian_shell_home_content.dart` |
| Home | `experience_home_screens.dart` (guardian) |
| Pet list | `pet_list_screen.dart`, list section widgets |
| Pet detail | `pet_detail_screen.dart`, `pet_detail/` widgets |
| Notifications | `notifications_screen.dart`, `notification_settings_screen.dart` |

### E2E

- `auth.login.spec.ts` (post-login list)
- `pet.profiles.spec.ts`
- `notifications.spec.ts`
- `experience.navigation.spec.ts`

---

## Phase 4 — Health, vet, and operational forms

**Outcome:** High-stakes forms and schedules are calm, clear, and state-complete.

### Screens / flows

| Area | Files |
|------|-------|
| Health dashboard + forms | `health_dashboard_screen.dart`, `health_entry_form_screen.dart`, `other_event_form_screen.dart` |
| Vet | `vet_list_screen.dart`, `vet_form_screen.dart` |
| Weight (pet detail) | `pet_weight_section.dart`, `weight_chart.dart`, `weight_tracking_section.dart` |

### Rules

- Operational copy stays direct (`copy-tone.md`)
- Overdue/due/completion UI follows `.agents/memory/health-entry-completion.md`
- All form fields: `labelText`; errors specific and actionable

### E2E

- `health.tracking.spec.ts`
- `veterinarian.spec.ts`
- `weight.tracking.spec.ts`

---

## Phase 5 — Organisation and foster portal

**Outcome:** Org dashboards match the unified system; org branding stays within `copy-tone.md` rules.

### Screens / flows

| Area | Files |
|------|-------|
| Org core | `organization_list_screen.dart`, `organization_detail_screen.dart`, `organization_form_screen.dart` |
| Members / people / pets | `organization_members_screen.dart`, `organization_person_detail_screen.dart`, `organization_pets_screen.dart` |
| Transfers / archive | `transfer_pet_screen.dart`, `transfer_pet_to_org_screen.dart`, `archived_*` |
| Foster | `pet_foster_placement_section.dart`, foster portal guard |
| Branding | `organization_branding_section.dart` |

### Notes

- Largest concentration of `AppTheme.org*` usage — migrate to semantic tokens
- Foster portal: `experience.foster-portal.spec.ts`

### E2E

- `organisation.management.spec.ts`
- `organisation.pet.management.spec.ts`
- `org.timeline.spec.ts`
- `adoption.spec.ts`

---

## Phase 6 — Long tail

**Outcome:** No visual stragglers; secondary flows match the system.

| Area | Files |
|------|-------|
| Sharing | `shared_pet_screen.dart`, sharing widgets on pet detail |
| Profile / settings | `my_details_screen.dart`, `experience_settings_screen.dart` |
| Help / about / legal | `help_screen.dart`, `about_screen.dart`, `legal_*` |
| Subscription | `paywall_screen.dart` |
| GDPR export | `export_data_*` |

### E2E

- `sharing.spec.ts`, `help.faq.spec.ts`, `auth.profile.spec.ts`, `gdpr.data-rights.spec.ts`

---

## Phase 7 — QA and documentation closeout

**Outcome:** Rework is documented, gated, and free of known token drift.

### Tasks

- [ ] Grep for remaining `Color(0x` outside `app_theme.dart` / charts — zero or documented exceptions
- [ ] Update `docs/design/principles.md` — remove transitional purple note
- [ ] Log completion in `docs/refactoring-log.md`
- [ ] Optional: add `@smoke-a11y` to any high-traffic journey not yet covered
- [ ] Run `/ui-design-deep` pass on one screen per experience (`/g/*`, `/o/*`) for consistency audit

### Verify

```bash
./scripts/pre-push.sh
```

---

## Parallel agent split (optional)

If using an integration branch + multiple agents:

| Agent | Owns | Avoid |
|-------|------|-------|
| `ui-phase-0` | `core/theme/`, `docs/design/tokens.md` | feature screens |
| `ui-phase-2-auth` | `auth/presentation/`, experience entry screens | org dashboards |
| `ui-phase-3-guardian` | `experience/` shell, `pet_profile/` list+detail | health forms |
| `ui-phase-5-org` | `organization/presentation/` | `app_theme.dart` after phase 0 merge |

**Never parallelise:** `app_theme.dart`, `tokens.md`, same screen file.

---

## Per-PR checklist

- [ ] Serves one phase outcome (or a clear sub-slice of it)
- [ ] `/ui-check` completed (or `/ui-design-deep` for phase kickoff)
- [ ] Theme tokens, not new ad-hoc colors
- [ ] l10n for new/changed strings
- [ ] Widget tests for touched interactive widgets
- [ ] E2E updated if selectors or journeys change
- [ ] `./scripts/pre-push-changed.sh`

---

## Open questions (resolve in Phase 0 kickoff)

1. Exact hex values for sage primary and coral secondary — design sign-off
2. Custom font Y/N (default: Material system)
3. Logo / illustration treatment on landing — keep current asset or refresh with theme?
4. Chart colors for weight/health — fixed palette in `tokens.md`?
