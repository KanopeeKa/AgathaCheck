---
title: Phase 4 — Foster & pet operations
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 4 — Foster & pet operations

**Parent:** [../../cross-domain/changes/roadmap-delivery-plan.md](../../cross-domain/changes/roadmap-delivery-plan.md) · [../../cross-domain/changes/program-contract.md](../../cross-domain/changes/program-contract.md)  
**Brief:** [`briefs/shelter-dashboard-brief.md`](briefs/shelter-dashboard-brief.md) §Fosters

## Purpose

This is the **smallest** phase because `/docs/domains/fostering/features/` (J1–J5, merged) already
delivers most of the foster/pet operational substance the brief asks for. Scope here is
deliberately narrow: foster self-management privacy, the agreement-withdrawal flow, and threading
Phase 3's permission bundles through the existing foster/pet action gates.

## In scope

- Foster self-management visibility columns and self-card UI (D26, D31)
- Agreement withdrawal flow: type-to-confirm, auto-pause, urgent administrative notification
  (D30, D11)
- Replacing remaining raw `isOrgAdmin`/role-string checks on foster/pet actions with
  `hasPermission()` calls against the real Phase 3 permission table

## Out of scope / forbidden ownership

- Must not fork or duplicate J3's session state machine — auto-pause on withdrawal sets a flag
  J3's existing session lifecycle already understands (or, if no such flag exists yet, adds the
  minimal one via an extension consistent with G0 §6.2's status list, not a parallel status enum)
- Must not touch `foster_profiles`/relationship approval logic (J1-owned) beyond adding the
  visibility columns this phase needs
- No new screens beyond the self-card visibility controls and the withdrawal confirmation flow

## Depends on

Phase 3 (`organization_permissions` table, bundle presets, Admin Contacts self-card pattern to
mirror for the Foster self-card).

## Exposes to

Phase 5's audit log viewer surfaces this phase's `foster_agreement_withdrawn` and visibility-change
audit events alongside Phase 3's permission events.

## Domain objects and states

| Object | Change |
|---|---|
| Foster profile / shelter–foster relationship | + `visible_to` (`other_fosters \| admins \| both \| nobody`), `address_visibility` (`full \| town \| hidden`), `contact_visibility` (`email \| phone \| neither \| both`) |
| Fostering session (J3-owned) | + minimal "flagged for admin review" state consistent with existing non-terminal statuses — exact mechanism decided in coordination with J3's owned state machine, not invented independently |

## Business rules

1. Foster self-card mirrors the Admin Contacts self-card pattern from Phase 3: own card first,
   remaining alphabetical by last name, own card editable, visibility controls exposed inline.
2. Address visibility and contact visibility are **separate** toggles from "who can see my card at
   all" (`visible_to`) — never conflate visibility-of-existence with visibility-of-detail (mirrors
   the brief's own "can view / can contact / can edit" distinction, program-contract §11).
3. Unticking agreement-to-follow-rules triggers, in order: (a) explicit warning copy describing
   consequences, (b) require the literal string `withdraw` typed to confirm, (c) on confirm: flag
   the foster's active/preparation sessions for admin review (auto-pause — do not silently
   terminate them), (d) emit an `urgent`-priority, `administrative`-kind notification to every
   admin/super-admin of that organisation, (e) write `foster_agreement_withdrawn` to
   `audit_events`.
4. This flow must remain rare and high-friction by design — no code path should be able to trigger
   it without the explicit typed confirmation, and it must not be reachable from any bulk action.
5. Every foster/pet action gate identified in the Phase 3 permission-key list (`manage_fosters`,
   `manage_pets`, `manage_fostering_sessions`, `transfer_pet_ownership`, etc.) is converted to a
   `hasPermission()` call in this phase if it wasn't already converted in Phase 3 — sweep
   `server/routes/organizations/**` and the matching Flutter screens for any remaining raw role
   string comparisons on these specific actions.

## Screens and navigation

| Route | Change |
|---|---|
| Foster card (existing, within Manage Fosters) | + self-management visibility section |
| Foster card | + "Withdraw agreement" high-friction action |

## Notifications

`agreementWithdrawn` (`administrative`, `priority: urgent`) — per program-contract §3.1/D11, sent
to all org admins/super-admins, pinned above date order in the Administrative filter until
resolved (resolution = an admin reviews the flagged sessions, tracked as a manual "reviewed"
action on the flagged-session UI, not a generic notification dismiss).

## Permissions

No new permission keys beyond Phase 3's list. This phase is about **using** them correctly, not
adding more.

## Audit events

`foster_agreement_withdrawn`, `foster_visibility_changed` (program-contract §4.5/§8-style).

## Phases with exit criteria

Sprints 4.1–4.5 (see [roadmap-delivery-plan.md](/docs/domains/cross-domain/changes/roadmap-delivery-plan.md)).

**Exit criteria:**

- Withdrawal flow tested end-to-end: type "withdraw" → session(s) flagged → urgent notification
  received by a test admin account → audit event recorded
- Grep sweep of `server/routes/organizations/**` for raw `role ===` comparisons on the
  foster/pet actions listed above returns zero matches outside `hasPermission()`'s own
  implementation
- Foster self-card visibility controls verified with Jest for all four `visible_to` /
  `address_visibility` / `contact_visibility` combinations relevant to a second viewer's role

## Migration / compatibility

New nullable columns on the existing foster profile/relationship table — default to the least
restrictive value that matches **today's actual behaviour** (i.e. don't silently make existing
fosters' details less visible than they are today on migration day; confirm today's default
visibility behaviour before choosing the column defaults).

## Legal/document dependencies

Agreement withdrawal ties into the existing signed-agreement documents already tracked by J1's
onboarding section — no new legal document type, just a new status-changing trigger on existing
data.

## Open questions

- Exact mechanism for "flag session for admin review" — extend J3's existing session status enum
  with a new non-terminal value, or add a boolean review flag alongside the existing status? Decide
  in coordination with J3's owned state machine at the start of sprint 4.3, not independently.

## Canonical BDD scenarios

```gherkin
Feature: Foster self-management
  As a foster
  I want to control who can see my details
  So that I feel safe sharing my information with a shelter

  Scenario: Foster restricts address visibility to town only
    Given I am a foster with a full address on file
    When I set my address visibility to "town only"
    Then another foster viewing my card should see only my town

Feature: Foster agreement withdrawal
  As a foster who no longer agrees to the organisation's rules
  I want to withdraw my agreement deliberately
  So that the shelter is aware and my active sessions are reviewed

  Scenario: Withdrawing agreement requires typed confirmation
    Given I am a foster with an active fostering session
    When I untick my agreement to follow the rules
    Then I should be warned that my sessions may be affected
    And I should be required to type "withdraw" to confirm

  Scenario: Withdrawal auto-pauses sessions and alerts admins
    Given I confirm withdrawal by typing "withdraw"
    Then my active fostering session should be flagged for admin review
    And every admin of the organisation should receive an urgent notification
```
