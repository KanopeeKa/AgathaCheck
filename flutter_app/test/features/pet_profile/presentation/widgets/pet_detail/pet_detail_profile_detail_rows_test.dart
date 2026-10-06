import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/pet_detail/pet_detail_profile_detail_rows.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('PetDetailProfileDetailRows shows chip id', (tester) async {
    const pet = Pet(id: 'p1', name: 'Rex', species: 'Dog', chipId: 'CHIP-99');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                PetDetailProfileDetailRows(pet: pet, theme: Theme.of(context)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('CHIP-99'), findsOneWidget);
  });
}
