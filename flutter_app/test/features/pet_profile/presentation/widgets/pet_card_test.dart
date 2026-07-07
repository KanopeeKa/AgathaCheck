import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
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

  test('Pet constructor accepts empty strings for required fields', () {
    expect(() => const Pet(id: 'id', name: '', species: ''), returnsNormally);
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('PetCard', () {
    testWidgets('displays pet name and breed', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.text('Buddy'), findsOneWidget);
      expect(find.text('Dog - Golden Retriever'), findsOneWidget);
    });

    // Skipped: Pet entity does not have direct age property, age is computed from dateOfBirth

    testWidgets('displays species only when no breed', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: petNoBio)));

      expect(find.text('Cat'), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no photo', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('displays organization name for org pets', (tester) async {
      const orgPet = Pet(
        id: 'org-pet-id',
        name: 'Max',
        species: 'Dog',
        breed: 'Labrador',
        organizationId: 'org-1',
        organizationName: 'Happy Paws Shelter',
      );

      await tester.pumpWidget(createTestWidget(PetCard(pet: orgPet)));

      expect(find.text('Happy Paws Shelter'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsOneWidget);
    });

    testWidgets('displays foster placement status for org pets', (
      tester,
    ) async {
      const orgPet = Pet(
        id: 'org-pet-id',
        name: 'Max',
        species: 'Dog',
        breed: 'Labrador',
        organizationId: 'org-1',
        organizationName: 'Happy Paws Shelter',
        fosterPlacementStatus: 'in_progress',
        fosterName: 'Jane Foster',
      );

      await tester.pumpWidget(createTestWidget(PetCard(pet: orgPet)));

      expect(find.textContaining('In foster care'), findsOneWidget);
      expect(find.textContaining('Jane Foster'), findsOneWidget);
      expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);
    });

    testWidgets('does not display foster placement for personal pets', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.byIcon(Icons.home_work_outlined), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: testPet, onTap: () => tapped = true)),
      );

      await tester.tap(find.byType(PetCard));
      expect(tapped, isTrue);
    });

    // Skipped: PetCard does not have onDelete parameter in implementation
  });
}
