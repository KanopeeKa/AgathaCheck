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
  testWidgets('landing branding presents the role-neutral operations desk', (
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

    expect(find.text('THE GUARDIAN OPERATIONS DESK'), findsOneWidget);
    expect(find.text('Keep care close.\nKeep everyone ready.'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Clear handovers'), findsOneWidget);
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.byKey(const Key('landing_guardian_path_card')), findsNothing);
    expect(find.byKey(const Key('landing_org_path_card')), findsNothing);
  });
}
