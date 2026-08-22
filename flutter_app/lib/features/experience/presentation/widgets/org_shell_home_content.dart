import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../organization/presentation/widgets/org_card.dart';

/// Organisation shell home: a calm switcher into each organisation workspace.
///
/// Operational destinations stay inside the selected organisation's profile.
/// This keeps the section root useful for orientation without duplicating the
/// pet/event feeds or turning the global drawer into an organisation sitemap.
class OrgShellHomeContent extends ConsumerWidget {
  const OrgShellHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final orgsAsync = ref.watch(organizationListProvider);

    return orgsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _OrgHubMessage(
        icon: Icons.error_outline,
        title: l.orgNoOrganizations,
        detail: '$e',
        action: TextButton(
          onPressed: () => ref.invalidate(organizationListProvider),
          child: Text(l.retry),
        ),
      ),
      data: (orgs) {
        if (orgs.isEmpty) {
          return _OrgHubMessage(
            icon: Icons.business_outlined,
            title: l.orgNoOrganizations,
            detail: l.createOrJoinOrganization,
            action: FilledButton.icon(
              onPressed: () => context.push('/organizations/new'),
              icon: const Icon(Icons.add),
              label: Text(l.create),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _OrgHubHeader(
              title: l.organisationsDashboardTitle,
              subtitle: l.orgMembershipByEmailInvite,
            ),
            const SizedBox(height: 20),
            Text(
              l.myOrganizations,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...orgs.map(
              (org) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrgCard(
                  organization: org,
                  onTap: () => context.push('/o/orgs/${org.id}'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('org_home_create'),
              onPressed: () => context.push('/organizations/new'),
              icon: const Icon(Icons.add),
              label: Text(l.create),
            ),
          ],
        );
      },
    );
  }
}

class _OrgHubHeader extends StatelessWidget {
  const _OrgHubHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      header: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.business_center_outlined,
                color: colors.primary,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgHubMessage extends StatelessWidget {
  const _OrgHubMessage({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            action,
          ],
        ),
      ),
    );
  }
}
