import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../../domain/services/foster_visibility.dart';
import '../../providers/manage_fosters_providers.dart';
import '../../providers/organization_providers.dart';
import '../../widgets/manage_fosters/foster_person_tile.dart';
import '../../widgets/manage_fosters/foster_summary_card.dart' show showManageFostersAddManualDialog;
import '../../widgets/org_shell_app_bar_title.dart';
import '../../widgets/org_shell_scaffold.dart';

final manageFostersTabProvider = StateProvider.family<ManageFostersTab, String>(
  (ref, orgId) => ManageFostersTab.all,
);

final manageFostersApprovalFilterProvider =
    StateProvider.family<ManageFostersApprovalFilter?, String>(
      (ref, orgId) => null,
    );

class ManageFostersScreen extends ConsumerWidget {
  const ManageFostersScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tab = ref.watch(manageFostersTabProvider(orgId));
    final approvalFilter = ref.watch(
      manageFostersApprovalFilterProvider(orgId),
    );
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));
    final viewerUserId = ref.watch(authProvider.select((s) => s.user?.id));
    final canManage = canManageFosters(viewerRole, orgId);
    final fosterParentsAsync = ref.watch(orgFosterParentsProvider(orgId));

    return OrgShellScaffold(
      title: l.manageFostersTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('manage_fosters_back'),
      contextualActions: [
        IconButton(
          key: const Key('manage_fosters_foster_requests'),
          icon: const Icon(Icons.mail_outline),
          tooltip: l.fosterRequestsTitle,
          onPressed: canManage
              ? () => context.push('/o/orgs/$orgId/foster-requests')
              : null,
        ),
        if (canManage)
          IconButton(
            key: const Key('manage_fosters_add_manual'),
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l.addExternalFoster,
            onPressed: () => showManageFostersAddManualDialog(
              context: context,
              ref: ref,
              orgId: orgId,
            ),
          ),
      ],
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                l.manageFostersDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ManageFostersTabBar(orgId: orgId, selected: tab),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _ApprovalFilters(orgId: orgId, selected: approvalFilter),
            ),
            Expanded(
              child: fosterParentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (parents) {
                  final filtered = filterFosterParentsForManageFosters(
                    parents: parents,
                    tab: tab,
                    approvalFilter: approvalFilter,
                  );
                  if (tab == ManageFostersTab.recentlyFostered) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.manageFostersRecentlyFosteredPlaceholder,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l.manageFostersEmptyTab,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView(
                    key: const Key('manage_fosters_list'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      FosterPersonTileGrid(
                        orgId: orgId,
                        parents: filtered,
                        canManage: canManage,
                        viewerUserId: viewerUserId,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
    ),
    );
  }
}

class _ManageFostersTabBar extends ConsumerWidget {
  const _ManageFostersTabBar({required this.orgId, required this.selected});

  final String orgId;
  final ManageFostersTab selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tabs = <(ManageFostersTab, String)>[
      (ManageFostersTab.newFosters, l.manageFostersTabNew),
      (ManageFostersTab.fostering, l.manageFostersTabFostering),
      (ManageFostersTab.recentlyFostered, l.manageFostersTabRecentlyFostered),
      (ManageFostersTab.inactive, l.manageFostersTabInactive),
      (ManageFostersTab.all, l.manageFostersTabAll),
    ];

    return SingleChildScrollView(
      key: const Key('manage_fosters_tabs'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (tab, label) in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: Key('manage_fosters_tab_${tab.name}'),
                label: Text(label),
                selected: selected == tab,
                onSelected: (_) {
                  ref.read(manageFostersTabProvider(orgId).notifier).state =
                      tab;
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ApprovalFilters extends ConsumerWidget {
  const _ApprovalFilters({required this.orgId, required this.selected});

  final String orgId;
  final ManageFostersApprovalFilter? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filters = <(ManageFostersApprovalFilter, String, Key)>[
      (
        ManageFostersApprovalFilter.underReview,
        l.manageFostersFilterUnderReview,
        const Key('manage_fosters_filter_under_review'),
      ),
      (
        ManageFostersApprovalFilter.approved,
        l.manageFostersFilterApproved,
        const Key('manage_fosters_filter_approved'),
      ),
      (
        ManageFostersApprovalFilter.archived,
        l.manageFostersFilterArchived,
        const Key('manage_fosters_filter_archived'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.manageFostersApprovalFiltersLabel,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final (filter, label, key) in filters)
              FilterChip(
                key: key,
                label: Text(label),
                selected: selected == filter,
                onSelected: (isSelected) {
                  ref
                      .read(manageFostersApprovalFilterProvider(orgId).notifier)
                      .state = isSelected
                      ? filter
                      : null;
                },
              ),
          ],
        ),
      ],
    );
  }
}

String localizedFosterApprovalState(
  AppLocalizations l,
  FosterApprovalState state,
) {
  switch (state) {
    case FosterApprovalState.underReview:
      return l.manageFostersApprovalStateUnderReview;
    case FosterApprovalState.approved:
      return l.manageFostersApprovalStateApproved;
    case FosterApprovalState.declined:
      return l.manageFostersApprovalStateDeclined;
    case FosterApprovalState.archived:
      return l.manageFostersApprovalStateArchived;
  }
}

String localizedFosterRetentionCategory(AppLocalizations l, String category) {
  switch (category) {
    case 'declined_archived':
      return l.manageFostersRetentionDeclinedArchived;
    case 'manual_contact':
      return l.manageFostersRetentionManualContact;
    case 'shelter_foster_relationship':
    default:
      return l.manageFostersRetentionShelterFosterRelationship;
  }
}
