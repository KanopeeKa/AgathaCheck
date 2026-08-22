---
title: Guardian Today presentation foundation
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Guardian Today presentation foundation

The Guardian Today presentation foundation is a pure, local adapter for existing
Guardian pets and health entries. It does not make requests, infer permissions,
or change any provider-owned collection.

## Inputs

- Eligible pets are supplied through `PetListController.guardianShellPets`.
- Existing `HealthEntry` values and an explicit clock produce care priorities.
- UI loading and error signals are reduced to an explicit screen state.

## Outputs

- `GuardianTodayCarePriorities` exposes immutable overdue, due-today, and
  reminder-window upcoming groups; its dashboard preview is capped at five.
- `GuardianTodayPetPreview` exposes an immutable, attention-first four-pet
  preview and its overflow count.
- Relationship, care-status, and screen-state enums provide localized UI
  consumers with stable values instead of strings or duplicated conditions.

## Stable rules

- Overdue care precedes due-today care, which precedes reminder-window upcoming
  care. Date order and original source order break ties.
- Pet selection prioritizes those same urgency groups, then preserves the
  controller's stable guardian-shell order.
- Passed-away pets are not presented. Ownership and shared/foster eligibility
  remain the controller's authority.
- `firstUse`, `allClear`, `attention`, `loading`, `partial`, and `error` are
  distinct states. An error must never be presented as an empty care list.

Later dashboard UI slices consume these outputs but must not change the model,
ARB contract, or generated localization files without coordination.