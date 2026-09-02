---
title: AgathaTrack redesign blueprint
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-26
tags: [design,ui,ux]
---
# AgathaTrack redesign blueprint

**Status:** Design plan — no implementation commitment

**Purpose:** A screen-by-screen, decision-led blueprint for completing the AgathaTrack redesign without reopening locked product choices.

**Read with:** `docs/domains/navigation/README.md`, `docs/design/tokens.md`, `docs/design/copy-tone.md`, and `docs/e2e/navigation-contract.md`.

---

## 1. What this redesign is trying to achieve

AgathaTrack should feel like a calm, dependable care desk: a place where a guardian, foster parent, or shelter worker can quickly understand what needs attention and take the next safe action.

This is **not** a social pet app, a generic admin dashboard, or a dense data console. It is an operational product for care coordination. The visual system should therefore favour:

1. **Orientation before action** — make the current place, current pet/organisation, and next important item immediately clear.
2. **Progressive disclosure** — show a useful summary first; put detailed management on its own destination.
3. **Calm, high-contrast hierarchy** — use colour and emphasis to communicate meaning, never decoration alone.
4. **Continuity across roles** — the product stays recognisably AgathaTrack whether a user is in Pet Care, Shelter, foster, or Account context.
5. **Safety in high-stakes actions** — destructive actions, care completion, role changes, privacy changes, and foster workflow transitions must be explicit, reversible where possible, and clearly explained.

### Success measures

- A returning guardian can find the next due care action without scanning a mixed feed.
- A shelter member can enter the correct organisation workspace from a simple root, then find a people, foster, pet, or administration destination without a global sitemap.
- A user understands whether they are on a root surface, a list, a detail, or a form from navigation and page structure alone.
- A user never has to infer status from colour only.
- English and French versions preserve hierarchy, meaning, and action clarity.

---

## 2. Non-negotiable product decisions

This blueprint implements the decisions below; it does not reinterpret them.

| Area | Locked direction | Design consequence |
|---|---|---|
| Global navigation | Hamburger is a sparse section switcher on compact widths only. Pet Care and Shelter are peers; Account is globally separate. On medium+ Pet Care widths, leading nav (D-v4-4) replaces the drawer for primary destinations. | Do not put Events, Vets, People, Fosters, Settings, or generic Home in the drawer. Do not duplicate the five Pet Care destinations in drawer and leading nav. |
| Header | Root surfaces use workspace toggle (compact: app bar; medium+: sidebar header). Sub-screens use back navigation. Authenticated screens retain a global bell. Medium+ content headers carry page title + contextual actions. | Avoid a persistent “Home” button, stacked tab bars, or duplicate navigation chrome. |
| Pet Care home | Exactly **My Pets**, **Due and Overdue**, and **My Vets** management sections. Today is a compact orientation layer above them. | Today cannot become a fourth section, a tab, a standalone feed, route, or backend event model. |
| Pet Care data semantics | Today is presentation over existing data; care completion and undo remain server-authoritative. | Do not invent client-only status or “completed” states that can disagree with the backend. |
| Organisation root | A calm workspace selector, not a combined pet/event dashboard. | The root shows membership cards and the path into a selected organisation; it does not duplicate organisation operations. |
| Organisation profile | `/o/orgs/:id` is the profile composer and local navigation surface. | Keep it as a profile/header plus rows; no second primary presentation destination. |
| Organisation navigation order | Admin contacts → People → Foster parents → Fostering sessions → Pets → Connected organisations → Organisation Administration. | Preserve this sequence whenever permissions make a row visible. |
| People | People is visible to all organisation members; per-person actions remain permission/privacy-gated. Admin contacts is People filtered to admins. | Never build a second competing Admin Contacts directory. |
| Organisation administration | One Super Admin-only local destination. | Keep roles, permissions, templates, and organisation-level settings grouped there. |
| Notifications | One global bell and unified slide-over; Care and Organisation are filters, not separate apps. | Do not create an Organisation notification centre or a second bell. |
| Account | Global, personal, and visually distinct from operational work. | Keep profile, cross-org preferences, help/legal, sign-out, and per-org personal settings under Account. |
| Landing/auth | One role-neutral entry path. Experience context resolves after authentication. | Do not ask users to choose Pet Care/Shelter/Foster before sign-in. |
| Branding | Organisations can personalise logo, name, and approved image surfaces only. | System colours, focus, danger, warning, success, and contrast remain product-controlled. |

The governing decisions are D1–D11, D17–D18, D25–D37, D-v2-*, D-v3-*, D-v4-*, and D-v4-1–D-v4-5 in the domain decision docs indexed at `docs/domains/navigation/README.md`.

---

### 2.1 Pet Care Today mobile refinement

The Pet Care home uses a content-first mobile treatment. This refinement **supersedes** the earlier three-section visual composition without changing the underlying care, ownership, notification, or Shelter permission contracts.

- The Pet Care mobile bar exposes **Today, Pets, Care, Fostering, and Account** (D-v4-1). The workspace toggle remains for Pet Care/Shelter switching on compact widths; the notification bell remains global.
- The home begins with a horizontally scrollable, capped four-pet preview and a lightweight Add Pet control; visual section headings may be omitted where the region remains semantically labelled.
- Care is a pale-plum contextual region with `CARE`, **Due** and **Soon** controls, a total due/overdue count, and no more than three rows per preview. Due is ordered oldest-overdue first, then due today; Soon is ordered soonest first.
- Direct care completion, refresh, failure rollback, Undo, routing, and the full unified Care destination remain server-authoritative and unchanged.
- Veterinary contacts remain a lightweight, display-first surface with Add Vet and existing routes.
- Fostering and Shelters use a pale-teal context. Pet Care home only shows details already visible through established fostered-pet relationships; pending placements remain notification-led and unavailable session detail is stated plainly.
- View all appears only when a preview is truncated. Empty, loading, and error states must never assert that care or sessions are absent when data failed to load.

### 2.2 Pet Care adaptive leading navigation (tablet / desktop)

On widths where the bottom bar is hidden, the same five destinations (D-v4-1) appear in **leading application chrome** (D-v4-4, D-v4-5):

| Width | Chrome | Behaviour |
|-------|--------|-----------|
| &lt;600px | Bottom bar | Unchanged (D-v4-1); drawer available for workspace switch |
| 600–839px | Navigation rail | Icon + label destinations; workspace toggle in rail header |
| ≥840px | Expanded sidebar (~240px) | Full labels; workspace toggle + brand in sidebar header; Account pinned at bottom |

**Rules:**

- Preserve the **same routes and mental model** as compact — do not invent different destination names.
- The hamburger drawer is **hidden** when leading nav is visible; it must not duplicate the five destinations.
- The content header on medium+ becomes functional: page title, contextual actions, notification bell — not a centred logo reproduction of the mobile app bar.
- Leading nav remains visible on nested Pet Care workspace routes (pet detail, care forms, etc.) with tab highlighting derived from the closest primary destination (same semantics as PR #767 compact bottom nav).
- Shelter-specific sidebar IA is a follow-on; this slice is Pet Care-only.

---

## 3. Design principles

### P1 — Calm does not mean low-information

Use whitespace, grouping, and restrained surfaces to make information easier to scan. Do not hide essential operational context merely to make a screen look minimal.

**Apply it by:**

- using a short status summary before lists;
- grouping related actions under one clear heading;
- limiting dashboard previews rather than showing every record;
- allowing full destinations to carry the complete management density;
- using explicit empty, loading, error, and permission-denied states.

### P2 — One primary action per decision point

Every screen may contain many links, but it should have one visually dominant action that matches the user’s most likely next step.

**Examples:**

- Auth: Sign in or Create account, depending on the selected state.
- Pet Care Today: complete the most urgent care action only when that action is clearly safe.
- Organisation root: enter an organisation workspace; Create organisation is secondary to existing memberships.
- People: Add or invite only when the user has permission.
- Forms: Save/Create; Delete is separated and never visually adjacent as an equal peer.

### P3 — Context is a safety feature

The user should always be able to answer:

1. Which experience am I in?
2. Which pet or organisation does this item belong to?
3. What will happen if I take this action?
4. How do I return without losing my work?

Use clear page titles, ownership/status labels, back navigation, descriptive confirmations, and contextual subtitles to answer those questions.

### P4 — Colour carries meaning, not identity alone

Use the locked Pet Care plum and Organisation teal as contextual primaries. Use warm coral only as an accent. Reserve success, warning, danger, and priority tokens for their semantic meanings.

Every coloured state needs a text label, icon, shape, or position cue in addition to colour.

### P5 — Lists are operational tools

List rows and cards need a predictable anatomy:

- recognisable identity (photo/avatar or accessible placeholder);
- primary label;
- secondary context;
- state/ownership/role label where relevant;
- a single clear tap target;
- optional count or trailing affordance only when it helps scanning.

Avoid decorative cards that obscure which portion is tappable.

### P6 — Detail pages explain; lists navigate

Root and directory screens should navigate. Detail screens should provide context, status, actions, and related sections. Forms should focus on editing one decision at a time.

### P7 — Permission gates must be quiet but clear

Do not expose disabled controls without explanation. Show a visible local destination when all members may enter it, then gate private actions within the destination. When an entire section is unavailable, omit it rather than creating a misleading dead end.

### P8 — Never sacrifice accessibility for the visual treatment

All interactive surfaces require meaningful semantics, stable labels, visible keyboard focus, 48dp minimum touch targets, and a usable Flutter web accessibility tree. Design accepts long localized labels and text scaling from the start.

---

## 4. Visual language and system guidance

### 4.1 Palette roles

Use the existing semantic token system rather than scattered literal values.

| Role | Pet Care | Shelter | Usage |
|---|---|---|---|
| Context primary | Plum | Teal | primary buttons, active contextual controls, selected local state |
| App canvas | Warm paper / neutral | Warm paper / neutral | broad page background |
| Raised surface | White | White | cards, menus, sheets, input containers |
| Warm accent | Coral | Coral | restrained decorative accent, illustration detail, non-critical emphasis |
| Success | System green | System green | completed/saved/successful state only |
| Warning | System warning | System warning | overdue, needs attention, confirmation friction |
| Danger | System danger | System danger | deletion, urgent administrative alert, destructive confirmation |

**Do not:**

- use organisation logo colours as the primary action colour;
- use coral for destructive actions or warning states;
- use red as a normal count badge;
- use a different colour family for each screen;
- rely on the Pet Care/Shelter primary colour to communicate access rights.

### 4.2 Surface and elevation rules

1. The page background is quiet and warm.
2. White cards separate actionable content from the canvas.
3. Use borders and tonal contrast before heavy shadows.
4. Reserve stronger elevation for overlays: dialogs, the notification panel, bottom sheets, and menus.
5. Do not put every section inside a card. A dashboard section can be a heading plus a contained list.

### 4.3 Type hierarchy

Use Material typography roles, with consistent semantic intent:

| Role | Purpose |
|---|---|
| Display/headline | landing value proposition, major hero titles only |
| Title large | page title / organisation name band |
| Title medium | section headings and card headings |
| Body large | primary operational content |
| Body medium | supporting descriptions and metadata |
| Label large | buttons, chips, compact status labels |

Rules:

- Page titles may wrap to two lines; do not shrink below the locked minimum legibility threshold.
- Metadata must not visually compete with the primary label.
- Uppercase is not a status strategy.
- Truncate only after allowing the intended wrapped title treatment.

### 4.4 Spacing and density

Use a consistent rhythm based on the documented token scale. The experience should feel composed rather than sparse:

- 8dp: related text/icon spacing;
- 12–16dp: within a compact row/card;
- 16–20dp: between related groups;
- 24–32dp: between major sections;
- 48dp minimum touch target, even when visual controls are smaller.

For dense operational lists, preserve touch targets and label legibility rather than reducing spacing below the minimum.

### 4.5 Motion

Motion should confirm hierarchy, not entertain:

- drawer and notifications panel: directional slide;
- route/content swaps: brief fade/slide aligned to navigation direction;
- completion/undo: small state transition plus plain confirmation;
- no looping animation beyond loading affordances;
- honour reduced-motion platform settings.

---

## 5. Information architecture blueprint

### 5.1 Authenticated global structure

```text
Authenticated app
├── Pet Care root (/pc/home)
│   ├── My Pets
│   ├── Due and Overdue
│   └── My Vets
├── Organisation root (/o/home or /o/orgs)
│   └── Organisation workspace (/o/orgs/:id)
│       ├── Admin contacts → People filtered to admins
│       ├── People
│       ├── Foster parents
│       ├── Fostering sessions
│       ├── Pets
│       ├── Connected organisations
│       └── Organisation Administration (permission-gated)
└── Account (/account)
    ├── personal profile and preferences
    ├── per-organisation personal settings
    ├── help, legal, and about
    └── sign out
```

### 5.2 Global drawer card

**Purpose:** Switch between peer sections only.

**Content:**

1. Pet Care
2. Organisation
3. Divider / breathing space
4. Account pinned to the bottom

**Rules:**

- Organisation visibility follows the locked member/toggle rule.
- The active section is obvious using label, primary context colour, and selected surface treatment.
- No global “Home.”
- No Events, Vets, notifications, settings, people, or foster operations in this drawer.
- Opening a peer section lands on its root surface, not its latest deep route unless the established route-resume logic says otherwise.

### 5.3 Global bell card

**Purpose:** One stable entry point for all notifications.

**Structure:**

- Bell button with combined unread badge.
- Right-side, full-height slide-over.
- Title and compact unread summary.
- Filter chips: All / Care / Organisation.
- Date-grouped list below.
- Urgent administrative items are visually prioritised within their filter, but remain administrative items.

**Row anatomy:**

- leading kind/status icon;
- concise title;
- contextual subject (pet, organisation, person where permitted);
- timestamp or due timing;
- unread treatment;
- resolved treatment only for derived actionable administrative items.

**Do not:** create a parallel organisation inbox, manual “resolved” control for Care, or permanent dashboard alert banners duplicating this feed.

---

## 6. Design cards: entry and first-run

### Card A — Landing

**Job:** Establish trust and move users into one universal authentication path.

**Audience:** new and returning users, regardless of eventual role.

**Hierarchy:**

1. AgathaTrack brand mark and product name.
2. Calm, operational headline: care coordination for guardians, shelters, and foster teams.
3. One short supportive paragraph, not a feature wall.
4. Primary action: Sign in.
5. Secondary action: Create account.
6. Quiet support/legal links.

**Visual direction:** Operations Desk — deep olive grounding, warm paper surfaces, muted gold/shelter-arch details used sparingly. The visual language should imply a trusted desk and a place for care records, not a consumer pet marketplace.

**Interaction rules:**

- Both primary actions lead to the same role-neutral auth flow.
- Do not place role selection before authentication.
- Preserve the native HTML password-manager bridge on Flutter web.
- Do not make a decorative hero image the only carrier of meaning.

**Empty/error treatment:** Auth errors appear near the form, are specific, do not blame the user, and retain entered non-sensitive data where safe.

### Card B — Sign in / Create account / Reset password

**Job:** Make the next step unmistakable and safe.

**Layout:**

- focused form column;
- clear label above/with every field;
- one primary submit action;
- secondary text link for switching mode;
- visible password requirements before a user submits an invalid password;
- an accessible back/close route only where the flow is genuinely dismissible.

**Design guidance:**

- Keep the brand area visually quieter than the form after first view.
- Do not use cute validation copy.
- “Forgot password?” is available but not prominent enough to compete with Sign in.
- Confirmation screens name what was sent or changed without revealing sensitive account detail.

### Card C — Experience resolution and chooser

**Job:** Resolve context after sign-in without forcing users to understand the product architecture.

**Rules:**

- Returning users resume their established/last-active experience according to the locked route rules.
- New accounts may see the role-neutral chooser only when it is required.
- Pet Care and Shelter options are peers, not an identity test.
- Organisation onboarding redirection behaviour remains intact.

---

## 7. Design cards: shared authenticated shell

### Card D — Root app bar

**Applies to:** Pet Care root and Organisation root.

**Anatomy:**

- leading hamburger;
- context/brand area;
- persistent bell;
- no generic Home action;
- no top-level tab strip.

**Pet Care context:** quiet AgathaTrack identity plus Pet Care-primary accents.

**Organisation root context:** quiet AgathaTrack identity plus Organisation-primary accents.

**In-organisation context:** organisation logo thumbnail and title, bell retained; follow locked title wrapping/truncation rules.

### Card E — Sub-screen app bar

**Applies to:** detail, directory, form, care, and local organisation destinations.

**Anatomy:**

- back control;
- contextual title;
- bell;
- one optional action only where the screen’s primary action belongs in the app bar.

**Rules:**

- Back navigation must preserve deep links and browser expectations.
- Do not replace the back button with hamburger on local screens.
- If a title is long, wrap then reduce only within the locked rules before ellipsising.

### Card F — Loading, empty, error, and permission states

Every high-level surface needs all four states designed before implementation.

| State | Required content |
|---|---|
| Loading | reserved layout space/skeleton or calm progress state; do not cause major layout jumps |
| Empty | precise explanation and one appropriate action, if any |
| Error | plain language, retry where meaningful, no raw backend message |
| Permission-restricted | explain only when the user can reasonably expect the item; otherwise omit private action surfaces |

---

## 8. Design cards: Pet Care experience

### Card G — Pet Care Today orientation layer

**Job:** Answer “what matters now?” without becoming a fourth dashboard section.

**Position:** directly under the Pet Care root header, before My Pets.

**Content, in priority order:**

1. compact greeting/time orientation only if it adds value;
2. short care status sentence — for example, “2 care items need attention”;
3. one to three prioritised care previews;
4. a safe route into the Due and Overdue section;
5. no independent Today feed, route, tab, or universal add button.

**State treatment:**

- Due: clear but restrained attention treatment.
- Overdue: warning/danger semantics plus plain “Overdue” label.
- Completed: server-confirmed change with temporary undo where the established care flow supports it.
- Loading/error: do not make the rest of the Pet Care dashboard unusable.

### Card H — My Pets

**Job:** Give guardians a bounded, recognisable snapshot of their care responsibility.

**Rules:**

- Maximum 4 dashboard preview cards.
- Each preview card has a roughly 96–112px photo region, accessible photo placeholder, pet name, and useful ownership/status context.
- The card tap opens the existing full pet destination.
- The section action opens the full pets list.
- Relationship/shared/foster semantics remain visible where relevant; never imply exclusive ownership by default.

**Card anatomy:**

```text
[photo / labelled placeholder]
Pet name
Relationship or care context
Optional concise status
```

### Card I — Due and Overdue

**Job:** Present care priorities, not a generic event chronology.

**Rules:**

- “Events” means computed health, weight, and other care entries only.
- Sort by the existing due ordering.
- Limit the dashboard preview to 5 care items.
- Each item identifies pet, care type, due state, due date/time where applicable, and a direct safe action.
- Completion cannot be represented as a local-only UI toggle.
- The full destination remains `/pc/events`.

### Card J — My Vets

**Job:** Keep veterinary contacts easy to scan without changing the dashboard into a directory.

**Rules:**

- Compact, uncapped row list.
- Show identity and most useful contact/location context.
- A section-level route opens the full vets destination.
- Vet detail is display-first: Call/Email actions are immediately visible where contact data permits; editing is a separate, deliberate action.

### Card K — Pet detail and timeline

**Job:** Make one pet’s care history understandable without mixing it into the dashboard.

**Structure:**

- pet identity and status context;
- key care actions;
- clear sections for health, weight, documents, sharing, and timeline as authorised;
- per-pet timeline for custody segments, fostering sessions, and manual fallback entries.

**Rules:**

- Timeline is not a Pet Care dashboard feature.
- Redacted organisation-pet views show only permitted information and do not leak timelines, sessions, health, or documents.
- Share and custody actions state their impact and recipient/context before confirmation.

---

## 9. Design cards: Organisation experience

### Card L — Organisation root workspace hub

**Job:** Let a person select the organisation they need to work in.

**Hierarchy:**

1. Organisation workspace header: “Shelters dashboard” / localised equivalent.
2. Short explanatory line about memberships/invitations.
3. “My Organisations” heading.
4. Membership cards.
5. Secondary create-organisation action.
6. Discover entry as the approved dedicated navigation row.

**Membership card anatomy:**

- logo or accessible initial/placeholder;
- organisation name;
- organisation type;
- member/pet counts where available and useful;
- one clear tap target;
- no embedded operational pet/event preview.

**Rules:**

- Do not block the root on unrelated pet or event provider failures.
- Empty membership state explains how to create or join an organisation.
- Create remains available, but it should not visually dominate real memberships.
- Discover is a dedicated destination, not an inline tile grid.

### Card M — Organisation profile composer

**Job:** Establish organisation identity, show public/member context, and route people into local operational areas.

**Structure:**

1. identity header: logo/name/photo where available;
2. public contact/legal/presentation information as appropriate;
3. member-local navigation rows in the locked order;
4. edit action only when permitted;
5. no duplicate preview dashboards for People, Pets, Connections, or Fosters.

**Locked navigation row order:**

1. Admin contacts — opens People filtered to admins.
2. People — all organisation people.
3. Foster parents.
4. Fostering sessions.
5. Pets.
6. Connected organisations.
7. Organisation Administration — Super Admin only.

**Design rules:**

- Rows use a clear label, optional useful count, and chevron affordance.
- Each entire row is the hit target and exposes a button semantic label.
- Permission-gated rows are omitted when unavailable.
- Non-members see only the allowed public profile tier.
- `/presentation` remains a redirect to this profile; it does not receive a second primary design.

### Card N — People directory

**Job:** Give all organisation members one understandable people inventory while protecting private actions.

**Structure:**

- title and local context;
- filters/chips for People, Admin contacts, foster-related views, and invite status where relevant;
- self card pinned first;
- remaining people alphabetically by last name;
- tile-level actions only where the viewer has permission.

**Tile anatomy:**

- avatar/photo/initials;
- person name;
- role label;
- foster badge where applicable (a relationship/status, never a wire role);
- minimal visibility/contact context;
- optional action affordance only when allowed.

**Rules:**

- Admin contacts is this screen with `filter=admins`, not a separate directory.
- A person’s private contact data must follow existing visibility rules.
- Messaging and phone actions follow locked capability rules; do not imply a chat system where none exists.
- Bulk Change role routes to Roles & Permissions with the selected people preserved.

### Card O — Foster parents and fostering sessions

**Job:** Support operational fostering work without conflating people, placement state, and account role.

**Foster parents:** a focused operational directory, with clear foster badge/status and controlled actions.

**Fostering sessions:** a stateful list organised by current operational status, then a detail flow.

**Onboarding:** a vertical stepper with completed checkmark-in-disc, explicit future/deferred markers, and authorised override/confirm controls.

**Rules:**

- Keep foster identity distinct from membership role.
- Urgent agreement withdrawal remains rare, high-friction, and routes through the unified Administrative notification pattern.
- Do not silently cancel affected sessions; present paused/review-needed state.

### Card P — Organisation pets

**Job:** Provide an inventory and operational route into pet work.

**Guidance:**

- use filters/tabs with labels and non-colour selected state;
- preserve additive Rainbow Bridge/shadow filter semantics;
- show enough identity/status to scan the list;
- keep pet actions permission-aware;
- open authorised full pet detail; associates enter the redacted view where required;
- archival and transfer states are explicit and distinct from deletion.

### Card Q — Connected organisations and Discover

**Connected organisations**

- Show relationship identity, connection status, and a simple confirm before disconnect.
- Avoid destructive styling until the final confirmation.

**Discover organisations**

- Dedicated screen with server-backed search and preserved pagination.
- Public card fields remain limited to name, logo, locality, and description.
- Search supports clear input, debounce feedback, and no-results state.
- “Browsing as …” context is visible when relevant.
- Tapping a result enters its public/member profile route; discoverability/opt-out access rules are preserved.

### Card R — Organisation Administration

**Job:** Give Super Admins one bounded place for organisation-level governance.

**Sections:**

- Roles & Permissions;
- default permission sets;
- document, agreement, and email templates;
- other approved local workflow settings.

**Permission editing guidance:**

- staged changes, one Save action;
- visible unsaved-change marker;
- leave-without-save warning;
- role preset actions explain their reset effects;
- bulk indeterminate state is visible through control state and text, not colour alone;
- Detailed permissions is collapsed by default;
- broad default-set changes require an explicit impact confirmation.

---

## 10. Design cards: forms and high-friction actions

### Card S — Create/edit organisation

**Job:** Let Super Admins establish or edit organisation identity without a boxed, form-heavy visual experience.

**Structure:**

- shared template for Create and Edit;
- identity band: cover treatment + roughly 96px logo + name;
- grouped fields with helpful labels;
- Upload cover / Upload logo affordances with explicit JPG/PNG/WebP and size guidance;
- primary Create or Save;
- Cancel for Create;
- Delete only on Edit, visually and spatially separated from Save.

**Rules:**

- upload success/failure comes from real server outcomes;
- do not make photo/logo optionality look like validation failure;
- no separate “presentation” destination;
- legal identifiers use locale-appropriate labels, never French-only assumptions.

### Card T — Care entry and other operational forms

**Job:** Make date, dose, schedule, and care details hard to misunderstand.

**Rules:**

- every control has a durable text label;
- errors say what must be corrected;
- default values are visible and reviewable;
- date/time language is localised;
- Save has one primary position;
- cancellation warns only when meaningful unsaved work exists;
- success returns to the appropriate existing route with visible confirmation.

### Card U — Destructive and irreversible actions

**Use for:** delete organisation, delete pet/item, leave organisation, disconnect organisation, privacy-impacting change, broad permission reset.

**Confirmation anatomy:**

1. exact action title;
2. plain explanation of the impact;
3. affected subject named;
4. secondary cancel action;
5. danger-styled confirmation action only;
6. extra friction only where the real risk warrants it.

**Do not:** use generic “Are you sure?” language, hide consequences in small text, or make Cancel visually weaker than legibility allows.

---

## 11. Responsive and platform guidance

### Mobile

- Single primary column.
- Preserve 48dp targets and avoid horizontal chip overflow without a deliberate scroll/wrap solution.
- Cards may stack metadata under the title.
- The notification slide-over becomes a full-width or near-full-width sheet while retaining its one-panel model.
- Profile navigation rows remain easy to tap and read; do not compress them into a grid.

### Tablet

- Use additional width for breathing room, not unrelated parallel panes.
- Organisation and people cards may become a measured grid only if identity and actions remain equally legible.
- Maintain a single clear reading order.

### Desktop/web

- Constrain primary reading widths so dense screens do not become long unscannable rows.
- Root dashboards and organisation hub may use a wider content column, but preserve sequence and grouping.
- Keyboard navigation, visible focus rings, and semantic structure are first-class.
- Browser back/deep links must retain the same page hierarchy as in-app back navigation.

---

## 12. Accessibility, localization, and semantic requirements

### Accessibility checklist

- Every icon-only control has an accessible name.
- All clickable cards/rows expose one clear interactive semantic role.
- Semantic role fallbacks are supported for Flutter web where required: button first, then checkbox/tab/group as documented.
- A route transition is not considered complete until both the route and the destination’s ready semantic marker exist.
- Status does not depend on colour alone.
- Focus is visible on buttons, rows, inputs, filters, menus, and dialog actions.
- Dialogs, drawers, sheets, menus, and notification panels trap/restore focus correctly.
- Images have useful text alternatives or explicit decorative treatment.
- Empty and error states are announced and remain actionable.

### Localization checklist

- All visible strings use ARB resources.
- English and French are designed, not merely translated; longer French strings must retain hierarchy and tap target size.
- Enum labels shown to users are localised when touched.
- Dates, due-state language, and legal labels follow locale.
- Tests use English/French label patterns plus semantic identifiers where a label is intentionally flexible.

### E2E semantics checklist

- Prefer accessible role and name, then stable semantic identifier.
- Use direct URL navigation only as an instrumented last-resort fallback after a user-facing route has been attempted.
- Every navigation action waits for route **and** ready locator.
- Update page objects when a redesigned surface changes visible semantics; avoid per-test raw selectors.
- Test the locked Organisation row order and permission-aware visibility.

---

## 13. Delivery plan: design-to-implementation sequence

Each stage should be reviewed as a coherent visual slice. Do not merge visual change before its relevant states, semantics, localization, and regression expectations are addressed.

### Stage 0 — Design system guardrails

**Goal:** Confirm the reusable visual language before screen work spreads it.

1. Reconcile semantic tokens, typography, spacing, radius, elevation, focus, state, and motion roles.
2. Confirm Pet Care and Shelter contextual primaries without creating separate component systems.
3. Document standard cards, rows, banners, chips, input fields, dialogs, empty states, error states, and loading states.
4. Define a contrast and text-scaling review checklist.
5. Create lightweight component specimens for the shared patterns.

**Exit criteria:** a designer/developer can create a new screen without inventing a new card, colour, or spacing rule.

### Stage 1 — Landing and universal auth

**Goal:** Establish the Operations Desk visual direction and remove entry ambiguity.

1. Redesign landing hierarchy.
2. Refine sign-in, create-account, and password-reset form shells.
3. Preserve password-manager/autofill behavior.
4. Review error, loading, keyboard, and small-screen states.
5. Verify that no role selection occurs before authentication.

**Exit criteria:** one calm, role-neutral entry experience works across desktop and mobile widths.

### Stage 2 — Shared authenticated shell and notifications

**Goal:** Make global orientation consistent before redesigning destination content.

1. Finalise root and sub-screen app bar hierarchy.
2. Implement sparse global drawer.
3. Implement global bell panel hierarchy and filters.
4. Define Account’s global/personal visual treatment.
5. Validate navigation and deep-link behavior.

**Exit criteria:** users can reliably distinguish switching section, going back, opening notifications, and entering Account.

### Stage 3 — Pet Care home and care journeys

**Goal:** Make daily care work faster without changing existing authority or routing.

1. Design Today orientation layer.
2. Redesign My Pets bounded preview.
3. Redesign Due and Overdue preview and safe completion feedback.
4. Redesign My Vets compact list.
5. Extend the same patterns through pets, care details, care forms, vets, and weight.
6. Validate shared/foster/ownership context and undo behavior.

**Exit criteria:** Pet Care home contains exactly the locked three management sections and Today remains compact orientation only.

### Stage 4 — Organisation root and profile composer

**Goal:** Make the organisational path calm and legible.

1. Redesign the Organisation root as membership workspace hub.
2. Establish membership-card rules, empty state, create action, and Discover entry.
3. Redesign organisation identity/profile header.
4. Implement the locked local navigation-row sequence.
5. Check non-member public tier and permission-gated member rows.

**Exit criteria:** Organisation root does not contain mixed operations; profile is the clear route into local work.

### Stage 5 — Organisation operational destinations

**Goal:** Apply the system to people, foster operations, pets, discover, connections, and administration.

1. People directory and filtered Admin contacts.
2. Foster parents, sessions, and onboarding timeline.
3. Organisation pets, filters, archival/transfer routes, and redacted access.
4. Discover and connected organisations.
5. Organisation Administration and staged permission editing.
6. Create/edit organisation template and branding upload guidance.

**Exit criteria:** organisation work is discoverable through local routes, while individual controls remain permission/privacy safe.

### Stage 6 — Account and long-tail surfaces

**Goal:** Remove visual stragglers and clarify personal versus operational settings.

1. Account home and My Details.
2. Per-organisation personal settings.
3. Sharing, help, legal, GDPR, about, and subscription flows.
4. Empty/error/permission-state consistency sweep.

**Exit criteria:** no secondary flow looks like it belongs to a different product.

### Stage 7 — QA and consolidation

**Goal:** Verify that the redesign is usable, semantically stable, and consistent.

1. Visual review at mobile, tablet, and desktop widths.
2. Keyboard and screen-reader semantics pass.
3. English/French text expansion pass.
4. Widget and Playwright semantics review for changed journeys.
5. Confirm no global navigation, backend semantics, ownership, or care-completion decision drift.
6. Document any new design decision in the decisions log before implementation.

**Exit criteria:** no known visual/semantic regression remains, and all locked decisions are still demonstrably true in the product.

---

## 14. Per-screen design review card template

Use this card before changing any significant screen:

```md
### [Screen name]

**User job:** What must the user accomplish here?
**Entry routes:** Which existing routes/actions lead here?
**Primary action:** The single most important safe next action.
**Secondary actions:** Supporting destinations or contextual actions.
**Information hierarchy:** What appears first, second, and only on demand?
**States:** Loading / empty / error / permission-restricted / success.
**Navigation:** Root drawer or back navigation? What is the expected destination after completion?
**Accessibility:** Role/name semantics, focus order, touch targets, non-colour status.
**Localization:** English/French labels that may grow, date/number considerations.
**Data constraints:** Server authority, ownership/privacy/permission boundaries, existing route invariants.
**E2E hooks:** Stable semantic identifier or accessible label; expected route and ready marker.
**Locked decisions:** Decision IDs this screen must preserve.
```

---

## 15. Explicit anti-patterns

Do not introduce any of the following without a new recorded decision:

- ~~a five-tab bottom navigation bar;~~ **Superseded by D-v4-1** — approved for compact Pet Care primary nav only (Today, Pets, Care, Fostering, Account).
- ~~a horizontal website-style top navbar for Pet Care primary destinations;~~ Rejected — application shell uses leading nav (D-v4-4) on medium+.
- a universal floating Add action;
- a standalone Today route;
- a generic Home destination;
- a global sitemap drawer;
- separate Pet Care and Shelter notification systems;
- an inline Organisation root pet/event feed;
- a second Admin Contacts directory;
- a separate Organisation presentation primary destination;
- organisation-controlled danger, warning, success, or focus styling;
- role selection before sign-in;
- visual completion states that bypass server-authoritative care semantics;
- a design that exposes private person/pet information to an unpermitted viewer.

---

## 16. Final implementation guidance

1. Treat the design system as a shared language, not a theme layer applied at the end.
2. Build one journey at a time: entry → shell → root → detail → action → confirmation.
3. Start each journey from its designed loading/empty/error state, not only its ideal populated state.
4. Preserve all existing domain truth: authentication, routing, localization, ownership/foster/shared semantics, care completion/undo, backend authority, and deep links.
5. Update semantics and Playwright page objects at the same time as any meaningful navigation or label change.
6. If a request conflicts with this document or the decision log, stop and record/review the decision before implementing.

This blueprint is intentionally detailed so implementation can proceed in small, reviewable slices while keeping the whole application coherent.