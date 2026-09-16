---
title: CIM Fix Plan
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-09-15
tags: [cim,fix-plan,agent]
---

# CIM Fix Plan

Owner: engineering (agent-executable unless flagged). All changes target the
`KanopeeKa/AgathaCheck` repo. Items are ordered for safe, atomic PRs; each is
self-contained and independently mergeable.

Two findings from the review are closed and excluded from this plan:
- **Rate limiting** — CIM routes inherit `router.use(createApiLimiter())` from
  `server/routes/pets/index.js:20` (registered before the CIM routes at lines
  25–27). Not a gap.
- **Numeric coercion of `weight_entries.weight`** — column is
  `DOUBLE PRECISION` (`db/migrations/archive/v1__initial.sql:214`); node-postgres
  returns a native JS number. `Number(row.weight)` in `safeguardsService.js` is a
  harmless no-op. Not a gap.

---

## Workstream A — Regulatory & observability gaps

### A1. Document `care_recommendations` in the regulatory DATA_MAP
**Why.** `regulatory/DATA_MAP.md` documents `care_safeguards` (§1.6d) and the
weight provenance columns, but the Phase C `care_recommendations` table is
missing. The feature doc requires safeguard/evidence persistence to align with
DATA_MAP; recommendations are persisted pet-scoped rows (status history,
`responded_at`) and belong in the map.

**Files.** `regulatory/DATA_MAP.md`.

**Changes.**
- Add a new subsection `### 1.6e Care Recommendations (care_recommendations table) — Phase C`
  adjacent to the existing `care_safeguards` block (after §1.6d, before §1.7).
- Table rows mirroring `db/migrations/054_care_recommendations.sql`:
  `id (UUID)`, `pet_id (UUID, FK pets)`, `care_family (VARCHAR(50))`,
  `suggestion_key (VARCHAR(100))`, `status (VARCHAR(30), default pending)`,
  `engine_version (VARCHAR(20))`, `knowledge_version (VARCHAR(20))`,
  `suggested_name (VARCHAR(255))`, `suggested_frequency (VARCHAR(30))`,
  `suggested_frequency_interval (INTEGER)`,
  `suggested_health_entry_type (VARCHAR(30))`, `rationale_key (VARCHAR(100))`,
  `health_entry_id (UUID, FK health_entries, ON DELETE SET NULL)`,
  `responded_at (TIMESTAMPTZ)`, `created_at`, `updated_at`.
- Note the unique index `(pet_id, care_family, suggestion_key)` and that
  `health_entry_id` links an accepted/adjusted suggestion to the created rhythm.
- State the privacy classification consistent with `care_safeguards`:
  pet-scoped care-intelligence state, retained with the pet (`ON DELETE CASCADE`).

**Verification.** `grep -n "care_recommendations" regulatory/DATA_MAP.md`
returns the new subsection; cross-check column list against the migration.
No code/test change.

### A2. Add audit logging to CIM routers
**Why.** `server/routes/pets/coreRouter.js` uses `logAuditEventSafe` from
`server/lib/audit.js` for pet mutations. CIM writes — accepting/adjusting a
recommendation creates a health rhythm; dismissing a safeguard is a
care-affecting state change — emit no audit events, breaking the repo's
"tiered audit logging" convention.

**Files.** `server/routes/careIntelligence/recommendationsRouter.js`,
`server/routes/careIntelligence/safeguardsRouter.js`.

**Changes.**
- Import `logAuditEventSafe` from `../../lib/audit.js` in both routers.
- `recommendationsRouter` respond handler: after a successful state transition,
  fire `logAuditEventSafe(pool, { actorUserId: userId, action, resourceType,
    resourceId, petId, metadata, req })` with:
  - `action`: `care_recommendation.accepted` / `.adjusted` / `.dismissed` /
    `.not_relevant`.
  - `resourceType: 'care_recommendation'`, `resourceId: recommendationId`,
    `petId`, `metadata: { care_family, suggestion_key, health_entry_id? }`.
- Place the call after the `UPDATE ... RETURNING` succeeds and before
  `res.json(...)`. Use `logAuditEventSafe` (fire-and-forget; failures logged,
  never block) so it cannot break the response — matches `coreRouter.js`.
- `safeguardsRouter` dismiss handler: `action: 'care_safeguard.dismissed'`,
  `resourceType: 'care_safeguard'`, `resourceId: safeguardId`, `petId`,
  `metadata: { safeguard_type }` after the dismiss `UPDATE` succeeds.
- Do **not** audit the GET handlers (reads), and do **not** audit the implicit
  sync writes in `GET .../care-safeguards` (that sync is a re-evaluation, not a
  guardian action; the guardian-initiated dismiss is the auditable event).

**Verification.** Extend `server/test/careIntelligence/recommendations.test.js`
and `safeguards.test.js`: assert the mock pool received an `INSERT INTO
audit_events` query on accept and on dismiss (the existing mock pool can record
calls). `node_modules/.bin/jest --env=node --forceExit careIntelligence` green.

---

## Workstream B — Correctness & safety of the safeguard lifecycle

### B1. Widen the safeguard fingerprint to carry a magnitude signal
**Why (confirmed real).** `evidenceFingerprint` hashes only
`{measurement_count, direction, classification}`. `classification` is a coarse
4-value enum and carries no magnitude, so a pet whose weight keeps declining
while staying in the same bucket/ direction/ count never regenerates a different
fingerprint — a dismissed safeguard cannot resurface for a worsening trend,
which is at odds with the doc's "resurface unless context changes materially".

**Approach.** Surface a magnitude field from the evaluator into the evidence,
then include a bucketed magnitude in the fingerprint (bucketed to avoid
re-surfacing on every single new measurement, which would defeat dismissal).

**Files.**
- `server/routes/careIntelligence/weightChangeSpec.js` — return `delta_pct`
  (already computed) on every classification branch (it currently returns only
  `classification/direction/persistent/reasons`). Add `delta_pct: <number|null>`
  to all five return objects.
- `server/routes/careIntelligence/weightSafeguardEvaluator.js` — add
  `delta_pct: changeSpec.delta_pct ?? null` to the `evidence` object.
- `server/routes/careIntelligence/safeguardsService.js` — in `evidenceFingerprint`,
  add a bucketed magnitude: `magnitude_bucket: evidence?.delta_pct == null ? null
  : Math.round(evidence.delta_pct * 20) / 20` (i.e. 5% buckets) into the hashed
  payload alongside the existing three fields.

**Why bucketing.** A raw `delta_pct` would change on every new measurement,
re-surfacing a dismissed safeguard immediately — the opposite extreme.
5% buckets mean a worsening trend (e.g. −5% → −10% → −15%) crosses buckets and
resurfaces, while noise within a bucket respects the dismissal.

**Tests (new — `server/test/careIntelligence/safeguards.test.js`).**
- Update the existing `evidenceFingerprint` "stable for equivalent evidence"
  test: keep stability for identical evidence, but add a case asserting two
  evidences differing only in `delta_pct` across a 5% boundary produce
  **different** fingerprints.
- Add `weightChangeSpec.test.js` assertions that `delta_pct` is present and
  numeric on `unexplained_material` and `ordinary` branches.

**Verification.** `node_modules/.bin/jest --env=node --forceExit careIntelligence`
green. Manually trace: a dismissed `weight_trend_down` safeguard with
`delta_pct = -0.06` (bucket −0.05) that later worsens to `delta_pct = -0.12`
(bucket −0.10) now has a differing fingerprint → reactivation path in
`syncPetSafeguards` fires.

**Spec note.** This is a behaviour change to the resurface policy. Record a
one-line note in `docs/domains/pet_care/features/care-intelligence.md`
"Silence principle" or "Suggestions vs safeguards" section: *"A dismissed
weight safeguard resurfaces when the trend crosses a 5% magnitude bucket."*

### B2. Test the safeguard service reactivation and no-candidate-delete paths
**Why.** `safeguards.test.js` covers insert + dismiss only. The reactivation
branch (dismissed → context changes → status back to `active`) and the
no-candidate branch (`evaluateWeightSafeguard` returns null →
`DELETE ... WHERE status = 'active'`) are the subtlest parts of
`syncPetSafeguards` and are untested.

**Files.** `server/test/careIntelligence/safeguards.test.js`.

**Changes.** Add to the `Care safeguards API` describe block (extend the
existing mock pool — it already handles UPDATE reactivation and DELETE):
- **Reactivation:** seed a dismissed safeguard for `pet-1` with
  `_dismiss_fingerprint` set to an old fingerprint; provide a declining
  weight series whose new fingerprint differs (use the B1 magnitude bucket).
  GET → assert the row's status returns to `active` and `dismissed_at` is null.
- **No-candidate delete:** seed an `active` safeguard, then swap
  `weightEntries` to a stable (non-declining) series. GET → assert the active
  row is deleted and the response is `[]`.

**Verification.** Jest green. (Depends on B1 for the fingerprint-difference
case; if B1 is deferred, drive the difference via `classification`/`count`
instead and add a TODO for the magnitude case.)

---

## Workstream C — Frontend robustness & feature completion

### C1. Hide the `adjust` action (C1a — owner confirmed)
**Why.** `CareRecommendationResponseAction.adjust` is plumbed through the
enum, repository, datasource, and backend (`buildAcceptedHealthEntry` handles
`adjust`, `care_source: 'agatha_adjusted'`), but `CareSuggestionCard` renders
only Accept / Why / Not relevant / Dismiss — no Adjust button. The roadmap
lists `CareRhythmAdjustSheet` as Phase C deliverable; the phase-D plan lists it
as "Phase C debt (polish)".

**Owner decision (confirmed):** go with C1a (hide). Verified that `adjust` has
no consumer outside CIM's own backend router/shared enum and the frontend data
layer (datasource/model) — no vet portal, no admin surface, nothing else
depends on it. Fully reversible one-line guard.

**Files.**
- `server/routes/careIntelligence/recommendationsRouter.js` — in the
  `action === 'accept' || action === 'adjust'` branch, reject `adjust` with
  `400 { error: 'Adjust is not available yet' }` (or similar) so the API does
  not promise an un-built UI path. Keep `buildAcceptedHealthEntry`'s `adjust`
  handling intact (dead but reversible) so the sheet can re-enable it later
  without touching the evaluator.
- `flutter_app/lib/features/care_intelligence/domain/entities/care_recommendation.dart`
  — add a doc comment on `CareRecommendationResponseAction.adjust` noting it is
  intentionally not surfaced in V1 and the backend returns 400 until the
  `CareRhythmAdjustSheet` ships.

**Verification.** `flutter analyze`; add a backend test asserting `POST
.../respond` with `{ action: 'adjust' }` returns 400. Jest green.

### C2. Wrap `CareSafeguardCard.dismiss` in error handling
**Why.** `CareSafeguardCard` calls `dismiss()` with no try/catch and no user
feedback; a network/500 failure silently does nothing. `CareSuggestionCard`
has full error handling via `CareSuggestionRespondActions` — the safeguard
card should match.

**Files.** `flutter_app/lib/features/care_intelligence/presentation/widgets/care_safeguard_card.dart`.

**Changes.**
- Convert the inline `dismiss()` to handle errors: catch, and on
  `CareIntelligenceException` with `isForbidden` show
  `l.careSuggestionEditForbidden` (reuse the existing key), else show a generic
  retry snackbar (add `careSafeguardDismissFailed` l10n key, EN + FR).
- Add a `_dismissing` guard (like `_responding` in the suggestion card) so the
  Dismiss button is disabled while in flight.
- Import `CareIntelligenceException` and `AppLocalizations`.

**Files (l10n).** `flutter_app/lib/l10n/app_en.arb`, `app_fr.arb` — add
`careSafeguardDismissFailed` ("Could not dismiss this. Try again." /
"Impossible d'ignorer. Réessayez.").

**Verification.** Add a widget test in a new
`flutter_app/test/features/care_intelligence/presentation/widgets/care_safeguard_card_test.dart`:
fake repository whose `dismissSafeguard` throws — assert the failure snackbar
appears and the button re-enables. (Flutter SDK absent in this sandbox; test
to be run in CI.)

### C3. Ship the full weight-context capture unit (RESCOPED — Phase E prerequisite)
**Priority: higher than the rest of workstream C.** This closes a documented
Phase E prerequisite, not an orphan-widget polish.

**Why (rescoped after second pass).** The original C3 framed this as
localizing+wiring a single orphan selector. Verified facts that change the
task shape:
1. **No reference-weight UI exists anywhere in the codebase.** The only
   frontend reference to `weight_reference_*` / `weight_management_context` is
   the domain enum `flutter_app/lib/features/care_intelligence/domain/weight_provenance.dart`
   (grep-confirmed — no form, no datasource send, no PUT body). There is no
   existing form to attach a selector to; the whole capture unit must be built.
2. **The safeguard suppression path is dead code in practice.** Phase E
   (`weightSafeguardEvaluator.js`, `care_safeguards` table) is already live.
   `weightSafeguardEvaluator.js:47` and `weightChangeSpec.js:82` suppress only
   when `management_context !== 'none'`, and the schema defaults the column to
   `'none'` (`db/migrations/055_weight_provenance_contract.sql:20`). No
   production write path sets it to a non-`none` value. So a guardian on a
   vet-supervised weight-loss plan has no way to stop the safeguard card from
   firing.
3. **`docs/domains/pet_care/changes/phase-d-review-relevance-plan.md` §9**
   requires structured context capture to "exist in production before Phase E
   ships — not a backlog-only item." Phase E has shipped; the prerequisite is
   unmet.

**Backend is already in place** — `server/routes/pets/coreRouter.js:252–315`
PUT `/pets/:id` accepts and persists `weight_reference_value`,
`weight_reference_authority`, and `weight_management_context` (with
`validateReferenceAuthority`/`validateManagementContext`). This task is
**frontend-only**: build the capture UI and send to the existing endpoint.

**Scope.** Ship `weight_reference_value` + `weight_reference_authority` +
`weight_management_context` as one coordinated capture unit on the pet profile
edit form, not the `WeightManagementContextSelector` in isolation. The selector
becomes one part of a 3-field section (reference value, reference authority,
management context).

**Files.**
- `flutter_app/lib/features/care_intelligence/presentation/widgets/weight_management_context_selector.dart`
  — replace hardcoded `labelText`/`helperText`/item labels with l10n keys
  (`weightManagementContextLabel/Helper` +
  `weightManagementContextNone/VetManaged/CarePlan/TreatmentRelated`).
- New `flutter_app/lib/features/care_intelligence/presentation/widgets/weight_reference_fields.dart`
  (or similar) — reference-value numeric field + reference-authority
  selector, composing with the management-context selector into one section.
- Pet profile/edit form — render the section; load current values from the pet
  row (extend the pet model/datasource to expose these three fields if not
  already), and on save call `PUT /api/pets/:id` with
  `weight_reference_value` / `weight_reference_authority` /
  `weight_management_context`. Reuse the existing pet-update datasource path.
- `flutter_app/lib/l10n/app_en.arb`, `app_fr.arb` — add the management-context
  keys above plus reference-field keys (`weightReferenceValueLabel`,
  `weightReferenceAuthorityLabel`, per-authority labels) in EN + FR.

**Verification.** `flutter analyze`; widget test that the section renders all
options and emits values; round-trip covered by the existing `coreRouter` PUT
tests once the frontend sends the fields. Add a focused test that setting
`management_context: vet_managed` causes the safeguard evaluator to return null
(closes the dead-code path end-to-end at the unit level).

**Interim risk if deferred.** If shipping the full capture flow is not in scope
for this pass, do **not** fold it into C3 as ordinary UI debt. Call it out
explicitly as an **accepted interim risk**: safeguards can false-fire for
vet-explained weight loss with no user-facing way to suppress them, because
the D3 production prerequisite is unmet while Phase E is live. Product owner
to decide before any build here.

---

## Workstream D — Test coverage

### D1. Unit tests for `PetCarePresentationPolicy`
**Why.** The policy is safety-critical (suppresses suggestions when a safeguard
is active; decides dashboard vs profile slots) and has no direct tests — its
behaviour is only indirectly exercised via the suggestion-card test.

**Files.** New
`flutter_app/test/features/pet_care/presentation/pet_care_presentation_policy_test.dart`.

**Changes.** Pure unit tests (no Flutter widgets):
- `profileSafeguard` returns the first active safeguard; ignores dismissed.
- `profileSuggestion` returns null when an `activeSafeguard` is present;
  returns the first pending recommendation otherwise; returns null when none
  pending.
- `profileMilestoneMoment` returns null when safeguard or suggestion active;
  returns the moment otherwise.
- `dashboardSafeguard`/`dashboardSuggestion`/`dashboardMilestoneMoment` — first
  active across pets, suppression by higher priority, "max one across pets".

**Verification.** `flutter test` (CI). Pure Dart — fast.

### D2. Direct tests for `weightChangeSpec` branches
**Why.** `weightChangeSpec.test.js` has 2 cases; the ordinary, life-stage,
reference-tolerance, persistence, and short-term-fluctuation branches are only
indirectly hit.

**Files.** `server/test/careIntelligence/weightChangeSpec.test.js`.

**Changes.** Add named assertions for each classification:
- `ordinary` — change below material threshold.
- `ordinary` (life-stage growth) — puppy <12 months, direction up.
- `explained` — `reference_authority` + within tolerance.
- `ordinary` (short-term fluctuation) — material delta but not persistent.
- `unexplained_material` — persistent declining series, no context.
- Boundary: delta_pct exactly at `MATERIAL_PCT` and at `ORDINARY_FLUCTUATION_PCT*2`.

**Verification.** Jest green.

### D3. Add a harness runner + minimal E2E coverage
**Why.** `runEvaluationHarness` is built but has no CLI/runner entry — it's
only called from one test, so the D5a deliverable isn't operable. And there is
zero Playwright E2E for CIM; the roadmap's negative tests (suggestion never in
Actions) have no end-to-end guard.

**Files (runner).** New `server/scripts/care-intelligence-harness.js` — a thin
`#!/usr/bin/env node` script that imports `runEvaluationHarness`, runs it, prints
the JSON report to stdout, and exits non-zero on `failures_present`. Follow the
style of `server/scripts/migrate.js` (shebang, `fileURLToPath` not needed; just
invoke and `process.exit`).

**Files (E2E).** New `e2e/playwright/tests/care-suggestion.spec.ts` and a
`e2e/playwright/pages/care-suggestion.page.ts` page object following the
existing pattern (`guardian-dashboard.page.ts`).
- Seed a pet eligible for a suggestion (adult dog, no rhythms).
- Assert the "Suggested by Agatha" card appears on the pet profile contextual
  slot.
- Assert it does **not** appear in the Actions (`/pc/events`) list (negative
  invariant from roadmap §12).
- Accept → assert a rhythm appears in Care Rhythms and the suggestion card is
  gone.

**Verification.** `node server/scripts/care-intelligence-harness.js` exits 0;
E2E run via the existing `e2e/scripts/run-local.sh` (manual dispatch per
`e2e.yml`, not per-PR).

---

## Workstream E — Cleanup

### E1. Dedupe `parseDateMs`
**Why.** `parseDateMs` is copied in `weightChangeSpec.js`,
`weightFeatureExtraction.js`, and (canonical) `weightPrimitives.js`.

**Files.** `server/routes/careIntelligence/weightChangeSpec.js`,
`server/routes/careIntelligence/weightFeatureExtraction.js`.

**Changes.** Replace the local `parseDateMs` definitions with
`import { parseDateMs } from '../../lib/care/observations/weightPrimitives.js';`
and delete the local copies. (Leave `weightPrimitives.js` as the single source.)

**Verification.** Jest green; `grep -rn "function parseDateMs" server/routes/careIntelligence`
returns nothing.

---

## Sequencing & PR strategy

Recommended merge order (each is an atomic, independently-verifiable PR):

1. **A1** (DATA_MAP doc) — no code risk; unblock regulatory review.
2. **E1** (dedupe `parseDateMs`) — pure refactor; trivial.
3. **D2** (weightChangeSpec branch tests) — pure test add; de-risks B1.
4. **→ PAUSE for confirmation before B1 (behaviour change).**
5. **B1** (fingerprint magnitude) — behaviour change; lands after D2 so the new
   branches are locked.
6. **B2** (reactivation/no-candidate tests) — locks the B1 behaviour.
7. **A2** (audit logging) — backend; test-asserted.
8. **D1** (presentation policy tests) — pure Dart tests.
9. **C2** (safeguard card error handling + l10n + test).
10. **C1a** (hide `adjust` action — owner confirmed C1a).
11. **→ PAUSE for confirmation before (rescoped) C3 — Phase E prerequisite, owner decision.**
12. **C3** (full weight-context capture unit — rescoped; higher priority than
    the rest of C). If the owner defers, record the accepted interim risk
    explicitly (safeguards false-fire for vet-explained weight loss) and skip.
13. **D3** (harness runner + E2E) — largest; last.

**Resolved owner decisions:**
- C1: **C1a (hide)** — confirmed no external consumer; reversible one-line guard.
- C3: **rescoped** to the full weight-context capture unit; **owner decision
  still required** — build it now (Phase E prerequisite) or defer and accept
  the interim risk.

**Pause points (proceed to each only after confirmation):**
- Before **B1** (fingerprint magnitude behaviour change).
- Before **C3** (rescoped Phase E prerequisite).

## Out of scope (tracked separately, do not bundle)
- Analytics events for the suggestion funnel (acknowledged Phase C debt in the
  roadmap; needs its own observability PR with PostHog consent gating).
- Re-evaluating the writes-on-GET design in `syncPetSafeguards` (intentional
  re-evaluation; a sync-on-write refactor is a larger architectural change —
  raise separately if desired).
- `cim_evidence_view` surfacing `rules_fired`/`reasons` (calmness vs traceability
  trade-off; needs product input, not a bug).
