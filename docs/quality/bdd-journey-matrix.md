# BDD journey matrix & traceability

Living map between **customer journeys**, **Gherkin scenarios**, and **Playwright executors**.  
Sprint **4.3** target: **≥ 50% of all Gherkin scenarios (161)** have a Playwright test — **≥ 81 scenarios** mapped on `main`.

**Sources of truth (in order):**

| Layer | Location | Role |
|-------|----------|------|
| Behaviour spec | `flutter_app/test/bdd/features/*.feature` | What the product must do (Gherkin) |
| Traceability | *this file* | Journey → priority → scenario → test link |
| Executor | `e2e/playwright/tests/*.spec.ts` | Automated UI proof (`@bdd` header lists scenarios) |
| Page objects | `e2e/playwright/pages/` | Reusable UI vocabulary |

**Operational how-to:** `e2e/README.md`  
**Runner setup:** `e2e/scripts/run-local.sh`

---

## Recommended standard (hybrid BDD)

We use a **spec-first hybrid** (not full Cucumber execution yet — see `docs/refactoring-debt.md`):

1. **Gherkin scenarios remain canonical** — product language, readable by QA/product.
2. **Priority tags in feature files** — `@P0`, `@P1`, `@P2` on each `Scenario` (Cucumber tag convention).  
   - `@P0` = release smoke / must not break  
   - `@P1` = core journey completion  
   - `@P2` = edge cases, secondary flows, i18n polish  
3. **Implementation status tags** (optional, added during 4.3): `@implemented` when a Playwright test exists; remove when scenario changes.
4. **Playwright spec header** documents the link (already in use):

   ```ts
   /**
    * @bdd pet_profiles.feature
    * Scenario: Creating a new pet with required fields
    * Scenario: Viewing pet details
    */
   ```

5. **This matrix** is the human-readable **requirements traceability matrix (RTM)** — journey → behaviour → scenario → spec file.
6. **CI gate (4.3 deliverable):** `e2e/scripts/check_bdd_coverage.js` — ratio of scenarios with a Playwright mapping vs **all 161** Gherkin scenarios; gate at **50%** (81 scenarios).

Industry parallels: ATDD traceability matrix + Cucumber living documentation + smoke tagging (`@smoke` in Playwright title for UAT).

---

## Personas

| Persona | Primary journeys |
|---------|------------------|
| **Pet guardian** (personal) | Onboarding, pets, health, weight, notifications, sharing |
| **Org operator** (pro/charity) | Organisation admin, org pets, foster/adoption, timeline |
| **Adopter / viewer** | Shared link (anonymous), accept share |
| **Subscriber** | Paywall & subscription management |
| **Any user** | Help/FAQ, account profile, GDPR data rights |

---

## Customer journeys (ordered by product priority)

Journeys are ordered **P0 → P1 → P2** at the journey level. Within each journey, behaviours are ordered by priority.

### J1 — Onboarding & account (Authentication)

**Goal:** Secure access to the app and basic profile.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | Sign up (happy path) | Signing up with valid credentials | `auth.signup.spec.ts` | ✅ |
| P0 | Log in (happy path) | Logging in with valid credentials | `auth.login.spec.ts` `@smoke` | ✅ |
| P0 | Reject wrong password | Logging in with incorrect password | `auth.login.spec.ts` | ✅ |
| P1 | Sign-up validation | mismatched / missing email / invalid email / short password / duplicate email (5) | `auth.signup.spec.ts` | ✅ |
| P1 | Log out | Logging out from the app | `auth.profile.spec.ts` | ✅ |
| P1 | View / edit profile | Viewing user details; Updating user profile | `auth.profile.spec.ts` | ✅ |
| P2 | Login edge validation | non-existent email; missing email/password | — | ❌ |
| P2 | UX | Toggle password visibility; login ↔ signup navigation | — | ❌ |

**Feature:** `authentication.feature` (17 scenarios) — **11/17 implemented (~65%)**

---

### J2 — Pet profiles (personal inventory)

**Goal:** Create and maintain pets on the home list and detail screen.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | Empty state | Empty pet list shows prompt | `pet.profiles.spec.ts` | ✅ |
| P0 | Create pet | Creating a new pet with required fields | `pet.profiles.spec.ts` | ✅ |
| P0 | View detail | Viewing pet details | `pet.profiles.spec.ts` | ✅ |
| P1 | Edit pet | Editing a pet's name (breed, delete, cancel, passed away…) | `pet.profiles.spec.ts` | ✅ partial |
| P1 | Full profile | all fields, color, age from DOB, photo, vet link | `pet.profiles.spec.ts` (all fields partial) | partial |
| P2 | Identification reminders | chip reminders | — | ❌ |

**Feature:** `pet_profiles.feature` (17) — **11/17 (~65%)**

---

### J3 — Health tracking (medications & dashboard)

**Goal:** Track due health work and complete entries.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | See due work | Viewing all health entries / due on dashboard | `health.tracking.spec.ts` | ✅ partial |
| P0 | Mark complete | Marking a health entry as taken | `health.tracking.spec.ts` | ✅ |
| P0 | Add medication | Creating a medication entry | `health.tracking.spec.ts` | ✅ |
| P1 | Entry types | preventive, vet visit, procedure, photo attachment | `health.tracking.spec.ts` (preventive, vet visit, procedure) | partial |
| P1 | Dashboard UX | filter tabs, group by date/pet/species, empty state | `health.tracking.spec.ts` (filter tabs, empty state) | partial |
| P1 | Edit / delete / undo / snooze / history | 5 scenarios | `health.tracking.spec.ts` (edit, delete, undo, snooze) | partial |
| P1 | Health issues & link to entries | 2 scenarios | — | ❌ |
| P1 | Pet list due badges | due events on pet list | `health.tracking.spec.ts` | ✅ |
| P2 | Export CSV/PDF; org filter | 3 scenarios | `health.tracking.spec.ts` (CSV) | partial |

**Feature:** `health_tracking.feature` (24) — **14/24 (~58%)**

---

### J4 — Notifications

**Goal:** Surface due/overdue work and manage read state.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | Empty state | Empty notifications shows message | `notifications.spec.ts` `@smoke` | ✅ |
| P0 | View list | Viewing the notification list | `notifications.spec.ts` | ✅ |
| P1 | Unread badge | badge on app bar; updates when read; cleared when all read | `notifications.spec.ts` | ✅ |
| P1 | Mark read | single + mark all | `notifications.spec.ts` | ✅ |
| P1 | Navigation | tap pet → pet detail; settings screen | `notifications.spec.ts` | ✅ |
| P1 | Server-side generation | overdue / due soon / completed notifications | — | ❌ |
| P2 | Grouping, pet color, org icon, mute/unmute | 6 scenarios | — | ❌ |

**Feature:** `notifications.feature` (18) — **9/18 (~50%)**

---

### J5 — Weight tracking

**Goal:** Log weight over time on pet profile.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | Empty state | Empty weight history | `weight.tracking.spec.ts` `@smoke` | ✅ |
| P0 | Add entry (UI) | Adding a weight entry | `weight.tracking.spec.ts` | ✅ |
| P1 | History & chart | list, multiple entries, chart | `weight.tracking.spec.ts` | ✅ partial |
| P1 | Edit / delete / units | 3 scenarios | `weight.tracking.spec.ts` | ✅ partial |
| P2 | Latest on profile; PDF report weight | 2 scenarios | — | ❌ |

**Feature:** `weight_tracking.feature` (10) — **8/10 (~80%)**

---

### J6 — Sharing & collaboration

**Goal:** Share pet visibility with family or adopters.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | Anonymous preview | Viewing a shared pet without being logged in | `sharing.spec.ts` `@smoke` | ✅ |
| P0 | Create link | Creating a share link for a pet | `sharing.spec.ts` | ✅ |
| P1 | Preview content | health entries; vet; owner name | `sharing.spec.ts` | ✅ |
| P1 | Accept share | Accepting a share into personal pet list | `sharing.spec.ts` | ✅ |
| P1 | Invalid link | Opening an expired or invalid share link | `sharing.spec.ts` | ✅ |
| P2 | Pending / decline / hide / unhide | 6 scenarios | — | ❌ |

**Feature:** `sharing.feature` (13) — **6/13 (~46%)**

---

### J7 — Organisation management

**Goal:** Pro/charity org lifecycle and membership.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P0 | Create org | Creating a Professional organisation | `organisation.management.spec.ts` | ✅ (demoted @smoke Sprint 6.5) |
| P1 | Full org CRUD & membership | remaining 10 scenarios | `organisation.management.spec.ts` | ✅ |

**Feature:** `organisation_management.feature` (11) — **11/11 (100%)**

---

### J8 — Organisation pets & placements (P1 product)

| Feature | Scenarios | Implemented |
|---------|----------:|------------:|
| `organisation_pet_management.feature` | 6 | 6 |
| `organisation_pet_timeline.feature` | 6 | 4 |
| `org_foster_and_adoption.feature` | 5 | 5 |
| `org_to_org_transfer.feature` | 3 | 3 |
| `org_pet_return.feature` | 2 | 2 |
| `pet_ownership_and_adoption.feature` | 2 | 2 |

**Subtotal:** 24 scenarios mapped in Sprint 6 — **22/24** (2 timeline scenarios deferred)

---

### J8c — Fostering platform (P2, Wave C)

| Feature | Scenarios | Implemented | Playwright |
|---------|----------:|------------:|------------|
| `fostering_platform.feature` | 3 | 3 | `fostering.platform.spec.ts` |
| `foster_onboarding.feature` | 3 | 3 | `foster.onboarding.spec.ts` |

**Subtotal:** 6 scenarios — **6/6** (API-first; visit-path scenario asserts positive `visit_outcome` before journey start)

---

### J9 — Veterinarian directory (P1)

**Feature:** `veterinarian_management.feature` (10) — **9/10** (`veterinarian.spec.ts`; linked-pets view pending)

---

### J10 — Subscriptions (P1 commercial)

**Feature:** `subscriptions.feature` (11) — **0/11** (RevenueCat; implement after core guardian journeys; UAT billing env required)

---

### J11 — Help & FAQ (P2)

**Feature:** `help_faq.feature` (10) — **10/10** (`help.faq.spec.ts`)

---

### J12 — Pet report PDF export (P2, pet guardian)

**Goal:** Download a PDF health/profile report for a pet.

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P2 | PDF report weight | PDF pet report shows latest weight as current weight | — | ❌ |
| P2 | Health PDF export | Exporting health entries as PDF | — | ❌ |

**Features:** `weight_tracking.feature`, `health_tracking.feature` — **not in 4.3 scope** unless capacity remains after 50% gate.

---

### J13 — GDPR / data rights (P2, all users)

| Pri | Behaviour | Gherkin scenario | Playwright | Status |
|-----|-----------|------------------|------------|--------|
| P2 | Export my data | Exporting my personal data as JSON | `gdpr.data-rights.spec.ts` | ✅ |
| P2 | Delete my account | Deleting my account with password confirmation | `gdpr.data-rights.spec.ts` | ✅ |

---

### J8b — Pet ownership & adoption (feature text)

**Feature:** `pet_ownership_and_adoption.feature` (8 scenarios) — **0/8 implemented**

Persona: **organisation super user** transferring pets to private adopters and managing archives.

| # | Scenario | Summary |
|---|----------|---------|
| 1 | Sharing an organisation pet with a prospective adopter | Alice (super user) shares org pet Max; Eve accepts link → Max in Eve's list as shared |
| 2 | Adopter places a shared pet into their personal list | Eve accepts pending share into personal list; Max under My Pets, still belongs to org |
| 3 | Adopter places a shared pet into another organisation | Eve accepts share into her other org "Eve's Foster Home" |
| 4 | Archiving a pet from the organisation after adoption | Alice archives Max → gone from active list, in archived |
| 5 | Viewing archived pets | Alice sees Max in archived list |
| 6 | Restoring an archived pet | Alice restores Max → back in active list |
| 7 | Hiding a shared pet from the organisation view | Eve hides Max → not in list, no notifications, not on health dashboard |
| 8 | Unhiding a previously hidden shared pet | Eve unhides from org detail → pet, notifications, dashboard resume |

**Product note:** Overlaps `sharing.feature` (accept/hide flows) but from **org adoption** context with archive/restore. Confirm with product whether archive API is still active before implementing E2E.

## Coverage summary (integration branch @ 2026-07-08)

| Metric | Value |
|--------|------:|
| Gherkin scenarios (all features) | **161** |
| Playwright tests (`e2e/playwright/tests/`) | **79** |
| Scenarios with explicit Playwright mapping | **81** |
| **Sprint 4.3 gate (50% of all scenarios)** | **≥ 81** ✅ |
| **Gap to gate** | **0** |
| Current all-scenario coverage | **50.3%** (81/161) |
| Features touched | **9 / 13** |

### Priority tags (for ordering work, not the CI gate)

| Tier | Purpose |
|------|---------|
| **@P0** | Release smoke / UAT `@smoke` |
| **@P1** | Core journey completion (incl. logout, subscriptions) |
| **@P2** | Edge cases, PDF export, GDPR, i18n polish |

**Confirmed product inputs (2026-07-08):** Pet guardian journeys outrank org operator; logout is **P1**; **50% gate = all 161 scenarios**.

---

## Gap analysis — waves to reach 81/161 (4.3)

**Need ~32 more scenario mappings.** Ordered by persona priority (pet guardian first).

### Wave A — Auth P1 + health P0/P1 (~10 scenarios)

- Log out; view/update profile (`authentication.feature`)
- Health: empty dashboard, preventive entry, edit, delete, undo, snooze
- Health: pet-list due badges

### Wave B — Pet profiles + weight remainder (~8 scenarios)

- Edit breed, delete/cancel, passed away, photo, vet link
- Weight: latest on profile (if not covered)

### Wave C — Health dashboard depth + vets (~12 scenarios)

- Health: filter tabs, grouping, health issues, CSV export
- `veterinarian_management.feature` — create, list, link to pet

### Wave D — Sharing remainder + notifications generation (~6 scenarios)

- Pending share, decline, hide/unhide (`sharing.feature`)
- Notification generation scenarios (API seed)

### Wave E — Org operator (~14 scenarios) — after guardian waves

- `organisation_pet_management.feature` (6)
- `pet_ownership_and_adoption.feature` (8) — *validate archive API with product*
- `organisation_pet_timeline.feature` (6) — pick subset if over target

### Out of 4.3 scope (P2 / later)

- `subscriptions.feature` (P1 but billing env)
- `help_faq.feature`
- J12 PDF report export; J13 GDPR (no Gherkin yet)

---

## Traceability index (feature → spec)

| Gherkin feature | Playwright spec | Tests | Scenarios | Mapped |
|-----------------|-----------------|------:|----------:|-------:|
| `authentication.feature` | `auth.login.spec.ts`, `auth.signup.spec.ts`, `auth.profile.spec.ts` | 12 | 17 | 11 |
| `pet_profiles.feature` | `pet.profiles.spec.ts` | 10 | 17 | 11 |
| `health_tracking.feature` | `health.tracking.spec.ts` | 15 | 24 | 14 |
| `notifications.feature` | `notifications.spec.ts` | 8 | 18 | 9 |
| `weight_tracking.feature` | `weight.tracking.spec.ts` | 8 | 10 | 9 |
| `sharing.feature` | `sharing.spec.ts` | 7 | 13 | 8 |
| `organisation_management.feature` | `organisation.management.spec.ts` | 10 | 11 | 11 |
| `veterinarian_management.feature` | `veterinarian.spec.ts` | 9 | 10 | 9 |
| `organisation_pet_management.feature` | `organisation.pet.management.spec.ts` | 6 | 6 | 6 |
| `organisation_pet_timeline.feature` | `org.timeline.spec.ts` | 4 | 6 | 4 |
| `pet_ownership_and_adoption.feature` | `adoption.spec.ts` | 2 | 2 | 2 |
| `help_faq.feature` | `help.faq.spec.ts` | 10 | 10 | 10 |
| `gdpr_data_rights.feature` | `gdpr.data-rights.spec.ts` | 2 | 2 | 2 |
| `subscriptions.feature` | — | 0 | 11 | 0 |

---

## 4.3 delivery workflow (integration branch)

Avoid multiple CI runs on `main` while work is in flight:

```
main
 └── cursor/sprint-4.3-bdd-integration-13e3   ← integration branch (this doc + all 4.3 work)
      ├── parallel agent branches (file ownership per feature)
      └── merge agents → integration branch → single PR → main (one CI)
```

**Sound because:** `main` only sees one merge when 50% gate is met; PR CI validates the batch.

**Risks & mitigations:**

| Risk | Mitigation |
|------|------------|
| Integration branch drifts from `main` | Rebase integration branch on `main` before final PR |
| Parallel agents mix commits (seen in Sprint 3) | Strict file ownership; one feature/spec per agent; verify branch tips |
| Overlapping `api.ts` / shared page objects | One “foundation” agent merges first, or serialise shared-file edits |
| Counting scenarios loosely | `check_bdd_coverage.js` parses `@bdd` spec headers ↔ `.feature` titles |

---

## 4.3 implementation checklist

- [ ] Add `@P0` / `@P1` / `@P2` tags to scenarios (ordering aid)
- [x] Implement `e2e/scripts/check_bdd_coverage.js` — **50% of 161** gate
- [x] Wire BDD gate into PR CI (`_reusable-test.yml` governance job)
- [x] Execute Waves A–D on integration branch (parallel agents)
- [x] Add `@P0` / `@P1` / `@P2` tags to scenarios (ordering aid) — Sprint 5.6
- [ ] Update `e2e/README.md` coverage table
- [x] Single PR: integration branch → `main` when gate ≥ 81 scenarios (#102)
- [ ] Keep `@smoke` aligned with `@P0` for UAT — Sprint 6.5

---

## Changelog

| Date | Change |
|------|--------|
| 2026-07-08 | Product sign-off: 50% of all scenarios; logout P1; J12/J13 P2 journeys |
| 2026-07-08 | Initial journey matrix for Sprint 4.3 planning |
