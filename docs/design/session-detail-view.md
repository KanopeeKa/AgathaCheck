---
title: Session detail view — design notes
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-31
tags: [design, ui, fostering]
---

# Session detail view — design notes

Tier-2 design reference for the fostering **View Session** screen. Domain rules and API: [session-detail-view.md](/docs/domains/fostering/features/session-detail-view.md).

## Scope

One shared composition, two primary lenses:

- **Foster participant** — calm, “your role in this placement”; guardian shell (`/g/*`)
- **Shelter operator** — operational, “manage this session”; org shell (`/o/*`)

Same section order; copy, density, and actions differ.

## UX audit (brief)

| Area | Finding | Lens |
|------|---------|------|
| Hierarchy | Status chip + pet name first; counterparty second | Both |
| Friction | Duplicated actions between pet placement expansion and session detail | Shelter — consolidate on session detail |
| Missing state | Foster has no session home from pet profile | Foster |
| Confusion | Legacy `status` vs `session_status` — show **one** user-facing status (canonical session) | Both |
| Trust | Foster must not see shelter-internal register export or staff notes | Foster |

## System pattern

```
SessionDetailScreen (route shell: org | guardian)
  └── SessionDetailBody (shared)
        ├── SessionAlertBanner
        ├── SessionHeader (pet, org/foster, chips)
        ├── SessionLifecycleSection (status-driven)
        ├── SessionChecklistSection
        ├── SessionDocumentsSection
        ├── SessionAdoptionSection (conditional)
        ├── SessionNotesSection
        └── SessionActionBar (allowed_actions only)
```

Extract from existing `FosteringSessionDetailScreen`; do not fork a second screen.

## Visual rules (requirement)

| Rule | Rationale |
|------|-----------|
| Use `Theme.of(context)` / `colorScheme` for surfaces and chips | Token discipline |
| Status chip: text + icon; not colour alone | A11y |
| Primary CTA: one per screen state | Clear next action |
| Touch targets ≥ 48×48 logical px | `design.mdc` |
| Focus rings preserved on web | `accessibility.mdc` |
| Foster lens: Guardian accent on primary CTA; Shelter lens: org teal on primary | Experience context |

## Copy tone (requirement)

| Lens | Title (EN) | Tone |
|------|------------|------|
| Foster | “Your fostering session” | Participant, reassuring |
| Shelter | “Fostering session” | Direct, operational |
| History | “Fostering session” | Past tense in subtitle (“Ended …”) |

Avoid “placement” in user-facing strings on this screen; use “session” per G0 vocabulary.

## Section behaviour by lens

### Header

- **Foster:** org name + shelter contact affordance (`contact_counterparty`)
- **Shelter:** foster name/email (respect `fosterVisibility` filters)

### Checklist

- Card layout matching existing `FosteringSessionPreparationChecklist`
- Foster: toggle only items allowed by template metadata (`foster_completable` — add in template schema when needed; until then foster can toggle items explicitly marked in checklist JSON)
- Shelter: all items + “Mark ready” when in `preparation`

### Documents

- List rows: icon, title, status (pending / complete), open action
- Register export: shelter operator only; dialog with selectable text (existing pattern)

### Action bar

- Sticky bottom on mobile when actions exist; inline buttons on wide layouts acceptable
- Destructive actions (decline, cancel, end) use `OutlinedButton` or confirm dialog per existing session end flow

## Empty / loading / error

| State | Behaviour |
|-------|-----------|
| Loading | Center `CircularProgressIndicator` in body |
| Error | Single error line + retry button |
| Forbidden | “You don’t have access to this session” — no data leak |
| Terminal session | Hide action bar; show outcome chip |

## Accessibility (requirement)

- Screen title in shell app bar (`fosteringSessionDetailTitle` / foster variant)
- Each action button: `Semantics(identifier: 'session_action_<key>')` for E2E
- Checklist items: `session_checklist_item_<key>` (existing keys preserved)
- Status chip: `Semantics(label: localized status string)`

## Navigation

See [navigation-contract.md](/docs/e2e/navigation-contract.md) for routes and ready locators.

## Acceptance checklist (implementation)

- [ ] Theme tokens, not scattered colors
- [ ] Focus visible; touch ≥48dp
- [ ] l10n for all new strings (EN + FR)
- [ ] Empty, loading, error considered
- [ ] `/g/*` vs `/o/*` shells correct
- [ ] Widget tests for foster vs shelter action visibility
- [ ] E2E `@P1` for open session from pet profile (phase 4)

## Preference (non-blocking)

- Session header pet avatar thumbnail when pet photo available
- “Nearly finished” subtle warning tint on end date row (not error red)
