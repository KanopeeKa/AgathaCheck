import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_card.dart';

class OrganizationListScreen extends ConsumerWidget {
  const OrganizationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myOrganizations),
        leading: IconButton(
          key: const Key('org_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/'),
        ),
      ),
      body: orgsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    l.orgCreateFirst,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(organizationListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orgs.length,
              itemBuilder: (context, index) {
                final org = orgs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OrgCard(
                    organization: org,
                    onTap: () => context.push('/organizations/${org.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('org_create_fab'),
        onPressed: () => context.push('/organizations/new'),
        tooltip: l.createOrganization,
        icon: const Icon(Icons.add),
        label: Text(l.createOrganization),
      ),
    );
  }
}
