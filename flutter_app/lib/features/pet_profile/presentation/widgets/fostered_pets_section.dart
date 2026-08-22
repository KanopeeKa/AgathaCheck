import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class FosteredPetsSection extends ConsumerWidget {
  final List<Pet> fosteredActive;
  final String? orgFilter;
  final dynamic l;
  final ThemeData theme;

  /// When provided, replaces the default [PetCard] tile. The same
  /// [Dismissible] hide-wrapper is applied around the custom tile.
  final Widget Function(Pet pet)? tileBuilder;

  const FosteredPetsSection({
    super.key,
    required this.fosteredActive,
    required this.orgFilter,
    required this.l,
    required this.theme,
    this.tileBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fosteredActive.isEmpty && orgFilter == '_fostered') {
      return _EmptySection(message: l.noFosteredPets);
    }
    if (fosteredActive.isEmpty) return const SizedBox.shrink();

    final sorted = [...fosteredActive];
    sortPetsByCreatedAt(sorted);

    Widget buildDismissible(Pet pet, Widget child) => Dismissible(
      key: Key('hide_foster_${pet.id}'),
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
            Text(l.hideFosteredPet),
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
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.hideFosteredPet),
            content: Text(l.hideFosteredPetConfirm(pet.name)),
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
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.petHidden(pet.name))));
          }
        }
        return false;
      },
      child: child,
    );

    if (tileBuilder != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pet in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: buildDismissible(pet, tileBuilder!(pet)),
            ),
        ],
      );
    }

    return PetTileStrip(
      useWrap: true,
      pets: sorted,
      onPetTap: (pet) => context.go('/pet/${pet.id}'),
      tileBuilder: (pet, tile) => buildDismissible(pet, tile),
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
