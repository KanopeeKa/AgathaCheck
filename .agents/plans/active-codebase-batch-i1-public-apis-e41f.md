---
title: Active codebase Batch I1 — Public feature APIs and forbidden edges
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-i1-public-apis-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-i1-public-apis-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-i1-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **depends on** | Batches D (import gate), G (health/pet authority pattern) and H (auth/document ports) merged |
| **router risk** | R2 — protocols `flutter-mobile`, `testing`, `documentation` |

## Goal

Package 9, first half (D5, D20). Every active Flutter feature gets **one documented public entrypoint**. Then the forbidden edges are removed: domain features importing `experience`, cross-feature `data/` imports, and cross-feature `presentation/` internals. Finally, all cross-feature imports go through public entrypoints. The acyclic target is Batch I2.

Active features (16): `about`, `auth`, `care_intelligence`, `care_taxonomy`, `experience`, `health_tracking`, `help`, `notifications`, `people`, `pet_care`, `pet_profile`, `pet_tags`, `sharing`, `subscription`, `vet`, `weight_tracking`. The frozen features `organization` and `fostering_session` are excluded by the manifest. Entrypoints already exist for `health_tracking`, `pet_profile` and `vet` and are reviewed, not recreated.

**Anti-pattern guard (from the review):** a barrel that simply re-exports internals to satisfy the checker does **not** meet these criteria. Every export must appear in the feature README's public-surface table with a reason, and `data/**` is never exported.

**Phase overlap note:** phases 2–4 touch overlapping `flutter_app/lib/features/**` paths. They run strictly in sequence, each rebased on the previous merge, and never with `/spawn-sprint-agents`.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: "bootstrap: create integration branch + control issue, then phase 1"
artifact_ref:
  branch: null
  plan_path: .agents/plans/active-codebase-batch-i1-public-apis-e41f.md
  plan_commit: null
  snapshot_path: .agents/plans/active-codebase-batch-i1-public-apis-e41f.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Entrypoints, component READMEs and the entrypoint rule

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-i1-1-entrypoints-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i1-public-apis-e41f.*
flutter_app/lib/features/*/*.dart
flutter_app/lib/features/*/README.md
scripts/check_feature_imports.js
scripts/check_feature_imports.test.js
scripts/feature-import-baseline.json
scripts/test/fixtures/feature-imports/**
docs/architecture/modularity.md
docs/architecture/index.md
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **I1.1-1** Each of the 16 active features has `lib/features/<feature>/<feature>.dart` (D20). It exports only domain models and ports, query/command providers meant for other features, and explicitly listed UI entrypoints. It exports nothing under `data/**` (checker rule).
- [ ] **I1.1-2** Each feature has a `README.md` following the review's Appendix C template: purpose and non-goals, owned state and data, the public entrypoint, a public-surface table (symbol, kind, reason), allowed and forbidden dependencies, side effects, cache/freshness policy, permissions, tests, owner and last-reviewed date. `docs/architecture/index.md` links all of them.
- [ ] **I1.1-3** The checker gains **R6 `non-public-cross-feature-import`**: a cross-feature import must target the target feature's entrypoint file. This applies to `experience` and `core/router` too (D5: Experience consumes public APIs). It also gains **R7 `entrypoint-exports-data`**. Every current R6 violation is baselined by identity; R7 starts at 0. Fixture tests cover both rules.
- [ ] **I1.1-4** No runtime behaviour change: Flutter analyze and tests are green.

---

### Phase 2 — Remove domain → Experience edges (R1 = 0)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-i1-2-experience-edges-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i1-public-apis-e41f.*
flutter_app/lib/features/**
flutter_app/lib/core/widgets/**
flutter_app/lib/core/router/**
flutter_app/test/**
scripts/feature-import-baseline.json
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:** at the time of writing, about 56 directives in 33 files import `experience` from `auth` (4), `health_tracking` (4), `people` (4), `pet_care` (8), `pet_profile` (29), `pet_tags` (2), `sharing` (4) and `vet` (1). For each import, do one of the following:

- Move a widget or helper that lives in `experience` but belongs to the importing domain into its owner feature.
- Move a **pure** design-system widget (one with no feature providers and no feature models) into `core/widgets`.
- Invert the dependency with a callback or public model, so that `experience` composes the domain widget.

"Move to core" is allowed only for pure UI primitives, never for domain logic.

**Acceptance criteria:**

- [ ] **I1.2-1** Checker R1 reports **0** violations, and every R1 identity is removed from the baseline.
- [ ] **I1.2-2** Every widget moved into `core/widgets` has no import from `lib/features/**` (checker fixture or test), and each has a widget test in its new location.
- [ ] **I1.2-3** Flutter analyze and tests are green. The navigation and shell behaviour in pre-UAT E2E is verified at child close (I1.5).

---

### Phase 3 — Remove cross-feature data-layer and presentation-internal imports (R2 = 0, R3 = 0)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-i1-3-private-edges-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i1-public-apis-e41f.*
flutter_app/lib/features/**
flutter_app/lib/core/**
flutter_app/test/**
scripts/feature-import-baseline.json
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Acceptance criteria:**

- [ ] **I1.3-1** Checker R2 (cross-feature `data/**`) reports **0**. Consumers use the owner feature's domain port or provider from its entrypoint.
- [ ] **I1.3-2** Checker R3 (another feature's `presentation/**` internals) reports **0** outside the D5 composition layer. The composition layer uses only the UI entrypoints listed in the owner's README.
- [ ] **I1.3-3** No new public export exists without a README public-surface row, and R7 stays at 0.

---

### Phase 4 — All cross-feature imports go through entrypoints (R6 = 0)

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-i1-4-entrypoint-imports-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i1-public-apis-e41f.*
flutter_app/lib/features/**
flutter_app/lib/core/**
flutter_app/test/**
scripts/feature-import-baseline.json
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **I1.4-1** Checker R6 reports **0**, so every cross-feature import targets an entrypoint. The feature-import baseline contains no R1, R2, R3, R6 or R7 identities.
- [ ] **I1.4-2** Each entrypoint's export list equals its README public-surface table (a checker or test compares them).
- [ ] **I1.4-3** `architecture-metrics.py` is re-run, and the edge, directive and SCC figures are recorded in the baseline history table. The edge count must not be higher than at the batch start.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-i1-integration-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
**
```

**forbidden_paths:**

```
.github/workflows/deploy-*.yml
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** open one PR from the integration branch into `main`; `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch (the full active suite, because the refactor is broad); `complete-plan`; `roadmap-set-child`.

**Acceptance criteria:**

- [ ] **I1.5-1** The integration → `main` PR is merged by `/babysit-uat`, with Flutter analyze, all test shards and coverage green.
- [ ] **I1.5-2** Pre-UAT E2E is green on the merge SHA.
- [ ] **I1.5-3** The roadmap child status is `merged`.
