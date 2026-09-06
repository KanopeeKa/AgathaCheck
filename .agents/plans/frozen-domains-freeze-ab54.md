---
title: Frozen Domains Freeze — execute plan
owner: Agent
audience: agent
status: active
last_updated: 2026-09-07
tags: [execute-plan, frozen-domains, pet-care]
---

# Frozen Domains Freeze

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `frozen-domains-freeze-ab54` |
| **title** | Freeze Shelter + Fostering; Pet Care MVP-only |
| **author** | Cloud agent (user request 2026-09-07) |
| **created** | 2026-09-07 |
| **base_branch** | `cursor/frozen-domains-freeze-ab54-integration-ab54` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Disconnect Shelter and Fostering from the active product lifecycle so Pet Care can ship as the only workspace. Frozen source stays in Git; frozen APIs are not mounted in production/UAT; active code must not import frozen modules; frozen tests do not block CI. Subscription remains active.

**Governing sentence:** Shelter can rot without infecting Pet Care — without building archive-management infrastructure.

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-07T00:00:00Z |
| **approved_until** | 2026-09-09T00:00:00Z |
| **control_issue** | #1050 |
| **content_hash** | from snapshot |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous frozen-domains-freeze-ab54`  
**Standing grant:** User chat 2026-09-07 — "build a full plan … /execute-plan fully"

## Freeze-complete acceptance criteria (plan-wide)

1. No Shelter/Fostering reachable in MVP UI.
2. No frozen HTTP endpoints in production/UAT (`ENABLE_FROZEN_DOMAINS` opt-in only, default off everywhere).
3. Active Flutter/Node code does not import frozen feature modules (CI boundary script).
4. Frozen tests cannot make active CI fail.
5. Frozen Dart unreachable from active import graph; excluded from `flutter analyze`.
6. New Pet Care work has no obligation to preserve Shelter/Fostering semantics.
7. GDPR/delete/export for retained org/foster data still works (active tests).

## Locked product decisions (D-MVP)

| ID | Decision |
|----|----------|
| D-MVP-1 | Shelter workspace (`/o/*`) not in MVP; workspace toggle and drawer Shelter entry removed. |
| D-MVP-2 | Fostering sessions removed from Pet Care; fostered pets indistinguishable from owned pets in UI. |
| D-MVP-3 | Pet Care primary nav: four destinations — Today, Pets, Care, Account. |
| D-MVP-4 | Shelter + Fostering frozen; Subscription active. |
| D-MVP-5 | Frozen source in Git; frozen tests excluded from blocking CI. |
| D-MVP-6 | **Semantics:** Pet Care client does not expose or send foster/org linkage on new writes; schema may retain dormant fields; API rejects or documents unsupported dormant fields (no silent ignore). |
| D-MVP-7 | Frozen routers not mounted unless `ENABLE_FROZEN_DOMAINS=true` (default false everywhere). |
| D-MVP-8 | Active code must not import frozen Dart/JS modules (CI-enforced). |
| D-MVP-9 | GDPR/deletion/export for org/foster tables remains active obligation. |
| D-MVP-10 | No archived GitHub CI workflow; optional `test-frozen-domains.sh` only. |

## Directional dependency rule

```
ACTIVE ──► SHARED
            ▲
            │
FROZEN ─────┘

ACTIVE ──X──► FROZEN
```

## Phases

### Phase 1 — Freeze contract

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/frozen-domains-contract-ab54` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
docs/engineering/frozen-domains/**
docs/architecture/index.md
docs/domains/pet_care/README.md
docs/domains/shelter/README.md
docs/domains/fostering/README.md
.agents/plans/frozen-domains-freeze-ab54.md
.agents/plans/frozen-domains-freeze-ab54.snapshot.json
```

**forbidden_paths:**

```
flutter_app/lib/**
server/**
.github/workflows/**
e2e/**
scripts/ci/**
```

**allowed_exceptions:** `docs`, `tests`

**Scope:**

- Philosophy, MVP pivot decisions (D-MVP-1–10), rehydration outline, CI integration notes.
- Minimal `docs/engineering/frozen-domains/manifest.json` (domains, sourceRoots, serverRoots, testRoots, bddFeaturePatterns).
- Mark shelter/fostering docs `status: frozen`.
- Git tag `pre-frozen-domains-pivot-2026-09` on integration parent before phase 2 merges.

**Exit criteria:**

- [ ] Manifest committed; philosophy and pivot decisions locked.
- [ ] `pre-frozen-domains-pivot-2026-09` tag pushed.
- [ ] Architecture index reflects frozen status.

---

### Phase 2 — Technical isolation

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/frozen-domains-isolate-ab54` |
| **exit_checklist** | `single-backend-route` + `flutter-screen-split` |

**allowed_paths:**

```
docs/engineering/frozen-domains/**
flutter_app/lib/core/router/**
flutter_app/lib/features/experience/**
flutter_app/lib/features/vet/**
flutter_app/lib/features/pet_profile/**
flutter_app/analysis_options.yaml
server/bin/server.js
server/jest.config.cjs
server/jest.config.frozen.cjs
server/jest.config.active.cjs
server/package.json
server/routes/pets/**
server/lib/**
server/test/pets/**
server/test/gdpr/**
server/test/auth/**
scripts/check_frozen_domain_boundaries.sh
scripts/test-frozen-domains.sh
.agents/plans/frozen-domains-freeze-ab54.md
.agents/plans/frozen-domains-freeze-ab54.snapshot.json
```

**forbidden_paths:**

```
.github/workflows/**
e2e/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Prune `app_router` / experience routes so active graph does not import `organization` or `fostering_session`.
- Vet decoupling: Pet Care vet UI must not import `organization_providers`; extract minimal shared helpers to `core` or `vet` if needed.
- `ENABLE_FROZEN_DOMAINS` gate in `server.js` — frozen routes off by default (prod/UAT/dev).
- Jest: `jest.config.active.cjs` ignores frozen test roots; `jest.config.frozen.cjs` for manual script.
- `analyzer.exclude` frozen `sourceRoots` after disconnect.
- `scripts/check_frozen_domain_boundaries.sh` — fail on active imports of frozen roots (blocking in pre-push phase 4).
- D-MVP-6 API posture on pet writes (reject unsupported `organization_id` on POST/PUT from MVP paths).

**Exit criteria:**

- [ ] Boundary script passes on active tree.
- [ ] `flutter analyze` green without analyzing frozen roots.
- [ ] Active Jest green; frozen org tests not in default `npm test`.
- [ ] Frozen APIs unmounted when env unset.
- [ ] Vet list works on `/pc/vets` without organization provider imports.

---

### Phase 3 — Product pivot

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/frozen-domains-pivot-ab54` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/**
flutter_app/test/features/experience/**
flutter_app/test/features/vet/**
flutter_app/test/features/pet_profile/**
flutter_app/test/features/pet_care/**
docs/engineering/frozen-domains/**
docs/domains/navigation/**
docs/e2e/navigation-contract.md
.agents/plans/frozen-domains-freeze-ab54.md
.agents/plans/frozen-domains-freeze-ab54.snapshot.json
```

**forbidden_paths:**

```
.github/workflows/**
e2e/**
server/**
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Remove workspace toggle and Shelter drawer entry.
- Pet Care 4-tab nav (remove Fostering tab).
- Remove dashboard fostering section and foster pet subgrouping.
- Remove `/pc/fostering` and fostering session detail routes from active router.
- Redirect stray `/o/*` to `/pc/home` (or 404) for registered legacy paths.
- Presentation: no `fosterPlacementStatus` / fostering badges in active UI (dormant model fields OK).

**Exit criteria:**

- [ ] MVP UI is Pet Care only; no fostering semantics in presentation.
- [ ] Navigation contract doc updated for 4-tab Pet Care.
- [ ] Active Flutter widget tests updated/passing.

---

### Phase 4 — Active test/CI repair

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/frozen-domains-ci-ab54` |
| **exit_checklist** | `governance` + `bdd-journey` |

**allowed_paths:**

```
.github/workflows/**
scripts/ci/**
scripts/pre-push-changed.sh
scripts/pre-push.sh
scripts/check_frozen_domain_boundaries.sh
e2e/**
flutter_app/test/bdd/features/**
flutter_app/scripts/run_tests_ci_shard.sh
flutter_app/scripts/merge_flutter_coverage.sh
docs/quality/bdd-journey-matrix.md
docs/pipelines/ci-cd-gates.md
docs/engineering/frozen-domains/**
.agents/plans/frozen-domains-freeze-ab54.md
.agents/plans/frozen-domains-freeze-ab54.snapshot.json
```

**forbidden_paths:**

```
flutter_app/lib/features/organization/**
flutter_app/lib/features/fostering_session/**
server/routes/organizations/**
```

**allowed_exceptions:** `tests`, `docs`, `governance-allowlist`

**Scope:**

- Remove `flutter-test-org` from `ci.yml` and `ci-gate` / `assert-ci-gate.sh`.
- Rebalance `e2e/scripts/shard-files.mjs` for active specs only (no file moves to `_frozen/`).
- Remove org specs from `@smoke-ci`; update `check-smoke-tags.mjs` if needed.
- `check_bdd_coverage.js` excludes `bddFeaturePatterns` from active gate; recalibrate gate threshold.
- Split **only** hybrid BDD/E2E (experience_navigation, guardian_dashboard, guardian.navigation, pet_timeline, account_area, notifications) — leave wholly frozen specs in place, excluded from CI.
- `ci-scope-lib.sh` / `pre-push-changed.sh`: no org shard; boundary check in governance.
- `pre-uat-e2e.yml` shard count aligned with active manifest.

**Exit criteria:**

- [ ] `./scripts/pre-push.sh` green on integration branch.
- [ ] Active BDD gate passes.
- [ ] PR CI (`ci-gate`) green without org flutter shard or frozen E2E.
- [ ] Boundary script in governance job.

---

### Phase 5 — Seal

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/frozen-domains-seal-ab54` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
docs/**
.cursor/rules/**
.agents/memory/MEMORY.md
scripts/test-frozen-domains.sh
scripts/check_frozen_domain_boundaries.sh
docs/engineering/frozen-domains/**
.agents/plans/frozen-domains-freeze-ab54.md
.agents/plans/frozen-domains-freeze-ab54.snapshot.json
```

**forbidden_paths:**

```
flutter_app/lib/features/organization/**
server/routes/organizations/**
```

**allowed_exceptions:** `docs`, `tests`

**Scope:**

- Complete `rehydration-runbook.md`.
- Update `pet-care-architecture.mdc`, `testing.mdc`, agent ROUTER shelter notes.
- Optional `scripts/test-frozen-domains.sh` (manual only; no GitHub archived workflow).
- Git tag `frozen-domains-baseline-2026-09` after freeze-complete checklist verified.
- Open **integration → main** PR; run `/babysit-uat`.

**Exit criteria:**

- [ ] All seven freeze-complete criteria verified.
- [ ] `frozen-domains-baseline-2026-09` tag pushed.
- [ ] Integration PR merged to `main` with pre-UAT green.

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: "Bootstrap integration branch; phase 1 freeze contract"
artifact_ref:
  branch: null
  plan_path: .agents/plans/frozen-domains-freeze-ab54.md
  plan_commit: null
  snapshot_path: .agents/plans/frozen-domains-freeze-ab54.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check

**Output:** `proceed-high-risk` — cross-stack (Flutter, Node, CI, E2E), touches router and workflows, but scoped to five coherent phases with clear freeze boundary. Fits 48h window if phases stay lean (no manifest generator, no file relocations).

## Revoke and resume

Standard execute-plan policy. Halt on drift outside allowed_paths.
