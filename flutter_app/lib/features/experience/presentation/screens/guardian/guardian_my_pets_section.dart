import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../widgets/guardian_dashboard_pet_card.dart';
import '../../widgets/guardian_shell_shared_pet_card.dart';
import 'guardian_dashboard_helpers.dart';

/// Guardian dashboard pets: owned, fostered, and shared subgroups.
class GuardianMyPetsSection extends ConsumerWidget {
  const GuardianMyPetsSection({
    super.key,
    required this.allPets,
    required this.controller,
    this.previewPets,
    this.previewOverflowCount,
    this.careSummary,
  });

  final List<Pet> allPets;
  final PetListController controller;

  /// Ordered, capped values produced by the Guardian Today foundation.
  final List<Pet>? previewPets;

  /// Overflow metadata produced alongside [previewPets].
  ///
  /// The legacy inference preserves the existing shell composition until the
  /// integration slice passes the foundation value directly.
  final int? previewOverflowCount;
  final GuardianTodayCareSummary? careSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellPets = controller.guardianShellPets(allPets);
    final personalPets = guardianDashboardPersonalPets(allPets, controller);
    final fosterPets = guardianDashboardFosterPets(allPets, controller);
    final sharedPets = guardianDashboardSharedPets(allPets, controller);
    final hasAny = guardianDashboardHasAnyPets(allPets, controller);
    final showUnifiedPreview = previewPets != null;
    final inferredPreviewOverflow = showUnifiedPreview
        ? shellPets.where((pet) => !pet.passedAway).length - previewPets!.length
        : 0;
    final hasPreviewOverflow =
        (previewOverflowCount ?? inferredPreviewOverflow) > 0;
    final showPersonalSubgroupTitle =
        !showUnifiedPreview &&
        personalPets.isNotEmpty &&
        (fosterPets.isNotEmpty || sharedPets.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSection(
          title: l.myPets,
          headerAction: TextButton.icon(
            onPressed: () => context.push('/add'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.addPet),
          ),
          previewBuilder: (ctx) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showUnifiedPreview)
                  _DashboardPetPreview(
                    pets: previewPets!,
                    careSummary: careSummary,
                    l: l,
                    theme: theme,
                    ref: ref,
                    parentContext: context,
                  )
                else ...[
                  if (showPersonalSubgroupTitle)
                    _PetSubgroupTitle(title: l.myPets),
                  if (personalPets.isEmpty &&
                      fosterPets.isEmpty &&
                      sharedPets.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.noPetsYet,
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          key: const Key('my_pets_explore_shelters_link'),
                          onPressed: () => context.go('/o/orgs'),
                          icon: const Icon(Icons.business_outlined, size: 18),
                          label: Text(l.noPetsExploreShelters),
                        ),
                      ],
                    )
                  else if (personalPets.isNotEmpty)
                    PetTileStrip(
                      useWrap: true,
                      pets: personalPets,
                      onPetTap: (pet) => context.go('/pet/${pet.id}'),
                    ),
                  if (fosterPets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PetSubgroupTitle(title: l.myFosteredPets),
                    const SizedBox(height: 8),
                    PetTileStrip(
                      useWrap: true,
                      pets: fosterPets,
                      onPetTap: (pet) => context.go('/pet/${pet.id}'),
                    ),
                  ],
                  if (sharedPets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PetSubgroupTitle(title: l.sharedPets),
                    const SizedBox(height: 8),
                    PetTileStrip(
                      useWrap: true,
                      pets: sharedPets,
                      onPetTap: (pet) => context.go('/pet/${pet.id}'),
                      tileBuilder: (pet, tile) => GuardianShellSharedPetCard(
                        pet: pet,
                        l: l,
                        theme: theme,
                        ref: ref,
                        parentContext: context,
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
        if (showUnifiedPreview ? hasPreviewOverflow : hasAny)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('dashboard_manage_pets_link'),
              onPressed: () => context.go('/g/pets'),
              child: Text(l.allPets),
            ),
          ),
      ],
    );
  }
}

class _DashboardPetPreview extends StatelessWidget {
  const _DashboardPetPreview({
    required this.pets,
    required this.careSummary,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
  });

  final List<Pet> pets;
  final GuardianTodayCareSummary? careSummary;
  final AppLocalizations l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return Text(
        l.noPetsYet,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final width = ((constraints.maxWidth - (columns - 1) * 12) / columns)
            .clamp(0.0, 168.0)
            .toDouble();
        return Wrap(
          key: const Key('guardian_dashboard_pet_preview'),
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final pet in pets)
              SizedBox(width: width, child: _cardFor(context, pet)),
          ],
        );
      },
    );
  }

  Widget _cardFor(BuildContext context, Pet pet) {
    final card = GuardianDashboardPetCard(
      pet: pet,
      careState: careSummary == null
          ? GuardianTodayPetCareState.clear
          : guardianTodayPetCareState(pet, careSummary!),
      onTap: () => context.go('/pet/${pet.id}'),
    );
    if (!pet.isShared) return card;
    return GuardianShellSharedPetCard(
      pet: pet,
      l: l,
      theme: theme,
      ref: ref,
      parentContext: parentContext,
      child: card,
    );
  }
}

class _PetSubgroupTitle extends StatelessWidget {
  const _PetSubgroupTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
