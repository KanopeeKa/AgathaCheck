import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import 'support_screenshot_content_type.dart';
import 'support_screenshot_limits.dart';
import 'support_screenshot_upload.dart';

class SupportScreenshotSection extends StatelessWidget {
  const SupportScreenshotSection({
    super.key,
    required this.screenshots,
    required this.onChanged,
    required this.disabled,
  });

  final List<SupportScreenshotUpload> screenshots;
  final ValueChanged<List<SupportScreenshotUpload>> onChanged;
  final bool disabled;

  int get _totalBytes =>
      screenshots.fold<int>(0, (sum, file) => sum + file.bytes.length);

  Future<void> _pickScreenshot(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    if (screenshots.length >= supportScreenshotMaxCount) {
      _showSnack(context, l.supportScreenshotErrorTooMany);
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !context.mounted) return;

    final name = picked.name;
    if (!isAllowedSupportScreenshotFilename(name)) {
      if (context.mounted) {
        _showSnack(context, l.supportScreenshotErrorType);
      }
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    if (bytes.length > supportScreenshotMaxBytesPerFile) {
      _showSnack(context, l.supportScreenshotErrorFileTooLarge);
      return;
    }
    if (_totalBytes + bytes.length > supportScreenshotMaxBytesTotal) {
      _showSnack(context, l.supportScreenshotErrorTotalTooLarge);
      return;
    }

    final filename = _defaultFilename(name);
    final updated = List<SupportScreenshotUpload>.from(screenshots)
      ..add(SupportScreenshotUpload(filename: filename, bytes: bytes));
    onChanged(updated);
  }

  String _defaultFilename(String original) {
    final lower = original.toLowerCase();
    for (final ext in supportScreenshotAllowedExtensions) {
      if (lower.endsWith(ext)) {
        return 'screenshot$ext';
      }
    }
    return 'screenshot.jpg';
  }

  void _removeAt(int index) {
    final updated = List<SupportScreenshotUpload>.from(screenshots)
      ..removeAt(index);
    onChanged(updated);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.supportScreenshotSectionTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: l.supportScreenshotPiiNotice,
          child: Text(
            l.supportScreenshotPiiNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('support_screenshot_add'),
          onPressed: disabled ? null : () => _pickScreenshot(context),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(l.supportScreenshotAddButton),
        ),
        if (screenshots.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(screenshots.length, (index) {
            final file = screenshots[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                key: Key('support_screenshot_item_$index'),
                contentPadding: EdgeInsets.zero,
                leading: _ScreenshotThumb(bytes: file.bytes),
                title: Text(file.filename),
                subtitle: Text(l.supportStaffAttachmentBytes(file.bytes.length)),
                trailing: IconButton(
                  key: Key('support_screenshot_remove_$index'),
                  tooltip: l.supportScreenshotRemoveButton,
                  onPressed: disabled ? null : () => _removeAt(index),
                  icon: const Icon(Icons.close),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ScreenshotThumb extends StatelessWidget {
  const _ScreenshotThumb({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.memory(
        bytes,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}
