import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/core/widgets/consent_banner.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryPrefs implements SharedPreferences {
  final Map<String, Object?> _store = {};
  final Future<bool> Function(String key, bool value)? setBoolHook;

  _MemoryPrefs({this.setBoolHook});

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> setBool(String key, bool value) async {
    if (setBoolHook != null) return setBoolHook!(key, value);
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

void main() {
  testWidgets('reject optional persists and hides banner', (tester) async {
    final prefs = _MemoryPrefs();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ConsentBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(tester.element(find.byType(ConsentBanner)))!;
    await tester.tap(find.text(l.consentRejectOptional));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(l.consentBannerTitle), findsNothing);
  });

  testWidgets('reject optional failure keeps banner with error', (
    tester,
  ) async {
    final prefs = _MemoryPrefs(setBoolHook: (_, __) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ConsentBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(tester.element(find.byType(ConsentBanner)))!;
    await tester.tap(find.text(l.consentRejectOptional));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(l.consentBannerTitle), findsOneWidget);
    expect(find.text(l.consentPreferencesSaveFailed), findsOneWidget);
  });
}
