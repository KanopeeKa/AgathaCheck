import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/consent/consent_banner_surface.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('ConsentBannerSurface accept and manage callbacks', (
    tester,
  ) async {
    var accepted = false;
    var managed = false;
    late AppLocalizations l;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l = AppLocalizations.of(context)!;
            return Scaffold(
              body: ConsentBannerSurface(
                l10n: l,
                theme: Theme.of(context),
                onAcceptAll: () => accepted = true,
                onManagePreferences: () => managed = true,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.consentAcceptAll));
    expect(accepted, isTrue);

    await tester.tap(find.text(l.consentManagePreferences));
    expect(managed, isTrue);
  });
}
