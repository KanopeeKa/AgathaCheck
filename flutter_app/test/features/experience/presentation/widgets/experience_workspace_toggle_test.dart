@Tags(['frozen'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_workspace_toggle.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildToggle({
  required SharedPreferences prefs,
  required String currentLocation,
  bool showShelter = false,
}) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExperienceWorkspaceToggle(
          currentLocation: currentLocation,
          onDarkBackground: false,
          showShelter: showShelter,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('renders no interactive toggle while D-MVP-1 frozen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildToggle(
        prefs: prefs,
        currentLocation: '/pc/home',
        showShelter: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('experience_workspace_toggle')), findsNothing);
  });
}
