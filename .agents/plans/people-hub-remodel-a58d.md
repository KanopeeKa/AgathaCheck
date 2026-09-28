# People hub remodel — execute-plan

**plan_id:** `people-hub-remodel-a58d`  
**title:** People hub UX remodel — docs, roster cards, detail/edit, unified add, E2E  
**created:** 2026-09-28  
**base_branch:** `cursor/people-hub-remodel-integration-a58d`  
**default_merge_mode:** `auto`  
**artifact_branch_policy:** `phase-branch`

## Goal

Deliver the **post–`people-ui-hub-a58d` UX remodel**: one People roster with **VetTeam-style cards** on the hub and Today desk, **person detail** and **edit** routes, a **single “Add person”** journey (dedupe + late app-access / sharing), and **revoke/remove only in Edit** (danger zone). **Remodel existing** `docs/domains/people/**` into the canonical feature/changes set (no new parallel doc files). Encapsulate **widget, BDD, and Playwright** coverage and land one integration → `main` PR with **babysit-uat** (pre-UAT green).

**Prerequisite (orchestrator):** If `people-ui-hub-a58d` is not `completed`, run `complete-plan people-ui-hub-a58d` on `main` (p4 already merged via #1380) before merging implementation phases.

**Product locks (user chat 2026-09-28):**

- Nav label **People**; hub sections use [vocabulary.md](/docs/domains/people/features/vocabulary.md); **Today desk** first sub-block label **Vet team** (exception — not “Pet professionals” on desk only).
- **No** destructive actions on list rows or detail chrome — only **Edit → danger zone**.
- **Unified add** — no upfront “offline vs invite” fork; sharing is a sub-step when app access is needed (`flutter_app/lib/features/sharing/**`).
- **PersonRosterEntry** UI aggregate (contact | member | pending invite); backend may stay multi-table.
- Pattern reference: `flutter_app/lib/features/vet/presentation/widgets/vet_team_card.dart`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-28: full People hub remodel follow-up — docs remodel in place, tests/E2E, `/execute-plan` |
| **control_issue** | #1386 |

## Runtime

```yaml
autonomy: active
current_phase: p1-roster-cards
last_completed_phase: p0-docs
halt_reason: null
next_action: "start phase p1-roster-cards: checkout cursor/people-hub-remodel-p1-cards-a58d"
artifact_ref:
  branch: cursor/people-hub-remodel-integration-a58d
  plan_path: .agents/plans/people-hub-remodel-a58d.md
  plan_commit: 2055f4c7ea13d5d2afecfccefa5ec7b2fed05c62
  snapshot_path: .agents/plans/people-hub-remodel-a58d.snapshot.json
  snapshot_commit: 2055f4c7ea13d5d2afecfccefa5ec7b2fed05c62
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase p0-close-hub — Close `people-ui-hub-a58d`

Runtime sync: mark `p4-ship-main` merged, `complete-plan people-ui-hub-a58d`, close control #1373. No product code.

### Phase p0-docs — People documentation remodel

Consolidate UX/architecture into **existing** files only (`README`, `people-care-team.md`, `vocabulary.md`, `ui-hub-navigation.md`, `delivery-plan.md`). Extract rules from mockup board into feature spec; trim `changes/` items that are now in features. `bash scripts/validate_docs.sh` passes.

### Phase p1-roster-cards — Roster model, cards, routes

`PersonRosterEntry` + `PeopleDirectoryCard`; replace `ListTile` / desk text rows; routes `/pc/people/:personId`, tap from desk → detail; desktop master–detail shell (≥840px). Widget tests under `flutter_app/test/features/people/**`.

### Phase p2-detail-edit — Person view & edit

`PersonDetailScreen` (tabs per spec — no Activity for household members); `PersonEditScreen` with danger zone for revoke/remove; read-only name/photo when account linked.

### Phase p3-unified-add — Add person + sharing

Replace FAB → bare form with **PersonAdd** flow: identity → dedupe suggest → relationship → pets → optional app access → reuse sharing invite APIs. Deprecate parallel entry points where redundant.

### Phase p4-tests-e2e — Test harness & E2E

Review/update `people.feature`, `scripts/bdd-priority-tag-map.json`, Playwright guardian nav/dashboard/vet redirect/page objects; add scenarios for cards → detail, desk **Vet team**, filters. `node e2e/scripts/check_bdd_coverage.js --report-only` unchanged or improved.

### Phase p5-ship-main — Integration → main

Rebase `cursor/people-hub-remodel-integration-a58d` on `origin/main`, `./scripts/pre-push.sh`, single PR → `main`, **babysit-uat** until pre-UAT green.

## Sanity check

**expectation:** `proceed-high-risk` (multi-phase Flutter UI + E2E + sharing touchpoints; no new DB migrations in this plan unless p3 needs read-only API tweaks — escalate if migrations required).

## Escalation watch

- Breaking API or new migrations → halt and split
- `.github/workflows/**` → forbidden unless human approves CI change
