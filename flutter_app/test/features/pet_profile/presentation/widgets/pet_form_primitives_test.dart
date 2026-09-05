import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/pet_gender_section.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/pet_species_section.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_form/pet_form_neutered_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('PetSpeciesSection', () {
    testWidgets('selects Dog chip when prefill is lowercase dog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(PetSpeciesSection(selectedSpecies: 'dog', onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pet_species_chip_Dog')), findsOneWidget);
      expect(find.text('Dog'), findsWidgets);
    });

    testWidgets('opens more species sheet and returns selection', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _wrap(
          PetSpeciesSection(
            selectedSpecies: '',
            onChanged: (value) => picked = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pet_species_more_chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pet_species_more_Fish')));
      await tester.pumpAndSettle();

      expect(picked, 'Fish');
    });
  });

  group('PetGenderSection', () {
    testWidgets('selects Male segment when prefill is lowercase male', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(PetGenderSection(selectedGender: 'male', onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<PetSexSelection>>(
        find.byKey(const Key('pet_gender_field')),
      );
      expect(segmented.selected, {PetSexSelection.male});
    });
  });

  group('PetFormNeuteredSection', () {
    testWidgets('shows not applicable for Fish', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PetFormNeuteredSection(
            species: 'Fish',
            isNeutered: null,
            neuteredDate: null,
            onNeuteredChanged: (_) {},
            onPickNeuteredDate: () {},
            onClearNeuteredDate: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('pet_neuter_not_applicable')),
        findsOneWidget,
      );
      expect(find.text('Not applicable'), findsOneWidget);
      expect(find.byType(SegmentedButton<PetNeuterSelection>), findsNothing);
    });
  });
}
