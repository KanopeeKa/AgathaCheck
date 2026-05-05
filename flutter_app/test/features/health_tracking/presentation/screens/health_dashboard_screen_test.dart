import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('HealthDashboardScreen renders tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HealthDashboardScreen(),
        ),
      ),
    );
    // One pump so AppLocalizations resolves, but no pumpAndSettle —
    // the body's provider watchers will spin forever if not overridden.
    await tester.pump();
    expect(find.byType(TabBar), findsOneWidget);
  });
}
