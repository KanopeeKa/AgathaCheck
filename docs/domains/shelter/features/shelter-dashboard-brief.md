---
title: Shelter dashboard and shelter architecture brief
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
> **Status:** Locked master brief (source of truth). **IA superseded by Organisation v2** — see
> [`/docs/domains/shelter/changes/organisation-v2-delivery-plan.md`](/docs/domains/shelter/changes/organisation-v2-delivery-plan.md) (D-v2-IA-1/2):
> `/o/orgs/:id` is a profile composer; the section-card dashboard is no longer the primary entry.
> Do not edit inline — track deviations in
> [`/docs/experience-program/decisions-log.md`](/docs/experience-program/decisions-log.md) and feature-level detail in
> [`/docs/domains/shelter/changes/phase-3-organisation-presentation.md`](/docs/domains/shelter/changes/phase-3-organisation-presentation.md),
> [`/docs/domains/fostering/changes/phase-4-foster-pet-operations.md`](/docs/domains/fostering/changes/phase-4-foster-pet-operations.md), and
> [`/docs/domains/shelter/changes/phase-5-organisation-customisations.md`](/docs/domains/shelter/changes/phase-5-organisation-customisations.md).
> Imported verbatim 2026-07-25. This brief predates and must be reconciled with the shipped
> fostering platform (`//docs/domains/fostering/features/g0-contract-pack.md`) — see decisions log D7–D10.

# Organisation dashboard and organisation architecture brief

## Purpose

Design the Organisation area as a modular, role-aware product space with a simple top-level dashboard and a structured internal organisation architecture. The Organisation dashboard itself should stay light, while the inside of each organisation should provide clear entry points into organisation presentation, people, pets, foster operations, connected organisations, and organisation-level configuration [web:97][web:100][web:105].

This brief is written to be readable by both humans and AI implementation tools. It defines the information architecture, naming, object model, permissions logic, and UI behavior while leaving room for the implementation system to apply its own layout, styling, component patterns, and code conventions.

## Core principles

The Organisation area should follow these principles:

- Keep the Organisation dashboard itself simple
- Treat roles and permissions as distinct concepts
- Use standard roles as permission bundles
- Allow controlled permission overrides where needed
- Keep the inside of each organisation modular
- Separate public information, internal directories, operational workflows, and configuration
- Enforce permissions in the backend, with the UI reflecting allowed actions rather than acting as the security layer [web:100][web:105][web:109]

## Top-level Organisation dashboard

The Organisation dashboard should remain intentionally simple and should not try to expose all operational complexity at the top level. It should include only the following dashboard sections:

- My Organisations
- Discover Organisations

### My Organisations

Display the organisations the user belongs to as tiles. The section should include a clear **Add an organisation** action.

### Discover Organisations

For now, this should display the list of all organisations in the app as tiles. This is a discovery and entry point layer only.

### Dashboard rule

All meaningful operational actions should happen within an organisation, not on the top-level Organisation dashboard.

## Internal organisation model

Entering an organisation should open an internal dashboard rather than a single long page. That internal dashboard should present modular section cards that link to dedicated screens.

Recommended top-level sections inside an organisation:

- Organisation presentation
- Admin contacts
- Fosters
- Pets
- Connected organisations
- Legal & Documents
- Organisation customisations (super admin only, accessed from edit/admin area)

This modular structure is recommended because the organisation contains multiple object types with different visibility rules and lifecycle actions. A single long page would become difficult to scan, maintain, and permission-gate cleanly [web:97][web:109].

## Roles and permissions model

### Core distinction

The product must explicitly distinguish between:

- **Permissions**: atomic capabilities, such as edit organisation profile, add foster, validate home visit, or manage foster sessions
- **Roles**: reusable bundles of permissions assigned to people within an organisation

Roles should be the default mechanism for access control. Permissions may also be explicitly added to individuals or, where allowed, layered into role definitions for a given organisation. This should be documented and auditable, because ad hoc exceptions are useful but can quickly become hard to reason about if they are invisible [web:100][web:105][web:109].

### Permission rules

Use the following design rules:

- Default to standard role bundles
- Allow explicit permission overrides where needed
- Keep overrides visible and traceable
- Use least privilege by default
- Keep “permission to change permissions” narrowly scoped
- Reflect permissions in the UI, but enforce them in the backend [web:100][web:105]

### Recommended standard roles

Use a clearer first-pass naming system for visible roles:

| Role | Purpose |
|---|---|
| Associate | Basic internal member with limited access to internal organisation information |
| Foster | Person who fosters animals and manages their own relevant profile and care workflows |
| Foster Admin | Person who manages foster onboarding, validation, status, and foster operations |
| Pet Admin | Person who manages organisation pets and foster-session operations |
| Team Admin | Person who manages internal admin/team directory operations |
| Super Admin | Person who governs the organisation, manages sensitive settings, and can control role/permission structures |

These role bundles are a base model and should remain extensible. Some organisations may need extra permissions granted to selected individuals without creating a whole new visible role.

### Initial permission matrix

This is a recommended evolved base matrix derived from the described needs. It is a starting point, not a final exhaustive security model.

| Permission | Associate | Foster | Foster Admin | Pet Admin | Team Admin | Super Admin |
|---|---|---|---|---|---|---|
| View public organisation presentation | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| View internal organisation dashboard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| View legal & documents (read-only, as allowed) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| View org contact details | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Edit organisation profile | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| Delete organisation | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| Invite / remove members | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ |
| Manage role bundles / permission matrix | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| Add explicit permission overrides | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| View admin contacts directory | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Add admin contact | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| Edit / delete admin contact | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| View foster directory | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Add foster | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| Confirm foster | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| Pause foster | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| Archive foster | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| Add organisation note on foster | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| Validate home visit | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| View all org pets | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ |
| Add a pet | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ |
| Edit pet | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ |
| Manage foster sessions from pet side | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ |
| Create foster session from foster profile | ✗ | ✗ | ✓* | ✓* | ✗ | ✓ |
| Transfer ownership / adoption outcome | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ |
| Share pet as foster | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Day-to-day fostered pet care actions | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ |
| View connected organisations | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Connect organisations | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| Manage organisation customisations | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |

`*` Creating a foster session from a foster profile should require foster-level operational authority and should only be granted where both the workflow and the individual’s permissions justify it.

This matrix should be treated as the initial baseline. The real permission system should be designed so it can evolve without breaking existing role assignments.

## Organisation presentation

### Purpose

The organisation presentation area is the public identity and basic legal/contact layer of the organisation. It should be visible to everyone and should communicate trust, legitimacy, and contact clarity.

### Layout

The top of the organisation should include:

- A cover image across the top
- A round organisation logo overlapping the lower-left edge of the cover
- Organisation name next to the logo
- A short legal-information block below
- Contact details below that

### Legal information

Show a concise legal-information summary under a clearly labeled **Legal information** area rather than exposing every field in the visual hero itself. For French organisations, a sensible minimum legal baseline to support is:

- Legal name
- Registered address
- RNA number, where relevant
- SIREN and/or SIRET where applicable [web:84][web:82][web:102]

The association is automatically registered in the National Directory of Associations, and some associations must request SIRENE registration depending on their situation [web:84][web:102]. This means the product should support RNA and, where applicable, SIREN/SIRET rather than assuming every organisation has exactly the same identifiers [web:84][web:82].

### Contact details

Display:

- Phone number
- Email address

Each should provide a direct action:

- Call
- Email

### Legal & Documents

Documents should sit under the broader **Legal & Documents** section. For public or member-facing document consumption, a read-only slide-over is acceptable if the interaction is limited to reading or downloading a manageable set of documents.

Recommended use for this slide-over:

- Terms and conditions for foster families
- Agreements or public-facing organisation documents
- Legal documents intended for reference or download

The slide-over should support:

- Read
- Download
- Clear document grouping by type

If document management becomes more complex, editable, versioned, or template-driven, that configuration belongs in Organisation Customisations rather than in this public read-only surface.

## Admin contacts

### Visibility

The Admin contacts section should be visible to people with the appropriate internal visibility, including associates where intended by the organisation’s rules.

### Dashboard preview

The organisation internal dashboard should show a preview set of admin contacts as tiles with:

- Photo
- Name
- Optional role/specialty summary

The section ends with **See all**.

### Admin contacts screen

The dedicated Admin Contacts screen should function primarily as a directory first and an admin-management surface second.

People without Team Admin permissions should be able to:

- View the list of admins
- Open a person card
- See photo, contact details, and description
- Call and/or send a message in app

People with Team Admin permissions should additionally be able to:

- Add an admin

People with Super Admin permissions should additionally be able to:

- Edit an admin card
- Delete an admin

### Self-card rules

If the current user is an admin and their card appears in the list:

- Their card should appear first
- Remaining cards should follow alphabetical ordering by last name
- Their own card should have a clear highlighted treatment
- They should be able to edit their own card
- They should be able to control profile visibility and message-notification preferences

### Self-managed admin preferences

An admin should be able to control:

- Who can see their phone number: fosters, admins, all, nobody
- How they want to be notified when someone messages them: in app and/or email

## Fosters

### Dashboard behavior

The internal organisation dashboard should expose this section differently depending on the user:

- If the current user is a foster, show their own foster card first with clear highlight treatment
- If the user has Foster Admin permission, show a preview of the top three fosters and a **See all** link

### Foster screen

The dedicated Foster screen should be the main directory and management view.

People without Foster Admin permission should be able to:

- View the list of fosters
- Open a foster card
- See profile and allowed contact details
- Call and/or send a message in app

People with Foster Admin permission should additionally be able to:

- Add a foster
- Confirm a foster
- Pause a foster
- Archive a foster
- Add an organisation note
- Create a foster session from the foster profile where the required pet-operational permission is also present
- See the full foster information allowed by policy

### Foster self-management

If the current user is a foster and their card appears in the list:

- Their card should appear first
- Remaining cards should follow alphabetical ordering by last name
- They should be able to edit their own card
- They should control who can see their details: other fosters, admins, both, nobody
- They should control whether their address is fully visible, town only, or hidden
- They should control whether visible viewers can see email, phone, or neither
- They should control how they are notified when messaged: in app and/or email

### Foster card structure

The foster card should use modular stacked sections rather than one long mixed card. Recommended sections:

- Profile
- Onboarding
- Foster sessions
- Documents & agreement
- Internal notes (permission-restricted)
- Adopted pets

### Foster profile section

Compulsory fields:

- First name
- Last name
- Address (for legal documents)

Optional but recommended:

- Phone number

### Onboarding section

The onboarding section should preserve process integrity and auditability.

It should include:

- The onboarding form responses submitted for this organisation
- Support for multiple onboarding records if the foster has completed onboarding for more than one organisation
- A way to redo the onboarding form, which restarts the onboarding process rather than silently editing prior answers
- Date of home visit
- Name of the Foster Admin who carried out the home visit
- Name and date of the Foster Admin who validated the foster
- Signed agreement documents, where applicable
- The foster’s agreement to follow organisation rules and terms

### Agreement withdrawal behavior

If a foster unticks their agreement to follow the rules and terms:

- The system should explain the consequences clearly
- The foster should be warned they will be paused
- The flow should explain that active foster sessions may be terminated or affected
- The foster should be asked to confirm intentionally
- The foster should type **withdraw** to confirm the withdrawal action
- The organisation should be notified

This is a high-friction flow by design and should be treated as a serious status-changing action.

### Foster sessions section

Use two tabs:

- Current
- Past

Show reusable foster-session cards containing:

- Photo and name of pet
- Photo and name of foster
- Start date / end date
- In view of adoption flag where relevant
- Session status

### Adopted pets section

Show the list of pets adopted by that foster from the organisation. These are shadow pets from the organisation point of view.

If there are none, show **None yet**.

## Pets

### Domain model

There is one underlying pet object, but its legal guardianship context may differ.

- For organisation pets, the legal guardian is the organisation, while operational day-to-day care may be performed by a foster
- For guardian pets, the legal guardian and day-to-day carer are typically the same person
- When a pet is adopted, legal guardianship may transfer
- A shadow pet is the historical organisation-side snapshot after adoption and can be reactivated by re-merging with the live pet object if the pet returns

This model should be explicitly preserved in both product logic and implementation.

### Dashboard preview

Inside the organisation dashboard, the Pets section should show the first 12 pets ordered by latest added first. The section ends with **See all**.

Tapping a pet opens the pet card, with sections visible according to permissions.

### Pet screen

The full pet screen should provide tabs for quick filtering:

- Need attention
- In foster
- Adopted
- All

### Need attention definition

A pet is in **Need attention** if:

- It has been added but is not currently in foster, or
- It is in foster but the foster placement finishes in the next 10 days and no adoption or next fostering session is planned yet

The UI should provide a tooltip explaining this category. Pets in this category should also show a short explanatory line such as:

- Not in foster
- Foster finishing soon

### Filters

Support filters on:

- Name
- Fostered by
- Shadow
- Rainbow bridge

### Pet actions

People with Pet Admin permission should be able to:

- Add a pet
- Add or manage foster sessions / journeys from the pet side
- Manage and edit the pet

## Connected organisations

This section should list all connected organisations.

Behavior:

- Show all connected organisations if they exist
- Show **None yet** if none exist
- Provide a **Connect** action to search for another organisation

## Organisation customisations

### Visibility

This section is visible only to Super Admins and should be accessed from the organisation’s edit/admin layer rather than from the public-facing presentation surface.

### Purpose

Organisation Customisations is the organisation-level configuration area for deeper operational setup.

### Initial scope

The section should support at least:

1. **Templates**, scoped by journey
   - Example: onboarding foster journey
   - Documents to upload
   - Agreement templates for online signing
   - Email templates

2. **Roles and permissions**
   - Standard role bundles
   - Permission matrix
   - Explicit permission additions where allowed

This area should be treated as an admin/configuration workspace rather than a public or directory-facing screen.

## Permission-display guidance

Because this product has complex role and exception logic, the UI should clearly communicate why some actions are visible or hidden. This can be done through consistent action placement, disabled states where appropriate, and role-aware screen composition, but the underlying access control must still be enforced in the backend [web:97][web:100][web:105].

The specification should preserve a strong distinction between:

- Can view
- Can contact
- Can edit
- Can manage lifecycle state
- Can manage permissions

These must never be conflated.

## Mobile and UX expectations

The organisation area should remain mobile-first even though it is operationally complex. Internal dashboards should prioritize clear section entry points over dense admin layouts. Dedicated screens should carry the operational weight, while dashboard previews remain concise and scannable.

The interface should avoid turning into a corporate admin panel. It should feel like a humane operational workspace for shelters, fosters, and coordinators.

## Guardrails

The implementation should avoid the following pitfalls:

- Mixing roles and permissions as if they were the same thing
- Hiding permission overrides so they become impossible to audit
- Building the inside of an organisation as one very long mixed page
- Mixing public identity, internal directories, and configuration into one surface
- Overloading the public organisation header with too many legal fields
- Treating the documents slide-over as a full document-management system
- Conflating contact visibility with edit permissions
- Conflating foster operational status with profile visibility
- Treating shadow pets as a separate unrelated pet object
- Making the top-level Organisation dashboard too operationally heavy

## Flexibility for implementation

This brief is intentionally structured and explicit on architecture, roles, and permission behavior, while remaining flexible on component design, layout detail, motion, and visual styling. The implementing AI or designer may choose the most appropriate component patterns provided the role model, modular organisation architecture, and permission logic remain intact [web:97][web:109].

The final experience should support long-term maintainability, modular screen construction, and future evolution of the role-permission system without breaking the underlying conceptual model.
