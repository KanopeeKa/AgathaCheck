---
title: Agatha care journey — UI design (deep)
owner: Product / Documentation
audience: both
domain: pet_care
status: proposed
status_since: 2026-10-10
parent: agatha-care-journey-programme.md
tags: [design, ui, pet_profile, care_intelligence]
---

# Agatha care journey — UI design (deep)

**Skill:** `/ui-design-deep` · **Programme:** [`agatha-care-journey-programme.md`](./agatha-care-journey-programme.md)  
**Tokens:** [`docs/design/tokens.md`](../../../design/tokens.md) (Agatha: `agathaMessageSurface`, `agathaTeal`, `agathaTealAction`)  
**Canonical CIM chrome:** [`care-intelligence.md`](../features/care-intelligence.md) §Presentation

## 1. Scope

| Surface | Routes / widgets | PRs |
|---------|------------------|-----|
| Pet profile | `PetDetailScrollBody`, completeness slot, suggestion slots | PR-03–PR-05 |
| Pet form | `PetFormNeuteredSection`, chip field | PR-02–PR-03 |
| Agatha cards | `AgathaMessageCard`, `CareSuggestionCard` (reference) | PR-04, PR-06+ |
| Actions agenda | Care desk / Actions grouping | PR-12–PR-13 |
| For you | `NotificationSuggestionCard` | PR-06+ (optional parity) |

**Experience:** Pet Care `/pc/*` only. No Shelter/Fostering.

**Current vs target:** Completeness uses `petCareCollection` inset rows (muted); target uses **same Agatha chrome as rhythm suggestions** with **different actions** and shorter headlines.

---

## 2. Audits

### UX

- **Problem:** Two visual languages (inset list vs Agatha teal) for “Agatha wants something from you.” **Requirement**
- **Problem:** Neuter Yes/No/Not sure does not survive reload — erodes trust. **Requirement** (PR-01–02)
- **Friction:** Completeness only dismisses; no primary path without opening full form. **Requirement** (PR-03)
- **Risk:** Stacking safeguard + rhythm + welfare + completeness = four messages. **Requirement** (PR-05 cap)

### A11y

- Completeness inset uses `ListTile` + `TextButton` — OK; Agatha cards must keep `Semantics(identifier:)` for E2E (`care_suggestion_group` pattern). **Requirement**
- Segmented controls: label association via `PetFormLabeledField`. **Requirement**
- Touch ≥ 48dp on all Agatha actions (`design.mdc`). **Requirement**

### Design

- Do not use `petCarePrimary` plum on Agatha card CTAs — use `agathaTealAction`. **Requirement**
- Safeguards stay `info` / `infoLight` — never teal. **Requirement**
- `petCareCollection` may remain for **non-Agatha** collection lists (care rows). **Recommendation**

### Landing/auth

- No change in W1–W4. **N/A**

---

## 3. System first (rule → component → screen → flow)

### Rule R-ACJ-UI-001 (requirement)

**One Agatha suggestion shell** — eyebrow “Suggested by Agatha” only on **guidance** cards (completeness may use eyebrow **“Profile”** or shared eyebrow with subtitle “Complete {pet}’s profile” — product pick in PR-04; default: same eyebrow for learnability).

### Rule R-ACJ-UI-002 (requirement)

**Action outcome drives button label**, not a universal “Accept”.

| Card kind | Primary label examples |
|-----------|------------------------|
| Completeness | Add identification · Record status |
| Welfare | Learn more · Add to profile · Plan a visit (link) |
| Rhythm | Add to care (existing `careSuggestionAccept`) |

### Component pattern C-ACJ-01 (recommendation)

Extract from `CareSuggestionCard`:

- `AgathaSuggestionShell` — title row + body + action wrap
- `AgathaSuggestionActionBar` — primary filled, outlined Why, text secondaries

Handlers passed by kind; no shared “accept recommendation” for completeness.

### Screen: Pet profile slot order (requirement)

Align with [`pet-profile-care-surface` plan](../../../.agents/plans/pet-profile-care-surface.md) where still valid:

1. Identity card  
2. **Safeguard** (if any) — info chrome  
3. **`{Pet}'s care`** operational section (dominant)  
4. **At most one** guidance card: rhythm **or** welfare (policy)  
5. **Completeness** (only if slots allow per PR-05)  
6. Insight columns (weight, history)

*Challenge to legacy spec:* if completeness must always show, policy may place it **below** care list but **above** insight — never above `{Pet}'s care`.

### Flow: Inline capture (PR-03)

- Modal bottom sheet (mobile) / dialog (≥600px): species-aware copy, segmented status, optional ID field, Save.
- Success: dismiss card via state refresh; snackbar optional and calm.

---

## 4. Phased rollout (maps to PRs)

| Phase | UI deliverable |
|-------|----------------|
| PR-02 | Form reflects persisted enums |
| PR-03 | Sheet component + entry from card |
| PR-04 | Completeness card widget tests |
| PR-05 | Policy hides duplicate chrome |
| PR-06 | Welfare card variant + overflow menu (match For you FR-SC-1) |
| PR-12 | `CareAgendaDateGroupHeader` (name TBD) |
| PR-13 | Coordination banner below group header |

---

## 5. Review items (9-part)

### 5.1 Problem — dual chrome for Agatha-adjacent prompts (requirement)

### 5.2 Why it matters — breaks “quiet intelligence” positioning (requirement)

### 5.3 UX impact — clearer next action, less form hunting (recommendation)

### 5.4 A11y impact — merge semantics on card; preserve focus order (requirement)

### 5.5 System impact — shared shell reduces drift (recommendation)

### 5.6 Proposed fix — shell + outcome-specific actions (requirement)

### 5.7 Reusable rule — R-ACJ-UI-001 / 002 (requirement)

### 5.8 Implementation notes — file budget ≤500 lines; widgets under `care_intelligence/presentation/widgets/` or `experience/.../pet_profile/widgets/` (preference: experience composes, care_intelligence owns shell)

### 5.9 Acceptance checklist

- [ ] Theme tokens only (`AppColorTokens`, `Theme.of`)
- [ ] Focus visible; buttons ≥48dp
- [ ] All strings in ARB (EN + FR for touched keys)
- [ ] Loading/error on sheet save
- [ ] `editProfile` capability gates mutations
- [ ] Widget + golden-style layout test for one card
- [ ] `pre-push-changed.sh` on implementation PRs
- [ ] BDD `ACJ-*` scenarios for PR-04+

---

## 6. Copy tone (requirement)

Per [`copy-tone.md`](../../../design/copy-tone.md):

- Completeness headlines = **factual** (“Identification not recorded”), not judgment.
- Welfare Why? = species context + “talk to your vet” where health-adjacent (FR-SC-3 pattern).
- No compliance absolutes (“required by law”) unless jurisdiction project exists — use “check local rules” **preference** only.

---

## 7. Open questions (halt if unresolved)

| ID | Question | Default if no answer |
|----|----------|----------------------|
| UI-Q-01 | Same “Suggested by Agatha” eyebrow on completeness? | Yes, with subtitle “Profile” |
| UI-Q-02 | Completeness in For you tab? | No until PR-06 inbox wiring |
| UI-Q-03 | Merge chip+neuter one card? | Two cards max; policy may collapse to one with two primaries |
