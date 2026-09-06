import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../../../pet_profile/presentation/utils/pet_tile_dimensions.dart';
import '../../../../pet_profile/presentation/widgets/pet_tile_status_line.dart';
import '../../../../pet_profile/presentation/widgets/unified_pet_tile.dart';
import '../../widgets/pet_care_dashboard_ambient_deco.dart';
import '../../widgets/pet_care_dashboard_section_header.dart';
import '../../widgets/horizontal_carousel_controls.dart';
import '../../widgets/pet_care_illustrated_empty_state.dart';
import '../../widgets/pet_care_shell_shared_pet_card.dart';
import 'pet_care_dashboard_helpers.dart';

/// Guardian dashboard pets: owned, fostered, and shared subgroups.
class PetCareMyPetsSection extends ConsumerWidget {
  const PetCareMyPetsSection({
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
  final PetCareTodayCareSummary? careSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final personalPets = petCareDashboardPersonalPets(allPets, controller);
    final fosterPets = petCareDashboardFosterPets(allPets, controller);
    final sharedPets = petCareDashboardSharedPets(allPets, controller);
    final hasAny = petCareDashboardHasAnyPets(allPets, controller);
    final showUnifiedPreview = previewPets != null;
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
            PetCareDashboardSectionChrome(
              title: l.myPets,
              linkLabel: l.allPets,
              linkKey: const Key('dashboard_manage_pets_link'),
              onLinkPressed: () => context.go('/pc/pets'),
            ),
            const SizedBox(height: 10),
            _PetCarePetRail(
              pets: previewPets!,
              careSummary: careSummary,
              l: l,
              theme: theme,
              ref: ref,
              parentContext: context,
              onAddPet: () => context.push('/add'),
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
                    PetCareIllustratedEmptyState(
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
                      onPetTap: (pet) => openPetDetail(context, pet.id),
                    ),
                  if (fosterPets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PetSubgroupTitle(title: l.myFosteredPets),
                    const SizedBox(height: 8),
                    PetTileStrip(
                      useWrap: true,
                      pets: fosterPets,
                      onPetTap: (pet) => openPetDetail(context, pet.id),
                    ),
                  ],
                  if (sharedPets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PetSubgroupTitle(title: l.sharedPets),
                    const SizedBox(height: 8),
                    PetTileStrip(
                      useWrap: true,
                      pets: sharedPets,
                      onPetTap: (pet) => openPetDetail(context, pet.id),
                      tileBuilder: (pet, tile) =>
                          PetCareShellSharedPetCard(pet: pet, child: tile),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
        if (hasAny)
          PetCareDashboardSectionLink(
            linkKey: const Key('dashboard_manage_pets_link'),
            label: l.allPets,
            onPressed: () => context.go('/pc/pets'),
          ),
      ],
    );
  }
}

class _PetCarePetRail extends StatelessWidget {
  const _PetCarePetRail({
    required this.pets,
    required this.careSummary,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
    required this.onAddPet,
  });

  final List<Pet> pets;
  final PetCareTodayCareSummary? careSummary;
  final AppLocalizations l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = PetTileDimensions.widthFor(viewportWidth);
    final railHeight = pets.isEmpty
        ? 168.0
        : PetTileDimensions.heightFor(context);
    final addTileWidth = petCareDashboardAddPetTileWidth(viewportWidth);

    return SizedBox(
      key: const Key('guardian_dashboard_pet_preview'),
      height: railHeight,
      child: pets.isEmpty
          ? PetCareIllustratedEmptyState(
              key: const Key('guardian_dashboard_empty_pets'),
              assetPath: 'assets/dashboard/guardian-empty-pets.png',
              title: l.guardianEmptyPetsTitle,
              body: l.guardianEmptyPetsBody,
              actionLabel: l.addPet,
              actionKey: const Key('guardian_dashboard_add_pet'),
              onAction: onAddPet,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = petCarePetRailContentWidth(
                  petCount: pets.length,
                  cardWidth: tileWidth,
                  addTileWidth: addTileWidth,
                );
                final railScrolls = contentWidth > constraints.maxWidth;
                final leftover = constraints.maxWidth - contentWidth;
                const decoGap = 8.0;
                final usableLeftover = leftover - decoGap;
                final decoMode =
                    !railScrolls &&
                        usableLeftover > 0 &&
                        petCareDashboardDecoAllowedForWidth(viewportWidth)
                    ? petCarePetRailDecoModeForLeftover(usableLeftover)
                    : null;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    HorizontalCarouselControls(
                      height: railHeight,
                      scrollStep: tileWidth + 12,
                      builder: (scrollController) => ListView.separated(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 4),
                        itemCount: pets.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          if (index == pets.length) {
                            return _AddPetTile(
                              onPressed: onAddPet,
                              l: l,
                              width: addTileWidth,
                              height: railHeight,
                            );
                          }
                          return _cardFor(
                            context,
                            pets[index],
                            tileWidth: tileWidth,
                            tileHeight: railHeight,
                          );
                        },
                      ),
                    ),
                    if (decoMode != null)
                      Positioned(
                        left: contentWidth + decoGap,
                        top: 0,
                        bottom: 4,
                        right: 0,
                        child: PetCarePetRailYarnDeco(
                          mode: decoMode,
                          width: usableLeftover,
                          height: railHeight - 4,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _cardFor(
    BuildContext context,
    Pet pet, {
    required double tileWidth,
    required double tileHeight,
  }) {
    final careState = careSummary == null
        ? PetCareTodayPetCareState.clear
        : petCareTodayPetCareState(pet, careSummary!);
    final statusLine = resolvePetTileStatusLine(
      l: l,
      pet: pet,
      context: PetTileContext.petCare,
      careUrgency: petTileCareUrgencyFor(careState),
    );
    return UnifiedPetTile(
      pet: pet,
      width: tileWidth,
      height: tileHeight,
      statusLine: statusLine,
      onTap: () => openPetDetail(context, pet.id),
    );
  }
}

class _AddPetTile extends StatelessWidget {
  const _AddPetTile({
    required this.onPressed,
    required this.l,
    required this.width,
    required this.height,
  });

  final VoidCallback onPressed;
  final AppLocalizations l;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColorTokens.petCarePrimary,
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
