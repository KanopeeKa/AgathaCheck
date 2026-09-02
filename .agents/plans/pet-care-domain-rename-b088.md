# Pet Care domain rename — execute plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-care-domain-rename-b088` |
| **title** | Pet Care domain rename (workspace + wire + Actions labelling) |
| **author** | Cloud agent |
| **created** | 2026-09-02 |
| **base_branch** | `cursor/pet-care-domain-rename-b088-integration-b088` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Rename the Guardian/My Pets **workspace domain** to **Pet Care** across product copy, API, DB wire values, Flutter routes (`/pc/*`), and tests — while **keeping "My Pets"** for the dashboard pet-rail section only. Rename the due-items dashboard block to **Care Actions** (eyebrow `CARE ACTIONS` / FR `SOINS`), link **All Actions** / FR **Tous les soins**, and bottom nav **Actions** / FR **Soins**. Follow Shelter canonical-naming precedent but complete the wire migration (no long-lived `guardian` aliases). Custody **guardianship** legal terms in the custody model are carved out.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-02T12:15:00Z |
| **approved_until** | 2026-09-04T12:15:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant:** User chat 2026-09-02 — full rename analysis, FR table (Suivi / Mes animaux / Soins), `/execute-plan`.

**Sanity check:** `proceed-high-risk` — cross-cutting migration (~150 files), DB migration, route prefix change.

## Naming contract (locked)

| Surface | EN | FR |
|---------|----|----|
| Workspace (drawer, toggle) | Pet Care | Suivi |
| Dashboard pet rail section | My Pets | Mes animaux |
| Dashboard due-items eyebrow | CARE ACTIONS | SOINS |
| Section link to full list | All Actions | Tous les soins |
| Bottom nav tab | Actions | Soins |

Custody model: `guardianship`, `individual_guardianship` transfer kinds stay; workspace/API enums migrate to `pet_care`.

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "start phase 2: checkout cursor/pet-care-db-api-b088"
artifact_ref:
  branch: cursor/pet-care-domain-rename-b088-integration-b088
  plan_path: .agents/plans/pet-care-domain-rename-b088.md
  plan_commit: 56c2f06aa57e88e6b02c11fc09df15d044b7ac64
  snapshot_path: .agents/plans/pet-care-domain-rename-b088.snapshot.json
  snapshot_commit: 56c2f06aa57e88e6b02c11fc09df15d044b7ac64
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

---

## Phase 1 — Vocabulary & decision lock

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/pet-care-vocabulary-b088` |
| **exit_checklist** | `governance` |

**allowed_paths:** `docs/domains/pet_care/**`, `docs/domains/pet_profile/features/pet-profile-decisions.md`, `docs/domains/cross-domain/changes/program-contract.md`, `docs/e2e/navigation-contract.md`, `docs/design/copy-tone.md`, `docs/architecture/index.md`, `.agents/memory/shelter-terminology-and-evolving-design.md`, `.agents/plans/pet-care-domain-rename-b088.*`

**Scope:** D38 decision row; `docs/domains/pet_care/README.md`; forbidden-synonym table; custody carve-out; FR table; eyebrow capitals rule.

**Exit criteria:**

- [ ] D38 locked in pet-profile-decisions.md
- [ ] pet_care README + program-contract vocabulary updated
- [ ] navigation-contract.md locators documented (pre-implementation)

---

## Phase 2 — Database & API migration

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/pet-care-db-api-b088` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:** `db/migrations/**`, `db/schema/canonical.sql`, `server/**`, `docs/architecture/api-reference.md`, plan artifacts

**Scope:** Migration `047_*`: `users.category` `pet_guardian`→`pet_carer`; notification scope; `pet_access.role` audit; API field `guardian_name`→`primary_holder_name` (dual-read period if needed); seeds/demo constants.

**Exit criteria:**

- [ ] Migration up/down tested locally
- [ ] `cd server && npx jest --env=node --forceExit` green
- [ ] api-reference.md updated

---

## Phase 3 — Flutter wire, routes, experience rename

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/pet-care-flutter-wire-b088` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:** `flutter_app/lib/features/experience/**`, `flutter_app/lib/core/router/**`, `flutter_app/lib/core/theme/experience_colors.dart`, `flutter_app/lib/core/theme/app_color_tokens.dart`, `flutter_app/lib/core/branding/**`, `flutter_app/lib/features/notifications/domain/**`, `flutter_app/test/features/experience/**`, `flutter_app/test/core/router/**`, plan artifacts

**Scope:** `AppExperience.petCare`, wire `pet_care`, `/g/*`→`/pc/*`, rename `guardian_*` files/classes to `pet_care_*` where workspace-scoped; `NotificationScope.petCare`; prefs `last_app_section`.

**Exit criteria:**

- [ ] Router tests pass
- [ ] `flutter analyze` clean on touched paths
- [ ] Experience widget tests pass

---

## Phase 4 — l10n & UI copy

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/pet-care-l10n-ui-b088` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:** `flutter_app/lib/l10n/**`, `flutter_app/lib/features/**`, `flutter_app/test/**`, `flutter_app/web/**`, plan artifacts

**Scope:** Workspace strings Pet Care/Suivi; keep `myPets`=My Pets/Mes animaux; Actions labelling; fix hardcoded strings (`shared_pet_screen.dart`); regenerate l10n.

**Exit criteria:**

- [ ] EN+FR ARB complete per naming contract
- [ ] Widget tests updated for workspace vs section labels
- [ ] No hardcoded Guardian/My Pets workspace strings remain

---

## Phase 5 — BDD & Playwright E2E

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/pet-care-e2e-b088` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:** `flutter_app/test/bdd/**`, `e2e/**`, `scripts/bdd-priority-tag-map.json`, `docs/quality/bdd-journey-matrix.md`, `docs/e2e/**`, plan artifacts

**Scope:** BDD scenarios; Playwright locators (`flutter.ts`, page objects); rename spec files where appropriate; FR alternates Suivi/My Pets/Soins.

**Exit criteria:**

- [ ] `node e2e/scripts/check_bdd_coverage.js` passes
- [ ] Guardian/pet-care E2E shard green locally

---

## Phase 6 — Documentation sweep & agent memory

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/pet-care-docs-sweep-b088` |
| **exit_checklist** | `governance` |

**allowed_paths:** `docs/**`, `.agents/**`, plan artifacts

**forbidden_paths:** `flutter_app/**`, `server/**`, `db/**`

**Scope:** Sweep active docs for Guardian workspace references; update UAT personas; supersede ux-overhaul-recovery drawer items; memory file.

**Exit criteria:**

- [ ] No active docs use Guardian/My Pets for workspace
- [ ] My Pets retained only for section semantics in docs

---

## Final integration → main

After phase 6 merged to integration: one PR integration→`main`, `/babysit-uat`, `./scripts/pre-push.sh`.
