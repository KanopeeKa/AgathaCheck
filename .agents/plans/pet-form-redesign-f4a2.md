---
title: Pet form bug fixes and edit-screen redesign
owner: Experience Program Team
audience: agent
status: draft
last_updated: 2026-09-05
tags: [execute-plan, pet-profile, ux, api]
---

# Pet form bug fixes and edit-screen redesign

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-form-redesign-f4a2` |
| **title** | Pet form data/API fixes + edit-screen redesign to match Pet Profile |
| **author** | cloud-agent |
| **created** | 2026-09-05 |
| **base_branch** | `cursor/pet-form-redesign-f4a2-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Fix UAT-blocking pet edit bugs (species/gender prefill, photo upload 413, raw error messages) and redesign the Add/Edit Pet screen to match the Pet Profile visual language: sectioned hierarchy, persistent labels, Dog/Cat species chips with sheet for other species, sex and neuter segmented controls, dedicated photo upload endpoint, full EN/FR localization, and responsive phone / tablet / desktop layouts with save workflow and regression tests.

**Confirmed design decisions (2026-09-05):**

- Normalize species/gender on load **and** fix UAT seed casing at source
- Dedicated `POST /api/pets/:id/photo` upload (multipart via `safeUpload`) — no base64 in pet JSON
- All user-facing errors localized (EN + FR)
- Species: **Dog** and **Cat** chips only; **More species** sheet for Bird, Fish, Rabbit, Hamster, Ferret, Horse / Poney, Other
- Sex (mammals): **Female | Male | Unknown** segmented control
- Neutered/spayed: **Yes | No | Unknown** for mammals; **Not applicable** read-only status for non-mammal species (Bird, Fish, Hamster, Ferret, Horse / Poney) — section remains visible
- Fourth section **Care & records**: veterinarian, insurance, chip ID
- Delete / passed away in separated danger zone

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-05T13:35:00Z |
| **approved_until** | 2026-09-07T13:35:00Z |
| **control_issue** | [#976](https://github.com/KanopeeKa/AgathaCheck/issues/976) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous pet-form-redesign-f4a2`

## Sanity check

| Check | Result |
|-------|--------|
| Phase path disjointness | Pass — backend → client → primitives → screen → responsive → E2E |
| Scope estimate | **proceed-high-risk** — 6 phases + integration PR; fits medium feature if phased; may need re-approve if >48h |
| Migrations | None — `photo_path` stores URL/path string; backward-compatible read for legacy base64 until migrated on next save |
| API contract | Additive `POST /api/pets/:id/photo`; pet PUT no longer accepts large base64 payloads |
| Security | `safeUpload`, `userCanManagePet`, rate limit on pets router |

## Phases

### Phase 1 — Pet photo API and species/gender normalization

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/pet-photo-api-f4a2` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
server/routes/pets/**
server/lib/**
server/test/pets/**
server/db/seeds/**
```

**forbidden_paths:**

```
flutter_app/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:**

- Add `POST /api/pets/:id/photo` — multer memory + `saveUploadedFile`, 2 MB cap, JPG/PNG/WebP
- Return public upload URL; persist in `photo_path`
- `normalizeSpecies()` / `normalizeGender()` on pet create/update/read (`Dog`, `Male`, etc.)
- Reject or strip base64 blobs in `photoPath` on PUT (return 400 with safe message)
- Fix UAT seed species/gender to canonical title case in `server/db/seeds/scenarios/*.js`
- Jest: upload happy path, oversize 413, auth, normalization, seed regression

**Exit criteria:**

- [ ] Photo upload endpoint tested; no raw errors in 5xx
- [ ] Species/gender normalized on wire and in DB reads
- [ ] Seeds use `Dog`/`Male` not `dog`/`male`
- [ ] `./scripts/pre-push-changed.sh` green for server paths

---

### Phase 2 — Flutter photo pipeline and localized errors

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/pet-photo-client-f4a2` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/data/**
flutter_app/lib/features/pet_profile/domain/**
flutter_app/lib/features/pet_profile/presentation/controllers/**
flutter_app/lib/l10n/**
flutter_app/test/features/pet_profile/data/**
flutter_app/test/features/pet_profile/presentation/controllers/**
```

**forbidden_paths:**

```
server/**
flutter_app/lib/features/pet_profile/presentation/screens/**
flutter_app/lib/features/pet_profile/presentation/widgets/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:**

- `PetRemoteDataSource.uploadPetPhoto(id, bytes, filename, token)` multipart
- Repository: upload photo before/after save; store URL in `photoPath`
- `pickImage`: web-safe resize/compress, max size validation **at pick time**
- `PetFormSubmitOutcome` + l10n keys for photo too large, wrong type, upload failed, network error
- `PetModel.fromJson` defensive species/gender normalization
- Unit tests: normalization, error mapping, upload flow (mocked)

**Exit criteria:**

- [ ] Saving pet with photo no longer sends base64 in JSON body
- [ ] Oversized image blocked at pick with localized message
- [ ] `PetRemoteException` never shown raw to users
- [ ] Widget/controller tests pass

---

### Phase 3 — Shared form primitives (species, sex, neuter, fields)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/pet-form-primitives-f4a2` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/**
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_species_section.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_gender_section.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_dob_section.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_photo_section.dart
flutter_app/lib/l10n/**
flutter_app/test/features/pet_profile/presentation/widgets/**
```

**forbidden_paths:**

```
server/**
flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:**

- `PetFormLabeledField` — persistent label above field (pet-form scoped, not global theme)
- `PetFormSection` — heading + optional subtitle on `surfaceAlt`
- **Species:** Dog/Cat chips + More species bottom sheet; selected chip uses `PetInfoChip` language
- **Sex:** `SegmentedButton` Female | Male | Unknown; l10n `petSex*` keys
- **Neuter:** Yes | No | Unknown for mammals; read-only **Not applicable** for `speciesWithoutNeutering`
- **DOB:** `formatCalendarDateMedium`, calendar affordance, subtle clear
- **Weight:** label + field with suffix unit (`kg` / from provider)
- **About:** `aboutPetNamed(name)` + integrated char counter
- Widget tests: lowercase seed prefill, species sheet, neuter N/A for Fish

**Exit criteria:**

- [ ] Primitives render correctly in isolation tests
- [ ] Species `dog` → Dog chip selected; gender `male` → Male segment
- [ ] Fish shows neuter "Not applicable", not interactive segments
- [ ] `node scripts/check_file_size.js` passes

---

### Phase 4 — Edit/add screen restructure (phone layout)

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/pet-form-redesign-phone-f4a2` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/**
flutter_app/lib/features/pet_profile/presentation/screens/widgets/**
flutter_app/lib/features/pet_profile/presentation/controllers/**
flutter_app/lib/l10n/**
flutter_app/test/features/pet_profile/presentation/screens/**
```

**forbidden_paths:**

```
server/**
e2e/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:**

- Split `pet_form_screen.dart` (≤500 lines); wire Phase 3 primitives
- Sections: **Basic details**, **Health details**, **About**, **Care & records**
- Photo identity header (reuse `PetPhoto` styling, plum change-photo action)
- Reduced helper text per design brief
- **Save changes** / **Cancel**; dirty-state tracking; `PopScope` unsaved guard
- Success snackbar localized; Save disabled when pristine
- Danger zone: delete + passed away (existing behaviour, restyled)
- Add-mode: ownership selector above basic details; weight create vs edit preserved
- Update `pet_form_screen_test.dart`

**Exit criteria:**

- [ ] Edit Buddy on UAT data shows Dog, Male, all text fields prefilled
- [ ] Photo pick validates early; save uses upload endpoint
- [ ] Phone layout matches section spec
- [ ] `flutter analyze` + widget tests green

---

### Phase 5 — Responsive tablet and desktop layouts

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/pet-form-responsive-f4a2` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/**
flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/**
flutter_app/test/features/pet_profile/**
```

**forbidden_paths:**

```
server/**
e2e/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:**

- Breakpoints: phone `<600`, tablet `600–1024`, desktop `≥1024`
- **Tablet:** centred max-width ~720; DOB | Weight row; Species | Breed row
- **Desktop:** two-pane — left `PetFormPreviewCard` (live chips: name, species, sex, age, weight); right form max ~560px; page max ~1100 centred
- Phone: sticky bottom Save/Cancel bar (above safe area)
- Layout/widget tests at 320, 768, 1280 widths
- Walkthrough screenshots at three breakpoints (artifacts)

**Exit criteria:**

- [ ] Three layouts independently tuned (not stretched phone)
- [ ] Desktop preview updates as user edits
- [ ] Touch targets ≥48dp; focus visible on web
- [ ] Layout tests pass

---

### Phase 6 — E2E, BDD, and regression gate

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/pet-form-e2e-f4a2` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
e2e/**
flutter_app/test/bdd/**
flutter_app/test/features/pet_profile/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:**

- Update `e2e/playwright/pages/pet-form.page.ts` — Save changes, species chips, sex segments, photo upload
- Extend `pet.profiles.spec.ts`: photo upload UI, edit prefill with seeded pet, cancel unsaved
- BDD `pet_profiles.feature` scenarios aligned if step text changes
- `node e2e/scripts/check_bdd_coverage.js --report-only`
- Integration branch → `main` PR opened after phase 6 merge (coordinator runs `./scripts/pre-push.sh`)

**Exit criteria:**

- [ ] Playwright pet profile suite green locally
- [ ] BDD header titles match Gherkin
- [ ] Photo upload E2E covers dedicated endpoint path
- [ ] Full pre-push green before integration→main merge

---

## Integration → main

After all phases merged into `cursor/pet-form-redesign-f4a2-integration`:

1. Open single PR: integration → `main`
2. Run `./scripts/pre-push.sh`
3. **/babysit-uat** — merge + pre-UAT E2E gate on main

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-photo-api-f4a2"
artifact_ref:
  branch: cursor/pet-photo-api-f4a2
  plan_path: .agents/plans/pet-form-redesign-f4a2.md
  plan_commit: ebae04dbe5d6aff3c07bbbc3662b92f9d9acbcca
  snapshot_path: .agents/plans/pet-form-redesign-f4a2.snapshot.json
  snapshot_commit: ebae04dbe5d6aff3c07bbbc3662b92f9d9acbcca
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Revoke and resume

See [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md).

## Checklist before `approve-autonomous`

- [ ] `node scripts/validate_execute_plan_snapshot.js .agents/plans/pet-form-redesign-f4a2.snapshot.json`
- [ ] Control issue with labels `execute-plan`, `plan:pet-form-redesign-f4a2`, `autonomous-approved`
- [ ] `default_merge_mode: auto`
- [ ] Integration branch created from `main`
