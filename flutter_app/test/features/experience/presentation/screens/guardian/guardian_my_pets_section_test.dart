import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_my_pets_section.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_dashboard_pet_card.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_shell_shared_pet_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildSection({
    required List<Pet> pets,
    List<Pet>? previewPets,
    int? previewOverflowCount,
    GuardianTodayCareSummary? careSummary,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GuardianMyPetsSection(
              allPets: pets,
              controller: PetListController(),
              previewPets: previewPets,
              previewOverflowCount: previewOverflowCount,
              careSummary: careSummary,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('baseline: merged section uses wrap grid for personal pets', (
    tester,
  ) async {
    final pets = [
      const Pet(id: 'p1', name: 'Buddy', species: 'Dog', breed: 'Mix'),
      const Pet(id: 'p2', name: 'Whiskers', species: 'Cat', breed: ''),
    ];

    await tester.pumpWidget(buildSection(pets: pets));
    await tester.pumpAndSettle();

    expect(find.text('My Pets'), findsOneWidget);
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Whiskers'), findsOneWidget);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('baseline: shows foster subgroup when foster pets exist', (
    tester,
  ) async {
    final pets = [
      const Pet(id: 'p1', name: 'Buddy', species: 'Dog', breed: 'Mix'),
      const Pet(
        id: 'p2',
        name: 'Luna',
        species: 'Cat',
        breed: '',
        isFoster: true,
      ),
    ];

    await tester.pumpWidget(buildSection(pets: pets));
    await tester.pumpAndSettle();

    expect(find.text('My Fostered Pets'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.byType(Wrap), findsNWidgets(2));
  });

  testWidgets('baseline: shows empty state when no pets', (tester) async {
    await tester.pumpWidget(buildSection(pets: []));
    await tester.pumpAndSettle();

    expect(find.text('Who are we caring for?'), findsOneWidget);
    expect(find.text('My Fostered Pets'), findsNothing);
    expect(find.text('Shared Pets'), findsNothing);
  });

  testWidgets('baseline: shows shared subgroup when shared pets exist', (
    tester,
  ) async {
    final pets = [
      const Pet(
        id: 'p1',
        name: 'Max',
        species: 'Dog',
        breed: '',
        isShared: true,
      ),
    ];

    await tester.pumpWidget(buildSection(pets: pets));
    await tester.pumpAndSettle();

    expect(find.text('Shared Pets'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Who are we caring for?'), findsNothing);
  });

  testWidgets('compact preview handles zero, one, and exactly four pets', (
    tester,
  ) async {
    for (final count in [0, 1, 4]) {
      final pets = List.generate(
        count,
        (index) => Pet(id: 'pet-$index', name: 'Pet $index', species: 'Dog'),
      );
      await tester.pumpWidget(
        buildSection(pets: pets, previewPets: pets, previewOverflowCount: 0),
      );

      expect(find.byType(GuardianDashboardPetCard), findsNWidgets(count));
      expect(find.text('All Pets'), findsNothing);
      expect(find.text('Add Pet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('compact preview caps at four and exposes All Pets on overflow', (
    tester,
  ) async {
    final allPets = List.generate(
      5,
      (index) => Pet(id: 'pet-$index', name: 'Pet $index', species: 'Dog'),
    );

    await tester.pumpWidget(
      buildSection(
        pets: allPets,
        previewPets: allPets.take(4).toList(),
        previewOverflowCount: 1,
      ),
    );

    expect(find.byType(GuardianDashboardPetCard), findsNWidgets(4));
    expect(find.text('Pet 4'), findsNothing);
    expect(find.text('All Pets'), findsOneWidget);
  });

  testWidgets('compact preview remains a horizontal rail at phone widths', (
    tester,
  ) async {
    final pets = List.generate(
      4,
      (index) => Pet(id: 'pet-$index', name: 'Pet $index', species: 'Dog'),
    );

    for (final width in [320.0, 375.0, 414.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        buildSection(pets: pets, previewPets: pets, previewOverflowCount: 0),
      );

      final cards = find.byType(GuardianDashboardPetCard);
      expect(
        tester.getTopLeft(cards.at(1)).dx,
        greaterThan(tester.getTopLeft(cards.at(0)).dx),
      );
      expect(tester.getSize(cards.first).width, lessThanOrEqualTo(168));
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('shared compact cards retain their hide wrapper', (tester) async {
    const shared = Pet(
      id: 'shared-1',
      name: 'Shared pet',
      species: 'Cat',
      isShared: true,
    );
    await tester.pumpWidget(
      buildSection(
        pets: const [shared],
        previewPets: const [shared],
        previewOverflowCount: 0,
      ),
    );

    expect(find.byType(GuardianShellSharedPetCard), findsOneWidget);
    expect(find.byKey(const Key('hide_shell_shared_shared-1')), findsOneWidget);
  });
}
