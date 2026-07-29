import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_my_pets_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildSection({required List<Pet> pets}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: GuardianMyPetsSection(
            allPets: pets,
            controller: PetListController(),
          ),
        ),
      ),
    );
  }

  testWidgets('merged section uses wrap grid for personal pets', (
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

  testWidgets('shows foster subgroup when foster pets exist', (tester) async {
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

  testWidgets('shows empty state when no pets', (tester) async {
    await tester.pumpWidget(buildSection(pets: []));
    await tester.pumpAndSettle();

    expect(find.text('No pets yet'), findsOneWidget);
    expect(find.text('My Fostered Pets'), findsNothing);
  });
}
