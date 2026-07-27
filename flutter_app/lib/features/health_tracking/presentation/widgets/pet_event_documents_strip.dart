import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/health_remote_datasource.dart';
import 'pet_event_view_providers.dart';

/// Read-only horizontal documents strip for a health entry (view screen).
class PetEventDocumentsStrip extends ConsumerWidget {
  const PetEventDocumentsStrip({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final photosAsync = ref.watch(healthEntryPhotosProvider(entryId));
    final baseUrl = ref.watch(apiBaseUrlProvider);

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
        photosAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            l.failedToLoadPhotos('$e'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return Text(
                l.upTo4Photos,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _DocumentTile(
                  photo: photos[index],
                  baseUrl: baseUrl,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.photo, required this.baseUrl});

  final EventPhoto photo;
  final String baseUrl;

  bool _isPdf(String path) =>
      path.toLowerCase().split('?').first.endsWith('.pdf');

  String _documentUrl(String path) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath';
  }

  Future<void> _open(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final url = _documentUrl(photo.photoPath);
    if (_isPdf(photo.photoPath)) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (!context.mounted) return;
    showDialog<void>(
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPdf = _isPdf(photo.photoPath);
    final url = _documentUrl(photo.photoPath);
    final filename = photo.photoPath.split('/').last;

    return SizedBox(
      width: 96,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: isPdf
              ? Column(
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
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image,
                    color: colorScheme.outline,
                  ),
                ),
        ),
      ),
    );
  }
}
