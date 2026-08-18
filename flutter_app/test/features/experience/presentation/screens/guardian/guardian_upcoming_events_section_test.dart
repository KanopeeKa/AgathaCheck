import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/dashboard_section.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_upcoming_events_section.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

void main() {
  testWidgets('upcoming events section renders title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            FakeHealthEntriesNotifier.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: GuardianUpcomingEventsSection(pets: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Due and Overdue'), findsOneWidget);
    expect(find.byType(DashboardSection), findsOneWidget);
  });
}
