import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../../domain/entities/organization_member.dart';
import '../../providers/manage_fosters_providers.dart';
import '../organization_add_foster_parent_dialog.dart';

class FosterSummaryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final subtitleParts = <String>[
      if (parent.email != null && parent.email!.isNotEmpty) parent.email!,
      if (parent.phone != null && parent.phone!.isNotEmpty) parent.phone!,
      l.assignedPets(parent.activePetCount),
    ];

    String? statusLabel;
    if (fosterHasActivePlacement(parent)) {
      statusLabel = l.manageFostersStatusFostering;
    } else if (parent.isExternal) {
      statusLabel = l.fosterParentNoAccount;
    }

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
              CircleAvatar(
                child: Text(parent.initials),
              ),
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
              if (statusLabel != null)
                Chip(
                  label: Text(statusLabel),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
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
