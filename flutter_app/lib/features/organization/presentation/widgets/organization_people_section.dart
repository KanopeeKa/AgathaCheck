import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';
import '../providers/organization_providers.dart';
import 'organization_add_foster_parent_dialog.dart';
import 'organization_invite_by_email_dialog.dart';
import 'org_person_card.dart';

class OrganizationPeopleSection extends ConsumerWidget {
  const OrganizationPeopleSection({
    super.key,
    required this.orgId,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.localizedRoleLabel,
    required this.isSuperUser,
    required this.isOrgAdmin,
  });

  final String orgId;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final String Function(AppLocalizations, OrgMemberRole) localizedRoleLabel;
  final bool isSuperUser;
  final bool isOrgAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(orgPeopleProvider(orgId));

    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.people,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.orgPeopleDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            peopleAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) =>
                  Text('$e', style: TextStyle(color: colorScheme.error)),
              data: (people) {
                if (people.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.orgNoMembers,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...people.map(
                      (person) => OrgPersonCard(
                        person: person,
                        orgId: orgId,
                        localizedRoleLabel: localizedRoleLabel,
                        canSetPrimaryContact: isOrgAdmin,
                        onSetPrimaryContact:
                            isOrgAdmin &&
                                !person.isExternal &&
                                !person.isPending &&
                                (person.role?.isOrgAdmin ?? false)
                            ? () async {
                                try {
                                  await ref
                                      .read(organizationListProvider.notifier)
                                      .setPrimaryContact(
                                        orgId,
                                        person.recordId,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l.orgPrimaryContact),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                }
                              }
                            : null,
                        onTap: () => context.push(person.detailPath(orgId)),
                      ),
                    ),
                    const Divider(),
                    if (isSuperUser)
                      OutlinedButton.icon(
                        key: const Key('org_add_user_button'),
                        onPressed: () => showOrganizationInviteByEmailDialog(
                          context: context,
                          ref: ref,
                          orgId: orgId,
                        ),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(l.addUser),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('org_add_external_foster_button'),
                      onPressed: () => showOrganizationAddFosterParentDialog(
                        context: context,
                        ref: ref,
                        orgId: orgId,
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: Text(l.addExternalFoster),
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
}
