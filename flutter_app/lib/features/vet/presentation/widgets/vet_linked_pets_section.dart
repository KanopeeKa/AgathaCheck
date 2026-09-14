import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/form/app_form_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';

class VetLinkedPetsSection extends ConsumerWidget {
  const VetLinkedPetsSection({super.key, required this.vetId});

  final String vetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);
    final l = AppLocalizations.of(context)!;

    return AppFormSection(
      title: l.linkedPets,
      children: [
        petsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Could not load pets: $e'),
          data: (pets) {
            if (pets.isEmpty) {
              return Text(
                l.noPetsAddFirst,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }

            final linked = pets.where((p) => p.vetId == vetId).toList();
            final unlinked = pets.where((p) => p.vetId != vetId).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (linked.isNotEmpty)
                  ...linked.map(
                    (pet) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.pets,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(pet.name),
                        subtitle: Text(pet.species),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.link_off, size: 18),
                          label: Text(l.unlink),
                          onPressed: () => _unlinkPet(ref, pet),
                        ),
                      ),
                    ),
                  ),
                if (unlinked.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.availablePets,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...unlinked.map(
                    (pet) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.pets,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        title: Text(pet.name),
                        subtitle: Text(pet.species),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.link, size: 18),
                          label: Text(l.link),
                          onPressed: () => _linkPet(ref, pet),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _linkPet(WidgetRef ref, Pet pet) async {
    final updated = pet.copyWith(vetId: vetId);
    await ref.read(petListProvider.notifier).updatePet(updated);
  }

  Future<void> _unlinkPet(WidgetRef ref, Pet pet) async {
    final updated = pet.copyWith(clearVetId: true);
    await ref.read(petListProvider.notifier).updatePet(updated);
  }
}
