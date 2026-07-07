# Health entry form widgets

Extracted from `health_entry_form_screen.dart` to reduce screen size.

| Widget | File |
|--------|------|
| `HealthEntryPetSelector` | `health_entry_pet_selector.dart` |
| `HealthEntryPhotosSection` | `health_entry_photos_section.dart` |
| `HealthEntryNameDosageFields` / `HealthEntryNotesField` | `health_entry_text_fields.dart` |
| `HealthEntryFrequencySection` | `health_entry_frequency_section.dart` |
| `HealthEntryHealthIssueDropdown` | `health_entry_health_issue_dropdown.dart` |
| `HealthEntryRemindField` | `health_entry_remind_field.dart` |
| `HealthEntryEditActions` | `health_entry_edit_actions.dart` |
| `HealthEntryDocumentHandler` | `health_entry_document_handler.dart` |
| Frequency label helpers | `health_entry_frequency_labels.dart` |

`EntryDatePickerField` (shared) lives in `../entry_date_picker_field.dart`.

**Controller:** `health_entry_form_controller.dart` holds form state (including
name, dosage, notes), photo queue, load, and submit logic. The screen keeps submit
dialogs, history/delete flows, and snackbars only.
