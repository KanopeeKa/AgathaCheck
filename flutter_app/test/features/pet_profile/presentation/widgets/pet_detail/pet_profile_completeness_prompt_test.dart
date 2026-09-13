import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_profile_completeness_prompt.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('collapses neuter and chip prompts into one card', (
    tester,
  ) async {
    const pet = Pet(id: 'pet-1', name: 'Bella', species: 'Dog');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PetProfileCompletenessPrompt(pet: pet)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_profile_completeness_prompt')),
      findsOneWidget,
    );
    expect(find.text('Neutering status not recorded'), findsOneWidget);
    expect(find.text('Microchip details not added'), findsOneWidget);
  });

  testWidgets('hides when both prompts are dismissed or filled', (
    tester,
  ) async {
    final pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      chipId: 'FR-123',
      neuteredDate: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PetProfileCompletenessPrompt(pet: pet)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_profile_completeness_prompt')),
      findsNothing,
    );
  });
}
