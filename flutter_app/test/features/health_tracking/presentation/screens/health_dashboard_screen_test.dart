import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

Widget _wrapDashboard() {
  return ProviderScope(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(FakeHealthEntriesNotifier.new),
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HealthDashboardScreen(),
          ),
          GoRoute(
            path: '/health/add',
            builder: (context, state) => const Scaffold(body: SizedBox()),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('HealthDashboardScreen renders tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapDashboard());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TabBar), findsOneWidget);

    // Explicit teardown — avoids TabController / provider async work segfaulting
    // the flutter_tester shell during finalization on CI (Linux).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
