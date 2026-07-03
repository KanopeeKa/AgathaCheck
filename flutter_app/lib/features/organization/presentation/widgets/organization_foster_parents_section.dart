import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/organization_member.dart';
import '../providers/organization_providers.dart';
import 'organization_add_foster_parent_dialog.dart';

class OrganizationFosterParentsSection extends ConsumerWidget {
  const OrganizationFosterParentsSection({
    super.key,
    required this.orgId,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.localizedRoleLabel,
  });

  final String orgId;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final String Function(AppLocalizations, OrgMemberRole) localizedRoleLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fosterParentsAsync = ref.watch(orgFosterParentsProvider(orgId));

    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.fosterParents,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.fosterParentsDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            fosterParentsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('$e', style: TextStyle(color: colorScheme.error)),
              data: (parents) {
                if (parents.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.noFosterParents,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...parents.map((parent) => _FosterParentTile(
                          parent: parent,
                          theme: theme,
                          colorScheme: colorScheme,
                          l: l,
                          localizedRoleLabel: localizedRoleLabel,
                          onDelete: parent.isExternal
                              ? () => _confirmDelete(context, ref, parent)
                              : null,
                        )),
                    const Divider(),
                    OutlinedButton.icon(
                      key: const Key('org_add_foster_parent_button'),
                      onPressed: () => showOrganizationAddFosterParentDialog(
                        context: context,
                        ref: ref,
                        orgId: orgId,
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: Text(l.addFosterParent),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FosterParent parent,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteFosterParent),
        content: Text(l.deleteFosterParentConfirm(parent.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(orgFosterParentsProvider(orgId).notifier)
        .deleteExternal(parent.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fosterParentDeleted)),
      );
    }
  }
}

class _FosterParentTile extends StatelessWidget {
  const _FosterParentTile({
    required this.parent,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.localizedRoleLabel,
    this.onDelete,
  });

  final FosterParent parent;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final String Function(AppLocalizations, OrgMemberRole) localizedRoleLabel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (parent.email != null && parent.email!.isNotEmpty) parent.email!,
      if (parent.phone != null && parent.phone!.isNotEmpty) parent.phone!,
      l.assignedPets(parent.activePetCount),
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.orgIconBg,
        child: Text(
          parent.initials,
          style: const TextStyle(
            color: AppTheme.orgIconFg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(parent.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitleParts.join(' · ')),
          if (parent.activePets.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              parent.activePets.map((p) => p.petName).join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      isThreeLine: parent.activePets.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: parent.isExternal
                  ? Colors.blueGrey.withAlpha(30)
                  : parent.role?.isSuperAdmin == true
                      ? AppTheme.orgSuperUserBg
                      : AppTheme.orgChipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              parent.isExternal
                  ? l.fosterParentNoAccount
                  : parent.role != null
                      ? localizedRoleLabel(l, parent.role!)
                      : '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: parent.isExternal
                    ? Colors.blueGrey.shade800
                    : parent.role?.isSuperAdmin == true
                        ? AppTheme.orgSuperUserFg
                        : AppTheme.orgChipFg,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: l.deleteFosterParent,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
      dense: true,
    );
  }
}
