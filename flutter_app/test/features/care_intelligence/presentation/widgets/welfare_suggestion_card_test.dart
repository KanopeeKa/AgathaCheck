import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/welfare_suggestion.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/widgets/welfare_suggestion_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('ACJ-WF-08 neuter welfare card has no rhythm accept action', (
    tester,
  ) async {
    const pet = Pet(id: 'p1', name: 'Ada', species: 'Dog');
    const suggestion = WelfareSuggestion(
      id: 'ws-1',
      petId: 'p1',
      subjectKey: 'neuter_welfare',
      dedupeKey: 'welfare:neuter:p1',
      rationaleKey: 'careWelfareNeuterWhy',
      engineVersion: '1.0.0',
      severity: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WelfareSuggestionCard(
              pet: pet,
              suggestion: suggestion,
              canRecord: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('welfare_suggestion_card_neuter')),
      findsOneWidget,
    );
    expect(find.text('Add routine'), findsNothing);
    expect(find.text('Accept'), findsNothing);
    expect(
      find.byKey(const Key('welfare_suggestion_record_neuter')),
      findsOneWidget,
    );
  });

  testWidgets('vaccination welfare card has record action without Accept', (
    tester,
  ) async {
    const pet = Pet(id: 'p1', name: 'Ada', species: 'Dog');
    const suggestion = WelfareSuggestion(
      id: 'ws-vx',
      petId: 'p1',
      subjectKey: 'vaccination_welfare',
      dedupeKey: 'welfare:vaccination:p1',
      rationaleKey: 'careWelfareVaccinationWhy',
      engineVersion: '1.0.0',
      severity: 4,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WelfareSuggestionCard(
              pet: pet,
              suggestion: suggestion,
              canRecord: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('welfare_suggestion_card_vaccination')),
      findsOneWidget,
    );
    expect(find.text('Accept'), findsNothing);
    expect(
      find.byKey(const Key('welfare_suggestion_record_vaccination')),
      findsOneWidget,
    );
  });
}
