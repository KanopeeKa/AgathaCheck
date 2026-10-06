---
title: Active codebase Batch K — Cohesive extractions and final acceptance
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-k-final-acceptance-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-k-final-acceptance-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-k-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **depends on** | Batches D–J merged |
| **router risk** | R2 — protocols `testing`, `documentation`, `flutter-mobile`, `api-contract` |

## Entry gate (coordination, `docs/agent-efficiency/parallel-programmes.md`)

- Landing slot **12**: after every other ARCH child and the programmes they wait on have landed.

## Goal

Deliver Package 12 and the programme's final acceptance:

- Extract the remaining hotspots only along real responsibility boundaries, not to hit a line count.
- Write the ADRs and complete the component contracts.
- Re-measure with identical exclusions, publish before/after figures, and close the review.

Hotspots at `0cc739e` (from the metrics script):

- **Server:** `registerCoreRoutes` (370-line function), `registerCrudRoutes` (386), `registerOccurrenceRoutes` (358), `registerCompletionRoutes` (261), `registerPlannedAbsenceRoutes` (253), `shareInviteService.js` (456 lines), `projectSchedule.js` (502).
- **Flutter:** `pet_list_screen.dart` (`build` 351 lines), `pet_detail_profile_card.dart` (`build` 242), `landing_auth_forms.dart` (488), `paywall_screen.dart` (457), `pet_form_screen.dart` (441), `notification_panel.dart` (437), `consent_banner.dart` (463), `manage_events_collection_filter.dart` (411).

**Phase overlap note:** phases 1 and 2 are disjoint (server / Flutter), and phases 3 and 4 are docs. They run in sequence.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 5
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/active-codebase-batch-k-final-acceptance-e41f.md
  plan_commit: 58427e4219fd1f5a011e678a7fecf855c2960b8e
  snapshot_path: .agents/plans/active-codebase-batch-k-final-acceptance-e41f.snapshot.json
  snapshot_commit: 58427e4219fd1f5a011e678a7fecf855c2960b8e
open_prs: []
merge_commits: {"5":"58427e4219fd1f5a011e678a7fecf855c2960b8e"}
debt_issue_refs: []
```

## Phases

### Phase 1 — Server extractions by use case

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-k1-server-extractions-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-k-final-acceptance-e41f.*
server/routes/pets/**
server/routes/healthEntries/**
server/routes/careContext/**
server/services/**
server/lib/care/**
server/lib/pets/**
server/lib/health/**
server/test/**
scripts/file-size-allowlist.json
```

**forbidden_paths:**

```
server/routes/organizations/**
server/routes/fosterPlacements.js
server/routes/custodyTransfers.js
server/routes/auth/**
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
file-split
governance-allowlist
```

**Acceptance criteria:**

- [ ] **K.1-1** Each server hotspot above is split into HTTP translation (route) and an application service or use case with a named, tested public contract. Examples: occurrence use cases and DTO mapping out of `occurrencesRouter`; planned-absence commands and queries; invite orchestration versus persistence; pet CRUD versus lifecycle; health CRUD versus documents.
- [ ] **K.1-2** No active route-registration function exceeds **150** physical lines on the metrics heuristic. Every resulting file is ≤ 300 lines, or has a size-report entry with a reason, owner and review date. `projectSchedule.js` drops below 500 lines, or gets an allowlist ratchet entry with justification.
- [ ] **K.1-3** Contract, route and real-PG suites pass unchanged. No response changes. Each new service has its own unit tests.
- [ ] **K.1-4** No single-use wrapper without a semantic role: every new module states its responsibility in a header comment, and the integration reviewer confirms each split owns a coherent responsibility.

---

### Phase 2 — Flutter extractions by cohesive subcomponent

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-k2-flutter-extractions-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-k-final-acceptance-e41f.*
flutter_app/lib/features/**
flutter_app/lib/core/widgets/**
flutter_app/test/**
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

- [ ] **K.2-1** Every Flutter hotspot above is decomposed into subwidgets with **explicit** data and callback inputs. Extracted presentational widgets read no providers; state stays in controllers.
- [ ] **K.2-2** No `build` method exceeds **120** physical lines on the metrics heuristic, and every touched file is ≤ 300 lines or has a justified size-report entry.
- [ ] **K.2-3** Each extracted widget has a widget test. Semantics labels and identifiers used by E2E are unchanged (grep of the E2E selectors against the widget tree). Accessibility labels exist on every interactive control.
- [ ] **K.2-4** The feature-import checker (R1–R8) stays green with an empty baseline for the non-baselinable rules.

---

### Phase 3 — ADRs and component contracts

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-k3-adrs-contracts-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-k-final-acceptance-e41f.*
docs/architecture/**
docs/engineering/**
flutter_app/lib/features/*/README.md
server/README.md
server/lib/*/README.md
server/routes/*/README.md
server/services/*/README.md
```

**forbidden_paths:**

```
server/**/*.js
flutter_app/**/*.dart
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
docs
```

**Acceptance criteria:**

- [x] **K.3-1** ADRs exist in `docs/architecture/decisions/` for: transaction ownership (`withTransaction`, COMMIT guard, no pool fallback); cleanup jobs (D10/D11, lease semantics, retention); canonical health state and `CareScheduleController` (D19); retained frozen-data compatibility seam (Package 2); and pet cache freshness (D2/D18). They join ADR 0001 (erasure) and the layering ADR (I2.1). The decisions index lists them all.
- [x] **K.3-2** Server component READMEs (auth, pets, healthEntries, sharing, careContext, jobs, account) follow Appendix C: purpose, owned tables, endpoints with inputs/outputs/errors, transaction owner, side effects, permissions, tests, owner and last reviewed. Flutter READMEs from I1 are refreshed with the last-reviewed date.
- [x] **K.3-3** `docs/architecture/index.md` links every ADR, component README, `api-reference.md`/OpenAPI and the baseline README. `bash scripts/validate_docs.sh` is green.

---

### Phase 4 — Final verification and review closure

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-k4-final-acceptance-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-k-final-acceptance-e41f.*
.agents/plans/active-codebase-completion-e41f.*
docs/architecture/reviews/active-codebase-review.md
docs/engineering/active-codebase-baseline/**
.agents/memory/MEMORY.md
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

- [x] **K.4-1** Full `./scripts/pre-push.sh` + pre-UAT E2E run on the integration → `main` PR (phase 5, K.5-1). Phase 4: `bash scripts/validate_docs.sh` green; evidence matrix in review doc §Final acceptance verification.
- [x] **K.4-2** `architecture-metrics.py` re-run @ `afc7c4ad`; [`metrics-headline.md`](../../docs/engineering/active-codebase-baseline/metrics-headline.md) programme comparison table (`a8c7db1` → `0cc739e` → final).
- [x] **K.4-3** Review doc `status: implemented`; Implementation status all Done; P2/P3 size exceptions table with owner/review date.
- [x] **K.4-4** Review doc §Final acceptance verification — flows, tests, cleanup-job ops links.
- [x] **K.4-5** Roadmap programme exit criteria annotated in [`active-codebase-completion-e41f.md`](./active-codebase-completion-e41f.md) (item 9 deferred to K.5 pre-UAT on `main`).
- [x] **K.4-6** `.agents/memory/MEMORY.md` active-codebase gates entry.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-k-integration-e41f` |
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

**Scope:** open one PR from the integration branch into `main`; `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch; `complete-plan` on K; `roadmap-set-child`; then `complete-plan active-codebase-completion-e41f`.

**Acceptance criteria:**

- [ ] **K.5-1** The integration → `main` PR is merged by `/babysit-uat`, with every CI job green.
- [ ] **K.5-2** Pre-UAT E2E is green on the merge SHA, which is the programme's final gate.
- [ ] **K.5-3** `roadmap-status active-codebase-completion-e41f` reports `complete: true`, and `complete-plan` has closed both the K and roadmap control issues with summaries.
