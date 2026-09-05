import '../../../../../l10n/app_localizations.dart';
import '../../data/datasources/pet_remote_datasource.dart';
import 'pet_form_outcomes.dart';

String petFormSubmitErrorMessage(
  AppLocalizations l,
  PetFormSubmitErrorKind kind,
) {
  return switch (kind) {
    PetFormSubmitErrorKind.photoTooLarge => l.petPhotoTooLarge,
    PetFormSubmitErrorKind.photoUnsupportedType => l.petPhotoUnsupportedType,
    PetFormSubmitErrorKind.photoUploadFailed => l.petPhotoUploadFailed,
    PetFormSubmitErrorKind.networkError => l.petPhotoNetworkError,
    PetFormSubmitErrorKind.unauthorized => l.petPhotoUnauthorized,
    PetFormSubmitErrorKind.saveFailed => l.petSaveFailed,
  };
}

String petFormPickImageErrorMessage(
  AppLocalizations l,
  PetFormPhotoError error,
) {
  return switch (error) {
    PetFormPhotoError.tooLarge => l.petPhotoTooLarge,
    PetFormPhotoError.unsupportedType => l.petPhotoUnsupportedType,
    PetFormPhotoError.pickFailed => l.petPhotoPickFailed,
  };
}

PetFormSubmitErrorKind petFormSubmitErrorKindFrom(Object error) {
  if (error is PetRemoteException) {
    if (error.statusCode == 401) {
      return PetFormSubmitErrorKind.unauthorized;
    }
    if (error.statusCode == 413) {
      return PetFormSubmitErrorKind.photoTooLarge;
    }
    final message = error.message.toLowerCase();
    if (message.contains('jpg') ||
        message.contains('png') ||
        message.contains('webp') ||
        message.contains('image')) {
      return PetFormSubmitErrorKind.photoUnsupportedType;
    }
    if (message.contains('photo')) {
      return PetFormSubmitErrorKind.photoUploadFailed;
    }
    return PetFormSubmitErrorKind.saveFailed;
  }
  return PetFormSubmitErrorKind.networkError;
}
