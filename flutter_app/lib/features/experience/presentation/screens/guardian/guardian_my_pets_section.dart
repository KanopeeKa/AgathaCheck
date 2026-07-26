import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import 'guardian_dashboard_helpers.dart';

/// My Pets dashboard section — preview grid (max 4) with All Pets link.
class GuardianMyPetsSection extends StatelessWidget {
  const GuardianMyPetsSection({
    super.key,
    required this.allPets,
    required this.controller,
  });

  final List<Pet> allPets;
  final PetListController controller;

  static const previewLimit = 4;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final previewPets = guardianDashboardPreviewPets(
      allPets,
      controller,
      limit: previewLimit,
    );
    final hasMore = guardianDashboardHasMorePets(
      allPets,
      controller,
      limit: previewLimit,
    );

    return DashboardSection(
      title: l.myPets,
      headerAction: TextButton(
        key: const Key('dashboard_add_pet_button'),
        onPressed: () => context.push('/add'),
        child: Text(l.dashboardAddPet),
      ),
      previewBuilder: (ctx) {
        if (previewPets.isEmpty) {
          return Text(
            l.noPetsYet,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            ),
          );
        }
        return PetCardGrid(
          pets: previewPets,
          onPetTap: (pet) => context.go('/pet/${pet.id}'),
        );
      },
      endLink: hasMore
          ? DashboardSectionLink(
              label: l.allPets,
              onPressed: () => context.go('/g/pets'),
            )
          : null,
    );
  }
}
