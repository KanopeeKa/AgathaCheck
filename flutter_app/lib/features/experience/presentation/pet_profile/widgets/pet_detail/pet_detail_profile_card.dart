import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/weight_tracking/weight_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'pet_detail_profile_card_layout.dart';

/// The header card on the pet detail screen: photo, name, quick-info chips,
/// and optional bio / neuter / chip / insurance rows. Vet and emergency
/// contacts live in the People around section below this card.
///
/// The photo column width is computed from a [LayoutBuilder] so the card
/// stays usable at 320 logical px without horizontal overflow.
class PetDetailProfileCard extends ConsumerWidget {
  const PetDetailProfileCard({
    super.key,
    required this.pet,
    required this.viewerContext,
  });

  final Pet pet;
  final PetDetailContext viewerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final canEdit = viewerContext.can(PetDetailAction.editProfile);

    String? weightChipLabel;
    if (pet.weight != null) {
      final unit = ref.watch(weightUnitProvider(pet.id));
      final converted = convertWeight(pet.weight!, unit);
      weightChipLabel =
          '${converted.toStringAsFixed(1)} ${weightUnitLabel(unit)}';
    }

    return PetDetailProfileCardLayout(
      pet: pet,
      theme: theme,
      l: l,
      canEdit: canEdit,
      viewerRole: viewerContext.role,
      weightChipLabel: weightChipLabel,
      onEdit: () => context.go('/edit/${pet.id}'),
    );
  }
}
