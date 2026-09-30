# People hotfixes — execute-plan (`people-hotfixes-7f3b`)

| Field | Value |
|-------|-------|
| **plan_id** | `people-hotfixes-7f3b` |
| **parent** | roadmap [`people-domain-refactor-7f3b`](./people-domain-refactor-7f3b.md), child 1 of 4 |
| **title** | Fix six cheap People bugs now, each with a regression test |
| **base_branch** | `main` (single-slice child; each phase PR targets `main` → `/babysit-uat`) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **phases** | 2 (commit prefix `phase(<n>/2): …`) |
| **entry gate** | Docs PR (landing slot 0b, #1454) merged. Lands in slot 0c. Touches People-owned files only, so it may land before or after ARCH D ([parallel-programmes §4](../../docs/agent-efficiency/parallel-programmes.md)) |
| **source of truth** | [target doc](../../docs/domains/people/changes/people-domain-refactor.md) §1 (bugs B1–B13) |

## Goal

Stop the most visible People bugs while the larger refactor waits for its landing slots. The fixes are small, local and deliberately temporary. The later children replace the code they touch, but they keep the **regression tests**, which move with the behaviour.

Out of scope here: B3, B4, B6, B8, B10, B11, B12. They need the new server model, the picker or the list–detail layout, and are fixed in `people-server-7f3b` and the client children.

### Pre-bootstrap check (2026-09-30, `main` @ `eee5cb1b`)

- **E2E remediations [#1456](https://github.com/KanopeeKa/AgathaCheck/pull/1456) / [#1458](https://github.com/KanopeeKa/AgathaCheck/pull/1458):** touched only `e2e/playwright/**` and `server/package*.json` (audit). **No** `flutter_app/lib/features/people/**` changes. Vet-edit Playwright flows were updated; **h2** scope for B9/B13 on the Flutter edit/add screens is unchanged.
- **Overlapping live plans:** only `test-health-ci-5f3a` (#1449) has `autonomy: active` with a future `approved_until`; it does not overlap `server/lib/people/**` or `flutter_app/lib/features/people/**`.

---

### Phase 1 — `h1-server-kind` · Renaming a contact never changes its kind (B2)

| Field | Value |
|-------|-------|
| **id** | `h1-server-kind` |
| **ordinal** | 1/2 |
| **branch** | `cursor/people-hotfix-h1-kind-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |
| **router_risk** | R1 |
| **protocols** | `api-contract`, `testing` |

**allowed_paths:**

```
server/lib/people/contactMutations.js
server/test/people/**
docs/architecture/api-reference.md
.agents/plans/people-hotfixes-7f3b.md
.agents/plans/people-hotfixes-7f3b.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
db/**
e2e/**
.github/workflows/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `docs`

**Scope:**

- In `patchPersonalContact`, remove the branch that re-infers `kind` when `name` changes without `kind` (`contactMutations.js:121`). Kind changes only when `kind` is sent.
- Note the behaviour in the API reference (PATCH contacts).

**Exit criteria:**

- [ ] Regression test: PATCH `{ name }` on an organisation contact keeps `kind: organisation`, and the linked `vets` row keeps its clinic
- [ ] Jest green

---

### Phase 2 — `h2-client-fixes` · Detail loop, desk labels, report details, add and edit errors (B1, B5, B7, B9, B13)

| Field | Value |
|-------|-------|
| **id** | `h2-client-fixes` |
| **ordinal** | 2/2 |
| **branch** | `cursor/people-hotfix-h2-client-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **router_risk** | R1 |
| **protocols** | `accessibility`, `testing` |

**allowed_paths:**

```
flutter_app/lib/features/people/**
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_people_desk_module.dart
flutter_app/lib/features/pet_profile/presentation/controllers/download_report_controller.dart
flutter_app/lib/features/pet_profile/presentation/providers/pet_vet_contacts_provider.dart
flutter_app/lib/l10n/**
flutter_app/test/features/people/**
flutter_app/test/features/experience/**
flutter_app/test/features/pet_profile/**
.agents/plans/people-hotfixes-7f3b.md
.agents/plans/people-hotfixes-7f3b.snapshot.json
```

**forbidden_paths:**

```
server/**
db/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`

**Scope:**

- **B1:** `peopleContactDetailProvider` no longer watches `peopleContactByIdProvider` while also writing into the list. Read the cached value with `ref.read`. Also give `PeopleContact` value equality (`==` / `hashCode`), so list updates don't re-notify unchanged contacts.
- **B5:** the Today desk uses `peopleContactRolesLine` / `peopleContactKindLabel` (localized), not raw `roles.join` / `kind`.
- **B7:** the PDF report's assigned vet carries the contact's phone, email and address, not only the name. Extend `PetVetOption` or read the contact.
- **B9:**
  - the add screen catches save errors and shows a mapped message (no raw text);
  - the kind "Change" toggles against the *current* kind;
  - no role is preselected; Save stays disabled until one is chosen, with a helper line.
- **B13:** the edit screen maps errors by HTTP status to copy (no `($e)` raw text, no `contains('400')`).

**Exit criteria:**

- [ ] B1 regression: a provider test with a fake datasource shows opening detail triggers exactly **one** `getContact`
- [ ] B5 widget test: the desk shows "Vet nurse · Emergency contact", not wire values
- [ ] B7 test: the report vet block includes phone/email/address when present
- [ ] B9 and B13 widget tests: failed save shows mapped copy; kind toggles back and forth; Save disabled with no role
- [ ] `flutter analyze` and `flutter test` green; `./scripts/pre-push-changed.sh --e2e-shards 3,9` green (desk and vet specs)

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: h1-server-kind
last_completed_phase: null
halt_reason: null
next_action: "continue phase h1-server-kind on branch cursor/people-hotfix-h1-kind-7f3b"
artifact_ref:
  branch: cursor/people-hotfix-h1-kind-7f3b
  plan_path: .agents/plans/people-hotfixes-7f3b.md
  plan_commit: d170ca5208c913539352043dad117a3f37326f56
  snapshot_path: .agents/plans/people-hotfixes-7f3b.snapshot.json
  snapshot_commit: d170ca5208c913539352043dad117a3f37326f56
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1462"]
merge_commits: {}
debt_issue_refs: []
```
