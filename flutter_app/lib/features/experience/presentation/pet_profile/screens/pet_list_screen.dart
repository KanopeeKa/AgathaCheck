import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import '../utils/pet_care_dashboard_helpers.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/notifications/notifications.dart';
import '../widgets/pet_list/guardian_embedded_pets_list.dart';
import '../widgets/pet_list/pet_list_app_bar.dart';
import '../widgets/pet_list/pet_list_filtered_content.dart';
import '../widgets/pet_list/pet_list_status_views.dart';

/// Screen that displays the list of all pets owned by the user.
class PetListScreen extends ConsumerStatefulWidget {
  const PetListScreen({
    super.key,
    this.embeddedInShell = false,
    this.visiblePetIds,
  });

  /// When true, renders list body only (guardian shell provides top nav).
  final bool embeddedInShell;

  /// When set, only pets whose ids are in this set are shown.
  final Set<String>? visiblePetIds;

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
    final petListAsync = ref.watch(petListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final entriesAsync = widget.embeddedInShell
        ? ref.watch(healthEntriesNotifierProvider)
        : null;
    final careSummary = (entriesAsync != null && entriesAsync.hasValue)
        ? PetCareTodayCareSummary.forPets(
            entries: entriesAsync.valueOrNull!,
            pets: _controller.guardianShellPets(petListAsync.valueOrNull ?? []),
          )
        : null;

    final scaffoldBody = petListAsync.when(
      loading: () => const PetListLoadingBody(),
      error: (error, stack) => PetListErrorBody(
        message: l.failedToLoadPets(error.toString()),
        onRetry: () => ref.invalidate(petListProvider),
        retryLabel: l.retry,
      ),
      data: (allPets) => _buildPetListData(
        allPets: allPets,
        careSummary: careSummary,
        theme: theme,
        l: l,
      ),
    );

    if (widget.embeddedInShell) {
      return scaffoldBody;
    }

    return Scaffold(
      appBar: PetListAppBar(
        unreadCount: unreadCount,
        onLogout: () => ref.read(authProvider.notifier).logout(),
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

  Widget _buildPetListData({
    required List<Pet> allPets,
    required PetCareTodayCareSummary? careSummary,
    required ThemeData theme,
    required AppLocalizations l,
  }) {
    final scopedPets = widget.visiblePetIds == null
        ? allPets
        : allPets
              .where((pet) => widget.visiblePetIds!.contains(pet.id))
              .toList();

    if (scopedPets.isEmpty) {
      return PetListNoPetsEmptyBody(
        headline: allPets.isEmpty ? l.noPetsYet : l.petTagsNoMatch,
        subtitle: l.addFirstPet,
        showSubtitle: allPets.isEmpty,
      );
    }

    if (widget.embeddedInShell) {
      return PetCareEmbeddedPetsList(
        allPets: scopedPets,
        controller: _controller,
        careSummary: careSummary,
        l: l,
        theme: theme,
      );
    }

    final orgNames = _controller.getOrgNames(scopedPets);
    final hasFosteredPets = _controller.hasFosteredPets(scopedPets);
    _controller.syncOrgFilter(orgNames);
    final filteredPets = _controller.filterPets(scopedPets);

    if (filteredPets.isEmpty) {
      return PetListFilterEmptyBody(
        message: l.noPetsMatchFilter,
        showClearFilter: _controller.orgFilter != null,
        clearFilterLabel: l.showAllPets,
        onClearFilter: () => setState(() => _controller.orgFilter = null),
      );
    }

    return PetListFilteredContent(
      filteredPets: filteredPets,
      orgNames: orgNames,
      hasFosteredPets: hasFosteredPets,
      orgFilter: _controller.orgFilter,
      onOrgFilterChanged: (v) => setState(() => _controller.orgFilter = v),
      controller: _controller,
      l: l,
      theme: theme,
      ref: ref,
      parentContext: context,
    );
  }
}
