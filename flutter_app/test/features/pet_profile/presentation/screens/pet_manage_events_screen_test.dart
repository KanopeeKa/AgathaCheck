import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_manage_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/pet_event_entry_list.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  _TestHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

Future<List<HealthHistoryEntry>> _historyFor(
  Ref ref,
  String entryId,
) async {
  switch (entryId) {
    case 'entry-closed':
      return [
        HealthHistoryEntry(
          id: 'hist-2',
          entryId: entryId,
          markedAt: DateTime(2025, 7, 1),
          dueDate: DateTime(2025, 6, 15),
          completedOn: DateTime(2025, 6, 20),
          status: 'completed',
        ),
        HealthHistoryEntry(
          id: 'hist-1',
          entryId: entryId,
          markedAt: DateTime(2025, 6, 1),
          dueDate: DateTime(2025, 5, 1),
          completedOn: DateTime(2025, 5, 1),
          status: 'completed',
        ),
      ];
    case 'entry-skipped':
      return [
        HealthHistoryEntry(
          id: 'hist-skip',
          entryId: entryId,
          markedAt: DateTime(2025, 6, 2),
          dueDate: DateTime.now().add(const Duration(days: 10)),
          status: 'skipped',
        ),
      ];
    default:
      return [];
  }
}

void main() {
  const pet = Pet(id: 'pet-1', name: 'Rex', species: 'Dog', breed: 'Mix');
  final dateFormat = DateFormat('dd MMM yy');

  final openMedication = HealthEntry(
    id: 'entry-open-med',
    petId: 'pet-1',
    name: 'Heartgard',
    type: HealthEntryType.medication,
    dosage: '1 tablet',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().add(const Duration(days: 3)),
  );

  final overduePreventive = HealthEntry(
    id: 'entry-overdue',
    petId: 'pet-1',
    name: 'Flea treatment',
    type: HealthEntryType.preventive,
    dosage: '',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
  );

  final closedRecurring = HealthEntry(
    id: 'entry-closed',
    petId: 'pet-1',
    name: 'Dewormer',
    type: HealthEntryType.preventive,
    dosage: '1 dose',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 8, 1),
    repeatEndDate: DateTime.now().subtract(const Duration(days: 1)),
  );

  final oneTimeOther = HealthEntry(
    id: 'entry-other',
    petId: 'pet-1',
    name: 'Grooming',
    type: HealthEntryType.other,
    dosage: 'Full groom',
    frequency: HealthFrequency.once,
    startDate: DateTime(2025, 1, 1),
    completedOn: DateTime(2025, 3, 1),
    nextDueDate: DateTime(9999, 12, 31),
  );

  final skippedEntry = HealthEntry(
    id: 'entry-skipped',
    petId: 'pet-1',
    name: 'Skipped dose',
    type: HealthEntryType.medication,
    dosage: '5 mg',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().add(const Duration(days: 10)),
  );

  final allEntries = [
    openMedication,
    overduePreventive,
    closedRecurring,
    oneTimeOther,
    skippedEntry,
  ];

  Widget buildScreen({List<HealthEntry>? entries}) {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/events',
      routes: [
        GoRoute(
          path: '/pet/:petId/events',
          builder: (context, state) =>
              PetManageEventsScreen(petId: state.pathParameters['petId']!),
        ),
        GoRoute(
          path: '/pet/:petId/events/:entryId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('View ${state.pathParameters['entryId']}'),
            ),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        resolvedExperienceProvider.overrideWith(
          (ref) => AppExperience.guardian,
        ),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        healthEntriesNotifierProvider.overrideWith(
          () => _TestHealthEntriesNotifier(entries ?? allEntries),
        ),
        entryHistoryProvider.overrideWith(_historyFor),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('filterAndSortManageEvents', () {
    test('sorts open entries before closed and by next due date', () {
      final histories = <String, List<HealthHistoryEntry>>{
        'entry-closed': [
          HealthHistoryEntry(
            id: 'hist-2',
            entryId: 'entry-closed',
            markedAt: DateTime(2025, 7, 1),
            dueDate: DateTime(2025, 6, 15),
            completedOn: DateTime(2025, 6, 20),
            status: 'completed',
          ),
        ],
      };

      final sorted = filterAndSortManageEvents(
        allEntries,
        const ManageEventsFilters(),
        histories,
      );

      expect(sorted.first.id, 'entry-overdue');
      expect(sorted.last.id, 'entry-closed');
    });

    test('filters by type and recurring', () {
      final visible = filterAndSortManageEvents(
        allEntries,
        const ManageEventsFilters(
          type: ManageEventsTypeFilter.other,
          recurring: ManageEventsRecurringFilter.oneTime,
        ),
        const {},
      );

      expect(visible, hasLength(1));
      expect(visible.single.id, 'entry-other');
    });

    test('hides skipped entries when showSkipped is false', () {
      final visible = filterAndSortManageEvents(
        allEntries,
        const ManageEventsFilters(showSkipped: false),
        {
          'entry-skipped': [
            HealthHistoryEntry(
              id: 'hist-skip',
              entryId: 'entry-skipped',
              markedAt: DateTime(2025, 6, 2),
              dueDate: DateTime.now().add(const Duration(days: 10)),
              status: 'skipped',
            ),
          ],
        },
      );

      expect(visible.any((e) => e.id == 'entry-skipped'), isFalse);
    });
  });

  testWidgets('shows unified Events list without tabs', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Manage events'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('History'), findsNothing);
    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);
  });

  testWidgets('EventListCard navigates to view entry', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heartgard'));
    await tester.pumpAndSettle();

    expect(find.text('View entry-open-med'), findsOneWidget);
  });

  testWidgets('shows Skipped status for skipped occurrence', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Skipped'), findsOneWidget);
  });

  testWidgets('type filter shows only matching entries', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_events_type_other')));
    await tester.pumpAndSettle();

    expect(find.text('Grooming'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
    expect(find.text('Flea treatment'), findsNothing);
  });

  testWidgets('due/overdue filter hides non-due entries', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_events_status_dueOverdue')));
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
    expect(find.text('Grooming'), findsNothing);
  });

  testWidgets('show skipped chip toggles skipped entry visibility', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Skipped dose'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manage_events_show_skipped_chip')));
    await tester.pumpAndSettle();

    expect(find.text('Skipped dose'), findsNothing);

    await tester.tap(find.byKey(const Key('manage_events_show_skipped_chip')));
    await tester.pumpAndSettle();

    expect(find.text('Skipped dose'), findsOneWidget);
  });

  testWidgets('closed filter shows closed series with done date', (
    tester,
  ) async {
    final l = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_events_status_closed')));
    await tester.pumpAndSettle();

    expect(find.text('Dewormer'), findsOneWidget);
    expect(
      find.text(l.doneOn(dateFormat.format(DateTime(2025, 6, 20)))),
      findsOneWidget,
    );
  });
}
