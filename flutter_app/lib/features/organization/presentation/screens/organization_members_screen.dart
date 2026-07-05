import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';
import '../widgets/organization_invite_by_email_dialog.dart';
import '../widgets/organization_add_foster_parent_dialog.dart';
import '../widgets/organization_role_labels.dart';
import '../widgets/org_person_card.dart';

class OrganizationMembersScreen extends ConsumerWidget {
  const OrganizationMembersScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(orgPeopleProvider(orgId));
    final isSuperAdmin = ref.watch(isOrgSuperUserProvider(orgId));
    final isOrgAdmin = ref.watch(isOrgAdminProvider(orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.orgBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.orgBlue,
        title: AppLogoTitle(title: l.orgMembers),
        leading: IconButton(
          key: const Key('org_members_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isOrgAdmin)
            IconButton(
              key: const Key('org_generate_invite'),
              icon: const Icon(Icons.person_add),
              tooltip: l.orgInviteMember,
              onPressed: () => showOrganizationInviteByEmailDialog(
                context: context,
                ref: ref,
                orgId: orgId,
              ),
            ),
        ],
      ),
      body: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('org_members_retry'),
                onPressed: () => ref.invalidate(orgPeopleProvider(orgId)),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (people) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.orgPeopleDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (people.isEmpty)
                Center(child: Text(l.orgNoMembers))
              else
                ...people.map(
                  (person) => OrgPersonCard(
                    person: person,
                    orgId: orgId,
                    localizedRoleLabel: localizedOrgMemberRole,
                    onTap: person.isPending
                        ? null
                        : () => context.push(person.detailPath(orgId)),
                  ),
                ),
              const SizedBox(height: 16),
              if (isSuperAdmin)
                OutlinedButton.icon(
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
    );
  }
}
