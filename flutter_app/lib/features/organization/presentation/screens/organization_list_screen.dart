import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/organization_remote_datasource.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_card.dart';

class OrganizationListScreen extends ConsumerWidget {
  const OrganizationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationListProvider);
    final pendingAsync = ref.watch(pendingOrgInvitesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.orgBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.orgBlue,
        title: AppLogoTitle(title: l.myOrganizations),
        leading: IconButton(
          key: const Key('org_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(organizationListProvider);
          ref.invalidate(pendingOrgInvitesProvider);
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
                    Text(l.pendingInvites,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 8),
                    ...invites.map((invite) => Card(
                      color: colorScheme.primaryContainer.withAlpha(40),
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
                              l.inviteAsRole(invite.desiredRole == 'super_user'
                                  ? l.orgSuperUser
                                  : l.orgMember),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (invite.inviterName.isNotEmpty || invite.inviterEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                l.invitedBy(invite.inviterName.isNotEmpty
                                    ? invite.inviterName
                                    : invite.inviterEmail),
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
                                          .read(pendingOrgInvitesProvider.notifier)
                                          .declineInvite(invite.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l.inviteDeclined)),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                                          .read(pendingOrgInvitesProvider.notifier)
                                          .acceptInvite(invite.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l.inviteAccepted)),
                                        );
                                        context.push('/organizations/$orgId');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                    )),
                    const Divider(height: 24),
                  ],
                );
              },
            ),
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
                  children: orgs.map((org) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OrgCard(
                      organization: org,
                      onTap: () => context.push('/organizations/${org.id}'),
                    ),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.create),
                    onPressed: () => context.push('/organizations/new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.group_add, size: 18),
                    label: Text(l.join),
                    onPressed: () => _showJoinDialog(context, ref, l),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref, AppLocalizations l) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.joinOrganization),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.enterInviteCode),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: l.inviteCode,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              try {
                final token = ref.read(authProvider).accessToken;
                if (token == null) return;
                final ds = ref.read(orgRemoteDataSourceProvider);
                await ds.joinOrganization(code, token);
                ref.invalidate(organizationListProvider);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.joinSuccess)),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
            child: Text(l.join),
          ),
        ],
      ),
    );
  }
}
