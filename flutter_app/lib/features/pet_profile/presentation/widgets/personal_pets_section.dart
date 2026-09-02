import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet.dart';
import 'pet_card.dart';

class PersonalPetsSection extends StatelessWidget {
  final List<Pet> personalActive;
  final String? orgFilter;
  final dynamic l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;
  final bool bulkShareMode;
  final Set<String> selectedPetIds;
  final ValueChanged<String>? onPetSelectionToggle;

  const PersonalPetsSection({
    super.key,
    required this.personalActive,
    required this.orgFilter,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
    this.bulkShareMode = false,
    this.selectedPetIds = const {},
    this.onPetSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (personalActive.isEmpty && orgFilter == '_personal') {
      return _EmptySection(message: l.noPetsYet);
    }
    if (personalActive.isEmpty) return const SizedBox.shrink();

    final sorted = [...personalActive];
    sortPetsByCreatedAt(sorted);

    return PetTileStrip(
      useWrap: true,
      pets: sorted,
      onPetTap: (pet) {
        final selectable =
            bulkShareMode &&
            !pet.isShared &&
            !pet.isFoster &&
            pet.organizationId == null;
        if (selectable) {
          onPetSelectionToggle?.call(pet.id);
        } else {
          context.go('/pet/${pet.id}');
        }
      },
      tileBuilder: (pet, tile) {
        final selectable =
            bulkShareMode &&
            !pet.isShared &&
            !pet.isFoster &&
            pet.organizationId == null;
        if (!selectable) return tile;

        return Stack(
          children: [
            tile,
            Positioned(
              left: 8,
              top: 8,
              child: Checkbox(
                value: selectedPetIds.contains(pet.id),
                onChanged: (_) => onPetSelectionToggle?.call(pet.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
