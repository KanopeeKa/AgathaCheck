import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/experience_chooser_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  final dualEligibility = ExperienceEligibilityRules.compute(
    pets: const [
      Pet(id: '1', name: 'A', species: 'Cat'),
      Pet(
        id: '2',
        name: 'B',
        species: 'Dog',
        organizationId: 'o1',
        organizationName: 'Shelter',
      ),
    ],
    orgMembershipCount: 1,
  );

  testWidgets('chooser shows remember hint for dual users', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ExperienceChooserScreen(),
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(dualEligibility),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('remember_experience_choice')), findsOneWidget);
    expect(find.byKey(const Key('remember_experience_hint')), findsOneWidget);
    expect(find.byKey(const Key('experience_card_guardian')), findsOneWidget);
    expect(find.byKey(const Key('experience_card_organization')), findsOneWidget);
  });

  testWidgets('chooser hides organisation card for guardian-only eligibility', (
    tester,
  ) async {
    final guardianOnly = ExperienceEligibilityRules.compute(
      pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
      orgMembershipCount: 0,
    );
    await tester.pumpWidget(
      _wrap(
        const ExperienceChooserScreen(),
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(guardianOnly),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_card_guardian')), findsOneWidget);
    expect(find.byKey(const Key('experience_card_organization')), findsNothing);
  });
}
