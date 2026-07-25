import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../../domain/entities/organization_member.dart';
import '../../providers/manage_fosters_providers.dart';
import '../../providers/organization_providers.dart';
import '../../screens/manage_fosters/manage_fosters_screen.dart';
import '../organization_add_foster_parent_dialog.dart';
import 'foster_merge_dialog.dart';

class FosterSummaryCard extends ConsumerWidget {
  const FosterSummaryCard({
    super.key,
    required this.parent,
    required this.orgId,
    required this.localizedRoleLabel,
    this.onTap,
  });

  final FosterParent parent;
  final String orgId;
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

    String? activityLabel;
    if (fosterHasActivePlacement(parent)) {
      activityLabel = l.manageFostersStatusFostering;
    } else if (parent.isExternal) {
      activityLabel = l.fosterParentNoAccount;
    }

    final trailing = <Widget>[
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
      if (activityLabel != null)
        Chip(label: Text(activityLabel), visualDensity: VisualDensity.compact),
      if (parent.isExternal) _FosterActions(parent: parent, orgId: orgId),
    ];

    return Card(
      key: Key('foster_summary_card_${parent.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(parent.initials)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.displayName,
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
              ...trailing,
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
      case FosterApprovalState.approved:
        items.add(
          PopupMenuItem(
            value: 'archive',
            child: Text(l.manageFostersApprovalArchive),
          ),
        );
      case FosterApprovalState.declined:
        items.add(
          PopupMenuItem(
            value: 'approve',
            child: Text(l.manageFostersApprovalApprove),
          ),
        );
      case FosterApprovalState.archived:
        break;
    }

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
          case 'approve':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateApproval(parent.id, FosterApprovalState.approved);
          case 'decline':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateApproval(parent.id, FosterApprovalState.declined);
          case 'archive':
            await ref
                .read(orgFosterParentsProvider(orgId).notifier)
                .updateApproval(parent.id, FosterApprovalState.archived);
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
