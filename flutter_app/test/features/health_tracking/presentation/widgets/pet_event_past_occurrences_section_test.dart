import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/pet_event_view_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/pet_event_past_occurrences_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

List<HealthOccurrence> _pastRows(int count) {
  return List.generate(
    count,
    (i) => HealthOccurrence(
      id: 'past-$i',
      entryId: 'entry-1',
      scheduledDate: DateTime(2025, 6, count - i),
      status: 'completed',
      completedOn: DateTime(2025, 6, count - i),
    ),
  );
}

Widget _wrap({
  required Widget child,
  required List<HealthOccurrence> past,
  double width = 400,
  GoRouter? router,
}) {
  final app = ProviderScope(
    overrides: [
      entryPastOccurrencesProvider('entry-1').overrideWith((ref) async => past),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig:
          router ??
          GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: SizedBox(width: width, child: child),
                ),
              ),
              GoRoute(
                path: '/pet/:petId/events/:entryId/occurrences/:occId',
                builder: (context, state) => Scaffold(
                  body: Text('occ ${state.pathParameters['occId']}'),
                ),
              ),
            ],
          ),
    ),
  );
  return app;
}

void main() {
  testWidgets('hides list when there are no past occurrences', (tester) async {
    await tester.pumpWidget(
      _wrap(
        past: const [],
        child: const PetEventPastOccurrencesSection(
          entryId: 'entry-1',
          petId: 'pet-1',
          muted: false,
          maxVisibleRows: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-0')),
      findsNothing,
    );
  });

  testWidgets('shows at most three rows when maxVisibleRows is 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        width: 400,
        past: _pastRows(6),
        child: const PetEventPastOccurrencesSection(
          entryId: 'entry-1',
          petId: 'pet-1',
          muted: false,
          maxVisibleRows: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-3')),
      findsNothing,
    );
  });

  testWidgets('shows at most five rows when maxVisibleRows is 5', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        width: 690,
        past: _pastRows(7),
        child: const PetEventPastOccurrencesSection(
          entryId: 'entry-1',
          petId: 'pet-1',
          muted: false,
          maxVisibleRows: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrence_past-5')),
      findsNothing,
    );
  });

  testWidgets('row tap opens occurrence screen', (tester) async {
    await tester.pumpWidget(
      _wrap(
        past: _pastRows(1),
        child: const PetEventPastOccurrencesSection(
          entryId: 'entry-1',
          petId: 'pet-1',
          muted: false,
          maxVisibleRows: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pet_event_past_occurrence_past-0')));
    await tester.pumpAndSettle();
    expect(find.text('occ past-0'), findsOneWidget);
  });

  testWidgets('does not render legacy iterations header or unmark control', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        past: _pastRows(2),
        child: const PetEventPastOccurrencesSection(
          entryId: 'entry-1',
          petId: 'pet-1',
          muted: false,
          maxVisibleRows: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pet_event_past_iterations_header')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrences_header')),
      findsNothing,
    );
    expect(find.byKey(const Key('unmark_done_past-0')), findsNothing);
  });
}
