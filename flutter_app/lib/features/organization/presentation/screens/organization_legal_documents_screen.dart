import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/org_legal_documents_provider.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

/// Full-screen Legal & Documents view (deep-link route).
class OrganizationLegalDocumentsScreen extends ConsumerWidget {
  const OrganizationLegalDocumentsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return OrgShellScaffold(
      key: const Key('org_legal_documents_screen'),
      title: l.orgLegalDocumentsTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('org_legal_documents_screen_back'),
      child: LegalDocumentsPanel(orgId: orgId),
    );
  }
}

/// Shared panel body for drawer and route.
class LegalDocumentsPanel extends ConsumerWidget {
  const LegalDocumentsPanel({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(orgLegalDocumentsProvider(orgId));
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$e'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(orgLegalDocumentsProvider(orgId)),
              child: Text(l.retry),
            ),
          ],
        ),
      ),
      data: (grouped) {
        if (grouped.isEmpty) {
          return Center(child: Text(l.orgLegalDocumentsEmpty));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l.orgLegalDocumentsIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final entry in grouped.entries) ...[
              Text(
                entry.key.replaceAll('_', ' '),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...entry.value.map(
                (doc) => ListTile(
                  title: Text(doc.label),
                  subtitle: doc.description.isNotEmpty
                      ? Text(doc.description)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
