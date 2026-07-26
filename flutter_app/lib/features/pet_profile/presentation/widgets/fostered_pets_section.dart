import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class FosteredPetsSection extends ConsumerWidget {
  final List<Pet> fosteredActive;
  final String? orgFilter;
  final dynamic l;
  final ThemeData theme;

  const FosteredPetsSection({
    super.key,
    required this.fosteredActive,
    required this.orgFilter,
    required this.l,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fosteredActive.isEmpty && orgFilter == '_fostered') {
      return _EmptySection(message: l.noFosteredPets);
    }
    if (fosteredActive.isEmpty) return const SizedBox.shrink();

    final sorted = [...fosteredActive];
    sortPetsByCreatedAt(sorted);

    return PetTileStrip(
      useWrap: true,
      pets: sorted,
      onPetTap: (pet) => context.go('/pet/${pet.id}'),
      tileBuilder: (pet, tile) => Dismissible(
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.petHidden(pet.name))),
              );
            }
          }
          return false;
        },
        child: tile,
      ),
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
