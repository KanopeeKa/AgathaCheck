import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_fostering_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildSection(List<Pet> pets) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: GuardianFosteringSection(pets: pets)),
    );
  }

  testWidgets('only shows Guardian-visible foster relationship details', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection([
        const Pet(
          id: 'foster-1',
          name: 'Miso',
          species: 'Cat',
          isFoster: true,
          organizationName: 'Harbour Shelter',
          fosterPlacementStatus: 'active',
        ),
        const Pet(id: 'owned-1', name: 'Biscuit', species: 'Dog'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Miso'), findsOneWidget);
    expect(find.text('Harbour Shelter'), findsNWidgets(2));
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Biscuit'), findsNothing);
  });

  testWidgets(
    'uses a truthful empty state when no foster relationship exists',
    (tester) async {
      await tester.pumpWidget(
        buildSection(const [
          Pet(id: 'owned-1', name: 'Biscuit', species: 'Dog'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('No fostering sessions right now'), findsOneWidget);
      expect(
        find.byKey(const Key('guardian_dashboard_empty_fostering_action')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('guardian_dashboard_empty_shelters_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('guardian_dashboard_empty_fostering')),
        findsOneWidget,
      );
      expect(
        find.byType(Image),
        findsOneWidget,
        reason: 'the fostering illustration belongs to shelter connection',
      );
    },
  );
}
