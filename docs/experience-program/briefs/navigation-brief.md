> **Status:** Locked master brief (source of truth). Do not edit inline — track deviations in
> [`../decisions-log.md`](../decisions-log.md) and feature-level detail in
> [`../phase-1-navigation.md`](../phase-1-navigation.md). Imported verbatim 2026-07-25.

# Navigation redesign brief

## Purpose

Redesign the mobile navigation so it feels like a clean product shell rather than a generic website menu or mixed home feed. The new model should be simple, scalable, mobile-first, and suitable for a product that may later be ported to iOS and Android apps [file:32][file:33][web:46][web:48].

This brief is written to be readable by both humans and AI implementation tools. It defines the information architecture, behavior rules, naming, and UX principles, while leaving room for the implementation system to apply its own design system, layout logic, and code conventions [file:32][file:33].

## Core direction

The current generic Home screen should be removed and replaced with a clearer section-based navigation model. The hamburger should no longer behave like a full sitemap; it should behave like a full-height section switcher with a short, intentional set of top-level destinations [file:33][file:32].

The new structure should center the product around three top-level areas:

- Guardian
- Organisation
- Account

Guardian and Organisation are the two primary top-level destinations in the upper portion of the hamburger menu. Account is pinned at the bottom of the full-height menu and acts as the global personal/app-level area rather than a peer destination used as often as the other two [file:32][web:34][web:37].

## Naming rules

Use **Account** as the global bottom-pinned destination instead of Settings. This avoids collision with the phrase “organisation settings,” which should remain a local concept inside the Organisation area rather than a global destination [web:37].

The term “organisation settings” should continue to exist only within the Organisation section for organisation-scoped preferences such as permissions, documents, workflows, and related administrative configuration. The Account area should instead cover personal and app-level destinations such as profile, help, FAQ, contact, legal, about, and sign out [web:37].

## Required deliverables

The redesign scope should include the following dashboard work:

- Reviewed Guardian dashboard
- Reviewed Organisation dashboard
- New Account dashboard

Each dashboard should be treated as a landing space for its section, not as a generic homepage or mixed feed. The implementation should avoid rebuilding another catch-all home screen under a different name [file:33].

## Information architecture

The top-level navigation architecture should follow this model:

| Level | Area | Role |
|---|---|---|
| Global | Hamburger menu | Section switcher |
| Section | Guardian dashboard | Landing page for guardian workflows |
| Section | Organisation dashboard | Landing page for organisation workflows |
| Section | Account dashboard | Landing page for personal/app-level utilities |
| Local | Sub-screens inside each section | Task and detail flows |

The hamburger menu should expose only the global section choices and not a long list of nested destinations. Local navigation should happen inside each section dashboard and its related sub-screens, not inside the global drawer [file:32][file:33].

## Menu structure

The menu should be a full-height side drawer. It should feel calm, sparse, and structured, closer to a workspace switcher than a classic navigation list [file:32].

Expected drawer structure:

- Top area: close control, optional brand/app label if useful
- Main section list: Guardian, Organisation
- Bottom-pinned area: Account
- Account should be visually separated from the main section list

Do not treat Account like a promotional or high-emphasis call-to-action button. It should feel anchored and always available, but quieter than the primary sections [file:32].

## Visual and theming guidance

Use a light color scheme for the drawer and shell. The visual language should feel clean, minimal, and product-like rather than decorative [file:32][file:33].

Apply section theming lightly:

- Guardian uses the agreed Guardian theme color
- Organisation uses the agreed Organisation theme color
- Account uses a neutral treatment

Do not rely on large colored surfaces. The themed color should primarily appear in icons, active states, chips, subtle indicators, or other restrained UI accents. The drawer background and layout structure should remain mostly neutral so the navigation feels stable and mature [file:32][file:33].

## Header behavior

The header system should support clear separation between global navigation and local navigation. The user should always understand whether they are switching sections or moving backward within the current section [file:33].

Recommended behavior model:

| Context | Leading control | Meaning |
|---|---|---|
| Section dashboard root | Hamburger | Switch to another top-level section |
| Section sub-screen | Back arrow | Return to the parent dashboard or previous section-level screen |
| Deep task/edit flow | Back or close | Exit the current task flow cleanly |

The design should avoid placing equally dominant hamburger and back controls in a way that creates ambiguity. If both controls are present on the same screen, their visual hierarchy and placement must make their roles unambiguous [file:33].

## Interaction rules

The navigation model should follow these rules:

- No generic Home destination
- Hamburger remains the global section switcher
- Guardian dashboard is the root for guardian-related flows
- Organisation dashboard is the root for organisation-related flows
- Account dashboard is the root for personal/app-level flows
- Sub-screens should use a clear return path back to their parent dashboard
- Local section navigation should live within dashboards and section flows, not in the global drawer

This rule set should remain stable across the product so users can build a reliable mental model [file:33].

## Account area contents

The Account area should encapsulate global personal/app-level destinations such as:

- Profile
- Preferences or personal notification controls
- Help / FAQ
- Contact
- Legal
- About
- Sign out

Sign out is acceptable inside the Account area and does not need to remain exposed as a separate global drawer item. This keeps the global drawer focused while still making sign out discoverable in a conventional place [web:34][web:37].

## Accessibility and mobile expectations

The redesign should be mobile-first and suitable for future app-style usage. Interactive controls should be easy to tap and visually clear on small screens, including the hamburger trigger, drawer rows, and back navigation controls [web:46][web:48].

At a minimum, the implementation should preserve comfortable touch targets and avoid cramped controls in the header or drawer. The interaction model should prioritize clarity, thumb reach, and predictable behavior over decorative effects [web:46][web:48].

## Guardrails

The implementation should avoid the following pitfalls:

- Reintroducing a generic Home page under another label
- Turning the hamburger into a long sitemap or admin sidebar
- Mixing global navigation and local task navigation in the same drawer
- Treating Account as a primary CTA instead of a global utility area
- Letting organisation-scoped settings leak into the Account area
- Creating visual ambiguity between the hamburger and back arrow
- Overusing themed color on backgrounds, panels, or large blocks

## Flexibility for implementation

This brief is intentionally directional rather than prescriptive at the component level. The implementing AI or designer may apply its own design system, spacing logic, motion rules, icon system, and structural refinements, provided the navigation architecture, naming logic, and behavior rules defined above remain intact [file:32][file:33].

Any implementation should optimize for a polished mobile product shell, clear section ownership, and a navigation pattern that can scale cleanly into future native app experiences [file:32][file:33].
