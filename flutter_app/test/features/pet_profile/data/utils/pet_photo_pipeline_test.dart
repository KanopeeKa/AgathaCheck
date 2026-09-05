import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/utils/pet_photo_bytes.dart';
import 'package:pet_profile_app/features/pet_profile/data/utils/pet_profile_normalize.dart';

void main() {
  group('pet_profile_normalize', () {
    test('normalizes species aliases', () {
      expect(normalizePetSpecies('dog'), 'Dog');
      expect(normalizePetSpecies('Cat'), 'Cat');
    });

    test('normalizes gender aliases', () {
      expect(normalizePetGender('male'), 'Male');
      expect(normalizePetGender('female'), 'Female');
    });
  });

  group('pet_photo_bytes', () {
    test('detects pending uploads', () {
      expect(isPendingPetPhotoUpload('/uploads/pet_photos/a.jpg'), isFalse);
      expect(isPendingPetPhotoUpload('aGVsbG8='), isTrue);
      expect(isPendingPetPhotoUpload('data:image/png;base64,abc'), isTrue);
    });

    test('rejects unsupported filenames', () {
      expect(isAllowedPetPhotoFilename('photo.gif'), isFalse);
      expect(isAllowedPetPhotoFilename('photo.jpg'), isTrue);
    });
  });
}
