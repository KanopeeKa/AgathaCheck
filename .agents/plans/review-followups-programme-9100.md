# review-followups-programme-9100

## Goal

Address code-review follow-ups from recent merges to `main` in seven atomic phase PRs to a single integration branch, then one release PR to `main` via `/babysit-uat`. Each phase has one verifiable outcome; decisions on ambiguous items are recorded in canonical docs.

## Canonical docs

| Domain | Path |
|--------|------|
| Notifications / suggestions (FR-FB-1, FR-FB-2, FR-SG-1) | `docs/domains/notifications/features/notifications-v2-spec.md` |
| Care / absence | `docs/domains/pet_care/features/care-context.md`, `docs/architecture/calendar-dates.md` |
| Pet profile | `docs/domains/pet_profile/features/pet-profile-decisions.md` + OpenAPI |
| Sharing | `docs/domains/sharing/features/specs.md` |
| Notifications / consent (Flutter) | `docs/domains/notifications/features/notifications-v2-spec.md` (consent UX where applicable) |
| CI / UAT | `docs/e2e/uat-deploy-tiers.md`, `docs/agent-efficiency/pr-review-cost-efficiency.md` |

## Delivery rules

- Phase PRs target `cursor/review-followups-integration-9100` only; squash-merge via `/babysit-plus`.
- One release PR: integration → `main` (phase 7, `/babysit-uat`).
- Failing test first for every behaviour fix; canonical-docs sync before push; `## Docs` on each PR.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-13T09:03:00Z |
| **approved_until** | 2026-10-15T09:03:00Z |
| **approved_by** | user-chat-2026-10-13-review-followups-programme-standing-grant |
| **control_issue** | #1855 |
| **Grant** | User message: full programme, integration branch, no stop |

## Phases

### Phase 1 — Server: notifications and suggestions (items 1–4)

**Outcome:** Unscoped notification resolve is guarded; suggestion quiet window and scheduler recovery are documented or migrated; suggestion inbox comments fixed.

**Scope:** `resolveNotifications` / callers; `SUGGESTION_EXPIRY_QUIET_WINDOW_DAYS`; `expireStaleSuggestions` decision; scheduler stale reclaim migration + tests; `suggestionInbox.js` comment placement.

**Exit criteria:**

- [ ] Jest: unscoped resolve, scoped resolve, revoke with null code
- [ ] Jest: scheduler claim, concurrent claim, failure reset, stale reclaim
- [ ] FR-FB-1 / spec updated for 30-day window and expiry behaviour (or migration + schema docs)
- [ ] `cd server && npx jest --env=node --forceExit` green for touched areas

### Phase 2 — Server: care, absence and timezone (items 5–7)

**Outcome:** Docblocks fixed; `todayIso` resolved once per request; auth before timezone on coverage routers; undo audit matches actual occurrence.

**Docs:** `care-context.md`, `calendar-dates.md`.

**Exit criteria:**

- [ ] Existing timezone tests pass
- [ ] Occurrence undo mismatch test
- [ ] No per-call `users` query storm in absence list/overlap paths

### Phase 3 — Server: pets and profile (items 8–9)

**Outcome:** `createPet` id conflict → 409; `updatePet` partial-safe or PATCH decision in canonical doc + tests.

**Exit criteria:**

- [ ] 409 test for foreign-owned id
- [ ] Partial update tests (`name` only; explicit `null` clears)
- [ ] Decision row in `pet-profile-decisions.md`

### Phase 4 — Server: sharing (items 10–11)

**Outcome:** No account enumeration on invite create; strict invitee acceptance (user id + verified email).

**Docs:** `docs/domains/sharing/features/specs.md`.

**Exit criteria:**

- [ ] Identical invite-create responses for known/unknown email
- [ ] Accept rejects wrong user / unverified email

### Phase 5 — Flutter: notifications and consent (items 12–13)

**Outcome:** Suggestion card accept/feedback UX; consent save result handling and local timestamp formatting.

**Exit criteria:**

- [ ] Widget tests for malformed accept, feedback failure, consent save success/failure
- [ ] `flutter analyze` + `flutter test` green

### Phase 6 — CI and workflows (items 14–19)

**Outcome:** Workflow injection hardening; pre-uat cancel decision documented; quality-kpis scoped permissions; docs-hygiene robustness; coverage threshold single source; backend ratchet includes lib/services/routes.

**Exit criteria:**

- [ ] `check_coverage_threshold_consistency.test.js` aligned with workflow env
- [ ] Ratchet fixture for unloaded file
- [ ] Decision on `cancel-in-progress` in PR body + `uat-deploy-tiers.md` if kept

### Phase 7 — Release integration → main

**Outcome:** Single PR listing items 1–19, decisions, docs; `./scripts/pre-push.sh`; `/babysit-uat`; `complete-plan`.

**Exit criteria:**

- [ ] Pre-UAT green on merge SHA
- [ ] Acceptance suite per programme spec

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "start phase 1: checkout cursor/review-followups-phase1-notifications-9100"
artifact_ref:
  branch: cursor/review-followups-integration-9100
  plan_path: .agents/plans/review-followups-programme-9100.md
  plan_commit: 562ce69e54cb04155c99d9cbd0a29707dc32ecf8
  snapshot_path: .agents/plans/review-followups-programme-9100.snapshot.json
  snapshot_commit: 562ce69e54cb04155c99d9cbd0a29707dc32ecf8
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
