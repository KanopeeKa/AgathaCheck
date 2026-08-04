import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_request.dart';
import '../../providers/foster_requests_providers.dart';
import '../../widgets/org_shell_app_bar_title.dart';
import '../../widgets/org_shell_scaffold.dart';

class FosterRequestsScreen extends ConsumerWidget {
  const FosterRequestsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final requestsAsync = ref.watch(orgFosterRequestsProvider(orgId));

    return OrgShellScaffold(
      title: l.fosterRequestsTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('foster_requests_back'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('foster_requests_send_fab'),
        onPressed: () => context.push('/o/orgs/$orgId/foster-requests/new'),
        icon: const Icon(Icons.send),
        label: Text(l.fosterRequestSendNew),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              l.fosterRequestsDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.fosterRequestsEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  key: const Key('foster_requests_list'),
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _FosterRequestListTile(
                      request: request,
                      onTap: () => context.push(
                        '/o/orgs/$orgId/foster-requests/${request.id}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FosterRequestListTile extends StatelessWidget {
  const _FosterRequestListTile({required this.request, required this.onTap});

  final FosterRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final petLabel = request.pets.isNotEmpty
        ? request.pets
              .map((p) => p.petName)
              .where((n) => n.isNotEmpty)
              .join(', ')
        : request.petIds.join(', ');
    final summary = request.responseSummary;

    return Card(
      key: Key('foster_request_tile_${request.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      localizedFosterRequestStatus(l, request.status),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (petLabel.isNotEmpty)
                Text(
                  l.fosterRequestPetsLabel(petLabel),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                l.fosterRequestTargetsSummary(
                  request.targetCount,
                  summary.canHelp,
                  summary.cannotHelp,
                  summary.pending,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String localizedFosterRequestStatus(
  AppLocalizations l,
  FosterRequestStatus status,
) {
  switch (status) {
    case FosterRequestStatus.draft:
      return l.fosterRequestStatusDraft;
    case FosterRequestStatus.sent:
      return l.fosterRequestStatusSent;
    case FosterRequestStatus.cancelled:
      return l.fosterRequestStatusCancelled;
  }
}

String localizedFosterResponseType(
  AppLocalizations l,
  FosterResponseType response,
) {
  switch (response) {
    case FosterResponseType.canHelp:
      return l.fosterRequestResponseCanHelp;
    case FosterResponseType.cannotHelp:
      return l.fosterRequestResponseCannotHelp;
    case FosterResponseType.pending:
      return l.fosterRequestResponsePending;
  }
}
