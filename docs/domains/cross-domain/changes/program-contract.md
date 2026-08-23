---
title: Experience program contract
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [experience, contract]
---
# Experience program — platform contract

**Status:** Locked baseline for delivery  
**Last updated:** 2026-07-25  
**Related:** [navigation README](/docs/domains/navigation/README.md#decision-index-split-from-experience-program-decisions-log) · [roadmap-delivery-plan.md](roadmap-delivery-plan.md) · [navigation-brief.md](/docs/domains/navigation/features/navigation-brief.md) ·
[/docs/domains/fostering/features/g0-contract-pack.md](/docs/domains/fostering/features/g0-contract-pack.md) (this contract does not restate G0 — it extends it for the navigation/guardian/organisation-presentation surfaces G0 does not cover)

This is the platform contract layer for the **Experience program** (navigation reversal + Guardian
dashboard + Organisation presentation/access-control rework). Phase docs reference this file
instead of redefining vocabulary or cross-cutting rules. Follows the same "mandatory sections"
discipline as `g0-contract-pack.md` so the two programs read consistently.

---

## 1. Relationship to prior work

| Prior artifact | Disposition |
|---|---|
| `docs/design/navigation-v2.md` | **Superseded** (D1, D2) — kept as history |
| `docs/experience-split-plan.md` | Already superseded by navigation-v2; stays superseded |
| `cursor/org-mode-nav-phase3-shell-acf1` branch, control issue #262 | **Closed** (D6), not resumed |
| `docs/domains/fostering/features/g0-contract-pack.md` (J1–J5, merged) | **Kept and extended.** Vocabulary (foster profile, shelter–foster relationship, fostering session, participant comment vs staff note), permission-key catalog (§7), and audit event catalog (§8) are the foundation this program builds role bundles and self-management visibility on top of — not a parallel model |
| `docs/domains/shelter/features/org-custody-model.md` | Kept as-is; pet timeline (D18) reads from `custody_transfers`, does not duplicate it |
| `family_events` table, `familyEventsRouter.js`, `organisation_pet_timeline.feature` | **Superseded and retired** (D18, D19) |

---

## 2. Canonical vocabulary (this program)

| Term | Definition |
|---|---|
| **Journey** | A user-facing area of the roadmap (Guardian navigation, Organisation management, Pet management, Foster management, Notifications) — the top layer of the three-layer implementation shape |
| **Feature** | An implementable slice of a journey with its own acceptance criteria, UI rules, permissions, and BDD scenarios |
| **Sprint** | A vertically-sliced increment delivering one feature (or a safe sub-slice of one) with tests, UX review, and a release gate — the unit of actual delivery |
| **Notification kind** | `care` \| `administrative` — content-type axis (D7). Orthogonal to scope |
| **Notification scope** | `guardian` \| `organization` — existing enum, now a grouping/label only, not a routing split (D7, D8) |
| **Event** (this program) | Health/weight/other-entry due item only (D17). Not the legacy "family event" |
| **Pet timeline** | Composite per-pet history: guardian custody segments + fostering sessions + manual entries (D18). Replaces "family events" |
| **Role** | Coarse org-membership category: `associate \| foster \| admin \| super_admin` (D13) |
| **Permission key** | Atomic capability, G0 §7 catalog + this program's additions (§6 below) |
| **Bundle preset** | A named, UI-level grouping of permission keys (Foster Admin, Pet Admin, Team Admin) applied to `admin`-role members — **not** a wire role |
| **Permission override** | An individually granted/revoked permission key on a specific org member, audited (D16) |

### Forbidden synonyms (this program)

| Do not use | Use instead |
|---|---|
| "Family event" (new work) | Pet timeline entry (guardian custody segment / session / manual entry) |
| "Settings" (as a global nav item) | Account (global) vs organisation edit/customisations (org-scoped) vs self-card preferences (per-person, per-org) |
| "Home" (as a route/button) | Guardian dashboard (`/g/home`) or Organisation entry (`/o/orgs`) — there is no generic Home |
| Foster Admin / Pet Admin / Team Admin as if they were wire roles | Bundle presets over permission keys on the `admin` wire role |

---

## 3. Notification model (D7–D11) — target shape

### 3.1 Data model

Extend `AppNotification` (`flutter_app/lib/features/notifications/domain/entities/app_notification.dart`) and its backend row with:

| Field | Values | Notes |
|---|---|---|
| `kind` | `care \| administrative` | New. Set at creation time (not derived at read time) so SQL can filter/count by kind directly |
| `priority` | `normal \| urgent` | New. `urgent` reserved for D11 cases (agreement withdrawal alert, etc.) |
| `resolvedAt` | nullable timestamp | New. Null = open. Set when the referenced object transitions (request answered, transfer accepted/declined) — never a manual "mark resolved" by the recipient for administrative items with a referenced object |
| `scope` | existing enum | Kept as a **grouping label** (drives "From: <org name>" style grouping and the org filter chip), not a route |

`NotificationType` (existing enum: `dueSoon, overdue, reminder, completed, general`) stays for **care**-kind items. Add administrative type values aligned 1:1 with G0's existing `event_type` audit catalog where one exists (reuse the same semantic name in both places — one trigger emits both an audit row and a notification row):

`fosterRequestReceived, fosterRequestResponded, fosterApprovalGranted, fosterApprovalDeclined, sessionStartingSoon, sessionEndingSoon, agreementWithdrawn (urgent), connectionRequestReceived, pendingShareReceived, pendingFosterPlacementReceived, pendingAdoptionPlacementReceived, pendingCustodyTransferReceived, adminMessageReceived`

### 3.2 UX pattern (locked, D8/D9)

```
┌─────────────────────────────────────┐
│  Notifications              ✕      │  ← full-height right slide-over
├─────────────────────────────────────┤
│  [ All ] [ Care ] [ Organisation ]  │  ← kind filter chips (plum/green accent)
├─────────────────────────────────────┤
│  Today                              │
│   🔶 Urgent — Foster withdrew ...   │  ← priority=urgent, pinned above date order
│   🟣 Bella's vaccination is due     │  ← care, plum dot
│   🟢 Rescue Hearts: new foster req. │  ← administrative, green dot, org name label
│  Yesterday                          │
│   ...                               │
└─────────────────────────────────────┘
```

- Bell badge = single combined unread count across both kinds (never a dual badge — keeps the bell globally understandable per the brief).
- Chips filter the **already date-grouped** list; they do not introduce a second grouping axis.
- Every row keeps the existing read/unread visual treatment (`notification_tile.dart`); administrative rows referencing an open object additionally show an "Action needed" affordance until `resolvedAt` is set.
- Retire `/g/notifications` and `/o/notifications` as separate screens/providers; one `/notifications` route reachable only from the bell (not the drawer, not Account).
- `NotificationScopeRules` (existing pure-function class) is repurposed: keep the guardian/organization split logic for the "Organisation" chip's grouping, drop its use as a screen-level filter.

### 3.3 Pending-inbox migration (D10)

`PendingSharesSection`, `PendingFosterPlacementsSection`, `PendingAdoptionPlacementsSection`,
`PendingCustodyTransfersSection` (today rendered inline on the guardian/org shell home) become
**notification-emitting events** instead of permanent dashboard widgets:

- Each pending-object creation emits an `administrative`-kind, unresolved notification.
- The notification deep-links to the existing accept/decline screen for that object (reuse, no new UI for the actual accept/decline flow).
- `resolvedAt` is set when the object transitions out of "pending" (accepted, declined, expired).
- The dashboard sections themselves are removed once the notification path is live and tested (do not remove before the replacement is verified — see Phase 2 exit criteria).

---

## 4. Role and permission model (D12–D16) — draft shape, explicitly TBD

> **This entire section is `tbd` per D12.** Implement it as the current best shape, but do not
> let any call site assume it is final — always gate through the helper functions in §6, never
> inline role-string comparisons, so a future shape change is a localised edit.

### 4.1 Wire roles (target)

`organization_users.role`: `associate | foster | admin | super_admin`

- `associate` is new (D14) — same default access as today's implicit plain member, i.e. no
  new default grants. Replaces the informal "no special role" state with an explicit value so
  every membership row has a real role.
- `foster` is unchanged — still the org-membership flag, still orthogonal to fostering
  **approval** (G0 §4.3 — do not conflate).
- `admin` replaces the assumption that all admins have identical powers — an `admin` member's
  actual capability set comes from bundle presets / individual permission keys (§4.2), not the
  role string alone.
- `super_admin` unchanged.

### 4.2 Bundle presets (UI-level, not wire values)

| Bundle preset | Permission keys granted (see §6 for full key list) |
|---|---|
| Foster Admin | `manage_fosters`, `review_foster_onboarding`, `contact_fosters`, `confirm_foster_competencies`, `home_visits` (G0 §7, already defined) |
| Pet Admin | `manage_pets` *(new)*, `manage_fostering_sessions` (G0 §7), `transfer_pet_ownership` *(new)* |
| Team Admin | `manage_admin_contacts` *(new)*, `manage_members` *(new)* |

Applying a bundle preset to an `admin`-role member is implemented as: write one row per key into
`organization_permissions` with `source = 'bundle:<preset name>'` (audit trail keeps the
provenance visible — satisfies "keep overrides visible and traceable" even though a bundle grant
isn't technically an "override").

### 4.3 Permission override table (new)

```sql
CREATE TABLE organization_permissions (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  user_id UUID NOT NULL REFERENCES users(id),
  permission_key VARCHAR(64) NOT NULL,
  source VARCHAR(32) NOT NULL DEFAULT 'individual', -- 'individual' | 'bundle:<preset>'
  granted_by UUID NOT NULL REFERENCES users(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES users(id)
);
CREATE UNIQUE INDEX idx_org_permissions_active
  ON organization_permissions (organization_id, user_id, permission_key)
  WHERE revoked_at IS NULL;
```

Effective permission check = default grants for `role` (existing G0 §7 defaults) **union**
active (`revoked_at IS NULL`) rows in `organization_permissions` for that user+org.

### 4.4 `manage_permissions` (D15)

New permission key `manage_permissions` — default grant: `super_admin` only, in the same
default-grant table as G0 §7. Checked via the same helper as every other permission key
(`hasPermission(actorRole, org, 'manage_permissions')`), never a literal
`role === 'super_admin'` comparison, so a future exception is a data change, not a code change.

### 4.5 Audit (D16)

New `audit_events` `event_type` values (existing table, existing retention tiers —
`docs/ops/observability.md`): `permission_granted`, `permission_revoked`, `role_changed`,
`bundle_preset_applied`, `admin_contact_visibility_changed`, `foster_visibility_changed`,
`member_visibility_changed`.
`resource_type = 'organization_permission'` or `'organization_user'`; `metadata` carries
`{ permission_key, source }` only — never PII.

---

## 5. Discoverability model (D20–D22)

```sql
ALTER TABLE organizations
  ADD COLUMN town VARCHAR(120),
  ADD COLUMN administrative_area VARCHAR(120), -- generic label; UI localises "Department"/"Postcode"/"ZIP" by locale
  ADD COLUMN description TEXT,
  ADD COLUMN is_discoverable BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN legal_identifier_1 VARCHAR(64),
  ADD COLUMN legal_identifier_2 VARCHAR(64),
  ADD COLUMN legal_identifier_3 VARCHAR(64),
  ADD COLUMN public_profile_metadata JSONB; -- reserved, unused in this program
```

- New **unauthenticated-safe** endpoint, e.g. `GET /organizations/discover` — returns only
  `id, name, logo_url, town, administrative_area, description` for rows where
  `is_discoverable = true`. Paginated, rate-limited (`createApiLimiter()` per `security.mdc`),
  no PII, no contact/legal fields.
- Flutter: a standalone `OrgDiscoveryList` (or similar) widget with no dependency on
  authenticated providers — consumed by the authenticated Discover Organisations section now;
  designed so a future pre-login landing page can mount the same widget without rework (D22).
  This is a **constraint on how the widget is built**, not a second screen to ship now.
- `public_profile_metadata` stays unused (reserved) — do not invent a shape for it speculatively;
  the next phase that needs it (e.g. "current needs") defines its own migration.

---

## 6. Test strategy and coverage

| Layer | Tool | Expectation for this program |
|---|---|---|
| Node routes | Jest + supertest | Every new/changed route file gets a test file (`single-backend-route-change` checklist) — new discover endpoint, new permissions routes, new legal-field fields on org update, new timeline endpoint |
| Flutter domain/data | `flutter test` | New entities (`NotificationKind`, permission bundle model, timeline entry, discover org) get model + repo tests before/with the widget |
| Flutter UI | Widget tests | Every extracted widget (drawer, bell panel, org section cards, admin contact card, pet tabs) gets a widget test — mirrors `split-flutter-screen` convention |
| Integration | `flutter test` integration dir | Add/extend for the new drawer + shell chrome (blocking in CI, no `continue-on-error`) |
| BDD (Gherkin) | `flutter_app/test/bdd/features/` | See §6.1 disposition table |
| Playwright E2E | `e2e/playwright/tests/` | `@bdd` header exact match to Gherkin scenario titles; `@P1` tag for the critical paths (drawer switch, bell open, org discover, permission-gated action visibility) |
| Contract tests | Jest, G0-style fixtures | New permission-bundle read model gets a fixture-shape test the same way J1→J2 does today |

### 6.1 BDD file disposition

| File | Disposition | Why |
|---|---|---|
| `experience_navigation.feature` | **Extend + fix one scenario** | Most scenarios (login routing, chooser pre-select, remembered default) describe user *intent*, not drawer structure, and stay valid as-is. Only "User switches to organisation view from guardian drawer" (references the old "settings menu" switch mechanic) is `@legacy`-tagged and replaced with a new scenario reflecting the D5 drawer |
| `notifications.feature` | **Extend, no `@legacy` tag needed** | On inspection, scenarios are phrased generically ("the notifications screen", "the user marks... as read") and don't assert the guardian/org screen split explicitly — they remain behaviourally true under the unified bell/panel. Add new scenarios for kind chips, unified badge, and resolved state (D7–D9); no deletions required |
| `organisation_pet_timeline.feature` | **Rewrite (`@legacy` on the whole feature)** | Fully encodes the legacy family-events model (assign/from/to/notes CRUD), which is entirely superseded by the pet timeline (D18) |
| `organisation_management.feature`, `org_foster_and_adoption.feature`, `foster_onboarding.feature`, `fostering_platform.feature` | **Extend** | Still-valid J1–J5 behaviour; add new scenarios for roles/permissions/self-management, do not restart |
| New: `organisation_discovery.feature`, `organisation_permissions.feature`, `admin_contacts.feature`, `foster_self_management.feature`, `pet_screen_filters.feature`, `account_area.feature`, `guardian_dashboard.feature`, `pet_timeline.feature` | **New** | No prior coverage exists |

Rewrites use the same `@legacy` tag + dedicated cleanup PR pattern already established in G0 §14.2
— do not delete old scenarios in the same PR that adds new ones; tag `@legacy`, let the BDD
coverage gate (`node e2e/scripts/check_bdd_coverage.js`, floor **≥ 105** scenarios) confirm net
growth, then remove `@legacy` scenarios in a follow-up PR once the new Playwright specs are green
on `main`.

### 6.2 Coverage expectation

Every phase should **increase**, never decrease, the reported Flutter domain coverage
(`flutter-coverage / Flutter domain coverage`, floor 65%) and the BDD scenario count. A phase
that only removes code (e.g. retiring `family_events`) must still net-positive on scenario count
by adding the replacement feature's scenarios in the same PR sequence.

---

## 7. Gates and technical limitations (know before you build)

| Gate / limitation | Detail | Implication for this program |
|---|---|---|
| `ci-gate / CI passed` + `Analyze JavaScript` | Required checks on every PR to `main` | Standard — no change |
| BDD coverage gate | `node e2e/scripts/check_bdd_coverage.js`, floor ≥ 105 scenarios | Track net scenario count per §6.1 — do not merge a rewrite PR that drops the count below floor before the replacement scenarios land |
| File size gate | `node scripts/check_file_size.js`, 500-line hand-written ceiling | `organization_detail_screen.dart` split (Phase 3) and drawer rework (Phase 1) must use `/split-flutter-screen` from the start, not as an afterthought |
| **Agent PR safety gate** (`agent-pr-safety-gate.yml`) | Blocks `cursor/*` PRs touching `db/migrations/**`, `server/config/security.js`, `infra/**`, `**/auth/**`, `**/billing/**`, `**/secrets/**` — **but only when the PR body contains a standalone `Fixes #N`-style line** (the "agent implementation PR" pattern used by the separate autonomous issue-dispatch workflow) | This program **does** need new migrations (permission overrides, discover fields, legal fields, notification kind/priority/resolvedAt, manual timeline entries). Do not phrase PR bodies with a standalone `Fixes #N` line for migration-touching PRs — use `Related to #N` / prose references instead, so the irrelevant gate doesn't fire. Migrations remain normal, expected work in this repo (see J1–J5 precedent) |
| CI scope skip (`ci-scope`) | Flutter jobs may skip on narrow diffs; **never** skips for migrations, `server/config/security.js`, `flutter_app/lib/core/**`, `.github/workflows/** ` | Phase 1 (drawer, shell core) touches `flutter_app/lib/core/**` → always runs full Flutter suite, budget review time accordingly |
| UAT deploy cadence | Default 90-minute minimum interval between UAT deploys (`UAT_DEPLOY_MIN_INTERVAL_MINUTES`); catch-up runs every 30 min | Sequential single-agent phases merging faster than 90 min apart batch onto the same UAT deploy — expected, not a bug |
| UAT full E2E cadence | `UAT_FULL_E2E_MERGE_THRESHOLD` — full Playwright doesn't run every merge | New Playwright specs still run on the PR `@smoke-ci` canary; full-suite confidence comes at UAT cadence, not every PR |
| WAF / live smoke flakiness | `.agents/memory/uat-live-e2e-triage.md`, `docs/e2e/uat-waf-queue-lessons.md` — known health-vs-auth WAF probe classification, `infra_failed` vs real regression | Any new unauthenticated endpoint (discover organisations, D20) is a **new public surface** — coordinate with the UAT WAF lessons doc before assuming a live-smoke failure is a real regression vs a WAF probe artifact |
| `single-backend.mdc` | Node/Express is the only backend | No Dart backend mirror for any new route in this program |
| Forbidden ownership (G0 §4) | J1–J5 tables/routers have declared owners | New Phase 3/4 work must not duplicate J3 session state or J1 relationship/approval fields — extend via the documented read models (G0 §5) |

---

## 8. Logging and observability

Follow `docs/ops/observability.md` as-is — no new logging system needed.

| New surface | Audit event? | Application log? | PostHog? |
|---|---|---|---|
| Permission grant/revoke, role change | Yes — `audit_events` (§4.5) | Standard Pino request log | No (admin action, not a product-usage metric worth tracking) |
| Discover Organisations search | No (public, no PII) | Standard Pino request log; watch rate-limit hits | Yes — page view is fine (no PII); exclude from session replay masking rules only if it ever surfaces authenticated org data (it should not) |
| Pet timeline manual entry create/edit | `audit_events` `resource_type = 'pet_timeline_entry'` | Standard | No |
| Agreement withdrawal | `audit_events` (already exists conceptually — align with G0's audit catalog, add `foster_agreement_withdrawn` `event_type`) | Standard, plus explicit `logger.warn` given the urgent-notification fan-out | No |
| Admin contact / foster self-management preference changes | `audit_events` per D16/§4.5 | Standard | No |
| **Sensitive-screen exclusions** | — | — | Add the new Admin Contacts self-card screen and permission-management screen to the existing PostHog sensitive-screen exclusion list (`docs/ops/observability.md` §Support investigation workflow already excludes org person detail — extend, don't duplicate, the exclusion list) |

---

## 9. Localisation

- All new user-facing strings go through ARB (`flutter_app/lib/l10n/app_en.arb`, `app_fr.arb`) —
  no inline literals, per `design.mdc`.
- Legal identifier labels (D28): add three generic ARB keys per locale
  (`orgLegalIdentifier1Label`, `orgLegalIdentifier2Label`, `orgLegalIdentifier3Label`); FR values
  are "Numéro RNA" / "SIREN" / "SIRET", EN values are generic ("Legal identifier 1/2/3") until a
  specific country config is needed. Do not add per-country conditional Dart logic in this phase —
  the localisation layer alone should carry this (per D28's explicit instruction).
- "Administrative area" label (D20) similarly resolves through locale (e.g. "Department" FR,
  "Postcode"/"ZIP" elsewhere) rather than a hardcoded field name.
- Enum `.label` getters (new `NotificationKind`, bundle preset names, timeline entry types) must
  be localised, not hardcoded English strings — see `.agents/memory/localization-enum-labels.md`.
- New screens (Discover Organisations, Admin Contacts, Legal & Documents slide-over, permission
  matrix admin UI, Account dashboard) all need EN + FR strings **before** merge, not as a
  follow-up.

---

## 10. Asset / image rules

- Reuse `image_picker` + existing static-asset upload/serving path already implemented in
  `organization_branding_section.dart` — do not build new upload plumbing for the cover/logo
  hero (D29).
- State explicit guidance in upload UI copy: recommended cover dimensions, recommended logo
  dimensions (square), accepted formats, max file size — mirror the existing
  `maxWidth: 1200, imageQuality: 85` pattern already used for org images.
- Follow `security.mdc` file-upload rules unchanged (server-generated `fileId`, `memoryStorage()`,
  MIME allowlist) — no new upload code path, just a new call site.

---

## 11. UI/UX guardrails carried forward

Everything already in `design.mdc` / `accessibility.mdc` applies. Program-specific emphasis:

- Dashboards stay previews; dedicated screens carry management weight (both briefs' explicit rule).
- Symmetric preview→full-screen pattern across My Pets / Upcoming Pet Events / My Vets and across
  the Organisation section cards — reuse one shared "dashboard section" component, do not
  hand-roll three different preview layouts.
- Plum = guardian-owned, green = fostered/org-owned — never colour-only, pair with text/icon
  (existing `ownership_accent.dart` rule, reused for notification kind chips too, D8).
- Touch targets ≥ 48×48 logical px throughout the new drawer/bell/section-card surfaces.
- `/ui-check` before merge on every phase with new screens; `/ui-design-deep` for Phase 1
  (multi-screen shell rework) and Phase 3 (new multi-screen organisation IA).

---

## 12. Modularity and ownership conventions

- New Flutter screens: `flutter_app/lib/features/<feature>/presentation/screens/`, extracted
  widgets in matching `widgets/` subfolders, mirrored tests in `flutter_app/test/features/<feature>/`.
- New Node routes: `server/routes/<domain>/`, mirrored tests in `server/test/<domain>/`.
- No hand-written file above 500 lines at merge time — plan the split (`/split-flutter-screen`)
  as part of the feature's design, not as cleanup after the fact.
- New planning docs live under `docs/domains/<domain>/features/` or `changes/` per
  [documentation standards](/docs/domains/documentation/standards.md) — do not scatter notes in
  loose `docs/*.md` files; extend domain feature docs or add a clearly cross-referenced change doc.

---

## 13. Skills worth using in this program

| Skill | Where it helps most |
|---|---|
| `/split-flutter-screen` | Phase 1 drawer/shell rework; Phase 3 `organization_detail_screen.dart` decomposition into section cards |
| `/single-backend-route-change` | Every new/changed route (discover, permissions, legal fields, timeline) |
| `/add-bdd-playwright-scenario` | Every new/rewritten `.feature` file in §6.1 |
| `/ui-design-deep` | Phase 1 (shell), Phase 3 (organisation IA) — multi-screen consistency reviews |
| `/ui-check` | Every phase with new/changed screens, lighter touch |
| `/security-error-audit` | Any phase adding new 5xx-returning routes (discover, permissions) |
| `/pre-push-verify` | Every push |

**Suggested new skill (not yet written):** a `/notification-kind-migration` style checklist would
help if this kind/scope split needs to be replicated for a future notification-adjacent feature —
not worth authoring before Phase 1 ships and the pattern is proven once, but flag it if a second
consumer of the kind/scope split appears.

---

## 14. Open questions carried into delivery

These are genuinely open — resolve at the start of the phase named, not before:

| # | Question | Phase | Default if not resolved in time |
|---|---|---|---|
| Q1 | Exact copy/flow for the notification "Action needed" affordance on administrative items — banner vs trailing chip vs swipe action? | Phase 1 | Trailing chip, simplest to build and test |
| Q2 | Should `associate` require a data migration for existing memberships with no explicit role today, or is there always already a role value? | Phase 3 | Confirm via a read-only query against the actual `organization_users.role` distribution before writing the migration |
| Q3 | Exact content mapping of today's `experience_settings_screen.dart` rows into {Account, org edit/customisations, self-card} — needs a line-by-line audit | Phase 1/3 | Audit as the first task of Phase 1, not assumed upfront |
| Q4 | Should the Discover Organisations endpoint require any auth-optional rate-limit tuning beyond the default `createApiLimiter()` given it's fully public? | Phase 3 | Start with default limiter, revisit if abuse is observed |
