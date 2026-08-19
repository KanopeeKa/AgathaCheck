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
  testWidgets('FTUE shows three action cards', (tester) async {
    await tester.pumpWidget(_wrap(const ExperienceChooserScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ftue_action_track_pets')), findsOneWidget);
    expect(find.byKey(const Key('ftue_action_run_shelter')), findsOneWidget);
    expect(find.byKey(const Key('ftue_action_fostering')), findsOneWidget);
    expect(find.text('Welcome to Agatha Track'), findsOneWidget);
  });

  testWidgets('fostering action opens optional code dialog', (tester) async {
    await tester.pumpWidget(_wrap(const ExperienceChooserScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ftue_action_fostering')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ftue_foster_code_field')), findsOneWidget);
    expect(
      find.byKey(const Key('ftue_foster_continue_button')),
      findsOneWidget,
    );
  });
}
