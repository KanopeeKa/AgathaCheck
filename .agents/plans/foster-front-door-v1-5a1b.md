# Plan — Foster front door v1 (questionnaire, home visit, revalidation, claim)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `foster-front-door-v1-5a1b` |
| **title** | Foster candidate questionnaire, home visit, annual revalidation, offline claim |
| **author** | cloud-agent |
| **created** | 2026-08-21 |
| **base_branch** | `cursor/foster-front-door-v1-5a1b-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Replace manual foster onboarding checkboxes with the v1.3 foster candidate questionnaire (XML), home visit lifecycle, document-bundle wiring, annual revalidation, and self-service offline foster claim. Deferred: pet sitter, duplicate meds, broadcast messaging.

**Standing grant:** User chat 2026-08-21 — Track A + C1 only; `/execute-plan` with spawn-sprint-agents and babysit-plus.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-21T14:14:00Z |
| **approved_until** | 2026-08-23T14:14:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous foster-front-door-v1-5a1b`

---

## Phase 0 — Policy + canonical form seed

| Field | Value |
|-------|-------|
| **id** | `0` |
| **branch** | `cursor/foster-front-door-policy-5a1b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
regulatory/forms/**
docs/fostering-platform/**
docs/refactoring-log.md
.agents/plans/foster-front-door-v1-5a1b.*
```

**Scope:**

- Commit default foster candidate form v1.3 XML
- Add `docs/fostering-platform/product-rules-foster-v1.md` (no fake home visit; deferred sitter/broadcast/duplicate meds)
- Extend `j1-foster-onboarding.md` Phase 5 outline

**Exit criteria:**

- [ ] Form XML in repo
- [ ] Product rules doc reflects scope decisions
- [ ] J1 doc updated

---

## Phase 1 — Questionnaire engine (backend)

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/foster-questionnaire-backend-5a1b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
db/migrations/**
db/schema/**
server/lib/fosterQuestionnaire.js
server/routes/organizations/fosterQuestionnaireRouter.js
server/routes/organizations/fosterOnboarding.js
server/routes/organizations/index.js
server/test/organizations/fosterQuestionnaire.test.js
server/test/organizations/fosterOnboarding.test.js
docs/fostering-platform/**
.agents/plans/foster-front-door-v1-5a1b.*
```

**Scope:**

- Migrations: templates, submissions, answers, matching profiles, decisions
- Parse/seed default v1.3 template; org settings (min age, light-touch review)
- Submit API + AUTO_GO / ADMIN_REVIEW logic + Q02_B flag
- Wire `onboarding_form` auto-complete on submission
- Audit events from form XML

**Exit criteria:**

- [ ] Jest covers outcome paths
- [ ] Onboarding step auto-completes on submit

---

## Phase 2 — Questionnaire UI (spawn)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/foster-questionnaire-ui-5a1b` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `bdd-journey` |

**spawn_config:**

```
integration_branch: cursor/foster-front-door-v1-5a1b-integration
ownership_ref: docs/refactoring-log.md#foster-front-door-v1-5a1b
```

**allowed_paths:**

```
flutter_app/lib/features/organization/**/foster_questionnaire/**
flutter_app/lib/features/organization/presentation/**/foster_onboarding/**
flutter_app/lib/l10n/**
flutter_app/test/features/organization/**/foster_questionnaire/**
flutter_app/test/bdd/features/foster_onboarding.feature
e2e/playwright/tests/foster.questionnaire.spec.ts
e2e/playwright/pages/**/foster*
docs/refactoring-log.md
.agents/plans/foster-front-door-v1-5a1b.*
```

**Spawn agents:**

| Agent | Branch | Owns |
|-------|--------|------|
| flutter-candidate | `cursor/foster-q-candidate-ui-5a1b` | Candidate form screens/widgets |
| flutter-admin | `cursor/foster-q-admin-ui-5a1b` | Admin review/decision UI |
| e2e-foster-q | `cursor/foster-q-e2e-5a1b` | BDD + Playwright |

**Exit criteria:**

- [ ] Candidate can submit questionnaire
- [ ] Admin can review and decide
- [ ] BDD + Playwright happy path

---

## Phase 3 — Home visit backend

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/foster-home-visit-backend-5a1b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
db/migrations/**
db/schema/**
server/lib/fosterHomeVisits.js
server/routes/organizations/fosterHomeVisitsRouter.js
server/routes/organizations/fosterOnboarding.js
server/routes/organizations/index.js
server/test/organizations/fosterHomeVisits.test.js
docs/fostering-platform/**
.agents/plans/foster-front-door-v1-5a1b.*
```

**Scope:**

- Schedule/reschedule/cancel; attendees; validator with `home_visits` permission
- Checklist + photos; address excluded from exports
- Outcome Yes/No; wire `home_visit` step auto-complete

**Exit criteria:**

- [ ] Jest lifecycle tests pass
- [ ] Onboarding step auto-completes on validated Yes

---

## Phase 4 — Home visit UI (spawn)

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/foster-home-visit-ui-5a1b` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `bdd-journey` |

**Spawn agents:**

| Agent | Branch | Owns |
|-------|--------|------|
| flutter-home-visit | `cursor/foster-hv-flutter-5a1b` | Admin schedule/validate UI + candidate status |
| e2e-home-visit | `cursor/foster-hv-e2e-5a1b` | BDD + Playwright |

**Exit criteria:**

- [ ] Admin can schedule and validate home visit
- [ ] Candidate sees visit status

---

## Phase 5 — Document bundle wire-up

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/foster-document-wire-5a1b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**Scope:**

- Post home-visit Yes → document pack flow
- Paper signature admin confirm path
- Full onboarding timeline reaches `approved` through real steps

**Exit criteria:**

- [ ] Integration test: questionnaire → visit → documents → approved

---

## Phase 6 — Annual revalidation (spawn)

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/foster-revalidation-5a1b` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `single-backend-route` |

**Spawn agents:**

| Agent | Branch | Owns |
|-------|--------|------|
| node-revalidation | `cursor/foster-reval-backend-5a1b` | Scheduled job + API |
| flutter-revalidation | `cursor/foster-reval-flutter-5a1b` | Candidate + admin UI |

**Exit criteria:**

- [ ] Yearly check-in job fires
- [ ] Admin can require new home visit

---

## Phase 7 — Offline foster self-service claim (spawn)

| Field | Value |
|-------|-------|
| **id** | `7` |
| **branch** | `cursor/foster-claim-invite-5a1b` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `bdd-journey` |

**Spawn agents:**

| Agent | Branch | Owns |
|-------|--------|------|
| node-claim | `cursor/foster-claim-backend-5a1b` | Claim token + accept API |
| flutter-claim | `cursor/foster-claim-flutter-5a1b` | Connect-to-account UI + accept flow |

**Exit criteria:**

- [ ] Claim email → signup/login links external record
- [ ] Onboarding history preserved after merge

---

## Runtime state

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 2
halt_reason: null
next_action: "continue phase 3 on branch cursor/foster-home-visit-backend-5a1b"
artifact_ref:
  branch: cursor/foster-home-visit-backend-5a1b
  plan_path: .agents/plans/foster-front-door-v1-5a1b.md
  plan_commit: 0c5459ccf0b89f1ec787d8fc66c0dfb02eb6b5ad
  snapshot_path: .agents/plans/foster-front-door-v1-5a1b.snapshot.json
  snapshot_commit: 0c5459ccf0b89f1ec787d8fc66c0dfb02eb6b5ad
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check

**Output:** `proceed-high-risk` — multi-phase UI + migrations; spawn parallel agents; 48h window.
