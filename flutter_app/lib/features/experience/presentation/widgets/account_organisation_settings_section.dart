import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/providers/org_provider_list.dart';

/// Lists organisations on the Account screen; each opens per-org privacy settings.
class AccountOrganisationSettingsSection extends ConsumerWidget {
  const AccountOrganisationSettingsSection({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final orgsAsync = ref.watch(organizationListProvider);

    return orgsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error'),
      data: (orgs) {
        if (orgs.isEmpty) {
          return Text(
            l.accountOrgSettingsEmpty,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: orgs.map((org) => _OrgRow(org: org)).toList(),
        );
      },
    );
  }
}

class _OrgRow extends StatelessWidget {
  const _OrgRow({required this.org});

  final Organization org;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('account_org_settings_${org.id}'),
      onTap: () => context.push('/account/orgs/${org.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.business_outlined, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(org.name)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
