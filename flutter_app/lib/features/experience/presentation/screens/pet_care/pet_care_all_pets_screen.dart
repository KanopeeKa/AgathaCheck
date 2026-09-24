import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/presentation/screens/pet_list_screen.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/pet_list_stale_banner.dart';
import '../../../../pet_tags/domain/services/pet_tag_filter.dart';
import '../../../../pet_tags/presentation/providers/pet_tag_providers.dart';
import '../../../../pet_tags/presentation/widgets/pet_tag_filter_bar.dart';
import '../../widgets/experience_shell_scaffold.dart';
import '../../widgets/pet_care_bottom_action_bar.dart';
import '../../../domain/entities/app_experience.dart';

/// Full guardian pet list (`/pc/pets`) — All Pets screen from the dashboard link.
class PetCareAllPetsScreen extends ConsumerWidget {
  const PetCareAllPetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(petTagListProvider);
    final filter = ref.watch(petTagFilterProvider);
    final visiblePetIds = tagsAsync.maybeWhen(
      data: (tags) => matchingPetIdsForTagFilter(
        selectedTagIds: filter.selectedTagIds,
        matchMode: filter.matchMode,
        tags: tags,
      ),
      orElse: () => null,
    );

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.allPets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PetListStaleBanner(),
          const PetTagFilterBar(),
          Expanded(
            child: PetListScreen(
              embeddedInShell: true,
              visiblePetIds: visiblePetIds,
            ),
          ),
          PetCareBottomActionBar(
            onAddPet: () => context.push('/add'),
            onSharePets: () => context.push('/pc/pets/bulk-share'),
          ),
        ],
      ),
    );
  }
}
