---
title: People & Care Team — vocabulary (EN/FR)
owner: Product / Documentation
audience: both
domain: people
feature_id: people_care_team
status: accepted
related_prs: []
related_bdd: []
---

# People & Care Team — vocabulary (EN/FR)

**Status:** approved on 2026-09-27 and **not shipped yet**. It covers the UI wording for the [People & Care Team spec](/docs/domains/people/features/people-care-team.md).

When this feature ships, the implementing PR must:

- move the shipped rows into [terminology.md](/docs/design/terminology.md), with one ARB key per label, following the D38 table pattern
- localise enum labels (see `.agents/memory/localization-enum-labels.md`)
- then delete this file

Until then, don't change shipped strings ad hoc.

**Wire values don't change.** The API, database and logs keep `co_parent` and `carer`. Only the UI labels change: Co-parent, Full access, Can log care. Don't rename the enums.

**Absence carers keep "care team".** The Away Planning UI keeps *care team* / *équipe de soins* for the carers on an absence, as defined in [terminology.md](/docs/design/terminology.md) and [away-planning-carer-model.md](/docs/domains/pet_care/features/away-planning-carer-model.md). Only the People page avoids that term.

## Principles

1. **The group heading carries the relationship, and the row carries the role.** A row doesn't repeat what its heading already says.
2. **English and French match in tone and meaning, not word for word.** French needs the warmer wording more.
3. **Section labels are short and easy to scan. Action labels sound like normal speech.**
4. **No gendered nouns for people.** Neither users nor contacts have grammatical gender in the data. Use words that don't change with gender, service names, or verb phrases.
5. **Precise words for access.** People need to know exactly what someone can do.
6. **Labels, not nudges.** Never ask "who will do this?" in an empty state ([copy-tone.md](/docs/design/copy-tone.md)).

## Main surfaces

| Concept | English | French | Notes |
| --- | --- | --- | --- |
| Page title and nav label | People | Autour de vos animaux | Deliberately not parallel: the French is broader and warmer. Localisers must not "correct" either side. Not "care team", which already means the carers on an absence |
| Household section (People page) | Household name, e.g. Morgan household | Household name, e.g. « Famille Morgan » | Every household is headed by its name, including when there's only one |
| Carers section | Trusted carers | Proches & pet-sitters | Not "Proches & gardes": *garde* can mean a guard, a duty shift or custody |
| Professionals section | Pet professionals | Leurs pros | |
| Filters | All · Household · Carers · Professionals | Tous · Foyer · Proches · Pros | Short forms of the section headings. "Household" is the generic word, because the sections use household names |

## Pet profile

| Concept | English | French |
| --- | --- | --- |
| Section title | People around Buddy | Autour de Buddy |
| Household group | At home | À la maison |
| Carers group | Trusted carers | Proches & pet-sitters |
| Professionals group | Pet professionals | Ses pros |

"At home" / "À la maison" is used **only** on the pet profile. A pet has at most one household, so it always means that pet's home.

Example:

> **Autour de Buddy**
> **À la maison** — Alex, Sam
> **Proches & pet-sitters** — Jamie · Pet-sitting
> **Ses pros** — Clinique Greenhill · Vétérinaire

## Care setting relabel (shipped strings)

The shipped `careSettingHome` label is "At home" / "À la maison". That's the same wording as the household group, on the same care screens. When provider fields ship:

| ARB key | English (today → planned) | French (today → planned) |
| --- | --- | --- |
| `careSettingHome` | At home → At home (you give it) | À la maison → À domicile |
| `careSettingFieldHelper` | "Where this care happens or who delivers it." → "Where this care happens." | "Où ce soin a lieu ou qui le réalise." → "Où ce soin a lieu." |

The "who delivers it" part of the helper moves to the new provider field.

## Adding someone

| Element | English | French |
| --- | --- | --- |
| Title | Who would you like to add? | Qui souhaitez-vous ajouter ? |
| Option | Someone at home | Quelqu'un à la maison |
| Helper | Lives with you and shares your pets' everyday life. | Une personne qui partage le quotidien de vos animaux. |
| Option | A trusted carer | Quelqu'un qui les garde |
| Helper | A friend, relative or pet sitter who sometimes looks after them. | Un proche, un ami ou un pet-sitter qui s'en occupe ponctuellement. |
| Option | A pet professional | Un pro pour vos animaux |
| Helper | Vet, groomer, walker, trainer… | Vétérinaire, toilettage, promenade, éducation… |
| Option | An organisation | Un établissement |
| Helper | Clinic, grooming salon, boarding, daycare… | Clinique, salon de toilettage, pension, garderie… |

The "Someone at home" helper deliberately excludes people who only help regularly, such as a daily dog walker. Those are carers (D4).

## Roles (shown on the row)

French labels name the service rather than a gendered job title. The same label then works for a person and for an organisation.

| Role | English | French |
| --- | --- | --- |
| sitter | Pet sitter | Pet-sitting |
| walker | Dog walker | Promenade |
| vet | Vet | Vétérinaire |
| vet nurse | Vet nurse | Auxiliaire vétérinaire |
| groomer | Groomer | Toilettage |
| trainer | Trainer | Éducation |
| behaviourist | Behaviourist | Comportementaliste |
| boarding | Boarding / daycare | Pension / garderie |
| emergency contact | Emergency contact | Contact d'urgence |
| other | Other | Autre |

A row reads as "Jamie Taylor · Pet-sitting · Buddy, Luna". It never reads "Proche & garde".

"Household member" / "Membre du foyer" is a relationship label. It isn't shown under a household heading.

## Household roles and access

| Concept | English | French | Notes |
| --- | --- | --- | --- |
| Current user | You | Vous | |
| Organiser | Organiser | Gère le foyer | The asymmetry is intentional. English uses a noun, which doesn't vary by gender. French uses a verb phrase ("Vous · Gère le foyer") because the data has no gender to choose between *Organisateur* and *Organisatrice*. It also avoids *Admin*. Access levels stay capability nouns in both languages |
| Co-parent | Co-parent | Co-parent | A direct share that can also share onward (spec D26). Uses the shipped `coParent` label |
| Full access | Full access | Accès complet | |
| Can log care | Can log care | Peut enregistrer les soins | |
| No app access | No app access | Aucun accès à l'application | |
| Temporary access | Temporary access | Accès temporaire | Don't use "Guest access", which suggests a lighter account (D8) |
| During an absence | Access during this absence | Accès pendant cette absence | |
| With an end date | Access until 10 Oct | Accès jusqu'au 10 oct. | |
| No active access | No current access | Aucun accès en cours | |
| Household (generic) | Household | Foyer | |

## Household actions

| Action | English | French | Notes |
| --- | --- | --- | --- |
| Leave | Leave "Morgan household" | Quitter « Famille Morgan » | Never *Quitter le foyer*, which echoes *abandon du domicile conjugal* |
| Remove a pet | Remove Buddy from "Morgan household" | Retirer Buddy de « Famille Morgan » | |
| Removal choice | Remove from household only | Retirer du foyer uniquement | |
| Removal choice | Remove all access to my pets | Retirer tout accès à mes animaux | |
| Review step when creating | These pets will be shared with household members | Ces animaux seront partagés avec les membres du foyer | |

## People and contact details

Avoid the word "contact" in consumer-facing navigation. "Contact" is a domain term for specs and code.

| Concept | English | French |
| --- | --- | --- |
| Add a person | Add person | Ajouter quelqu'un |
| Add an organisation | Add organisation | Ajouter un établissement |
| Detail screen title | The person's or organisation's name | The person's or organisation's name |
| Detail screen, accessibility label only | Person details | Détails de la personne |
| Phone, email, address | Contact information | Coordonnées |
| Search | Search people | Rechercher |
| Related pets | Related pets | Animaux concernés |
| Related care | Related care | Soins associés |
| Works at | Works at | Travaille chez |
| Private note | Private note | Note personnelle |
| Household note | Household note | Note du foyer |
| Inactive | Inactive | Inactif |

## Care items

| Concept | English | French | Notes |
| --- | --- | --- | --- |
| Provider (data concept) | Provider | Intervenant | For the data model and for field headings where one is needed. The UI shows the role plus the name instead, e.g. "Vétérinaire · Clinique Greenhill" |
| Looked after by | Looked after by | Qui s'en occupe | A field label only, never an empty-state prompt |
| Default, pet in a household | Anyone in the household | Quelqu'un du foyer | Not "Anyone at home", which clashes with the care setting |
| Default, pet in no household | You | Vous | |
| Logged by | Logged by | Enregistré par | |
| Performed by | Done by | Fait par | For medication, history may read "Given by" / "Donné par" |
| Combined history line | Given by Jamie · logged by Alex | Donné par Jamie · enregistré par Alex | Only when the two differ |

## Absence planning

| Concept | English | French | Notes |
| --- | --- | --- | --- |
| Carer section heading | Who's caring | Qui s'en occupe | The canonical form always shows the answer: "Qui s'en occupe : Jamie". The question-mark version is for mockups only, never an empty state |
| Choose a carer | Choose a carer | Choisir qui s'en occupe | |
| Assigned carer | Assigned carer | Personne prévue | |
| Instructions | Instructions for the carer | Consignes | |
| Invite | Invite for this absence | Inviter pour cette absence | |
| Carer no longer available | Jamie can no longer see Buddy's plan. Choose someone else? | Jamie ne peut plus voir le plan de Buddy. Choisir quelqu'un d'autre ? | A calm, practical tone, never an alarm |

## Avoid

| Avoid | Why | Use instead |
| --- | --- | --- |
| *Prestataire* | Sounds commercial and administrative | The role plus the name |
| *Admin* | Cold, and inconsistent with the rest of the product | Organiser / Gère le foyer |
| Guest access | Suggests a lighter account | Temporary access / Accès temporaire |
| *Proches & gardes*, *Gardes* | *Garde* can mean a guard, a duty shift or custody | Proches & pet-sitters, Proches |
| *Quitter le foyer* | Carries the connotation of separation law | Quitter « \<nom du foyer\> » |
| Gendered job titles (*Organisateur/trice*, *Promeneur/euse*, *Toiletteur/euse*, *Éducateur/trice*) | The data has no gender for people | Service labels or verb phrases |
| "Contact" in navigation | Makes the feature feel like an address book | Person, Coordonnées |
| "Care team" as the page name | Already defined as the carers on an absence | People / Autour de vos animaux |
| "At home" for anything except the pet-profile group | Clashes with the care setting, and with having several households | Household names, "Anyone in the household" |
| Question prompts in empty states ("Who'll be handling…?") | Goes against [copy-tone.md](/docs/design/copy-tone.md) | Labels that show an answer |
