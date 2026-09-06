import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/vet_providers.dart';
import '../widgets/vet_filter_bar.dart';
import '../widgets/vet_list_card.dart';
import '../widgets/vet_compact_row.dart';

class VetListScreen extends ConsumerWidget {
  const VetListScreen({
    super.key,
    this.embeddedInShell = false,
    this.experience = AppExperience.petCare,
    this.backPath = '/pc/home',
  });

  final bool embeddedInShell;
  final AppExperience experience;
  final String backPath;

  String get _listPath =>
      experience == AppExperience.petCare ? '/pc/vets' : '/o/vets';

  String? _defaultOrganizationIdForCreate(String? filter) {
    if (filter == null || filter == '_personal') return null;
    return filter;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetListAsync = ref.watch(vetListProvider);
    final filter = ref.watch(vetOrganizationFilterProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final orgs = ref.watch(organizationListProvider).valueOrNull ?? [];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (embeddedInShell)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l.veterinarians, style: theme.textTheme.headlineSmall),
          ),
        VetFilterBar(
          selectedFilter: filter,
          onFilterChanged: (value) =>
              ref.read(vetOrganizationFilterProvider.notifier).state = value,
          guardianOnly: experience == AppExperience.organization,
        ),
        Expanded(
          child: vetListAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load vets: $error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        ref.read(vetListProvider.notifier).refresh(),
                    child: Text(l.retry),
                  ),
                ],
              ),
            ),
            data: (vets) {
              if (vets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 80,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(l.noVetsYet, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        l.addVetFirst,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final petsAsync = ref.watch(petListProvider);
              final pets = petsAsync.valueOrNull ?? [];

              return RefreshIndicator(
                onRefresh: () => ref.read(vetListProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vets.length,
                  itemBuilder: (context, index) {
                    final vet = vets[index];
                    final linkedPets = pets
                        .where((p) => p.vetId == vet.id)
                        .toList();
                    final orgMatches = orgs.where(
                      (o) => o.id == vet.organizationId,
                    );
                    final orgName = orgMatches.isEmpty
                        ? null
                        : orgMatches.first.name;
                    if (experience == AppExperience.petCare) {
                      return VetCompactRow(
                        vet: vet,
                        linkedPetCount: linkedPets.length,
                        showChevron: false,
                        onTap: () => context.go('$_listPath/${vet.id}'),
                      );
                    }
                    return VetListCard(
                      vet: vet,
                      linkedPetNames: linkedPets.map((p) => p.name).toList(),
                      organizationName: orgName,
                      onTap: () => context.go('$_listPath/${vet.id}'),
                      onEdit: () => context.go('$_listPath/edit/${vet.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('add_vet_button'),
              onPressed: () {
                final orgId = _defaultOrganizationIdForCreate(filter);
                final query = orgId == null ? '' : '?org=$orgId';
                context.go('$_listPath/add$query');
              },
              icon: const Icon(Icons.add),
              label: Text(l.addVet),
            ),
          ),
        ),
      ],
    );

    if (embeddedInShell) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.veterinarians),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: () => context.go(backPath),
        ),
      ),
      body: body,
    );
  }
}
