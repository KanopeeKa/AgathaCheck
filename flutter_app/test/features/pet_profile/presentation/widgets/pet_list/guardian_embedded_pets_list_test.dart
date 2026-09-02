import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/guardian_embedded_pets_list.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/pet_list_section_header.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows owned, shared, and fostered sections separately', (
    tester,
  ) async {
    final controller = PetListController();
    final pets = [
      const Pet(id: 'owned', name: 'Owned', species: 'Cat'),
      const Pet(
        id: 'shared',
        name: 'Shared',
        species: 'Dog',
        isShared: true,
        guardianName: 'Alex',
      ),
      const Pet(
        id: 'foster',
        name: 'Foster',
        species: 'Cat',
        isFoster: true,
        organizationName: 'Shelter',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return Scaffold(
              body: GuardianEmbeddedPetsList(
                allPets: pets,
                controller: controller,
                careSummary: null,
                l: l,
                theme: Theme.of(context),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PetListSectionHeader), findsNWidgets(3));
    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('Shared'), findsOneWidget);
    expect(find.text('Foster'), findsOneWidget);
  });
}
