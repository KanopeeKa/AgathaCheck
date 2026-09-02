import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/data/datasources/health_remote_datasource.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/pet_event_view_screen.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/pet_event_view_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  _TestHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

Future<List<HealthHistoryEntry>> _openHistory(Ref ref, String entryId) async =>
    [
      HealthHistoryEntry(
        id: 'hist-1',
        entryId: 'entry-1',
        markedAt: DateTime(2025, 6, 1),
        dueDate: DateTime(2025, 5, 1),
        completedOn: DateTime(2025, 5, 1),
        status: 'completed',
      ),
    ];

Future<List<HealthHistoryEntry>> _closedHistory(
  Ref ref,
  String entryId,
) async => [
  HealthHistoryEntry(
    id: 'hist-2',
    entryId: 'entry-2',
    markedAt: DateTime(2025, 7, 1),
    dueDate: DateTime(2025, 6, 15),
    completedOn: DateTime(2025, 6, 15),
    status: 'completed',
  ),
  HealthHistoryEntry(
    id: 'hist-1',
    entryId: 'entry-2',
    markedAt: DateTime(2025, 6, 1),
    dueDate: DateTime(2025, 5, 1),
    completedOn: DateTime(2025, 5, 1),
    status: 'completed',
  ),
];

Future<List<EventPhoto>> _emptyPhotos(Ref ref, String entryId) async => [];

HealthOccurrence _occ({
  required String id,
  required DateTime date,
  String? time,
  String status = 'pending',
  DateTime? completedOn,
}) {
  return HealthOccurrence(
    id: id,
    entryId: 'entry-1',
    scheduledDate: date,
    scheduledTime: time,
    status: status,
    completedOn: completedOn,
  );
}

Future<List<HealthOccurrence>> _openOccurrences(Ref ref, String entryId) async {
  final today = calendarDateOnly(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));
  return [
    _occ(id: 'occ-missed', date: yesterday, time: '08:00'),
    _occ(id: 'occ-today', date: today, time: '12:00'),
    _occ(id: 'occ-later', date: tomorrow, time: '08:00'),
  ];
}

Future<List<HealthOccurrence>> _emptyOccurrences(Ref ref, String entryId) async =>
    [];

Future<List<HealthOccurrence>> _pastOccurrences(Ref ref, String entryId) async =>
    [
      _occ(
        id: 'past-1',
        date: DateTime(2025, 4, 1),
        status: 'completed',
        completedOn: DateTime(2025, 4, 1),
      ),
    ];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const pet = Pet(
    id: 'pet-1',
    name: 'Bella',
    species: 'Dog',
    colorValue: 0xFF2196F3,
  );

  final openEntry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'Heartworm',
    type: HealthEntryType.preventive,
    dosage: '1 tablet',
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2020, 1, 1),
    healthIssueId: 'issue-1',
    healthIssueName: 'Skin allergy',
    notes: 'Give with food',
  );

  final closedEntry = HealthEntry(
    id: 'entry-2',
    petId: 'pet-1',
    name: 'Flea treatment',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 8, 1),
    repeatEndDate: DateTime(2025, 7, 26),
    notes: 'Series ended',
  );

  Widget buildApp({
    required HealthEntry entry,
    required Future<List<HealthHistoryEntry>> Function(Ref, String) historyFn,
    Future<List<HealthOccurrence>> Function(Ref, String)? openOccurrencesFn,
    Future<List<HealthOccurrence>> Function(Ref, String)? pastOccurrencesFn,
  }) {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/events/${entry.id}',
      routes: [
        GoRoute(
          path: '/pet/:petId/events/:entryId',
          builder: (context, state) => PetEventViewScreen(
            petId: state.pathParameters['petId']!,
            entryId: state.pathParameters['entryId']!,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: const [],
              orgMembershipCount: 0,
            ),
          ),
        ),
        organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        healthEntriesNotifierProvider.overrideWith(
          () => _TestHealthEntriesNotifier([entry]),
        ),
        entryHistoryProvider.overrideWith(historyFn),
        healthEntryPhotosProvider.overrideWith(_emptyPhotos),
        entryOccurrencesProvider.overrideWith(
          openOccurrencesFn ?? _emptyOccurrences,
        ),
        entryPastOccurrencesProvider.overrideWith(
          pastOccurrencesFn ?? ((ref, _) async => []),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('open entry shows zoned occurrences with per-row actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        entry: openEntry,
        historyFn: _openHistory,
        openOccurrencesFn: _openOccurrences,
        pastOccurrencesFn: _pastOccurrences,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Heartworm'), findsOneWidget);
    expect(find.text('Close event'), findsOneWidget);
    expect(find.byKey(const Key('pet_event_edit_app_bar')), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(
      find.byKey(const Key('pet_event_occurrence_row_occ-missed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pet_event_occurrence_mark_done_occ-today')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pet_event_occurrence_skip_occ-later')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pet_event_skip_all_missed')), findsOneWidget);
    expect(find.text('Snooze'), findsNothing);
    expect(find.text('Give with food'), findsOneWidget);
    expect(find.text('Skin allergy'), findsOneWidget);
    expect(
      find.byKey(const Key('pet_event_health_issue_link')),
      findsOneWidget,
    );
  });

  testWidgets('closed entry greys status and shows reopen', (tester) async {
    await tester.pumpWidget(
      buildApp(entry: closedEntry, historyFn: _closedHistory),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Flea treatment'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Reopen event'), findsOneWidget);
    expect(find.text('Close event'), findsNothing);
    expect(find.text('Mark as done'), findsNothing);
    expect(find.text('Skip all missed'), findsNothing);
    expect(find.text('Series ended'), findsOneWidget);
  });

  testWidgets('open entry without occurrences falls back to legacy summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(entry: openEntry, historyFn: _openHistory),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_event_occurrence_summary_entry-1')),
      findsOneWidget,
    );
    expect(find.text('Mark as done'), findsNothing);
    expect(find.text('Snooze'), findsNothing);
  });
}
