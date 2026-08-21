import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../../domain/entities/organization_member.dart';
import '../../providers/organization_providers.dart';
import '../../screens/manage_fosters/manage_fosters_screen.dart';
import '../organization_add_foster_parent_dialog.dart';
import '../../../foster_home_visit/presentation/widgets/foster_home_visit_forms.dart';
import 'foster_merge_dialog.dart';

class FosterSummaryCard extends ConsumerWidget {
  const FosterSummaryCard({
    super.key,
    required this.parent,
    required this.orgId,
    required this.canManage,
    required this.localizedRoleLabel,
    this.onTap,
  });

  final FosterParent parent;
  final String orgId;
  final bool canManage;
  final String Function(AppLocalizations, OrgMemberRole) localizedRoleLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final subtitleParts = <String>[
      if (parent.email != null && parent.email!.isNotEmpty) parent.email!,
      if (parent.phone != null && parent.phone!.isNotEmpty) parent.phone!,
      l.assignedPets(parent.activePetCount),
    ];

    final activityLabel = switch (parent.fosteringActivitySummary) {
      FosteringActivitySummary.activelyFostering =>
        l.manageFostersStatusFostering,
      FosteringActivitySummary.inPreparation =>
        l.fosteringSessionPreparationTitle,
      FosteringActivitySummary.recentlyEnded =>
        l.manageFostersTabRecentlyFostered,
      FosteringActivitySummary.notYetPlaced =>
        parent.isExternal ? l.fosterParentNoAccount : null,
      FosteringActivitySummary.inactive => null,
    };

    final statusChips = <Widget>[
      if (parent.isExternal &&
          parent.approvalState != FosterApprovalState.approved)
        Chip(
          key: Key('foster_approval_chip_${parent.id}'),
          label: Text(localizedFosterApprovalState(l, parent.approvalState)),
          visualDensity: VisualDensity.compact,
        ),
      if (parent.isExternal && parent.isLinkedToRegisteredAccount)
        Chip(
          key: Key('foster_linked_chip_${parent.id}'),
          label: Text(l.manageFostersLinkedAccount),
          visualDensity: VisualDensity.compact,
        ),
      if (parent.isExternal && parent.hasOutreachOptOut)
        Chip(
          key: Key('foster_opt_out_chip_${parent.id}'),
          label: Text(l.manageFostersOutreachOptOut),
          visualDensity: VisualDensity.compact,
        ),
      if (parent.isExternal)
        Chip(
          key: Key('foster_retention_chip_${parent.id}'),
          label: Text(
            localizedFosterRetentionCategory(l, parent.retentionCategory),
          ),
          visualDensity: VisualDensity.compact,
        ),
      if (activityLabel != null)
        Chip(label: Text(activityLabel), visualDensity: VisualDensity.compact),
    ];

    return Card(
      key: Key('foster_summary_card_${parent.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Text(parent.initials)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.isSelfCard
                              ? l.fosterSelfPrefsYourCard
                              : parent.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleParts.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (parent.role != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            localizedRoleLabel(l, parent.role!),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (parent.isExternal && canManage)
                    _FosterActions(parent: parent, orgId: orgId),
                ],
              ),
              if (statusChips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: statusChips),
              ],
              if (parent.isSelfCard) ...[
                const SizedBox(height: 12),
                FosterHomeVisitStatusLink(orgId: orgId),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FosterActions extends ConsumerWidget {
  const _FosterActions({required this.parent, required this.orgId});

  final FosterParent parent;
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<String>>[];
    final mergeAvailable = parent.canMergeIntoRegisteredAccount;

    if (mergeAvailable) {
      items.add(
        PopupMenuItem(
          value: 'merge',
          child: Text(l.manageFostersMergeIntoAccount),
        ),
      );
    }

    switch (parent.approvalState) {
      case FosterApprovalState.underReview:
        items.addAll([
          PopupMenuItem(
            value: 'approve',
            child: Text(l.manageFostersApprovalApprove),
          ),
          PopupMenuItem(
            value: 'decline',
            child: Text(l.manageFostersApprovalDecline),
          ),
        ]);
        break;
      case FosterApprovalState.approved:
        items.add(
          PopupMenuItem(
            value: 'archive',
            child: Text(l.manageFostersApprovalArchive),
          ),
        );
        break;
      case FosterApprovalState.declined:
        items.add(
          PopupMenuItem(
            value: 'approve',
            child: Text(l.manageFostersApprovalApprove),
          ),
        );
        break;
      case FosterApprovalState.archived:
        break;
    }

    items.add(
      PopupMenuItem(
        value: parent.hasOutreachOptOut ? 'clear_opt_out' : 'record_opt_out',
        child: Text(
          parent.hasOutreachOptOut
              ? l.manageFostersClearOutreachOptOut
              : l.manageFostersRecordOutreachOptOut,
        ),
      ),
    );

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      key: Key('foster_actions_menu_${parent.id}'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case 'merge':
            await showFosterMergeDialog(
              context: context,
              ref: ref,
              orgId: orgId,
              parent: parent,
            );
            break;
          case 'approve':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateApproval(parent.id, FosterApprovalState.approved);
            break;
          case 'decline':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateApproval(parent.id, FosterApprovalState.declined);
            break;
          case 'archive':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateApproval(parent.id, FosterApprovalState.archived);
            break;
          case 'record_opt_out':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateOptOut(parent.id, true);
            break;
          case 'clear_opt_out':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateOptOut(parent.id, false);
            break;
        }
      },
      itemBuilder: (context) => items,
    );
  }
}

void showManageFostersAddManualDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
}) {
  showOrganizationAddFosterParentDialog(
    context: context,
    ref: ref,
    orgId: orgId,
  );
}
