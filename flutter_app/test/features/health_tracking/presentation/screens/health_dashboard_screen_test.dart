// Linux CI: flutter_tester segfaults during teardown of this full-screen mount
// (TabController + ConsumerStatefulWidget). Covered locally; actions widget has
// its own test in health_dashboard_actions_test.dart.
@Tags(['skip-ci'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('HealthDashboardScreen renders tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HealthDashboardScreen(skipHeavyBody: true),
      ),
    );
    await tester.pump();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byKey(const Key('health_tab_all')), findsOneWidget);
    expect(find.byKey(const Key('health_tab_medications')), findsOneWidget);
  });
}
