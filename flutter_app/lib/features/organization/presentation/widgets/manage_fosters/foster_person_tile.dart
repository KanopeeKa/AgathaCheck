import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../../domain/entities/organization_member.dart';
import '../../../domain/services/foster_visibility.dart';
import '../../providers/organization_providers.dart';
import '../org_person_tile.dart';
import '../org_person_tile_grid.dart';
import 'foster_merge_dialog.dart';

class FosterPersonTile extends ConsumerWidget {
  const FosterPersonTile({
    super.key,
    required this.parent,
    required this.orgId,
    required this.canManage,
    required this.viewerUserId,
    required this.viewerRole,
    this.onTap,
  });

  final FosterParent parent;
  final String orgId;
  final bool canManage;
  final String? viewerUserId;
  final OrgMemberRole? viewerRole;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPhone = canViewerSeeFosterParentPhone(
      parent: parent,
      viewerUserId: viewerUserId,
      viewerRole: viewerRole,
    );

    return OrgPersonTile(
      key: Key('foster_person_tile_${parent.id}'),
      recordId: parent.id,
      displayName: parent.displayName,
      initials: parent.initials,
      photoUrl: parent.photoUrl,
      role: parent.isExternal ? null : parent.role,
      isExternal: parent.isExternal,
      fosterApprovalState: parent.approvalState.toWire(),
      fosterNeedsAttention:
          parent.approvalState == FosterApprovalState.declined ||
          parent.approvalState == FosterApprovalState.archived,
      activeFosterCount: parent.activePetCount,
      isSelf: parent.isSelfCard,
      selfCardLabel: parent.isSelfCard
          ? AppLocalizations.of(context)!.fosterSelfPrefsYourCard
          : null,
      phone: showPhone ? parent.phone : null,
      onTap: onTap,
      trailing: parent.isExternal && canManage
          ? _FosterActions(parent: parent, orgId: orgId)
          : null,
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

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface.withAlpha(230),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        key: Key('foster_actions_menu_${parent.id}'),
        icon: const Icon(Icons.more_vert, size: 20),
        padding: EdgeInsets.zero,
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
      ),
    );
  }
}

/// Foster directory tile grid for Manage Fosters.
class FosterPersonTileGrid extends ConsumerWidget {
  const FosterPersonTileGrid({
    super.key,
    required this.orgId,
    required this.parents,
    required this.canManage,
    required this.viewerUserId,
  });

  final String orgId;
  final List<FosterParent> parents;
  final bool canManage;
  final String? viewerUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));

    return OrgPersonTileGrid(
      gridKey: const Key('manage_fosters_tile_grid'),
      tiles: parents
          .map(
            (parent) => FosterPersonTile(
              parent: parent,
              orgId: orgId,
              canManage: canManage,
              viewerUserId: viewerUserId,
              viewerRole: viewerRole,
              onTap: parent.isExternal
                  ? () => context.push(
                      '/o/orgs/$orgId/people/external/${parent.id}',
                    )
                  : parent.userId != null
                  ? () => context.push(
                      '/o/orgs/$orgId/people/member/${parent.id}',
                    )
                  : null,
            ),
          )
          .toList(),
    );
  }
}
