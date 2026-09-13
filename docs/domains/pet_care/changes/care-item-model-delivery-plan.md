---
title: Care Item Model & Pet Profile Care Surface — Delivery Plan
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-13
tags: [pet_care, care_item, pet_profile, delivery, ui]
---

# Care Item Model & Pet Profile Care Surface — Delivery Plan

**Roadmap plan:** `.agents/plans/pet-care-item-model.md`
**Canonical product behaviour:** [care-progression.md](../features/care-progression.md) · [care-entitlements.md](../features/care-entitlements.md)
**Terminology authority:** [docs/design/terminology.md](../../../design/terminology.md)
**Design system:** [docs/design/system.md](../../../design/system.md) · [docs/design/copy-tone.md](../../../design/copy-tone.md)

---

## 0. How to use this document

This is the **single source of truth** for the Pet Profile care refactor. It was produced from an
analysis-and-challenge cycle with the product owner; every decision below is **settled** unless
marked `OPEN`. Implementation is split into seven child plans under `.agents/plans/`, driven by the
roadmap plan `pet-care-item-model`.

| If you are… | Read |
|---|---|
| Implementing a phase | §1 product intent, then the child plan for your phase, then the relevant §2–§12 contract |
| Deciding a name or a string | §4 naming table — do **not** invent copy |
| Building UI | §5 component contracts + §10 accessibility |
| Touching status/urgency logic | §6 status contract |
| Touching `care_family` | §7 taxonomy contract |
| Tempted to add something not listed | §13 explicitly rejected — check there first |

**Hard rule for implementers:** this refactor is **presentation and terminology**, not a new domain
object. `health_entries` already *is* the care item (series/template); `health_occurrences` already
*is* the dated instance. Do not introduce a new `CareItem` table, route family, or Dart entity that
duplicates them. Renaming at the presentation boundary is in scope; re-modelling is not.

---

## 1. Product intent

> The Pet Profile should read as a concise, intelligent picture of the pet's **current care
> situation** — not a menu of features.

Consequences that drive every decision below:

1. **One user-facing concept: a Care Item.** It may be one-off or recurring. "Care Routine" and
   "Care Rhythm" stop being user-facing objects. Recurrence becomes an *attribute* of a Care Item.
2. **One operational section: `{Pet}'s care`.** Care Items are grouped **temporally** (needs
   attention / today / upcoming), never by type or by recurring-vs-one-off.
3. **Attention is derived, not a feature.** "Time to follow up" becomes an attention state *inside*
   `{Pet}'s care`, not its own card.
4. **Everything else gets quieter.** Weight becomes a compact insight tile. Health Issues and
   Timeline move into a low-emphasis "Health & history" area. Completeness prompts collapse to one
   compact treatment.
5. **Visual treatment follows purpose, not domain.** Four roles only: Attention, Action, Insight,
   Destination (§5).

### Information architecture (preserved)

```
Pet Profile  →  All care  →  Care Item detail  →  Edit / Add care
```

---

## 2. What already exists (do not rebuild)

Verified against `main` at plan authoring time. Confirm with a quick read before you rely on it.

| Concept | Where it already lives | Note |
|---|---|---|
| Care item / series | `health_entries` table; `server/routes/healthEntries/**` | Carries `frequency`, `frequency_interval`, `recurrence_anchor`, `repeat_end_date`, `schedule_times` |
| Dated instance | `health_occurrences` table | Materialised from the series |
| Unified add/edit form | `flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart` | Already one entry point; recurrence is already a field, not an upfront fork |
| "All care" destination | `flutter_app/lib/features/pet_profile/presentation/screens/pet_manage_events_screen.dart` | Already unifies recurring + one-off |
| Establishment / progression | `care_establishments`, `care_milestones`; `server/lib/care/progression/weightEstablishmentPolicy.js`; `server/lib/care/capabilities.js` | `supportsEstablishment` is **weight_monitoring only** today |
| Contextual-card arbitration on profile | `flutter_app/lib/features/pet_care/presentation/pet_care_presentation_policy.dart` | `profileSafeguard` / `profileSuggestion` / `profileMilestoneMoment` **already** guarantee at most one card. The problem is *placement and treatment*, not arbitration. |

**Therefore in scope:** presentation composition, a shared component/token layer, status
consolidation, `care_family` correctness, and copy. **Not in scope:** a new care entity.

---

## 3. Root problem not named in the original brief

Care status/urgency is derived in **at least four** independent places with **three different
vocabularies**:

| Derivation | Location | Vocabulary |
|---|---|---|
| Pet-level status | `flutter_app/lib/features/pet_profile/domain/services/care_status_service.dart` → `CareStatus` | `allSet` / `worthACheck` / `timeToFollowUp` |
| Dashboard urgency | `petCareTodayCareUrgency` provider | urgency tiers |
| Occurrence zone | `OccurrenceZone` | zone buckets |
| Server open-occurrence shaping | `listOpenOccurrences` | overdue/due/upcoming |

Grouping Care Items temporally on the profile means the profile **must** agree with the list
destination and with the dashboard. Consolidating this is **Child A** and is a prerequisite for the
UI work — not a nice-to-have. Building the new section on top of four derivations would guarantee
"needs attention" on the profile disagreeing with "overdue" in All care.

---

## 4. Naming and copy (canonical — do not deviate)

### 4.0 Verified current state — read this before proposing any name

All of the following was read off `main` at plan authoring time. **Do not work from memory of how
this "should" be.**

**`docs/design/terminology.md` D38 (Pet Care workspace labels) as it actually stands:**

| Surface | EN | FR | ARB keys (**target**, mostly not yet real) |
|---|---|---|---|
| Workspace | Pet Care | Suivi | `drawerPetCare`, `experiencePetCareView` |
| Dashboard pet rail | My Pets | Mes animaux | `myPets` |
| Due-items block | **CARE ACTIONS** (eyebrow) | SOINS | `careActionsEyebrow` or `careEyebrow` |
| Full due list link | **All Actions** | **Tous les soins** | `allActions` |
| Bottom nav | Actions | Soins | `actionsNavLabel` |
| Passed-away pets section | Rainbow bridge | Au-delà des nuages | `rainbowBridge` |

D38's key column is **aspirational**. Real keys today: `allActions` → **absent** (the real key is
`allCare`); `actionsNavLabel` → **absent** (the real key is `careNavLabel`); `careActionsEyebrow` →
absent, but `careEyebrow` exists.

**Actual `app_en.arb` / `app_fr.arb` values:**

| Key | `en` | `fr` |
|---|---|---|
| `careForPet` | `Care for {petName}` | `Soins pour {petName}` |
| `allCare` | `All Actions` | `Tous les soins` |
| `careNavLabel` | `Actions` | **`Soins`** |
| `manageEvents` | `Manage events` | `Gérer les événements` |
| `eventsNavLabel` | `Events` | `Événements` |

**`allCare` is one key serving two different scopes** — this is the bug at the heart of the
"two vocabularies" problem:

| Call site | Scope |
|---|---|
| `pet_events_preview_section.dart` (×2) | **pet-scoped** — profile preview's "see all" |
| `pet_care_upcoming_events_section.dart` (×2) | **global** — Pet Care dashboard's "see all" |

`manageEvents` likewise serves two scopes: the pet-scoped list screen title
(`pet_manage_events_screen.dart`) **and** the pet event view screen title
(`pet_event_view_screen.dart`, ×3 — which Child E turns into Care Item detail).

**Two consequences that kill earlier candidate names:**

1. **`Care actions` cannot be the global screen title** — D38 already uses `CARE ACTIONS` as the
   *dashboard due-items block eyebrow*. Reusing the words for a whole screen recreates exactly the
   ambiguity this refactor exists to remove.
2. **EN and FR already diverge:** EN says *Actions*, FR says *Soins* (= care). So the pet-scoped
   `All care` reads as distinct from global `All Actions` in **EN only**. In **FR** both would be
   `Tous les soins`. The FR needs a disambiguator that EN gets for free — see **O4**.

### 4.1 Surface names

| Surface | Scope | EN title | Change |
|---|---|---|---|
| Profile operational section | one pet | **`{Pet}'s care`** | `careForPet` value change |
| Section's trailing link | one pet | **`View all care`** | **new** key; splits off `allCare` |
| Pet-scoped list destination | one pet | **`All care`** | **new** key; replaces `manageEvents` here |
| Global dashboard "see all" link | all pets | **`All Actions`** (unchanged) | keeps `allCare` |
| Global cross-pet queue screen (`/pc/events`) | all pets | **`All Actions`** — reuse `allCare` | replaces `eventsNavLabel` as the title |
| Bottom nav | all pets | **`Actions`** (unchanged) | `careNavLabel` untouched |

**The global vocabulary does not change.** Titling the global screen with the same string as the
link that leads to it (`All Actions`) is more coherent than today's `Events`, costs no new key, and
keeps D38 intact for every global surface.

Rejected: `All of {Pet}'s care` (verbose, per product owner). Rejected: `Care actions` for the
global screen (collides with the D38 eyebrow, §4.0). Rejected: reusing `All care` for the global
queue (it is a filtered work queue, not a complete catalogue).

**D38 amendment is now purely additive** — add the pet-scoped rows, and correct the key column to
name the real keys. This is a much lower governance risk than the contradiction an earlier draft of
this plan would have required. Child F must still land the amendment in the **same PR** as the
strings, because `terminology.md` forbids ad-hoc string changes.

### 4.2 String keys

| Key | Action | `en` value |
|---|---|---|
| `careForPet` | **change value** | `{petName}'s care` (was `Care for {petName}`) |
| `viewAllCare` | **new** | `View all care` — used by the **pet-scoped** preview link only |
| `allCareTitle` | **new** | `All care` — pet-scoped list screen title |
| `allCare` | **keep key and value** | `All Actions` — now the **global** link *and* the global screen title |
| `careNavLabel` | unchanged | `Actions` |
| `manageEvents` | **retire** | pet-scoped list → `allCareTitle`; pet event view → Care Item detail title (Child E) |
| `eventsNavLabel` | **retire** | all three call sites are titles/headers, not nav |
| `careRhythmsTitle`, `careRhythmsSubtitle`, `careRhythmsEmpty`, `careRhythmNextDue` | **retire** | after the Care Rhythms screen is removed (Child E) |

`fr`: **read the existing `app_fr.arb` entry before writing** — several care strings were hand-tuned
and the EN/FR vocabularies already diverge (§4.0).

- `careForPet` → keep the existing `Soins pour {petName}` or refine to `Soins de {petName}`; it
  already reads possessively.
- `viewAllCare` → `Voir tous les soins`
- `allCareTitle` → `Tous les soins de {petName}` (O4 resolved — must **not** be `Tous les soins`,
  which is already `allCare`'s FR value for the global surface).

### 4.3 "Occurrence" in user-facing copy

`occurrence` appears in user-facing strings. It is domain jargon and must go — but by **semantic
migration, not find-and-replace**. Each string gets the word that fits its sentence:

| Context | Replacement |
|---|---|
| A single dated instance of a recurring item | *"this one"* / *"this date"* / the date itself |
| The list of instances on Care Item detail | **`Dates`** |
| A skipped/missed instance | *"skipped"* / *"missed"* |
| A completed instance | *"done"* |

Blind replacement produces sentences like "Delete this dates". Child F owns this; every changed
string must be read in its rendered sentence.

### 4.4 Progression copy

Per `copy-tone.md` and `care-progression.md`: only **positive, settled** states are shown.

| State | Copy | Where |
|---|---|---|
| Established | **`Established`** badge + `Part of {Pet}'s regular care.` | Care Item detail; subtle chip in lists |
| Not yet established | **nothing** | — |

**"Building pattern" must not be surfaced.** The original brief asked for it; `care-progression.md`
explicitly forbids showing negative or uncertain progression states, and showing "building" invites
the gamification the brief also rules out. Do not add it. Do not show streak counts, day counts, or
"3 of 4 to go".

---

## 5. Component contracts — the four semantic roles

**Child B builds these before any screen changes.** Screen phases consume them and must not
hand-roll an equivalent. This is the mechanism that stops the four visual treatments drifting apart
across surfaces.

Location: `flutter_app/lib/features/pet_care/presentation/widgets/care_surface/`

| Role | Widget | Purpose | Visual rules |
|---|---|---|---|
| **Attention** | `CareAttentionCallout` | Something needs the carer now | Semantic *foreground* for text/icon + **subtle** semantic background fill; never a saturated banner. Compact height. At most one per screen region. |
| **Action** | `CareActionRow` | A Care Item the carer can act on | List row: leading family icon, title, temporal subtitle, trailing primary affordance. Neutral surface. Status conveyed by **text + icon**, never colour alone. |
| **Insight** | `CareInsightTile` | A read-only derived fact (e.g. weight trend) | Low-emphasis card, no primary affordance, tappable as a whole to its destination. Hosts `CareTrendSparkline`. |
| **Destination** | `CareDestinationRow` | Navigation to a quieter area | Minimal: label + chevron. No counts unless the count is the point. No card chrome. |

Plus:

| Widget | Purpose |
|---|---|
| `CareTrendSparkline` | Small trend line for the weight insight tile. Must render a meaningful empty/insufficient-data state, not a flat line. |
| `CareSurfaceTokens` | The spacing/radius/emphasis constants the four roles share, resolved from `AppColorTokens` / `ColorScheme`. **No new raw colour literals.** |

Contract requirements:

- Every widget takes its strings from the caller (l10n at the call site), so the primitives stay
  copy-agnostic.
- Every interactive primitive exposes a `Key` for E2E and a semantic label for a11y.
- Widget tests for each primitive, including the empty/insufficient states.
- These files are new; if any exceeds 500 lines it must be split, not allowlisted.

---

## 6. Status derivation contract (Child A)

**Goal:** one derivation, consumed everywhere; one vocabulary at the presentation boundary.

1. Introduce a single pet-scoped care-status service that produces the **temporal grouping** the
   profile, All care, and the dashboard all consume:
   - `needsAttention` — overdue, or an attention state such as *time to follow up*
   - `today` — due today and not yet done
   - `upcoming` — due after today, within the section's horizon
2. Keep `CareStatus` (`allSet` / `worthACheck` / `timeToFollowUp`) only if it is still the pet-level
   *summary*; it must be **computed from** the new grouping, not in parallel with it.
3. `petCareTodayCareUrgency` and `OccurrenceZone` must be expressed in terms of the new grouping or
   deleted. Leaving them as independent derivations fails the phase.
4. The server's `listOpenOccurrences` shaping is the **authority for dates**; the client derives
   grouping from it and must not re-implement due-date maths.
5. Optimistic completion must move an item out of its group immediately and reconcile on
   confirmation — the current behaviour must not regress.

**Exit evidence:** a test that asserts the same care item lands in the same group when read through
the profile provider, the All-care provider, and the dashboard provider.

---

## 7. `care_family` taxonomy contract (Child C)

### The problem

`inferCareFamilyFromType` in `server/routes/healthEntries/shared.js` guesses `care_family` from the
coarse `type` field (`medication` / `preventive` / `vet_visit` / `other`). The guess is frequently
wrong, and progression and intelligence both key off `care_family`. Building family-aware UI on top
of a bad inference propagates the error into the interface.

### The decision: make unknown honestly unknown

1. **Remove the inference.** Do not replace it with a better guess.
2. **Backfill deterministically** — only where the mapping is unambiguous. Rows that cannot be
   determined become explicitly uncategorised.
3. **Make `care_family` required on create** at the API boundary.
4. **On edit of an uncategorised item:** *suggest and confirm*, never force. Pre-select the most
   likely family, show it as a suggestion, let the carer accept or change it. A forced modal on an
   unrelated edit is hostile.
5. **Uncategorised items still work.** They appear in `{Pet}'s care` and All care, are completable,
   and simply do not participate in family-specific progression or intelligence.

### Risk — read before starting

Making `care_family` required is a **breaking API change** for older clients. This needs explicit
governance sign-off (see the child plan's escalation note) and must not be bundled with UI work.
Confirm the migration ordering: backfill and tolerate-missing **ship before** the required-field
enforcement.

---

## 8. Care Intelligence placement (Child D)

Arbitration already exists (§2). What changes is **treatment by kind** — safeguards and
suggestions are not the same thing and must not share a slot:

| Kind | Treatment | Placement |
|---|---|---|
| **Safeguard** (something may be wrong) | `CareAttentionCallout`, compact | **Above** `{Pet}'s care` |
| **Suggestion** / **Milestone moment** (something could be better / something good happened) | One contextual card | **Below** `{Pet}'s care` |

A safeguard buried under the care list is a safety problem. A suggestion above it competes with the
carer's actual work. Keep the existing single-card arbitration for the lower slot; the safeguard
slot is separate and also at-most-one.

---

## 9. Pet Profile composition (Child D)

Top-to-bottom, desktop and mobile share this order; only density and columns change.

| # | Region | Role | Notes |
|---|---|---|---|
| 1 | Pet identity header | — | Unchanged |
| 2 | Completeness prompt | Attention (single, compact) | Collapse today's multiple prompts into **one** compact treatment. Dismissible. |
| 3 | Safeguard slot | Attention | At most one; only when a safeguard is active (§8) |
| 4 | **`{Pet}'s care`** | Action | Temporal groups (§6); `View all care` trailing link; **the operational centre of the screen** |
| 5 | Suggestion / milestone slot | Insight-ish contextual card | At most one (§8) |
| 6 | Weight | Insight | Compact tile + `CareTrendSparkline`; taps through to weight detail |
| 7 | **Health & history** | Destination | Quiet group: Health issues, Timeline. Minimal rows, no cards. |

Removed from the profile: the standalone "Time to follow up" card (becomes a state inside #4) and
the Care Rhythms navigation row (concept retired, §4.2).

### Responsive behaviour

- **Mobile:** single column, order as above.
- **Tablet:** single column, wider gutters; the weight insight may sit beside Health & history if it
  does not push `{Pet}'s care` below the fold.
- **Desktop:** `{Pet}'s care` keeps the primary column; insight + destination regions may move to a
  secondary column. `{Pet}'s care` must remain the largest, highest element in every breakpoint.

**Non-negotiable:** at no breakpoint may anything outrank `{Pet}'s care` visually.

### Why this is split across two phases

`pet_detail_screen.dart` is already near the 500-line cap and the widget tree order is load-bearing
for existing tests. Child D therefore lands (1) the new `{Pet}'s care` section behind its own widget
with tests, then (2) the profile recomposition that adopts it and demotes the rest. Doing both in
one PR makes the diff unreviewable and the file-size gate unmeetable.

---

## 10. Accessibility requirements

A **pre-existing defect** must be fixed rather than propagated:
`healthEntryStatusColor()` in
`flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_status.dart` returns the
warning colour for small text on a light surface. That combination **fails contrast**.

Rules for all care surfaces:

1. Status must be conveyed by **text + icon**, never colour alone.
2. Where a status needs colour, use the semantic **foreground** for the glyph/text and a **subtle
   semantic background** behind it — do not paint text in the raw semantic colour.
3. All new interactive controls carry semantic labels (`accessibility.mdc`).
4. Tap targets meet the existing minimum in `system.md`.
5. The sparkline is decorative; the tile's semantic label must state the trend in words.

---

## 11. Seed / fixture recipe

Required so every implementer and reviewer sees the same profile. Child A lands it; later phases
use it.

One pet with:

| Care item | Purpose it demonstrates |
|---|---|
| Recurring, overdue | `needsAttention` group |
| Recurring, due today, not done | `today` group |
| Recurring, due today, already done | done-state rendering |
| Recurring, due later this week | `upcoming` group |
| One-off, due today | one-off and recurring co-existing in one temporal group |
| Recurring, uncategorised `care_family` | uncategorised still works (§7.5) |
| Weight monitoring that genuinely **establishes** (see below) | `Established` badge + a real sparkline |
| An open health issue | Health & history destination is non-empty |

Plus a second, near-empty pet so empty states are reviewable.

### Making the weight item actually establish

Read from `server/lib/care/progression/weightEstablishmentPolicy.js` — do not guess these:

| Requirement | Value |
|---|---|
| Cadence band | `high`, which means interval **≤ 14 days** → use **weekly** recurrence |
| `minCompletedOccurrences` | **4** |
| `minSpanDays` | **21** |
| `minMeasurements` | **3** |

Only `weight_monitoring` has `supportsEstablishment: true` in `server/lib/care/capabilities.js`
(verified: exactly one match in the capability matrix). So the weight item is the **only** way to
see the `Established` treatment. If the fixture's weight item does not cross every threshold above,
no reviewer on any later phase can see that state at all.

---

## 12. Test and verification impact

| Area | Requirement |
|---|---|
| Widget tests | One per new primitive (§5), including empty/insufficient states |
| Provider tests | The cross-surface grouping agreement test (§6) |
| Server tests | `care_family` backfill + required-field enforcement (Child C) |
| BDD | Update the Gherkin scenarios that assert the retired profile rows and the old section title. `node e2e/scripts/check_bdd_coverage.js --report-only` must not regress. |
| Playwright | Selectors keyed to retired copy/rows will break. Fix them in the phase that retires the row — never in a later "cleanup" phase. |
| A11y | Contrast check on the fixed status treatment (§10) |
| File size | `node scripts/check_file_size.js`. New files must be split, not allowlisted. |

---

## 13. Explicitly rejected — do not re-add

Recorded so a later implementer does not "helpfully" restore them.

| Idea | Why rejected |
|---|---|
| `Care actions` as the global screen title | Collides with D38's existing `CARE ACTIONS` dashboard eyebrow (§4.0) |
| Retitling any **global** care surface | The global vocabulary is coherent once the screen reuses `All Actions`; changing it means a contradictory D38 amendment for no gain (§4.1) |
| A new `CareItem` table / entity | `health_entries` already is it (§2). Duplication, not simplification. |
| "Building pattern" / progress-toward-established UI | Forbidden by `care-progression.md`; invites gamification (§4.4) |
| Streaks, counts, scores, badges beyond `Established` | Brief explicitly rules out gamification |
| Grouping `{Pet}'s care` by type or by recurring-vs-one-off | Defeats the single-Care-Item mental model (§1.2) |
| `All of {Pet}'s care` as the destination title | Verbose (§4.1) |
| Reusing `All care` for the global `/pc/events` queue | It is filtered, not complete (§4.1) |
| A better `care_family` inference heuristic | Wrong guesses are worse than honest unknowns (§7) |
| Forced family-selection modal on edit | Hostile; suggest-and-confirm instead (§7.4) |
| Keeping "Time to follow up" as its own card | It is a derived state, not a feature (§1.3) |
| Allowlisting a new file past 500 lines | Governance; split instead |

---

## 14. Open items

| # | Item | Status |
|---|---|---|
| O1 | D38 amendment wording in `terminology.md` | **Open** — lands in Child F; product owner should skim the diff |
| O2 | Governance sign-off for the breaking `care_family` required-field change | **Resolved 2026-09-13** — product owner approved; `care-family-required` may proceed when its prerequisites are met |
| O3 | Whether the tablet breakpoint moves the weight tile beside Health & history | **Open** — decide with a real screenshot in Child D phase 2 |
| O4 | FR title for the pet-scoped `All care` destination | **Resolved 2026-09-13** — `Tous les soins de {petName}` (see §4.2) |

### O4 — the French collision (resolved)

EN distinguishes the two destinations for free (`All care` vs `All Actions`). FR does not: `allCare`
is already `Tous les soins` for the **global** surface, so the pet-scoped destination needs a
different FR string.

Candidates, best first:

1. **`Tous les soins de {petName}`** — unambiguous, uses the pet name the screen already has in
   context. Accepts an EN/FR asymmetry (EN stays the short `All care`). Recommended.
2. **`Soins de {petName}`** — shorter, but then the destination and the profile section share a
   title.
3. **Retitle the global FR surface instead** — rejected: it means a contradictory D38 amendment
   (§4.1) and touches a surface this refactor otherwise leaves alone.

**Decision (2026-09-13):** option 1 — `Tous les soins de {petName}` for `allCareTitle` in `app_fr.arb`.
Child F phase 1 uses this value.
