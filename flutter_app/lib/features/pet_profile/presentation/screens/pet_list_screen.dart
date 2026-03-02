import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_card.dart';

/// Screen that displays the list of all pets owned by the user.
///
/// Shows a scrollable list of [PetCard] widgets for each pet,
/// with options to add new pets, navigate to pet details, and
/// access veterinarian and health tracking features from the app bar.
class PetListScreen extends ConsumerStatefulWidget {
  /// Creates a [PetListScreen].
  const PetListScreen({super.key});

  @override
  ConsumerState<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends ConsumerState<PetListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).checkDueEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);
    final auth = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
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
                semanticLabel: 'App logo',
              ),
            ),
            const SizedBox(width: 8),
            const Text(AppConstants.appTitle),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.go('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.local_hospital),
            tooltip: 'Veterinarians',
            onPressed: () => context.go('/vets'),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Events',
            onPressed: () => context.go('/health'),
          ),
          PopupMenuButton<String>(
            tooltip: 'User menu',
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
                  ExcludeSemantics(
                    child: Icon(
                      Icons.pets,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
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
                  onPassedAway: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.grey[400], size: 22),
                            const SizedBox(width: 8),
                            const Text('Passed Away'),
                          ],
                        ),
                        content: Text(
                          'Are you sure you would like to mark ${pet.name} as having passed away?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    if (!context.mounted) return;

                    final hasSharedUsers = await ref
                        .read(petListProvider.notifier)
                        .markPassedAway(pet.id);

                    if (!context.mounted) return;

                    await showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) {
                        final theme = Theme.of(ctx);
                        return AlertDialog(
                          title: Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.grey[400], size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'In loving memory of ${pet.name}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'We are deeply sorry for your loss. ${pet.name} has crossed the rainbow bridge, and we know how much they meant to you.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (hasSharedUsers) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'A notification has been sent to everyone who shared ${pet.name}\'s profile to let them know of their passing.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                'We will remove any further health reminders and notifications. ${pet.name}\'s profile will be kept in your archive so you can always look back on their memories.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Thank you'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Pet'),
                        content: Text(
                          'Are you sure you want to delete ${pet.name}? '
                          'This will permanently remove all linked health events, '
                          'health issues, weight records, notifications, and '
                          'shared access for this pet.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(ctx).colorScheme.error,
                            ),
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
        key: const Key('add_pet_button'),
        onPressed: () => context.push('/add'),
        tooltip: 'Add a new pet',
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
    );
  }
}
