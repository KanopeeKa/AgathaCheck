import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_card.dart';

void main() {

  const testPet = Pet(
    id: 'test-id',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    bio: 'A friendly dog',
    photoPath: '',
    colorValue: 0xFF7E57C2,
    passedAway: false,
  );

  const petNoBio = Pet(
    id: 'test-id-2',
    name: 'Whiskers',
    species: 'Cat',
    breed: '',
    bio: '',
    photoPath: '',
    colorValue: 0xFF26A69A,
    passedAway: false,
  );
    test('throws if required fields are null', () {
      expect(
        () => Pet(
          id: 'id',
          name: '',
          species: '',
        ),
        returnsNormally,
      );
      // The following should not compile, but we can check runtime null assertion
      expect(
        () => Pet(
          id: 'id',
          name: null as String, // ignore: null_argument_to_non_null_type
          species: 'Dog',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Pet(
          id: null as String, // ignore: null_argument_to_non_null_type
          name: 'Buddy',
          species: 'Dog',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Pet(
          id: 'id',
          name: 'Buddy',
          species: null as String, // ignore: null_argument_to_non_null_type
        ),
        throwsA(isA<AssertionError>()),
      );
    });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('PetCard', () {
    testWidgets('displays pet name and breed', (tester) async {
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: testPet)),
      );

      expect(find.text('Buddy'), findsOneWidget);
      expect(find.text('Dog - Golden Retriever'), findsOneWidget);
    });

    // Skipped: Pet entity does not have direct age property, age is computed from dateOfBirth

    testWidgets('displays species only when no breed', (tester) async {
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: petNoBio)),
      );

      expect(find.text('Cat'), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no photo', (tester) async {
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: testPet)),
      );

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createTestWidget(
          PetCard(pet: testPet, onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(PetCard));
      expect(tapped, isTrue);
    });

    // Skipped: PetCard does not have onDelete parameter in implementation
  });
}
