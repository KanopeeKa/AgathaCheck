import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../data/datasources/health_remote_datasource.dart';
import '../../controllers/health_entry_form_constants.dart';
import '../../providers/health_providers.dart';
import '../../utils/health_document_picker.dart';

/// Photo/document pick, upload, and delete for [OtherEventFormScreen].
class OtherEventPhotoHandler {
  OtherEventPhotoHandler({
    required this.ref,
    required this.context,
    required this.entryId,
    required this.isEdit,
    required this.isMounted,
    required this.getPhotos,
    required this.getPendingPhotos,
    required this.setPhotos,
    required this.setPendingPhotos,
    required this.setUploading,
  });

  final WidgetRef ref;
  final BuildContext context;
  final String? entryId;
  final bool isEdit;
  final bool Function() isMounted;
  final List<EventPhoto> Function() getPhotos;
  final List<XFile> Function() getPendingPhotos;
  final void Function(List<EventPhoto>) setPhotos;
  final void Function(List<XFile>) setPendingPhotos;
  final void Function(bool) setUploading;

  Future<void> loadPhotos() async {
    if (entryId == null) return;
    try {
      final ds = ref.read(healthDataSourceProvider);
      final photos = await ds.getPhotos(entryId!);
      if (isMounted()) setPhotos(photos);
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToLoadPhotos('$e'),
            ),
          ),
        );
      }
    }
  }

  String? documentValidationError(String filename, int byteLength) {
    final l = AppLocalizations.of(context)!;
    final extension = filename.split('.').last.toLowerCase();
    if (!healthDocumentAllowedExtensions.contains(extension)) {
      return l.unsupportedDocumentFormat;
    }
    if (byteLength > healthDocumentMaxBytes) {
      return l.documentTooLarge;
    }
    return null;
  }

  Future<void> addPickedDocument(XFile picked, {int? byteLength}) async {
    final length = byteLength ?? await picked.length();
    if (!isMounted()) return;
    final validationError = documentValidationError(picked.name, length);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    if (isEdit) {
      setUploading(true);
      final bytes = await picked.readAsBytes();
      final ds = ref.read(healthDataSourceProvider);
      await ds.uploadPhoto(entryId!, bytes, picked.name);
      await loadPhotos();
      if (isMounted()) setUploading(false);
    } else {
      setPendingPhotos([...getPendingPhotos(), picked]);
    }
  }

  Future<void> pickDocument() async {
    if (getPhotos().length + getPendingPhotos().length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxPhotosReached)),
      );
      return;
    }

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
        setUploading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e')),
          ),
        );
      }
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) await addPickedDocument(picked);
  }

  Future<void> uploadPendingPhotos(String newEntryId) async {
    final ds = ref.read(healthDataSourceProvider);
    for (final file in getPendingPhotos()) {
      final bytes = await file.readAsBytes();
      await ds.uploadPhoto(newEntryId, bytes, file.name);
    }
  }

  Future<void> deletePhoto(EventPhoto photo) async {
    try {
      final ds = ref.read(healthDataSourceProvider);
      await ds.deletePhoto(entryId!, photo.id);
      await loadPhotos();
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

  void removePendingPhoto(int index) {
    final pending = List<XFile>.from(getPendingPhotos())..removeAt(index);
    setPendingPhotos(pending);
  }
}
