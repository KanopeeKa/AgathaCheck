import 'package:image_picker/image_picker.dart';

import '../../data/datasources/health_remote_datasource.dart';
import '../providers/health_providers.dart';
import 'health_entry_form_constants.dart';
import 'health_entry_form_controller_base.dart';
import 'health_entry_form_outcomes.dart';
import 'health_entry_form_state.dart';

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
        final ds = formRef.read(healthDataSourceProvider);
        await ds.uploadPhoto(entryId!, bytes, picked.name);
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
    final ds = formRef.read(healthDataSourceProvider);
    final photos = await ds.getPhotos(entryId!);
    state = state.copyWith(photos: photos);
  }

  Future<void> deletePhoto(EventPhoto photo) async {
    if (entryId == null) return;
    final ds = formRef.read(healthDataSourceProvider);
    await ds.deletePhoto(entryId!, photo.id);
    await loadPhotos();
  }

  Future<void> uploadPendingPhotosToEntry(
    String entryId,
    List<XFile> files,
  ) async {
    if (files.isEmpty) return;
    final ds = formRef.read(healthDataSourceProvider);
    for (final file in files) {
      final bytes = await file.readAsBytes();
      await ds.uploadPhoto(entryId, bytes, file.name);
    }
  }

  void clearPendingPhotos() => state = state.copyWith(pendingPhotos: const []);
}
