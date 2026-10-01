---
title: AgathaTrack terminology
owner: Documentation Team
audience: product, design, engineering, content
status: active
last_updated: 2026-09-29
tags: [design, brand, copy, l10n]
---

# AgathaTrack terminology

Canonical relationship and role language for the **active Pet Care product**. Voice and register patterns are in [`copy-tone.md`](./copy-tone.md); product values are in [`true-north.md`](./true-north.md).

Shelter and Fostering terminology for frozen domains is preserved separately — see [`frozen-domains`](../engineering/frozen-domains/README.md). Do not let frozen-domain vocabulary shape active Pet Care direction.

## Pet parent (preferred English relationship term)

**Pet parent** is AgathaTrack's preferred English term for the primary person caring for their own pet.

It reflects responsibility, attachment, mental load, and the human–animal bond. It does **not** mean treating pets as human children or adopting a cute “fur baby” brand.

### When to use it

> **In English, prefer “pet parent” in brand, marketing, onboarding, and supportive relationship copy. In operational UI, prefer “you” unless naming the relationship adds clarity.**

| Context | Prefer |
|---------|--------|
| Brand, marketing, onboarding, empty states, supportive copy | pet parent (when a relationship label helps) |
| Forms, schedules, deletes, errors, status labels | **you** |
| Multiple carers involved | precise role terms (below) |

## Role and relationship terms

Use **you** in UI whenever a role label is unnecessary.

When multiple people are involved, use precise care-role language:

| Term | Use when |
|------|----------|
| **care team** | Collective carers for one pet (Away Planning carer concept) |
| **carer** / **caregiver** | General non-owner helper |
| **sitter** | Temporary care arrangement |
| **carer** | Someone with care-only shared access (`pet_access.role = carer`) — not the pet parent |
| **co-parent** | Shared access with profile/vet/sharing admin (`pet_access.role = co_parent`) — owner minus transfer |
| **Veterinary team** | Pet Care dashboard section and vet detail surfaces — the guardian's veterinary clinics (EN label; FR: *Équipe vétérinaire*). Not the same as **care team** (carers). |
| **veterinary professional** / **vet** | Clinical context |

### Planned: People & Care Team vocabulary

The EN/FR wording for the People directory, households and absence access is approved but **not shipped**. It lives in [`vocabulary.md`](../domains/people/features/vocabulary.md) until the feature ships. When it ships, the rows move into this file.

From that point, **carer** becomes a relationship word only. Access levels get labels that describe capability: Full access and Can log care. Until then, the rows above describe shipped behaviour. Don't change shipped strings ad hoc.

## Legal, technical, and permission terms

Keep these where required — do not rename technical entities purely for branding:

| Term | Use when |
|------|----------|
| **owner** | Ownership transfer, legal control, FAQ accuracy |
| **custody** | Custody segments, org/legal docs |
| **account holder** | Auth, billing, account management |
| **legal guardian** | Legal guardianship (distinct from Pet Care workspace) |
| **permission role** | API, authorization, sharing ACLs (`carer`, `co_parent`, `foster`) |
| **PetViewerRole.guardian** | Flutter viewer enum for owner viewing own pet — **not** `pet_access.role`; rename to `petParent` deferred |

Legal or technical **guardianship** is separate from Pet Care relationship language. See [pet_care README](../domains/pet_care/README.md).

## Localization

- Do **not** force a literal translation of “pet parent” into other languages.
- Translate the **relationship intent** naturally for the target language and culture.
- All user-facing strings belong in ARB/l10n.
- Localize enum `.label` when touched — `.agents/memory/localization-enum-labels.md`.

## Product naming

| Term | Rule |
|------|------|
| **AgathaTrack** | Current product name — use in all new UI and design work |
| **AgathaCheck** | Legacy — do not introduce in new copy |
| **Agatha** | Product voice for explainable suggestions — not a chat persona, simulated person, or veterinarian |

## Pet Care workspace labels (D38)

Keep these EN/FR labels distinct in copy and l10n:

| Surface | EN | FR | ARB key |
|---------|----|----|---------|
| Workspace | Pet Care | Suivi | `drawerPetCare`, `experiencePetCareView`, … |
| Dashboard pet rail | My Pets | Mes animaux | `myPets` — **do not repurpose for workspace** |
| Due-items block | CARE ACTIONS (eyebrow) | SOINS | `careEyebrow` |
| Away-planning block | AWAY PLANNING (eyebrow) | PLANIFICATION D'ABSENCE | `awayPlanningEyebrow` |
| Away-planning hub link | All absences | Toutes les absences | `allAbsences` |
| Full due list link | All Actions | Tous les soins | `allCare` |
| Global queue screen (`/pc/events`) | All Actions | Tous les soins | `allCare` |
| Bottom nav | Actions | Soins | `careNavLabel` |
| Profile operational section | {Pet}'s care | Soins pour {petName} | `careForPet` |
| Profile preview trailing link | View all care | Voir tous les soins | `viewAllCare` |
| Pet-scoped All care list | All care | Tous les soins de {petName} | `allCareTitle` |
| Passed-away pets section | Rainbow bridge | Au-delà des nuages | `rainbowBridge` — collapsed expansion on full pets list |

Pet-scoped care surfaces use `viewAllCare` / `allCareTitle`; global surfaces keep `allCare` and
`careNavLabel`. Do not reuse global keys on pet-scoped UI.

## Care timing vocabulary (care occurrences, 2026-09-29)

Canonical in [care-item-evolution.md](../domains/pet_care/features/care-item-evolution.md) (D-CIE-024 … D-CIE-027) and [CSM decisions](../domains/pet_care/changes/care-schedule-management-decisions.md) (D-CSM-019 … D-CSM-033). "Occurrence" is an internal word and never appears in UI (D-CIE-001).

| Term (EN) | FR (proposed) | Meaning | Do not say |
|-----------|---------------|---------|-----------|
| **Overdue** | En retard | Past its day or time and not done. The same at every priority | Late, Missed |
| **Not recorded** / **3 doses not recorded** | Non noté / 3 doses non notées | Fixed schedule: the next dose is already due and this one has no record. Assumes the care was probably given | Missed, Forgotten |
| **Done** | Fait | Recorded as done | Completed (in chips) |
| **Fixed schedule** | Calendrier fixe | Dates follow the calendar, whatever happens to each date | Fixed dates, From due date |
| **After it's done** | Après l'avoir fait | The next date counts from the day it is done | From completion, Counts from when it's done |
| **Schedule type** | Type de calendrier | Setting that holds the two values above | Next due date (title) |
| **If done after the due date** | Si c'est fait après la date prévue | Remembered choice: Ask me / Keep the next date / Skip the next date / Move this and following | Late behaviour, Late leeway |
| **Plan another date** | Prévoir une autre date | Add a date (booster, booked visit, extra dose). **Change date** moves one | Add occurrence |
| **Postpone until** | Reporter au | Move care to a later date; without a date it is **Pause** | Snooze |
| **Record earlier doses** · **Given** / **Not given** (medication) · **Done** / **Not done** (other care) | Noter les doses précédentes · Donnée / Pas donnée · Fait / Pas fait | Review of the Not recorded stack | Skipped (for Not given) |
| **Record as given** | Noter comme donnée | From History, for a dose closed as Not recorded | Reopen |
| **Estimated next** | Prochaine date estimée | Display-only line on overdue After-it's-done care | Next due (it is not actionable) |
| **Today** · **Due soon** · **Upcoming** · **Today's list** | Aujourd'hui · Bientôt · À venir plus tard · La liste du jour | Agenda sections (D-CIE-025) | Due and Overdue, Coming soon |
| **Nothing due today** | Rien à faire aujourd'hui | Empty Today, followed by Due soon / Upcoming | All caught up! (no praise) |

## Known terminology debt (active code)

Preserve production strings until a deliberate copy migration. Do **not** fix these ad hoc in unrelated PRs.

| Location | Current | Notes |
|----------|---------|-------|
| `landingPetCarePathSummary` | “For pet parents and foster carers” | Foster is frozen-domain vocabulary — schedule a Pet Care landing pass |
| `aboutIntro` | “pet guardians and shelters” | Mixes legacy guardian + frozen Shelter audience |
| `petResponsibilityGuardian` | “You are the pet guardian” | Prefer pet-parent framing when migrated |
| `guardian` | “Guardian” | Enum/label — map to terminology rules on touch |
| `petTimelineCustodySegment` | “Guardian: {name}” | Legal/custody context — review on custody copy pass |

Track intentional migrations in a dedicated copy/terminology issue or PR — not drive-by string edits.
