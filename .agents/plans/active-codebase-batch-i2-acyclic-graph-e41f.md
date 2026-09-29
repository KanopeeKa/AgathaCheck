---
title: Active codebase Batch I2 — Acyclic feature graph and server direction
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-i2-acyclic-graph-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-i2-acyclic-graph-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-i2-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **depends on** | Batch I1 merged |
| **router risk** | R2 — protocols `flutter-mobile`, `testing`, `documentation` |

## Goal

Package 9, second half (D5, D21). Take the active Flutter feature graph from one strongly connected component (13 features at `0cc739e`) to **zero** multi-feature SCCs, using cuts chosen from the measured graph. Make the result permanent with a checker rule that has no baseline. Apply the same ownership direction to the server.

**Phase overlap note:** phases 2 and 3 overlap on `flutter_app/lib/features/**`. They run strictly in sequence and never in parallel.

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
  plan_path: .agents/plans/active-codebase-batch-i2-acyclic-graph-e41f.md
  plan_commit: null
  snapshot_path: .agents/plans/active-codebase-batch-i2-acyclic-graph-e41f.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Layering ADR and cut list

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-i2-1-layering-adr-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i2-acyclic-graph-e41f.*
docs/architecture/decisions/**
docs/architecture/modularity.md
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
server/**
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
docs
```

**Acceptance criteria:**

- [ ] **I2.1-1** ADR `docs/architecture/decisions/000N-feature-layering.md` sets the target layer order, derived from the metrics run at the batch base. Proposed order, bottom to top: `core` → `auth` → `care_taxonomy` → `pet_profile` (domain, data, list, form only; D21) → {`vet`, `people`, `pet_tags`, `sharing`, `notifications`, `weight_tracking`, `health_tracking`} → {`care_intelligence`, `pet_care`} → `experience` (composition), with `subscription`, `about` and `help` as leaves. Every allowed direction is stated explicitly.
- [ ] **I2.1-2** A cut list names every current feature edge that points against the layer order (edge, files, directives, planned remedy: move to owner, move composition to `experience`, or invert with a callback or port), with each assigned to phase 2 or 3.
- [ ] **I2.1-3** The ADR records D21: multi-feature pet-profile surfaces move into `experience`, and `pet_profile` keeps no dependency on `health_tracking`, `weight_tracking`, `pet_care`, `sharing`, `vet`, `notifications` or `care_intelligence`.

---

### Phase 2 — Pet profile composition cut (breaks pet_profile ↔ health_tracking and siblings)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-i2-2-pet-profile-cut-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i2-acyclic-graph-e41f.*
flutter_app/lib/features/pet_profile/**
flutter_app/lib/features/experience/**
flutter_app/lib/features/health_tracking/**
flutter_app/lib/features/weight_tracking/**
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

**Acceptance criteria:**

- [ ] **I2.2-1** The metrics script and checker show **no** edges from `pet_profile` to `health_tracking`, `weight_tracking`, `pet_care`, `sharing`, `vet`, `notifications` or `care_intelligence`. Today these edges carry 67, 16, 18, 7, 3, 4 and 4 directives.
- [ ] **I2.2-2** The moved composite surfaces live under `experience/…/pet_profile/`, keep the same routes (router paths unchanged) and the same semantics labels, so the E2E selectors keep working, and keep or move their widget tests.
- [ ] **I2.2-3** No user-visible change: widget tests and golden or semantics assertions for the pet detail and profile screens pass.

---

### Phase 3 — Remaining cycle cuts and the no-cycle rule (SCC = 0)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-i2-3-cycle-cuts-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i2-acyclic-graph-e41f.*
flutter_app/lib/features/**
flutter_app/lib/core/**
flutter_app/test/**
scripts/check_feature_imports.js
scripts/check_feature_imports.test.js
scripts/feature-import-baseline.json
scripts/test/fixtures/feature-imports/**
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

- [ ] **I2.3-1** `python3 scripts/architecture/architecture-metrics.py` reports **"Strongly connected multi-feature components: 0"**.
- [ ] **I2.3-2** The checker gains **R5 `feature-cycle`**, which fails whenever any multi-feature SCC exists. R5 **cannot be baselined**: the tool rejects `--accept-new` for it. A fixture test proves a two-feature cycle fails.
- [ ] **I2.3-3** The checker gains **R8 `layer-order`**, which fails on any feature edge against the ADR layer order (I2.1). Its baseline is empty.
- [ ] **I2.3-4** R4 (`new-feature-edge`) remains for review visibility: a new edge that respects the layers is accepted only through `--update-baseline` in the same PR, with the edge listed in the PR body.

---

### Phase 4 — Server ownership direction

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-i2-4-server-direction-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-i2-acyclic-graph-e41f.*
server/test/architecture/serverDirection.test.js
server/routes/**
server/lib/**
server/services/**
server/db/**
docs/architecture/modularity.md
```

**forbidden_paths:**

```
server/routes/organizations/**
server/routes/fosterPlacements.js
server/routes/custodyTransfers.js
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **I2.4-1** `serverDirection.test.js` (from H.4) is extended with three rules. (a) Route modules import other route modules only through their area's composition `index.js` or its `shared.js`. (b) `server/db/**` query modules never import `server/services/**`, `server/lib/**` application services or `server/routes/**`. (c) `server/routes/**` contains no direct `pool.connect()` calls; every transaction goes through `withTransaction` (complements the E.3 ownership test). All rules pass with **zero** exceptions for active code.
- [ ] **I2.4-2** `docs/architecture/modularity.md` "Server ownership" section: routes translate HTTP, application services orchestrate and own transactions, persistence modules accept the client. Simple CRUD stays direct where no use-case abstraction helps.
- [ ] **I2.4-3** No response change: backend unit and integration suites pass unchanged.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-i2-integration-e41f` |
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

**Scope:** open one PR from the integration branch into `main`; `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch (full active suite); `complete-plan`; `roadmap-set-child`.

**Acceptance criteria:**

- [ ] **I2.5-1** The integration → `main` PR is merged by `/babysit-uat`, with every Flutter and backend job green.
- [ ] **I2.5-2** Pre-UAT E2E is green on the merge SHA.
- [ ] **I2.5-3** The roadmap child status is `merged`, and the Package 9 row reads Done, with the before/after SCC figures.
