import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/pet.dart';
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

          final activePets = pets.where((p) => !p.passedAway).toList();
          final passedAwayPets = pets.where((p) => p.passedAway).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DueEventsSection(pets: pets),
              ...activePets.map((pet) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PetCard(
                  pet: pet,
                  onTap: () => context.go('/pet/${pet.id}'),
                ),
              )),
              if (passedAwayPets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ExpansionTile(
                      key: const Key('passed_away_section'),
                      leading: Icon(
                        Icons.favorite,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      title: Text(
                        'Rainbow Bridge',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${passedAwayPets.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: passedAwayPets.map((pet) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PetCard(
                                pet: pet,
                                onTap: () => context.go('/pet/${pet.id}'),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

class _DueEventsSection extends ConsumerWidget {
  const _DueEventsSection({required this.pets});

  final List<Pet> pets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        final dueEntries = entries
            .where((e) => !e.isCompleted && (e.isOverdue || e.isDueToday))
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

        final petMap = {for (final p in pets) p.id: p};

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: dueEntries.isEmpty
                    ? colorScheme.outlineVariant
                    : colorScheme.error.withAlpha(80),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        dueEntries.isEmpty
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        size: 20,
                        color: dueEntries.isEmpty
                            ? Colors.green
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dueEntries.isEmpty
                            ? "You're all caught up"
                            : 'Due & Overdue Events',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dueEntries.isEmpty
                              ? colorScheme.onSurface
                              : colorScheme.error,
                        ),
                      ),
                      if (dueEntries.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${dueEntries.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (dueEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No events are overdue or due today.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (dueEntries.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...dueEntries.map((entry) {
                      final pet = petMap[entry.petId];
                      final petColor = pet?.colorValue != null
                          ? Color(pet!.colorValue!)
                          : colorScheme.primary;
                      final isOverdue = entry.isOverdue;
                      final dateFormat = DateFormat.yMMMd();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (pet != null) {
                              context.go('/pet/${pet.id}');
                            }
                          },
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: petColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (pet != null) ...[
                                                    AppConstants.speciesIconWidget(
                                                      pet.species,
                                                      size: 14,
                                                      color: petColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      pet.name,
                                                      style: theme
                                                          .textTheme.labelSmall
                                                          ?.copyWith(
                                                        color: petColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  Icon(
                                                    _entryTypeIcon(entry.type),
                                                    size: 13,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      entry.name,
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOverdue
                                                ? colorScheme.error
                                                    .withAlpha(20)
                                                : Colors.orange.withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOverdue
                                                ? dateFormat
                                                    .format(entry.nextDueDate)
                                                : 'Today',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: isOverdue
                                                  ? colorScheme.error
                                                  : Colors.orange[800],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _entryTypeIcon(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication;
      case HealthEntryType.preventive:
        return Icons.shield;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital;
      case HealthEntryType.procedure:
        return Icons.more_horiz;
    }
  }
}
