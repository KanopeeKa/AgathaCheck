---
title: AgathaTrack terminology
owner: Documentation Team
audience: product, design, engineering, content
status: active
last_updated: 2026-09-09
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
| **shared carer** | Someone with shared access (not owner) |
| **Veterinary team** | Pet Care dashboard section and vet detail surfaces — the guardian's veterinary clinics (EN label; FR: *Équipe vétérinaire*). Not the same as **care team** (carers). |
| **veterinary professional** / **vet** | Clinical context |

## Legal, technical, and permission terms

Keep these where required — do not rename technical entities purely for branding:

| Term | Use when |
|------|----------|
| **owner** | Ownership transfer, legal control, FAQ accuracy |
| **custody** | Custody segments, org/legal docs |
| **account holder** | Auth, billing, account management |
| **legal guardian** | Legal guardianship (distinct from Pet Care workspace) |
| **permission role** | API, authorization, sharing ACLs |

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
| Full due list link | All Actions | Tous les soins | `allCare` |
| Global queue screen (`/pc/events`) | All Actions | Tous les soins | `allCare` |
| Bottom nav | Actions | Soins | `careNavLabel` |
| Profile operational section | {Pet}'s care | Soins pour {petName} | `careForPet` |
| Profile preview trailing link | View all care | Voir tous les soins | `viewAllCare` |
| Pet-scoped All care list | All care | Tous les soins de {petName} | `allCareTitle` |
| Passed-away pets section | Rainbow bridge | Au-delà des nuages | `rainbowBridge` — collapsed expansion on full pets list |

Pet-scoped care surfaces use `viewAllCare` / `allCareTitle`; global surfaces keep `allCare` and
`careNavLabel`. Do not reuse global keys on pet-scoped UI.

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
