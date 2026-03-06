import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
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
  String? _orgFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).checkDueEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(allPetsIncludingOrgProvider);
    final auth = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

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
                tooltip: l.notifications,
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
            tooltip: l.veterinarians,
            onPressed: () => context.go('/vets'),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l.events,
            onPressed: () => context.go('/health'),
          ),
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: l.organizations,
            onPressed: () => context.go('/organizations'),
          ),
          PopupMenuButton<String>(
            tooltip: l.userMenu,
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
            itemBuilder: (context) {
              final l = AppLocalizations.of(context)!;
              return [
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
                PopupMenuItem<String>(
                  value: 'details',
                  child: ListTile(
                    leading: const Icon(Icons.person_outlined),
                    title: Text(l.myDetails),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l.logOut),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
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
              Text(l.failedToLoadPets(error.toString())),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(allPetsIncludingOrgProvider),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (allPets) {
          if (allPets.isEmpty) {
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
                    l.noPetsYet,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.addFirstPet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final orgNames = allPets
              .where((p) => p.organizationName != null)
              .map((p) => p.organizationName!)
              .toSet()
              .toList()
            ..sort();

          final filteredPets = _orgFilter == null
              ? allPets
              : _orgFilter == '_personal'
                  ? allPets.where((p) => p.organizationId == null).toList()
                  : allPets.where((p) => p.organizationName == _orgFilter).toList();

          final personalActive = filteredPets.where((p) => p.organizationId == null && !p.passedAway).toList();
          final personalPassed = filteredPets.where((p) => p.organizationId == null && p.passedAway).toList();

          final orgGroups = <String, List<Pet>>{};
          final orgPassedGroups = <String, List<Pet>>{};
          for (final pet in filteredPets) {
            if (pet.organizationName != null) {
              if (pet.passedAway) {
                orgPassedGroups.putIfAbsent(pet.organizationName!, () => []).add(pet);
              } else {
                orgGroups.putIfAbsent(pet.organizationName!, () => []).add(pet);
              }
            }
          }

          final allPassedAway = [...personalPassed];
          for (final pets in orgPassedGroups.values) {
            allPassedAway.addAll(pets);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (orgNames.isNotEmpty)
                _OrgFilterChips(
                  orgNames: orgNames,
                  selected: _orgFilter,
                  onSelected: (v) => setState(() => _orgFilter = v),
                  l: l,
                ),
              _DueEventsSection(pets: allPets),
              if (_orgFilter == null || _orgFilter == '_personal') ...[
                if (personalActive.isNotEmpty || (_orgFilter == null && orgGroups.isNotEmpty))
                  _SectionHeader(
                    icon: Icons.person,
                    title: l.myPets,
                    count: personalActive.length,
                  ),
                ...personalActive.map((pet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PetCard(
                    pet: pet,
                    onTap: () => context.go('/pet/${pet.id}'),
                  ),
                )),
                if (personalActive.isEmpty && _orgFilter == '_personal')
                  _EmptySection(message: l.noPetsYet),
              ],
              for (final orgName in orgGroups.keys.toList()..sort()) ...[
                _SectionHeader(
                  icon: Icons.business,
                  title: orgName,
                  count: (orgGroups[orgName]?.length ?? 0),
                ),
                ...orgGroups[orgName]!.map((pet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PetCard(
                    pet: pet,
                    onTap: () => context.go('/pet/${pet.id}'),
                  ),
                )),
              ],
              if (allPassedAway.isNotEmpty)
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
                              '${allPassedAway.length}',
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
                            children: allPassedAway.map((pet) => Padding(
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
        tooltip: l.addNewPet,
        icon: const Icon(Icons.add),
        label: Text(l.addPet),
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

class _OrgFilterChips extends StatelessWidget {
  const _OrgFilterChips({
    required this.orgNames,
    required this.selected,
    required this.onSelected,
    required this.l,
  });

  final List<String> orgNames;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text(l.allPets),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(l.myPets),
              selected: selected == '_personal',
              onSelected: (_) => onSelected('_personal'),
            ),
            ...orgNames.map((name) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                avatar: const Icon(Icons.business, size: 16),
                label: Text(name),
                selected: selected == name,
                onSelected: (_) => onSelected(name),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
