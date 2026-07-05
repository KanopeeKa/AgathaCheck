import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../data/datasources/health_remote_datasource.dart';

class HealthEntryPhotosSection extends StatelessWidget {
  const HealthEntryPhotosSection({
    required this.photos,
    required this.pendingPhotos,
    required this.isUploading,
    required this.baseUrl,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onDelete,
    required this.onRemovePending,
  });

  final List<EventPhoto> photos;
  final List<XFile> pendingPhotos;
  final bool isUploading;
  final String baseUrl;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<EventPhoto> onDelete;
  final ValueChanged<int> onRemovePending;

  int get _totalCount => photos.length + pendingPhotos.length;

  bool _isPdfDocument(String filename) =>
      filename.toLowerCase().split('?').first.endsWith('.pdf');

  String _displayName(String path) => path.split('/').last;

  String _documentUrl(String path) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath';
  }

  Widget _documentPlaceholder(
      BuildContext context, String filename, ColorScheme colorScheme) {
    final isPdf = _isPdfDocument(filename);
    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isPdf ? Icons.picture_as_pdf : Icons.description,
              color: colorScheme.primary, size: 36),
          const SizedBox(height: 6),
          Text(
            _displayName(filename),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final l = AppLocalizations.of(context)!;

    Widget addPhotoButton() {
      return PopupMenuButton<String>(
        tooltip: l.addPhoto,
        onSelected: (value) {
          if (value == 'camera') {
            onPickCamera();
          } else {
            onPickGallery();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
              value: 'camera',
              child: ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l.cameraOption),
                contentPadding: EdgeInsets.zero,
              )),
          PopupMenuItem(
              value: 'gallery',
              child: ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l.galleryFilesOption),
                contentPadding: EdgeInsets.zero,
              )),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(l.addPhoto,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: colorScheme.primary)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(l.photos,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        if (isUploading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (_totalCount > 0)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _totalCount,
                  itemBuilder: (context, index) {
                    if (index < photos.length) {
                      return _buildSavedPhoto(context, photos[index], colorScheme);
                    }
                    final pendingIndex = index - photos.length;
                    return _buildPendingPhoto(
                        context, pendingPhotos[pendingIndex], pendingIndex, colorScheme);
                  },
                ),
              if (_totalCount > 0) const SizedBox(height: 12),
              if (_totalCount < 4 && !isUploading) addPhotoButton(),
              const SizedBox(height: 8),
              Text(
                _totalCount > 0
                    ? '${l.photoCountLabel(_totalCount)}${pendingPhotos.isNotEmpty ? l.pendingUploadSuffix(pendingPhotos.length) : ''}'
                    : l.upTo4Photos,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPhoto(
      BuildContext context, EventPhoto photo, ColorScheme colorScheme) {
    final imageUrl = _documentUrl(photo.photoPath);
    final isPdf = _isPdfDocument(photo.photoPath);
    return GestureDetector(
      onTap: isPdf ? null : () => _showFullScreen(context, imageUrl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isPdf
                ? _documentPlaceholder(context, photo.photoPath, colorScheme)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child:
                          Icon(Icons.broken_image, color: colorScheme.outline),
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Semantics(
              label: AppLocalizations.of(context)!.removePhoto,
              button: true,
              child: GestureDetector(
                onTap: () => onDelete(photo),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPhoto(BuildContext context, XFile file, int pendingIndex,
      ColorScheme colorScheme) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        final isPdf = _isPdfDocument(file.name);
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isPdf
                  ? _documentPlaceholder(context, file.name, colorScheme)
                  : snapshot.hasData
                  ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.pendingLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                label: AppLocalizations.of(context)!.removePhoto,
                button: true,
                child: GestureDetector(
                  onTap: () => onRemovePending(pendingIndex),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: AppLocalizations.of(context)!.close,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

