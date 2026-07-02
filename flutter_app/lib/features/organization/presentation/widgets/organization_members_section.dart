import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';

class OrganizationMembersSection extends StatelessWidget {
  final AsyncValue membersAsync;
  final bool isSuperUser;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final String Function(AppLocalizations, OrgMemberRole) localizedRoleLabel;
  final void Function()? onAddUser;

  const OrganizationMembersSection({
    super.key,
    required this.membersAsync,
    required this.isSuperUser,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.localizedRoleLabel,
    this.onAddUser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.people,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            membersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('$e',
                  style: TextStyle(color: colorScheme.error)),
              data: (members) {
                return Column(
                  children: [
                    ...members.map((member) {
                      final isPending = member.role.isPending;
                      return Opacity(
                        opacity: isPending ? 0.7 : 1.0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPending
                                ? Colors.grey.shade300
                                : AppTheme.orgIconBg,
                            child: isPending
                                ? Icon(Icons.hourglass_empty, size: 18, color: Colors.grey.shade600)
                                : Text(
                                    member.initials,
                                    style: const TextStyle(
                                      color: AppTheme.orgIconFg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            member.displayName,
                            style: isPending
                                ? TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)
                                : null,
                          ),
                          subtitle: Text(member.email),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? Colors.orange.withAlpha(30)
                                  : member.role.isSuperAdmin
                                      ? AppTheme.orgSuperUserBg
                                      : AppTheme.orgChipBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              localizedRoleLabel(l, member.role),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPending
                                    ? Colors.orange.shade800
                                    : member.role.isSuperAdmin
                                        ? AppTheme.orgSuperUserFg
                                        : AppTheme.orgChipFg,
                              ),
                            ),
                          ),
                          dense: true,
                        ),
                      );
                    }),
                    if (isSuperUser && onAddUser != null) ...[
                      const Divider(),
                      OutlinedButton.icon(
                        key: const Key('org_add_user_button'),
                        onPressed: onAddUser,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(l.addUser),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
