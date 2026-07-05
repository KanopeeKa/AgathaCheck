import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/entities/org_person.dart';

Color orgPersonBorderColor(OrgPersonSummary person) {
  if (person.isExternal) return Colors.grey.shade500;
  final role = person.role;
  if (role == null) return Colors.grey.shade400;
  if (role.isSuperAdmin || role == OrgMemberRole.pendingSuperAdmin) {
    return const Color(0xFFD4AF37);
  }
  if (role.isOrgAdmin || role == OrgMemberRole.pendingAdmin) {
    return const Color(0xFFC0C0C0);
  }
  return Colors.transparent;
}

class OrgPersonCard extends StatelessWidget {
  const OrgPersonCard({
    super.key,
    required this.person,
    required this.orgId,
    required this.localizedRoleLabel,
    this.onTap,
  });

  final OrgPersonSummary person;
  final String orgId;
  final String Function(AppLocalizations, OrgMemberRole) localizedRoleLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final borderColor = orgPersonBorderColor(person);
    final roleLabel = person.isExternal
        ? l.fosterParentNoAccount
        : person.role != null
            ? localizedRoleLabel(l, person.role!)
            : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.orgBlueDarker,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: person.isPending ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor == Colors.transparent
                    ? theme.colorScheme.outlineVariant.withAlpha(120)
                    : borderColor,
                width: borderColor == Colors.transparent ? 1 : 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              person.isPending ? FontStyle.italic : null,
                          color: person.isPending
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleChip(
                        label: roleLabel,
                        isPending: person.isPending,
                        isSuperAdmin: person.role?.isSuperAdmin == true,
                        isExternal: person.isExternal,
                      ),
                    ],
                  ),
                ),
                _FosterStatusDisk(count: person.activeFosterCount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.isPending,
    required this.isSuperAdmin,
    required this.isExternal,
  });

  final String label;
  final bool isPending;
  final bool isSuperAdmin;
  final bool isExternal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.orange.withAlpha(30)
            : isExternal
                ? Colors.blueGrey.withAlpha(30)
                : isSuperAdmin
                    ? AppTheme.orgSuperUserBg
                    : AppTheme.orgChipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPending
              ? Colors.orange.shade800
              : isExternal
                  ? Colors.blueGrey.shade800
                  : isSuperAdmin
                      ? AppTheme.orgSuperUserFg
                      : AppTheme.orgChipFg,
        ),
      ),
    );
  }
}

class _FosterStatusDisk extends StatelessWidget {
  const _FosterStatusDisk({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: active
          ? Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : null,
    );
  }
}
