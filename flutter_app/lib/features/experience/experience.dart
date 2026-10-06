/// Public API for the Pet Care shell, navigation, and composed desk surfaces.
library;

export 'domain/entities/app_experience.dart';
export 'domain/entities/drawer_menu_group.dart';
export 'domain/entities/drawer_menu_item.dart';
export 'domain/services/experience_eligibility.dart';
export 'domain/services/pet_care_onboarding_rules.dart';
export 'presentation/providers/experience_providers.dart';
export 'presentation/screens/account_screen.dart';
export 'presentation/screens/experience_chooser_screen.dart';
export 'presentation/screens/experience_home_screens.dart';
export 'presentation/screens/experience_resolve_screen.dart';
export 'presentation/screens/experience_settings_screen.dart';
export 'presentation/screens/pet_care_onboarding_screen.dart';
export 'presentation/screens/pet_care/pet_care_due_events_screen.dart';
export 'presentation/widgets/experience_shell_scaffold.dart';
export 'presentation/screens/pet_care/pet_care_desk_preview_screen.dart';
export 'presentation/screens/pet_care/add_event_type_picker_sheet.dart';
export 'presentation/screens/pet_care/pet_care_all_pets_screen.dart';
export 'presentation/care_item/detail/care_item_detail_screen.dart';
export 'presentation/care_item/occurrence/occurrence_screen.dart';
export 'presentation/screens/pet_care/pet_care_dashboard_contextual_slot_section.dart';
export 'presentation/pet_profile/widgets/pet_profile_care_suggestion_section.dart';
export 'presentation/screens/pet_care/pet_care_bulk_share_select_screen.dart';
// D21 — composed pet profile surfaces
export 'presentation/pet_profile/screens/pet_list_screen.dart';
export 'presentation/pet_profile/screens/pet_detail_screen.dart';
export 'presentation/pet_profile/screens/pet_form_screen.dart';
export 'presentation/pet_profile/screens/pet_manage_events_screen.dart';
export 'presentation/pet_profile/screens/pet_health_issues_screen.dart';
export 'presentation/pet_profile/widgets/pet_edit_permission_guard.dart';
export 'presentation/pet_profile/utils/pet_care_dashboard_helpers.dart';
export 'presentation/pet_profile/widgets/pet_list/pet_care_pets_tile_grid.dart';
export 'presentation/pet_profile/screens/widgets/pet_care_global_events_filters.dart';
export 'presentation/pet_profile/screens/widgets/manage_events_collection_filter.dart';
export 'presentation/pet_profile/screens/widgets/org_events_collection_filter.dart';
export 'presentation/pet_profile/widgets/pet_care_section/pet_care_action_row_builder.dart';
export 'presentation/pet_profile/widgets/pet_list/home_event_actions.dart';
export 'presentation/pet_profile/screens/widgets/pet_event_entry_list.dart';
export 'presentation/pet_profile/screens/widgets/manage_events_filters.dart';
export 'presentation/pet_profile/screens/widgets/health_events_section.dart';
export 'package:pet_profile_app/features/pet_profile/pet_profile.dart'
    show Pet, PetListController, PetListStaleBanner, petListProvider;
