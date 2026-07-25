import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/manage_fosters_providers.dart';
import '../../providers/organization_providers.dart';
import '../../utils/org_screen_theme.dart';
import '../../widgets/manage_fosters/foster_summary_card.dart';
import '../../widgets/organization_role_labels.dart';

final manageFostersTabProvider = StateProvider.family<ManageFostersTab, String>(
  (ref, orgId) => ManageFostersTab.all,
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
    final fosterParentsAsync = ref.watch(orgFosterParentsProvider(orgId));

    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.manageFostersTitle),
          leading: IconButton(
            key: const Key('manage_fosters_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
          actions: [
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
        ),
        body: Column(
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
              child: _ApprovalFiltersPlaceholder(l: l, theme: theme),
            ),
            Expanded(
              child: fosterParentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (parents) {
                  final filtered = filterFosterParentsForManageFosters(
                    parents: parents,
                    tab: tab,
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
                  return ListView.builder(
                    key: const Key('manage_fosters_list'),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final parent = filtered[index];
                      return FosterSummaryCard(
                        parent: parent,
                        orgId: orgId,
                        localizedRoleLabel: localizedOrgMemberRole,
                        onTap: parent.isExternal
                            ? () => context.push(
                                '/o/orgs/$orgId/people/external/${parent.id}',
                              )
                            : parent.userId != null
                            ? () => context.push(
                                '/o/orgs/$orgId/people/member/${parent.userId}',
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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

class _ApprovalFiltersPlaceholder extends StatelessWidget {
  const _ApprovalFiltersPlaceholder({required this.l, required this.theme});

  final AppLocalizations l;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
            InputChip(
              key: const Key('manage_fosters_filter_under_review'),
              label: Text(l.manageFostersFilterUnderReview),
              onPressed: null,
            ),
            InputChip(
              key: const Key('manage_fosters_filter_approved'),
              label: Text(l.manageFostersFilterApproved),
              onPressed: null,
            ),
            InputChip(
              key: const Key('manage_fosters_filter_archived'),
              label: Text(l.manageFostersFilterArchived),
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l.manageFostersApprovalFiltersComingSoon,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
