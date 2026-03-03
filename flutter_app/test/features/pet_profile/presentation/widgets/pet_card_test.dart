import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_card.dart';

void main() {
  final testPet = Pet(
    id: 'test-id',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2022, 1, 15),
    weight: 30.0,
    bio: 'A friendly dog',
  );

  const petNoBio = Pet(
    id: 'test-id-2',
    name: 'Whiskers',
    species: 'Cat',
  );

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

    testWidgets('displays age when dateOfBirth available', (tester) async {
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: testPet)),
      );

      expect(find.textContaining('yrs old'), findsOneWidget);
    });

    testWidgets('does not display age when no dateOfBirth', (tester) async {
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: petNoBio)),
      );

      expect(find.textContaining('old'), findsNothing);
    });

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

  });
}
