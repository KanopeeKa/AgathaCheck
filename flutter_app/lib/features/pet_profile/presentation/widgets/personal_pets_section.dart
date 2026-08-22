import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

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

  /// When provided (and [bulkShareMode] is false), replaces the default
  /// square [PetCard] tiles with a vertical list of custom cards.
  /// The shared-pet Dismissible wrapper is applied around the custom card.
  final Widget Function(Pet pet)? cardBuilder;

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
    this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (personalActive.isEmpty && orgFilter == '_personal') {
      return _EmptySection(message: l.noPetsYet);
    }
    if (personalActive.isEmpty) return const SizedBox.shrink();

    final sorted = [...personalActive];
    sortPetsByCreatedAt(sorted);

    // When a custom cardBuilder is provided and not in bulk-share mode,
    // render a vertical list of custom cards (preserving the hide-wrapper
    // for shared pets).
    if (cardBuilder != null && !bulkShareMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pet in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: pet.isShared
                  ? _SharedDismissible(
                      pet: pet,
                      l: l,
                      theme: theme,
                      ref: ref,
                      parentContext: parentContext,
                      child: cardBuilder!(pet),
                    )
                  : cardBuilder!(pet),
            ),
        ],
      );
    }

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
        if (!selectable && !pet.isShared) return tile;

        Widget card = tile;
        if (selectable) {
          card = Stack(
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
        } else if (pet.isShared && !bulkShareMode) {
          card = Dismissible(
            key: Key('hide_${pet.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.hideSharedPet,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.visibility_off,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            confirmDismiss: (_) async {
              final confirmed = await showDialog<bool>(
                context: parentContext,
                builder: (ctx) => AlertDialog(
                  title: Text(l.hideSharedPet),
                  content: Text(l.hideSharedPetConfirm(pet.name)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.hide),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(hiddenSharedPetsProvider.notifier)
                    .hideSharedPet(pet.id);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(l.petHidden(pet.name))),
                  );
                }
              }
              return false;
            },
            child: tile,
          );
        }

        return card;
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

/// Dismissible wrapper for shared pets in the custom-card list path.
class _SharedDismissible extends StatelessWidget {
  const _SharedDismissible({
    required this.pet,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
    required this.child,
  });

  final Pet pet;
  final dynamic l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('hide_${pet.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.hideSharedPet,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.visibility_off,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: parentContext,
          builder: (ctx) => AlertDialog(
            title: Text(l.hideSharedPet),
            content: Text(l.hideSharedPetConfirm(pet.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.hide),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(hiddenSharedPetsProvider.notifier)
              .hideSharedPet(pet.id);
          if (parentContext.mounted) {
            ScaffoldMessenger.of(
              parentContext,
            ).showSnackBar(SnackBar(content: Text(l.petHidden(pet.name))));
          }
        }
        return false;
      },
      child: child,
    );
  }
}
