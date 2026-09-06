import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care_onboarding_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('guardian onboarding welcome step shows title and skip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PetCareOnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_care_onboarding_screen')), findsOneWidget);
    expect(
      find.byKey(const Key('pet_care_onboarding_welcome')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pet_care_onboarding_skip')), findsOneWidget);
    expect(find.text('Welcome to AgathaTrack'), findsOneWidget);
  });
}
