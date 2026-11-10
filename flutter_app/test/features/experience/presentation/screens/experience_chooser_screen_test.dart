@Tags(['frozen'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/experience_chooser_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('retired chooser shows progress until redirect', (tester) async {
    await tester.pumpWidget(_wrap(const ExperienceChooserScreen()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('ftue_action_track_pets')), findsNothing);
  });
}
