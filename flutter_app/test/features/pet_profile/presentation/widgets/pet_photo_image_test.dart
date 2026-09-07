import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_photo_image.dart';

void main() {
  group('buildPetPhotoImage', () {
    test('returns network image for server upload paths', () {
      final widget = buildPetPhotoImage(
        photoPath: '/uploads/pet_photos/buddy.jpg',
        apiBaseUrl: '/backend',
        fit: BoxFit.cover,
      );

      expect(widget, isA<Image>());
      final image = widget! as Image;
      expect(image.image, isA<NetworkImage>());
      expect(
        (image.image as NetworkImage).url,
        '/backend/api/uploads/pet_photos/buddy.jpg',
      );
    });

    test('returns memory image for inline base64 paths', () {
      final widget = buildPetPhotoImage(
        photoPath: 'aGVsbG8=',
        apiBaseUrl: '/backend',
        fit: BoxFit.cover,
      );

      expect(widget, isA<Image>());
      expect((widget! as Image).image, isA<MemoryImage>());
    });

    test('returns null for empty photo path', () {
      expect(
        buildPetPhotoImage(
          photoPath: '',
          apiBaseUrl: '/backend',
          fit: BoxFit.cover,
        ),
        isNull,
      );
    });
  });
}
