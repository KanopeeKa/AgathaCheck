import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('HealthDashboardScreen renders care filter chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HealthDashboardScreen(skipHeavyBody: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('health_filter_group_all')), findsOneWidget);
    expect(
      find.byKey(const Key('health_filter_group_prevention')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('health_filter_family_all')), findsOneWidget);
    expect(
      find.byKey(const Key('health_filter_family_medication')),
      findsOneWidget,
    );
  });
}
