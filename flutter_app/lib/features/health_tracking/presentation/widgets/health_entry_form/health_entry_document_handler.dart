import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../../controllers/health_entry_form_outcomes.dart';
import '../../../data/datasources/health_remote_datasource.dart';
import '../../utils/health_document_picker.dart';

/// Photo/document pick and delete helpers for [HealthEntryFormScreen].
class HealthEntryDocumentHandler {
  HealthEntryDocumentHandler({
    required this.ref,
    required this.context,
    required this.controller,
    required this.entryId,
    required this.isMounted,
  });

  final WidgetRef ref;
  final BuildContext context;
  final HealthEntryFormController controller;
  final String? entryId;
  final bool Function() isMounted;

  String _documentValidationMessage(HealthDocumentValidationError error) {
    final l = AppLocalizations.of(context)!;
    return switch (error) {
      HealthDocumentValidationError.unsupportedFormat =>
        l.unsupportedDocumentFormat,
      HealthDocumentValidationError.tooLarge => l.documentTooLarge,
    };
  }

  Future<void> addPickedDocument(XFile picked, {int? byteLength}) async {
    if (!isMounted()) return;
    if (!controller.canAddPhoto()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxPhotosReached)),
      );
      return;
    }

    try {
      final validationError = await controller.addDocument(
        picked,
        byteLength: byteLength,
      );
      if (!isMounted()) return;
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_documentValidationMessage(validationError))),
        );
      }
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e')),
          ),
        );
      }
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      await addPickedDocument(picked);
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e')),
          ),
        );
      }
    }
  }

  Future<void> pickDocument() async {
    try {
      final file = await pickSingleHealthDocument();
      if (file == null) return;
      if (!isMounted()) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final picked = XFile.fromData(bytes, name: file.name);
      await addPickedDocument(picked, byteLength: bytes.length);
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e')),
          ),
        );
      }
    }
  }

  Future<void> deletePhoto(EventPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePhotoTitle),
        content: Text(AppLocalizations.of(context)!.deletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || entryId == null) return;
    try {
      await controller.deletePhoto(photo);
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToDeletePhoto('$e'),
            ),
          ),
        );
      }
    }
  }
}
