import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_issue_document.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../pet_profile/presentation/controllers/health_issues_controller.dart';

class HealthIssueDocumentsStrip extends ConsumerWidget {
  const HealthIssueDocumentsStrip({
    super.key,
    required this.petId,
    required this.issueId,
    required this.controller,
  });

  final String petId;
  final String issueId;
  final HealthIssuesController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final docsAsync = ref.watch(healthIssueDocumentsProvider(issueId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l.photos,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        docsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            l.failedToLoadPhotos('$e'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (docs) => SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: docs.length + (docs.length < 4 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index < docs.length) {
                  return _DocumentTile(
                    document: docs[index],
                    controller: controller,
                    onTap: () => _openDocument(context, docs[index]),
                    onDelete: () => controller.deleteDocument(
                      context,
                      petId,
                      issueId,
                      docs[index],
                    ),
                  );
                }
                return _AddDocumentTile(
                  onTap: () => controller.pickAndUploadDocument(
                    context,
                    petId,
                    issueId,
                    currentCount: docs.length,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    HealthIssueDocument document,
  ) async {
    final l = AppLocalizations.of(context)!;
    final url = controller.documentUrl(document.url);
    final isPdf = controller.isPdfDocument(document.url);

    if (isPdf) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: l.close,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.controller,
    required this.onTap,
    required this.onDelete,
  });

  final HealthIssueDocument document;
  final HealthIssuesController controller;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPdf = controller.isPdfDocument(document.url);
    final url = controller.documentUrl(document.url);
    final filename = document.url.split('/').last;

    return SizedBox(
      width: 96,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isPdf)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, color: colorScheme.primary),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        filename,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                )
              else
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image,
                    color: colorScheme.outline,
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: Semantics(
                  label: AppLocalizations.of(context)!.removePhoto,
                  button: true,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDocumentTile extends StatelessWidget {
  const _AddDocumentTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return SizedBox(
      width: 96,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(96, 112),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              l.addPhoto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
