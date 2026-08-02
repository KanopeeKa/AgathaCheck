import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/admin_contact_self_prefs.dart';
import '../../../domain/services/admin_contacts.dart';
import '../../providers/admin_contact_providers.dart';
import '../../providers/organization_providers.dart';
import '../admin_contacts/admin_contact_card.dart';

/// Profile preview of organisation admin contacts (photo, name, role, messaging).
class OrganisationProfileAdminContacts extends ConsumerWidget {
  const OrganisationProfileAdminContacts({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(orgPeopleProvider(orgId));
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));
    final viewerUserId = ref.watch(authProvider.select((s) => s.user?.id));
    final selfPrefs = ref.watch(adminContactSelfPrefsProvider(orgId));
    final l = AppLocalizations.of(context)!;
    final mutedStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return peopleAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('$e', style: mutedStyle),
      data: (people) {
        final sorted = sortAdminContacts(
          contacts: people,
          viewerUserId: viewerUserId,
        );

        if (sorted.isEmpty) {
          return Text(l.adminContactsEmpty, style: mutedStyle);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sorted.map((person) {
            final isSelf = viewerHasAdminSelfCard(person, viewerUserId);
            return AdminContactCard(
              key: Key('org_profile_admin_contact_${person.recordId}'),
              person: person,
              orgId: orgId,
              viewerRole: viewerRole,
              viewerUserId: viewerUserId,
              phoneVisibility: isSelf
                  ? selfPrefs.phoneVisibility
                  : AdminPhoneVisibility.admins,
              isSelf: isSelf,
              onView: person.isPending
                  ? null
                  : () => context.push(person.detailPath(orgId)),
            );
          }).toList(),
        );
      },
    );
  }
}
