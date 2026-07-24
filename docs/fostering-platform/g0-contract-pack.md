# G0 — Platform contract pack (fostering & adoption)

**Status:** Draft baseline for agent handoff  
**Last updated:** 2026-07-24  
**Supersedes:** informal journey boundaries only — does not replace `docs/org-fostering-strategy.md` until journey delivery begins.

This document is the **platform contract layer**. Journey agents (J1–J5) must reference G0 instead of redefining shared rules. G1 (document and compliance artefact packs) depends on stable hooks defined here and implemented in J3/J5.

---

## 1. Design invariants

These are non-negotiable architectural rules. Any journey spec or PR that violates them must be rejected or escalated.

| # | Invariant |
|---|-----------|
| I1 | **One foster person model** — a human is represented once at platform level (`Foster profile`), regardless of how many shelters they work with. |
| I2 | **One shelter–foster relationship model** — approval, local screening, and shelter-confirmed data live on a per-shelter relationship, not on the global profile alone. |
| I3 | **One fostering session / active placement model** — evolve `foster_placements`; never run a parallel placement universe. |
| I4 | **At most one open fostering session per pet** — never more than one session in a non-terminal workflow state for the same pet at the same time. |
| I5 | **One adoption legal workflow** — Feature 5 supersedes legacy placement-embedded adoption completion; do not maintain two adoption paths long term. |
| I6 | **One org-local lightweight prospect model (v1)** — prospects are owned by the creating shelter only; no cross-shelter prospect directory in v1. |
| I7 | **Participant comments ≠ staff notes** — separate fields, separate storage, separate access rules everywhere (platform-wide). |
| I8 | **Indirect collection requires transparency at first contact** — manual foster and prospect records must send Art. 14-style notice on first outreach (source, purpose, rights, opt-out). |
| I9 | **Global reusable data ≠ shelter-local data** — never mix in one field or expose local screening data across shelters. |
| I10 | **Calendar dates on the wire** — `YYYY-MM-DD` for all user-facing dates (`docs/calendar-dates.md`). |

---

## 2. Canonical vocabulary

Use these terms consistently in specs, APIs, UI copy keys, audit events, and agent briefs. Avoid overloaded words like “foster” or “placement” without a qualifier.

| Term | Definition | Owner journey |
|------|------------|---------------|
| **Foster profile** | Global, reusable person data (housing, household, species capacity, self-declared competencies, availability). May exist without any shelter approval. | J1 |
| **Shelter–foster relationship** | Shelter-local link between one shelter and one foster profile: approval state, shelter questionnaire answers, shelter-confirmed competencies, staff notes, archive state, manual-entry provenance. | J1 |
| **Approved foster** | A shelter–foster relationship in `approved` approval state. Required for matching requests (J2) unless an explicit exception is documented in a journey spec. | J1 |
| **Manual foster record** | Shelter-local foster profile created by staff without a registered user account; may later merge into a registered account. | J1 |
| **Fostering session** | The formal temporary placement record for one pet with one foster under one shelter. Evolves `foster_placements`. | J3 |
| **Foster request** | Structured outreach from shelter to foster (one or more pets); not a session. | J2 |
| **Foster request response** | Foster’s structured reply to a request (`can_help` / `cannot_help` + follow-up fields). | J2 |
| **Preparation** | Session phase before active care: checklist, documents, prerequisites, ready-to-start. | J3 |
| **Prospect** | Org-local lightweight adopter record without a full user account. | J4 |
| **Adoption visit** | Scheduled meeting among pet, foster, adopter/prospect, shelter representative. Distinct from fostering session. | J4 |
| **Adoption journey** | Legal adoption workflow (certificate timing, contracts, transfer, finalisation). Supersedes legacy in-placement adoption states. | J5 |
| **Org member role `foster`** | Existing org membership role granting app access and org contact visibility. **Not** the same as “approved foster” (see §4.3). | Platform auth |
| **Activity summary** | Derived label for Manage Fosters tabs (e.g. “Fostering”, “Recently fostered”) computed from J3 session state — **not** owned by J1. | J1 displays, J3 sources |
| **Participant comment** | Visible to all participants of a record (visit, session thread where applicable). | Per journey, G0 rules |
| **Staff note** | Shelter-internal only; never visible to foster/adopter/prospect. | Per journey, G0 rules |

### Forbidden synonyms

Do not introduce parallel names for the same concept:

| Do not use | Use instead |
|------------|-------------|
| Foster parent (new model) | Foster profile + shelter–foster relationship |
| Placement (ambiguous) | Fostering session |
| External foster (new model) | Manual foster record |
| Adopter lite / lead | Prospect |
| Shared notes / internal comments (mixed) | Participant comment OR staff note |

Legacy code may still say `FosterParent`, `foster_placements` during migration; new specs and user-facing copy use canonical vocabulary above.

---

## 3. Roadmap framing (Features 1–5 + G0/G1)

| Feature | Journey | One-sentence outcome |
|---------|---------|----------------------|
| **Feature 1** | J1 — Foster onboarding and approval | A person becomes an approved foster for a shelter with reusable global profile data and shelter-local screening. |
| **Feature 2** | J2 — Matching and requests | Shelters find suitable approved fosters and send structured requests with actionable responses. |
| **Feature 3** | J3 — Fostering sessions | A placement becomes a formal session with preparation, dual-confirmed start, active care, and governed end outcomes. |
| **Feature 4** | J4 — Adoption visits | Shelters schedule and record adoption visits during foster care and decide whether to move toward view-to-adopt. |
| **Feature 5** | J5 — Adoption conversion | A validated adoption path completes legal adoption and closes the fostering session as converted. |
| **G0** | Platform contract layer | This document — vocabulary, ownership, contracts, permissions, audit, merge, retention. |
| **G1** | Document and compliance artefact packs | Editable templates and register export; hooks only — no independent state model. |

---

## 4. Object ownership map

### 4.1 Primary ownership

| Object | Authoritative owner | Storage direction (v1) | Forbidden ownership |
|--------|---------------------|------------------------|---------------------|
| Foster profile | J1 | New table or evolve user profile extension | J2–J5 must not write global profile fields |
| Shelter–foster relationship | J1 | Evolve `org_foster_parents` + new approval/questionnaire columns or child tables | J2 must not mutate approval or staff notes |
| Foster request / response | J2 | New tables | J3 must not embed request payload in session |
| Fostering session | J3 | **Evolve `foster_placements`** | J1/J2/J4/J5 must not create parallel session tables |
| Session preparation checklist | J3 | Session-scoped rows or JSON with typed keys from G1 hook catalog | G1 must not define its own session states |
| Adoption visit | J4 | New table | J3 must not duplicate visit scheduling |
| Prospect | J4 | New org-scoped table | No global prospect index in v1 |
| Adoption journey | J5 | New workflow table(s); supersedes placement adoption statuses | J4 must not perform final adoption transfer |
| Document templates / packs | G1 | Template storage per shelter | G1 must not invent lifecycle states |

### 4.2 Consumes contract / read model from

Journey agents may only depend on **published read models or APIs**, not another journey’s internal tables.

| Consumer | Depends on contracts from | Read models consumed |
|----------|---------------------------|----------------------|
| J1 | G0 | — |
| J2 | G0, J1 | Approved foster list, capacity inputs, competency flags, activity summary inputs |
| J3 | G0, J1, J2 (optional entry) | Foster profile identity, shelter–foster relationship id, positive request response id |
| J4 | G0, J3 | Active or view-to-adopt session context, foster/pet ids |
| J5 | G0, J3, J4 | Session type, visit validation outcome, pet adoptability |
| G1 | G0, J3, J5 | Checklist item keys, adoption milestone keys — **hooks only** |

### 4.3 Org member role `foster` vs approved foster

**Decision (G0):** These are separate concepts and must remain separable in specs and UI.

| Concept | Meaning | Can exist without the other? |
|---------|---------|----------------------------|
| Org member role `foster` | App login + org membership with foster role permissions | Yes |
| Approved foster | Shelter–foster relationship with `approval_state = approved` | Yes |

Rules:

- Granting org role `foster` does **not** auto-approve for fostering operations.
- Approval does **not** auto-grant org membership; invite/accept is a separate flow.
- J1 spec must define whether approved fosters who are not org members receive foster-portal access via a different capability (e.g. placement/session participant) — to be detailed in J1, not redefined elsewhere.

### 4.4 Manage Fosters screen semantics (J1 + J3 contract)

| Concern | Owner |
|---------|-------|
| People list layout, invite/manual add, approval actions | J1 |
| Tab labels: New, Fostering, Recently fostered, Inactive, All | J1 UI |
| **Meaning** of Fostering / Recently fostered / Inactive | **Derived from J3 session read model** |
| Session detail, preparation, start/end | J3 |

J1 must not store duplicate activity flags. It queries a J3-published aggregate (e.g. `fostering_activity_summary` on shelter–foster relationship).

Suggested derived activity values (computed by J3, displayed by J1):

| Summary value | Rule (illustrative — J3 owns exact query) |
|---------------|------------------------------------------|
| `not_yet_placed` | Approved, no session in last N days |
| `in_preparation` | ≥1 session in preparation / ready-to-start |
| `actively_fostering` | ≥1 active session |
| `recently_ended` | Ended session within configurable window, none active |
| `inactive` | No open session and none recently ended |

---

## 5. Cross-journey contracts

### 5.1 J1 → J2: Approved foster read model

J1 exposes per shelter:

```json
{
  "shelter_foster_relationship_id": "uuid",
  "foster_profile_id": "uuid",
  "approval_state": "under_review | approved | declined | archived",
  "display_name": "string",
  "species_capacities": [{ "species": "cat", "declared": 2 }],
  "self_declared_competencies": ["elderly", "light_medical"],
  "confirmed_competencies": ["elderly"],
  "is_manual_record": true,
  "has_registered_account": false
}
```

J2 filtering uses `approval_state = approved` by default.

### 5.2 J1 + J3 → J2: Capacity read model

```
available_capacity(species) =
  declared_capacity(species)   -- from J1 foster profile
  - preparation_count(species) -- from J3 sessions in preparation + ready_to_start
  - active_count(species)      -- from J3 sessions in active
```

J2 owns the formula; J1 supplies declared capacity; J3 supplies session counts.

### 5.3 Competency taxonomy (v1 — frozen)

Single taxonomy, owned by G0, used by J1 (declare/confirm) and J2 (filter):

- `very_young`
- `elderly`
- `light_medical`
- `heavy_medical`
- `light_behavioural`
- `heavy_behavioural`

Matching rule: use `confirmed_competencies` when non-empty; else `self_declared_competencies`.

### 5.4 J2 → J3: Positive response handoff

When shelter accepts a positive foster request response, J3 creates a fostering session in `preparation`.

| Field | Required |
|-------|----------|
| `foster_request_response_id` | Yes, when session originated from request |
| `shelter_foster_relationship_id` | Yes |
| `pet_id` | Yes (one pet per session — see I4) |
| `session_type` | `standard_foster` \| `foster_in_view_to_adopt` |
| `earliest_availability` | From response |
| `capacity_confirmed_at` | From response timestamp |

Idempotency: one session per `(foster_request_response_id, pet_id)`.

**Multi-pet request rule (G0):** A single request may cover multiple pets. Each accepted pet produces a **separate** fostering session (or a separate preparation candidate). J2 owns fan-out; J3 owns session creation per pet.

### 5.5 J3 → J4: View-to-adopt bridge

J4 may schedule adoption visits when:

- Session `session_type = foster_in_view_to_adopt`, **or**
- J4 spec explicitly allows pre-session visits (open question — default **foster-context only** until J4 spec resolves).

J4 triggers view-to-adopt preparation only after visit validation — does not mutate session type without J3 contract.

### 5.6 J3 + J4 → J5: Adoption journey start

J5 **supersedes** legacy flows:

- `waiting_adoption_confirmation`
- `pending_adoption_conditions`
- in-placement `adopted` terminal state

J5 starts only when:

- Fostering session exists and is eligible, **and**
- J4 validation complete (if visit path), **or**
- Direct adoption path defined in J5 spec.

J5 close event: session → `converted_to_adoption` (new terminal state); triggers existing custody transfer / shadow semantics per `docs/architecture/org-custody-model.md`.

### 5.7 G1 hooks (no independent state)

G1 checklist keys are **references** on J3/J5 records:

| Hook kind | Example keys | Set by |
|-----------|--------------|--------|
| Session compliance item | `foster_contract_prepared`, `foster_contract_signed`, `information_document_delivered`, `veterinary_certificate_tracked`, `register_entry_created` | J3 |
| Session configurable prerequisite | `home_visit_completed`, `reference_call_completed` | J3 |
| Adoption milestone | `commitment_certificate_signed`, `adoption_contract_prepared`, `transfer_date_set` | J5 |

G1 supplies template content and export formats; J3/J5 own status transitions.

---

## 6. Fostering session evolution (J3 mandate)

**Title invariant:** J3 evolves `foster_placements` into **fostering sessions** — functional evolution with compatibility, not a second table plus parallel logic.

### 6.1 Status mapping (current → target)

| Current `foster_placements.status` | Target session status | Migration action |
|-----------------------------------|----------------------|------------------|
| `pending` | `preparation` or new `pending_acceptance` | Map: if no prep checklist existed → `pending_acceptance`; else `preparation` |
| `in_progress` | `active` | Direct map |
| `waiting_adoption_confirmation` | Adoption journey in progress (J5) | Migrate to J5 workflow row; session → `end_pending` or `adoption_in_progress` |
| `pending_adoption_conditions` | Adoption journey in progress (J5) | Same |
| `adopted` | `converted_to_adoption` | Terminal |
| `not_in_foster` | `cancelled` or `returned_to_shelter` | Infer from history where possible; else `cancelled` |

Exact mapping is finalised in `migration-appendix.md` before J3 agent starts. Agent must not invent a third status enum.

### 6.2 Target session statuses (J3 owned)

| Status | Terminal? |
|--------|-----------|
| `pending_acceptance` | No |
| `preparation` | No |
| `ready_to_start` | No |
| `active` | No |
| `end_pending_confirmation` | No |
| `returned_to_shelter` | Yes |
| `transferred` | Yes |
| `converted_to_adoption` | Yes |
| `cancelled` | Yes |

### 6.3 One active session per pet (I4)

Database today enforces one open row per pet for active placement statuses (`idx_foster_placements_one_active_pet`). J3 must preserve and extend this constraint to include `preparation`, `ready_to_start`, `active`, `end_pending_confirmation`, and adoption-in-progress states as defined in migration appendix.

Transfer flow: current session → `transferred` (terminal); new session created in `preparation` for receiving foster.

---

## 7. Permission catalog

Permissions are additive to org roles (`super_admin`, `admin`, `foster`). Default grants are journey-implemented; G0 owns names and semantics.

| Permission key | Description | Default grant |
|----------------|-------------|---------------|
| `manage_fosters` | Invite, manual add, archive shelter–foster relationships | super_admin, admin |
| `review_foster_onboarding` | Approve / decline onboarding submissions | super_admin, admin |
| `contact_fosters` | Phone/email/in-app request from foster card | super_admin, admin |
| `confirm_foster_competencies` | Shelter-confirmed competency flags | super_admin, admin |
| `manage_fostering_sessions` | Create, prepare, start, end sessions | super_admin, admin |
| `home_visits` | Mark configurable home-visit prerequisites | super_admin, admin |
| `adopter_screening` | Create/manage adoption visits, view prospects | super_admin, admin |
| `manage_adoption_visits` | CRUD visits, shared comments | super_admin, admin (+ assignable fosters per J4) |
| `start_adoption_journey` | Open Feature 5 workflow | super_admin, admin |
| `confirm_return_to_shelter` | Confirm physical return | super_admin, admin |
| `manage_document_templates` | G1 template administration | super_admin |

Foster role defaults: view own sessions, respond to requests, participant comments on own visits — detailed in journey specs, not expanded here.

---

## 8. Audit event catalog

All events use snake_case `event_type`, include `organization_id`, `actor_user_id`, `occurred_at`, and `subject_type` + `subject_id`.

| event_type | Subject | Emitted by |
|------------|---------|------------|
| `manual_foster_record_created` | shelter_foster_relationship | J1 |
| `foster_profile_submitted` | foster_profile | J1 |
| `foster_approval_granted` | shelter_foster_relationship | J1 |
| `foster_approval_declined` | shelter_foster_relationship | J1 |
| `foster_archived` | shelter_foster_relationship | J1 |
| `foster_merge_completed` | foster_profile | J1 |
| `indirect_contact_notice_sent` | shelter_foster_relationship or prospect | J1, J4 |
| `foster_request_sent` | foster_request | J2 |
| `foster_request_response_received` | foster_request_response | J2 |
| `fostering_session_created` | fostering_session | J3 |
| `session_checklist_item_updated` | fostering_session | J3 |
| `offline_signature_confirmed` | fostering_session | J3 |
| `session_start_confirmed_shelter` | fostering_session | J3 |
| `session_start_confirmed_foster` | fostering_session | J3 |
| `session_return_confirmed` | fostering_session | J3 |
| `session_transferred` | fostering_session | J3 |
| `prospect_record_created` | prospect | J4 |
| `prospect_merge_completed` | prospect | J4 |
| `adoption_visit_scheduled` | adoption_visit | J4 |
| `adoption_visit_outcome_recorded` | adoption_visit | J4 |
| `adoption_visit_validated` | adoption_visit | J4 |
| `adoption_journey_started` | adoption_journey | J5 |
| `adoption_certificate_signed` | adoption_journey | J5 |
| `adoption_finalised` | adoption_journey | J5 |
| `session_converted_to_adoption` | fostering_session | J5 |

---

## 9. Lightweight person merge framework (platform standard)

Applies to **manual foster records** (J1) and **prospects** (J4).

### 9.1 Required capture on manual create

| Field | Required |
|-------|----------|
| `created_by_user_id` | Yes |
| `created_at` | Yes |
| `creation_source` | `manual_shelter_entry` |
| `lawful_basis_attested` | Yes (admin attestation checkbox) |
| `organization_id` | Yes |

### 9.2 First-contact transparency (Art. 14)

Before or at first email/SMS to a manual record:

- Which shelter entered the data
- Why they are contacted
- What they can do (register, opt out, contact shelter)
- Link to privacy notice / rights

Reuse and extend existing `externalFosterNotice` pattern; J4 prospect notice is a sibling template, not a one-off.

### 9.3 Merge rules

| Rule | Behaviour |
|------|-----------|
| Survivor record | Registered user account + global profile wins |
| Duplicate detection | Email match (case-insensitive) suggests merge; phone secondary |
| Shelter-local data | Remains on shelter relationship / prospect row; re-link to survivor ids |
| Session history | Unchanged; foreign keys updated to survivor |
| Audit | `foster_merge_completed` or `prospect_merge_completed` with `merged_from_id`, `merged_into_id`, `actor_user_id` |
| Opt-out | Manual/prospect opt-out flag suppresses outreach; does not delete audit log |

### 9.4 Forbidden

- Silent cross-shelter merge
- Merging staff notes into global profile
- Deleting audit trail on merge

---

## 10. Comment visibility rule (platform invariant)

| Kind | Visibility | Storage |
|------|------------|---------|
| **Participant comment** | All visit/session participants listed on the record | `participant_comments` or equivalent — never mixed |
| **Staff note** | Shelter staff with appropriate permission only | `staff_notes` — separate column/table |

Rules:

- No mixed-use `notes` field on new objects.
- APIs must not return staff notes to foster/adopter/prospect callers.
- UI must label the two kinds distinctly.

Legacy `org_foster_parents.notes` is staff-only; new model must not regress this.

---

## 11. Retention categories

G0 defines categories; legal/DPO signs off durations in `regulatory/` before implementation.

| Category | Examples | Direction |
|----------|----------|-----------|
| **Global foster profile** | Housing, competencies | Retain while account active + statutory limitation after deletion request |
| **Shelter–foster relationship** | Approval, local Q&A | Org-scoped; retain per shelter policy within platform limits |
| **Declined / archived foster** | Declined applications | Minimum retention for disputes; auto-archive rules in J1 |
| **Manual foster / prospect (no account)** | Pre-merge records | Shorter default; delete or anonymise if no activity |
| **Fostering session** | Contracts, checklist | Statutory foster register alignment — longer retention |
| **Adoption journey** | Certificate, contracts | Statutory adoption record alignment |
| **Audit log** | All `event_type` rows | Append-only; retention ≥ session/adoption records |
| **Participant comments** | Visit comments | Align with parent record retention |

---

## 12. Current-state compatibility gates

Each legacy entity has exactly one disposition before journey agents split. Implementation detail lives in `migration-appendix.md` (next doc).

| Legacy entity | Disposition | Owner |
|---------------|-------------|-------|
| `org_foster_parents` | **Evolve** → shelter–foster relationship + link to foster profile | J1 |
| `foster_placements` | **Evolve** → fostering sessions (same table extended or rename with view) | J3 |
| Placement statuses (`pending`, `in_progress`, …) | **Wrap and deprecate** → map to session statuses; dual-write window max one release | J3 |
| In-placement adoption states | **Replace** → J5 adoption journey; migrate open rows | J5 |
| `FosterParent` Flutter entity | **Wrap and deprecate** → new domain types alias during migration | J1 |
| Org role `foster` | **Keep** — orthogonal to approval | Platform |
| `externalFosterNotice` email | **Keep and extend** → merge framework sibling templates | J1, J4 |
| `pet_access.role = foster` | **Keep** — tied to active session | J3 |
| Custody / shadow on adoption | **Keep** — J5 calls existing custody transfer | J5 |

**Gate:** No J1–J5 agent starts until its row(s) in this table are marked `locked` in migration appendix.

---

## 13. Mandatory sections for journey specs (J1–J5)

Each journey spec must include:

1. Purpose (one sentence)
2. **In scope**
3. **Out of scope / forbidden ownership** (mandatory non-goals)
4. Depends on contracts from (G0 + upstream journeys)
5. Consumes read models from
6. Exposes read models / APIs to
7. Domain objects and states
8. Business rules (numbered, testable)
9. Screens and navigation
10. Notifications
11. Permissions (from §7)
12. Audit events (from §8)
13. Phases with exit criteria
14. Migration / compatibility (from §12)
15. Legal/document dependencies
16. Open questions
17. Canonical BDD scenarios (3–5)

---

## 14. Document index (handoff package)

| Doc | Status |
|-----|--------|
| `g0-contract-pack.md` | **This file** |
| `migration-appendix.md` | TODO — status mapping, dual-write plan, in-flight row handling |
| `j1-foster-onboarding.md` | TODO |
| `j2-matching-requests.md` | TODO |
| `j3-fostering-sessions.md` | TODO |
| `j4-adoption-visits.md` | TODO |
| `j5-adoption-conversion.md` | TODO |
| `g1-document-artefact-packs.md` | TODO — depends on J3/J5 hook freeze |

---

## 15. Open questions (G0 level only)

| # | Question | Default if unresolved |
|---|----------|----------------------|
| Q1 | Foster portal access for approved non-member fosters? | Session participant token access; no full org membership |
| Q2 | Adoption visits for non-fostered pets? | J4 foster-context only |
| Q3 | Rename table `foster_placements` → `fostering_sessions` or extend in place? | Extend in place first; rename optional later |
| Q4 | Single global `foster_profiles` table vs user profile extension? | J1 spec decides; G0 requires stable `foster_profile_id` |

Journey-specific open questions belong in J1–J5 specs, not here.
