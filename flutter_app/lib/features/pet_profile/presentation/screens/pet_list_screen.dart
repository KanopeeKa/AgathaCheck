import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../health_tracking/presentation/widgets/events_nav_icon_button.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/pet_providers.dart';
import '../controllers/pet_list_controller.dart';
import '../widgets/org_filter_chips.dart';
import '../widgets/personal_pets_section.dart';
import '../widgets/fostered_pets_section.dart';
import '../widgets/organization_pets_section.dart';
import '../widgets/passed_away_pets_section.dart';
import '../widgets/pet_list/due_events_section.dart';
import '../widgets/pet_list/pending_custody_transfers_section.dart';
import '../widgets/pet_list/pending_adoption_placements_section.dart';
import '../widgets/pet_list/pending_foster_placements_section.dart';
import '../widgets/pet_list/pending_shares_section.dart';
import '../../../experience/presentation/screens/guardian/guardian_bulk_share.dart';
import '../widgets/pet_list/pet_list_section_header.dart';

/// Screen that displays the list of all pets owned by the user.
class PetListScreen extends ConsumerStatefulWidget {
  const PetListScreen({
    super.key,
    this.embeddedInShell = false,
    this.enableBulkShare = false,
  });

  /// When true, renders list body only (guardian shell provides top nav).
  final bool embeddedInShell;

  /// When true (with [embeddedInShell]), shows bulk-share multi-select for owned pets.
  final bool enableBulkShare;

  @override
  ConsumerState<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends ConsumerState<PetListScreen> {
  late final PetListController _controller;
  bool _bulkShareMode = false;
  final Set<String> _selectedPetIds = {};

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
    final petListAsync = ref.watch(petListProvider);
    final auth = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final scaffoldBody = petListAsync.when(
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
              onPressed: () => ref.invalidate(petListProvider),
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
                Text(l.noPetsYet, style: theme.textTheme.headlineSmall),
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

        final orgNames = widget.embeddedInShell
            ? <String>[]
            : _controller.getOrgNames(allPets);
        final hasFosteredPets = _controller.hasFosteredPets(allPets);
        _controller.syncOrgFilter(orgNames);
        final filteredPets = widget.embeddedInShell
            ? _controller.guardianShellPets(allPets)
            : _controller.filterPets(allPets);

        if (filteredPets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_off,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l.noPetsMatchFilter,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (_controller.orgFilter != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _controller.orgFilter = null),
                    child: Text(l.showAllPets),
                  ),
                ],
              ],
            ),
          );
        }
        final personalActive = _controller.getPersonalActive(filteredPets);
        final personalPassed = _controller.getPersonalPassed(filteredPets);
        final fosteredActive = _controller.getFosteredActive(filteredPets);
        final fosteredPassed = _controller.getFosteredPassed(filteredPets);
        final orgGroups = _controller.getOrgGroups(filteredPets);
        final orgPassedGroups = _controller.getOrgPassedGroups(filteredPets);
        final allPassedAway = _controller.getAllPassedAway(
          personalPassed,
          fosteredPassed,
          orgPassedGroups,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (orgNames.isNotEmpty || hasFosteredPets)
              OrgFilterChips(
                orgNames: orgNames,
                showFosteredChip: hasFosteredPets,
                selected: _controller.orgFilter,
                onSelected: (v) => setState(() => _controller.orgFilter = v),
                l: l,
              ),
            if (!widget.embeddedInShell) ...[
              PendingSharesSection(),
              PendingFosterPlacementsSection(),
              PendingAdoptionPlacementsSection(),
              const PendingCustodyTransfersSection(),
            ],
            if (!widget.embeddedInShell) DueEventsSection(pets: allPets),
            if (_controller.orgFilter == null ||
                _controller.orgFilter == '_personal') ...[
              if (personalActive.isNotEmpty ||
                  (_controller.orgFilter == null &&
                      (fosteredActive.isNotEmpty || orgGroups.isNotEmpty)))
                PetListSectionHeader(
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
                bulkShareMode: widget.enableBulkShare && _bulkShareMode,
                selectedPetIds: _selectedPetIds,
                onPetSelectionToggle: (petId) {
                  setState(() {
                    if (_selectedPetIds.contains(petId)) {
                      _selectedPetIds.remove(petId);
                    } else {
                      _selectedPetIds.add(petId);
                    }
                  });
                },
              ),
            ],
            if (_controller.orgFilter == null ||
                _controller.orgFilter == '_fostered') ...[
              if (fosteredActive.isNotEmpty ||
                  _controller.orgFilter == '_fostered')
                PetListSectionHeader(
                  icon: Icons.home_work_outlined,
                  title: l.myFosteredPets,
                  count: fosteredActive.length,
                ),
              FosteredPetsSection(
                fosteredActive: fosteredActive,
                orgFilter: _controller.orgFilter,
                l: l,
                theme: theme,
              ),
            ],
            if (!widget.embeddedInShell &&
                (_controller.orgFilter == null ||
                    (_controller.orgFilter != '_personal' &&
                        _controller.orgFilter != '_fostered')))
              OrganizationPetsSection(
                orgGroups: orgGroups,
                l: l,
                theme: theme,
                ref: ref,
                parentContext: context,
              ),
            PassedAwayPetsSection(allPassedAway: allPassedAway, theme: theme),
          ],
        );
      },
    );

    if (widget.embeddedInShell) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.enableBulkShare)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _bulkShareMode ? l.bulkShareSelectHint : l.allPets,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    key: const Key('bulk_share_toggle'),
                    onPressed: () {
                      setState(() {
                        _bulkShareMode = !_bulkShareMode;
                        if (!_bulkShareMode) _selectedPetIds.clear();
                      });
                    },
                    child: Text(_bulkShareMode ? l.cancel : l.bulkShare),
                  ),
                  if (_bulkShareMode)
                    FilledButton(
                      key: const Key('bulk_share_action'),
                      onPressed: () async {
                        final pets = ref.read(petListProvider).valueOrNull ?? [];
                        final owned = _controller
                            .getPersonalActive(_controller.guardianShellPets(pets))
                            .where((p) => !p.isShared && !p.isFoster && p.organizationId == null)
                            .where((p) => _selectedPetIds.contains(p.id))
                            .map((p) => (id: p.id, name: p.name))
                            .toList();
                        if (owned.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.bulkShareNoneSelected)),
                          );
                          return;
                        }
                        await runBulkShareForPets(context, ref, owned);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.bulkShareDone)),
                          );
                          setState(() {
                            _bulkShareMode = false;
                            _selectedPetIds.clear();
                          });
                        }
                      },
                      child: Text(l.bulkShareAction),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: scaffoldBody),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    key: const Key('add_pet_button'),
                    onPressed: () => context.push('/add'),
                    tooltip: l.addNewPet,
                    icon: const Icon(Icons.add),
                    label: Text(l.addPet),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: AppConstants.appTitle),
        actions: [
          MergeSemantics(
            child: Semantics(
              label: unreadCount > 0
                  ? '${l.notifications}, ${unreadCount > 99 ? '99+' : unreadCount} unread'
                  : l.notifications,
              child: Stack(
                clipBehavior: Clip.none,
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
                      child: ExcludeSemantics(
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
                    ),
                ],
              ),
            ),
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
                        : (auth.user?.lastName?.isNotEmpty == true
                              ? auth.user!.lastName![0]
                              : auth.user?.email[0] ?? 'U'))
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
                            : (auth.user?.lastName?.isNotEmpty == true
                                  ? auth.user!.lastName!
                                  : 'User'),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        auth.user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
      body: scaffoldBody,
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
