import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/router/occurrence_screen_route.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Regression for go_router reusing [OccurrenceScreen] state across replace hops
/// (CARE-ITEM-R-020): neighbour navigation must reload each occurrence.
Map<String, dynamic> _neighborDetail({
  required String occurrenceId,
  required String scheduledDate,
  Map<String, dynamic>? previousOccurrence,
  Map<String, dynamic>? nextOccurrence,
}) {
  return {
    'occurrence': {
      'id': occurrenceId,
      'scheduled_date': scheduledDate,
      'scheduled_time': null,
      'status': 'pending',
      'occurrence_status': 'due',
      'completed_on': null,
      'outcome': 'due',
      'origin': 'computed',
      'notes': '',
    },
    'entry': {
      'id': 'entry-1',
      'pet_id': 'pet-1',
      'name': 'Flea',
      'care_family': 'parasite_prevention',
      'recurrence_anchor': 'from_completion',
      'late_completion_choice': null,
      'status': 'active',
      'as_of': {
        'date': scheduledDate,
        'time': '09:00',
        'timezone': 'Europe/Paris',
      },
      'open_occurrences': [
        {
          'id': occurrenceId,
          'scheduled_date': scheduledDate,
          'scheduled_time': null,
          'status': 'due',
          'origin': 'computed',
        },
      ],
    },
    if (previousOccurrence != null) 'previous_occurrence': previousOccurrence,
    if (nextOccurrence != null) 'next_occurrence': nextOccurrence,
  };
}

class _NeighborNavServer {
  _NeighborNavServer(this.reads);

  final List<Map<String, dynamic>> reads;
  final List<String> fetchedOccurrenceIds = [];

  late final http.Client client = MockClient((request) async {
    if (request.method == 'GET' &&
        request.url.pathSegments.contains('occurrences')) {
      final occId = request.url.pathSegments.last;
      fetchedOccurrenceIds.add(occId);
      final payload = reads.firstWhere(
        (row) => row['occurrence']['id'] == occId,
        orElse: () => reads.last,
      );
      return http.Response(json.encode(payload), 200);
    }
    return http.Response(json.encode({'undo_token': 'u'}), 200);
  });
}

Widget _harness(_NeighborNavServer server) => ProviderScope(
  overrides: [
    careItemHttpClientProvider.overrideWithValue(server.client),
    petByIdProvider('pet-1').overrideWith(
      (ref) async =>
          Pet(id: 'pet-1', name: 'Buddy', species: 'dog', photoPath: null),
    ),
  ],
  child: MaterialApp.router(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: '/pet/pet-1/events/entry-1/occurrences/occ-a',
      routes: [
        GoRoute(
          path: '/pet/:petId/events/:entryId/occurrences/:occurrenceId',
          builder: buildOccurrenceDetailScreen,
        ),
      ],
    ),
  ),
);

Future<void> _tapNeighbor(WidgetTester tester, String semanticsId) async {
  await tester.scrollUntilVisible(
    find.bySemanticsIdentifier('occurrence_neighbors_section'),
    48,
    scrollable: find.byType(Scrollable).first,
  );
  final target = find.bySemanticsIdentifier(semanticsId);
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
}

void main() {
  testWidgets(
    'replace neighbour hops reload occurrence data through two next and one previous',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final server = _NeighborNavServer([
        _neighborDetail(
          occurrenceId: 'occ-a',
          scheduledDate: '2026-06-08',
          nextOccurrence: {
            'id': 'occ-b',
            'scheduled_date': '2026-06-10',
            'scheduled_time': null,
            'occurrence_status': 'due',
          },
        ),
        _neighborDetail(
          occurrenceId: 'occ-b',
          scheduledDate: '2026-06-10',
          previousOccurrence: {
            'id': 'occ-a',
            'scheduled_date': '2026-06-08',
            'scheduled_time': null,
            'occurrence_status': 'due',
          },
          nextOccurrence: {
            'id': 'occ-c',
            'scheduled_date': '2026-06-12',
            'scheduled_time': null,
            'occurrence_status': 'due',
          },
        ),
        _neighborDetail(
          occurrenceId: 'occ-c',
          scheduledDate: '2026-06-12',
          previousOccurrence: {
            'id': 'occ-b',
            'scheduled_date': '2026-06-10',
            'scheduled_time': null,
            'occurrence_status': 'due',
          },
        ),
      ]);

      await tester.pumpWidget(_harness(server));
      await tester.pumpAndSettle();

      expect(server.fetchedOccurrenceIds, ['occ-a']);

      await _tapNeighbor(tester, 'occurrence_neighbor_next');
      await tester.pumpAndSettle();

      expect(server.fetchedOccurrenceIds, ['occ-a', 'occ-b']);

      await _tapNeighbor(tester, 'occurrence_neighbor_next');
      await tester.pumpAndSettle();

      expect(server.fetchedOccurrenceIds, ['occ-a', 'occ-b', 'occ-c']);

      final screenContext = tester.element(find.byType(OccurrenceScreen));
      final router = GoRouter.of(screenContext);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        endsWith('/occurrences/occ-c'),
      );

      await _tapNeighbor(tester, 'occurrence_neighbor_previous');
      await tester.pumpAndSettle();

      expect(server.fetchedOccurrenceIds, ['occ-a', 'occ-b', 'occ-c', 'occ-b']);
      expect(
        GoRouter.of(
          tester.element(find.byType(OccurrenceScreen)),
        ).routerDelegate.currentConfiguration.uri.path,
        endsWith('/occurrences/occ-b'),
      );
    },
  );

  testWidgets('replaceOccurrenceScreen uses context.go like production', (
    tester,
  ) async {
    final server = _NeighborNavServer([
      _neighborDetail(
        occurrenceId: 'occ-a',
        scheduledDate: '2026-06-08',
        nextOccurrence: {
          'id': 'occ-b',
          'scheduled_date': '2026-06-10',
          'scheduled_time': null,
          'occurrence_status': 'due',
        },
      ),
      _neighborDetail(
        occurrenceId: 'occ-b',
        scheduledDate: '2026-06-10',
        previousOccurrence: {
          'id': 'occ-a',
          'scheduled_date': '2026-06-08',
          'scheduled_time': null,
          'occurrence_status': 'due',
        },
      ),
    ]);

    await tester.pumpWidget(_harness(server));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OccurrenceScreen));
    replaceOccurrenceScreen(
      context,
      petId: 'pet-1',
      entryId: 'entry-1',
      occurrenceId: 'occ-b',
      source: 'neighbor',
    );
    await tester.pumpAndSettle();

    expect(server.fetchedOccurrenceIds, ['occ-a', 'occ-b']);
  });
}
