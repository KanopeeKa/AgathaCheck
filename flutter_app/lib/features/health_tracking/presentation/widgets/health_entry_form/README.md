# Health entry form widgets

Extracted from `health_entry_form_screen.dart` to reduce screen size.

| Widget | File |
|--------|------|
| `HealthEntryPetSelector` | `health_entry_pet_selector.dart` |
| `HealthEntryPhotosSection` | `health_entry_photos_section.dart` |
| `HealthEntryNameDosageFields` / `HealthEntryNotesField` | `health_entry_text_fields.dart` |

`EntryDatePickerField` (shared) lives in `../entry_date_picker_field.dart`.

**Controller:** `health_entry_form_controller.dart` holds form state (including
name, dosage, notes), photo queue, load, and submit logic. The screen keeps UI
dialogs/snackbars only.
