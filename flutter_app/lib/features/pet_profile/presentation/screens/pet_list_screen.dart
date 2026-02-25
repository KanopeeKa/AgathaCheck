import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_card.dart';

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petListAsync = ref.watch(petListProvider);
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(AppConstants.appTitle),
          ],
        ),
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
          if (auth.isLoggedIn)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  ((auth.user?.name.isNotEmpty ?? false)
                          ? auth.user!.name[0]
                          : auth.user?.email[0] ?? 'U')
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              onSelected: (value) async {
                if (value == 'details') {
                  context.push('/my-details');
                } else if (value == 'logout') {
                  await ref.read(authProvider.notifier).logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.name.isNotEmpty == true
                            ? auth.user!.name
                            : 'User',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        auth.user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'details',
                  child: ListTile(
                    leading: Icon(Icons.person_outlined),
                    title: Text('My Details'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Log Out'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Sign In'),
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
