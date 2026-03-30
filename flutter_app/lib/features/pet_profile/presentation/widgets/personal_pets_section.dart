import 'package:flutter/material.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class PersonalPetsSection extends StatelessWidget {
  final List<Pet> personalActive;
  final String? orgFilter;
  final dynamic l;
  final dynamic theme;
  final dynamic ref;
  final dynamic context;

  const PersonalPetsSection({
    super.key,
    required this.personalActive,
    required this.orgFilter,
    required this.l,
    required this.theme,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    if (personalActive.isEmpty && orgFilter == '_personal') {
      return _EmptySection(message: l.noPetsYet);
    }
    if (personalActive.isEmpty) return const SizedBox.shrink();
    return Column(
      children: personalActive.map((pet) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: pet.isShared
            ? Dismissible(
                key: Key('hide_{pet.id}'),
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
                      Text(l.hideSharedPet, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Icon(Icons.visibility_off, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  final confirmed = await showDialog<bool>(
                    context: this.context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.hideSharedPet),
                      content: Text(l.hideSharedPetConfirm(pet.name)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.hide)),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(hiddenSharedPetsProvider.notifier).hideSharedPet(pet.id);
                    if (this.context.mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(l.petHidden(pet.name))),
                      );
                    }
                  }
                  return false;
                },
                child: PetCard(
                  pet: pet,
                  onTap: () => this.context.go('/pet/{pet.id}'),
                ),
              )
            : PetCard(
                pet: pet,
                onTap: () => this.context.go('/pet/{pet.id}'),
              ),
      )).toList(),
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
