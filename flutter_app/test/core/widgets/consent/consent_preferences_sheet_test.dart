import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/core/services/consent_service.dart';
import 'package:pet_profile_app/core/widgets/consent/consent_preferences_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fakes.dart';

class _FailingPrefs extends FakePrefs {
  @override
  bool? getBool(String key) => null;

  @override
  Future<bool> setBool(String key, bool value) async => false;
}

class _OkPrefs implements SharedPreferences {
  final Map<String, Object?> _store = {};

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _sheetHarness({
  required SharedPreferences prefs,
  required Locale locale,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('save failure keeps sheet open and shows retry snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sheetHarness(
        prefs: _FailingPrefs(),
        locale: const Locale('en'),
        child: const ConsentPreferencesSheet(),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(
      tester.element(find.byType(ConsentPreferencesSheet)),
    )!;

    await tester.ensureVisible(find.text(l.consentSavePreferences));
    await tester.tap(find.text(l.consentSavePreferences));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ConsentPreferencesSheet), findsOneWidget);
    expect(find.text(l.consentPreferencesSaveFailed), findsOneWidget);
    expect(find.text(l.consentPreferencesSaved), findsNothing);
  });

  testWidgets('save success shows snackbar and pops sheet', (tester) async {
    await tester.pumpWidget(
      _sheetHarness(
        prefs: _OkPrefs(),
        locale: const Locale('en'),
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => const ConsentPreferencesSheet(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(
      tester.element(find.byType(ConsentPreferencesSheet)),
    )!;

    await tester.ensureVisible(find.text(l.consentSavePreferences));
    await tester.tap(find.text(l.consentSavePreferences));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ConsentPreferencesSheet), findsNothing);
    expect(find.text(l.consentPreferencesSaved), findsOneWidget);
  });

  testWidgets('consent timestamp uses locale date format', (tester) async {
    final prefs = _OkPrefs();
    await prefs.setString('consent_timestamp', '2026-03-15T14:30:00.000');
    await prefs.setBool('consent_has_responded', true);
    await prefs.setBool('consent_essential', true);
    await prefs.setBool('consent_analytics', false);
    await prefs.setBool('consent_marketing', false);

    await tester.pumpWidget(
      _sheetHarness(
        prefs: prefs,
        locale: const Locale('fr'),
        child: const ConsentPreferencesSheet(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('15/03/2026'), findsOneWidget);
    expect(find.textContaining('14:30'), findsOneWidget);
  });
}
