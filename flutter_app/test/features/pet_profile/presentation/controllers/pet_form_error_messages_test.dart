import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_remote_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_form_error_messages.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_form_outcomes.dart';

void main() {
  group('petFormSubmitErrorKindFrom', () {
    test('maps 413 to photoTooLarge', () {
      expect(
        petFormSubmitErrorKindFrom(
          PetRemoteException('Image must be 2 MB or smaller', statusCode: 413),
        ),
        PetFormSubmitErrorKind.photoTooLarge,
      );
    });

    test('maps unsupported image message to photoUnsupportedType', () {
      expect(
        petFormSubmitErrorKindFrom(
          PetRemoteException('Only JPG, PNG, and WebP images are allowed'),
        ),
        PetFormSubmitErrorKind.photoUnsupportedType,
      );
    });

    test('maps generic exceptions to networkError', () {
      expect(
        petFormSubmitErrorKindFrom(Exception('socket')),
        PetFormSubmitErrorKind.networkError,
      );
    });
  });
}
