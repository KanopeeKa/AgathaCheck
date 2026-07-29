import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/theme/experience_colors.dart';
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
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 180, child: child)),
      ),
    );
  }

  group('PetCard', () {
    testWidgets('displays pet name and breed', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.text('Buddy'), findsOneWidget);
      expect(find.textContaining('Golden Retriever'), findsOneWidget);
    });

    testWidgets('displays species only when no breed', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: petNoBio)));

      expect(find.text('Cat'), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no photo', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('org pets include organization in semantics label', (
      tester,
    ) async {
      const orgPet = Pet(
        id: 'org-pet-id',
        name: 'Max',
        species: 'Dog',
        breed: 'Labrador',
        organizationId: 'org-1',
        organizationName: 'Happy Paws Shelter',
      );

      await tester.pumpWidget(createTestWidget(PetCard(pet: orgPet)));

      expect(find.text('Max'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pet: Max, Happy Paws Shelter, Dog'),
        findsOneWidget,
      );
    });

    testWidgets('foster placement line uses org green accent', (tester) async {
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
      await tester.pumpAndSettle();

      final fosterText = tester.widget<Text>(
        find.textContaining('In foster care'),
      );
      final orgGreen = AppTheme.lightTheme
          .extension<ExperienceColors>()!
          .organizationPrimary;
      expect(fosterText.style?.color, orgGreen);
    });

    testWidgets('isFoster pet shows green foster label', (tester) async {
      const fosterPet = Pet(
        id: 'foster-id',
        name: 'Luna',
        species: 'Cat',
        breed: '',
        isFoster: true,
      );

      await tester.pumpWidget(createTestWidget(PetCard(pet: fosterPet)));
      await tester.pumpAndSettle();

      expect(find.text('In foster care'), findsOneWidget);
    });

    testWidgets('does not display foster placement for personal pets', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.byIcon(Icons.home_work_outlined), findsNothing);
    });

    testWidgets('shows ownership status bar', (tester) async {
      await tester.pumpWidget(createTestWidget(PetCard(pet: testPet)));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createTestWidget(PetCard(pet: testPet, onTap: () => tapped = true)),
      );

      await tester.tap(find.byType(PetCard));
      expect(tapped, isTrue);
    });

    testWidgets('PetTileStrip lays out square vertical tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: PetTileStrip(
                useWrap: true,
                pets: const [testPet],
                onPetTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final tile = tester.getSize(find.byType(PetCard));
      expect(tile.width, tile.height);
      expect(tile.width, closeTo((400 - 2 * PetCard.tileSpacing) / 3, 0.01));
    });
  });
}
