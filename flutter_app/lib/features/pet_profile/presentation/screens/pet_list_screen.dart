import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/events_nav_icon_button.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_card.dart';
import '../controllers/pet_list_controller.dart';
import '../widgets/org_filter_chips.dart';
import '../widgets/personal_pets_section.dart';
import '../widgets/organization_pets_section.dart';
import '../widgets/passed_away_pets_section.dart';

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
  late final PetListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PetListController();
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
        title: const AppLogoTitle(title: AppConstants.appTitle),
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
          const EventsNavIconButton(),
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
                ((auth.user?.firstName?.isNotEmpty == true)
                  ? auth.user!.firstName![0]
                  : (auth.user?.lastName?.isNotEmpty == true ? auth.user!.lastName![0] : auth.user?.email[0] ?? 'U'))
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
              } else if (value == 'help') {
                context.push('/help');
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
                        auth.user?.firstName?.isNotEmpty == true
                          ? auth.user!.firstName!
                          : (auth.user?.lastName?.isNotEmpty == true ? auth.user!.lastName! : 'User'),
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
                  value: 'help',
                  child: ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(l.help),
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

          final orgNames = _controller.getOrgNames(allPets);
          final filteredPets = _controller.filterPets(allPets);
          final personalActive = _controller.getPersonalActive(filteredPets);
          final personalPassed = _controller.getPersonalPassed(filteredPets);
          final orgGroups = _controller.getOrgGroups(filteredPets);
          final orgPassedGroups = _controller.getOrgPassedGroups(filteredPets);
          final allPassedAway = _controller.getAllPassedAway(personalPassed, orgPassedGroups);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (orgNames.isNotEmpty)
                OrgFilterChips(
                  orgNames: orgNames,
                  selected: _controller.orgFilter,
                  onSelected: (v) => setState(() => _controller.orgFilter = v),
                  l: l,
                ),
              _PendingSharesSection(),
              _DueEventsSection(pets: allPets),
              if (_controller.orgFilter == null || _controller.orgFilter == '_personal') ...[
                if (personalActive.isNotEmpty || (_controller.orgFilter == null && orgGroups.isNotEmpty))
                  _SectionHeader(
                    icon: Icons.person,
                    title: l.myPets,
                    count: personalActive.length,
                  ),
                PersonalPetsSection(
                  personalActive: personalActive,
                  orgFilter: _controller.orgFilter,
                  l: l,
                  theme: theme,
                  ref: ref,
                  parentContext: context,
                ),
              ],
              OrganizationPetsSection(
                orgGroups: orgGroups,
                l: l,
                theme: theme,
                ref: ref,
                context: context,
              ),
              PassedAwayPetsSection(
                allPassedAway: allPassedAway,
                theme: theme,
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
          ..sort((a, b) {
            final ad = a.nextDueDate ?? DateTime(2100);
            final bd = b.nextDueDate ?? DateTime(2100);
            return ad.compareTo(bd);
          });

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
                                                    .format(entry.nextDueDate!)
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
      case HealthEntryType.familyEvent:
        return Icons.family_restroom;
    }
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

class _PendingSharesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSharesProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pendingShares) {
        if (pendingShares.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.share, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l.pendingShares,
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
                      '${pendingShares.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...pendingShares.map((share) => _PendingShareCard(share: share)),
            ],
          ),
        );
      },
    );
  }
}

class _PendingShareCard extends ConsumerWidget {
  const _PendingShareCard({required this.share});

  final PendingShare share;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final petColor = share.petColorValue != null
        ? Color(share.petColorValue!)
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.primary.withAlpha(80)),
        ),
        color: theme.colorScheme.primaryContainer.withAlpha(40),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: petColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AppConstants.speciesIconWidget(
                        share.petSpecies,
                        size: 22,
                        color: petColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          share.petName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.petSharedWithYou(
                            share.guardianName.isNotEmpty ? share.guardianName : 'Someone',
                            share.petName,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(pendingSharesProvider.notifier).declineShare(share.petId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.shareDeclined)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: Text(l.declineShare),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _showAcceptShareDialog(context, ref, share, l),
                    child: Text(l.acceptShare),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAcceptShareDialog(BuildContext context, WidgetRef ref, PendingShare share, AppLocalizations l) {
    final orgsAsync = ref.read(organizationListProvider);
    final orgs = orgsAsync.valueOrNull ?? [];

    if (orgs.isEmpty) {
      _doAcceptShare(context, ref, share.petId, null, l);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.acceptShareTo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l.acceptShareToHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(l.myPets),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _doAcceptShare(context, ref, share.petId, null, l);
                  },
                ),
                const Divider(),
                ...orgs.map((org) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(org.name),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _doAcceptShare(context, ref, share.petId, org.id, l);
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _doAcceptShare(BuildContext context, WidgetRef ref, String petId, String? orgId, AppLocalizations l) async {
    try {
      await ref.read(pendingSharesProvider.notifier).acceptShare(petId, organizationId: orgId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.shareAccepted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
