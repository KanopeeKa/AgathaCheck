import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';
import '../providers/org_discovery_provider.dart';
import '../utils/org_screen_theme.dart';
import '../widgets/org_card.dart';
import '../widgets/org_discovery/org_discovery_section.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';
import '../widgets/organization_role_labels.dart';

class OrganizationListScreen extends ConsumerWidget {
  const OrganizationListScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationListProvider);
    final pendingAsync = ref.watch(pendingOrgInvitesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final body = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(organizationListProvider);
        ref.invalidate(pendingOrgInvitesProvider);
        ref.invalidate(orgDiscoveryListProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          pendingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (invites) {
              if (invites.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.pendingInvites,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...invites.map(
                    (invite) => Card(
                      color: orgListCardColor(),
                      elevation: 0,
                      shape: orgListCardTheme().shape,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.inviteToJoinOrg(invite.organizationName),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.inviteAsRole(
                                localizedOrgRoleWire(l, invite.desiredRole),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (invite.inviterName.isNotEmpty ||
                                invite.inviterEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                l.invitedBy(
                                  invite.inviterName.isNotEmpty
                                      ? invite.inviterName
                                      : invite.inviterEmail,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(
                                            pendingOrgInvitesProvider.notifier,
                                          )
                                          .declineInvite(invite.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(l.inviteDeclined),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(l.declineInvite),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    try {
                                      final orgId = await ref
                                          .read(
                                            pendingOrgInvitesProvider.notifier,
                                          )
                                          .acceptInvite(invite.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(l.inviteAccepted),
                                          ),
                                        );
                                        context.push('/o/orgs/$orgId');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(l.acceptInvite),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            l.myOrganizations,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          orgsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('$error'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: const Key('org_retry_button'),
                    onPressed: () => ref.invalidate(organizationListProvider),
                    child: Text(l.retry),
                  ),
                ],
              ),
            ),
            data: (orgs) {
              if (orgs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.business_outlined,
                          size: 80,
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.orgNoOrganizations,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.createOrJoinOrganization,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: orgs
                    .map(
                      (org) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OrgCard(
                          organization: org,
                          onTap: () => context.push('/o/orgs/${org.id}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const OrgDiscoverySection(),
          const SizedBox(height: 16),
          Text(
            l.orgMembershipByEmailInvite,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('org_create_button'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.create),
              onPressed: () => context.push('/o/orgs/new'),
            ),
          ),
        ],
      ),
    );

    if (embeddedInShell) {
      return body;
    }

    return OrgShellScaffold(
      title: l.organisationsDashboardTitle,
      navVariant: OrgNavTitleVariant.dashboard,
      leadingKey: const Key('org_back_button'),
      onBack: () => context.go('/'),
      child: body,
    );
  }
}
