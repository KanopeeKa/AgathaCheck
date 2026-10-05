import 'package:image_picker/image_picker.dart';

import '../../domain/entities/health_entry_photo.dart';
import '../../domain/entities/health_document.dart';
import '../providers/health_providers.dart';
import 'health_entry_form_constants.dart';
import 'health_entry_form_controller_base.dart';
import 'health_entry_form_outcomes.dart';

mixin HealthEntryFormPhotoMixin on HealthEntryFormControllerBase {
  HealthDocumentValidationError? validateDocument(
    String filename,
    int byteLength,
  ) {
    final extension = filename.split('.').last.toLowerCase();
    if (!healthDocumentAllowedExtensions.contains(extension)) {
      return HealthDocumentValidationError.unsupportedFormat;
    }
    if (byteLength > healthDocumentMaxBytes) {
      return HealthDocumentValidationError.tooLarge;
    }
    return null;
  }

  bool canAddPhoto() => state.totalPhotoCount < healthEntryMaxPhotos;

  HealthEntryPhoto _toEventPhoto(HealthDocument doc) {
    return HealthEntryPhoto(
      id: doc.id,
      eventId: doc.healthEntryId ?? entryId ?? '',
      photoPath: doc.url,
      caption: doc.caption,
      occurrenceId: doc.occurrenceId,
    );
  }

  Future<HealthDocumentValidationError?> addDocument(
    XFile picked, {
    int? byteLength,
  }) async {
    if (!canAddPhoto()) {
      return null;
    }

    final length = byteLength ?? await picked.length();
    final validationError = validateDocument(picked.name, length);
    if (validationError != null) {
      return validationError;
    }

    if (state.isEdit && entryId != null) {
      state = state.copyWith(isUploadingPhoto: true);
      try {
        final bytes = await picked.readAsBytes();
        final repo = formRef.read(healthDocumentsRepositoryProvider);
        await repo.uploadEntryDocument(entryId!, bytes, picked.name);
        await loadPhotos();
      } finally {
        state = state.copyWith(isUploadingPhoto: false);
      }
    } else {
      state = state.copyWith(pendingPhotos: [...state.pendingPhotos, picked]);
    }
    return null;
  }

  void removePendingPhoto(int index) {
    final updated = List<XFile>.from(state.pendingPhotos)..removeAt(index);
    state = state.copyWith(pendingPhotos: updated);
  }

  Future<void> loadPhotos() async {
    if (entryId == null) return;
    final repo = formRef.read(healthDocumentsRepositoryProvider);
    final photos = await repo.listEntryDocuments(entryId!);
    state = state.copyWith(photos: photos.map(_toEventPhoto).toList());
  }

  Future<void> deletePhoto(HealthEntryPhoto photo) async {
    if (entryId == null) return;
    final repo = formRef.read(healthDocumentsRepositoryProvider);
    await repo.removeEntryDocument(entryId!, photo.id);
    await loadPhotos();
  }

  Future<void> uploadPendingPhotosToEntry(
    String entryId,
    List<XFile> files,
  ) async {
    if (files.isEmpty) return;
    final repo = formRef.read(healthDocumentsRepositoryProvider);
    for (final file in files) {
      final bytes = await file.readAsBytes();
      await repo.uploadEntryDocument(entryId, bytes, file.name);
    }
  }

  void clearPendingPhotos() => state = state.copyWith(pendingPhotos: const []);
}
