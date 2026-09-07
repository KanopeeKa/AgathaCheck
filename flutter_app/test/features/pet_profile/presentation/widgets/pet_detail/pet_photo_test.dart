import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_photo.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [apiBaseUrlProvider.overrideWith((ref) => '/backend')],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('PetPhoto shows a species placeholder for a living pet with no '
      'photo', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 140,
          child: PetPhoto(
            pet: Pet(id: 'p1', name: 'Rex', species: 'Dog'),
          ),
        ),
      ),
    );

    // No memorial overlay for a living pet.
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets(
    'PetPhoto shows the memorial overlay for a pet that passed away',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 140,
            child: PetPhoto(
              pet: Pet(id: 'p1', name: 'Rex', species: 'Dog', passedAway: true),
            ),
          ),
        ),
      );

      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('PetPhoto loads server upload paths via the API URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 140,
          height: 140,
          child: PetPhoto(
            pet: Pet(
              id: 'p1',
              name: 'Rex',
              species: 'Dog',
              photoPath: '/uploads/pet_photos/rex.jpg',
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect(
      (image.image as NetworkImage).url,
      '/backend/api/uploads/pet_photos/rex.jpg',
    );
  });
}
