import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/consent/consent_banner_surface.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _bannerAtWidth({
  required double width,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800), textScaler: textScaler),
      child: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context)!;
          final theme = Theme.of(context);
          return Scaffold(
            body: Center(
              child: SizedBox(
                width: width - 32,
                child: ConsentBannerSurface(
                  l10n: l,
                  theme: theme,
                  onManagePreferences: () {},
                  onRejectOptional: () {},
                  onAcceptAll: () {},
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('ConsentBannerSurface action callbacks', (tester) async {
    var accepted = false;
    var managed = false;
    var rejected = false;
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
                onRejectOptional: () => rejected = true,
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

    await tester.tap(find.text(l.consentRejectOptional));
    expect(rejected, isTrue);
  });

  for (final width in [320.0, 360.0, 399.0, 400.0, 480.0]) {
    testWidgets('layouts without flex exception at ${width.toInt()} dp', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_bannerAtWidth(width: width));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConsentBannerSurface), findsOneWidget);
    });
  }

  testWidgets(
    'French locale at 2.0 text scale shows all actions without overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 2400),
              textScaler: TextScaler.linear(2),
            ),
            child: Builder(
              builder: (context) {
                final l = AppLocalizations.of(context)!;
                final theme = Theme.of(context);
                return Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ConsentBannerSurface(
                        l10n: l,
                        theme: theme,
                        onManagePreferences: () {},
                        onRejectOptional: () {},
                        onAcceptAll: () {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final l = AppLocalizations.of(
        tester.element(find.byType(ConsentBannerSurface)),
      )!;
      expect(find.text(l.consentAcceptAll), findsOneWidget);
      expect(find.text(l.consentManagePreferences), findsOneWidget);
      expect(find.text(l.consentRejectOptional), findsOneWidget);
    },
  );

  testWidgets('saving shows labelled progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return Scaffold(
              body: ConsentBannerSurface(
                l10n: l,
                theme: Theme.of(context),
                saving: true,
                onManagePreferences: () {},
                onRejectOptional: () {},
                onAcceptAll: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Accept All'), findsNothing);
  });

  testWidgets('save failure shows retryable error copy', (tester) async {
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
                saveFailed: true,
                onManagePreferences: () {},
                onRejectOptional: () {},
                onAcceptAll: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.consentPreferencesSaveFailed), findsOneWidget);
  });
}
