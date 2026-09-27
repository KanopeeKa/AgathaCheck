@Tags(['frozen'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/experience_chooser_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
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
  testWidgets('FTUE shows pet care onboarding action', (tester) async {
    await tester.pumpWidget(_wrap(const ExperienceChooserScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ftue_action_track_pets')), findsOneWidget);
    expect(find.text('Welcome to AgathaTrack'), findsOneWidget);
    expect(find.byKey(const Key('ftue_action_run_shelter')), findsNothing);
    expect(find.byKey(const Key('ftue_action_fostering')), findsNothing);
  });
}
