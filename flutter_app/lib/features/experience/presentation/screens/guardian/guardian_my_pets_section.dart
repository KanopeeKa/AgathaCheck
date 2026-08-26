import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../widgets/guardian_dashboard_pet_card.dart';
import '../../widgets/guardian_illustrated_empty_state.dart';
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

    if (showUnifiedPreview) {
      return Semantics(
        container: true,
        label: l.myPets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GuardianPetRail(
              pets: previewPets!,
              careSummary: careSummary,
              l: l,
              theme: theme,
              ref: ref,
              parentContext: context,
              onAddPet: () => context.push('/add'),
            ),
            if (hasPreviewOverflow)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('dashboard_manage_pets_link'),
                  onPressed: () => context.go('/g/pets'),
                  child: Text(l.allPets),
                ),
              ),
          ],
        ),
      );
    }

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
                ...[
                  if (showPersonalSubgroupTitle)
                    _PetSubgroupTitle(title: l.myPets),
                  if (personalPets.isEmpty &&
                      fosterPets.isEmpty &&
                      sharedPets.isEmpty)
                    GuardianIllustratedEmptyState(
                      key: const Key('guardian_dashboard_empty_pets'),
                      assetPath: 'assets/dashboard/guardian-empty-pets.png',
                      title: l.guardianEmptyPetsTitle,
                      body: l.guardianEmptyPetsBody,
                      actionLabel: l.addPet,
                      actionKey: const Key('guardian_dashboard_add_pet'),
                      onAction: () => context.push('/add'),
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
        if (hasAny)
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

class _GuardianPetRail extends StatelessWidget {
  const _GuardianPetRail({
    required this.pets,
    required this.careSummary,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
    required this.onAddPet,
  });

  final List<Pet> pets;
  final GuardianTodayCareSummary? careSummary;
  final AppLocalizations l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    final usesLargeText = MediaQuery.textScalerOf(context).scale(14) > 18;

    return SizedBox(
      key: const Key('guardian_dashboard_pet_preview'),
      height: pets.isEmpty
          ? usesLargeText
                ? 168
                : 132
          : usesLargeText
          ? 128
          : 96,
      child: pets.isEmpty
          ? GuardianIllustratedEmptyState(
              key: const Key('guardian_dashboard_empty_pets'),
              assetPath: 'assets/dashboard/guardian-empty-pets.png',
              title: l.guardianEmptyPetsTitle,
              body: l.guardianEmptyPetsBody,
              actionLabel: l.addPet,
              actionKey: const Key('guardian_dashboard_add_pet'),
              onAction: onAddPet,
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: pets.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == pets.length)
                  return _AddPetTile(onPressed: onAddPet, l: l);
                return SizedBox(
                  width: 142,
                  child: _cardFor(context, pets[index]),
                );
              },
            ),
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

class _AddPetTile extends StatelessWidget {
  const _AddPetTile({required this.onPressed, required this.l});

  final VoidCallback onPressed;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Semantics(
        button: true,
        label: l.addPet,
        child: Material(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const Key('guardian_dashboard_add_pet'),
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColorTokens.guardianPrimary,
                    foregroundColor: AppColorTokens.inverse,
                    child: Icon(Icons.add),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l.addPet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
