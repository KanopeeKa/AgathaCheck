---
title: Agatha care journey — UI design (deep)
owner: Product / Documentation
audience: both
domain: pet_care
status: proposed
status_since: 2026-10-10
folds_into: docs/domains/pet_care/features/care-intelligence.md
parent: agatha-care-journey-programme.md
tags: [design, ui, pet_profile, care_intelligence]
---

# Agatha care journey — UI design (deep)

**Programme:** [`agatha-care-journey-programme.md`](./agatha-care-journey-programme.md)  
**Tokens:** [`docs/design/tokens.md`](../../../design/tokens.md)

> **Authority:** This file is the **single source of truth** for pet-profile Agatha **slot order**, tiebreak, and completeness visibility. The programme links here.

## 1. Scope

| Surface | PRs | Notes |
|---------|-----|-------|
| Pet profile (`/pc/*`) | PR-03–05 | Primary |
| Pet form | PR-02–03 | |
| Agatha cards | PR-04, PR-06+ | |
| Actions agenda | PR-12–13 | CSM-gated |

**Data scope:** PR-01 changes the shared **`pets`** row (org shadow, sharing, redaction). UI copy is Pet Care; **API impact is cross-cutting** — not “Pet Care only.”

---

## 2. Audits (summary)

- Dual chrome (inset vs Agatha) — **requirement** to unify on Agatha for completeness/welfare.
- Neuter tri-state must survive reload — **PR-01–02**.
- Stacking messages — **minimal policy in PR-04**, extended in PR-05.

---

## 3. Pet profile slot order (requirement)

1. Identity card  
2. **Safeguard** (info chrome) — if active  
3. **`{Pet}'s care`** — operational centre; never outranked  
4. **At most one guidance card:** rhythm **or** welfare (tiebreak below)  
5. **Completeness** — only if policy allows; **not mandatory** when slot budget exhausted  
6. Insights (weight, health history)

### Guidance tiebreak (PR-05)

1. Rhythm suggestion **>** welfare suggestion  
2. Else higher rule **severity** (server)  
3. Else **oldest** `created_at`

### Completeness visibility (decision)

Completeness **does not always show**. It uses the same slot budget as guidance; dismissed cards respect **30d cooldown** (PR-05).

### Nag budget (PR-05)

- Per card kind: max **1** prominent show per 7d unless user-initiated edit  
- After dismiss: **30d** suppress (align welfare with FR-FB-1 direction)

---

## 4. Agatha shell rules

**R-ACJ-UI-001:** Shared `AgathaMessageCard` shell for completeness, welfare, rhythm.

**R-ACJ-UI-002:** Primary button label reflects **outcome** — never universal “Accept” on completeness/welfare.

### Resolved product choices (was §7 open questions)

| ID | Decision |
|----|----------|
| UI-Q-01 | Completeness uses same “Suggested by Agatha” eyebrow + subtitle line “Profile” |
| UI-Q-02 | Completeness **not** in For you until PR-06 inbox union |
| UI-Q-03 | **Two** completeness cards max (chip + neuter); do not merge into one card in v1 |

---

## 5. Flows

- **PR-03:** Sheet from **existing inset prompt**; PR-04 switches host to Agatha card calling same sheet.
- **PR-04:** Delete legacy `NeuterReminderCard` / `ChipReminderCard` and controllers (alarmist copy — roadmap §12).

---

## 6. Copy

- Headlines factual; welfare Why? may include vet line (FR-SC-3 pattern).
- Microchip: **“Check local rules”** only — no “required by law” (programme PR-07).

---

## 7. Acceptance checklist (implementation)

See programme + bdd-qa. Copy: ARB keys touched by programme must pass **forbidden-term lint** (bdd-qa § Copy lint).
