import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_stack_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('review entry opens care item with returnTo after sheet closes', (
    tester,
  ) async {
    final _entry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Morning meds',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.daily,
      startDate: DateTime(2024, 1, 1),
      nextDueDate: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/pc/home',
          routes: [
            GoRoute(
              path: '/pc/home',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showOccurrenceStackSheet(
                      context,
                      entry: _entry,
                      occurrences: const [],
                      onRecordHead: (_, __, ___) async {},
                      onSkipAllMissed: () async {},
                    ),
                    child: const Text('Open sheet'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/pet/:petId/events/:entryId',
              builder: (_, state) =>
                  Text('event|${state.uri.queryParameters['returnTo'] ?? ''}'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('occurrence_review_entry')));
    await tester.pumpAndSettle();

    expect(find.text('event|/pc/home'), findsOneWidget);
  });
}
