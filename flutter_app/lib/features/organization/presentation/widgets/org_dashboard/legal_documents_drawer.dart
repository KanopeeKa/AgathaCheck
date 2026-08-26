import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/org_legal_document.dart';
import '../../providers/org_legal_documents_provider.dart';
import '../../providers/org_provider_deps.dart';
import '../../utils/org_legal_document_download.dart';

/// Read-only Legal & Documents slide-over (Phase 3.7).
class LegalDocumentsDrawer extends ConsumerWidget {
  const LegalDocumentsDrawer({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final documentsAsync = ref.watch(orgLegalDocumentsProvider(orgId));

    return Drawer(
      key: const Key('org_legal_documents_drawer'),
      width: MediaQuery.of(context).size.width * 0.88,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.orgLegalDocumentsTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('org_legal_documents_close'),
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l.orgLegalDocumentsIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: documentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: '$e',
                  onRetry: () =>
                      ref.invalidate(orgLegalDocumentsProvider(orgId)),
                ),
                data: (grouped) {
                  if (grouped.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.orgLegalDocumentsEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final entry in grouped.entries) ...[
                        Text(
                          _typeLabel(l, entry.key),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                          (doc) => _DocumentTile(orgId: orgId, document: doc),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(AppLocalizations l, String templateType) {
    switch (templateType) {
      case 'session_checklist':
        return l.orgLegalDocumentsTypeSession;
      case 'adoption_milestone':
        return l.orgLegalDocumentsTypeAdoption;
      default:
        return templateType.replaceAll('_', ' ');
    }
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.orgId, required this.document});

  final String orgId;
  final OrgLegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(document.label),
        subtitle: document.description.isNotEmpty
            ? Text(
                document.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          key: Key('org_legal_download_${document.id}'),
          tooltip: l.orgLegalDocumentsDownload(document.label),
          icon: const Icon(Icons.download_outlined),
          onPressed: () => _download(context, ref),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final token = ref.read(orgTokenProvider);
    if (token == null) return;

    try {
      final remote = ref.read(orgLegalDocumentsRemoteProvider);
      final payload = await remote.downloadDocument(
        orgId: orgId,
        templateId: document.id,
        token: token,
      );
      await downloadOrgLegalDocument(
        filename: payload.filename,
        content: payload.content,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.orgLegalDocumentsDownloaded(document.label)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('org_legal_documents_retry'),
              onPressed: onRetry,
              child: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
