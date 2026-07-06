# Health entry form widgets

Extracted from `health_entry_form_screen.dart` to reduce screen size.

| Widget | File |
|--------|------|
| `HealthEntryPetSelector` | `health_entry_pet_selector.dart` |
| `HealthEntryPhotosSection` | `health_entry_photos_section.dart` |

`EntryDatePickerField` (shared) lives in `../entry_date_picker_field.dart`.

**Controller:** `health_entry_form_controller.dart` holds form state, photo
queue, load, and submit logic (Phase 1). The screen keeps text controllers and
UI dialogs/snackbars. Phase 2 (recurrence edge cases, further slimming) is in
`docs/refactoring-debt.md`.
