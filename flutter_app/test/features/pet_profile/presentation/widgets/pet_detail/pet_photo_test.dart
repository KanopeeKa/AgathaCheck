import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_photo.dart';

void main() {
  testWidgets('PetPhoto shows a species placeholder for a living pet with no '
      'photo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 140,
            child: PetPhoto(
              pet: Pet(id: 'p1', name: 'Rex', species: 'Dog'),
            ),
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
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 140,
              child: PetPhoto(
                pet: Pet(
                  id: 'p1',
                  name: 'Rex',
                  species: 'Dog',
                  passedAway: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    },
  );
}
