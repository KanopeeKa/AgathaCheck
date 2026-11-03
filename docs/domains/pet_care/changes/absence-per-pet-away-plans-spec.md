---
title: Absences and per-pet away plans — functional change spec
owner: Product / Agent
audience: both
status: proposed
status_since: 2026-11-03
folds_into: docs/domains/pet_care/features/care-context.md
last_updated: 2026-11-03
---

# Absences and per-pet away plans — functional change spec

**Status:** Proposed. Product decisions are agreed (2026-11-03); this document is up for review before the technical plan is written.
**Folds into:** [care-context.md](../features/care-context.md) (primary) and [away-planning-carer-model.md](../features/away-planning-carer-model.md).
**Requirement IDs:** the `Planned` rows `CARE-CONTEXT-R-025` … `R-041` and `AWAY-PLANNING-CARER-R-016` … `R-018` are already in those canonical docs. This document explains them; the canonical rows are the contract.

This is a **functional** description only. It says what the person sees and what the product guarantees. Storage, endpoints and widgets belong to the technical plan that follows review (§11).

---

## 1. Why

Today one absence is one screen that covers every pet at once: Who's caring for all pets, then "Care during your absence" with a section per pet. With three pets the page gets long. It mixes information that different carers need, and there is no natural home for a pet's absence on that pet's own page.

The underlying facts are already per pet: carer, pet note, care to review, planned care, per-pet PDF and per-pet guest access. This change makes the presentation match. An **absence** is the trip. Each pet on the trip has its own **away plan**.

## 2. Concepts and naming

| Concept | Holds | EN label | FR label |
|---|---|---|---|
| **Absence** | Title, dates, who is going away, trip-wide notes, its away plans | Absence | Absence |
| **Away plan** (one pet) | The pet, who's caring, notes for the pet, care to review, planned care | {Pet}'s away plan | Plan d'absence de {Pet} |

Rules:

- An absence has **at least one** away plan. There is **one** away plan per pet per absence.
- A pet can have away plans on several absences, and these can overlap (today's non-blocking overlap warning still applies — CARE-CONTEXT-R-004).
- **Who is going away is the person who logs the absence.** It is one person and cannot be changed. It is shown, not chosen.
- "Away plan" no longer means the whole trip. The current screen title "Away plan" / "Plan d'absence" moves to the per-pet screen. The trip screen is titled with the absence title, or "Absence" when there is no title.
- [terminology.md](/docs/design/terminology.md) records both terms, EN and FR, in the delivery PR.

## 3. Journeys

### 3.1 Create an absence for three pets (reference journey)

Frederique (`frederique.prevost@gmail.com`, UAT) has Buddy, Whiskers and Pebble. She is away from 15 to 21 November.

1. Away (`/pc/away`) → **I'll be away**.
2. The form asks for a title (optional), the dates, the pets and trip-wide notes (optional), as today. It shows "You're away" as a fixed line. There is no picker for who is going.
3. She ticks all three pets and saves.
4. **One absence and three away plans** are created: Buddy's, Whiskers's and Pebble's.
5. She lands on the **absence screen** (§4.1). It shows one pill per pet: "See Buddy's away plan", "See Whiskers's away plan", "See Pebble's away plan".
6. She taps Buddy's pill and the **away plan screen** for Buddy opens (§4.2).

**Single pet:** if exactly one pet is ticked, saving lands directly on that pet's away plan screen. The absence is one tap away through **See absence**.

**Starting from a pet:** when the create form opens from a pet's context (§4.3), that pet is already ticked. The person can untick it or add others.

Nothing about care changes when an absence is saved (CARE-CONTEXT-R-001). Saving still needs only dates and pets (CARE-CONTEXT-R-022).

### 3.2 Review one pet's plan

On Buddy's away plan screen Frederique:

- sees the trip (title, dates, "You're away") as read-only
- assigns or changes who's caring for Buddy and writes notes for Buddy
- works through **Care to review** and **Planned care** for Buddy only
- downloads Buddy's handover PDF
- taps **See absence** to go back to the trip

Pebble has no care items, so Pebble's plan shows the existing calm "nothing scheduled" state. Pebble's pill still exists.

### 3.3 Add a pet to a saved absence

From the absence screen: **Add a pet** → choose from pets the person can manage that are not already on the absence → confirm.

- A new away plan is created for that pet with no carer and no notes.
- If the dates overlap another active absence for that pet, the usual warning shows. It does not block.
- If carers on this absence already have absence access, the app asks before any of them can see the new pet (PEOPLE-D16). Declining still adds the pet; it just doesn't widen anyone's access.

### 3.4 Remove a pet from an absence

From that pet's away plan screen: **Remove {Pet} from this absence** → confirmation.

- The confirmation says what goes: this pet's carer assignment, notes for this pet, and decisions made on this pet's care for this trip. Care items and their dates are **not** changed; postponed or moved dates stay as they are.
- Any absence access a carer had to this pet ends straight away. Pending carer invites stop covering this pet.
- The person returns to the absence screen.

**Removing the last pet deletes the absence.** The confirmation says so plainly ("Pebble is the only pet on this absence. Removing it deletes the absence.") and uses the same outcome as deleting the absence today: the absence disappears from lists, and all absence access ends straight away.

### 3.5 A co-parent opens a shared pet

Sam has Full access to Buddy only (as co-parent or household Full access). Frederique's absence includes Buddy, Whiskers and Pebble.

- On **Buddy's pet page**, Sam sees the away plan section: "Frederique is away · 15–21 Nov" and can open Buddy's away plan.
- Sam can **view and edit** Buddy's away plan: who's caring, notes for Buddy, care decisions.
- **See absence** shows the trip title, dates, trip-wide notes and **only Buddy's pill**. Whiskers and Pebble are not named, counted or hinted at.
- Sam cannot change the trip itself (title, dates, trip notes, delete) and cannot add or remove pets. Those belong to the person going away (§5).

People with **Can log care** (household tier, care-only share, or absence guest access) do not see away plan screens or the pet page section. Their care handover scope is unchanged (PEOPLE-D7).

## 4. Screens

### 4.1 Absence screen (`/pc/away/:absenceId`)

Top to bottom:

1. **Summary card:** title, dates, who's away ("You're away" / "{Name} is away"), trip-wide notes preview, **Edit** (for the person going away only).
2. **Overall status:** the existing attention-only line, combined across the pets the viewer can see (CARE-CONTEXT-R-016 rules).
3. **Pets on this absence:** one pill per pet the viewer can access, in a stable order (alphabetical by pet name).
   - Each pill has the pet's avatar and name, the label "See {Pet}'s away plan", and one short status: carer gap first ("No carer yet", "Carer no longer available"), else care to review ("2 to review"), else nothing.
   - **Add a pet** after the pills (person going away only; hidden on cancelled or past absences).
4. **Full-trip handover PDF** (app-bar action, as today).

The long per-pet content that is on this screen today ("Who's caring" for every pet, "Care during your absence" per pet) moves to the away plan screen and is **not** duplicated here.

### 4.2 Away plan screen (`/pc/away/:absenceId/pets/:petId`)

Top to bottom:

1. **Trip header (read-only):** title, dates, who's away, and the **See absence** button. There is no edit control for trip fields here.
2. **Pet header:** avatar and name, linking to the pet page (D-AWD-006).
3. **Who's caring:** this pet's carer, with the existing carer dialog for changes (AWAY-PLANNING-CARER-R-017).
4. **Notes for {Pet}:** shown on the screen and editable. This replaces "only inside the carer dialog" (AW-11 §2a).
5. **Trip notes:** the trip-wide notes, read-only, labelled as being for the whole trip.
6. **Care to review**, then **Planned care:** same content and behaviour as today's per-pet section (CARE-CONTEXT-R-017 … R-021, R-023), for this pet only.
7. **Download {Pet}'s plan:** the per-pet handover PDF (AWAY-PLANNING-CARER-R-009, R-010 unchanged).
8. **Remove {Pet} from this absence** in the overflow menu (person going away only).

Cancelled absence: everything is read-only and downloads are disabled, as today.

### 4.3 Pet page section (above "People around {Pet}")

- Lists this pet's **current and upcoming** away plans (absence not cancelled, `ends_on >= today`), soonest first.
- Each row shows the absence title (or the dates when there is no title), the dates, who's away, and the same one-line status as the pill. Tapping a row opens that away plan screen.
- If there are more than two, show the first two and an "All absences" link to the Away hub.
- **Hidden** when the pet has no current or upcoming away plan, and hidden for viewers who are not allowed to see away plans (§5).
- **Entry point:** the pet page's actions menu has **Plan an absence**, which opens the create form with this pet ticked. It is shown to people with Full access to the pet.
- Mobile and web use the same order. On the desktop two-column layout, the section sits in the primary column directly above "People around {Pet}".

### 4.4 Away hub and dashboard tile

- **Away hub (`/pc/away`):** two sections — **Your absences** and **Other people's absences** (FR **Absences des autres**). The first lists absences the viewer logged. The second lists absences that include a pet the viewer has Full access to but did not log; cards show "{Name} is away" and only the pets the viewer can access. One card per absence (never duplicated under both sections). Tapping a card opens the absence screen.
- **Dashboard away tile:** unchanged. It nudges the person going away about their own absences only.

### 4.5 Navigation

- Away plan screens are pushed full screens on mobile and web, like care item detail. Back returns to where the person came from (absence screen, pet page, care item) using the existing return-path pattern.
- **See absence** always opens the absence screen.
- Links that today open the whole absence for a specific pet open **that pet's away plan** instead:
  - the care item's absence module
  - pet-specific overlap warnings
- The hub and the dashboard tile still open the absence screen.

## 5. Who can see and do what

| Action | Person going away | Full access to the pet (record owner, co-parent, household Full access) | Can log care / absence guest |
|---|---|---|---|
| See the absence (summary, trip notes) | Yes | Yes, when at least one pet on it is theirs to see | No |
| See pills | All pets they can access | Only pets they have Full access to | No |
| View this pet's away plan | Yes, while they have Full access to the pet | Yes | No (care handover scope only) |
| Edit this pet's away plan (carer, notes, care decisions, invite a carer) | Yes | Yes | No |
| Edit trip (title, dates, trip notes) and delete the absence | Yes | No | No |
| Add a pet / remove a pet | Yes (adding needs Full access to the added pet) | No | No |
| Full-trip PDF | Yes, covering the pets they can access | Yes, covering only their pets | No |
| Per-pet PDF | Yes | Yes | No |

- Access is checked **when the page is read**, not stored on the plan. If someone loses Full access to a pet, they stop seeing its plan immediately. If they gain it, the plan appears.
- The **person who declared the absence** always sees it under **Your absences** and can edit the trip or delete it, even when they no longer have Full access to one or more pets on the trip.
- When a person other than the one going away edits a plan, the plan shows the change. "Last changed by" stays in the audit trail only (PEOPLE-D17); there is no new notification in this change.
- **The person going away is never a carer on their own absence.** They are not offered as a carer candidate, and a contact linked to their account cannot be assigned (AWAY-PLANNING-CARER-R-016).
- This replaces "planned absences are visible only to the person who logged them" (CARE-CONTEXT-R-005). That rule is retired when this ships.

## 6. Status facts

Both facts stay facts, never a single "ready" verdict (D-AWAY-002).

| Level | Facts | Shown on |
|---|---|---|
| Away plan (one pet) | Carer state (`unset` · `set` · `unavailable`); care coverage state; number of care items to review | Pill, pet page row, away plan screen header |
| Absence | Existing combined carer coverage and care coverage, over the pets the viewer can see | Absence screen status line, hub card, dashboard tile (person going away) |

The one-line pill status uses the existing priority: carer gap first, then care to review.

## 7. Lifecycle and edge cases

| Situation | Outcome |
|---|---|
| Dates edited on the absence | Apply to every away plan. The existing confirmations for carer access and plan review still apply |
| Absence deleted (cancelled) | Every away plan goes with it; all absence access ends straight away (as today) |
| Pet removed from the absence | §3.4 |
| Last pet removed | Absence deleted (§3.4) |
| Pet deleted from the app | Its away plans are removed. If that was the last pet on an absence, the absence is deleted and its absence access ends |
| Pet leaves a household or is transferred | The plan stays with the pet (PEOPLE-D17). Who can see it is re-evaluated (§5). Carer contacts are re-pointed as today (PEOPLE-CARE-TEAM-D-029, D-034) |
| Person going away loses Full access to a pet | They stop seeing that pet's plan and pill. The plan remains visible to people who still have Full access |
| Carer leaves, loses access, or contact removed | Pet's carer state becomes `unavailable` (PEOPLE-D18), shown on the pill |
| Same carer for several pets | Inviting a carer from one pet's plan offers to include the other pets on this absence where they are already the carer and the inviter can grant access (AWAY-PLANNING-CARER-R-018) |
| Two absences overlap for one pet | Both plans appear on the pet page section; the overlap warning stays non-blocking |
| Past absence | Visible from the hub's past list; plans read-only; not on the pet page section |

## 8. Handover PDFs

- **Full-trip PDF** (absence screen): same content as today, limited to the pets the downloader can access. Recording `last_handover_downloaded_at` is unchanged (AWAY-PLANNING-CARER-R-008).
- **Per-pet PDF** (away plan screen): unchanged privacy rules for the declarer and for carers (AWAY-PLANNING-CARER-R-009). When the downloader has Full access to some pets only, trip context and pet-name lists in that PDF are limited to **pets they can access** (same rule as the full-trip PDF in R-040). It does not record a download (R-010).

## 9. Out of scope

- Choosing who is going away, or more than one traveller.
- Different dates per pet within one absence.
- Notifying co-parents when an absence that includes their pet is created or edited.
- Giving away plan screens to Can log care or absence guests.
- Moving an away plan from one absence to another.
- Changes to care scheduling, resolutions or projection rules.

## 10. Acceptance criteria (functional)

| # | Given / When / Then | Requirement |
|---|---|---|
| AP-1 | Given three pets ticked, when the absence is saved, then one absence and three away plans exist and the absence screen shows three pills | CARE-CONTEXT-R-025, R-027, R-028 |
| AP-2 | Given one pet ticked, when saved, then the person lands on that pet's away plan screen | CARE-CONTEXT-R-027 |
| AP-3 | When a pill is tapped, then the away plan screen shows only that pet's carer, notes, care to review and planned care; trip fields are read-only; See absence returns to the absence | CARE-CONTEXT-R-029, R-030 |
| AP-4 | Given the person logging, then "You're away" is shown and no traveller picker exists; others see "{Name} is away" | CARE-CONTEXT-R-026 |
| AP-5 | Given an upcoming away plan for Buddy, when Buddy's page opens, then the section shows above People around Buddy and opens Buddy's plan; given none, the section is absent | CARE-CONTEXT-R-031 |
| AP-6 | Given Sam has Full access to Buddy only, when Sam opens the absence, then only Buddy's pill shows and other pets are not disclosed; Sam can edit Buddy's carer and notes but not trip fields | CARE-CONTEXT-R-032, R-033 |
| AP-7 | Given Can log care on Buddy, then no away plan section or screen is available | CARE-CONTEXT-R-032 |
| AP-8 | When a pet is added to a saved absence, then a new empty plan exists, overlap warns, and existing guest carers get no access without confirmation | CARE-CONTEXT-R-034 |
| AP-9 | When a pet is removed, then its carer, notes and decisions for this trip go, its absence access ends, and care item dates are unchanged | CARE-CONTEXT-R-035 |
| AP-10 | When the last pet is removed, then the confirmation states the absence will be deleted and the absence is deleted | CARE-CONTEXT-R-035 |
| AP-11 | When a pet on a one-pet absence is deleted, then the absence is deleted | CARE-CONTEXT-R-036 |
| AP-12 | Pill and pet-page status show carer gap first, then review count | CARE-CONTEXT-R-037 |
| AP-13 | From a care item's absence module, the link opens that pet's away plan | CARE-CONTEXT-R-038 |
| AP-14 | Hub lists absences including a pet the viewer has Full access to, labelled with the traveller | CARE-CONTEXT-R-039 |
| AP-15 | Full-trip PDF by Sam contains Buddy only | CARE-CONTEXT-R-040 |
| AP-16 | The person going away is never offered or accepted as a carer on their own absence | AWAY-PLANNING-CARER-R-016 |
| AP-17 | Who's caring and notes for the pet are edited on the away plan screen | AWAY-PLANNING-CARER-R-017 |
| AP-18 | Inviting a carer from one plan offers the other pets they already care for on this absence | AWAY-PLANNING-CARER-R-018 |

The delivery PR moves these into the canonical acceptance tables with `bdd:` / `test:` coverage.

## 11. Delivery

Engineering sequencing, phase paths, security gates, and per-slice test and documentation checklists are **not** duplicated here. They live in:

- [absence-per-pet-away-plans-delivery-plan.md](./absence-per-pet-away-plans-delivery-plan.md) (human programme + UAT proof)
- Execute-plan `.agents/plans/absence-per-pet-away-plans-a7566.md` (control issue [#2036](https://github.com/KanopeeKa/AgathaCheck/issues/2036))

This document remains the **functional** product contract (`AP-1`–`AP-18`, §5 visibility). The delivery plan is the implementation programme.

---

*End of spec.*
