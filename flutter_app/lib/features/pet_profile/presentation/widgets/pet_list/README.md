# Pet list widgets

Extracted from `pet_list_screen.dart` to keep the screen under the modularity
size target (~300 lines). Each file owns one list-dashboard section.

| Widget | File |
|--------|------|
| `PetListSectionHeader` | `pet_list_section_header.dart` |
| `DueEventsSection` | `due_events_section.dart` |
| `PendingSharesSection` / `PendingShareCard` | `pending_shares_section.dart` |
| `PendingFosterPlacementsSection` | `pending_foster_placements_section.dart` |
| `PendingAdoptionPlacementsSection` | `pending_adoption_placements_section.dart` |

Tests: `test/features/pet_profile/presentation/widgets/pet_list/`
