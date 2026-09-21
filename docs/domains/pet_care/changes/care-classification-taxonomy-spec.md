---
title: Care classification taxonomy — product & data spec
owner: Product / Agent
audience: both
status: draft
last_updated: 2026-09-21
tags: [pet_care, care_item, taxonomy, health_entry, spec]
---

# Care classification taxonomy — product & data spec

**Status:** Draft for review (product owner + engineering)  
**Supersedes (partially):** informal `type` + `care_family` dual-picker UX; §7 of [care-item-model-delivery-plan.md](./care-item-model-delivery-plan.md)  
**Related:** [care-progression.md](../features/care-progression.md) · [care-foundation-roadmap.md](./care-foundation-roadmap.md) · [terminology.md](../../../design/terminology.md)

---

## 0. How to use this document

| If you are… | Read |
|---|---|
| Reviewing product intent | §1–§3 |
| Implementing API / DB | §4–§6 |
| Building Flutter UI | §7–§9 |
| Wiring health-issue flows | §10 |
| Checking scope boundaries | §11–§12 |

**Hard rule:** one canonical taxonomy module (`CareTaxonomy`). No second enum, picker, or inference map in forms, filters, E2E helpers, or CIM templates.

---

## 1. Problem statement

Care entries today expose two user-facing fields that overlap:

| Field | Values | Role today |
|-------|--------|------------|
| `type` (`HealthEntryType`) | medication, preventive, vet_visit, other | Legacy coarse bucket; drives profile split, filters, routing |
| `care_family` (`CareFamily`) | 9 semantic families | Authoritative for icons, progression, intelligence, schedule anchors |

This is confusing because **`type` compresses multiple independent dimensions** (what, where, whether it was planned). Example: “preventive” spans vaccination (usually at the vet) and parasite prevention (usually at home) — different involvement, same legacy type.

Additionally, the product needs:

1. **Planned** care (due dates, rhythms, reminders) vs **unplanned** care (recorded after the fact — not necessarily urgent).
2. **Importance** for prioritising planned care (vaccines vs grooming) — separate from system notification `priority=urgent`.
3. **Health-issue linkage** prompts at natural moments (recorded visit, completed vet appointment).
4. A **single UI sub-component** so taxonomy never diverges again.

---

## 2. Product intent (settled)

1. **Hide `type` from users.** Server derives it for backward compatibility only.
2. **Care family is primary** — “what kind of care is this?”
3. **Care setting is secondary** — “where / who delivers it?” — soft default from family, always changeable.
4. **Care planning distinguishes intent** — planned vs unplanned (record). **Unplanned ≠ urgent.** A late-logged grooming is unplanned but routine.
5. **Care importance is always stored** — default from family, user may override in **both** planned and record flows. Never `null` on write (simplifies stats and queries).
6. **No urgent picker** on care entries. Urgency is handled in the real world before logging; the app records facts.
7. **Health-issue prompts** are contextual (§10), not a permanent form field overload.
8. **Do not introduce a new domain table.** Extend `health_entries` (and presentation) per [care-item-model-delivery-plan.md](./care-item-model-delivery-plan.md).

---

## 3. Classification model

### 3.1 Axes (orthogonal)

```text
┌─────────────────────────────────────────────────────────────┐
│  care_family     WHAT area of care (semantic, stable)         │
│  care_setting    WHERE / delivery context (soft default)    │
│  care_planning   PLANNED vs UNPLANNED (scheduling intent)   │
│  care_importance ESSENTIAL | RECOMMENDED | OPTIONAL         │
│                  (prioritisation weight — not urgency)      │
└─────────────────────────────────────────────────────────────┘
         │
         ▼ (server-derived, not user-facing)
  type: medication | preventive | vet_visit | other  (legacy compat)
```

### 3.2 `care_family` (existing enum — canonical list)

| Wire value | User label (EN) |
|------------|-----------------|
| `medication` | Medication |
| `vaccination` | Vaccination |
| `parasite_prevention` | Parasite prevention |
| `wellness_review` | Wellness review |
| `dental` | Dental care |
| `weight_monitoring` | Weight monitoring |
| `grooming` | Grooming |
| `nail_care` | Nail care |
| `other` | Other care |

**Not in scope for this spec:** adding `urgent_care` as a family. Reactive care uses existing families + `care_planning=unplanned`.

### 3.3 `care_setting` (new)

```text
home  |  vet  |  other
```

| Value | Meaning (UI copy) |
|-------|-------------------|
| `home` | At home (you administer) |
| `vet` | At the vet / clinic |
| `other` | Somewhere else (groomer, mobile service, etc.) |

**Policy:** taxonomy defines `default_setting` per family. UI pre-fills on family change. **All three values remain selectable always** — no server rejection of “unusual” combinations. Optional helper text when default is strong (e.g. vaccination: “Usually at the vet”).

### 3.4 `care_planning` (new)

```text
planned  |  unplanned
```

| Value | Meaning | Typical UX |
|-------|---------|------------|
| `planned` | Future or recurring care the pet parent intends to do | Due dates, recurrence, reminders |
| `unplanned` | Care that already happened; logged after the fact | `completed_on` required; no upcoming due; reminders off |

**Clarifications:**

- Unplanned includes emergencies **and** mundane late logs (grooming done without a prior plan).
- There is **no** `urgent` value and **no** urgent picker.
- Recurring entries (`frequency != once`) are always `planned`.
- `unplanned` entries use `frequency = once`.

### 3.5 `care_importance` (new)

```text
essential  |  recommended  |  optional
```

| Tier | Meaning | Example families (default) |
|------|---------|----------------------------|
| `essential` | Missing it has real health consequences | medication, vaccination, parasite_prevention |
| `recommended` | Should stay on track | wellness_review, dental, weight_monitoring |
| `optional` | Beneficial; low cost if delayed | grooming, nail_care, other |

**Policy:**

- **Always persisted** on create/update — default from taxonomy when client omits.
- **Editable in both** planned and record flows (chip or compact picker).
- Set `importance_overridden = true` when user changes away from family default (optional audit column).
- Used for: due-list sort, dashboard emphasis, away-planning load hints, analytics — **not** for notification `priority=urgent`.

**Distinction from notifications:**

| Concept | Scope |
|---------|--------|
| `care_importance` | Care entry scheduling / prioritisation |
| `notifications.priority = urgent` | System/admin alerts (agreement withdrawal, etc.) — unchanged |

---

## 4. Taxonomy registry (single source of truth)

### 4.1 Location (proposed)

```text
shared/care_taxonomy.json          # canonical definitions
  → codegen or mirrored tests to Dart + Node

flutter_app/.../care_taxonomy/     # registry + UI component
server/lib/care/taxonomy/          # validation + deriveLegacyType
```

### 4.2 Per-family definition shape

```json
{
  "vaccination": {
    "default_setting": "vet",
    "default_importance": "essential",
    "derived_legacy_type": {
      "home": "preventive",
      "vet": "preventive",
      "other": "preventive"
    },
    "filter_group": "prevention",
    "capabilities_ref": "vaccination"
  }
}
```

### 4.3 Default matrix (v1 — `OPEN` for product sign-off)

| Family | `default_setting` | `default_importance` |
|--------|-------------------|----------------------|
| medication | home | essential |
| vaccination | vet | essential |
| parasite_prevention | home | essential |
| wellness_review | vet | recommended |
| dental | vet | recommended |
| weight_monitoring | home | recommended |
| grooming | other | optional |
| nail_care | other | optional |
| other | other | optional |

### 4.4 Legacy `type` derivation

Server function: `deriveLegacyType(care_family, care_setting) → type`

- Implemented **only** in taxonomy module.
- Called on every write; stored in `health_entries.type` for compat.
- Clients stop sending `type` in a later phase.
- Lossy mapping is acceptable — `type` is deprecated.

**Suggestion for reviewer:** publish the full derivation table in `shared/care_taxonomy.json` rather than ad hoc switches in CRUD handlers.

---

## 5. Database & API

### 5.1 New columns on `health_entries`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `care_setting` | `VARCHAR(20)` | NOT NULL | `'home'` (backfill per family) |
| `care_planning` | `VARCHAR(20)` | NOT NULL | `'planned'` |
| `care_importance` | `VARCHAR(20)` | NOT NULL | from taxonomy on write |
| `importance_overridden` | `BOOLEAN` | NOT NULL | `false` |

Existing: `care_family`, `type`, `health_issue_id`, `frequency`, `next_due_date`, `completed_on`, `remind_days_before`.

### 5.2 Write payload (client → API)

```json
{
  "care_family": "grooming",
  "care_setting": "other",
  "care_planning": "unplanned",
  "care_importance": "optional",
  "frequency": "once",
  "completed_on": "2026-09-18",
  "health_issue_id": null
}
```

- `type` **optional** on write during migration; server overwrites with derived value.
- If `care_importance` omitted → server applies family default.
- If `care_setting` omitted → server applies family default.

### 5.3 Validation rules

| Rule | Enforcement |
|------|-------------|
| `care_family` required on create | existing |
| `care_setting` ∈ {home, vet, other} | server |
| `care_planning` ∈ {planned, unplanned} | server |
| `care_importance` ∈ {essential, recommended, optional} | server; default if omitted |
| `unplanned` → `completed_on` required | server |
| `unplanned` → `next_due_date` must be null | server |
| `unplanned` → `remind_days_before = 0` | server default |
| `planned` + recurring → recurrence fields per existing rules | server |
| `frequency != once` → `care_planning` must be `planned` | server |

### 5.4 Backfill strategy

1. Add columns with defaults.
2. Set `care_setting` from family default matrix.
3. Set `care_planning = planned` for rows with `next_due_date` or recurring frequency; `unplanned` for completed one-offs with no future due (heuristic — `OPEN` threshold).
4. Set `care_importance` from family defaults.
5. Recompute `type` via `deriveLegacyType`.

---

## 6. CIM & recommendations cleanup

- Deprecate `suggested_health_entry_type` on `care_recommendations`.
- Templates specify `care_family`, `care_setting` (optional), `care_importance` (optional).
- Accept flow creates entries with explicit classification; server derives `type`.

**Phase:** after taxonomy module ships; separate atomic PR.

---

## 7. UI — `CareClassificationSection`

Single encapsulated sub-component used by add/edit/record flows.

### 7.1 Structure

```text
CareClassificationSection
├── PlanningToggle          [ Plan this care | Record what happened ]
├── FamilyPicker            9 families (icons from taxonomy)
├── SettingField            home | vet | other (default on family change)
└── ImportanceSelector      essential | recommended | optional
                            (shown for BOTH planning modes; defaults from family)
```

### 7.2 Behaviour by planning mode

| Control | Planned | Unplanned (record) |
|---------|---------|---------------------|
| Family | required | required |
| Setting | shown, default | shown, default |
| Importance | shown, default, overridable | shown, default, overridable |
| Schedule / recurrence | shown | hidden |
| Due date | shown | hidden |
| Completed date | optional until done | **required** |
| Reminders | per family/importance defaults | hidden / forced off |

### 7.3 Entry points

| Route / action | Initial state |
|----------------|---------------|
| Add care (default) | `planned`, family from context or blank |
| Record care | `unplanned`, completed date focused |
| From health issue | `planned` or `unplanned`, family suggested from issue context (`OPEN`) |
| CIM accept | from recommendation template |

### 7.4 Remove from form

- `HealthEntryType` dropdown — **remove from user-facing form**.
- Separate “Care category” label — merged into classification section (family picker).

---

## 8. Filters, lists, routing

### 8.1 Filters (replace type chips)

- **Primary:** filter by `care_family` (multi-select).
- **Secondary:** `care_setting = vet` (“At the vet”).
- **Tertiary:** `care_planning` (upcoming = planned + active due; history includes unplanned + completed).
- Sort planned dues: `care_importance` (essential first) → due date.

### 8.2 Routing unification

- Target: single add path `/pet/:petId/care/add` with query `?planning=unplanned` for record mode.
- Deprecate `/health/add` vs `/other/add` and `kHealthEventTypes` / `kOtherEventTypes` profile split.
- Unified list on pet profile sorted by relevance, not legacy type sections.

**Delivery:** separate PR after classification form ships.

---

## 9. Copy & terminology

| Internal | User-facing (EN) | Notes |
|----------|------------------|-------|
| `care_family` | Care type / Kind of care | Avoid “category” + “type” together |
| `care_setting` | Where | Subtitle explains options |
| `care_planning=planned` | Plan this care | |
| `care_planning=unplanned` | Record what happened | Not “Urgent” |
| `care_importance` | Priority | Or “How important is staying on track?” — `OPEN` copy review |
| `type` | *(hidden)* | Never shown |

Tone: calm, operational — per [copy-tone.md](../../../design/copy-tone.md). Importance explains sorting, not moral judgement.

---

## 10. Health-issue linkage prompts

Existing: `health_entries.health_issue_id` optional link; dropdown on form when single pet selected.

### 10.1 Prompt — unplanned record (especially vet)

**When:** user saves `care_planning=unplanned` with `care_setting=vet` OR families `wellness_review`, `dental`, `vaccination`.

**UI:** lightweight sheet after save (dismissible):

> “Was this visit related to a health issue?”  
> [ Link existing issue ] [ Add new issue ] [ Not related ]

- Link existing → pick from pet’s issues; set `health_issue_id` on entry.
- Add new → navigate to health-issue create with entry pre-linked.
- Not related → dismiss.

**Also consider** (lower priority): same prompt for unplanned `medication` (acute prescription course).

### 10.2 Prompt — planned vet visit completion

**When:** user marks completed a **planned** entry where `care_setting=vet` (or family ∈ {wellness_review, dental, vaccination}).

**UI:** after completion confirm:

> “Did the vet identify anything new to track?”  
> [ Add health issue ] [ Link existing ] [ No ]

**Re-planning nudge** (same sheet or follow-up):

> “Plan the next visit?” → pre-filled planned entry (family + setting from completed entry).

### 10.3 Neutering as health issue (interim)

Until procedures vs conditions taxonomy is sorted:

- Treat **neutering / spay** as a **health issue** title (e.g. “Neutering”) when relevant.
- CIM or completion prompts may suggest creating/linking this issue after surgical vet visits.
- Pet-level `neutered_date` remains separate profile data — do not conflate in this spec.

**Explicitly deferred:** full procedure taxonomy, SNOMED-like condition typing.

### 10.4 Suggested health-issue titles (prompt helpers — not enums)

Optional quick-pick chips on “Add health issue” from vet prompt:

- Injury or illness
- Dental problem
- Neutering / spay
- Other (free text)

`OPEN`: whether chips are v1 or free-text only.

---

## 11. Explicitly out of scope

| Item | Reason |
|------|--------|
| `urgent` picker on care entries | Urgency is pre-app; unplanned covers late logging |
| New `urgent_care` family | Use existing families + unplanned |
| Enforcing setting per family | Soft defaults only |
| New `CareItem` table | `health_entries` is the care item |
| Procedure vs condition taxonomy | Separate future work |
| Paywall / entitlement changes | `care_importance` ≠ entitlement |
| Notification priority redesign | Unchanged |

---

## 12. Delivery phases (suggested)

| Phase | Outcome | PR type |
|-------|---------|---------|
| **A** | `shared/care_taxonomy.json` + Dart/Node registry + contract tests | Foundation |
| **B** | DB migration + API validation + derive `type` | Backend |
| **C** | `CareClassificationSection`; hide type picker | Flutter |
| **D** | Record vs plan form behaviour + validation | Flutter |
| **E** | Health-issue prompts (§10.1–10.2) | Flutter + thin API if needed |
| **F** | Family-based filters; deprecate type filters | Flutter |
| **G** | Unified routing / single care list | Flutter |
| **H** | CIM: drop `suggested_health_entry_type` | Full-stack |

Each phase = one verifiable outcome ([atomic-pr-policy](../../../agent-efficiency/atomic-pr-policy.md)).

---

## 13. Open questions for review

1. **Backfill heuristic** for `care_planning` on legacy rows — is “completed once + no next due = unplanned” safe, or default all legacy to `planned`?
2. **Importance UI label** — “Priority”, “Importance”, or “How critical is staying on track?”
3. **Filter groups** — expose `filter_group` in taxonomy (prevention / clinical / lifestyle) for chip UI?
4. **Record entry point** — global FAB action vs pet profile only?
5. **Health-issue prompt scope** — vet-setting only, or all unplanned entries?
6. **Dental at home** — one family with setting `home` for home hygiene, or defer until procedure split?
7. **API breaking change** — when to stop accepting client-sent `type`?

---

## 14. Suggestions included for reviewer consideration

1. **Store importance always** (product owner confirmed) — prefer server-side default on omit over nullable + inference on read.
2. **Keep setting always editable** — avoids false precision and support burden; defaults handle 95% case.
3. **Separate planning from urgency** — use `care_planning=unplanned` for all post-hoc records; reserve future `tags` if episodic severity is ever needed for timeline analytics.
4. **Prompts over permanent fields** — health-issue linkage at save/completion reduces form noise.
5. **Codegen taxonomy** — prevents third inference map in Playwright (`inferCareFamilyFromType` today).
6. **Involvement score (future)** — optional derived field `estimated_effort: low|medium|high` from `(family, setting)` for away-planning; not v1 UI.
7. **Completion → issue → re-plan chain** — treat as a small state machine in the form controller, not scattered `Navigator` calls.

---

## 15. Acceptance criteria (v1 complete)

- [ ] User never sees `type` on add/edit/record forms.
- [ ] Every new/updated entry has non-null `care_family`, `care_setting`, `care_planning`, `care_importance`.
- [ ] Record flow requires `completed_on`; no due date or reminders.
- [ ] Taxonomy defaults match §4.3 matrix; single JSON/registry source.
- [ ] `deriveLegacyType` has contract tests (Dart ↔ Node).
- [ ] Vet unplanned save shows health-issue prompt (dismissible).
- [ ] Planned vet completion shows health-issue + optional re-plan prompt.
- [ ] No urgent picker anywhere in care entry flows.
- [ ] Filters use family (type chips removed or deprecated).

---

## Appendix A — Example records

**Planned vaccination**

```json
{
  "care_family": "vaccination",
  "care_setting": "vet",
  "care_planning": "planned",
  "care_importance": "essential",
  "frequency": "yearly",
  "next_due_date": "2027-04-01",
  "remind_days_before": 7
}
```

**Unplanned grooming (late log, not urgent)**

```json
{
  "care_family": "grooming",
  "care_setting": "other",
  "care_planning": "unplanned",
  "care_importance": "optional",
  "frequency": "once",
  "completed_on": "2026-09-15"
}
```

**Unplanned emergency vet (still no urgent flag)**

```json
{
  "care_family": "wellness_review",
  "care_setting": "vet",
  "care_planning": "unplanned",
  "care_importance": "recommended",
  "frequency": "once",
  "completed_on": "2026-09-20",
  "health_issue_id": "…"
}
```

---

*End of spec — comments welcome from engineering and review agents.*
