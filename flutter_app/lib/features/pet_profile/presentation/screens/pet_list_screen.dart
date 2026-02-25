import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_card.dart';

/// The home screen displaying a list of all pet profiles.
///
/// Shows pet cards in a scrollable list. Users can tap a card
/// to edit the pet, or tap the FAB to add a new pet.
class PetListScreen extends ConsumerWidget {
  /// Creates a [PetListScreen].
  const PetListScreen({super.key});

  /// Builds the pet list UI with loading, error, empty, and data states.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital),
            tooltip: 'Veterinarians',
            onPressed: () => context.go('/vets'),
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'Health Tracking',
            onPressed: () => context.go('/health'),
          ),
        ],
      ),
      body: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load pets: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(petListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (pets) {
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets,
                    size: 80,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pets yet!',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first pet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PetCard(
                  pet: pet,
                  onTap: () => context.go('/pet/${pet.id}'),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Pet'),
                        content: Text(
                          'Are you sure you want to delete ${pet.name}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(petListProvider.notifier).deletePet(pet.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
    );
  }
}
