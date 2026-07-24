import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/widgets/landing/landing_branding_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('landing branding shows guardian and org path cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return LandingBrandingSection(
              theme: Theme.of(context),
              l10n: AppLocalizations.of(context)!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('landing_guardian_path_card')), findsOneWidget);
    expect(find.byKey(const Key('landing_org_path_card')), findsOneWidget);
    expect(find.text('For pet parents and foster carers'), findsOneWidget);
    expect(find.text('For shelters, rescues, and care teams'), findsOneWidget);
  });

  testWidgets('landing guardian path card expands detail on tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return LandingBrandingSection(
              theme: Theme.of(context),
              l10n: AppLocalizations.of(context)!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('See how it works'), findsOneWidget);
    expect(find.textContaining('Coordinate with your household'), findsNothing);

    await tester.tap(find.byKey(const Key('landing_guardian_path_card')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Coordinate with your household'),
      findsOneWidget,
    );
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('landing path cards use experience accent fills', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return LandingBrandingSection(
              theme: Theme.of(context),
              l10n: AppLocalizations.of(context)!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final guardianMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const Key('landing_guardian_path_card')),
        matching: find.byType(Material),
      ),
    );
    final orgMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const Key('landing_org_path_card')),
        matching: find.byType(Material),
      ),
    );

    expect(guardianMaterial.color, isNotNull);
    expect(orgMaterial.color, isNotNull);
    expect(guardianMaterial.color, isNot(equals(orgMaterial.color)));
    expect(guardianMaterial.elevation, 0);
    expect(orgMaterial.elevation, 0);
  });
}
