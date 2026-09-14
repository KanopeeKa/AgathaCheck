---
title: Form harmonisation (Pet Care create/edit)
plan_id: form-harmonisation-c656
---

# Form harmonisation — Pet Care create/edit surfaces

## Goal

Harmonise all active Pet Care create/edit forms to match the pet form pattern:
`AppFormSection` grouping, external labels, cancel+save actions, sticky phone bar,
dirty-guard on edit screens, and desktop preview where applicable. Exclude frozen
Shelter/Fostering org forms.

## Autonomy

| Field | Value |
|-------|-------|
| approved_by | user-chat-standing-grant-2026-09-14-form-harmonisation |
| approved_until | 2026-09-16T12:00:00Z |
| control_issue | 1160 |
| autonomy | completed |

## Phases

### Phase 1 — Core form primitives

Extract `core/widgets/form/*` from pet form; migrate pet form imports.

### Phase 2 — Health entry form

Restructure `HealthEntryFormScreen` with sections, preview panel, dirty guard.

### Phase 3 — Vet form

Harmonise `VetFormScreen` with sections, actions bar, dirty guard.

### Phase 4 — Compact forms

Profile editor, weight sheet, timeline sheet, health-issue dialog, password form,
sharing transfer dialog.

### Phase 5 — Cleanup

Remove dead `OtherEventFormScreen`, duplicate `pet_form_screen_body`, final integration PR to main.
