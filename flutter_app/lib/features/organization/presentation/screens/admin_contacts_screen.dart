import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/admin_contacts.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_contact_providers.dart';
import '../providers/organization_providers.dart';
import '../widgets/admin_contacts/admin_contact_invite_dialog.dart';
import '../widgets/admin_contacts/admin_contacts_list.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class AdminContactsScreen extends ConsumerWidget {
  const AdminContactsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(orgPeopleProvider(orgId));
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));
    final viewerUserId = ref.watch(authProvider.select((s) => s.user?.id));
    final canManage = canManageAdminContacts(viewerRole, orgId);
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return OrgShellScaffold(
      title: l.adminContactsTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('admin_contacts_back'),
      contextualActions: [
        if (canManage)
          IconButton(
            key: const Key('admin_contacts_add'),
            icon: const Icon(Icons.person_add),
            tooltip: l.adminContactsAddAdmin,
            onPressed: () => showAdminContactInviteDialog(
              context: context,
              ref: ref,
              orgId: orgId,
            ),
          ),
      ],
      child: peopleAsync.when(
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
                key: const Key('admin_contacts_retry'),
                onPressed: () => ref.invalidate(orgPeopleProvider(orgId)),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (people) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminContactsList(
              orgId: orgId,
              people: people,
              viewerUserId: viewerUserId,
            ),
          ],
        ),
      ),
    );
  }
}
