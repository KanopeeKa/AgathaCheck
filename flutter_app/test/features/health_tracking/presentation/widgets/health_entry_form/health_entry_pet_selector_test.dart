import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/health_entry_pet_selector.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('HealthEntryPetSelector', () {
    final pets = [
      Pet(
        id: 'p1',
        name: 'Buddy',
        species: 'dog',
        breed: 'Lab',
      ),
      Pet(
        id: 'p2',
        name: 'Mittens',
        species: 'cat',
        breed: '',
      ),
    ];

    testWidgets('renders pet chips and toggles selection', (tester) async {
      var selected = <String>{'p1'};
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HealthEntryPetSelector(
              pets: pets,
              selectedPetIds: selected,
              isEdit: false,
              onChanged: (next) => selected = next,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget);
      expect(find.text('Mittens'), findsOneWidget);

      await tester.tap(find.text('Mittens'));
      await tester.pump();
      expect(selected, containsAll(['p1', 'p2']));
    });

    testWidgets('edit mode shows read-only pet name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HealthEntryPetSelector(
              pets: pets,
              selectedPetIds: const {'p1'},
              isEdit: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });
  });
}
